(() => {
  function qs(s, r=document){ return r.querySelector(s); }
  function qsa(s, r=document){ return Array.from(r.querySelectorAll(s)); }

  function renderOptions(selectEl, rows, {value='id', label='nombre', placeholder='--'} = {}) {
    if (!selectEl) return;
    selectEl.innerHTML = '';
    if (placeholder) {
      const opt0 = document.createElement('option');
      opt0.value = ''; opt0.textContent = placeholder;
      selectEl.appendChild(opt0);
    }
    rows.forEach(r => {
      const o = document.createElement('option');
      o.value = r[value]; o.textContent = r[label] ?? r[value];
      selectEl.appendChild(o);
    });
  }

  window.__UI_COMMON__ = { qs, qsa, renderOptions };
})();
