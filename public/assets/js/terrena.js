// Terrena JS – Layout + Dashboard
// Rutas de logos
const LOGO_FULL = (window.__BASE__ || '') + '/assets/img/logo.svg';
const LOGO_MINI = (window.__BASE__ || '') + '/assets/img/logo2.svg';

document.addEventListener('DOMContentLoaded', () => {
  const sidebar             = document.getElementById('sidebar');
  const sidebarCollapseBtn  = document.getElementById('sidebarCollapse');        // desktop
  const sidebarToggleMobile = document.getElementById('sidebarToggleMobile');    // móvil
  const logoImg             = document.getElementById('logoImg');                // <img> del logo

  // ===== Toggle MÓVIL (off-canvas) =====
  sidebarToggleMobile?.addEventListener('click', (e) => {
    e.preventDefault();
    if (window.innerWidth < 992) sidebar?.classList.toggle('show');
  });
  // Cierra tocando fuera (solo móvil)
  document.addEventListener('click', (ev) => {
    if (window.innerWidth >= 992) return;
    if (!sidebar?.classList.contains('show')) return;
    const clickedInside = sidebar.contains(ev.target) || sidebarToggleMobile?.contains(ev.target);
    if (!clickedInside) sidebar.classList.remove('show');
  });

  // ===== Collapse DESKTOP =====
  sidebarCollapseBtn?.addEventListener('click', (e) => {
    e.preventDefault();
    if (!sidebar) return;
    sidebar.classList.toggle('collapsed');

    // Cambia logo según estado
    if (logoImg) {
      const isCollapsed = sidebar.classList.contains('collapsed');
      logoImg.src = isCollapsed ? LOGO_MINI : LOGO_FULL;
      logoImg.alt = isCollapsed ? 'Terrena mini' : 'Terrena';
    }
  });
  // Ajuste si recarga colapsado (por CSS server-side, si aplica)
  if (logoImg && sidebar?.classList.contains('collapsed')) {
    logoImg.src = LOGO_MINI;
  }

  // ===== Reloj / Fecha =====
  tickClock();
  setInterval(tickClock, 1000);

  // ===== Filtros =====
  setupFilters();

  // ===== Listas (header y tablero) =====
  renderHeaderAlerts([]);
  renderKpiRegisters([]);
  renderActivity();
  renderOrders([]);
});

// ======================= Datos reales (API) =======================
window.Terrena = window.Terrena || {};
window.Terrena.initDashboardCharts = async function (range) {
  const base = (window.__BASE__ || '') + '/api/reports';
  const today = new Date().toISOString().slice(0, 10);
  const desde = range?.desde || today;
  const hasta = range?.hasta || desde;
  const rangeParams = { desde, hasta };

  const buildQuery = (params = {}) => {
    const usp = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value === undefined || value === null || value === '') return;
      usp.append(key, value);
    });
    const qs = usp.toString();
    return qs ? `?${qs}` : '';
  };

  const fetchReport = async (path) => {
    const res = await fetch(base + path, { headers: { Accept: 'application/json' } });
    if (!res.ok) {
      const err = new Error(`GET ${path} → ${res.status}`);
      err.status = res.status;
      throw err;
    }
    const payload = await res.json().catch(() => null);
    if (!payload || payload.ok === false) {
      const err = new Error(payload?.message || `Error al cargar ${path}`);
      err.payload = payload;
      throw err;
    }
    return payload;
  };

  try {
    const [
      kpisSucursal,
      ventasDia,
      ventasFamilia,
      ventasHora,
      ventasTop,
      ticketPromedio,
      itemsResumen,
      formasPago,
      alertasAnomalias
    ] = await Promise.all([
      fetchReport(`/kpis/sucursal${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/dia${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/familia${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/hora${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/top${buildQuery({ ...rangeParams, limit: 5 })}`),
      fetchReport(`/ticket/promedio${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/items_resumen${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/formas${buildQuery(rangeParams)}`),
      fetchReport(`/anomalias${buildQuery({ limit: 6 })}`)
    ]);

    const kpiRows = kpisSucursal.data || [];
    const totalVentas = kpiRows.reduce((sum, row) => {
      const efectivo = Number(row.sistema_efectivo || 0);
      const noEfectivo = Number(row.sistema_no_efectivo || 0);
      return sum + efectivo + noEfectivo;
    }, 0);

    setText('kpi-sales-today', money(totalVentas));
    setText('kpi-avg-ticket', money(Number(ticketPromedio.ticket_promedio || 0)));
    setText('kpi-items-sold', Number(itemsResumen.unidades || 0).toLocaleString('es-MX'));

    const topProducts = aggregateTopProducts(ventasTop.data || []);
    const bestProduct = topProducts[0];
    if (bestProduct) {
      setText('kpi-star-product', bestProduct.descripcion || bestProduct.plu || '—');
      setText('kpi-star-sales', money(Number(bestProduct.venta_total || 0)));
    } else {
      setText('kpi-star-product', '—');
      setText('kpi-star-sales', '—');
    }

    const alerts = alertasAnomalias.data || [];
    setText('kpi-alerts', alerts.length.toLocaleString('es-MX'));

    renderHeaderAlerts(alerts);
    renderKpiRegisters(kpiRows, { fechaObjetivo: hasta });

    renderSalesTrendChart(ventasDia.data || []);
    renderSalesByHourChart(ventasHora.data || []);
    renderBranchPaymentsChart(ventasFamilia.data || []);
    renderTopProductsChart(topProducts);
    renderPaymentChart(formasPago.data || []);
  } catch (error) {
    console.error('Error cargando dashboard', error);
    toast('No fue posible obtener los datos del dashboard.', 'danger');
    setText('kpi-sales-today', '—');
    setText('kpi-avg-ticket', '—');
    setText('kpi-items-sold', '—');
    setText('kpi-star-product', '—');
    setText('kpi-star-sales', '—');
    setText('kpi-alerts', '0');
    renderKpiRegisters([]);
    renderHeaderAlerts([]);
    ['salesTrendChart', 'salesByHourChart', 'branchPaymentsChart', 'topProductsChart', 'paymentChart'].forEach(destroyChart);
  }
};

