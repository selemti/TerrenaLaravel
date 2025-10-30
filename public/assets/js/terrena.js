// Terrena JS – Layout + Dashboard
// Rutas de logos
const LOGO_FULL = (window.__BASE__ || '') + '/assets/img/logo.svg';
const LOGO_MINI = (window.__BASE__ || '') + '/assets/img/logo2.svg';

document.addEventListener('DOMContentLoaded', () => {
  const sidebar             = document.getElementById('sidebar');
  const sidebarCollapseBtn  = document.getElementById('sidebarCollapse');        // desktop
  const sidebarToggleMobile = document.getElementById('sidebarToggleMobile');    // móvil
  const logoImg             = document.getElementById('logoImg');                // <img> del logo

  const syncLogo = (isCollapsed) => {
    if (!logoImg) return;
    logoImg.src = isCollapsed ? LOGO_MINI : LOGO_FULL;
    logoImg.alt = isCollapsed ? 'Terrena mini' : 'Terrena';
  };

  const toggleMobileSidebar = (force) => {
    if (!sidebar) return;
    const shouldShow = typeof force === 'boolean' ? force : !sidebar.classList.contains('show');
    sidebar.classList.toggle('show', shouldShow);
    document.body.classList.toggle('sidebar-open', shouldShow);
    if (shouldShow) {
      sidebar.classList.remove('collapsed');
      document.body.classList.remove('collapsed');
      syncLogo(false);
    }
  };

  const ensureResponsiveState = () => {
    if (!sidebar) return;
    if (window.innerWidth >= 992) {
      toggleMobileSidebar(false); // cierra overlay si se agranda la pantalla
    } else {
      sidebar.classList.remove('collapsed');
      document.body.classList.remove('collapsed');
      syncLogo(false);
    }
  };

  // ===== Toggle MÓVIL (off-canvas) =====
  sidebarToggleMobile?.addEventListener('click', (e) => {
    e.preventDefault();
    toggleMobileSidebar();
  });
  // Cierra tocando fuera (solo móvil)
  document.addEventListener('click', (ev) => {
    if (window.innerWidth >= 992) return;
    if (!sidebar?.classList.contains('show')) return;
    const clickedInside = sidebar.contains(ev.target) || sidebarToggleMobile?.contains(ev.target);
    if (!clickedInside) toggleMobileSidebar(false);
  });

  // ===== Collapse DESKTOP =====
  sidebarCollapseBtn?.addEventListener('click', (e) => {
    e.preventDefault();
    if (!sidebar) return;
    const willCollapse = !sidebar.classList.contains('collapsed');
    sidebar.classList.toggle('collapsed', willCollapse);
    document.body.classList.toggle('collapsed', willCollapse);
    toggleMobileSidebar(false); // evita que se quede abierto en móvil
    syncLogo(willCollapse);
  });

  const initialCollapsed = sidebar?.classList.contains('collapsed') || document.body.classList.contains('collapsed');
  if (initialCollapsed) {
    sidebar?.classList.add('collapsed');
    document.body.classList.add('collapsed');
    syncLogo(true);
  } else {
    syncLogo(false);
  }

  window.addEventListener('resize', ensureResponsiveState);
  ensureResponsiveState();

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

/**
 * Helper for making authenticated API GET requests
 * Includes Authorization header with Sanctum token if available
 */
window.Terrena.apiGet = async function(url) {
  const headers = {
    'Accept': 'application/json',
  };

  if (window.TerrenaApiToken) {
    headers['Authorization'] = 'Bearer ' + window.TerrenaApiToken;
  }

  const res = await fetch(url, {
    method: 'GET',
    headers,
  });

  if (res.status === 401) {
    console.warn('[Terrena] No autenticado en API (401):', url);
    // Could dispatch a global event here to show a login modal
  }
  if (res.status === 403) {
    console.warn('[Terrena] Sin permiso (403):', url);
    toast('No tienes permiso para acceder a este recurso.', 'warning');
  }

  return res;
};

window.Terrena.initDashboardCharts = async function (range) {
  const baseReports = (window.__BASE__ || '') + '/api/reports';
  const baseCaja = (window.__BASE__ || '') + '/api/caja';
  const todayIso = toISODate(new Date());
  const desde = toISODateOnly(range?.desde || todayIso);
  const hasta = toISODateOnly(range?.hasta || desde);
  const rangeParams = { desde, hasta };
  const trendDesde = toISODateOnly(subtractDays(hasta, 6));
  const trendParams = { desde: trendDesde, hasta };

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
    const res = await window.Terrena.apiGet(baseReports + path);
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

  const fetchCajaStatus = async (date) => {
    const query = buildQuery({ date: toISODateOnly(date) });
    const res = await window.Terrena.apiGet(baseCaja + `/cajas${query}`);
    if (!res.ok) {
      const err = new Error(`GET /caja/cajas → ${res.status}`);
      err.status = res.status;
      throw err;
    }
    const payload = await res.json().catch(() => null);
    if (!payload || payload.ok === false) {
      const err = new Error(payload?.error || 'Error al cargar estatus de cajas');
      err.payload = payload;
      throw err;
    }
    return payload;
  };

  try {
    const [
      kpisSucursal,
      kpisTerminal,
      ventasDia,
      ventasFamilia,
      ventasHora,
      ventasTop,
      ticketPromedio,
      itemsResumen,
      formasPago,
      alertasAnomalias,
      cajasStatus,
      ventasSucursales,
      ordenesRecientes
    ] = await Promise.all([
      fetchReport(`/kpis/sucursal${buildQuery(rangeParams)}`),
      fetchReport(`/kpis/terminal${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/dia${buildQuery(trendParams)}`),
      fetchReport(`/ventas/familia${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/hora${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/top${buildQuery({ ...rangeParams, limit: 5 })}`),
      fetchReport(`/ticket/promedio${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/items_resumen${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/formas${buildQuery(rangeParams)}`),
      fetchReport(`/anomalias${buildQuery({ limit: 6 })}`),
      fetchCajaStatus(hasta),
      fetchReport(`/ventas/sucursales${buildQuery(rangeParams)}`),
      fetchReport(`/ventas/ordenes_recientes${buildQuery({ ...rangeParams, limit: 10 })}`)
    ]);

    const kpiRows = Array.isArray(kpisSucursal.data) ? kpisSucursal.data : [];
    const terminalRows = Array.isArray(kpisTerminal.data) ? kpisTerminal.data : [];
    const cajaRows = Array.isArray(cajasStatus.terminals) ? cajasStatus.terminals : [];
    const branchLookup = buildBranchLookup(cajaRows);
    const totalsSource = kpiRows.length ? kpiRows : terminalRows;

    const totals = totalsSource.reduce((acc, row) => {
      const venta = Number(row.venta_total || row.total || 0);
      acc.venta += venta;
      acc.sesiones += Number(row.tickets || row.sesiones || 0);
      return acc;
    }, { venta: 0, sesiones: 0 });

    const totalVentas = totals.venta;

    setText('kpi-sales-today', money(totalVentas));
    setText('kpi-avg-ticket', money(Number(ticketPromedio.ticket_promedio || 0)));
    setText('kpi-items-sold', Number(itemsResumen.unidades ?? 0).toLocaleString('es-MX'));

    const topProducts = aggregateTopProducts(ventasTop.data || []);
    const bestProduct = topProducts[0];
    if (bestProduct) {
      setText('kpi-star-product', bestProduct.descripcion || bestProduct.plu || '—');
      setText('kpi-star-sales', `${money(Number(bestProduct.venta_total || 0))} · ${formatUnits(bestProduct.unidades)}`);
    } else {
      setText('kpi-star-product', '—');
      setText('kpi-star-sales', '—');
    }

    const alerts = alertasAnomalias.data || [];
    setText('kpi-alerts', alerts.length.toLocaleString('es-MX'));

    renderHeaderAlerts(alerts);
    renderKpiRegisters(kpiRows, terminalRows, cajaRows, { fechaObjetivo: hasta, branchLookup, fallbackLatest: false });
    renderBranchSummary(ventasSucursales.data || []);

    renderSalesTrendChart(ventasDia.data || [], { desde: trendDesde, hasta });
    renderSalesByHourChart(ventasHora.data || [], { startHour: 7, endHour: 19 });
    renderBranchPaymentsChart(ventasFamilia.data || [], { branchLookup });
    renderTopProductsChart(topProducts);
    renderPaymentChart(formasPago.data || []);
    renderOrders(ordenesRecientes.data || []);
  } catch (error) {
    console.error('Error cargando dashboard', error);
    toast('No fue posible obtener los datos del dashboard.', 'danger');
    setText('kpi-sales-today', '—');
    setText('kpi-avg-ticket', '—');
    setText('kpi-items-sold', '—');
    setText('kpi-star-product', '—');
    setText('kpi-star-sales', '—');
    setText('kpi-alerts', '0');
    renderHeaderAlerts([]);
    renderKpiRegisters([], [], []);
    renderBranchSummary([]);
    renderOrders([]);
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
    current.venta_total += Number(row.venta_total || row.total || 0);
    current.unidades += Number(row.unidades ?? row.qty ?? row.cantidad ?? 0);
    if (!current.descripcion && row.descripcion) {
      current.descripcion = row.descripcion;
    }
    map.set(key, current);
  });
  return Array.from(map.values())
    .sort((a, b) => Number(b.venta_total || 0) - Number(a.venta_total || 0))
    .slice(0, 5);
}

function renderSalesTrendChart(rows, opts = {}) {
  if (typeof Chart === 'undefined') return;
  const canvas = document.getElementById('salesTrendChart');
  if (!canvas) return;

  const list = Array.isArray(rows) ? rows.filter(r => r && r.fecha) : [];
  const totalsByDate = new Map();
  const ticketsByDate = new Map();
  list.forEach((row) => {
    const iso = toISODateOnly(row.fecha);
    totalsByDate.set(iso, Number(row.venta_total || row.total || 0));
    ticketsByDate.set(iso, Number(row.tickets || 0));
  });

  const startDate = parseISODate(opts.desde) || parseISODate(list[0]?.fecha);
  const endDate = parseISODate(opts.hasta) || startDate;
  const labels = [];
  const data = [];
  const tickets = [];

  if (startDate && endDate) {
    for (let cursor = new Date(startDate); cursor <= endDate; cursor.setDate(cursor.getDate() + 1)) {
      const iso = toISODate(cursor);
      labels.push(formatDateLabel(iso));
      data.push(Number(totalsByDate.get(iso) || 0));
      tickets.push(Number(ticketsByDate.get(iso) || 0));
    }
  } else {
    labels.push('—');
    data.push(0);
    tickets.push(0);
  }

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
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label(context) {
              const venta = money(context.parsed.y ?? context.parsed.x ?? 0);
              const idx = context.dataIndex;
              const tk = tickets[idx] ?? 0;
              return `Venta: ${venta} · Tickets: ${tk.toLocaleString('es-MX')}`;
            }
          }
        }
      },
      scales: {
        x: { grid: { display: false } },
        y: { beginAtZero: true }
      }
    }
  });
}

