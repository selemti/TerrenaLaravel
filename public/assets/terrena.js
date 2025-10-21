// Terrena JS â€“ Layout + Dashboard
// Sucursales (fijo por ahora, luego desde BD)
const BRANCHES = ['Principal','NB','Torre','Terrena'];

// Rutas de logos
const LOGO_FULL = (window.__BASE__ || '') + '/assets/img/logo.svg';
const LOGO_MINI = (window.__BASE__ || '') + '/assets/img/logo2.svg';

document.addEventListener('DOMContentLoaded', () => {
  const sidebar             = document.getElementById('sidebar');
  const sidebarCollapseBtn  = document.getElementById('sidebarCollapse');        // desktop
  const sidebarToggleMobile = document.getElementById('sidebarToggleMobile');    // móvil
  const logoImg             = document.getElementById('logoImg');                // <img> del logo

  function syncLogo(isCollapsed){
    if (!logoImg) return;
    logoImg.src = isCollapsed ? LOGO_MINI : LOGO_FULL;
    logoImg.alt = isCollapsed ? 'Terrena mini' : 'Terrena';
  }

  function ensureDesktopState(){
    if (!sidebar) return;
    if (window.innerWidth >= 992){
      sidebar.classList.remove('show'); // oculta overlay si vuelve a desktop
    }else{
      // En móvil preferimos expandido completo
      if (sidebar.classList.contains('collapsed')){
        sidebar.classList.remove('collapsed');
        document.body.classList.remove('collapsed');
        syncLogo(false);
      }
    }
  }

  // ===== Toggle MÓVIL (off-canvas) =====
  sidebarToggleMobile?.addEventListener('click', (e) => {
    e.preventDefault();
    if (!sidebar) return;
    if (window.innerWidth < 992) {
      sidebar.classList.toggle('show');
    }
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
    const isCollapsed = !sidebar.classList.contains('collapsed');
    sidebar.classList.toggle('collapsed', isCollapsed);
    document.body.classList.toggle('collapsed', isCollapsed);
    sidebar.classList.remove('show'); // por si estaba abierto en móvil
    syncLogo(isCollapsed);
  });
  // Ajuste si recarga colapsado (por CSS server-side, si aplica)
  if (sidebar?.classList.contains('collapsed') || document.body.classList.contains('collapsed')) {
    sidebar?.classList.add('collapsed');
    document.body.classList.add('collapsed');
    syncLogo(true);
  }

  window.addEventListener('resize', ensureDesktopState);
  ensureDesktopState();

  // ===== Reloj / Fecha =====
  tickClock();
  setInterval(tickClock, 1000);

  // ===== Filtros =====
  setupFilters();

  // ===== Listas (header y tablero) =====
  renderHeaderAlerts();
  renderKpiRegisters();
  renderActivity();
  renderOrders();

  // ===== GrÃ¡ficas =====
  initCharts();
  if (window.Terrena && typeof Terrena.initDashboardCharts === 'function') {
    Terrena.initDashboardCharts();
  }
});

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

  s.value = toISODate(weekAgo);
  e.value = toISODate(today);

  btn?.addEventListener('click', () => {
    const desde = s.value;
    const hasta = e.value;
    if (window.Terrena && typeof Terrena.initDashboardCharts === 'function') {
      Terrena.initDashboardCharts({ desde, hasta });
    }
    toast('Filtros aplicados');
  });
}
function toISODate(d){return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`}

/* =============== Header Alerts (campana) =============== */
function renderHeaderAlerts(){
  const badge = document.getElementById('hdr-alerts-badge');
  const list  = document.getElementById('hdr-alerts-list');
  if (!badge || !list) return;

  // Dummy (reemplazar por tu API)
  const data = [
    {type:'low',  icon:'fa-triangle-exclamation text-warning', txt:'Inventario bajo: Leche (10L)',       minutesAgo: 8},
    {type:'error',icon:'fa-circle-exclamation text-danger',    txt:'Diferencia en corte: Sucursal NB',   minutesAgo: 18},
    {type:'info', icon:'fa-tags text-primary',                 txt:'Descuento > $50 en ticket #521',     minutesAgo: 25},
    {type:'low',  icon:'fa-triangle-exclamation text-warning', txt:'A punto de agotarse: CafÃ© de Altura',minutesAgo: 47},
    {type:'info', icon:'fa-ticket text-primary',               txt:'Tickets abiertos: 3 en Torre',       minutesAgo: 60},
  ].slice(0,5);

  badge.textContent = data.length;
  badge.style.display = (data.length > 0) ? 'inline-block' : 'none';

  list.innerHTML = data.map(a => `
    <a class="hdr-alert" href="${(window.__BASE__||'')+'/reportes'}">
      <i class="fa-solid ${a.icon}"></i>
      <span>${a.txt}</span>
      <span class="timeago">${timeago(a.minutesAgo)}</span>
    </a>`).join('');
}

/* =============== KPIs â€“ Estatus de cajas (tabla) =============== */
function renderKpiRegisters(){
  const tbody = document.getElementById('kpi-registers');
  if (!tbody) return;
  const rows = [
    {sucursal:'Principal', abierto:true,  vendido: 3250.50},
    {sucursal:'NB',        abierto:false, vendido: 0.00},
    {sucursal:'Torre',     abierto:true,  vendido: 1980.00},
    {sucursal:'Terrena',   abierto:false, vendido: 0.00},
  ];
  tbody.innerHTML = rows.map(r => `
    <tr>
      <td>${r.sucursal}</td>
      <td>${r.abierto
        ? '<span class="badge text-bg-success">Abierto</span>'
        : '<span class="badge text-bg-secondary">Cerrado</span>'}</td>
      <td class="text-end">${r.abierto ? money(r.vendido) : '-'}</td>
    </tr>`).join('');
}

/* =============== Actividad reciente =============== */
function renderActivity(){
  const ul = document.getElementById('activity-list');
  if (!ul) return;
  const items = [
    {txt:'Admin cerrÃ³ corte en Principal', minutesAgo:12},
    {txt:'OC #1024 registrada a LÃ¡cteos MX', minutesAgo:28},
    {txt:'Descuento 15% aplicado en ticket #531', minutesAgo:39},
    {txt:'OP-001 (Tortas de pollo x20) generada', minutesAgo:52},
    {txt:'Costo actualizado: Leche 1.5L', minutesAgo:63},
  ].slice(0,5);
  ul.innerHTML = items.map(i => `
    <li><i class="fa-solid fa-circle small text-muted"></i>
      <span>${i.txt}</span>
      <span class="timeago">${timeago(i.minutesAgo)}</span>
    </li>`).join('');
}

/* =============== Ã“rdenes recientes =============== */
function renderOrders(){
  const tb = document.getElementById('orders-table');
  if (!tb) return;
  const rows = [
    {ticket: 1543, suc:'Principal', hora:'13:42', total: 128.50},
    {ticket: 1542, suc:'Torre',     hora:'13:35', total:  58.00},
    {ticket: 1541, suc:'NB',        hora:'13:31', total:  82.90},
    {ticket: 1540, suc:'Principal', hora:'13:25', total:  32.00},
    {ticket: 1539, suc:'Principal', hora:'13:18', total:  49.00},
  ].slice(0,5);
  tb.innerHTML = rows.map(r => `
    <tr><td>${r.ticket}</td><td>${r.suc}</td><td>${r.hora}</td><td class="text-end">${money(r.total)}</td></tr>
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

/* =============== Charts =============== */
function initCharts(){
  if (typeof Chart === 'undefined') return;

  // Tendencia 7 dÃ­as
  if (document.getElementById('salesTrendChart')) {
    makeLine('salesTrendChart',
      ['Lun','Mar','MiÃ©','Jue','Vie','SÃ¡b','Dom'],
      [{label:'Ventas Diarias ($)',data:[2450,3120,2980,4050,4780,6250,5820],bg:'rgba(233,122,58,.2)',stroke:'#E97A3A'}]
    );
  }

  // Ventas por hora â€“ barra apilada por sucursal
  if (document.getElementById('salesByHourChart')) {
    const hours = ['08h','09h','10h','11h','12h','13h','14h','15h','16h','17h'];
    makeStackedBars('salesByHourChart', hours, [
      {label:'Principal', data:[120,180,260,340,520,620,600,520,430,350], color:'#234330'},
      {label:'NB',        data:[ 20, 30, 45, 60,  80,100, 90, 70, 50, 40], color:'#D2B464'},
      {label:'Torre',     data:[ 10, 20, 35,  0,  20, 30, 40, 50, 60, 70], color:'#E97A3A'},
      {label:'Terrena',   data:[  0,  0, 10, 20,  30, 50, 60, 40, 20, 10], color:'#6C757D'},
    ]);
  }

  // Top 5 productos â€“ horizontal apilada por sucursal
  if (document.getElementById('topProductsChart')) {
    const labels = ['Latte Vainilla','Capuchino','Torta Pollo','Americano','Croissant'];
    makeStackedHorizontalBars('topProductsChart', labels, [
      {label:'Principal', data:[350.25, 290.10, 245.00, 230.40, 190.50], color:'#234330'},
      {label:'NB',        data:[ 40.00,  35.00,  20.00,  18.00,  12.00], color:'#D2B464'},
      {label:'Torre',     data:[ 30.00,  25.00,  18.00,  15.00,  10.00], color:'#E97A3A'},
      {label:'Terrena',   data:[ 10.00,  12.00,   8.00,   9.00,   6.00], color:'#6C757D'},
    ]);
  }

  // Ventas por sucursal por tipo (apilada)
  if (document.getElementById('branchPaymentsChart')) {
    makeStackedBars('branchPaymentsChart', BRANCHES, [
      {label:'Efectivo', data:[2100,1800,1200,900],  color:'#D2B464'},
      {label:'Tarjeta',  data:[2600,1500,1400,800],  color:'#E97A3A'},
      {label:'Transf.',  data:[ 500, 300, 250,120],  color:'#234330'},
    ]);
  }

  // Formas de pago (dona)
  if (document.getElementById('paymentChart')) {
    makeDoughnut('paymentChart',
      ['Efectivo','Tarjeta','Transferencia'],
      [650.25, 920.50, 80.00],
      ['#D2B464','#E97A3A','#234330']
    );
  }
}

/* ====== Chart helpers ====== */
function makeLine(canvasId, labels, datasets){
  const ctx = document.getElementById(canvasId);
  new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: datasets.map(ds => ({
        label: ds.label,
        data: ds.data,
        fill: true,
        backgroundColor: ds.bg || 'rgba(0,0,0,.05)',
        borderColor: ds.stroke || '#333',
        tension: 0.35,
        pointRadius: 0
      }))
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: true } },
      scales: { x: { grid:{display:false} }, y: { beginAtZero: true } }
    }
  });
}

