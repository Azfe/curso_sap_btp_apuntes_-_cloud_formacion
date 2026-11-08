# Cómo funciona una app SAPUI5: del `index.html` a la pantalla

Esta app muestra en el navegador un texto, un botón y un campo de entrada con un saludo que cambia mientras escribes. Para conseguirlo, cada fichero de `webapp` hace una parte del trabajo.

## La idea general

UI5 separa la aplicación en tres piezas, un patrón llamado **MVC**:

| Pieza | Qué hace | Dónde está |
|---|---|---|
| **Modelo** (Model) | Guarda los datos | Se crea en `App.controller.ts` (`JSONModel`) |
| **Vista** (View) | Define qué se ve | `view/App.view.xml` |
| **Controlador** (Controller) | Decide qué pasa cuando el usuario actúa | `controller/App.controller.ts` |

Una forma sencilla de verlo es un restaurante: el modelo es la despensa, la vista es el plato que ve el cliente y el controlador es el camarero que atiende lo que el cliente pide.

## El camino paso a paso

```
index.html  →  carga UI5  →  index.ts  →  App.view.xml  →  App.controller.ts  →  se dibuja la página
```

### 1. `index.html`: la puerta de entrada

Es lo primero que pide el navegador. Casi no tiene contenido visible; su trabajo es cargar UI5 con la etiqueta `<script id="sap-ui-bootstrap">`, lo que se conoce como *bootstrap*. Sus atributos más importantes son:

- `src="resources/sap-ui-core.js"`: el fichero principal de UI5.
- `data-sap-ui-theme="sap_horizon"`: el tema visual.
- `data-sap-ui-resource-roots='{"ui5.tutorial.walkthrough": "./"}'`: indica que todo lo que empiece por `ui5.tutorial.walkthrough` está en esta misma carpeta (`webapp`).
- `data-sap-ui-on-init="module:ui5/tutorial/walkthrough/index"`: cuando UI5 termine de cargar, ejecuta `index`.

Además, `<body id="content">` es el hueco de la página donde se colocará la aplicación.

### 2. `index.ts`: el arranque

UI5 ya está cargado y ejecuta este fichero, que hace dos cosas:

1. `XMLView.create(...)` crea la vista a partir de su nombre. `ui5.tutorial.walkthrough.view.App` se traduce a la ruta `./view/App.view.xml`.
2. `view.placeAt("content")` coloca la vista ya creada en el `<body id="content">`.

Sin `placeAt`, la vista existiría en memoria pero no se vería.

### 3. `view/App.view.xml`: qué se ve

Describe la pantalla con etiquetas. Cada etiqueta es un control de UI5:

- `<Text>`: muestra el texto fijo "Hola Mundo!".
- `<Button>`: un botón. `press=".onShowHello"` indica qué método del controlador se ejecuta al pulsarlo.
- `<Input>`: un campo donde el usuario puede escribir.

Las líneas `xmlns` dicen en qué librería buscar cada etiqueta. Con `xmlns="sap.m"`, `<Text>` significa `sap.m.Text`.

`controllerName` une la vista con su controlador, así que UI5 lo carga automáticamente.

### 4. `controller/App.controller.ts`: la lógica y los datos

- **`onInit()`** se ejecuta una sola vez, al crearse la vista. Crea un `JSONModel` con los datos (`recipient.name = "Mundo"`) y lo asigna a la vista con `setModel`.
- **`onShowHello()`** se ejecuta al pulsar el botón y muestra un mensaje breve con `MessageToast`.

### 5. El data binding: cómo llegan los datos a la pantalla

En la vista, las llaves enlazan un control con un dato del modelo:

```xml
<Input value="{/recipient/name}"
    description="Hola {/recipient/name}"
    valueLiveUpdate="true" />
```

`{/recipient/name}` significa: "en el modelo, entra en `recipient` y toma `name`". Por eso, al cargar, el campo contiene "Mundo" y a su lado se lee "Hola Mundo".

El enlace funciona en los dos sentidos: al escribir en el campo, cambia el dato del modelo, y todo lo enlazado a ese dato se actualiza. `valueLiveUpdate="true"` hace que ocurra con cada letra, en vez de esperar a que salgas del campo.

## ¿Y los demás ficheros?

- **`manifest.json`**: es la ficha de la aplicación (identificador, tipo, título y versión). La UI5 CLI lee de aquí `sap.app.id` al arrancar el servidor. De momento la app no lo usa en el navegador, porque `index.ts` crea la vista directamente.
- **TypeScript**: el navegador no entiende ficheros `.ts`. Cuando pide `index.js` o `App.controller.js`, `ui5-tooling-transpile` convierte el `.ts` correspondiente a JavaScript al momento. Los `import` se transforman en `sap.ui.define`, el sistema de módulos de UI5.

## Resumen

1. El navegador abre `index.html`, que carga UI5.
2. UI5 ejecuta `index.ts`, que crea la vista.
3. Al crear la vista se carga su controlador y se ejecuta `onInit`, que le da los datos.
4. Las llaves `{...}` de la vista toman esos datos del modelo.
5. `placeAt("content")` pone el resultado en la página.
6. A partir de ahí, UI5 reacciona a lo que hace el usuario: si pulsa el botón, se ejecuta `onShowHello`; si escribe, se actualizan el modelo y el saludo.
