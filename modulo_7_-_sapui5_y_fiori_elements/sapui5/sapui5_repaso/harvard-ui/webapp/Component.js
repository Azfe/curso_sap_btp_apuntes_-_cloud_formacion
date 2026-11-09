sap.ui.define([
    "sap/ui/core/UIComponent",
    "com/azup/harvardui/harvardui/model/models"
], (UIComponent, models) => {
    "use strict";

    return UIComponent.extend("com.azup.harvardui.harvardui.Component", {
        metadata: {
            manifest: "json",
            interfaces: [
                "sap.ui.core.IAsyncContentCreation"
            ]
        },

        init() {
            // call the base component's init function
            UIComponent.prototype.init.apply(this, arguments);

            // set the device model
            this.setModel(models.createDeviceModel(), "device");

            // enable routing
            this.getRouter().initialize();
        }
    });
});