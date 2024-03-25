(async (callerId) => {
  try {
    const userName = '{{userName}}';
    if (userName == null || userName === '') {
      throw new Error('No users');
    }
    const api = window.webViewLayer.getApi(userName);
    const hos = await api.mobile.user.getHosRuleSet();
    window.geotabModules.{{moduleName}}.{{functionName}}(
      { callerId, result: JSON.stringify(hos) },
      () => {},
    );
  } catch (err) {
    window.geotabModules.{{moduleName}}.{{functionName}}(
      { callerId, error: err.message },
      () => {},
    );
    throw err;
  }
})('{{callerId}}');
