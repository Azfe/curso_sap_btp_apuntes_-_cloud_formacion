# Creación de procedimientos y funciones en SAP HANA Cloud

> **Fuente:** *SAP HANA Cloud, guía del desarrollador de la base de datos de SAP HANA para las aplicaciones multidestino de Cloud Foundry (SAP Business App Studio)* — SAP HANA Cloud, SAP HANA Database | QRC 1/2026.
> Contenido original: <https://help.sap.com/docs/HANA_CLOUD_DATABASE/c2b99f19e9264c4d9ae9221b22f6f589?locale=en-US&state=PRODUCTION&version=2026_1_QRC>
>
> El PDF es una traducción automática de SAP; la versión original en inglés tiene prioridad. Los ejemplos de código son ilustrativos y a veces están incompletos. Al final hay una sección de [erratas detectadas](#erratas-detectadas-en-el-pdf).

## Índice

1. [Introducción](#1-introducción)
2. [Crear el proyecto en SAP Business Application Studio](#2-crear-el-proyecto-en-sap-business-application-studio)
3. [Crear los artefactos de datos para un procedimiento](#3-crear-los-artefactos-de-datos-para-un-procedimiento)
4. [Crear un procedimiento de base de datos](#4-crear-un-procedimiento-de-base-de-datos)
5. [Crear una función de base de datos](#5-crear-una-función-de-base-de-datos)
6. [Erratas detectadas en el PDF](#erratas-detectadas-en-el-pdf)

---

## 1. Introducción

Los procedimientos y funciones de base de datos ayudan a gestionar el modelo de datos subyacente. Además de los artefactos en tiempo de diseño habituales (tablas, vistas…, definidos con SAP HANA Cloud DDL), se pueden crear **procedimientos** y **funciones escalares o de tabla** con **SQLScript**. Los procedimientos se usan, por ejemplo, para insertar datos en tablas o vistas, o para eliminarlos.

Cada artefacto tiene una extensión de fichero distinta, y **la extensión determina qué plug-in HDI** genera el objeto de catálogo correspondiente:

| Artefacto | Extensión | Ejemplo |
|---|---|---|
| Procedimiento | `.hdbprocedure` | `myProcedure.hdbprocedure` |
| Función escalar o de tabla | `.hdbfunction` | `myScalarFunction.hdbfunction` |
| Sinónimo | `.hdbsynonym` | `mySynonym.hdbsynonym` |

> **Consejo:** las funciones escalares y de tabla comparten la extensión `.hdbfunction` y el mismo plug-in HDI.

Se recomienda guardar procedimientos y funciones en una **carpeta separada** dentro del módulo `db/`:

```text
<MyAppName>
|- db/                              # Database deployment artifacts
|  |- package.json                  # Database details/dependencies
|  |- src/                          # Database artifacts: tables, views, etc.
|     |- .hdiconfig                 # HDI build plug-in configuration
|     |- .hdinamespace              # HDI run-time name-space configuration
|     |- data/
|     |  |- myTable.hdbtable        # HANA DDL table definition
|     |  \- myView.hdbview          # HANA DDL view definition
|     |
|     |- procedures                 # Database procedures, functions, ...
|        |- myProc.hdbprocedure     # Database procedure
|        \- myFunc.hdbfunction      # Database function
\- mtad.yaml
```

### Requisitos previos (comunes a todas las tareas)

- Acceso a un sistema SAP HANA Cloud en ejecución con el entorno Cloud Foundry instalado y configurado.
- SAP Business Application Studio (BAS) con la extensión **SAP HANA Native Application** en el espacio de desarrollo. En general sirve cualquier editor de texto para crear los artefactos.
- Un espacio de desarrollo y un proyecto de aplicación multidestino (MTA) creados.

---

## 2. Crear el proyecto en SAP Business Application Studio

La guía repite estos pasos al principio de cada tarea. Si ya tienes un proyecto, puedes saltártelos. También se puede crear un proyecto importándolo o clonándolo.

1. Inicia SAP Business Application Studio.
2. Abre la paleta de comandos (**Ver → Paleta de comandos…**, `Ctrl` + `Shift` + `P` o `F1`), escribe *Proyecto* y selecciona **Crear proyecto a partir de plantilla**.
   > Alternativa: en la pestaña *Bienvenida*, **Iniciar desde plantilla → Crear un nuevo proyecto**.
3. En el asistente, selecciona **Proyecto de base de datos SAP HANA** → **Iniciar**.
4. **Añadir información básica:** nombre del proyecto (p. ej. `myapp`) → **Siguiente**.
5. **Fijar propiedades básicas:** acepta los valores por defecto → **Siguiente**.
6. **Establecer información de base de datos:** valores por defecto → **Siguiente**.
   - Área de nombres: *(vacía)*
   - Nombre de esquema: *(vacío)*
   - Versión de base de datos SAP HANA: *HANA Cloud*
   - ¿Vincular el módulo de base de datos a una instancia de servicio de Cloud Foundry?: *Sí*
7. **Vincular a servicio de contenedor HDI:** inicia sesión en Cloud Foundry.
   - Correo electrónico y contraseña de un usuario registrado de Cloud Foundry → `Intro` o **Iniciar sesión**.
     > Si tienes 2FA configurado, puede que necesites un token de un solo uso.
   - Organización y espacio de Cloud Foundry: selecciónalos en el desplegable.
   - Servicio de Cloud Foundry: **Crear una nueva instancia de servicio**.
   - Nombre de instancia único (por defecto `<ProjectName>-hdidb-ws-<WorkspaceName>`).
     > Se recomienda aceptar el nombre por defecto. Vincularse a un servicio existente puede dar problemas porque se eliminarían (*undeploy*) ficheros de un despliegue anterior.
8. **Finalizar** para generar el proyecto en la organización y el espacio seleccionados.

---

## 3. Crear los artefactos de datos para un procedimiento

**Objetivo:** crear las tablas, vistas y tipos que usarán después los procedimientos y funciones, además de una secuencia para los IDs y unos datos iniciales.

### Paso 1. Crear el proyecto

Sigue la [sección 2](#2-crear-el-proyecto-en-sap-business-application-studio).

### Paso 2. Crear la carpeta de datos

En el módulo `db/`, crea la carpeta `src/data` (p. ej. `myapp/db/src/data`). Guardará tablas, tipos, vistas, secuencias, etc.

### Paso 3. Añadir las tablas

**a. Tabla cabecera:** `myapp/db/src/data/PurchaseOrderHeader.hdbtable`

```sql
COLUMN TABLE "PurchaseOrderHeader" (
      "PURCHASEORDERID" INTEGER GENERATED BY DEFAULT AS IDENTITY (NO CYCLE NO CACHE N...  -- línea cortada en el PDF, ver erratas
      "HISTORY.CREATEDBY" NVARCHAR(10) COMMENT 'Created By',
      "HISTORY.CREATEDAT" DATE COMMENT 'Created Date',
      "HISTORY.CHANGEDBY" NVARCHAR(10) COMMENT 'Changed By',
      "HISTORY.CHANGEDAT" DATE COMMENT 'Change Date',
      "NOTEID" NVARCHAR(10) COMMENT 'Notes',
      "PARTNER" NVARCHAR(10) COMMENT 'Supplier',
      "CURRENCY" NVARCHAR(5) COMMENT 'Currency',
      "GROSSAMOUNT" DECIMAL(15,2) COMMENT 'Gross Amount',
      "NETAMOUNT" DECIMAL(15,2) COMMENT 'Net Amount',
      "TAXAMOUNT" DECIMAL(15,2) COMMENT 'Tax Amount',
      "LIFECYCLESTATUS" NVARCHAR(1) COMMENT 'Lifecycle Status',
      "APPROVALSTATUS" NVARCHAR(1) COMMENT 'Approval Status',
      "CONFIRMSTATUS" NVARCHAR(1) COMMENT 'Confirmation Status',
      "ORDERINGSTATUS" NVARCHAR(1) COMMENT 'Ordering Status',
      "INVOICINGSTATUS" NVARCHAR(1) COMMENT 'Invoicing Status',
      PRIMARY KEY ("PURCHASEORDERID"))
      COMMENT 'Purchase Order Header'
      WITH ASSOCIATIONS( JOIN "PurchaseOrderItem" AS "ITEMS" ON "PURCHASEORDERID" = "ITEMS"."PURCHASEORDERID")  -- final reconstruido, ver erratas
      UNLOAD PRIORITY 5 AUTO MERGE
```

**b. Tabla posición:** `myapp/db/src/data/PurchaseOrderItem.hdbtable`

```sql
COLUMN TABLE "PurchaseOrderItem" (
      "PURCHASEORDERID" INTEGER NOT NULL COMMENT 'Purchase Order ID',
      "PURCHASEORDERITEM" INTEGER NOT NULL COMMENT 'Purchase Order Item',
      "PRODUCT" NVARCHAR(10) NOT NULL COMMENT 'Product ID',
      "NOTEID" NVARCHAR(10) COMMENT 'Notes',
      "CURRENCY" NVARCHAR(5) COMMENT 'Currency',
      "GROSSAMOUNT" DECIMAL(15,2) COMMENT 'Gross Amount',
      "NETAMOUNT" DECIMAL(15,2) COMMENT 'Net Amount',
      "TAXAMOUNT" DECIMAL(15,2) COMMENT 'Tax Amount',
      "QUANTITY" DECIMAL(13,3) COMMENT 'Quantity',
      "QUANTITYUNIT" NVARCHAR(3) COMMENT 'Quantity Unit',
      "DELIVERYDATE" DATE COMMENT 'Delivery Date',
      PRIMARY KEY ("PURCHASEORDERID","PURCHASEORDERITEM"))
      COMMENT 'Purchase Order Item'
      WITH ASSOCIATIONS( JOIN "PurchaseOrderHeader" AS "POHeader" ON "POHeader"."PURCHASEORDERID" = "PURCHASEORDERID")  -- final reconstruido, ver erratas
      UNLOAD PRIORITY 5 AUTO MERGE
```

### Paso 4. Añadir una vista SQL

`myapp/db/src/data/PurchaseOrderItemView.hdbview`

```sql
VIEW "PurchaseOrderItemView" COMMENT 'Purchase Order Item View' (
     "PurchaseOrderItemId",
     "ItemPos",
     "ProductID",
     "CurrencyCode",
     "Amount",
     "NetAmount",
     "TaxAmount",
     "Quantity",
     "QuantityUnit",
     "DeliveryDate1"
     ) AS SELECT
     "Item_$0"."PURCHASEORDERID" AS "PurchaseOrderItemId",
     "Item_$0"."PURCHASEORDERITEM" AS "ItemPos",
     "Item_$0"."PRODUCT" AS "ProductID",
     "Item_$0"."CURRENCY" AS "CurrencyCode",
     "Item_$0"."GROSSAMOUNT" AS "Amount",
     "Item_$0"."NETAMOUNT" AS "NetAmount",
     "Item_$0"."TAXAMOUNT" AS "TaxAmount",
     "Item_$0"."QUANTITY" AS "Quantity",
     "Item_$0"."QUANTITYUNIT" AS "QuantityUnit",
     "Item_$0"."DELIVERYDATE" AS "DeliveryDate1"
FROM "PurchaseOrderItem" AS "Item_$0"
WITH READ ONLY STRUCTURED PRIVILEGE CHECK
```

### Paso 5. Crear una secuencia

Las tablas usan un ID de pedido único como clave primaria, así que hace falta una secuencia que genere un ID autoincremental en cada inserción.

1. Clic derecho en `myapp/db/src/data` → **Nuevo → Archivo**.
2. Nómbralo `orderId.hdbsequence`. Es una secuencia sin ciclos, que depende de la tabla cabecera:

```sql
SEQUENCE "orderId"
INCREMENT BY 1
START WITH 200000000
MINVALUE 1
MAXVALUE 2999999999
NO CYCLE
RESET BY SELECT IFNULL(MAX(PURCHASEORDERID), 0)+1
FROM "PurchaseOrderHeader"
```

3. Guarda el fichero.

### Paso 6. Cargar datos iniciales

En HDI, para importar un CSV a una tabla se necesitan dos artefactos:

| Fichero | Función |
|---|---|
| `myData.csv` | Los datos que se van a cargar |
| `myTargetTable.hdbtabledata` | Qué CSV va a qué tabla y cómo se mapean las columnas |

**a. `db/src/data/Purchase.hdbtabledata`**

```json
{
    "format_version" : 1,
    "imports" : [
        {
            "target_table" : "PurchaseOrderHeader",
            "source_data" : {
                "data_type" : "CSV",
                "file_name" : "header.csv",
                "has_header" : false,
                "dialect" : "HANA",
                "type_config" : {
                    "delimiter" : ","
                }
            },
            "import_settings" : {
                "import_columns" : [
                    "PURCHASEORDERID",
                    "NOTEID",
                    "PARTNER",
                    "CURRENCY",
                    "GROSSAMOUNT",
                    "NETAMOUNT",
                    "TAXAMOUNT",
                    "LIFECYCLESTATUS",
                    "APPROVALSTATUS",
                    "CONFIRMSTATUS",
                    "ORDERINGSTATUS",
                    "INVOICINGSTATUS"]
            },
            "column_mappings" : {
                "PURCHASEORDERID" : 1,
                "NOTEID" : 6,
                "PARTNER" : 7,
                "CURRENCY" : 8,
                "GROSSAMOUNT" : 9,
                "NETAMOUNT" : 10,
                "TAXAMOUNT" : 11,
                "LIFECYCLESTATUS" : 12,
                "APPROVALSTATUS" : 13,
                "CONFIRMSTATUS" : 14,
                "ORDERINGSTATUS" : 15,
                "INVOICINGSTATUS" : 16
            }
        },
        {
            "target_table" : "PurchaseOrderItem",
            "source_data" : {
                "data_type" : "CSV",
                "file_name" : "item.csv",
                "has_header" : false,
                "dialect" : "HANA",
                "type_config" : {
                    "delimiter" : ","
                }
            },
            "import_settings" : {
                "import_columns" : [
                    "PURCHASEORDERID",
                    "PURCHASEORDERITEM",
                    "PRODUCT",
                    "NOTEID",
                    "CURRENCY",
                    "GROSSAMOUNT",
                    "NETAMOUNT",
                    "TAXAMOUNT",
                    "QUANTITY",
                    "QUANTITYUNIT" ]
            },
            "column_mappings" : {
                "PURCHASEORDERID" : 1,
                "PURCHASEORDERITEM" : 2,
                "PRODUCT" : 3,
                "NOTEID" : 4,
                "CURRENCY" : 5,
                "GROSSAMOUNT" : 6,
                "NETAMOUNT" : 7,
                "TAXAMOUNT" : 8,
                "QUANTITY" : 9,
                "QUANTITYUNIT" : 10
            }
        }]
}
```

**b. `db/src/data/header.csv`**

```csv
0500000000,0000000033,20120101,0000000033,20120101,9000000001,0100000000,EUR,13224.47
0500000001,0000000033,20120102,0000000033,20120102,9000000001,0100000002,EUR,12493.73
```

**c. `db/src/data/item.csv`**

```csv
0500000000,0000000010,HT-1000,,EUR,1137.64,956,181.64,1,EA,20121204
0500000000,0000000020,HT-1091,,EUR,61.88,52,9.88,2,EA,20121204
0500000000,0000000030,HT-6100,,EUR,1116.22,938,178.22,2,EA,20121204
0500000000,0000000040,HT-1000,,EUR,2275.28,1912,363.28,2,EA,20121204
0500000000,0000000050,HT-1091,,EUR,92.82,78,14.82,3,EA,20121204
0500000000,0000000060,HT-6100,,EUR,1116.22,938,178.22,2,EA,20121204
0500000000,0000000070,HT-1000,,EUR,2275.28,1912,363.28,2,EA,20121204
0500000000,0000000080,HT-1091,,EUR,61.88,52,9.88,2,EA,20121204
0500000000,0000000090,HT-6100,,EUR,1674.33,1407,267.33,3,EA,20121204
0500000000,0000000100,HT-1000,,EUR,3412.92,2868,544.92,3,EA,20121204
0500000001,0000000010,HT-1100,,USD,213.96,179.8,34.16,2,EA,20121204
0500000001,0000000020,HT-2026,,USD,35.69,29.99,5.7,1,EA,20121204
0500000001,0000000030,HT-1002,,USD,3736.6,3140,596.6,2,EA,20121204
0500000001,0000000040,HT-1100,,USD,213.96,179.8,34.16,2,EA,20121204
0500000001,0000000050,HT-2026,,USD,71.38,59.98,11.4,2,EA,20121204
0500000001,0000000060,HT-1002,,USD,3736.6,3140,596.6,2,EA,20121204
0500000001,0000000070,HT-1100,,USD,320.94,269.7,51.24,3,EA,20121204
0500000001,0000000080,HT-2026,,USD,107.06,89.97,17.09,3,EA,20121204
0500000001,0000000090,HT-1002,,USD,3736.6,3140,596.6,2,EA,20121204
0500000001,0000000100,HT-1100,,USD,320.94,269.7,51.24,3,EA,20121204
```

### Paso 7. Crear un sinónimo

Hace falta un sinónimo para acceder a cualquier tabla o vista **fuera del contenedor** de la aplicación. Aquí se usa para acceder a la vista `DUMMY` del esquema `SYS`.

`db/src/data/general.hdbsynonym`

```json
{
  "DUMMY" : {
     "target" : {
              "schema" : "SYS",
              "object" : "DUMMY"
     }
  }
}
```

### Paso 8. Crear un privilegio estructurado

El privilegio estructurado es el sucesor lógico del privilegio analítico. Permite **filtrar filas** de la vista `PurchaseOrderItemView`.

1. Crea la subcarpeta `db/src/roles`.
2. Crea `PurchaseOrder.hdbstructuredprivilege`:

```sql
STRUCTURED PRIVILEGE
  "PO_VIEW_PRIVILEGE"
  FOR SELECT ON
  "PurchaseOrderItemView"
WHERE "CurrencyCode" = 'EUR'
```

### Paso 9. Crear un rol para el privilegio estructurado

El usuario técnico vinculado al contenedor HDI da acceso a los objetos desde la aplicación. Para que **otros usuarios de base de datos** (p. ej. herramientas de informes externas) tengan acceso, hay que crear un rol.

`db/src/roles/dev007.hdbrole`

```json
{
    "role": {
        "name": "dev007",
        "object_privileges": [
            {
                "name": "PurchaseOrderHeader",
                "type": "TABLE",
                "privileges": [ "SELECT" ]
            },
            {
                "name": "PurchaseOrderItem",
                "type": "TABLE",
                "privileges": [ "SELECT" ]
            },
            {
                "name": "PurchaseOrderItemView",
                "type": "VIEW",
                "privileges": [ "SELECT" ]
            }
        ],
        "schema_analytic_privileges": [
            {
                "privileges": [ "PO_VIEW_PRIVILEGE" ]
            }
        ]
    }
}
```

### Paso 10. Comprobar los plug-ins en `.hdiconfig`

Cada sufijo de fichero está vinculado a un plug-in HDI. `db/src/.hdiconfig` debe contener **al menos** estas entradas. En SAP HANA Cloud, el número de versión del plug-in es opcional.

```json
"hdbsequence": {
     "plugin_name": "com.sap.hana.di.sequence"
     },
"hdbtable" : {
     "plugin_name" : "com.sap.hana.di.table"
     },
"hdbview" : {
     "plugin_name" : "com.sap.hana.di.view"
     },
"csv" : {
     "plugin_name" : "com.sap.hana.di.tabledata.source"
     },
"hdbtabledata" : {
     "plugin_name" : "com.sap.hana.di.tabledata"
     },
"hdbfunction" : {
     "plugin_name" : "com.sap.hana.di.hdbfunction"
     },
"hdbstructuredprivilege" : {
     "plugin_name" : "com.sap.hana.di.structuredprivilege"
     },
"hdbsynonym" : {
     "plugin_name" : "com.sap.hana.di.hdbsynonym"
     },
"hdbrole" : {
     "plugin_name" : "com.sap.hana.di.role"
     },
"hdbroleconfig" : {
     "plugin_name" : "com.sap.hana.di.role.config"
     }
```

> ⚠️ Tal cual lo copia la guía, este bloque tiene nombres de plug-in incorrectos. Usa el `.hdiconfig` corregido de la sección de [erratas](#erratas-detectadas-en-el-pdf).
>
> **Consejo:** `.hdiconfig` está oculto por defecto. Para verlo: **Ver → Mostrar archivos ocultos**.

### Paso 11. Desplegar el módulo `db`

El despliegue activa el modelo de datos y crea en el catálogo los objetos de cada artefacto: dos tablas y una vista.

- En BAS, selecciona `myapp/db` en el panel **PROYECTOS de SAP HANA** y pulsa **Desplegar**.
- Si el terminal muestra `(Builder) Build of /myapp/db completed`, el modelo se ha activado correctamente en el contenedor HANA.

---

## 4. Crear un procedimiento de base de datos

**Objetivo:** crear, editar y desplegar un procedimiento (`.hdbprocedure`) que cuenta las compras de un pedido según su ID.

**Requisito adicional:** tener creadas las tablas de la [sección 3](#3-crear-los-artefactos-de-datos-para-un-procedimiento).

### Paso 1. Crear el proyecto

Sigue la [sección 2](#2-crear-el-proyecto-en-sap-business-application-studio).

### Paso 2. Crear el procedimiento almacenado

1. Crea la carpeta `db/src/procedures` (p. ej. `MyApp/db/src/procedures`).
2. Clic derecho en la carpeta → **Nuevo → Archivo** → `OrderCount.hdbprocedure`.
   > **Alternativa con asistente:** **Ver → Paleta de comandos**, escribe *crear* y selecciona **SAP HANA: Crear artefacto de base de datos SAP HANA**. Elige **Procedimiento (hdbprocedure)**, ponle nombre y guárdalo en `db/src/procedures`.
3. Añade el código SQLScript y guarda:

`MyApp/db/src/procedures/OrderCount.hdbprocedure`

```sql
PROCEDURE "OrderCount"(
 OUT ORDER_COUNT INTEGER,
 IN PURCHASEORDERITEM_ID INTEGER
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
--DEFAULT SCHEMA <default_schema_name>
READS SQL DATA AS
BEGIN
  /*************************************
   Write your procedure logic
  *************************************/
  SELECT
    COUNT(*) INTO ORDER_COUNT
  FROM
    "PurchaseOrderItem"
  WHERE
    "PURCHASEORDERITEM" = PURCHASEORDERITEM_ID;
END
```

| Cláusula | Significado |
|---|---|
| `OUT` / `IN` | Parámetros de salida y de entrada |
| `LANGUAGE SQLSCRIPT` | Lenguaje del cuerpo del procedimiento |
| `SQL SECURITY INVOKER` | Se ejecuta con los privilegios de quien lo llama (la alternativa es `DEFINER`) |
| `READS SQL DATA` | Procedimiento de solo lectura: no modifica datos |
| `SELECT … INTO` | Asigna el resultado de la consulta a una variable o parámetro |

4. Despliega: clic derecho en `MyApp/db` → **Desplegar**, y sigue el progreso en la consola. Al terminar verás algo así:

```text
Implementación en contenedor A7976B2D158949D193DB4843390C4BE5 realizada [ID de implementación: ninguna].
Implementación finalizada a las 24/05/2023 13:02:13
```

### Paso 3. Comprobar el plug-in

`.hdiconfig` debe contener (el número de versión es opcional y puede variar):

```json
"hdbprocedure": {
    "plugin_name": "com.sap.hana.di.procedure",
    "plugin_version": "40.0.0"                 //optional
},
```

### Paso 4. Comprobar que se ha desplegado

1. Abre el **Explorador de base de datos SAP HANA** en el panel lateral de BAS.
   > También puedes abrir el explorador **PROYECTOS de SAP HANA**, localizar `MyApp/db` y pulsar **Abrir contenedor HDI**.
2. Despliega la instancia de servicio de tu aplicación (`<AppName>-hdbdb-ws-<ID>`).
   > Si el contenedor no aparece, pulsa **Actualizar explorador**.
3. Selecciona el nodo **Procedimientos**.
4. Comprueba que en el panel **CATALOG** aparece `OrderCount`.

### Paso 5. Probar el procedimiento

1. En **CATALOG**, selecciona `OrderCount` para ver su definición.
   > La pestaña **CREATE Statement** muestra el SQL con el que se creó.
2. Opciones de prueba:

| Opción | Qué hace |
|---|---|
| **Generar sentencia CALL** | Muestra la sentencia `CALL` del procedimiento |
| **Generar sentencia CALL con IU** | Muestra la sentencia `CALL` en una interfaz gráfica para introducir los parámetros de forma interactiva |
| **Analizar código SQLScript** | Analiza el SQLScript. El informe muestra el objeto y el esquema afectados, la regla que lo detectó, una descripción y el fragmento de código. Con **Descargar** se guarda en CSV (p. ej. `SQLScript_Code_Analysis_Results.csv`) |

> Algunos procedimientos no se pueden llamar con la IU, por ejemplo los que tienen parámetros de tipos definidos por el usuario (`TABLE_TYPE`). Esos se ejecutan sin la IU.

3. Clic derecho en el procedimiento → **Generar sentencia CALL con IU**.
4. Introduce un valor en el parámetro de entrada.
   > La primera columna de `item.csv` es el `PURCHASEORDERID`, así que puedes usar `0500000000` o `0500000001` para probar.
5. Pulsa **Ejecutar SQL con valores de parámetro de esta pestaña**.

---

## 5. Crear una función de base de datos

**Objetivo:** crear una **función escalar definida por el usuario (UDF)**. Una UDF escalar encapsula lógica compleja en un único objeto y se puede llamar en las cláusulas `SELECT` y `WHERE`. Recibe parámetros de entrada y devuelve los valores escalares indicados en `RETURNS` (p. ej. `decimal(15,2)`).

La función de ejemplo, `apply_discount`:
- Aplica un descuento al precio del producto.
- Calcula el precio de venta con el descuento aplicado.

### Paso 1. Crear el proyecto

Sigue la [sección 2](#2-crear-el-proyecto-en-sap-business-application-studio).

### Paso 2. Crear la función

1. Si no existe, crea la carpeta `db/src/functions` (p. ej. `myapp/db/src/functions`).
2. Clic derecho → **Nuevo → Archivo** → `apply_discount.hdbfunction`.
   > **Alternativa con asistente:** **SAP HANA: Crear artefacto de base de datos SAP HANA**, elige **Función (hdbfunction)** y guárdala en `db/src/functions`.
3. Añade el código SQLScript:

`db/src/functions/apply_discount.hdbfunction`

```sql
FUNCTION "apply_discount" (im_price decimal(15,2), im_discount decimal(15,2) )
RETURNS result decimal(15,2)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER AS
BEGIN
result := :im_price - ( :im_price * :im_discount );
END;
```

> En SQLScript, `:variable` lee el valor de una variable o parámetro, y `:=` asigna.

4. Despliega: clic derecho en `MyApp/db` → **Desplegar** y sigue el progreso en la consola.

### Paso 3. Comprobar el plug-in

`.hdiconfig` debe contener:

```json
"hdbfunction": {
    "plugin_name": "com.sap.hana.di.function"
},
```

### Paso 4. Comprobar que se ha desplegado

1. Abre el **Explorador de base de datos SAP HANA**.
2. Despliega la instancia de servicio de tu aplicación (`<AppName>-hdbdb-ws-<ID>`).
3. Selecciona el nodo **Funciones**.
4. Comprueba que en **CATALOG** aparece `apply_discount`.

### Paso 5. Probar la función

1. En **Funciones**, selecciona `apply_discount` para ver su configuración en la pestaña de detalles.
2. Opciones de prueba:

| Opción | Qué hace |
|---|---|
| **Generar sentencia SELECT** | Muestra la sentencia `SELECT` para llamar a la función |
| **Analizar código SQLScript** | Igual que en los procedimientos; el resultado se puede descargar en CSV |

Por ejemplo, un 10 % de descuento sobre 100:

```sql
SELECT "apply_discount"(100.00, 0.10) AS PRECIO_FINAL FROM DUMMY;  -- 90.00
```

---

## Erratas detectadas en el PDF

El PDF es una traducción automática con ejemplos "solo ilustrativos". Al transcribirlo he encontrado estas incoherencias:

| # | Dónde | Problema | Corrección |
|---|---|---|---|
| 1 | `PurchaseOrderHeader.hdbtable` y `PurchaseOrderItem.hdbtable` | Algunas líneas salen **cortadas** por el margen del PDF: la definición `IDENTITY (...)` de `PURCHASEORDERID` y los `ON` de `WITH ASSOCIATIONS` | Los `ON` están reconstruidos por el nombre de las columnas. La cláusula `IDENTITY` hay que completarla con la guía original de SAP Help |
| 2 | `.hdiconfig` del paso 10 (sección 3) | Nombres de plug-in incorrectos: `com.sap.hana.di.hdbfunction` y `com.sap.hana.di.hdbsynonym`. La propia guía usa `com.sap.hana.di.function` en la sección 5 | `com.sap.hana.di.function` y `com.sap.hana.di.synonym` |
| 3 | `.hdiconfig` del paso 10 | `hdbroleconfig` aparece como `com.sap.hana.di.role.config` | `com.sap.hana.di.roleconfig` |
| 4 | `.hdiconfig` del paso 10 | No incluye `hdbprocedure`, que hace falta en la sección 4 | Añadir `com.sap.hana.di.procedure` |
| 5 | Secuencia `orderId` | El texto dice "de 200000000 a 299999999", pero el código usa `MAXVALUE 2999999999` (un 9 más) | Decide cuál quieres; el código es el que manda |
| 6 | `header.csv` vs `Purchase.hdbtabledata` | El mapeo de cabecera usa columnas hasta la 16, pero `header.csv` solo tiene 9 por fila | Completa el CSV con las 16 columnas o ajusta `column_mappings` |
| 7 | `OrderCount.hdbprocedure` | El parámetro se llama `PURCHASEORDERITEM_ID` y filtra por `PURCHASEORDERITEM` (la posición), pero la prueba dice "introduzca un valor en `PURCHASEORDER_ID`" y sugiere IDs de pedido (`0500000000`) | Para contar posiciones de un pedido, filtra por `"PURCHASEORDERID" = :PURCHASEORDER_ID` |
| 8 | Paso 7 (sinónimo) | Dice "cree dos archivos" pero solo muestra el `.hdbsynonym` | Para un sinónimo a `SYS.DUMMY` basta con el `.hdbsynonym` con el schema fijo |
| 9 | Paso 8 (privilegio estructurado) | Dice "en la carpeta data, cree la subcarpeta roles", pero la ruta es `db/src/roles` | La carpeta va en `db/src/roles` |
| 10 | Varias | "Cabecera"/"Elemento" (Header/Item) y "Reserva de vuelo" son restos de la traducción o de otro tutorial | Las tablas son `PurchaseOrderHeader` y `PurchaseOrderItem`; el proyecto es `myapp` |

### `.hdiconfig` corregido para toda la guía

```json
{
  "file_suffixes": {
    "hdbtable":               { "plugin_name": "com.sap.hana.di.table" },
    "hdbview":                { "plugin_name": "com.sap.hana.di.view" },
    "hdbsequence":            { "plugin_name": "com.sap.hana.di.sequence" },
    "csv":                    { "plugin_name": "com.sap.hana.di.tabledata.source" },
    "hdbtabledata":           { "plugin_name": "com.sap.hana.di.tabledata" },
    "hdbprocedure":           { "plugin_name": "com.sap.hana.di.procedure" },
    "hdbfunction":            { "plugin_name": "com.sap.hana.di.function" },
    "hdbsynonym":             { "plugin_name": "com.sap.hana.di.synonym" },
    "hdbstructuredprivilege": { "plugin_name": "com.sap.hana.di.structuredprivilege" },
    "hdbrole":                { "plugin_name": "com.sap.hana.di.role" },
    "hdbroleconfig":          { "plugin_name": "com.sap.hana.di.roleconfig" }
  }
}
```
