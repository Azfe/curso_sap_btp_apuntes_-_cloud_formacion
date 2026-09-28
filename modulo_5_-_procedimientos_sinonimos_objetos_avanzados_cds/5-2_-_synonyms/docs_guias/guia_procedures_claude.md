# Procedure en Harvard que lee de Cambridge mediante synonyms

Objetivo: el procedure `SyncAlumnoCambridge`, desplegado en el contenedor HDI de **Harvard**, lee la nota final de un alumno en **Cambridge** a través de un synonym y la escribe en la tabla de Harvard.

Es la misma configuración que ya funciona en Cambridge (Cambridge → Harvard), pero en la dirección contraria: **Harvard lee de Cambridge**.

## Índice

1. [Orden de trabajo](#orden-de-trabajo)
2. [Cambridge: exponer la tabla](#cambridge-exponer-la-tabla)
3. [Harvard: synonym, grants y mta.yaml](#harvard-synonym-grants-y-mtayaml)
4. [Probar el procedure](#probar-el-procedure)
5. [Si algo falla](#si-algo-falla)
6. [Referencia: ficheros finales en Harvard](#referencia-ficheros-finales-en-harvard)

---

## Orden de trabajo

1. **Cambridge** expone su tabla (roles) y **se despliega primero**.
2. **Harvard** crea el synonym, pide permisos (grants) y enlaza el servicio `cambridge-db` en su `mta.yaml`.
3. Se despliega Harvard y se prueba el procedure.

---

## Cambridge: exponer la tabla

### Paso 1 — Rol para el usuario de la aplicación

Crea `cambridge/db/src/external_access.hdbrole`:

```json
{
    "role": {
        "name": "external_access",
        "object_privileges": [
            { "name": "UNI_CAMBRIDGE_STUDENTS", "type": "TABLE", "privileges": ["SELECT"] }
        ]
    }
}
```

Este rol lo recibe el **usuario de la aplicación de Harvard**, que ejecuta el procedure. El procedure es `SQL SECURITY INVOKER`, así que se ejecuta con los permisos de quien lo llama.

### Paso 2 — Rol con grant option para el owner

Crea `cambridge/db/src/external_access#.hdbrole`:

```json
{
    "role": {
        "name": "external_access#",
        "object_privileges": [
            { "name": "UNI_CAMBRIDGE_STUDENTS", "type": "TABLE", "privileges_with_grant_option": ["SELECT"] }
        ]
    }
}
```

Este rol lo recibe el **object owner de Harvard**. Lo necesita para poder crear el synonym y el procedure sobre una tabla que no es suya. El `#` al final del nombre es la convención para los roles con grant option.

### Paso 3 — Registrar el plug-in de roles

`cambridge/db/src/.hdiconfig` no incluye `hdbrole`. Añádelo:

```json
"hdbrole": { "plugin_name": "com.sap.hana.di.role" },
```

Revisa las comas: la última entrada no debe llevarla.

### Paso 4 — Desplegar Cambridge

```bash
cd cambridge
mbt build
cf deploy mta_archives/Cambridge_1.0.0.mtar
```

> Es obligatorio que Cambridge esté desplegado antes que Harvard. Si los roles no existen todavía en `cambridge-db`, los grants de Harvard fallarán.

---

## Harvard: synonym, grants y mta.yaml

### Paso 5 — `cambridge.hdbgrants`

Crea `harvard/db/src/cambridge.hdbgrants`:

```json
{
    "cambridge-db": {
      "object_owner":     { "container_roles": ["external_access#"] },
      "application_user": { "container_roles": ["external_access"] }
    }
}
```

La clave `"cambridge-db"` debe coincidir con el `key` de `SERVICE_REPLACEMENTS` del paso 8.

### Paso 6 — `cambridge.hdbsynonym`

Crea `harvard/db/src/cambridge.hdbsynonym`:

```json
{
    "HARVARD_CAMBRIDGE_STUDENT": { "target": { "object": "UNI_CAMBRIDGE_STUDENTS" } }
}
```

La clave es el nombre local del synonym dentro de Harvard. Tiene que ser exactamente el nombre que usa el procedure en su `FROM`.

### Paso 7 — `cambridge.hdbsynonymconfig`

Crea `harvard/db/src/cambridge.hdbsynonymconfig`:

```json
{
    "HARVARD_CAMBRIDGE_STUDENT": {
        "target": { "object": "UNI_CAMBRIDGE_STUDENTS", "schema.configure": "cambridge-db/schema" }
    }
}
```

El nombre del schema del contenedor de Cambridge es un hash que no conoces de antemano. `schema.configure` hace que se rellene al desplegar, tomándolo de las credenciales del servicio `cambridge-db`.

### Paso 8 — `mta.yaml`

Haz tres cambios, igual que en el `mta.yaml` de Cambridge.

**a)** En el módulo `harvard-db-deployer`, sustituye el bloque `requires`:

```yaml
  - name: harvard-db-deployer
    type: hdb
    path: gen/db
    parameters:
      instances: 1
      buildpack: nodejs_buildpack
    requires:
      - name: harvard-db
        properties:
          TARGET_CONTAINER: ~{hdi-container-service}
      - name: cambridge-db
        group: SERVICE_REPLACEMENTS
        properties:
          key: cambridge-db
          service: ~{cambridge-db-service}
```

**b)** En el recurso `harvard-db`, añade `properties`:

```yaml
  - name: harvard-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared
    properties:
      hdi-container-service: ${service-name}
```

Ahora el deployer de Harvard está enlazado a dos contenedores. `TARGET_CONTAINER` le indica en cuál tiene que desplegar.

**c)** Añade el recurso de Cambridge como servicio existente:

```yaml
  - name: cambridge-db
    type: org.cloudfoundry.existing-service
    parameters:
      service-name: cambridge-db
    properties:
      cambridge-db-service: ${service-name}
```

Comprueba el nombre real del servicio con `cf services`. Si no se llama `cambridge-db`, cambia `service-name`.

### Paso 9 — Desplegar Harvard

```bash
cd harvard
mbt build
cf deploy mta_archives/Harvard_1.0.0.mtar
```

Prueba primero así, sin `.mtaext`. Como `cambridge-db` es un `existing-service`, `cf deploy` enlaza el servicio y el deployer recibe las credenciales por ese binding. Si funciona, no necesitas el paso 9b.

### Paso 9b (opcional) — `cfg/cambridge-db.mtaext`

Solo hace falta si el deploy falla al resolver `cambridge-db`. Es el equivalente de `cambridge/cfg/harvard-db.mtaext`, pero con las credenciales del **otro** contenedor.

**1. Ignorarlo en git antes de rellenarlo**, porque contiene contraseñas. En `harvard/.gitignore`:

```
cfg/*.mtaext
```

Compruébalo con `git check-ignore -v cfg/cambridge-db.mtaext`.

**2. Obtener las credenciales** de una service key de `cambridge-db` (no de `harvard-db`):

```bash
cf service-keys cambridge-db                           # lista las keys existentes
cf create-service-key cambridge-db cambridge-db-key    # solo si no hay ninguna
cf service-key cambridge-db <nombre-de-la-key>
```

**3. Crear `harvard/cfg/cambridge-db.mtaext`.** Respecto al fichero de Cambridge cambian estos campos:

| Campo | Cambridge (`harvard-db.mtaext`) | Harvard (`cambridge-db.mtaext`) |
|---|---|---|
| `ID` | `Cambridge.harvard-db.config` | `Harvard.cambridge-db.config` |
| `extends` | `Cambridge` (el `ID` de su `mta.yaml`) | `Harvard` |
| `resources[].name` | `harvard-db` | `cambridge-db` |
| Valores de `config` | Service key de `harvard-db` | Service key de `cambridge-db` |

```yaml
_schema-version: '3.3.0'
ID: Harvard.cambridge-db.config
extends: Harvard
resources:
  - name: cambridge-db
    parameters:
      config:
        certificate: "<de la service key>"
        database_id: "<de la service key>"
        driver: "com.sap.db.jdbc.Driver"
        hdi_password: "<de la service key>"
        hdi_user: "<de la service key>"
        host: "<de la service key>"
        password: "<de la service key>"
        port: "443"
        schema: "<de la service key>"
        type: "hdi"
        tags:
          - hana
          - password
        url: "<de la service key>"
        user: "<de la service key>"
```

- La service key **no** trae `type` ni `tags`: añádelos a mano como arriba, igual que en el fichero de Cambridge.
- Comprobación: el `schema` debe ser **distinto** del que aparece en `cambridge/cfg/harvard-db.mtaext`. Si coinciden, has copiado la key del contenedor equivocado.

**4. Desplegar pasándolo con `-e`.** Si no se pasa, el fichero no se aplica:

```bash
cf deploy mta_archives/Harvard_1.0.0.mtar -e cfg/cambridge-db.mtaext
```

---

## Probar el procedure

### Dónde ejecutarlo

En el **SAP HANA Database Explorer**, conectado al **contenedor HDI de Harvard** (`harvard-db`). Si te conectas al contenedor de Cambridge o como `DBADMIN`, dará `invalid procedure name`.

- **Desde BAS:** panel **SAP HANA PROJECTS** → `harvard` → `db` → **Open HDI Container** → **Open SQL Console**.
- **Desde el BTP Cockpit:** SAP HANA Cloud → **Actions → Open in SAP HANA Database Explorer** → **+** → *Database Type: HDI Container* → `harvard-db` → clic derecho → **Open SQL Console**.

La conexión usa el usuario de runtime del contenedor (`…_RT`). Ese usuario recibe el rol `external_access` de Cambridge a través de `application_user` en el `.hdbgrants`, y por eso puede leer el synonym (el procedure es `SQL SECURITY INVOKER`).

> Alternativa sin escribir SQL: en el catálogo, **Procedures → SyncAlumnoCambridge** → clic derecho → **Generate CALL Statement with UI**.

### Datos de prueba

Hace falta un alumno con el **mismo email en los dos CSV** y notas distintas:

| Fichero | Fila |
|---|---|
| `harvard/db/data/uni.harvard.Students.csv` | `stu-005,Claudia,Tania,21,clau.tan@intercambio.com,80` |
| `cambridge/db/data/uni.cambridge.Students.csv` | `stu-005,Claudia,Tania,21,clau.tan@intercambio.com,100` |

### Caso correcto

```sql
CALL "SyncAlumnoCambridge"('clau.tan@intercambio.com', ?, ?);
```

Los `?` son los parámetros `OUT`; el resultado aparece en una pestaña en la parte inferior. Resultado obtenido:

| `OV_MENSAJE` | `OV_RETURNCODE` |
|---|---|
| `Nota sincronizada correctamente: 100` | `0` |

Comprobación: la nota de Harvard ha pasado de `80` a `100`, igual que en Cambridge.

```sql
-- Nota en Cambridge (vía synonym) y en Harvard: deben coincidir
SELECT 'Cambridge' AS ORIGEN, EMAIL, FINALGRADE FROM "HARVARD_CAMBRIDGE_STUDENT" WHERE EMAIL = 'clau.tan@intercambio.com'
UNION ALL
SELECT 'Harvard',             EMAIL, FINALGRADE FROM "UNI_HARVARD_STUDENTS"      WHERE EMAIL = 'clau.tan@intercambio.com';
```

### Casos de error

```sql
CALL "SyncAlumnoCambridge"('no.existe@nada.com', ?, ?);         -- esperado: 1
CALL "SyncAlumnoCambridge"('elena.fernandez@email.com', ?, ?);  -- esperado: 2 (solo está en Cambridge)
```

| `ov_returncode` | Significado |
|---|---|
| `0` | Nota sincronizada |
| `1` | El alumno no existe en Cambridge |
| `2` | El alumno existe en Cambridge pero no en Harvard |

> **La nota puede "volver atrás" tras redesplegar.** Los datos de los CSV los carga HDI al desplegar. Si en un despliegue posterior cambia `uni.harvard.Students.csv`, HDI recarga la tabla y la nota vuelve al valor del CSV (`80`), perdiendo el `UPDATE` del procedure. Basta con volver a ejecutar el `CALL`.

---

## Si algo falla

| Error | Causa probable |
|---|---|
| `insufficient privilege` en los grants | Cambridge no se desplegó con los roles (pasos 1 a 4). |
| `invalid table name HARVARD_CAMBRIDGE_STUDENT` | El nombre del synonym no coincide entre el `.hdbsynonym`, el `.hdbsynonymconfig` y el procedure. |
| `service cambridge-db not found` | El `service-name` del paso 8c no coincide con `cf services`. |
| El deploy crea objetos en el contenedor equivocado | Falta `TARGET_CONTAINER` (paso 8a). |
| El deploy no encuentra las credenciales de `cambridge-db` | Usa el `.mtaext` del paso 9b y despliega con `-e`. |
| Los grants fallan aun usando el `.mtaext` | Las credenciales son de `harvard-db` y no de `cambridge-db`: compara el `schema` de los dos ficheros. |

---

## Referencia: ficheros finales en Harvard

### `harvard/db/src/.hdiconfig`

Igual que en el vídeo tutorial, salvo `hdbgrants`: se usa `com.sap.hana.di.grants`, el mismo plug-in que en Cambridge, que ya despliega bien.

```json
{
  "file_suffixes": {
    "hdbtable":         { "plugin_name": "com.sap.hana.di.table" },
    "hdbview":          { "plugin_name": "com.sap.hana.di.view" },
    "hdbindex":         { "plugin_name": "com.sap.hana.di.index" },
    "hdbconstraint":    { "plugin_name": "com.sap.hana.di.constraint" },
    "hdbtabledata":     { "plugin_name": "com.sap.hana.di.tabledata" },
    "hdbsequence":      { "plugin_name": "com.sap.hana.di.sequence" },
    "hdbrole":          { "plugin_name": "com.sap.hana.di.role" },
    "hdbroleconfig":    { "plugin_name": "com.sap.hana.di.roleconfig" },
    "hdbgrants":        { "plugin_name": "com.sap.hana.di.grants" },
    "hdbsynonym":       { "plugin_name": "com.sap.hana.di.synonym" },
    "hdbsynonymconfig": { "plugin_name": "com.sap.hana.di.synonym.config" },
    "hdbprocedure":     { "plugin_name": "com.sap.hana.di.procedure" }
  }
}
```

### `harvard/db/src/procedures/SyncAlumnoCambridge.hdbprocedure`

```sql
PROCEDURE "SyncAlumnoCambridge"(
    IN iv_email NVARCHAR(100),
    OUT ov_mensaje NVARCHAR(200),
    OUT ov_returncode INTEGER
)

LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER AS 
BEGIN
    DECLARE lv_nota_cambridge INTEGER;
    DECLARE lv_count INTEGER;

    -- 1. Buscar alumno en Cambridge vía synonyms
    -- COUNT(*) siempre devuelve una fila: evita NO_DATA_FOUND (1299) y
    -- el error por varias filas (1300) si el email está duplicado
    SELECT COUNT(*), MAX(FINALGRADE)
    INTO lv_count, lv_nota_cambridge
    FROM "HARVARD_CAMBRIDGE_STUDENT"
    WHERE email = :iv_email;

    IF :lv_count = 0 THEN
        ov_mensaje := 'Alumno no encontrado en Cambridge: ' || :iv_email;
        ov_returncode := 1;
        RETURN;    
    END IF;

    -- 2. Actualizar FINALGRADE en Harvard con el valor de Cambridge
    UPDATE "UNI_HARVARD_STUDENTS"
    SET FINALGRADE = :lv_nota_cambridge
    WHERE email = :iv_email;

    -- ::ROWCOUNT sí es fiable tras un UPDATE
    IF ::ROWCOUNT = 0 THEN
        ov_mensaje := 'Alumno no encontrado en Harvard: ' || :iv_email;
        ov_returncode := 2;
        RETURN;    
    END IF;

    ov_mensaje := 'Nota sincronizada correctamente: ' || TO_NVARCHAR(:lv_nota_cambridge);
    ov_returncode := 0;
END;
```

> No añadas `READS SQL DATA` (como en el ejemplo `OrderCount` de la guía de SAP): este procedure hace un `UPDATE` y esa cláusula lo impediría.
