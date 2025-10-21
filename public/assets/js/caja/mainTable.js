// assets/js/caja/mainTable.js
import { api, MXN } from './config.js';
import { $, esc, GET_FALLBACK, currentDate } from './helpers.js';
import { els, state } from './state.js';
import { abrirWizard } from './wizard.js';

console.debug('[caja/mainTable] init', { type: typeof api?.cajas });

function buildUrl(endpoint, qs) {
  if (!endpoint) return null;
  if (typeof endpoint === 'function') return endpoint(qs);
  if (typeof endpoint === 'string') {
    if (!qs) return endpoint;
    const hasQuery = endpoint.includes('?');
    const trailing = /[?&]$/.test(endpoint);
    const sep = hasQuery ? (trailing ? '' : '&') : '?';
    return `${endpoint}${sep}${qs}`;
  }
  return null;
}

// --- KPIs ---
export function renderKPIs() {
  if (!state?.data) return;
  const abiertas = state.data.filter(r => r.estado === 'ABIERTA').length;
  const pendientes = state.data.filter(r => ['PRECORTE_PENDIENTE', 'VALIDACION'].includes(r.estado)).length;
  const precortes = state.data.filter(r => r.precorte_listo).length;
  const conciliadas = state.data.filter(r => r.estado === 'CONCILIADA').length;

  if (els.kpiAbiertas) els.kpiAbiertas.textContent = abiertas;
  if (els.kpiPendientes) els.kpiPendientes.textContent = pendientes;
  if (els.kpiPrecortes) els.kpiPrecortes.textContent = precortes;
  if (els.kpiConcil) els.kpiConcil.textContent = conciliadas;

  // Actualizar badges en tabs
  updateTabBadges(abiertas, pendientes, conciliadas);
}

// --- Helpers para tabs y filtros ---
function updateTabBadges(abiertas, pendientes, conciliadas) {
  const tabActivas = document.querySelector('#tab-activas .badge');
  const tabPendientes = document.querySelector('#tab-pendientes .badge');
  const tabConciliadas = document.querySelector('#tab-conciliadas .badge');

  if (tabActivas) tabActivas.textContent = abiertas;
  if (tabPendientes) tabPendientes.textContent = pendientes;
  if (tabConciliadas) tabConciliadas.textContent = conciliadas;
}

function getEstadoBadge(estado) {
  const badges = {
    'REGULARIZAR': '<span class="badge bg-danger">⚠️ Regularizar</span>',
    'ABIERTA': '<span class="badge bg-success">🟢 Abierta</span>',
    'PRECORTE_PENDIENTE': '<span class="badge bg-warning text-dark">📋 Precorte Pendiente</span>',
    'VALIDACION': '<span class="badge bg-info">🔍 En Validación</span>',
    'EN_REVISION': '<span class="badge bg-primary">👀 En Revisión</span>',
    'CONCILIADA': '<span class="badge bg-secondary">✅ Conciliada</span>',
    'DISPONIBLE': '<span class="badge bg-light text-dark">Disponible</span>',
  };
  return badges[estado] || badges['DISPONIBLE'];
}

function getFilteredData() {
  if (!state.data) return [];

  const activeTab = document.querySelector('#cajaTabs .nav-link.active');
  if (!activeTab) return state.data;

  const filtro = activeTab.dataset.filtro;
  if (!filtro || filtro === 'todas') return state.data;

  switch (filtro) {
    case 'activas':
      return state.data.filter(r => r.estado === 'ABIERTA');
    case 'pendientes':
      return state.data.filter(r => ['PRECORTE_PENDIENTE', 'VALIDACION'].includes(r.estado));
    case 'conciliadas':
      return state.data.filter(r => r.estado === 'CONCILIADA');
    default:
      return state.data;
  }
}

// --- LÃ³gica del Wizard / acciones ---
export function puedeWizard(r) {
  // Wizard disponible para estos estados
  const estadosPermitidos = ['ABIERTA', 'PRECORTE_PENDIENTE', 'VALIDACION', 'REGULARIZAR'];
  return r.sesion_id && estadosPermitidos.includes(r.estado);
}

