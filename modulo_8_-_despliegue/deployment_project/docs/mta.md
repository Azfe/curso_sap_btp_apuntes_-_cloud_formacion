# MTA (Multi-Target Application)

## Qué es MTA

**MTA** significa *Multi-Target Application*. Es el formato que usa SAP BTP para **empaquetar y desplegar como una sola unidad una aplicación formada por varias piezas**.

Una aplicación CAP real casi nunca es un único programa. Suele tener:

- el **servicio CAP** en Node.js (carpeta `srv`);
- el **despliegue de la base de datos** (crear tablas en SAP HANA Cloud);
- la **interfaz** (SAPUI5/Fiori, carpeta `app`);
- **servicios de BTP** de los que depende: XSUAA (autenticación), HANA, Destination, etc.

Cada pieza es un *target* distinto. Por eso se llama *multi-target*. MTA describe todas las piezas y cómo se relacionan, para desplegarlas juntas y en el orden correcto.

## El fichero `mta.yaml`

Es el "plano" de la aplicación. Tiene dos partes principales:

```yaml
ID: deployment_project
version: 1.0.0

modules:              # lo que se construye y ejecuta (código propio)
  - name: deployment_project-srv      # el servidor CAP
    type: nodejs
    path: gen/srv
    requires:
      - name: deployment_project-auth # necesita XSUAA
      - name: deployment_project-db   # necesita HANA

  - name: deployment_project-db-deployer   # crea las tablas en HANA
    type: hdb
    path: gen/db
    requires:
      - name: deployment_project-db

resources:            # servicios de BTP que se crean/usan
  - name: deployment_project-auth
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json

  - name: deployment_project-db
    type: com.sap.xs.hdi-container
```

- **modules**: el código propio (servidor, *deployer* de base de datos, app UI…).
- **resources**: instancias de servicios de BTP que se crean automáticamente.
- **requires/provides**: conectan módulos y recursos. Por ejemplo, "el servidor necesita HANA y XSUAA", y BTP le inyecta las credenciales.

## Qué hace `cds add mta`

Genera automáticamente el `mta.yaml` a partir de lo que tiene el proyecto CAP. Mira la configuración (`package.json`, servicios usados, si hay HANA, XSUAA, UI…) y crea los módulos y recursos correspondientes, para no tener que escribirlo a mano.

Lo normal es combinarlo con otros `cds add`:

```bash
cds add hana      # usar SAP HANA Cloud en producción
cds add xsuaa     # autenticación real (genera xs-security.json)
cds add mta       # genera/actualiza el mta.yaml con todo lo anterior
```

## Flujo de despliegue

```bash
mbt build                                              # construye el paquete → mta_archives/xxx.mtar
cf deploy mta_archives/deployment_project_1.0.0.mtar   # lo despliega en Cloud Foundry
```

1. **`mbt build`** (*Cloud MTA Build Tool*) lee el `mta.yaml`, ejecuta los *builds* (`cds build`, etc.) y lo empaqueta todo en un único fichero **`.mtar`**.
2. **`cf deploy`** sube ese `.mtar` a BTP Cloud Foundry, que crea los servicios (HANA, XSUAA…), despliega las tablas, arranca el servidor y le pasa las credenciales.

En Business Application Studio también se puede hacer clic derecho sobre `mta.yaml` → **Build MTA Project** y, después, sobre el `.mtar` generado → **Deploy MTA Archive**.

## Relación con este proyecto

En local el proyecto usa **SQLite** y **autenticación *mocked*** (el usuario `admin` definido en `package.json`, bajo `cds.requires.auth`). Eso solo sirve para desarrollo. En BTP:

- SQLite se sustituye por **HANA Cloud** (`cds add hana`);
- los usuarios *mocked* se sustituyen por **XSUAA**, y el rol `admin` se define en `xs-security.json` y se asigna en el *cockpit* de BTP mediante *Role Collections*.

Por eso, para desplegar, lo habitual es ejecutar `cds add hana`, `cds add xsuaa` y luego `cds add mta`.
