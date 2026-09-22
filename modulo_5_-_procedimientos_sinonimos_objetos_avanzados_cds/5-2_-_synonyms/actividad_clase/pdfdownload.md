# Activar el acceso a objetos en otro contenedor HDI

> **Fuente:** SAP HANA Cloud, guía del desarrollador de la base de datos de SAP HANA para las aplicaciones multidestino de Cloud Foundry (SAP Business App Studio)
> SAP HANA Cloud, SAP HANA Database | QRC 3/2026 · Público
> Contenido original: https://help.sap.com/docs/HANA_CLOUD_DATABASE/c2b99f19e9264c4d9ae9221b22f6f589?locale=en-US&state=PRODUCTION&version=2026_3_QRC
>
> *Documento traducido automáticamente. La versión original en inglés tiene prioridad. Es una documentación personalizada generada por SAP Help Portal y puede estar incompleta.*

Utilice un sinónimo para permitir el acceso a otro contenedor HDI.

## Requisitos previos

- Tiene acceso (y puede desplegar) al entorno de tiempo de ejecución de la aplicación.
- Tiene acceso a SAP Business Application Studio y hay un espacio de desarrollo de aplicaciones nativas de SAP HANA instalado en su área de trabajo de desarrollo.

## Contexto

Puede utilizar un sinónimo en una aplicación para permitir el acceso a objetos de base de datos en un contenedor de aplicaciones diferente; es decir, objetos en un contenedor HDI que pertenece a otra aplicación. Debe garantizar el acceso al contenedor HDI externo y especificar el tipo de autorizaciones (`SELECT`, `EXECUTE`) necesarias en el objeto de destino (tabla, vista, etc.).

## Procedimiento

### 1. Localice el objeto de destino

Localice el objeto de destino en el esquema externo al que apuntará el sinónimo.

Los objetos de destino pueden ser tablas, vistas, funciones, procedimientos, etc.; el esquema de destino es otro contenedor HDI.

### 2. Cree las definiciones de rol

Cree las definiciones de rol que permiten el acceso al objeto de base de datos de destino. En este escenario, cree dos roles:

> **Nota:** Ambos roles deben crearse en el esquema HDI que contiene el objeto de base de datos de destino, por ejemplo, `Table_T1`.

> **Consejo:** La herramienta de desarrollo guiado de SAP Business Application Studio incluye un tutorial llamado *Utilizar objetos contenidos en un esquema de base de datos externo* que le muestra cómo completar los pasos individuales en esta tarea. Encontrará un enlace a la herramienta de desarrollo guiado en la pantalla de bienvenida de SAP Business Application Studio o en la paleta de comandos (*Ver → Paleta de comandos... → Desarrollo guiado*).

#### a. Rol para el propietario del esquema de la aplicación que contiene el sinónimo

El rol `Role_R1G#` (`Role_R1G.hdbrole`) define las autorizaciones necesarias para el acceso externo a un objeto de destino específico (con la opción de concesión); el rol debe asignarse al usuario que necesita acceso al esquema donde se encuentra el objeto de destino `Table_T1`. En este caso, el rol de acceso se asigna al propietario del esquema que contiene el sinónimo que apunta a la tabla de destino.

Puede utilizar el asistente de creación de artefactos en SAP Business Application Studio para crear el nuevo artefacto `hdbrole` en tiempo de diseño.

> **Consejo:** Por defecto, SAP Business Application Studio abre el nuevo artefacto `hdbrole` en el editor gráfico. Sin embargo, también puede abrir el archivo en el editor de códigos o modificar la configuración predeterminada. También puede alternar entre el código y los editores gráficos. Las modificaciones realizadas en el artefacto abierto durante la sesión de edición se sincronizan entre ambos editores.

Código de muestra — `Role_R1G.hdbrole`, definición de rol para propietario de esquema HDI:

```json
{
  "role": {
    "name": "Role_R1G#",
    "object_privileges": [
      {
        "name": "<Table_T1>",
        "type": "TABLE",
        "privileges_with_grant_option": [ "SELECT" ]
      }
    ]
  }
}
```

> **Consejo:** El carácter de almohadilla (`#`) al final del nombre de rol significa que el rol está previsto para la asignación a un propietario de esquema (por ejemplo, `<Container>#OO`) y que el rol debe incluir el privilegio "with grant option".

#### b. Rol para el usuario de la aplicación que contiene el sinónimo

