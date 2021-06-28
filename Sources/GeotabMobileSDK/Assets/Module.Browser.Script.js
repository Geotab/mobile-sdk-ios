
window.open = function(url, target, options) {
    if (url == null) throw new Error("URL is required");
    window.geotabModules.browser.openBrowserWindow({
        url: url,
        target: target || "_blank",
        features: options
    }, (err, url) => {});
    return {
        close: function() {
            if (target == "_blank") {
              return
            }
            window.geotabModules.browser.closeBrowserWindow(undefined, () => {});
        }
    }
};