export function renderAcciones(r) {
  // Get store_id from session data instead of hardcoding
  const store = r.store_id || 1;
  const bdate = currentDate();
  const opening = Number(r.opening_float || 0);
  const sesionId = r.sesion_id;
  const userId = r.assigned_user;

  if (!sesionId) return '';
  if (!puedeWizard(r)) return '';

  return `
    <button type="button" class="btn btn-sm btn-primary"
            data-caja-action="wizard"
            data-store="${esc(store)}"
            data-terminal="${esc(r.id)}"
            data-user="${esc(userId)}"
            data-bdate="${esc(bdate)}"
            data-opening="${esc(opening)}"
            data-sesion="${esc(sesionId)}"
            title="Abrir Wizard">
      <i class="fa-solid fa-wand-magic-sparkles"></i>
    </button>`;
}

// --- Tabla ---
export function renderTabla() {
  if (!els.tbody) {
    console.error('El elemento tbody de la tabla no se encontró.');
    return;
  }
  els.tbody.innerHTML = '';
  if (!state.data || state.data.length === 0) {
    const tr = document.createElement('tr');
    tr.innerHTML = `<td colspan="7" class="text-center text-secondary py-4">No hay sesiones para esta fecha.</td>`;
    els.tbody.appendChild(tr);
    return;
  }

  // Filtrar por tab activo
  const filteredData = getFilteredData();

  filteredData.forEach(r => {
    const estado = r.estado || 'DISPONIBLE';
    const badgeEstado = getEstadoBadge(estado);

    // Formatear hora de apertura
    let horaApertura = '–';
    if (r.apertura_ts) {
      try {
        const d = new Date(r.apertura_ts);
        horaApertura = d.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', hour12: true });
      } catch (e) {
        horaApertura = r.apertura_ts;
      }
    }

    const tr = document.createElement('tr');
    tr.dataset.estado = estado;
    tr.innerHTML = `
      <td>${esc(r.location ?? '–')}</td>
      <td>${esc(r.name ?? r.id ?? '–')}</td>
      <td>${esc(r.assigned_name ?? '–')}</td>
      <td>${horaApertura}</td>
      <td>${badgeEstado}</td>
      <td class="text-end">${MXN.format(Number(r.opening_float || 0))}</td>
      <td class="text-end"><div class="d-flex flex-wrap gap-2">${renderAcciones(r)}</div></td>`;
    els.tbody.appendChild(tr);
  });

  els.tbody.querySelectorAll('[data-caja-action="wizard"]').forEach(btn => {
    if (btn.dataset.bound === '1') return;
    btn.dataset.bound = '1';
    btn.addEventListener('click', abrirWizard);
  });
}

// --- data ---
export async function cargarTabla() {
  const qs = new URLSearchParams({ date: currentDate() }).toString();
  const primaryUrl = buildUrl(api?.cajas, qs);
  const secondaryUrl = buildUrl(api?.legacy?.cajas, qs);
  if (!primaryUrl) {
    throw new Error('Endpoint de cajas no configurado');
  }
  const j = await GET_FALLBACK([primaryUrl, secondaryUrl].filter(Boolean));
  state.date = j?.date || currentDate();
  state.data = Array.isArray(j?.terminals) ? j.terminals : [];
  if (els.badgeFecha) els.badgeFecha.textContent = state.date;
  renderKPIs();
  renderTabla();
}

// --- boot ---
export async function bootCaja() {
  if (els.tbody) {
    els.tbody.innerHTML = `<tr><td colspan="7" class="text-center text-secondary py-4">Cargando...</td></tr>`;
  }
  await cargarTabla();
  initTabFilters();
  initRefreshButton();
}

// --- Inicializar filtros de tabs ---
function initTabFilters() {
  if (!els.cajaTabs) return;

  const tabButtons = els.cajaTabs.querySelectorAll('.nav-link');
  tabButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();

      // Actualizar clase active
      tabButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      // Re-renderizar tabla con filtro
      renderTabla();
    });
  });
}

// --- Inicializar botón refrescar ---
function initRefreshButton() {
  if (!els.btnRefrescar) return;

  els.btnRefrescar.addEventListener('click', async () => {
    // Deshabilitar botón mientras carga
    els.btnRefrescar.disabled = true;
    const originalHTML = els.btnRefrescar.innerHTML;
    els.btnRefrescar.innerHTML = '<i class="fa-solid fa-rotate fa-spin"></i> Refrescando...';

    try {
      await cargarTabla();
    } catch (error) {
      console.error('Error al refrescar:', error);
      alert('Error al refrescar los datos. Por favor intenta de nuevo.');
    } finally {
      // Restaurar botón
      els.btnRefrescar.disabled = false;
      els.btnRefrescar.innerHTML = originalHTML;
    }
  });
}