function renderSalesByHourChart(rows, opts = {}) {
  if (typeof Chart === 'undefined') return;
  const canvas = document.getElementById('salesByHourChart');
  if (!canvas) return;

  const aggregated = new Map();
  (Array.isArray(rows) ? rows : []).forEach((row) => {
    const date = parseISODateTime(row.hora);
    if (!date) return;
    const hour = date.getHours();
    aggregated.set(hour, (aggregated.get(hour) || 0) + Number(row.venta_total || 0));
  });

  const startHour = Number.isFinite(opts.startHour) ? Number(opts.startHour) : 0;
  const endHour = Number.isFinite(opts.endHour) ? Number(opts.endHour) : 23;

  const labels = [];
  const data = [];
  for (let hour = startHour; hour <= endHour; hour += 1) {
    labels.push(formatHourLabelFromHour(hour));
    data.push(Number(aggregated.get(hour) || 0));
  }

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

function renderBranchPaymentsChart(rows, opts = {}) {
  if (typeof Chart === 'undefined') return;
  const canvas = document.getElementById('branchPaymentsChart');
  if (!canvas) return;

  const branchLookup = opts.branchLookup instanceof Map ? opts.branchLookup : new Map();
  const branchesSet = new Set();
  const familiesSet = new Set();
  const lookup = new Map();

  (Array.isArray(rows) ? rows : []).forEach((row) => {
    if (!row) return;
    const branch = resolveBranchName(row, branchLookup);
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
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label(context) {
              const row = list[context.dataIndex] || {};
              const venta = money(context.parsed.x ?? context.parsed.y ?? 0);
              const unidades = Number(row.unidades || 0).toLocaleString('es-MX');
              return `Venta: ${venta} · Unidades: ${unidades}`;
            }
          }
        }
      },
      scales: {
        x: { beginAtZero: true },
        y: { grid: { display: false } }
      }
    }
  });
}

