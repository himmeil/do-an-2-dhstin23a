(() => {
  const splash = document.getElementById('app-loading');
  const progressBar = document.getElementById('app-loading-indicator');
  const progressFill = document.getElementById('app-loading-progress');
  const percentLabel = document.getElementById('app-loading-percent');
  const statusLabel = document.getElementById('app-loading-status-text');

  if (!splash || !progressBar || !progressFill || !percentLabel || !statusLabel) {
    throw new Error('Không tìm thấy thành phần màn hình khởi động.');
  }

  splash.classList.add('is-initializing');

  let hasStarted = false;

  const startCompletion = () => {
    if (hasStarted) return;
    hasStarted = true;

    splash.classList.remove('is-initializing');
    splash.classList.add('is-completing');
    splash.setAttribute('aria-label', 'Đang hoàn tất khởi động ứng dụng');
    progressBar.setAttribute('aria-label', 'Đang hoàn tất');
    statusLabel.textContent = 'HOÀN THÀNH';

    const duration = 1000;
    const startTime = performance.now();

    const updateProgress = (now) => {
      const progress = Math.min(1, (now - startTime) / duration);
      const percent = Math.floor(progress * 100);

      progressFill.style.width = `${progress * 100}%`;
      percentLabel.textContent = `${percent}%`;
      progressBar.setAttribute('aria-valuenow', String(percent));

      if (progress < 1) {
        window.requestAnimationFrame(updateProgress);
        return;
      }

      statusLabel.textContent = 'ĐANG VÀO APP';
      splash.setAttribute('aria-label', 'Đang vào ứng dụng');
      progressBar.setAttribute('aria-label', 'Đã tải xong, đang vào ứng dụng');

      window.setTimeout(() => {
        splash.classList.add('is-hidden');
        window.setTimeout(() => splash.remove(), 300);
      }, 1000);
    };

    window.requestAnimationFrame(updateProgress);
  };

  window.addEventListener('app-ready', startCompletion, { once: true });

  window.addEventListener(
    'app-startup-error',
    () => {
      statusLabel.textContent = 'KHÔNG THỂ MỞ ỨNG DỤNG';
      splash.classList.add('is-error');
    },
    { once: true },
  );
})();
