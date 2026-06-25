// Flutter web bootstrap
(function() {
  var _flutter = window._flutter || {};
  _flutter.loader = {
    load: function(options) {
      options = options || {};
      var serviceWorkerSettings = options.serviceWorkerSettings || {};
      var onEntrypointLoaded = options.onEntrypointLoaded || function() {};

      var entrypointUrl = options.entrypointUrl || 'main.dart.js';
      var serviceWorkerUrl = serviceWorkerSettings.serviceWorkerUrl || 'flutter_service_worker.js';

      // Load the main entrypoint
      var script = document.createElement('script');
      script.src = entrypointUrl;
      script.type = 'application/javascript';
      script.onload = function() {
        // The entrypoint calls _flutter.loader.loadEntrypoint with the engine initializer
        if (typeof _flutter.loader.loadEntrypoint === 'function') {
          _flutter.loader.loadEntrypoint({
            entrypointUrl: entrypointUrl,
            onEntrypointLoaded: onEntrypointLoaded
          });
        }
      };
      document.body.appendChild(script);

      // Register service worker for PWA support
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register(serviceWorkerUrl)
          .then(function(registration) {
            console.log('LoveSync service worker registered:', registration.scope);
          })
          .catch(function(error) {
            console.log('LoveSync service worker registration failed:', error);
          });
      }
    },
    loadEntrypoint: function(options) {
      // This is called by the generated main.dart.js
      if (typeof options.onEntrypointLoaded === 'function') {
        // Pass the engine initializer
        options.onEntrypointLoaded({
          initializeEngine: function(config) {
            return Promise.resolve({
              runApp: function() {
                if (typeof _flutter.loader.runApp === 'function') {
                  return _flutter.loader.runApp(config);
                }
                console.warn('LoveSync: runApp not available');
              }
            });
          }
        });
      }
    },
    runApp: function(config) {
      // Called when the app is ready to run
      if (typeof window._flutter.runApp === 'function') {
        return window._flutter.runApp(config);
      }
      console.warn('LoveSync: Flutter app engine not initialized');
    }
  };
  window._flutter = _flutter;
})();