function setText(id, value) {
  const el = document.getElementById(id);
  if (el) el.textContent = value;
}

function destroyChart(target) {
  const canvas = typeof target === 'string' ? document.getElementById(target) : target;
  if (canvas && canvas._chart) {
    canvas._chart.destroy();
    delete canvas._chart;
  }
}

function aggregateTopProducts(rows) {
  const map = new Map();
  rows.forEach((row) => {
    if (!row) return;
    const key = row.plu || row.descripcion || row.item_key || '—';
    const current = map.get(key) || {
      plu: row.plu || key,
      descripcion: row.descripcion || '',
      venta_total: 0,
      unidades: 0
    };
    current.venta_total += Number(row.venta_total || 0);
    current.unidades += Number(row.unidades || 0);
    map.set(key, current);
  });
  return Array.from(map.values())
    .sort((a, b) => Number(b.venta_total || 0) - Number(a.venta_total || 0))
    .slice(0, 5);
}

function renderSalesTrendChart(rows) {
  if (typeof Chart === 'undefined') return;
  const canvas = document.getElementById('salesTrendChart');
  if (!canvas) return;

  const sorted = Array.isArray(rows)
    ? rows.filter(r => r && r.fecha).sort((a, b) => new Date(a.fecha) - new Date(b.fecha))
    : [];
  const labels = sorted.map(r => formatDateLabel(r.fecha));
  const data = sorted.map(r => Number(r.venta_total || 0));

  destroyChart(canvas);
  const chartLabels = labels.length ? labels : ['—'];
  const chartData = data.length ? data : [0];

  canvas._chart = new Chart(canvas.getContext('2d'), {
    type: 'line',
    data: {
      labels: chartLabels,
      datasets: [{
        label: 'Ventas ($)',
        data: chartData,
        fill: true,
        backgroundColor: 'rgba(233,122,58,0.15)',
        borderColor: '#E97A3A',
        tension: 0.35,
        pointRadius: 3
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false } },
        y: { beginAtZero: true }
      }
    }
  });
}

function renderSalesByHourChart(rows) {
  if (typeof Chart === 'undefined') return;
  const canvas = document.getElementById('salesByHourChart');
  if (!canvas) return;

  const aggregated = new Map();
  (Array.isArray(rows) ? rows : []).forEach((row) => {
    if (!row || !row.hora) return;
    const key = row.hora;
    aggregated.set(key, (aggregated.get(key) || 0) + Number(row.venta_total || 0));
  });

  const entries = Array.from(aggregated.entries()).sort((a, b) => new Date(a[0]) - new Date(b[0]));
  const labels = entries.map(([hour]) => formatHourLabel(hour));
  const data = entries.map(([, total]) => total);

  destroyChart(canvas);
  const chartLabels = labels.length ? labels : ['—'];
  const chartData = data.length ? data : [0];

  canvas._chart = new Chart(canvas.getContext('2d'), {
    type: 'bar',
    data: {
      labels: chartLabels,
      datasets: [{
        label: 'Venta ($)',
        data: chartData,
        backgroundColor: '#4e79a7'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false } },
        y: { beginAtZero: true }
      }
    }
  });
}

function renderBranchPaymentsChart(rows) {
  if (typeof Chart === 'undefined') return;
  const canvas = document.getElementById('branchPaymentsChart');
  if (!canvas) return;

  const branchesSet = new Set();
  const familiesSet = new Set();
  const lookup = new Map();

  (Array.isArray(rows) ? rows : []).forEach((row) => {
    if (!row) return;
    const branch = row.sucursal_id || row.sucursal || 'Sin sucursal';
    const family = row.familia || 'OTROS';
    const key = `${branch}::${family}`;
    branchesSet.add(branch);
    familiesSet.add(family);
    lookup.set(key, (lookup.get(key) || 0) + Number(row.venta_total || 0));
  });

  const branches = Array.from(branchesSet);
  const families = Array.from(familiesSet);
  const palette = ['#4e79a7', '#f28e2b', '#e15759', '#76b7b2', '#59a14f', '#edc948', '#b07aa1', '#ff9da7'];

  destroyChart(canvas);
  if (!branches.length || !families.length) {
    return;
  }

  const datasets = families.map((family, index) => ({
    label: family,
    data: branches.map(branch => lookup.get(`${branch}::${family}`) || 0),
    backgroundColor: palette[index % palette.length],
    borderWidth: 0
  }));

  canvas._chart = new Chart(canvas.getContext('2d'), {
    type: 'bar',
    data: { labels: branches, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: true } },
      scales: {
        x: { stacked: true, grid: { display: false } },
        y: { stacked: true, beginAtZero: true }
      }
    }
  });
}