El rol `Role_R1.hdbrole` define las autorizaciones requeridas por el usuario de la aplicación que necesita acceso al objeto de destino `Table_T1` mediante un sinónimo; la autorización `SELECT` es necesaria para el objeto de destino (sin opción de concesión). El rol debe asignarse al usuario de la aplicación que contiene el sinónimo que necesita acceso al objeto de destino `Table_T1`.

> **Nota:** `Role_R1` se asigna al usuario de la aplicación incluyendo una referencia a él en `Role_R2`, que se define en un paso posterior.

Código de muestra — `Role_R1.hdbrole`, definición de rol para usuario de aplicación:

```json
{
  "role": {
    "name": "Role_R1",
    "object_privileges": [
      {
        "name": "<Table_T1>",
        "type": "TABLE",
        "privileges": [ "SELECT" ]
      }
    ]
  }
}
```

Puede utilizar el asistente de creación de artefactos en SAP Business Application Studio para crear el nuevo artefacto `hdbrole` en tiempo de diseño.

> **Consejo:** Si la función de autocompletar está activada en el editor de texto (código), la extensión Aplicación nativa de SAP HANA en SAP Business Application Studio proporciona descripciones contextuales de etiquetas y propiedades en artefactos HDI basados en JSON. Para escenarios comunes, también se proporcionan plantillas.

### 3. Conceda acceso al esquema que contiene el objeto de destino del sinónimo

Conceda acceso al esquema que contiene el objeto de destino del sinónimo (por ejemplo, `Table_T1`). Puede realizar esta tarea para escenarios utilizando un servicio de contenedor HDI o un servicio proporcionado por el usuario, como se describe a continuación.

> **Consejo:** Se puede utilizar un contenedor HDI para proporcionar acceso a una aplicación de base de datos; se puede utilizar un servicio proporcionado por el usuario para proporcionar acceso a varias aplicaciones de base de datos.

#### Servicio de contenedor HDI

El propietario del esquema que contiene el sinónimo requiere privilegios `SELECT` (con la opción de conceder el privilegio `SELECT`) en el objeto de destino al que apunta el sinónimo para poder crear vistas sobre el sinónimo. El acceso para el propietario del esquema se puede activar en roles de usuario a los que se hace referencia en un contenedor HDI con la propiedad `"container_roles"` en un archivo `.hdbgrants`, como se ilustra en el siguiente ejemplo:

Código de muestra — fichero de configuración de concesión de acceso (`myApp/db/cfg/Synonym_S1-table.hdbgrants`):

```json
{
  "EPM_log-table-grantor": {
    "object_owner": {
      "container_roles": [
        "Role_R1G#"
      ]
    },
    "application_user": {
      "container_roles": [
        "Role_R1"
      ]
    }
  }
}
```

> **Atención:** En el archivo `hdbgrants`, se recomienda utilizar un enfoque de menor autorización en el que se creen diferentes roles con autorizaciones dedicadas para el propietario del objeto y el usuario de la aplicación, respectivamente.

#### Servicio proporcionado por el usuario

El propietario del esquema que contiene el sinónimo requiere privilegios `SELECT` (con la opción de conceder el privilegio `SELECT`) en el objeto de destino al que apunta el sinónimo para poder crear vistas sobre el sinónimo. El acceso para el propietario del esquema se puede activar en roles de usuario que para un servicio proporcionado por el usuario se referencian con la propiedad `"schema_roles"` en un archivo `.hdbgrants`, como se ilustra en el siguiente ejemplo:

Código de muestra — fichero de configuración de concesión de acceso (`myApp/db/cfg/Synonym_S1-table.hdbgrants`):

```json
{
  "EPM_log-table-grantor": {
    "object_owner": {
      "schema_roles": [
        {
          "schema": "<Schema_Name>",
          "roles": [ "Role_R1G#" ]
        }
      ]
    },
    "application_user": {
      "schema_roles": [
        {
          "schema": "<Schema_Name>",
          "roles": [ "Role_R1" ]
        }
      ]
    }
  }
}
```

> **Atención:** En el archivo `hdbgrants`, se recomienda utilizar un enfoque de menor autorización en el que se creen diferentes roles con autorizaciones dedicadas para el propietario del objeto y el usuario de la aplicación, respectivamente.

Para el acceso a objetos mediante un servicio proporcionado por el usuario, debe asegurarse de que ya existe un usuario de base de datos (si es necesario creando uno nuevo ahora) y de que a este usuario se le han concedido los roles especificados en el archivo `.hdbgrants` *with admin option*, por ejemplo, utilizando la consola SQL de la siguiente manera:

