sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], (Controller, Filter, FilterOperator) => {
    "use strict";

    return Controller.extend("com.azup.harvardui.harvardui.controller.harvard-ui", {
        onInit() {
        },

        onSearch(oEvent) {
            const sQuery = (oEvent.getParameter("query") || "").trim();
            const aFilters = [];

            if (sQuery) {
                // "Ana Garcia" -> ["Ana", "Garcia"]: cada palabra debe aparecer
                // en el nombre O en el apellido (sin distinguir mayúsculas)
                const aWordFilters = sQuery.split(/\s+/).map((sWord) => new Filter({
                    filters: [
                        new Filter({ path: "name", operator: FilterOperator.Contains, value1: sWord, caseSensitive: false }),
                        new Filter({ path: "surname", operator: FilterOperator.Contains, value1: sWord, caseSensitive: false })
                    ],
                    and: false
                }));

                // Todas las palabras tienen que cumplirse a la vez
                aFilters.push(new Filter({ filters: aWordFilters, and: true }));
            }

            // Con la búsqueda vacía, aFilters = [] y se vuelve a mostrar a todos los alumnos
            this.byId("studentsList").getBinding("items").filter(aFilters);
        }
    });
});