function renderTopProductsChart(rows) {
  if (typeof Chart === 'undefined') return;
  const canvas = document.getElementById('topProductsChart');
  if (!canvas) return;

  const list = Array.isArray(rows) ? rows : [];
  const labels = list.map(row => row.descripcion || row.plu || '—');
  const data = list.map(row => Number(row.venta_total || 0));

  destroyChart(canvas);
  const chartLabels = labels.length ? labels : ['—'];
  const chartData = data.length ? data : [0];

  canvas._chart = new Chart(canvas.getContext('2d'), {
    type: 'bar',
    data: {
      labels: chartLabels,
      datasets: [{
        label: 'Venta ($)',
        data: chartData,
        backgroundColor: '#9c755f'
      }]
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { beginAtZero: true },
        y: { grid: { display: false } }
      }
    }
  });
}

function renderPaymentChart(rows) {
  if (typeof Chart === 'undefined') return;
  const canvas = document.getElementById('paymentChart');
  if (!canvas) return;

  const list = Array.isArray(rows) ? rows : [];
  const labels = list.map(row => row.codigo_fp || 'OTROS');
  const data = list.map(row => Number(row.monto || 0));
  const palette = ['#59a14f', '#e15759', '#f28e2b', '#76b7b2', '#edc948', '#b07aa1', '#499894'];

  destroyChart(canvas);
  const chartLabels = labels.length ? labels : ['—'];
  const chartData = data.length ? data : [0];

  canvas._chart = new Chart(canvas.getContext('2d'), {
    type: 'doughnut',
    data: {
      labels: chartLabels,
      datasets: [{
        data: chartData,
        backgroundColor: chartLabels.map((_, idx) => palette[idx % palette.length])
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { position: 'bottom' } }
    }
  });
}

function formatDateLabel(value) {
  const date = value ? new Date(value) : null;
  if (!date || Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('es-MX', { day: '2-digit', month: 'short' });
}

function formatHourLabel(value) {
  const date = value ? new Date(value) : null;
  if (!date || Number.isNaN(date.getTime())) return value || '—';
  return date.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
}

function toISODateOnly(value) {
  if (!value) return '';
  if (value instanceof Date) return toISODate(value);
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) {
    return String(value).slice(0, 10);
  }
  return toISODate(d);
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// Bind filtros por si el handler original no llama a BD
/* =============== Reloj =============== */
function tickClock(){
  const now = new Date();
  const hh = String(now.getHours()).padStart(2,'0');
  const mm = String(now.getMinutes()).padStart(2,'0');
  const dd = String(now.getDate()).padStart(2,'0');
  const mo = String(now.getMonth()+1).padStart(2,'0');
  const yyyy = now.getFullYear();

  const topClock    = document.getElementById('live-clock');         // header
  const bottomClock = document.getElementById('live-clock-bottom');  // footer
  const dateEl      = document.getElementById('live-date');          // footer

  if (topClock)    topClock.textContent    = `${hh}:${mm}`;
  if (bottomClock) bottomClock.textContent = `${hh}:${mm}`;
  if (dateEl)      dateEl.textContent      = `${dd}/${mo}/${yyyy}`;
}

/* =============== Filtros =============== */
function setupFilters(){
  const s = document.getElementById('start-date');
  const e = document.getElementById('end-date');
  const btn = document.getElementById('apply-filters');
  if (!s || !e) return;

  const today = new Date();
  const weekAgo = new Date(today); weekAgo.setDate(today.getDate() - 7);

  if (!s.value) s.value = toISODate(weekAgo);
  if (!e.value) e.value = toISODate(today);

  const triggerRefresh = () => {
    const desde = s.value || undefined;
    const hasta = e.value || undefined;
    if (window.Terrena && typeof Terrena.initDashboardCharts === 'function') {
      Terrena.initDashboardCharts({ desde, hasta });
    }
  };

  btn?.addEventListener('click', (ev) => {
    ev.preventDefault();
    triggerRefresh();
  });

  triggerRefresh();
}
function toISODate(d){return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`}

/* =============== Header Alerts (campana) =============== */
function renderHeaderAlerts(rows = []){
  const badge = document.getElementById('hdr-alerts-badge');
  const list  = document.getElementById('hdr-alerts-list');
  if (!badge || !list) return;

  const items = (Array.isArray(rows) ? rows : []).slice(0, 5).map((row) => {
    const rule = (row?.regla || row?.tipo || '').toString();
    const item = row?.item_key || row?.item || row?.descripcion || row?.plu || '';
    const branch = row?.sucursal_id || row?.branch_key || row?.location || '';
    const summaryParts = [rule, item, branch].map(part => (part || '').trim()).filter(Boolean);
    const txt = summaryParts.length ? summaryParts.join(' · ') : 'Movimiento anómalo';
    const ts = row?.ts || row?.fecha || null;
    const minutesAgo = ts ? Math.floor((Date.now() - new Date(ts).getTime()) / 60000) : null;
    const upperRule = rule.toUpperCase();
    let icon = 'fa-triangle-exclamation text-warning';
    if (upperRule.includes('ERROR') || upperRule.includes('NEG') || upperRule.includes('DIF')) {
      icon = 'fa-circle-exclamation text-danger';
    } else if (upperRule.includes('INFO')) {
      icon = 'fa-circle-info text-primary';
    }
    return { icon, txt, minutesAgo };
  });

  if (!items.length) {
    badge.textContent = '0';
    badge.style.display = 'none';
    list.innerHTML = '<div class="px-3 py-2 text-muted small">Sin alertas recientes</div>';
    return;
  }

  badge.textContent = items.length;
  badge.style.display = 'inline-block';
  const reportUrl = (window.__BASE__ || '') + '/reportes';

  list.innerHTML = items.map(a => `
    <a class="hdr-alert" href="${reportUrl}">
      <i class="fa-solid ${a.icon}"></i>
      <span>${escapeHtml(a.txt)}</span>
      <span class="timeago">${escapeHtml(a.minutesAgo != null ? timeago(a.minutesAgo) : '—')}</span>
    </a>`).join('');
}

/* =============== KPIs – Estatus de cajas (tabla) =============== */
function renderKpiRegisters(rows = [], opts = {}){
  const tbody = document.getElementById('kpi-registers');
  if (!tbody) return;

  const data = Array.isArray(rows) ? rows.filter(r => r) : [];
  if (!data.length) {
    tbody.innerHTML = '<tr><td colspan="3" class="text-center text-muted small">Sin datos en el rango seleccionado</td></tr>';
    return;
  }

  const targetDate = opts?.fechaObjetivo;
  let filtered = data;
  if (targetDate) {
    const isoTarget = toISODateOnly(targetDate);
    const matches = data.filter(r => toISODateOnly(r.fecha) === isoTarget);
    if (matches.length) {
      filtered = matches;
    } else {
      const latest = data.reduce((acc, row) => {
        if (!acc) return row;
        return new Date(row.fecha) > new Date(acc.fecha) ? row : acc;
      }, null);
      if (latest) {
        const latestIso = toISODateOnly(latest.fecha);
        filtered = data.filter(r => toISODateOnly(r.fecha) === latestIso);
      }
    }
  }

  const lookup = new Map();
  filtered.forEach((row) => {
    const branch = row.sucursal_id || row.sucursal || 'Sin sucursal';
    const current = lookup.get(branch) || { sucursal: branch, sesiones: 0, vendido: 0 };
    current.sesiones += Number(row.sesiones || 0);
    current.vendido += Number(row.sistema_efectivo || 0) + Number(row.sistema_no_efectivo || 0);
    lookup.set(branch, current);
  });

  const items = Array.from(lookup.values()).sort((a, b) => b.vendido - a.vendido);
  if (!items.length) {
    tbody.innerHTML = '<tr><td colspan="3" class="text-center text-muted small">Sin datos en el rango seleccionado</td></tr>';
    return;
  }

  tbody.innerHTML = items.map(item => {
    const abierto = item.sesiones > 0;
    return `
      <tr>
        <td>${escapeHtml(item.sucursal)}</td>
        <td>${abierto
          ? '<span class="badge text-bg-success">Abierta</span>'
          : '<span class="badge text-bg-secondary">Cerrada</span>'}</td>
        <td class="text-end">${money(Number(item.vendido || 0))}</td>
      </tr>`;
  }).join('');
}

/* =============== Actividad reciente =============== */
function renderActivity(items = []){
  const ul = document.getElementById('activity-list');
  if (!ul) return;
  if (!items.length) {
    ul.innerHTML = '<li class="text-muted small">Sin datos recientes</li>';
    return;
  }
  ul.innerHTML = items.map(i => `
    <li><i class="fa-solid fa-circle small text-muted"></i>
      <span>${escapeHtml(i.txt)}</span>
      <span class="timeago">${escapeHtml(timeago(i.minutesAgo || 0))}</span>
    </li>`).join('');
}

/* =============== Órdenes recientes =============== */
function renderOrders(rows = []){
  const tb = document.getElementById('orders-table');
  if (!tb) return;
  if (!rows.length) {
    tb.innerHTML = '<tr><td colspan="4" class="text-center text-muted small">Sin órdenes en el rango seleccionado</td></tr>';
    return;
  }
  tb.innerHTML = rows.map(r => `
    <tr><td>${escapeHtml(r.ticket)}</td><td>${escapeHtml(r.suc)}</td><td>${escapeHtml(r.hora)}</td><td class="text-end">${money(Number(r.total || 0))}</td></tr>
  `).join('');
}

/* =============== Helpers =============== */
function timeago(mins){
  if (mins < 1) return 'ahora';
  if (mins < 60) return `hace ${mins} min`;
  const h = Math.floor(mins/60); const m = mins%60;
  return `hace ${h}h ${m}m`;
}
function money(n){ return n.toLocaleString('es-MX',{style:'currency',currency:'MXN'}); }
function toast(msg,type='success'){
  const el=document.createElement('div');
  el.className=`alert alert-${type} alert-dismissible fade show`;
  Object.assign(el.style,{position:'fixed',top:'20px',right:'20px',zIndex:'2000',minWidth:'280px'});
  el.innerHTML=`${msg}<button type="button" class="btn-close" data-bs-dismiss="alert"></button>`;
  document.body.appendChild(el); setTimeout(()=>el.remove(),4000);
}

/* === CAJA: Cortes de caja (Precorte → Corte → Postcorte) === */

(function () {
  const $ = (sel, ctx=document) => ctx.querySelector(sel);
  const $$ = (sel, ctx=document) => Array.from(ctx.querySelectorAll(sel));
  const money = (n) => (Number(n)||0).toLocaleString('es-MX',{style:'currency',currency:'MXN'});

  // Si no es la vista de cortes, salir
  if (!$('#tblCortes')) return;

  const base = (window.__BASE__ || (document.body.dataset.base || '')).replace(/\/+$/,'');
  const API = base + '/api/v1';

  // Estado local para modales
  let currentPrecorte = null;

  // Listado principal
  async function loadCortes() {
    const bdate = $('#f_bdate')?.value || '';
    const url = new URL(API + '/caja/abiertas', window.location.origin);
    if (bdate) url.searchParams.set('bdate', bdate);

    const res = await fetch(url, {headers:{'Accept':'application/json'}});
    const rows = await res.json();
    const tbody = $('#tblCortes tbody');
    tbody.innerHTML = '';

    rows.forEach((r, idx) => {
      const badgeStage =
        r.stage === 'postcorte' ? '<span class="badge text-bg-success">postcorte</span>' :
        r.stage === 'corte' ? '<span class="badge text-bg-warning">corte</span>' :
        '<span class="badge text-bg-secondary">precorte</span>';

      const badgeStatus =
        r.status === 'closed' ? '<span class="badge text-bg-secondary">Cerrado</span>' :
        r.status === 'pending' ? '<span class="badge text-bg-warning">Pendiente</span>' :
        '<span class="badge text-bg-success">Abierto</span>';

      // Acciones según etapa
      let actions = '';
      if (r.stage === 'precorte' && r.status === 'open') {
        actions = `
          <button class="btn btn-sm btn-primary me-1 act-open-precorte" data-id="${r.id}">
            <i class="fa-solid fa-door-open me-1"></i>Precorte
          </button>`;
      }
      if (r.stage !== 'postcorte') {
        actions += `
          <button class="btn btn-sm btn-outline-primary me-1 act-open-corte" data-id="${r.id}">
            <i class="fa-solid fa-scale-balanced me-1"></i>Corte
          </button>`;
      }
      if (r.status !== 'closed') {
        actions += `
          <button class="btn btn-sm btn-outline-success act-open-post" data-id="${r.id}">
            <i class="fa-solid fa-clipboard-check me-1"></i>Postcorte
          </button>`;
      }

      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${idx+1}</td>
        <td>${r.sucursal}</td>
        <td>${r.terminal}</td>
        <td>${r.cajero ?? '-'}</td>
        <td>${badgeStage}</td>
        <td>${badgeStatus}</td>
        <td class="text-end">${money(r.vendido)}</td>
        <td class="text-end ${Number(r.difference||0)!==0 ? 'text-danger fw-bold' : ''}">
          ${money(r.difference||0)}
        </td>
        <td class="text-end">${actions}</td>
      `;
      tbody.appendChild(tr);
    });

    // Bind actions
    $$('.act-open-precorte').forEach(btn => btn.addEventListener('click', openPrecorteModal));
    $$('.act-open-corte').forEach(btn => btn.addEventListener('click', openCorteModal));
    $$('.act-open-post').forEach(btn => btn.addEventListener('click', openPostModal));
  }

  // Modal PRECORTE
  function openPrecorteModal(e) {
    const id = e.currentTarget.dataset.id;
    currentPrecorte = { id };
    // reiniciar conteo rápido
    $$('.den-qty').forEach(i => i.value = 0);
    $$('#tblDenominaciones .den-amount').forEach(td => td.textContent = money(0));
    $('#p_cash_total').textContent = money(0);
    $('#p_card').value = 0; $('#p_transfer').value = 0; $('#p_notes').value = '';
    new bootstrap.Modal($('#modalPrecorte')).show();
  }

  function recalcDenoms() {
    let total = 0;
    $$('.den-qty').forEach(inp => {
      const den = Number(inp.dataset.den);
      const qty = Number(inp.value||0);
      const amount = den * qty;
      total += amount;
      const cell = $(`#tblDenominaciones .den-amount[data-den="${den}"]`);
      if (cell) cell.textContent = money(amount);
    });
    $('#p_cash_total').textContent = money(total);
    return total;
  }
  $$('.den-qty').forEach(inp => inp.addEventListener('input', recalcDenoms));

  $('#formPrecorte')?.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    // 1) abrir/crear precorte
    const bdate = $('#p_bdate').value;
    const store = $('#p_store').value;
    const terminal = Number($('#p_terminal').value||0);
    const cajero = $('#p_cajero').value;

    let resp = await fetch(API + '/caja/precorte', {
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ bdate, store_id:store, terminal_id:terminal, user_id:cajero })
    });
    const { precorte_id } = await resp.json();
    currentPrecorte = { id: precorte_id };

    // 2) subir conteo rápido
    const det = [];
    $$('.den-qty').forEach(inp => {
      const den = Number(inp.dataset.den);
      const qty = Number(inp.value||0);
      if (qty>0) det.push({ den, qty });
    });
    await fetch(`${API}/caja/precorte/${precorte_id}/conteo`, {
      method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify(det)
    });

    // 3) declarados
    const cash = recalcDenoms();
    const card = Number($('#p_card').value||0);
    const transfer = Number($('#p_transfer').value||0);
    await fetch(`${API}/caja/precorte/${precorte_id}/decl`, {
      method:'PUT', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ cash, card, transfer, notes: $('#p_notes').value })
    });

    bootstrap.Modal.getInstance($('#modalPrecorte')).hide();
    loadCortes();
  });

  // Modal CORTE
  function openCorteModal(e) {
    const id = e.currentTarget.dataset.id;
    currentPrecorte = { id };
    $('#c_precorte_id').value = id;
    // cargar sistema
    fetch(`${API}/caja/precorte/${id}/sistema`)
      .then(r => r.json()).then(sys => {
        // MOCK: los declarados los tomamos de pantalla precorte (o backend cuando esté listo)
        const decl_cash  = 250.00, decl_card = 1200.00, decl_trans = 150.00;
        const decl_total = decl_cash + decl_card + decl_trans;
        const sys_total  = (Number(sys.sys_cash)||0) + (Number(sys.sys_card)||0) + (Number(sys.sys_transfer)||0);

        $('#c_decl_cash').textContent = money(decl_cash);
        $('#c_decl_card').textContent = money(decl_card);
        $('#c_decl_trans').textContent = money(decl_trans);
        $('#c_decl_total').textContent = money(decl_total);

        $('#c_sys_cash').textContent  = money(sys.sys_cash);
        $('#c_sys_card').textContent  = money(sys.sys_card);
        $('#c_sys_trans').textContent = money(sys.sys_transfer);
        $('#c_sys_total').textContent = money(sys_total);

        $('#c_diff').textContent = money(decl_total - sys_total);
        new bootstrap.Modal($('#modalCorte')).show();
      });
  }

  $('#btnCerrarTicketsCero')?.addEventListener('click', async () => {
    await fetch(`${API}/caja/cerrar-tickets-cero`, {method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ bdate: $('#f_bdate').value })
    });
    // Re-cargar sistema
    const id = $('#c_precorte_id').value;
    const sys = await (await fetch(`${API}/caja/precorte/${id}/sistema`)).json();
    const decl_total = parseMoney($('#c_decl_total').textContent);
    const sys_total  = (Number(sys.sys_cash)||0)+(Number(sys.sys_card)||0)+(Number(sys.sys_transfer)||0);
    $('#c_sys_cash').textContent  = money(sys.sys_cash);
    $('#c_sys_card').textContent  = money(sys.sys_card);
    $('#c_sys_trans').textContent = money(sys.sys_transfer);
    $('#c_sys_total').textContent = money(sys_total);
    $('#c_diff').textContent = money(decl_total - sys_total);
  });

  $('#btnConciliar')?.addEventListener('click', async () => {
    const id = $('#c_precorte_id').value;
    const payload = { /* en real mandarías sys/decl */ };
    const r = await fetch(`${API}/caja/precorte/${id}/conciliar`, {method:'PUT', headers:{'Content-Type':'application/json'}, body: JSON.stringify(payload)});
    await r.json();
    // En mock ya refleja diferencia; solo refresca listado
    loadCortes();
  });

  $('#btnCerrarCorte')?.addEventListener('click', async () => {
    const id = $('#c_precorte_id').value;
    await fetch(`${API}/caja/precorte/${id}/cerrar`, {method:'PUT'});
    bootstrap.Modal.getInstance($('#modalCorte')).hide();
    loadCortes();
  });

  // Modal POSTCORTE
  function openPostModal(e) {
    const id = e.currentTarget.dataset.id;
    currentPrecorte = { id };
    $('#post_precorte_id').value = id;
    $('#post_notes').value = '';
    new bootstrap.Modal($('#modalPost')).show();
  }

  $('#formPost')?.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const id = $('#post_precorte_id').value;
    const notes = $('#post_notes').value;
    await fetch(`${API}/caja/precorte/${id}/postcorte`, {
      method:'PUT', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ notes })
    });
    bootstrap.Modal.getInstance($('#modalPost')).hide();
    loadCortes();
  });

  function parseMoney(txt) {
    return Number(String(txt).replace(/[^\d.-]/g,'') || 0);
  }

  // Botones barra superior
  $('#btnRefreshCortes')?.addEventListener('click', loadCortes);
  $('#btnFiltrar')?.addEventListener('click', loadCortes);

  // Primera carga
  loadCortes();
})();
// === Cortes de Caja (vista) ===
(function () {
  const qs = (s, el = document) => el.querySelector(s);
  const qsa = (s, el = document) => Array.from(el.querySelectorAll(s));

  const tablaCajas = qs('#tabla-cajas');
  if (!tablaCajas) return; // no estamos en la vista de cortes

  // 1) Selección de caja → setear hidden inputs (store/terminal) del form "abrir precorte"
  const formAbrir = document.querySelector('form[action$="/caja/cortes/abrir"]');
  const hidStore = qs('#form-abrir-store');
  const hidTerm = qs('#form-abrir-terminal');

  function parseSel(val) {
    // val esperado: "Sucursal|Terminal"
    const [suc, termStr] = (val || '').split('|');
    // Mapea sucursal -> id (mock). En real vendrá de BD (stores)
    const map = { 'Principal': 1, 'NB': 2, 'Torre': 3, 'Terrena': 4 };
    return { store_id: map[suc] || null, terminal_id: parseInt(termStr || '0', 10) || null };
    // Si ya tendrás store_id y terminal_id reales en el value del radio, omite el map.
  }

  function currentSel() {
    const r = qs('input[name="selCaja"]:checked');
    return r ? parseSel(r.value) : { store_id: null, terminal_id: null };
  }

  function refreshHiddenTargets() {
    const cur = currentSel();
    if (hidStore) hidStore.value = cur.store_id || '';
    if (hidTerm) hidTerm.value = cur.terminal_id || '';
    // replicamos a otros forms
    const pStore = qs('#precorte-store');
    const pTerm = qs('#precorte-terminal');
    const cStore = qs('#cerrar-cero-store');
    const cTerm = qs('#cerrar-cero-terminal');
    [pStore, cStore].forEach(el => el && (el.value = cur.store_id || ''));
    [pTerm, cTerm].forEach(el => el && (el.value = cur.terminal_id || ''));
  }

  qsa('input[name="selCaja"]').forEach(r => {
    r.addEventListener('change', refreshHiddenTargets);
  });
  refreshHiddenTargets();

  // 2) Navegación de tabs
  function showTab(targetId) {
    const trigger = document.querySelector(`[data-bs-target="${targetId}"]`);
    if (!trigger) return;
    const tab = new bootstrap.Tab(trigger);
    tab.show();
  }

  const btnPrecorte = qs('#ir-a-precorte');
  if (btnPrecorte) btnPrecorte.addEventListener('click', () => showTab('#pane-precorte'));

  const btnCorte = qs('#ir-a-corte');
  if (btnCorte) btnCorte.addEventListener('click', () => showTab('#pane-corte'));

  // 3) Conteo rápido de denominaciones
  const inpDenos = qsa('.inp-dq');
  const totalEfe = qs('#total-efectivo');
  const declCash = qs('#decl-cash');

  function formatMoney(n) {
    const num = Number(n || 0);
    return num.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' });
  }

  function recalcDenos() {
    let total = 0;
    inpDenos.forEach(inp => {
      const den = Number(inp.dataset.deno);
      const qty = Math.max(0, Number(inp.value || 0));
      const imp = den * qty;
      total += imp;
      const cell = document.querySelector(`.deno-imp[data-deno="${den}"]`);
      if (cell) cell.textContent = formatMoney(imp);
    });
    if (totalEfe) totalEfe.textContent = formatMoney(total);
    if (declCash) declCash.value = total.toFixed(2);
    // reflejar en panel declarado en CORTE
    const resDeclCash = qs('#res-decl-cash');
    const resDeclTotal = qs('#res-decl-total');
    const dc = Number(qs('#decl-card')?.value || 0);
    const dt = Number(qs('#decl-transfer')?.value || 0);
    if (resDeclCash) resDeclCash.textContent = formatMoney(total);
    if (resDeclTotal) resDeclTotal.textContent = formatMoney(total + dc + dt);
  }

  inpDenos.forEach(inp => inp.addEventListener('input', recalcDenos));
  ['#decl-card', '#decl-transfer'].forEach(sel => {
    const el = qs(sel);
    if (el) el.addEventListener('input', recalcDenos);
  });
  recalcDenos();

  // 4) Mock: cargar totales del sistema (hasta conectar BD)
  const btnSistema = qs('#btn-cargar-sistema');
  if (btnSistema) btnSistema.addEventListener('click', () => {
    // Valores fake para demo; en vivo harás fetch a /caja/precorte/:id/sistema
    const sys = { cash: 240.00, card: 1200.00, transfer: 150.00 };
    qs('#res-sys-cash').textContent = formatMoney(sys.cash);
    qs('#res-sys-card').textContent = formatMoney(sys.card);
    qs('#res-sys-transfer').textContent = formatMoney(sys.transfer);
    qs('#res-sys-total').textContent = formatMoney(sys.cash + sys.card + sys.transfer);
    calcDiff();
  });

  // 5) Conciliar (Declarado - Sistema)
  function readMoney(id) {
    const el = qs(id);
    if (!el) return 0;
    const txt = el.textContent.replace(/[^\d.-]/g, '');
    return Number(txt || 0);
  }
  function calcDiff() {
    const dt = readMoney('#res-decl-total');
    const st = readMoney('#res-sys-total');
    const d  = dt - st;
    const el = qs('#res-diff');
    if (el) {
      el.textContent = formatMoney(d);
      el.classList.toggle('text-danger', d < 0);
      el.classList.toggle('text-success', d > 0);
    }
  }
  const btnConc = qs('#btn-conciliar');
  if (btnConc) btnConc.addEventListener('click', calcDiff);

})();
// === Utils ===
const qs = (s, el = document) => el.querySelector(s);
const qsa = (s, el = document) => Array.from(el.querySelectorAll(s));
const fmtMoney = n => Number(n||0).toLocaleString('es-MX',{style:'currency',currency:'MXN'});

