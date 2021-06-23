//
//  ModuleFunction.on.Script.js
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-30.
//

window.{{geotabModules}}.{{moduleName}}.{{functionName}} = function (eventName, callback) {
    if (typeof eventName != "string" || eventName == "") {
        throw new Error("eventName should be a string type and non-empty");
    }
    const mod = window.{{geotabModules}}.{{moduleName}};
    if (mod.onListeners == null) {
        mod.onListeners = {};
    }
    if (mod.onListeners[eventName] == null) {
        mod.onListeners[eventName] = [];
    }
    if (mod.onListeners[eventName].indexOf(callback) >= 0) {
        return;
    }
    mod.onListeners[eventName].push(callback);
    if (mod.___onCallback == null) {
        mod.___onCallback = function (error, response) {
            const eventName = response.event.event;
            if (mod.onListeners[eventName] == null && mod.onListeners[eventName].length == 0) {
                return;
            }
            mod.onListeners[eventName].forEach((cb) => {
                try { cb(response.notification, response.event); } catch (err) { }
            });
        };
    }
    window.webkit.messageHandlers.{{moduleName}}.postMessage(JSON.stringify({ function: '{{functionName}}', callback: "window.{{geotabModules}}.{{moduleName}}.___onCallback", params: Object.keys(mod.onListeners) }));
};
