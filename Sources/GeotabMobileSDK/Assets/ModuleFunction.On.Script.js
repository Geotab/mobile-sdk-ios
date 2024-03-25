window.{{geotabModules}}.{{moduleName}}.{{functionName}} = (eventName, callback) => {
  if (typeof eventName !== 'string' || eventName === '') {
    throw new Error('eventName should be a string type and non-empty');
  }
  const mod = window.{{geotabModules}}.{{moduleName}};
  if (mod.onListeners == null) {
    mod.onListeners = {};
  }
  if (mod.onListeners[eventName] == null) {
    mod.onListeners[eventName] = [];
  }
  if (mod.onListeners[eventName].indexOf(callback) >= 0) {
    return;
  }
  mod.onListeners[eventName].push(callback);
  if (mod.___onCallback == null) {
    mod.___onCallback = (error, response) => {
      const responseEventName = response.event.event;
      if (
        mod.onListeners[responseEventName] == null
        && mod.onListeners[responseEventName].length === 0
      ) {
        return;
      }
      mod.onListeners[responseEventName].forEach(async (cb) => {
        try {
          await cb(response.notification, response.event);
        } catch {
          // continue
        }
      });
    };
  }
  window.webkit.messageHandlers.{{moduleName}}.postMessage(
    JSON.stringify({
      function: '{{functionName}}',
      callback: 'window.{{geotabModules}}.{{moduleName}}.___onCallback',
      params: Object.keys(mod.onListeners),
    }),
  );
};