// === Sidebar toggle ===
(function(){
  const sidebar = qs('.sidebar');
  const toggleDesktop = qs('#sidebarCollapse');
  const toggleMobile = qs('#sidebarToggleMobile');
  if(sidebar && toggleDesktop){
    toggleDesktop.addEventListener('click',()=>{
      document.body.classList.toggle('collapsed');
    });
  }
  if(sidebar && toggleMobile){
    toggleMobile.addEventListener('click',()=>{
      sidebar.classList.toggle('show');
    });
  }
})();

// === Footer reloj/fecha ===
(function(){
  const clock = qs('#footer-clock');
  const dateEl = qs('#footer-date');
  if(clock && dateEl){
    setInterval(()=>{
      const now = new Date();
      clock.textContent = now.toLocaleTimeString('es-MX',{hour:'2-digit',minute:'2-digit',second:'2-digit'});
      dateEl.textContent = now.toLocaleDateString('es-MX',{weekday:'long',year:'numeric',month:'long',day:'numeric'});
    },1000);
  }
})();

// === Cortes de Caja: conteo rápido y conciliación ===
(function(){
  const tablaDenos = qs('#tabla-denominaciones');
  if(!tablaDenos) return; // no estamos en cortes.php

  const inpDenos = qsa('.inp-dq');
  const totalEfe = qs('#total-efectivo');
  const declCash = qs('#decl-cash');

  function recalcDenos(){
    let total=0;
    inpDenos.forEach(inp=>{
      const den = Number(inp.dataset.deno);
      const qty = Math.max(0, Number(inp.value||0));
      const imp = den*qty;
      total+=imp;
      const cell=qs(`.deno-imp[data-deno="${den}"]`);
      if(cell) cell.textContent=fmtMoney(imp);
    });
    if(totalEfe) totalEfe.textContent=fmtMoney(total);
    if(declCash) declCash.value=total.toFixed(2);
  }
  inpDenos.forEach(inp=>inp.addEventListener('input',recalcDenos));
  recalcDenos();

  // Conciliación mock
  const btnSistema=qs('#btn-cargar-sistema');
  if(btnSistema) btnSistema.addEventListener('click',()=>{
    const sys={cash:240,card:1200,transfer:150};
    qs('#res-sys-cash').textContent=fmtMoney(sys.cash);
    qs('#res-sys-card').textContent=fmtMoney(sys.card);
    qs('#res-sys-transfer').textContent=fmtMoney(sys.transfer);
    qs('#res-sys-total').textContent=fmtMoney(sys.cash+sys.card+sys.transfer);
    calcDiff();
  });
  const btnConc=qs('#btn-conciliar');
  if(btnConc) btnConc.addEventListener('click',calcDiff);

  function readMoney(id){
    const el=qs(id);
    if(!el) return 0;
    const txt=el.textContent.replace(/[^\d.-]/g,'');
    return Number(txt||0);
  }
  function calcDiff(){
    const dt=readMoney('#res-decl-total');
    const st=readMoney('#res-sys-total');
    const d=dt-st;
    const el=qs('#res-diff');
    if(el){
      el.textContent=fmtMoney(d);
      el.classList.toggle('text-danger',d<0);
      el.classList.toggle('text-success',d>0);
    }
  }
})();

// === Totales por tab (Descuentos, Anulaciones, Retiros, Tarjetas, Otros) ===
(function(){
  const map=[
    {tab:'#tab-descuentos',tbody:'#tbl-descuentos',kpi:'#kpi-descuentos'},
    {tab:'#tab-anulaciones',tbody:'#tbl-anulaciones',kpi:'#kpi-anulaciones'},
    {tab:'#tab-retiros',tbody:'#tbl-retiros',kpi:'#kpi-retiros'},
    {tab:'#tab-tarjetas',tbody:'#tbl-tarjetas',kpi:'#kpi-tarjetas'},
    {tab:'#tab-otros',tbody:'#tbl-otros',kpi:'#kpi-otros'},
  ];
  function sumar(sel){
    const tb=qs(sel);
    if(!tb) return 0;
    return qsa('td[data-amt]',tb).reduce((a,td)=>a+Number(td.dataset.amt||0),0);
  }
  map.forEach(({tab,tbody,kpi})=>{
    const btn=qs(tab);
    if(!btn) return;
    btn.addEventListener('shown.bs.tab',()=>{
      const t=sumar(tbody);
      const el=qs(kpi);
      if(el) el.textContent=fmtMoney(t);
    });
  });
})();
