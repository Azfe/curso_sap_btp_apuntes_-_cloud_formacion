import Controller from "sap/ui/core/mvc/Controller";
import MessageToast from "sap/m/MessageToast";
import JSONModel from "sap/ui/model/json/JSONModel";
import SelectionModel from "sap/ui/model/SelectionModel";

/**
 * @namespace ui5.tutorial.walkthrough.controller
 */
export default class App extends Controller {
    onInit(){
        // Añadir datos al modelo en la vista
        const data = {
            recipient: {
                name: "Mundo"
            }
        }
        // Definir el modelo con los datos
        const dataModel = new JSONModel(data)
        // Vincular el modelo a la vista
        this.getView()?.setModel(dataModel)
    }
    onShowHello(): void {
        // Mostrar un mensaje breve de UI5
        MessageToast.show("Hello world")
    }
}
