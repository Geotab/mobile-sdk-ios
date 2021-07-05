//
//  ModuleFunction.GetUserFunction.js
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-29.
//

(async function (callerId) {
    try {
        var userNames = window.webViewLayer.getApiUserNames();
        if (userNames == null || userNames.length == 0) {
            throw new Error("No users");
        }
        const device = require("utils/addinHelper").getExtendedAppState(window.driveApp.manager.store.getState().mobile)
        window.geotabModules.{{moduleName}}.{{functionName}}({callerId: callerId, result: JSON.stringify(device)}, (error, res) => {});
    } catch(err) {
        window.geotabModules.{{moduleName}}.{{functionName}}({callerId: callerId, error: err.message}, (error, res) => {});
        throw err;
    }
})("{{callerId}}");
