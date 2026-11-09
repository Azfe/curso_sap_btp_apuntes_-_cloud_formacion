/*global QUnit*/

sap.ui.define([
	"com/azup/harvardui/harvardui/controller/harvard-ui.controller"
], function (Controller) {
	"use strict";

	QUnit.module("harvard-ui Controller");

	QUnit.test("I should test the harvard-ui controller", function (assert) {
		var oAppController = new Controller();
		oAppController.onInit();
		assert.ok(oAppController);
	});

});