const PAYMENT_LABEL_MAP = {
  CASH: 'Efectivo',
  CASH_MXN: 'Efectivo',
  CASH_MXP: 'Efectivo',
  CASH_MXN_POS: 'Efectivo',
  CASH_USD: 'Efectivo USD',
  DEBIT: 'Tarjeta de débito',
  DEBIT_CARD: 'Tarjeta de débito',
  DEBITCARD: 'Tarjeta de débito',
  CREDIT: 'Tarjeta de crédito',
  CREDIT_CARD: 'Tarjeta de crédito',
  CREDITCARD: 'Tarjeta de crédito',
  CREDIT_SALE: 'Crédito',
  CREDIT_CLIENT: 'Crédito',
  TRANSFER: 'Transferencia',
  TRANSFERENCIA: 'Transferencia',
  BANK_TRANSFER: 'Transferencia',
  SPEI: 'Transferencia',
  CHECK: 'Cheque',
  CHEQUE: 'Cheque',
  VOUCHER: 'Vales',
  VALE: 'Vales',
  COUPON: 'Cupón',
  GIFT_CARD: 'Tarjeta de regalo',
  COURTESY: 'Cortesía',
  MERCADOPAGO: 'Mercado Pago',
  MPOS: 'TPV',
  OTHER: 'Otros',
  UNKNOWN: 'Otros',
  PENDING: 'Pendiente'
};

