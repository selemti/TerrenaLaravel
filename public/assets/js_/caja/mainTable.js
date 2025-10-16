// assets/js/caja/mainTable.js
import { api, MXN } from './config.js';
import { $, esc, GET_FALLBACK, currentDate } from './helpers.js';
import { els, state } from './state.js';
import { abrirWizard } from './wizard.js';

// --- KPIs ---
export function renderKPIs() {
  if (!state?.data) return;
  const abiertas = state.data.filter(r => r.activa).length;
  const precortes = state.data.filter(r => r.precorte_listo).length;
  const conciliadas = state.data.filter(r => r.precorte_listo && !r.postcorte_pendiente).length;

  if (els.kpiAbiertas) els.kpiAbiertas.textContent = abiertas;
  if (els.kpiPrecortes) els.kpiPrecortes.textContent = precortes;
  if (els.kpiConcil) els.kpiConcil.textContent = conciliadas;
  // Cálculo de la diferencia promedio
  // Aún no implementado, por lo que se mantiene en 0.
  if (els.kpiDifProm) els.kpiDifProm.textContent = MXN.format(0);
}

// --- Lógica del Wizard / acciones ---
export function puedeWizard(r) {
  const asignadaActiva = !!(r.asignada && r.activa && r.assigned_user);
  const validacionSinPC = !!(r.precorte_listo && r.sin_postcorte);
  const saltoSinPrecorte = !!r.skipped_precorte;
  return true;
  //return asignadaActiva || validacionSinPC || saltoSinPrecorte;
}

export function renderAcciones(r) {
  const store = 1; 
  const bdate = currentDate();
  const opening = Number(r.opening_float || 0);
  const sesionId = r.sesion_id;
  const userId = r.assigned_user;

  if (!sesionId) return '';
  if (!puedeWizard(r)) return '';

  return `
    <button class="btn btn-sm btn-primary"
            data-caja-action="wizard"
            data-store="${esc(store)}"
            data-terminal="${esc(r.id)}"
            data-user="${esc(userId)}"
            data-bdate="${esc(bdate)}"
            data-opening="${opening}"
            data-sesion="${esc(sesionId)}"
            title="Abrir Wizard">
        <i class="fa-solid fa-wand-magic-sparkles"></i>
    </button>
  `;
}

export function renderTabla() {
  if (!els.tbody) {
    console.error('El elemento tbody de la tabla no se encontró.');
    return;
  }
  els.tbody.innerHTML = '';
  if (!state.data || state.data.length === 0) {
    const tr = document.createElement('tr');
    tr.innerHTML = `<td colspan="9" class="text-center text-secondary py-4">Sin datos para la fecha seleccionada.</td>`;
    els.tbody.appendChild(tr);
    return;
  }
  state.data.forEach(r => {
    let badgeEstado;
    if (r.skipped_precorte) {
      badgeEstado = '<span class="badge bg-danger">Regularizar</span>';
    } else if (r.asignada && r.activa) {
      badgeEstado = '<span class="badge bg-success">Asignada</span>';
    } else if (r.asignada && !r.activa) {
      badgeEstado = '<span class="badge bg-info">En Corte</span>';
    } else if (!r.asignada && r.precorte_listo && r.sin_postcorte) {
      badgeEstado = '<span class="badge bg-warning text-dark">Validación</span>';
    } else {
      badgeEstado = '<span class="badge bg-secondary">Cerrada</span>';
    }

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${esc(r.location ?? '—')}</td>
      <td>${esc(r.name ?? r.id ?? '—')}</td>
      <td>${esc(r.assigned_name ?? '—')}</td>
      <td>${esc(state.date ?? '—')}</td>
      <td>${badgeEstado}</td>
      <td class="text-end">${MXN.format(Number(r.opening_float || 0))}</td>
      <td class="text-end">${MXN.format(0)}</td>
      <td class="text-end">${MXN.format(0)}</td>
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
  const j = await GET_FALLBACK([
    api.cajas(qs),
    api.legacy?.cajas ? api.legacy.cajas(qs) : null
  ].filter(Boolean));
  state.date = j?.date || currentDate();
  state.data = Array.isArray(j?.terminals) ? j.terminals : [];
  if (els.badgeFecha) els.badgeFecha.textContent = state.date;
  renderKPIs();
  renderTabla();
}

// --- boot ---
export async function bootCaja() {
  if (els.tbody) {
    els.tbody.innerHTML = `<tr><td colspan="9" class="text-center text-secondary py-4">Cargando...</td></tr>`;
  }
  await cargarTabla();
}