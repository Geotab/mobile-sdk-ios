// Copyright © 2021 Geotab Inc. All rights reserved.

(async function (callerId) {
    try {
        var userNames = window.webViewLayer.getApiUserNames();
        if (userNames == null || userNames.length == 0) {
            throw new Error("No users");
        }
        var api = window.webViewLayer.getApi(userNames[0]);
        var hos = await api.mobile.user.getHosRuleSet();
        window.geotabModules.{{moduleName}}.{{functionName}}({callerId: callerId, result: JSON.stringify(hos)}, (error, res) => {});
    } catch(err) {
        window.geotabModules.{{moduleName}}.{{functionName}}({callerId: callerId, error: err.message}, (error, res) => {});
        throw err;
    }
})("{{callerId}}");