```sql
create user <UserName> password <Password> set usergroup default
GRANT <SchemaName>."Role_R1" to <UserName> with admin option;
GRANT <SchemaName>."Role_R1G#" to <UserName> with admin option;
```

Puede utilizar el asistente de creación de artefactos en SAP Business Application Studio para crear el nuevo artefacto `hdbgrants` en tiempo de diseño.

> **Consejo:** Por defecto, SAP Business Application Studio abre el nuevo artefacto `hdbgrants` en el editor gráfico. Sin embargo, también puede abrir el archivo en el editor de códigos o modificar la configuración predeterminada. También puede alternar entre el código y los editores gráficos. Las modificaciones realizadas en el artefacto abierto durante la sesión de edición se sincronizan entre ambos editores.

> **Consejo:** Si la función de autocompletar está activada en el editor de texto (código), la extensión Aplicación nativa de SAP HANA en SAP Business Application Studio proporciona descripciones contextuales de etiquetas y propiedades en artefactos HDI basados en JSON. Para escenarios comunes, también se proporcionan plantillas.

### 4. Cree el(los) sinónimo(s)

Puede crear el objeto de tiempo de diseño sinónimo en una subcarpeta del módulo de base de datos de su aplicación, por ejemplo, en `/<MyApp>/db/src/synonyms/`. En este ejemplo, nombramos la definición de sinónimos `Synonym_S1.hdbsynonym`, que contiene varios sinónimos que hacen referencia a tablas (`Table_T1`, `Table_T2` y `Table_T3`), como se ilustra en el siguiente ejemplo:

Código de muestra — archivo de definición de sinónimos (`/MyApp/db/src/synonyms/Synonym_S1.hdbsynonym`):

```json
{
  "Table_T1": {}
}
```

> **Nota:** En este ejemplo, la configuración de sinónimos no está incluida en el archivo de sinónimos; se mueve al archivo de configuración correspondiente del sinónimo `Synonym_S1.hdbsynonymconfig`, como se describe en el paso siguiente.

Puede utilizar el asistente de creación de artefactos en SAP Business Application Studio para crear el nuevo artefacto `hdbsynonym` en tiempo de diseño.

> **Consejo:** Por defecto, SAP Business Application Studio abre el nuevo artefacto `hdbsynonym` en el editor gráfico. Sin embargo, también puede abrir el archivo en el editor de códigos o modificar la configuración predeterminada. También puede alternar entre el código y los editores gráficos. Las modificaciones realizadas en el artefacto abierto durante la sesión de edición se sincronizan entre ambos editores.

> **Consejo:** Si la función de autocompletar está activada en el editor de texto (código), la extensión Aplicación nativa de SAP HANA en SAP Business Application Studio proporciona descripciones contextuales de etiquetas y propiedades en artefactos HDI basados en JSON. Para escenarios comunes, también se proporcionan plantillas.

### 5. Cree un archivo de configuración de sinónimos

La configuración de sinónimos también se puede definir en un archivo `.hdbsynonymconfig`, por ejemplo, `myApp/db/cfg/Synonym_S1.hdbsynonymconfig`.

> **Nota:** Los archivos `.hdbsynonymtemplate` heredados también se pueden utilizar; se convierten al formato de archivo `.hdbsynonymconfig` requerido en el momento del despliegue.

### 6. Defina los detalles de la configuración de sinónimos

En lugar de definir un esquema y un nombre de esquema concreto, puede utilizar `"schema.configure"` para especificar una vía de acceso a un nombre de servicio. La expresión de vía de acceso se sustituye en el momento de la implementación por el nombre del esquema del servicio referenciado. Por ejemplo, en el siguiente ejemplo de código, `"schema.configure"` se sustituye por el esquema utilizado por el servicio de otorgante.

Código de muestra — archivo de configuración de sinónimos (`myApp/db/cfg/Synonym_S1.hdbsynonymconfig`):

```json
{
  "Table_T1": {
    "target": {
      "object": "Table_T1",
      "schema.configure": "EPM_log-table-grantor/schema"
    }
  },
  […]
}
```

### 7. Defina la configuración necesaria del plug-in HDI para el sinónimo

Agregue el archivo de configuración del complemento HDI central del proyecto de la aplicación (`.hdiconfig`) a la carpeta `cfg/` del módulo de la base de datos. Puede copiar el archivo de configuración del complemento HDI de `myapp/db/src/.hdiconfig` a `myapp/db/cfg/.hdiconfig`.

