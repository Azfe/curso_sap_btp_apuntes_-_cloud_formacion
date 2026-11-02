# Pruebas manuales del servicio OData con `test.http`

> Guía para probar a mano `HarvardService` (`srv/harvard-service.cds` + `srv/harvard-service.js`) con la extensión **REST Client** de VS Code / SAP Business Application Studio. Los datos de ejemplo son los CSV de `db/data/`.

## Índice

1. [Requisitos previos](#1-requisitos-previos)
2. [Arrancar el servidor](#2-arrancar-el-servidor)
3. [Cómo funciona REST Client](#3-cómo-funciona-rest-client)
4. [Sintaxis OData que hay que conocer](#4-sintaxis-odata-que-hay-que-conocer)
5. [Batería de pruebas](#5-batería-de-pruebas)
6. [Depurar con breakpoints](#6-depurar-con-breakpoints)
7. [Uso del depurador](#7-uso-del-depurador)
8. [Errores frecuentes](#8-errores-frecuentes)
9. [Pruebas manuales vs. automáticas](#9-pruebas-manuales-vs-automáticas)

---

## 1. Requisitos previos

- Extensión **REST Client** (`humao.rest-client`) instalada. En BAS viene preinstalada.
- Dependencias instaladas en el proyecto: `npm install`. Sin `node_modules`, el `import cds from '@sap/cds'` del handler falla aunque el `cds` global funcione.
- Un fichero `test.http` en la raíz del proyecto.

---

## 2. Arrancar el servidor

```bash
cds watch
```

O desde **Run and Debug** con la configuración `cds watch` (ver [sección 6](#6-depurar-con-breakpoints)).

Al arrancar en desarrollo, `cds watch`:

- Usa **SQLite en memoria** y carga los CSV de `db/data/` en cada arranque.
- Recarga automáticamente al guardar cualquier `.cds`, `.js` o `.csv`.
- Sirve el servicio en `http://localhost:4004/odata/v4/harvard`.

> **Importante:** las peticiones que escriben (`POST`, `PATCH`, `DELETE`, acciones) **cambian el estado** de la base de datos. Repetir una prueba puede dar otro resultado (p. ej. la segunda matrícula del mismo alumno devuelve `409`). Para volver a los datos iniciales, **reinicia el servidor** o guarda cualquier fichero.

> **Solo un servidor a la vez.** Si ya hay un `cds watch` en marcha (en una terminal o desde la tarea de `tasks.json`), un segundo arranque se queda parado en:
> ```
> [EADDRINUSE] - port 4004 is already in use by another server process.
> > Press Return to restart with an arbitrary port.
> ```
> Para el primero con `Ctrl+C` antes de lanzar otro.

---

## 3. Cómo funciona REST Client

| Elemento | Para qué sirve |
|---|---|
| `###` | **Separa peticiones.** Sin él, REST Client mete en el cuerpo todo lo que hay hasta el siguiente `###`, incluida la línea de la petición siguiente. |
| `Send Request` | Enlace que aparece encima de cada petición. La respuesta se abre en un panel a la derecha: código de estado en la primera línea, JSON debajo. |
| `@host = ...` | Variable de fichero. Se usa como `{{host}}`. Permite cambiar de `localhost` a la URL de BAS en un solo sitio. |
| `# @name x` | Da nombre a una petición para reutilizar su respuesta: `{{x.response.body.ID}}`. |
| `Authorization: {{admin}}` | Indica con qué usuario se envía la petición. Va **justo debajo de la URL**, junto a las demás cabeceras. Sin ella, la respuesta es `401`. |
| Línea en blanco | Obligatoria entre las cabeceras y el cuerpo JSON. |

Estructura de una petición:

```http
### Comentario descriptivo
POST {{host}}/Students
Authorization: {{admin}}
Content-Type: application/json

{
    "name" : "Juan"
}
```

> Las líneas que empiezan por `###` también sirven de comentario: aprovéchalas para anotar **qué debe devolver** cada petición.

### Usuarios de prueba

El servicio exige un usuario identificado y `package.json` usa `"kind": "mocked"`, así que cada petición debe indicar uno. Se definen una vez al principio del fichero como `Basic <usuario>:<contraseña>`:

```http
@admin = Basic admin:p
@profe = Basic profe:p
@alumno = Basic ana.garcia@students.example.edu:p
```

| Variable | Rol | Qué puede hacer |
|---|---|---|
| `{{admin}}` | `Admin` | Leer, crear y borrar `Students`; todo en `Courses`, `Subjects`, `Enrollments` y `Grades`; llamar a `enroll` y `studentsHasPassed`. |
| `{{profe}}` | `Profesor` | Leer y editar `Students` y `Grades`; leer `Enrollments`; llamar a `studentsHasPassed`. |
| `{{alumno}}` | `Alumno` (Ana) | Leer solo su registro de `Students`; leer `Courses`, `Subjects` y `PublicStudents`. |

| Código | Significado |
|---|---|
| `401` | No se ha identificado al usuario: falta la cabecera, o el usuario o la contraseña no coinciden con `package.json`. |
| `403` | El usuario se ha identificado, pero su rol no tiene permiso. |

---

## 4. Sintaxis OData que hay que conocer

| Operación | Sintaxis correcta | Error típico |
|---|---|---|
| Leer una entidad por clave | `GET /Students(<ID>)` | — |
| Borrar | `DELETE /Students(<ID>)` — **sin cuerpo** | Mandar el `ID` en el cuerpo |
| Llamar a una **función** (`function`) | `GET /studentsHasPassed(courseID=<ID>)` — parámetros **con nombre** en la URL | `(<ID>)` sin nombre → el parámetro llega `undefined` |
| Llamar a una **acción** (`action`) | `POST /enroll` con los parámetros en el cuerpo JSON | Usar `GET` |
| Asociaciones en el cuerpo | Clave externa `<asociación>_<clave>`: `student_ID`, `course_ID` | `studentID` → `Property "studentID" does not exist` |
| Expandir asociaciones | `GET /Enrollments?$filter=course_ID eq <ID>&$expand=student` | `GET /Courses?$expand=students`: esa asociación no está en el servicio (ver la nota siguiente) |

> **Parámetros de acción ≠ campos de entidad.** `studentID` y `courseID` son los parámetros declarados en `action enroll(...)`; solo valen en `POST /enroll`. Para insertar directamente en `/Enrollments` se usan los campos del modelo: `student_ID`, `course_ID`.

> **`Courses` no expone `students` a propósito.** `@restrict` se comprueba en la entidad de la URL, no en las expandidas. Con esa asociación, un alumno podría leer el email y la nota de sus compañeros mediante `Courses?$expand=students($expand=student)`. Por eso la proyección usa `excluding { students }`. Para ver los alumnos de un curso, usa `Enrollments` con un usuario `{{profe}}` o `{{admin}}`.

> Una petición `GET` **ignora el cuerpo**. Si un `GET` tiene JSON debajo, sobra.

---

## 5. Batería de pruebas

Esta batería es la de `test-odata.http`. Cubre cada handler de `srv/harvard-service.js` y los permisos del servicio. Envía las peticiones **en orden**: las de `enroll` y la del rollback dependen de las anteriores. Para repetir la serie, reinicia el servidor.

Las peticiones 1–12 usan `{{admin}}` para probar la lógica sin que interfieran los permisos; las 13–16 comprueban los permisos.

```http
@host = http://localhost:4004/odata/v4/harvard
@admin = Basic admin:p
@profe = Basic profe:p
@alumno = Basic ana.garcia@students.example.edu:p

### ─── 6.2.1 after READ ──────────────────────────────
### 1. Listar alumnos → 200, cada uno con "estado" (Aprobado / Suspenso / Pendiente)
GET {{host}}/Students
Authorization: {{admin}}

### ─── 6.2.1 before CREATE ───────────────────────────
### 2. Datos inválidos → el resultado depende de las validaciones activas (ver la tabla siguiente)
POST {{host}}/Students
Authorization: {{admin}}
Content-Type: application/json

{
    "name" : " ",
    "email" : "sin-arroba",
    "age" : 16
}

### 3. Alumno válido → 201 (guarda el ID para la petición 4)
# @name createStudent
POST {{host}}/Students
Authorization: {{admin}}
Content-Type: application/json

{
    "name" : "Juan",
    "surname" : "Ignacio",
    "email" : "juan.ignacio@example.edu",
    "age" : 20
}

### 4. Borrar el alumno creado en la 3 → 204
DELETE {{host}}/Students({{createStudent.response.body.ID}})
Authorization: {{admin}}

### ─── 6.2.2 studentsHasPassed ───────────────────────
### 5. Aprobados de Economics → 200 con Luis y Emma
GET {{host}}/studentsHasPassed(courseID=11111111-1111-1111-1111-000000000002)
Authorization: {{admin}}

### 6. Curso inexistente → 404 "Curso no encontrado"
GET {{host}}/studentsHasPassed(courseID=11111111-1111-1111-1111-000000000099)
Authorization: {{admin}}

### ─── 6.2.3-4 enroll ────────────────────────────────
### 7. Matricular a Emma en Computer Science → 200 success: true
POST {{host}}/enroll
Authorization: {{admin}}
Content-Type: application/json

{
    "studentID" : "44444444-4444-4444-4444-000000000003",
    "courseID" : "11111111-1111-1111-1111-000000000001"
}

### 8. Repetir la 7 → 409 "El alumno ya está matriculado en este curso"
POST {{host}}/enroll
Authorization: {{admin}}
Content-Type: application/json

{
    "studentID" : "44444444-4444-4444-4444-000000000003",
    "courseID" : "11111111-1111-1111-1111-000000000001"
}

### 9. Alumno inexistente → 404 "Alumno no encontrado"
POST {{host}}/enroll
Authorization: {{admin}}
Content-Type: application/json

{
    "studentID" : "44444444-4444-4444-4444-000000000099",
    "courseID" : "11111111-1111-1111-1111-000000000001"
}

### ─── Rollback (UNIQUE en Grades) ───────────────────
### 10. Preparar: Ana ya tiene nota en Microeconomics → 201
POST {{host}}/Grades
Authorization: {{admin}}
Content-Type: application/json

{
    "grade" : 6,
    "student_ID" : "44444444-4444-4444-4444-000000000001",
    "subject_ID" : "22222222-2222-2222-2222-000000000003"
}

### 11. Matricular a Ana en Economics → 409 "El alumno ya tiene nota en alguna asignatura de este curso"
POST {{host}}/enroll
Authorization: {{admin}}
Content-Type: application/json

{
    "studentID" : "44444444-4444-4444-4444-000000000001",
    "courseID" : "11111111-1111-1111-1111-000000000002"
}

### 12. Comprobar el rollback → 200 con UNA sola matrícula (Computer Science), no Economics
GET {{host}}/Enrollments?$filter=student_ID eq 44444444-4444-4444-4444-000000000001
Authorization: {{admin}}

### ─── 6.1.4 Permisos ────────────────────────────────
### 13. El alumno solo ve su registro → 200 con 1 fila (Ana)
GET {{host}}/Students
Authorization: {{alumno}}

### 14. El alumno no puede crear alumnos → 403
POST {{host}}/Students
Authorization: {{alumno}}
Content-Type: application/json

{
    "name" : "Prueba",
    "email" : "prueba@example.edu",
    "age" : 20
}

### 15. El profesor consulta los aprobados → 200
GET {{host}}/studentsHasPassed(courseID=11111111-1111-1111-1111-000000000002)
Authorization: {{profe}}

### 16. Sin usuario → 401
GET {{host}}/Students
```

### Peticiones 2 y 3: dependen de las validaciones activas

Los dos handlers `before('CREATE', 'Students')` de `srv/harvard-service.js` pueden estar comentados. El resultado cambia según cuáles estén activos:

| Validaciones activas | Petición 2 (datos inválidos) | Petición 3 (`juan.ignacio@example.edu`) |
|---|---|---|
| Ninguna | `201`: **el alumno se crea sin validar** | `201` |
| Solo 6.2.1 (nombre, email, edad) | `400` con 3 errores en `details` (`name`, `email`, `age`) | `201` |
| Solo 6.3.2 (EmailVerifier) | `400` `Email no válido` | Según la API real: `400` si no da el email como `valid`. Usa una dirección real. |

Si la petición 3 no devuelve `201`, la petición 4 también falla, porque usa su `ID`.

### Qué comprueba cada bloque

| Ejercicio | Peticiones | Qué demuestra |
|---|---|---|
| 6.2.1 after READ | 1 | El handler `after('READ')` añade `estado` a cada alumno según `finalGrade`. |
| 6.2.1 before CREATE | 2–4 | Con el handler activo, `req.error()` acumula los errores: **un solo 400** con los tres campos inválidos. Un alumno válido sí se crea y se puede borrar. |
| 6.2.2 | 5–6 | La función filtra por matrícula y `finalGrade >= 5`; un curso inexistente da 404. |
| 6.2.3–4 | 7–9 | Matrícula correcta, duplicada (409) y con alumno inexistente (404). |
| Rollback | 10–12 | Si falla un paso de `enroll` (el `INSERT` de notas choca con `@assert.unique`), CAP **deshace también la matrícula** ya insertada. La petición 12 lo confirma. |
| 6.1.4 Permisos | 13–16 | `where: 'email = $user'` limita al alumno a su registro; sin permiso se recibe `403`, y sin usuario, `401`. |

### IDs de los datos de prueba

| Prefijo | Entidad | Ejemplos |
|---|---|---|
| `11111111-…` | Courses | `…001` Computer Science, `…002` Economics |
| `22222222-…` | Subjects | `…001` Algorithms, `…002` Databases, `…003` Microeconomics, `…004` Statistics |
| `33333333-…` | Grades | `…001` – `…010` |
| `44444444-…` | Students | `…001` Ana, `…002` Luis, `…003` Emma, `…004` Kenji |

> Probar contra BAS desde el navegador o REST Client: cambia solo la variable
> `@host = https://port4004-<tu-workspace>.<región>.trial.applicationstudio.cloud.sap/odata/v4/harvard`

---

## 6. Depurar con breakpoints

Para que la ejecución se pare en `harvard-service.js` al enviar una petición, el servidor debe arrancarse **con el depurador**, no desde la terminal.

**VS Code solo lee el `launch.json` de la carpeta abierta como workspace.** En BAS el workspace suele ser `/home/user/projects`, así que la configuración va en `/home/user/projects/.vscode/launch.json` con el `cwd` apuntando al proyecto:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "cds watch (servicios_y_logica)",
            "type": "node",
            "request": "launch",
            "cwd": "${workspaceFolder}/sap_btp_course_notes/modulo_6_-_definicion_de_servicios_odata/servicios_y_logica",
            "runtimeExecutable": "cds",
            "args": ["watch"],
            "console": "integratedTerminal",
            "skipFiles": ["<node_internals>/**"]
        }
    ]
}
```

Pasos:

1. Para cualquier otro `cds watch` en marcha.
2. Run and Debug → elige `cds watch (servicios_y_logica)` → ▶.
3. Pon un breakpoint **dentro del cuerpo** de un handler, nunca en la línea `this.on(...)` (ver [7.3](#73-registro-vs-ejecución-dónde-poner-los-breakpoints)). Por ejemplo, la línea `const { studentID, courseID } = req.data;` de `enroll`.
4. Envía la petición correspondiente desde `test.http`. La ejecución se para y puedes inspeccionar `req.data`.

> **No configures `"program": ".../srv/harvard-service.js"`.** Ese fichero es un handler que CAP carga, no un programa: Node lo ejecuta, define la clase y termina sin arrancar ningún servidor.

---

## 7. Uso del depurador

### 7.1 La barra de depuración

Cuando el depurador está activo aparece una barra flotante con estos controles:

| Botón | Atajo | Qué hace |
|---|---|---|
| **Continue** ▶ | `F5` | Reanuda la ejecución hasta el siguiente breakpoint. Si no hay ninguno más en el camino, la petición termina y REST Client recibe la respuesta. |
| **Pause** ⏸ | `F6` | Detiene la ejecución en el punto en que esté. Con el servidor en reposo (esperando peticiones) se para dentro del bucle de eventos de Node, sin nada útil que ver: pulsa Continue. Solo sirve para cazar un bucle infinito o un proceso colgado. |
| **Step Over** ↷ | `F10` | Ejecuta la línea actual **completa** y se para en la siguiente del mismo fichero. Si la línea llama a una función, la ejecuta entera sin entrar en ella. Es el paso que más se usa. |
| **Step Into** ↓ | `F11` | Si la línea llama a una función, **entra** en ella y se para en su primera línea. Útil para entrar en un callback propio (p. ej. el `s => ({...})` del `subjects.map`). En llamadas a CAP (`SELECT`, `INSERT`) te lleva al código de `node_modules`: sal con Step Out. |
| **Step Out** ↑ | `Shift+F11` | Termina la función actual y se para en la línea que la llamó. Sirve para salir de una función en la que has entrado sin querer. |
| **Restart** ⟲ | `Ctrl+Shift+F5` | Para y vuelve a lanzar la configuración entera: reinicia `cds watch`, y con él la base de datos en memoria (**se pierden los datos creados**). |
| **Stop** ■ | `Shift+F5` | Termina la sesión y el servidor. El puerto 4004 queda libre. |

> En BAS (VS Code en el navegador), si un atajo no responde o lo intercepta el navegador (`F5` puede recargar la página si el foco no está en el editor), usa los botones de la barra.

### 7.2 Los paneles de Run and Debug

| Panel | Para qué sirve |
|---|---|
| **VARIABLES** | Valores de las variables en el punto de pausa. *Local* muestra las del handler (`req`, `studentID`, `student`…); *Closure* las de `init()` capturadas por el handler (`Students`, `Courses`…). Despliega `req` → `data` para ver lo que llegó en la petición. |
| **WATCH** | Expresiones que quieres vigilar en cada paso, p. ej. `req.data`, `subjects.length`. Se recalculan en cada parada. |
| **CALL STACK** | Cadena de llamadas hasta la línea actual. Arriba del todo, tu handler; debajo, el código de CAP que lo invocó. Muestra *"Paused on breakpoint"*, *"Paused on step"* o *"Paused on exception"*. |
| **BREAKPOINTS** | Lista de breakpoints: activarlos/desactivarlos con la casilla sin borrarlos, y las opciones de excepciones (*Caught* / *Uncaught Exceptions*). |
| **DEBUG CONSOLE** | Evalúa expresiones en el contexto de la pausa: escribe `req.data`, `student.name` o `subjects.map(s => s.ID)` y pulsa Enter. |

> También puedes **pasar el ratón** sobre una variable en el editor para ver su valor sin ir al panel.

### 7.3 Registro vs. ejecución: dónde poner los breakpoints

Cada handler tiene dos momentos distintos:

```js
this.on('enroll', async (req) => {             // ← REGISTRO: se ejecuta UNA vez, al ARRANCAR el servidor
    const { studentID, courseID } = req.data;  // ← EJECUCIÓN: se ejecuta en CADA petición
    ...
})
```

- La línea `this.on(...)` / `this.before(...)` / `this.after(...)` solo **registra** el handler. Se ejecuta dentro de `init()`, **antes** de que el servidor empiece a escuchar.
- El cuerpo de la función flecha `(req) => { ... }` es lo que se ejecuta **al llegar una petición**.

Un breakpoint en una línea de registro pausa el servidor durante el arranque: el servidor no llega a escuchar en el 4004 y REST Client responde *"The connection was rejected"*. Además, `cds watch` reinicia el servidor cada vez que guardas, así que vuelve a pararse en cada reinicio.

En `srv/harvard-service.js`:

| Handler | ❌ Línea de registro (arranque) | ✅ Primera línea del cuerpo (petición) |
|---|---|---|
| `before CREATE Students` | `this.before('CREATE', 'Students', ...)` | `const {name, email, age} = req.data;` |
| `after READ Students` | `this.after('READ', 'Students', ...)` | `const list = Array.isArray(students) ? ...` |
| `studentsHasPassed` | `this.on('studentsHasPassed', ...)` | `const { courseID } = req.data;` |
| `enroll` | `this.on('enroll', ...)` | `const { studentID, courseID } = req.data;` |

> Lo mismo aplica a `const { Students, Courses, Subjects } = this.entities;` y a `await super.init();`: se ejecutan al arrancar.

### 7.4 Cómo interpretar los pasos

- **La línea resaltada en amarillo es la siguiente que se va a ejecutar, no la última ejecutada.** Si estás parado en `const student = await SELECT...`, la variable `student` todavía es `undefined`; tras un Step Over ya tiene el valor.
- **`await` y Step Over.** En una línea con `await`, Step Over espera a que termine la consulta y se para en la línea siguiente con el resultado ya asignado. No hace falta entrar en la consulta para ver qué devolvió: mira la variable en VARIABLES.
- **Un `return` termina el handler.** Si haces Step Over sobre `return req.reject(404, ...)` o sobre el `return { success: true, ... }`, el depurador sale de tu código (verás código de CAP en CALL STACK o la ejecución sigue sola). Pulsa Continue: CAP envía la respuesta y REST Client la muestra.
- **`req.reject()` y `throw` saltan.** Desde ahí la ejecución no sigue a la línea siguiente: va al `catch` más cercano o sale del handler. En `enroll`, si falla el `INSERT` de notas, el siguiente paso te lleva directamente a la primera línea del `catch`.
- **Las condiciones muestran el camino.** En un `if (!student) return req.reject(...)`, si Step Over salta a la línea siguiente al `if`, la condición era falsa (el alumno existe). Si entra en el `return`, era verdadera.
- **Los comentarios y las líneas vacías no se ejecutan**: el depurador los salta.

### 7.5 Tipos de breakpoint

Clic derecho en el margen izquierdo del editor (junto al número de línea):

| Tipo | Cómo se crea | Cuándo usarlo |
|---|---|---|
| **Breakpoint** ● | Clic en el margen | Parar siempre en esa línea. |
| **Conditional Breakpoint** | *Add Conditional Breakpoint…* → *Expression* | Parar solo si se cumple una condición, p. ej. `studentID === '44444444-4444-4444-4444-000000000001'` para depurar solo las peticiones de Ana. |
| **Hit Count** | *Add Conditional Breakpoint…* → *Hit Count* | Parar a partir de la N-ésima vez que se pasa por la línea, p. ej. dentro de un bucle. |
| **Logpoint** ◆ | *Add Logpoint…* | **No para**: escribe un mensaje en DEBUG CONSOLE, p. ej. `Matriculando {studentID} en {courseID}`. Como un `console.log` sin tocar el código. |
| **Excepciones** | Panel BREAKPOINTS → *Uncaught Exceptions* | Parar justo donde se lanza un error no capturado (p. ej. un `ReferenceError`). Evita *Caught Exceptions*: se para también en errores internos que CAP gestiona y en el arranque. |

> Para dejar de parar sin perder los breakpoints, desmárcalos en el panel BREAKPOINTS o usa *Toggle Activate Breakpoints* en la cabecera del panel.

### 7.6 Qué pasa con la petición mientras estás en pausa

- REST Client se queda **esperando la respuesta**. No la recibe hasta que la ejecución termine (Continue o pasos hasta el final del handler).
- Si **guardas un fichero** mientras estás en pausa, `cds watch` reinicia el servidor: la sesión pausada se pierde, la petición falla y la base de datos en memoria vuelve a los CSV.
- **Stop** con una petición en pausa también corta la petición.

### 7.7 Ejemplo: depurar el rollback de `enroll`

1. Breakpoint en la primera línea del cuerpo de `enroll` (`const { studentID, courseID } = req.data;`) y otro en la primera línea del `catch` (`if (/unique constraint/i.test(error.message))`).
2. Envía las peticiones **10** y **11** de la [batería de pruebas](#5-batería-de-pruebas).
3. Se para en el cuerpo. En VARIABLES, despliega `req` → `data`: deben llegar `studentID` y `courseID` de Ana y Economics.
4. Step Over línea a línea: `student` y `course` toman valor; `already` queda `undefined` (Ana no estaba matriculada en Economics), así que el `if` no entra.
5. Step Over sobre `INSERT.into(Enrollments)`: la matrícula se inserta **dentro de la transacción**.
6. Continue: el `INSERT` de notas falla por `@assert.unique` y se para en el `catch`. En DEBUG CONSOLE escribe `error.message` → `UNIQUE constraint failed: ...`.
7. Step Over: entra en el `if` y llega al `return req.reject(409, ...)`.
8. Continue: CAP deshace la transacción (incluida la matrícula del paso 5) y REST Client recibe el `409`.
9. Envía la petición **12** para confirmar que la matrícula no quedó guardada.

---

## 8. Errores frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `The connection was rejected... RequestError` | URL mal formada, p. ej. `localhost:4004odata` (falta `/`), o servidor parado | Revisa la URL; comprueba que `cds watch` está en marcha |
| `Unexpected non-whitespace character after JSON at position N` | Falta `###` entre peticiones: la línea de la siguiente petición entra en el cuerpo | Separa cada petición con `###` |
| `Property "studentID" does not exist in HarvardService.Enrollments` | Parámetros de la acción usados como campos de la entidad | En entidades usa `student_ID` / `course_ID`; o llama a `POST /enroll` |
| `Navigation property "students" is not defined in HarvardService.Courses` | `Courses` excluye esa asociación a propósito, para que un alumno no pueda leer datos de sus compañeros | Usa `GET /Enrollments?$filter=course_ID eq <ID>&$expand=student` con `{{profe}}` o `{{admin}}` |
| `Navigation property "x" does not exist in "Y"` con otra asociación | La entidad destino de la asociación no está expuesta en el servicio | Expón esa entidad con una proyección en `srv/harvard-service.cds` |
| `401 Unauthorized` | Falta `Authorization`, o el usuario o la contraseña no coinciden con `package.json` | Añade `Authorization: {{admin}}` justo debajo de la URL, sin línea en blanco entre medias |
| `403 Forbidden` | El rol del usuario no tiene permiso para esa operación | Esperado si pruebas permisos; si no, usa un usuario con el rol adecuado |
| La función devuelve "no encontrado" con un ID que existe | Parámetro posicional: `studentsHasPassed(<ID>)` | Usa nombre: `studentsHasPassed(courseID=<ID>)` |
| `500` + `ReferenceError: x is not defined` + `server shutdown` | Error de JavaScript en un handler (variable mal escrita). En desarrollo CAP apaga el servidor ante errores no capturados | Corrige el handler; `cds watch` reinicia al guardar |
| `"title" not found in the elements of ...` | Columna inexistente en una consulta CQL | Revisa los nombres en `db/schema.cds` |
| `UNIQUE constraint failed` | Violación de `@assert.unique` (mensaje de la base de datos) | Esperado si pruebas duplicados; tradúcelo con `try/catch` + `req.reject(409, ...)` |
| `Enter a value between 0 and 10.` (`ASSERT_RANGE`) | Valor fuera de `@assert.range` | Esperado: la validación funciona |
| Run and Debug no hace nada | Puerto 4004 ocupado, o VS Code lee otro `launch.json` | Ver [sección 2](#2-arrancar-el-servidor) y [sección 6](#6-depurar-con-breakpoints) |
| Run and Debug arrancado, pero REST Client da `The connection was rejected` | Un breakpoint en una línea de **registro** (`this.on(...)`, `this.before(...)`…) pausa el servidor durante el arranque, antes de escuchar en el 4004 | Pulsa Continue y mueve el breakpoint dentro del cuerpo del handler. Ver [7.3](#73-registro-vs-ejecución-dónde-poner-los-breakpoints) |
| Las reglas de `@restrict` no se aplican | `auth.kind: "dummy"` en `package.json` desactiva las comprobaciones de roles | Usa `"kind": "mocked"` con usuarios de prueba |

---

## 9. Pruebas manuales vs. automáticas

| | `test.http` | `cds.test` + `node --test` |
|---|---|---|
| Quién comprueba el resultado | Tú, mirando cada respuesta | Las aserciones del test |
| Necesita servidor arrancado | Sí (`cds watch`) | No: arranca uno en memoria y lo apaga |
| Estado entre ejecuciones | Se acumula hasta reiniciar | Limpio en cada ejecución |
| Comprobar la base de datos (p. ej. rollback) | Con una petición `GET` adicional | Directamente con `SELECT` |
| Ideal para | Explorar la API mientras desarrollas | Detectar regresiones tras cada cambio |

Son complementarios: `test.http` para probar mientras escribes un handler, tests automáticos para asegurarte de que lo que ya funcionaba sigue funcionando.
