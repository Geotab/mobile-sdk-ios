(() => {
  window.addEventListener('load', () => {
    const event = new Event('deviceready');
    document.dispatchEvent(event);
  });
})();