function formatPaymentLabel(code) {
  if (!code) return 'Otros';
  const raw = code.toString().trim();
  const normalized = raw.toUpperCase().replace(/[^A-Z0-9]/g, '_');
  if (PAYMENT_LABEL_MAP[normalized]) {
    return PAYMENT_LABEL_MAP[normalized];
  }
  if (normalized.startsWith('CASH')) return 'Efectivo';
  if (normalized.includes('DEBIT')) return 'Tarjeta de débito';
  if (normalized.includes('CREDIT')) return 'Tarjeta de crédito';
  if (normalized.includes('TRANSFER')) return 'Transferencia';
  if (normalized.includes('VOUCHER') || normalized.includes('VALE')) return 'Vales';
  if (normalized.includes('CHEQ')) return 'Cheque';
  const beautified = raw
    .replace(/[_\-]+/g, ' ')
    .toLowerCase()
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
  return beautified || 'Otros';
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
  const displayLabels = chartLabels.map(formatPaymentLabel);

  canvas._chart = new Chart(canvas.getContext('2d'), {
    type: 'doughnut',
    data: {
      labels: displayLabels,
      datasets: [{
        data: chartData,
        backgroundColor: chartLabels.map((_, idx) => palette[idx % palette.length])
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: 'bottom' },
        tooltip: {
          callbacks: {
            label(context) {
              const value = Number(context.raw || 0);
              const texto = context.label || '';
              return `${texto}: ${money(value)}`;
            }
          }
        }
      }
    }
  });
}

function formatUnits(units) {
  const value = Number(units || 0);
  const formatted = value.toLocaleString('es-MX');
  return `${formatted} ${value === 1 ? 'ud' : 'uds'}`;
}

