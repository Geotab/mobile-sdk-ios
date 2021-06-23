//
//  Module.DeviceReady.Scripts.js
//  GeotabDriveSDK
//
//  Created by Yunfeng Liu on 2021-02-08.
//

(function() {
    window.addEventListener("load", function() {
        var event = new Event('deviceready');
        document.dispatchEvent(event);
    });
})();
