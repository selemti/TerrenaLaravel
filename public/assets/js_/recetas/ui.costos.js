(() => {
  const { qs } = window.__UI_COMMON__ || {};

  function formatMoney(n){ return (Number(n)||0).toFixed(2); }

  /** Pinta BOM en tbody */
  function renderBOM(tbody, bom = []) {
    if (!tbody) return;
    tbody.innerHTML = '';
    bom.forEach(row => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${row.nombre ?? row.item_name ?? row.sku ?? ''}</td>
        <td class="text-end">${row.qty ?? 0} ${row.um ?? ''}</td>
        <td class="text-end">${formatMoney(row.costo_unitario ?? 0)}</td>
        <td class="text-end fw-bold">${formatMoney(row.costo_linea ?? 0)}</td>
      `;
      if (row.warn_conversion) tr.classList.add('table-warning');
      tbody.appendChild(tr);
    });
  }

  function renderKPI(container, kpi) {
    if (!container) return;
    const { costoBase=0, costoMods=0, costoTotal=0, precioSugerido=0, margenObjetivo=0 } = kpi || {};
    container.innerHTML = `
      <div class="row g-3">
        <div class="col-sm-6 col-lg-3"><div class="card"><div class="card-body">
          <div class="text-muted small">Costo Base</div>
          <div class="fs-5">$${formatMoney(costoBase)}</div>
        </div></div></div>
        <div class="col-sm-6 col-lg-3"><div class="card"><div class="card-body">
          <div class="text-muted small">Costo Mods</div>
          <div class="fs-5">$${formatMoney(costoMods)}</div>
        </div></div></div>
        <div class="col-sm-6 col-lg-3"><div class="card"><div class="card-body">
          <div class="text-muted small">Costo Total</div>
          <div class="fs-5">$${formatMoney(costoTotal)}</div>
        </div></div></div>
        <div class="col-sm-6 col-lg-3"><div class="card"><div class="card-body">
          <div class="text-muted small">Precio sugerido (margen ${margenObjetivo||0}%)</div>
          <div class="fs-5">$${formatMoney(precioSugerido)}</div>
        </div></div></div>
      </div>
    `;
  }

  window.__UI_COSTOS__ = { renderBOM, renderKPI, formatMoney };
})();