El archivo de configuración `.hdiconfig` debe incluir las siguientes entradas:

Código de muestra — archivo de configuración de plug-in HDI (`.hdiconfig`):

```json
"hdbsynonym" : {
   "plugin_name" : "com.sap.hana.di.synonym",
   "plugin_version": "2.0.0.0"
},
"hdbsynonymconfig" : {
   "plugin_name" : "com.sap.hana.di.synonym.config",
   "plugin_version": "2.0.0.0"
}
```

> **Consejo:** La propiedad `"plugin_version": "2.0.0.0"` es opcional; a partir de SAP HANA 2.0, la versión de todos los complementos enviados con SAP HANA es la misma que (e igual a) la versión de SAP HANA.

### 8. Actualice el descriptor de desarrollo de la aplicación (`mta.yaml`)

Añada referencias a `<target-hdi-container service name>` en el descriptor de desarrollo para la aplicación que necesita utilizar el sinónimo para acceder a los objetos de destino, como se ilustra en el siguiente ejemplo.

Código de muestra — descriptor de desarrollo de aplicaciones (`MyApp/mta.yaml`):

```yaml
modules:
  - name: db
    type: hdb
    path: db
    requires:
      - name: hdi-container
        properties:
          TARGET_CONTAINER: ~{hdi-container-service}
      - name: EPM_XXX-table-grantor
        group: SERVICE_REPLACEMENTS
        properties:
          key: EPM_log-table-grantor
          service: ~{EPM_Synonym_S1-table-grantor-service}
resources:
  - name: hdi-container
    type: com.sap.xs.hdi-container
    properties:
      hdi-container-service: ${service-name}

  - name: EPM_XXX-table-grantor
    type: org.cloudfoundry.existing-service
    properties:
      EPM_Synonym_S1-table-grantor-service: ${service-name}
    parameters:
      service-name: <HDI_Container_Name>-hdi-container
```

### 9. Vincule el servicio de otorgante de tabla a su proyecto de aplicación

En la pestaña **SAP HANA PROJECTS**, despliegue el nodo *Conexiones de base de datos* del proyecto, seleccione el servicio al que desea vincular su aplicación (por ejemplo, `EPM_XXX-table-grantor`) y seleccione **Vincular** (*Bind*).

### 10. Consuma el sinónimo que ha creado

Una forma de consumir sinónimos desde dentro del esquema de la aplicación es utilizar una vista (por ejemplo, `View_V1`) en la tabla de destino.

Código de muestra — vista SQL `/myApp/db/src/View_V1.hdbview`:

```sql
VIEW "View_V1" AS SELECT * FROM Table_T1
```

> **Consejo:** `Role_R2` debe estar ubicado en el mismo esquema HDI que el sinónimo. La vista no es necesaria para la creación de un sinónimo; se utiliza aquí para probar el "consumo" del sinónimo `Synonym_S1`.

### 11. Cree una definición de rol que permita el acceso a la vista que consume `Synonym_S1`

La definición de rol (por ejemplo, `Role_R2.hdbrole`) debe asignarse a los usuarios de la aplicación que necesitan acceso a la vista (en este ejemplo, `View_V1`). El usuario de la aplicación ya tiene acceso a la vista a través de `access_role` del contenedor de la aplicación; el rol `Role_R2.hdbrole` es necesario para los usuarios fuera de la aplicación.

Código de muestra — `myApp/db/src/Role_R2.hdbrole`, definición de rol:

```json
{
  "role": {
    "name": "Role_R2",
    "object_privileges": [
      {
        "name": "View_V1",
        "type": "VIEW",
        "privileges": [ "SELECT" ]
      }
    ]
  }
}
```

### 12. Cree ambos proyectos de aplicación

Cree ambos proyectos de aplicación: la aplicación que contiene la tabla de destino (`Table_T1`) y la aplicación que contiene `Synonym_S1` y `View_V1`.

### 13. Verifique los catálogos de base de datos

Verifique los catálogos de base de datos para asegurarse de que existen los objetos adecuados y que se puede acceder a ellos con los sinónimos que ha creado.

## Información relacionada

- Uso de sinónimos para acceder a esquemas y objetos externos
- Sinónimos de base de datos en SAP HANA Cloud
- Opciones de sintaxis en el archivo hdbGrant
- Usuarios, autorizaciones y esquemas
