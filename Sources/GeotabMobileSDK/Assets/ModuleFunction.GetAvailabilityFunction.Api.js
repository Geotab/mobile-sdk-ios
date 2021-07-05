//
//  ModuleFunction.GetAvailabilityFunction.js
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2020-01-02.
//

(async function (callerId) {
    try {
        var userNames = window.webViewLayer.getApiUserNames();
        if (userNames == null || userNames.length == 0) {
            throw new Error("No users");
        }
        var api = window.webViewLayer.getApi(userNames[0]);
        var availability = await api.mobile.user.getAvailability();
        window.geotabModules.{{moduleName}}.{{functionName}}({callerId: callerId, result: JSON.stringify(availability)}, (error, res) => {});
    } catch(err) {
        window.geotabModules.{{moduleName}}.{{functionName}}({callerId: callerId, error: err.message}, (error, res) => {});
        throw err;
    }
})("{{callerId}}");
