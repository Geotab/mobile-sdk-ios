window.open = (url, target, options) => {
  if (url == null) throw new Error('URL is required');
  window.geotabModules.browser.openBrowserWindow({
    url,
    target: target || '_blank',
    features: options,
  }, () => {});
  return {
    close() {
      if (target === '_blank') {
        return;
      }
      window.geotabModules.browser.closeBrowserWindow(undefined, () => {});
    },
  };
};
