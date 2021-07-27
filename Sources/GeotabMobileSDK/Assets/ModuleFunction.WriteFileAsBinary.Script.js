// Copyright © 2021 Geotab Inc. All rights reserved.

window.{{geotabModules}}.{{moduleName}}.{{functionName}} = function(params, callback) {
    if (params.data instanceof ArrayBuffer !== true) {
        throw new Error("data must be ArrayBuffer");
    }
    var options = {
        path: params.path,
        data: [].slice.call(new Uint8Array(params.data)),
        offset: params.offset
    };
    var nativeCallback = "{{callbackPrefix}}" + Math.random().toString(36).substring(2);
    window.{{geotabNativeCallbacks}}[nativeCallback] = function (error, response) {
                callback(error, response);
        delete window.{{geotabNativeCallbacks}}[nativeCallback];
            };
    window.webkit.messageHandlers.{{moduleName}}.postMessage(JSON.stringify({ function: '{{functionName}}', callback: "{{geotabNativeCallbacks}}." + nativeCallback, params: options }));
};