function subtractDays(value, days) {
  const base = parseISODate(value);
  if (!base) return new Date();
  const offset = Number(days) || 0;
  base.setDate(base.getDate() - Math.max(0, offset));
  return base;
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

function formatHourLabelFromHour(hour) {
  const h = String(hour).padStart(2, '0');
  return `${h}:00`;
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

function parseISODate(value) {
  if (!value) return null;
  if (value instanceof Date) {
    return new Date(value.getFullYear(), value.getMonth(), value.getDate());
  }
  const str = String(value);
  const parts = str.split('-');
  if (parts.length === 3) {
    const year = Number(parts[0]);
    const month = Number(parts[1]) - 1;
    const day = Number(parts[2]);
    if (Number.isFinite(year) && Number.isFinite(month) && Number.isFinite(day)) {
      return new Date(year, month, day);
    }
  }
  const d = new Date(str);
  if (Number.isNaN(d.getTime())) return null;
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function parseISODateTime(value) {
  if (!value) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}

function formatDateShort(value) {
  const date = parseISODate(value);
  if (!date) return '';
  return date.toLocaleDateString('es-MX', { day: '2-digit', month: 'short' });
}

function resolveRowsForDate(rows, targetIso, opts = {}) {
  const data = Array.isArray(rows) ? rows.filter(Boolean) : [];
  if (!targetIso) return data;
  const prop = opts.prop || 'fecha';
  const fallbackLatest = Boolean(opts.fallbackLatest);
  const matches = data.filter(r => toISODateOnly(r[prop] ?? r.fecha ?? r.hora) === targetIso);
  if (matches.length || !fallbackLatest) return matches;
  const latestIso = data
    .map(r => toISODateOnly(r[prop] ?? r.fecha ?? r.hora))
    .filter(Boolean)
    .sort()
    .pop();
  return latestIso ? data.filter(r => toISODateOnly(r[prop] ?? r.fecha ?? r.hora) === latestIso) : matches;
}

function buildBranchLookup(rows = []) {
  const map = new Map();
  rows.forEach((row) => {
    if (!row) return;
    const location = (row.location || row.branch || row.sucursal || row.name || '').trim();
    const primary = location || (row.name || '').trim();
    if (primary) {
      map.set(primary, primary);
    }
    if (row.name) {
      map.set(row.name, primary || row.name);
    }
    if (row.sucursal) {
      map.set(row.sucursal, primary || row.sucursal);
    }
    if (row.sucursal_id) {
      map.set(String(row.sucursal_id), primary || String(row.sucursal_id));
    }
    if (row.branch_id) {
      map.set(String(row.branch_id), primary || String(row.branch_id));
    }
    if (row.id != null) {
      map.set(String(row.id), primary || `Terminal ${row.id}`);
    }
  });
  return map;
}

function resolveBranchName(row, lookup) {
  if (!row) return 'Sin sucursal';
  const candidates = [
    row.sucursal_nombre,
    row.location,
    row.sucursal,
    row.sucursal_id,
    row.branch,
    row.branch_id
  ].map(v => (v == null ? '' : String(v).trim())).filter(Boolean);
  for (const candidate of candidates) {
    if (lookup.has(candidate)) {
      return lookup.get(candidate);
    }
  }
  if (row.terminal_id != null) {
    const key = String(row.terminal_id);
    if (lookup.has(key)) return lookup.get(key);
  }
  return candidates[0] || 'Sin sucursal';
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
  if (!s.value) s.value = toISODate(today);
  if (!e.value) e.value = toISODate(today);

  const triggerRefresh = (ensureOrder = true) => {
    let desde = s.value || undefined;
    let hasta = e.value || undefined;
    if (ensureOrder && desde && hasta && desde > hasta) {
      [desde, hasta] = [hasta, desde];
      s.value = desde;
      e.value = hasta;
    }
    if (window.Terrena && typeof Terrena.initDashboardCharts === 'function') {
      Terrena.initDashboardCharts({ desde, hasta });
    }
  };

  s.addEventListener('change', () => triggerRefresh(true));
  e.addEventListener('change', () => triggerRefresh(true));
  btn?.addEventListener('click', (ev) => {
    ev.preventDefault();
    triggerRefresh(true);
  });

  // NO llamar triggerRefresh() aquí - dejar que dashboard.blade.php lo dispare después de cargar el token
  // triggerRefresh(false);
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
function renderKpiRegisters(sucursalRows = [], terminalRows = [], cajaRows = [], opts = {}){
  const tbody = document.getElementById('kpi-registers');
  if (!tbody) return;

  const toArray = (rows) => Array.isArray(rows) ? rows.filter(Boolean) : [];
  const sucursales = toArray(sucursalRows);
  const terminales = toArray(terminalRows);
  const cajas = toArray(cajaRows);

  const targetIso = opts?.fechaObjetivo ? toISODateOnly(opts.fechaObjetivo) : null;
  const branchLookup = opts.branchLookup instanceof Map ? opts.branchLookup : new Map();
  const filteredSucursales = resolveRowsForDate(sucursales, targetIso, { fallbackLatest: opts.fallbackLatest });
  const filteredTerminales = resolveRowsForDate(terminales, targetIso, { fallbackLatest: opts.fallbackLatest });

  const ventasPorSucursal = new Map();
  filteredSucursales.forEach((row) => {
    const key = resolveBranchName(row, branchLookup);
    const current = ventasPorSucursal.get(key) || { vendido: 0, sesiones: 0 };
    current.vendido += Number(row.venta_total || row.total || 0);
    current.sesiones += Number(row.tickets || row.sesiones || 0);
    ventasPorSucursal.set(key, current);
  });

  const ventasPorTerminal = new Map();
  filteredTerminales.forEach((row) => {
    const key = row.terminal_id || row.terminal || null;
    if (key == null) return;
    const current = ventasPorTerminal.get(key) || { vendido: 0, sesiones: 0 };
    current.vendido += Number(row.venta_total || row.total || 0);
    current.sesiones += Number(row.tickets || row.sesiones || 0);
    ventasPorTerminal.set(key, current);
  });

  const rowsToRender = [];
  const usedTerminals = new Set();
  const fallbackSucursal = ventasPorSucursal.size ? ventasPorSucursal.keys().next().value : 'Sin sucursal';

  cajas.forEach((row) => {
    const terminalKey = row.id ?? row.terminal_id ?? row.terminal ?? null;
    const terminalInfo = terminalKey != null ? ventasPorTerminal.get(terminalKey) : null;
    const sucursalNombre = resolveBranchName({ ...row, sucursal: row.location || row.branch }, branchLookup) || fallbackSucursal || 'Sin sucursal';
    const sucursalInfo = ventasPorSucursal.get(sucursalNombre) || ventasPorSucursal.get('Sin sucursal') || { vendido: 0, sesiones: 0 };
    const vendido = terminalInfo?.vendido ?? sucursalInfo.vendido ?? 0;
    const sesiones = terminalInfo?.sesiones ?? sucursalInfo.sesiones ?? 0;
    rowsToRender.push({
      key: terminalKey ?? sucursalNombre,
      sucursal: sucursalNombre || 'Sin sucursal',
      terminal: row.name || (terminalKey != null ? `Terminal ${terminalKey}` : '—'),
      vendido,
      sesiones,
      estadoRow: row
    });
    if (terminalKey != null) usedTerminals.add(terminalKey);
  });

  ventasPorTerminal.forEach((info, terminalKey) => {
    if (usedTerminals.has(terminalKey)) return;
    rowsToRender.push({
      key: terminalKey,
      sucursal: '—',
      terminal: `Terminal ${terminalKey}`,
      vendido: info.vendido,
      sesiones: info.sesiones,
      estadoRow: null
    });
  });

  if (!rowsToRender.length && ventasPorSucursal.size) {
    ventasPorSucursal.forEach((info, sucursal) => {
      rowsToRender.push({
        key: sucursal,
        sucursal,
        terminal: '—',
        vendido: info.vendido,
        sesiones: info.sesiones,
        estadoRow: null
      });
    });
  }

  if (!rowsToRender.length) {
    tbody.innerHTML = '<tr><td colspan="3" class="text-center text-muted small">Sin datos en el rango seleccionado</td></tr>';
    return;
  }

  rowsToRender.sort((a, b) => b.vendido - a.vendido);

  tbody.innerHTML = rowsToRender.map(item => `
      <tr>
        <td>
          ${escapeHtml(item.sucursal || 'Sin sucursal')}
          <div class="text-muted small">${escapeHtml(item.terminal || '—')}</div>
        </td>
        <td>${buildCajaStatusBadge(item.estadoRow, item.sesiones)}</td>
        <td class="text-end">${money(Number(item.vendido || 0))}</td>
      </tr>`).join('');
}

function buildCajaStatusBadge(estadoRow, sesiones = 0) {
  const defaultClosed = '<span class="badge text-bg-secondary">Cerrada</span>';
  if (!estadoRow && !sesiones) return defaultClosed;

  const normalized = (estadoRow?.estado || '').toString().trim().toUpperCase();
  const activa = Boolean(estadoRow?.activa);
  const badge = (text, cls) => `<span class="badge ${cls}">${escapeHtml(text)}</span>`;

  if (normalized === 'ABIERTA' || activa || sesiones > 0) {
    return badge('Abierta', 'text-bg-success');
  }
  if (normalized === 'REGULARIZAR') {
    return badge('Regularizar', 'text-bg-danger');
  }
  if (normalized === 'VALIDACION' || normalized === 'EN_REVISION') {
    return badge('En revisión', 'text-bg-warning');
  }
  if (normalized === 'PRECORTE_PENDIENTE') {
    return badge('Precorte pendiente', 'text-bg-warning');
  }
  if (normalized === 'CONCILIADA') {
    return badge('Conciliada', 'text-bg-primary');
  }
  if (normalized === 'DISPONIBLE') {
    return badge('Disponible', 'text-bg-info');
  }
  return defaultClosed;
}

function renderBranchSummary(rows = []){
  const tbody = document.getElementById('branch-summary');
  if (!tbody) return;

  const data = Array.isArray(rows) ? rows.filter(Boolean) : [];
  if (!data.length) {
    tbody.innerHTML = '<tr><td colspan="3" class="text-center text-muted small">Sin información</td></tr>';
    return;
  }

  const summary = new Map();
  data.forEach((row) => {
    const sucursal = (row.sucursal_id || row.sucursal || 'Sin sucursal').trim() || 'Sin sucursal';
    const current = summary.get(sucursal) || { sucursal, tickets: 0, venta: 0 };
    current.tickets += Number(row.tickets || 0);
    current.venta += Number(row.venta_total || row.total || 0);
    summary.set(sucursal, current);
  });

  const entries = Array.from(summary.values()).sort((a, b) => b.venta - a.venta);
  tbody.innerHTML = entries.map(item => `
    <tr>
      <td>${escapeHtml(item.sucursal)}</td>
      <td class="text-end">${Number(item.tickets || 0).toLocaleString('es-MX')}</td>
      <td class="text-end">${money(Number(item.venta || 0))}</td>
    </tr>
  `).join('');
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
    <tr>
      <td>${escapeHtml(r.ticket)}</td>
      <td>
        ${escapeHtml(r.sucursal || 'Sin sucursal')}
        <div class="text-muted small">${escapeHtml(r.terminal || '—')}</div>
      </td>
      <td>
        ${escapeHtml(r.hora || '—')}
        <div class="text-muted small">${escapeHtml(formatDateShort(r.fecha) || '')}</div>
      </td>
      <td class="text-end">${money(Number(r.total || 0))}</td>
    </tr>
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
  const API = base + '/api';
  // TODO: migrar cada acción a los endpoints definitivos /api/caja/precortes cuando estén listos en backend

  // Estado local para modales
  let currentPrecorte = null;

  // Listado principal
  async function loadCortes() {
    const bdate = $('#f_bdate')?.value || '';
    const url = new URL(API + '/caja/cajas', window.location.origin);
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

    // TODO: reemplazar por POST /api/caja/precortes cuando se exponga endpoint consolidado
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
    // TODO: migrar a /api/caja/precortes/{id}/conteo (pendiente backend)
    await fetch(`${API}/caja/precorte/${precorte_id}/conteo`, {
      method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify(det)
    });

    // 3) declarados
    const cash = recalcDenoms();
    const card = Number($('#p_card').value||0);
    const transfer = Number($('#p_transfer').value||0);
    // TODO: migrar a /api/caja/precortes/{id}/declarado cuando esté disponible
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
    // TODO: migrar a /api/caja/precortes/${id}/sistema cuando backend esté listo
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
    // TODO: confirmar ruta final para cerrar tickets cero (legacy Slim)
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
    // TODO: migrar a /api/caja/precortes/${id}/conciliar cuando se exponga endpoint nuevo
    const r = await fetch(`${API}/caja/precorte/${id}/conciliar`, {method:'PUT', headers:{'Content-Type':'application/json'}, body: JSON.stringify(payload)});
    await r.json();
    // En mock ya refleja diferencia; solo refresca listado
    loadCortes();
  });

  $('#btnCerrarCorte')?.addEventListener('click', async () => {
    const id = $('#c_precorte_id').value;
    // TODO: migrar a /api/caja/precortes/${id}/cerrar
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
    // TODO: migrar a /api/caja/postcortes/${id} cuando se publique el endpoint definitivo
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