function makeStackedBars(canvasId, labels, series){
  const ctx = document.getElementById(canvasId);
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: series.map(s => ({
        label: s.label, data: s.data, backgroundColor: s.color, borderWidth:0
      }))
    },
    options: {
      responsive:true, maintainAspectRatio:false,
      plugins:{ legend:{ display:true } },
      scales:{
        x:{ stacked:true, grid:{ display:false } },
        y:{ stacked:true, beginAtZero:true }
      }
    }
  });
}

function makeStackedHorizontalBars(canvasId, labels, series){
  const ctx = document.getElementById(canvasId);
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: series.map(s => ({
        label: s.label, data: s.data, backgroundColor: s.color, borderWidth:0
      }))
    },
    options: {
      indexAxis: 'y',
      responsive:true, maintainAspectRatio:false,
      plugins:{ legend:{ display:true } },
      scales:{
        x:{ stacked:true, beginAtZero:true },
        y:{ stacked:true, grid:{ display:false } }
      }
    }
  });
}

function makeDoughnut(canvasId, labels, data, colors){
  const ctx = document.getElementById(canvasId);
  new Chart(ctx, {
    type: 'doughnut',
    data: { labels, datasets:[{ data, backgroundColor: colors }] },
    options: { responsive:true, maintainAspectRatio:false, plugins:{ legend:{ position:'bottom' } } }
  });
}
/* === CAJA: Cortes de caja (Precorte â†’ Corte â†’ Postcorte) === */

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

      // Acciones segÃºn etapa
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
    // reiniciar conteo rÃ¡pido
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

    // 2) subir conteo rÃ¡pido
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
        // MOCK: los declarados los tomamos de pantalla precorte (o backend cuando estÃ© listo)
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
    const payload = { /* en real mandarÃ­as sys/decl */ };
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

  // 1) SelecciÃ³n de caja â†’ setear hidden inputs (store/terminal) del form "abrir precorte"
  const formAbrir = document.querySelector('form[action$="/caja/cortes/abrir"]');
  const hidStore = qs('#form-abrir-store');
  const hidTerm = qs('#form-abrir-terminal');

  function parseSel(val) {
    // val esperado: "Sucursal|Terminal"
    const [suc, termStr] = (val || '').split('|');
    // Mapea sucursal -> id (mock). En real vendrÃ¡ de BD (stores)
    const map = { 'Principal': 1, 'NB': 2, 'Torre': 3, 'Terrena': 4 };
    return { store_id: map[suc] || null, terminal_id: parseInt(termStr || '0', 10) || null };
    // Si ya tendrÃ¡s store_id y terminal_id reales en el value del radio, omite el map.
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

  // 2) NavegaciÃ³n de tabs
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

  // 3) Conteo rÃ¡pido de denominaciones
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
    // Valores fake para demo; en vivo harÃ¡s fetch a /caja/precorte/:id/sistema
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

// === Cortes de Caja: conteo rÃ¡pido y conciliaciÃ³n ===
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

  // ConciliaciÃ³n mock
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

// Carga datasets reales y pinta gráficas (Chart.js)
window.Terrena.initDashboardCharts = async function(range){
  const base = (window.__BASE__||'') + '/api/reports';
  const today = new Date().toISOString().slice(0,10);
  const desde = range?.desde || today;
  const hasta = range?.hasta || today;
  const q = `?desde=${desde}&hasta=${hasta}`;
  try{
    const [kpisSuc, ventasFam, ventasHora, topProd, tkAvg, itemsRes, formas] = await Promise.all([
      fetch(base + '/kpis/sucursal'+q).then(r=>r.json()),
      fetch(base + '/ventas/familia'+q).then(r=>r.json()),
      fetch(base + '/ventas/hora'+q).then(r=>r.json()),
      fetch(base + '/ventas/top'+q+'&limit=5').then(r=>r.json()),
      fetch(base + '/ticket/promedio'+q).then(r=>r.json()),
      fetch(base + '/ventas/items_resumen'+q).then(r=>r.json()),
      fetch(base + '/ventas/formas'+q).then(r=>r.json()),
    ]);
    // KPIs
    const totalVentasHoy = (kpisSuc.data||[]).reduce((s,r)=> s + (r.sistema_efectivo||0) + (r.sistema_no_efectivo||0), 0);
    const kpiSales = document.getElementById('kpi-sales-today'); if(kpiSales) kpiSales.textContent = money(totalVentasHoy);
    const kpiAvg = document.getElementById('kpi-avg-ticket'); if(kpiAvg) kpiAvg.textContent = money(tkAvg.ticket_promedio||0);
    const kpiItems = document.getElementById('kpi-items-sold'); if(kpiItems) kpiItems.textContent = (itemsRes.unidades||0).toLocaleString('es-MX');
    const kpiStar = document.getElementById('kpi-star-product'); if(kpiStar) kpiStar.textContent = (topProd.data&&topProd.data[0]) ? topProd.data[0].plu : '-';

    // Ventas por hora
    if (typeof Chart !== 'undefined'){
      const ctxHora = document.getElementById('salesByHourChart');
      if(ctxHora){
        const labels = (ventasHora.data||[]).map(r=> new Date(r.hora).toLocaleTimeString('es-MX',{hour:'2-digit'}));
        const data = (ventasHora.data||[]).map(r=> Number(r.venta_total||0));
        new Chart(ctxHora.getContext('2d'), {
          type: 'bar', data: { labels, datasets: [{ label: 'Venta', data, backgroundColor: '#4e79a7' }] },
          options: { responsive:true, plugins:{ legend:{ display:false } } }
        });
      }
      // Formas de pago (dona)
      const ctxPay = document.getElementById('paymentChart');
      if(ctxPay){
        const labels = (formas.data||[]).map(r=> r.codigo_fp||'OTROS');
        const data = (formas.data||[]).map(r=> Number(r.monto||0));
        new Chart(ctxPay.getContext('2d'), {
          type: 'doughnut', data: { labels, datasets: [{ data, backgroundColor: ['#59a14f','#e15759','#f28e2b','#76b7b2','#edc948'] }] },
          options: { responsive:true }
        });
      }
      // Ventas por sucursal (por familia) apilada
      const ctxBranch = document.getElementById('branchPaymentsChart');
      if(ctxBranch){
        const rows = ventasFam.data||[];
        const sucursales = [...new Set(rows.map(r=> r.sucursal_id||''))];
        const familias = [...new Set(rows.map(r=> r.familia||'OTROS'))];
        const datasets = familias.map((fam,i)=>({
          label: fam,
          data: sucursales.map(s=> Number((rows.find(r=> r.sucursal_id==s && r.familia==fam)||{}).venta_total||0)),
          backgroundColor: ['#4e79a7','#f28e2b','#e15759','#76b7b2','#59a14f','#edc948','#b07aa1','#ff9da7'][i%8]
        }));
        new Chart(ctxBranch.getContext('2d'),{ type:'bar', data:{ labels: sucursales, datasets }, options:{ responsive:true, scales:{ x:{stacked:true}, y:{stacked:true} } } });
      }
      // Top productos
      const ctxTop = document.getElementById('topProductsChart');
      if(ctxTop){
        const rows = topProd.data||[];
        const labels = rows.map(r=> r.plu);
        const data = rows.map(r=> Number(r.venta_total||0));
        new Chart(ctxTop.getContext('2d'),{ type:'bar', data:{ labels, datasets:[{ label:'Venta', data, backgroundColor:'#9c755f' }] }, options:{ indexAxis:'y', plugins:{legend:{display:false}} } });
      }
    }
  }catch(e){ console.error('Error cargando datasets', e); }
};

