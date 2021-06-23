//
//  ModuleFunction.LocalNotification.Cancel.Script.js
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-02-04.
//

window.{{geotabModules}}.{{moduleName}}.{{functionName}} = function (id, callback) {
    
    const mod = window.{{geotabModules}}.{{moduleName}};
    
    var nativeCallback = "{{callbackPrefix}}" + Math.random().toString(36).substring(2);
    
    window.{{geotabNativeCallbacks}}[nativeCallback] = function (error, notification) {
        if (error != null) {
            callback(error, undefined);
            return;
        }
        const actions = notification.actions;
        if (actions != null && actions.length > 0) {
            actions.forEach(action => {
                mod.{{off}}(action.id, (err, result) => {});
            });
        }
        callback(error, notification);
        delete window.{{geotabNativeCallbacks}}[nativeCallback];
    };
    
    window.webkit.messageHandlers.{{moduleName}}.postMessage(JSON.stringify({ function: '{{functionName}}', callback: "{{geotabNativeCallbacks}}." + nativeCallback, params: id }));
};
