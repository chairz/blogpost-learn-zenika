(() => {
  const root = document.documentElement;
  let choice = null;
  try {
    const saved = localStorage.getItem('learning-notes-theme');
    if (saved === 'light' || saved === 'dark') choice = saved;
  } catch (_) {
    // Theme switching still works when browser storage is unavailable.
  }

  function applyTheme() {
    const dark = choice !== 'light';
    root.dataset.theme = dark ? 'dark' : 'light';
    const button = document.getElementById('theme-toggle');
    if (button) {
      button.hidden = false;
      button.setAttribute('aria-pressed', String(dark));
    }
  }

  applyTheme();
  document.addEventListener('DOMContentLoaded', () => {
    applyTheme();
    document.getElementById('theme-toggle').addEventListener('click', () => {
      choice = root.dataset.theme === 'dark' ? 'light' : 'dark';
      try {
        localStorage.setItem('learning-notes-theme', choice);
      } catch (_) {}
      applyTheme();
    });
  });
})();
