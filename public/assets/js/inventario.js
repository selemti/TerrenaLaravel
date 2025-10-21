// Inventory Module
// Connects inventario.blade.php with inventory API endpoints

const API_BASE = '/TerrenaLaravel/api';

// Utility functions
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => r.querySelectorAll(s);

const esc = (x) => String(x ?? '').replace(/[&<>\"']/g, m => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
}[m]));

const fmt = {
    currency: (val) => new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val ?? 0),
    number: (val, decimals = 2) => new Intl.NumberFormat('es-MX', { minimumFractionDigits: decimals, maximumFractionDigits: decimals }).format(val ?? 0),
};

// API Helper
async function apiGet(endpoint) {
    try {
        const res = await fetch(`${API_BASE}${endpoint}`, {
            headers: { 'Accept': 'application/json' },
            credentials: 'same-origin'
        });

        if (!res.ok) {
            const error = await res.json().catch(() => ({ error: 'unknown' }));
            throw new Error(error.message || `HTTP ${res.status}`);
        }

        return await res.json();
    } catch (err) {
        console.error(`[inventario.js] GET ${endpoint} failed:`, err);
        throw err;
    }
}

async function apiPost(endpoint, data) {
    try {
        const body = new URLSearchParams();
        Object.entries(data || {}).forEach(([k, v]) => body.append(k, String(v ?? '')));

        const res = await fetch(`${API_BASE}${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'application/json'
            },
            body,
            credentials: 'same-origin'
        });

        if (!res.ok) {
            const error = await res.json().catch(() => ({ error: 'unknown' }));
            throw new Error(error.message || `HTTP ${res.status}`);
        }

        return await res.json();
    } catch (err) {
        console.error(`[inventario.js] POST ${endpoint} failed:`, err);
        throw err;
    }
}

// Toast notification
function toast(msg, type = 'info', duration = 5000) {
    const container = $('#toastContainer') || (() => {
        const c = document.createElement('div');
        c.id = 'toastContainer';
        c.className = 'position-fixed bottom-0 end-0 p-3';
        c.style.zIndex = '9999';
        document.body.appendChild(c);
        return c;
    })();

    const toastEl = document.createElement('div');
    toastEl.className = `toast align-items-center text-white bg-${type === 'error' ? 'danger' : type === 'success' ? 'success' : type === 'warning' ? 'warning' : 'info'} border-0`;
    toastEl.setAttribute('role', 'alert');
    toastEl.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">${esc(msg)}</div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
    `;

    container.appendChild(toastEl);
    const toast = new bootstrap.Toast(toastEl, { autohide: true, delay: duration });
    toast.show();

    toastEl.addEventListener('hidden.bs.toast', () => toastEl.remove());
}

// State
const state = {
    filters: {
        q: '',
        sucursal_id: '',
        categoria_id: '',
        status: 'all'
    },
    currentPage: 1,
    kpis: {},
    stock: [],
    categories: [],
    sucursales: [],
    almacenes: [],
    movementTypes: []
};

// Load KPIs
async function loadKPIs() {
    try {
        const response = await apiGet('/inventory/kpis');
        if (response.ok && response.data) {
            state.kpis = response.data;
            renderKPIs();
        }
    } catch (err) {
        console.error('Error loading KPIs:', err);
        toast('Error al cargar KPIs', 'error');
    }
}

function renderKPIs() {
    const { total_items = 0, inventory_value = 0, low_stock_count = 0, expiring_items = 0 } = state.kpis;

    const kpiTotal = $('#kpiTotalItems');
    const kpiValue = $('#kpiInventoryValue');
    const kpiLowStock = $('#kpiLowStock');
    const kpiExpiring = $('#kpiExpiring');

    if (kpiTotal) kpiTotal.textContent = fmt.number(total_items, 0);
    if (kpiValue) kpiValue.textContent = fmt.currency(inventory_value);
    if (kpiLowStock) kpiLowStock.textContent = fmt.number(low_stock_count, 0);
    if (kpiExpiring) kpiExpiring.textContent = fmt.number(expiring_items, 0);
}

// Load stock list
async function loadStockList() {
    const tbody = $('#stockTableBody');
    if (!tbody) return;

    tbody.innerHTML = '<tr><td colspan="8" class="text-center py-4"><div class="spinner-border spinner-border-sm text-primary me-2"></div>Cargando inventario...</td></tr>';

    try {
        const params = new URLSearchParams();
        if (state.filters.q) params.set('q', state.filters.q);
        if (state.filters.sucursal_id) params.set('sucursal_id', state.filters.sucursal_id);
        if (state.filters.categoria_id) params.set('categoria_id', state.filters.categoria_id);
        if (state.filters.status && state.filters.status !== 'all') params.set('status', state.filters.status);
        params.set('page', state.currentPage);
        params.set('per_page', 25);

        const response = await apiGet(`/inventory/stock/list?${params.toString()}`);

        if (response.ok && response.data) {
            state.stock = response.data.data || [];
            renderStockTable();
            renderPagination(response.data);
        }
    } catch (err) {
        console.error('Error loading stock:', err);
        tbody.innerHTML = '<tr><td colspan="8" class="text-center text-danger py-4"><i class="fa-solid fa-exclamation-triangle me-2"></i>Error al cargar inventario</td></tr>';
        toast('Error al cargar inventario', 'error');
    }
}

function renderStockTable() {
    const tbody = $('#stockTableBody');
    if (!tbody) return;

    if (state.stock.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center text-muted py-4"><i class="fa-solid fa-inbox me-2"></i>No hay items en inventario</td></tr>';
        return;
    }

    tbody.innerHTML = state.stock.map(item => {
        const stockClass = item.stock <= 0 ? 'text-danger' : item.stock < 10 ? 'text-warning' : 'text-success';
        const statusBadge = item.activo
            ? '<span class="badge bg-success-subtle text-success">Activo</span>'
            : '<span class="badge bg-secondary-subtle text-secondary">Inactivo</span>';

        return `
            <tr>
                <td>
                    <span class="badge bg-light text-dark font-monospace">${esc(item.sku)}</span>
                </td>
                <td>
                    <div class="fw-semibold">${esc(item.nombre)}</div>
                    ${item.descripcion ? `<small class="text-muted">${esc(item.descripcion)}</small>` : ''}
                </td>
                <td><span class="badge bg-info-subtle text-info">${esc(item.categoria)}</span></td>
                <td class="${stockClass} fw-semibold text-end">${fmt.number(item.stock, 2)}</td>
                <td class="text-muted">${esc(item.uom)}</td>
                <td class="text-end">${fmt.currency(item.costo)}</td>
                <td class="text-end fw-semibold">${fmt.currency(item.valor_total)}</td>
                <td>${statusBadge}</td>
                <td>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-primary" onclick="verKardex('${esc(item.sku)}')" title="Ver Kardex">
                            <i class="fa-solid fa-chart-line"></i>
                        </button>
                        <button class="btn btn-outline-secondary" onclick="movimientoRapido('${esc(item.sku)}')" title="Movimiento Rápido">
                            <i class="fa-solid fa-right-left"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

function renderPagination(paginationData) {
    const paginationEl = $('#stockPagination');
    if (!paginationEl || !paginationData) return;

    const { current_page = 1, last_page = 1, from = 0, to = 0, total = 0 } = paginationData;

    if (last_page <= 1) {
        paginationEl.innerHTML = '';
        return;
    }

    let html = '<ul class="pagination pagination-sm mb-0">';

    // Previous
    html += `<li class="page-item ${current_page <= 1 ? 'disabled' : ''}">
        <a class="page-link" href="#" onclick="changePage(${current_page - 1}); return false;">Anterior</a>
    </li>`;

    // Pages
    const maxPages = 5;
    let startPage = Math.max(1, current_page - Math.floor(maxPages / 2));
    let endPage = Math.min(last_page, startPage + maxPages - 1);
    startPage = Math.max(1, endPage - maxPages + 1);

    for (let i = startPage; i <= endPage; i++) {
        html += `<li class="page-item ${i === current_page ? 'active' : ''}">
            <a class="page-link" href="#" onclick="changePage(${i}); return false;">${i}</a>
        </li>`;
    }

    // Next
    html += `<li class="page-item ${current_page >= last_page ? 'disabled' : ''}">
        <a class="page-link" href="#" onclick="changePage(${current_page + 1}); return false;">Siguiente</a>
    </li>`;

    html += '</ul>';
    html += `<div class="text-muted small mt-2">Mostrando ${from} a ${to} de ${total} items</div>`;

    paginationEl.innerHTML = html;
}

function changePage(page) {
    state.currentPage = page;
    loadStockList();
}

// Load catalogs
async function loadCatalogs() {
    try {
        const [categories, sucursales, almacenes, movementTypes] = await Promise.all([
            apiGet('/catalogs/categories'),
            apiGet('/catalogs/sucursales'),
            apiGet('/catalogs/almacenes'),
            apiGet('/catalogs/movement-types')
        ]);

        if (categories.ok) state.categories = categories.data || [];
        if (sucursales.ok) state.sucursales = sucursales.data || [];
        if (almacenes.ok) state.almacenes = almacenes.data || [];
        if (movementTypes.ok) state.movementTypes = movementTypes.data || [];

        renderCatalogFilters();
    } catch (err) {
        console.error('Error loading catalogs:', err);
    }
}

function renderCatalogFilters() {
    // Populate category filter
    const catSelect = $('#filterCategoria');
    if (catSelect && state.categories.length > 0) {
        catSelect.innerHTML = '<option value="">Todas las categorías</option>' +
            state.categories.map(cat => `<option value="${esc(cat.id)}">${esc(cat.name)}</option>`).join('');
    }

    // Populate branch filter
    const sucSelect = $('#filterSucursal');
    if (sucSelect && state.sucursales.length > 0) {
        sucSelect.innerHTML = '<option value="">Todas las sucursales</option>' +
            state.sucursales.map(suc => `<option value="${esc(suc.id)}">${esc(suc.nombre)}</option>`).join('');
    }

    // Populate sucursal in movement form
    const movSucSelect = $('#movSucursal');
    if (movSucSelect && state.sucursales.length > 0) {
        movSucSelect.innerHTML = '<option value="">Seleccione sucursal...</option>' +
            state.sucursales.map(suc => `<option value="${esc(suc.id)}">${esc(suc.nombre)}</option>`).join('');
    }
}

// Filter handlers
function applyFilters() {
    const searchInput = $('#filterBuscar');
    const categorySelect = $('#filterCategoria');
    const branchSelect = $('#filterSucursal');
    const statusSelect = $('#filterEstado');

    state.filters.q = searchInput?.value || '';
    state.filters.categoria_id = categorySelect?.value || '';
    state.filters.sucursal_id = branchSelect?.value || '';
    state.filters.status = statusSelect?.value || 'all';
    state.currentPage = 1;

    loadStockList();
}

// Kardex modal
async function verKardex(itemId) {
    const modal = $('#modalKardex');
    if (!modal) return;

    const modalTitle = modal.querySelector('.modal-title .item-name');
    const tbody = modal.querySelector('#kardexTableBody');

    if (modalTitle) modalTitle.textContent = itemId;
    if (tbody) tbody.innerHTML = '<tr><td colspan="7" class="text-center py-4"><div class="spinner-border spinner-border-sm"></div></td></tr>';

    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();

    try {
        const response = await apiGet(`/inventory/items/${itemId}/kardex`);

        if (response.ok && response.data) {
            const movements = response.data;

            if (movements.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted py-4">No hay movimientos registrados</td></tr>';
                return;
            }

            let balance = 0;
            tbody.innerHTML = movements.map(mov => {
                const isInbound = ['ENTRADA', 'RECEPCION', 'COMPRA', 'TRASPASO_IN'].includes(mov.tipo);
                const qty = parseFloat(mov.cantidad || 0);
                balance += isInbound ? qty : -qty;

                return `
                    <tr>
                        <td class="text-muted small">${new Date(mov.ts).toLocaleDateString('es-MX')}</td>
                        <td class="text-muted small">${new Date(mov.ts).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' })}</td>
                        <td><span class="badge bg-${isInbound ? 'success' : 'danger'}-subtle text-${isInbound ? 'success' : 'danger'}">${esc(mov.tipo)}</span></td>
                        <td class="text-end ${isInbound ? 'text-success' : ''}">${isInbound ? fmt.number(qty, 3) : ''}</td>
                        <td class="text-end ${!isInbound ? 'text-danger' : ''}">${!isInbound ? fmt.number(qty, 3) : ''}</td>
                        <td class="text-end fw-semibold">${fmt.number(balance, 3)}</td>
                        <td class="text-muted small">${esc(mov.ref_tipo || '')} ${esc(mov.ref_id || '')}</td>
                    </tr>
                `;
            }).join('');
        }
    } catch (err) {
        console.error('Error loading kardex:', err);
        tbody.innerHTML = '<tr><td colspan="7" class="text-center text-danger py-4">Error al cargar kardex</td></tr>';
        toast('Error al cargar kardex', 'error');
    }
}

// Quick movement
function movimientoRapido(itemId) {
    const offcanvas = $('#offcanvasMovimiento');
    if (!offcanvas) return;

    const itemIdInput = offcanvas.querySelector('#movItemId');
    const tipoSelect = offcanvas.querySelector('#movTipo');

    if (itemIdInput) itemIdInput.value = itemId;

    // Populate movement types
    if (tipoSelect && state.movementTypes.length > 0) {
        tipoSelect.innerHTML = state.movementTypes
            .filter(t => ['ENTRADA', 'SALIDA', 'AJUSTE', 'MERMA'].includes(t.value))
            .map(t => `<option value="${esc(t.value)}">${esc(t.label)} (${t.sign})</option>`)
            .join('');
    }

    const bsOffcanvas = new bootstrap.Offcanvas(offcanvas);
    bsOffcanvas.show();
}

async function guardarMovimiento() {
    const form = $('#formMovimiento');
    if (!form) return;

    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    // Validation
    if (!data.item_id || !data.tipo || !data.cantidad || !data.sucursal_id) {
        toast('Por favor complete todos los campos requeridos', 'warning');
        return;
    }

    const btnGuardar = form.querySelector('[type="submit"]');
    if (btnGuardar) {
        btnGuardar.disabled = true;
        btnGuardar.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
    }

    try {
        const response = await apiPost('/inventory/movements', data);

        if (response.ok) {
            toast('Movimiento guardado exitosamente', 'success');

            // Close offcanvas
            const offcanvas = bootstrap.Offcanvas.getInstance('#offcanvasMovimiento');
            if (offcanvas) offcanvas.hide();

            // Reset form
            form.reset();

            // Reload data
            loadKPIs();
            loadStockList();
        } else {
            toast(response.message || 'Error al guardar movimiento', 'error');
        }
    } catch (err) {
        console.error('Error saving movement:', err);
        toast('Error al guardar movimiento', 'error');
    } finally {
        if (btnGuardar) {
            btnGuardar.disabled = false;
            btnGuardar.innerHTML = '<i class="fa-solid fa-save me-2"></i>Guardar';
        }
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    console.log('[inventario.js] Initializing...');

    // Load initial data
    loadKPIs();
    loadCatalogs();
    loadStockList();

    // Setup filter listeners
    const filterBtn = $('#btnAplicarFiltros');
    if (filterBtn) filterBtn.addEventListener('click', applyFilters);

    // Setup search on Enter
    const searchInput = $('#filterBuscar');
    if (searchInput) {
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                e.preventDefault();
                applyFilters();
            }
        });
    }

    // Setup movement form
    const formMov = $('#formMovimiento');
    if (formMov) {
        formMov.addEventListener('submit', (e) => {
            e.preventDefault();
            guardarMovimiento();
        });
    }

    console.log('[inventario.js] Initialized successfully');
});

// Global exports
window.verKardex = verKardex;
window.movimientoRapido = movimientoRapido;
window.changePage = changePage;
window.applyFilters = applyFilters;
