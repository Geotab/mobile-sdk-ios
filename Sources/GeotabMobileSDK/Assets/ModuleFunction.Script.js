//
//  Module.Scripts.js
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-29.
//


window.{{geotabModules}}.{{moduleName}}.{{functionName}} = function(params, callback) {
var nativeCallback = "{{callbackPrefix}}" + Math.random().toString(36).substring(2);
    window.{{geotabNativeCallbacks}}[nativeCallback] = function (error, response) {
                callback(error, response);
        delete window.{{geotabNativeCallbacks}}[nativeCallback];
            };
    window.webkit.messageHandlers.{{moduleName}}.postMessage(JSON.stringify({ function: '{{functionName}}', callback: "{{geotabNativeCallbacks}}." + nativeCallback, params: params }));
        };
