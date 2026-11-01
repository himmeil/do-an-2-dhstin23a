{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  onEntrypointLoaded: async (engineInitializer) => {
    const notifyAppReady = () => {
      if (window.__appReadyNotified) return;
      window.__appReadyNotified = true;
      window.dispatchEvent(new Event('app-ready'));
    };

    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();

      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          notifyAppReady();
        });
      });

      window.setTimeout(notifyAppReady, 1800);
    } catch (error) {
      window.dispatchEvent(new Event('app-startup-error'));
      throw error;
    }
  }
});
