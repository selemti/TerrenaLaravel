// assets/js/caja/wizard.js
import { BASE, DENOMS, MXN, api } from './config.js';
import { $, GET, GET_SOFT, POST_FORM, toast } from './helpers.js';
import { els, state } from './state.js';

/* ======= Utils de formato y parseo ======= */
const fmt = (n)=> MXN.format(Number(n||0));

const parseNum = (v)=>{
  if (v == null) return 0;
  const s = String(v).trim();
  if (!s) return 0;
  // “1.234,56” -> 1234.56  |  “1,234.56” -> 1234.56
  if (/^\d{1,3}(\.\d{3})*(,\d+)?$/.test(s)) return Number(s.replace(/\./g,'').replace(',', '.')) || 0;
  return Number(s.replace(/,/g,'')) || 0;
};

const formatInputMoney = (el)=>{
  const v = parseNum(el.value);
  el.value = v.toFixed(2); // deja 2 decimales
};

/** Entradas “no efectivo”: parseo robusto + formateo “.00”
		"12,345.67" / "12.345,67" / "12345" -> number */
function toNumber(x){
  let s = String(x ?? '').trim();
  if (s === '') return 0;
  if (/^\d{1,3}(\.\d{3})*(,\d+)?$/.test(s)) {          // 1.234,56
    s = s.replace(/\./g,'').replace(',', '.');
  } else {
    s = s.replace(/,/g,'');                            // 12,345.67
  }
  const n = parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}
function formatTwo(n){ return toNumber(n).toFixed(2); }
function bindMoneyInput(el){
  if (!el) return;
  el.addEventListener('input', ()=>{ el.dataset.touched='1'; });
  el.addEventListener('blur',  ()=>{ el.value = formatTwo(el.value); el.dataset.touched='1'; recalcPaso1(); });
  el.placeholder = '0.00';
}

// Reemplaza cualquier el por su clon y devuelve el clon (sirve para limpiar listeners)
function bindOnce(el, handler, event='click') {
  if (!el) return null;
  const clone = el.cloneNode(true);
  el.replaceWith(clone);
  if (handler) clone.addEventListener(event, handler);
  return clone;
}

// Recarga la tabla tras acciones
function reloadTable() {
  window.recargarTablaCajas && window.recargarTablaCajas();
}

// --- Inicialización del modal ---
let modalInstance = null;
function initModal() {
  const modalElement = document.getElementById('czModalPrecorte');
  if (!modalElement) {
    console.error('[wizard.js] Modal #czModalPrecorte no encontrado en el DOM');
    fallbackModal('Error: Modal de precorte no encontrado. Verifica _wizard_modals.php');
    return null;
  }

  modalInstance = new bootstrap.Modal(modalElement, {
    backdrop: 'static',
    keyboard: false
  });

  // Limpiar event listeners en botones (para evitar duplicados)
  bindOnce(els.btnGuardarPrecorte, guardarPrecorte);
  bindOnce(els.btnContinuarConc, continuarConciliacion);
  bindOnce(els.btnIrPostcorte, irPostcorte);
  bindOnce(els.btnPCGuardar, guardarBorradorPostcorte);
  bindOnce(els.btnPCValidar, validarPostcorte);

  return modalInstance;
}

async function postFirstAlive(pathCandidates, payload, queryString='') {
  let lastErr = null;
  for (const rel of pathCandidates) {
    const url = `${BASE}/api/${rel}${queryString ? `?${queryString}` : ''}`;
    try {
      const r = await POST_FORM(url, payload);
      if (r?.ok) return r;                // listo
      lastErr = r;                        // no ok, seguimos con la siguiente
    } catch (e) {
      lastErr = e;                        // 404/500 lance excepción → seguimos
    }
  }
  // si ninguna respondió ok, propagamos el último error
  if (lastErr instanceof Error) throw lastErr;
  throw new Error('Ninguna ruta válida: ' + pathCandidates.join(' | '));
}

/* =============== STEP / UI =============== */
export function setStep(n){
  state.step = n;
  if (!els.modal) return;

  if (els.step1) els.step1.classList.toggle('d-none', n!==1);
  if (els.step2) els.step2.classList.toggle('d-none', n!==2);
  if (els.step3) els.step3.classList.toggle('d-none', n!==3);

  if (els.stepBar){
    const pct = n===1?33:(n===2?66:100);
    els.stepBar.style.width = pct+'%';
    els.stepBar.setAttribute('aria-valuenow', String(pct));
  }

  // visibilidad por paso
  if (els.btnGuardarPrecorte) els.btnGuardarPrecorte.classList.toggle('d-none', n!==1);
  if (els.btnContinuarConc)   els.btnContinuarConc.classList.add('d-none');     // ya no se usa
  if (els.btnSincronizarPOS)  els.btnSincronizarPOS.classList.toggle('d-none', n!==2); // solo lo mostramos si falta DPR
  if (els.btnIrPostcorte)     els.btnIrPostcorte.classList.toggle('d-none', n!==2);
  if (els.btnCerrarSesion)    els.btnCerrarSesion.classList.toggle('d-none', n!==3);

  // botón Ir a Postcorte siempre deshabilitado hasta tener DPR
  if (n===2 && els.btnIrPostcorte) els.btnIrPostcorte.disabled = true;

  // Paso 1: limpia los “no efectivo” si es un nuevo precorte
  if (n===1 && !state.pasoGuardado){
    [els.declCredito, els.declDebito, els.declTransfer].forEach(el=>{ if(el){ el.value='0'; el.dataset.touched='0'; }});
  }
}

function ensureModalRefs(){
  const modal = document.querySelector('#czModalPrecorte, #modalPrecorte, #wizardPrecorte, .modal[data-role="precorte"]');
  els.modal = modal || null;
  if (!els.modal) return false;

  // steps + barra
  els.step1  = els.modal.querySelector('#czStep1,#step1,[data-step="1"]');
  els.step2  = els.modal.querySelector('#czStep2,#step2,[data-step="2"]');
  els.step3  = els.modal.querySelector('#czStep3,#step3,[data-step="3"]');
  els.stepBar= els.modal.querySelector('#czStepBar,.progress-bar,[data-role="stepbar"]');

  // botones (incluye cz*)
  els.btnGuardarPrecorte = els.modal.querySelector('#czBtnGuardarPrecorte,#btnGuardarPrecorte,[data-action="guardar-precorte"]');
  els.btnContinuarConc   = els.modal.querySelector('#czBtnContinuarConciliacion,#btnContinuarConc,[data-action="continuar-conc"]');
  els.btnSincronizarPOS  = els.modal.querySelector('#czBtnSincronizarPOS,#btnSincronizarPOS,[data-action="sincronizar-pos"]');
  els.btnIrPostcorte     = els.modal.querySelector('#czBtnIrPostcorte,#btnIrPostcorte,[data-action="ir-postcorte"]');
  els.btnCerrarSesion    = els.modal.querySelector('#czBtnCerrarSesion,#btnCerrarSesion,[data-action="cerrar-sesion"]');
  els.btnAutorizar       = els.modal.querySelector('[data-action="autorizar-corte"]');

  // campos paso 1
  els.tablaDenomsBody = els.modal.querySelector('#czTablaDenoms tbody,#tablaDenomsBody,[data-role="denoms-body"]');
  els.precorteTotal   = els.modal.querySelector('#czPrecorteTotal,#precorteTotal,[data-role="precorte-total"]');
  els.declCredito     = els.modal.querySelector('#czDeclCardCredito,#declCredito,[data-role="decl-credito"]');
  els.declDebito      = els.modal.querySelector('#czDeclCardDebito,#declDebito,[data-role="decl-debito"]');
  els.declTransfer    = els.modal.querySelector('#czDeclTransfer,#declTransfer,[data-role="decl-transfer"]');
  els.notasPaso1      = els.modal.querySelector('#czNotes,#notasPaso1,[data-role="notas-paso1"]');

  // paso 2
  els.chipFondo       = els.modal.querySelector('#czChipFondo,[data-role="chip-fondo"]');
  els.efEsperadoInfo  = els.modal.querySelector('#czEfectivoEsperado,[data-role="ef-esperado"]');
  els.concGrid        = els.modal.querySelector('#czConciliacionGrid,#concGrid,[data-role="conc-grid"]');
  els.bannerFaltaCorte= els.modal.querySelector('#czBannerFaltaCorte,[data-role="banner-falta-corte"]');

  // paso 3 (soporta ids alternativos que mencionaste)
  els.pc3Grid   = els.modal.querySelector('#pc3Grid');
  els.pc3VerE   = els.modal.querySelector('#pc3VerEfectivo');
  els.pc3VerTj  = els.modal.querySelector('#pc3VerTarjetas');
  els.pc3VerTr  = els.modal.querySelector('#pc3VerTransf');
  els.pc3Notas  = els.modal.querySelector('#pc3Notas');
  els.pc3BtnG   = els.modal.querySelector('#btnGuardarPostcorte,#btnPCGuardar');
  els.pc3BtnV   = els.modal.querySelector('#btnValidarPostcorte,#btnPCValidar');

  // hidden
  els.inputPrecorteId = document.querySelector('#cz_precorte_id,#precorteId,[data-role="precorte-id"]');
  return true;
}

/* === ÚNICO handler para “Ir a Postcorte” (sin duplicados) === */
bindIrPostcorteUnique

/* =============== DENOMS (Paso 1) =============== */
export function bindDenoms(){
  if (!els.tablaDenomsBody) return;
  els.tablaDenomsBody.innerHTML = '';
  state.denoms.clear();
  DENOMS.forEach(den=>{
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>$${den}</td>
      <td><input type="number" min="0" step="1" class="form-control form-control-sm cz-qty" data-denom="${den}" value="" inputmode="numeric" placeholder="0"></td>
      <td class="text-end cz-amt" data-denom="${den}">${MXN.format(0)}</td>`;
    els.tablaDenomsBody.appendChild(tr);
  });
  els.tablaDenomsBody.querySelectorAll('.cz-qty').forEach(inp=>{
    inp.addEventListener('input',()=>{
      const denom = Number(inp.dataset.denom);
      const qty   = Math.max(0, parseInt(inp.value||'0',10) || 0);
      state.denoms.set(denom, qty);
      const amt = denom * qty;
      const cell= els.tablaDenomsBody.querySelector(`.cz-amt[data-denom="${denom}"]`);
      if (cell) cell.textContent = MXN.format(amt);
      recalcPaso1();
    });
  });
}

// Parseo tolerante: "12,123" -> 12123 ; "1.234,56" -> 1234.56 ; "50" -> 50
function parseMoneyInput(el){
  if (!el) return 0;
  let s = String(el.value ?? '').trim();
  if (s === '') return 0;
  // si hay ambas , y . asumimos estilo 1.234,56
  if (/\d\.\d{3}(?:\.\d{3})*,\d{1,2}$/.test(s)) {
    s = s.replace(/\./g, '').replace(',', '.');
  } else {
    // quitar separadores de miles
    s = s.replace(/,/g,'');
  }
  const n = parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}
const fmt2 = n => (Number(n||0)).toFixed(2);

export function recalcPaso1(){
  let totalEf = 0;
  state.denoms.forEach((qty,den)=> totalEf += den*qty);
  if (els.precorteTotal) els.precorteTotal.textContent = fmt(totalEf);

  const getNE = (el)=> parseNum(el?.value);
  const credito  = getNE(els.declCredito);
  const debito   = getNE(els.declDebito);
  const transfer = getNE(els.declTransfer);

  const camposNE = [els.declCredito, els.declDebito, els.declTransfer];
  const filledNE = camposNE.every(el=>{
    if (!el) return false;
    return el.dataset.touched==='1' && el.value.trim()!=='' && parseNum(el.value) >= 0;
  });

  const okDenoms = totalEf > 0;
  if (els.btnGuardarPrecorte) els.btnGuardarPrecorte.disabled = !(okDenoms && filledNE);

  if (els.chipFondo)      els.chipFondo.textContent      = fmt(state.sesion.opening||0);
  if (els.efEsperadoInfo) els.efEsperadoInfo.textContent = fmt(state.sesion.opening||0);
}


/* =============== ABRIR WIZARD =============== */
export async function abrirWizard(ev){
  ev?.preventDefault?.();

  const btn = (
    ev?.currentTarget?.closest?.('[data-caja-action="wizard"]') ||
    ev?.target?.closest?.('[data-caja-action="wizard"]')
  );
  if (!btn){ toast('No se pudo resolver el botón del wizard','err', 8000, 'UI'); return; }
  if (btn.__busy) return; btn.__busy = true;

  const d = (k)=> (btn.dataset && k in btn.dataset) ? btn.dataset[k] : btn.getAttribute?.(`data-${k}`);
  const store    = parseInt(d('store')||'0',10);
  const terminal = parseInt(d('terminal')||'0',10);
  const user     = parseInt(d('user')||'0',10);
  const bdate    = String(d('bdate')||'').trim();
  const opening  = Number(d('opening')||0);
  const sesion   = parseInt(d('sesion')||'0',10);

  state.sesion = { store, terminal, user, bdate, opening, sesion_id: sesion || 0 };
  state.precorteId = null;
  state.postcorteId = null;
  state.pasoGuardado = false;

  // Limpia “no efectivo” y denoms
  const resetNE = (el)=>{ if (!el) return; el.value=''; el.dataset.touched='0'; };
  resetNE(els.declCredito); resetNE(els.declDebito); resetNE(els.declTransfer);
  if (els.notasPaso1) els.notasPaso1.value = '';

  if (!store || !terminal || !user || !bdate){
    toast('Faltan store/terminal/usuario','err', 12000, 'Datos incompletos', {sticky:true});
    btn.__busy = false; return;
  }

  try{
    // 0) Preflight
    if (sesion){
      const pre = await GET(`${BASE}/api/caja/precortes/preflight?sesion_id=${encodeURIComponent(sesion)}`);
      if (pre?.bloqueo){
        const n = pre.tickets || pre.tickets_abiertos || 0;
        mostrarAvisoElegante('Corte bloqueado',`Hay <b>${n}</b> ticket(s) abiertos. Cierra/cancela y vuelve a intentar.`,
          ()=> abrirWizard({ currentTarget: btn }));
        btn.__busy = false; return;
      }
    }

    // 1) Crear/recuperar precorte
    const payload = { bdate, store_id:store, terminal_id:terminal, user_id:user, sesion_id: sesion || '' };
    const j = await POST_FORM(api.precorte_create(), payload);
    if (!j?.ok || !j?.precorte_id){
      toast('No se pudo iniciar/recuperar precorte','err',12000,'Error',{sticky:true});
      btn.__busy=false; return;
    }
    state.precorteId = j.precorte_id;
    els.inputPrecorteId && (els.inputPrecorteId.value = String(state.precorteId));

    // 2) UI
    if (!ensureModalRefs()){
      fallbackModal(`Precorte #${state.precorteId} listo, pero no se encontró el modal real. Incluye <code>_wizard_modals.php</code>.`);
      btn.__busy=false; return;
    }
    wireDelegates();
    bindModalButtons();

    // 2b) Reanudar postcorte si quedó abierto (cerraste modal sin validar)
    const recalled = sesion ? recallPostcorte(sesion) : 0;
    if (recalled){
      state.postcorteId = recalled;
      setStep(3);
      const modal = initModal();
      if (!modal) { btn.__busy=false; return; }
      modal.show();
      await renderPaso3();
      btn.__busy=false; return;
    }

    // 3) Decidir paso por estatus (ENVIADO ⇒ Paso 2)
    let est = (j?.estatus || '').toUpperCase();
    try{
      const st = await GET_SOFT(`/api/precortes/${state.precorteId}/status`);
      if (st?.estatus) est = String(st.estatus).toUpperCase();
    }catch(_){}

    const abrirPaso2 = (est === 'ENVIADO');
    if (abrirPaso2){
      setStep(2);
      const modal = initModal();
      if (!modal) { btn.__busy=false; return; }
      modal.show();
      await sincronizarPOS(true);        // muestra/oculta botones según DPR
      bindIrPostcorteUnique();
      btn.__busy = false; return;
    }

    // Paso 1
    [els.declCredito, els.declDebito, els.declTransfer].forEach(el=>{
      if (!el) return;
      el.placeholder = '0.00';
      el.addEventListener('input', ()=>{ el.dataset.touched='1'; /* no formatees aquí para no “brincar” el cursor */ });
      el.addEventListener('blur',  ()=>{ el.dataset.touched='1'; formatInputMoney(el); recalcPaso1(); });
    });
    bindDenoms();
    recalcPaso1();
    setStep(1);
    const modal = initModal();
    if (!modal) { btn.__busy=false; return; }
    modal.show();
    bindIrPostcorteUnique();

  } catch(e){
    if (e?.status === 409 && e?.payload?.tickets_abiertos != null){
      const n = e.payload.tickets_abiertos;
      mostrarAvisoElegante('Corte bloqueado',`Hay <b>${n}</b> ticket(s) abiertos. Cierra/cancela y vuelve a intentar.`,
        ()=> abrirWizard({ currentTarget: btn }));
    } else {
      toast(`Error iniciando precorte: ${e.message}`, 'err', 15000, 'Error', {sticky:true});
    }
  } finally {
    btn.__busy = false;
  }
}

/* =============== GUARDAR (Paso 1) =============== */
async function guardarPrecorte(){
  if (!state.precorteId){ toast('No hay precorte activo','err',9000,'Error'); return; }

  // Montos capturados
  let totalEf = 0; const denoms = [];
  state.denoms.forEach((qty,den)=>{ if (qty>0){ denoms.push({den,qty}); totalEf += den*qty; }});

	const credito  = parseNum(els.declCredito?.value);
	const debito   = parseNum(els.declDebito ?.value);
	const transfer = parseNum(els.declTransfer?.value);
  const notas    = String(els.notasPaso1?.value||'').trim();

  const totalNoEf = (credito||0)+(debito||0)+(transfer||0);
  const totalDecl = totalEf + totalNoEf;

  const html = `
    <div class="mb-2">Se guardará el precorte <b>#${state.precorteId}</b> con:</div>
    <table class="table table-sm align-middle mb-2">
      <tbody>
        <tr><td>Efectivo</td><td class="text-end fw-semibold">${MXN.format(totalEf)}</td></tr>
        <tr><td>Tarjeta crédito</td><td class="text-end">${MXN.format(credito)}</td></tr>
        <tr><td>Tarjeta débito</td><td class="text-end">${MXN.format(debito)}</td></tr>
        <tr><td>Transferencias</td><td class="text-end">${MXN.format(transfer)}</td></tr>
        <tr class="table-light"><th>Total declarado</th><th class="text-end">${MXN.format(totalDecl)}</th></tr>
      </tbody>
    </table>
    ${notas ? `<div class="small text-muted">Notas: ${notas}</div>` : '' }
  `;
  const ok = await confirmElegante('Confirmar guardado', html, 'Cancelar', 'Guardar');
  if (!ok) return;

  try{
    const payload = {
      denoms_json: JSON.stringify(denoms),
      declarado_credito:  credito,
      declarado_debito:   debito,
      declarado_transfer: transfer,
      notas
    };
    const j = await POST_FORM(api.precorte_update(state.precorteId), payload);
    if (!j?.ok){ toast('No se pudo guardar precorte','err', 9000, 'Error'); return; }

    try { await POST_FORM(`${BASE}/api/precortes/${state.precorteId}/enviar`, { estatus:'ENVIADO' }); } catch(_){}

    state.pasoGuardado = true;
    toast('Precorte guardado','ok',6000,'Listo');

    // formatea campos “no efectivo”
    [els.declCredito, els.declDebito, els.declTransfer].forEach(el=>{ if (el) el.value = fmt2(parseMoneyInput(el)); });

    setStep(2);
    await sincronizarPOS(true);
    bindIrPostcorteUnique();
  }catch(e){
    toast(`Error guardando precorte: ${e.message}`,'err',9000,'Error');
  }
}
/* =============== Paso 2: Conciliación =============== */
// Paso 2: sincroniza, muestra conciliación y habilita/deshabilita "Ir a Postcorte".
// NUNCA muestra el botón "Sincronizar POS".
export async function sincronizarPOS(auto=false){
  if (!state.precorteId){ toast('No hay precorte activo','err', 9000, 'Error'); return; }
  els.bannerFaltaCorte?.classList.add('d-none');
  if (els.concGrid) els.concGrid.innerHTML = '<div class="text-muted small">Sincronizando con POS…</div>';

  // Por default, no dejamos avanzar
  if (els.btnIrPostcorte) els.btnIrPostcorte.disabled = true;

  const j = await GET_SOFT(api.precorte_totales(state.precorteId));

  // Si no hay DPR: mostramos banner y (si existe) botón "Sincronizar POS"
  if (!j?.ok){
    els.bannerFaltaCorte?.classList.remove('d-none');
    if (els.btnSincronizarPOS) els.btnSincronizarPOS.classList.remove('d-none');
    if (!auto){
      mostrarAvisoElegante(
        'Falta realizar el corte en POS',
        'Aún no hay Drawer Pull Report en Floreant POS. Realiza el corte y pulsa <b>Sincronizar</b>.',
        ()=> sincronizarPOS(false)
      );
    } else if (els.concGrid) {
      els.concGrid.innerHTML = '<div class="small text-muted">Esperando corte en POS…</div>';
    }
    return;
  }

  // Con DPR: ocultamos “Sincronizar POS” y habilitamos “Ir a Postcorte”
  if (els.btnSincronizarPOS) els.btnSincronizarPOS.classList.add('d-none');
  if (els.btnIrPostcorte)    els.btnIrPostcorte.disabled = false;

  const d = j.data || {};
  renderConciliacion(d, j);
  bindIrPostcorteUnique();
}

function statusBadge(diff){
  const v = diff===0 ? 'CUADRA' : (diff>0 ? 'A_FAVOR' : 'EN_CONTRA');
  const cls = v==='CUADRA' ? 'success' : (v==='A_FAVOR' ? 'primary' : 'danger');
  return `<span class="badge bg-${cls}">${v}</span>`;
}

export function renderConciliacion(d, raw){
  if (!els.concGrid) return;

  const efectivo_decl = Number(d?.efectivo?.declarado||0);
  const efectivo_sys  = Number(d?.efectivo?.sistema  ||0);
  const credito_decl  = Number(d?.tarjeta_credito?.declarado||0);
  const credito_sys   = Number(d?.tarjeta_credito?.sistema  ||0);
  const debito_decl   = Number(d?.tarjeta_debito?.declarado ||0);
  const debito_sys    = Number(d?.tarjeta_debito?.sistema   ||0);
  const transf_decl   = Number(d?.transferencias?.declarado ||0);
  const transf_sys    = Number(d?.transferencias?.sistema   ||0);

  const tjDecl = credito_decl + debito_decl;
  const tjSys  = credito_sys  + debito_sys;

  const row = (name, decl, sys)=>{
    const diff = decl - sys;
    const v = diff===0 ? 'CUADRA' : (diff>0 ? 'A_FAVOR' : 'EN_CONTRA');
    const cls = v==='CUADRA' ? 'success' : (v==='A_FAVOR' ? 'primary' : 'danger');
    return `
      <tr>
        <td>${name}</td>
        <td class="text-end">${MXN.format(decl)}</td>
        <td class="text-end">${MXN.format(sys)}</td>
        <td class="text-end">${MXN.format(diff)}</td>
        <td class="text-center"><span class="badge bg-${cls}">${v}</span></td>
      </tr>`;
  };

  const opening = Number(raw?.opening_float||state.sesion.opening||0);
  const netEf   = efectivo_sys - opening;

  els.concGrid.innerHTML = `
    <table class="table table-sm align-middle mb-2">
      <thead><tr>
        <th>Categoría</th><th class="text-end">Declarado</th><th class="text-end">Sistema</th><th class="text-end">Diferencia</th><th class="text-center">Estado</th>
      </tr></thead>
      <tbody>
        ${row('Efectivo',         efectivo_decl, efectivo_sys)}
        ${row('Tarjeta Crédito',  credito_decl,  credito_sys)}
        ${row('Tarjeta Débito',   debito_decl,   debito_sys)}
        ${row('Transferencias',   transf_decl,   transf_sys)}
      </tbody>
    </table>

    <div class="row g-2 small">
      <div class="col-12 col-md-3">
        <div class="border rounded p-2 h-100">
          <div class="text-muted">Fondo de caja</div>
          <div class="fw-semibold">${MXN.format(opening)}</div>
        </div>
      </div>
      <div class="col-12 col-md-3">
        <div class="border rounded p-2 h-100">
          <div class="text-muted">Ventas netas en efectivo (sistema – fondo)</div>
          <div class="fw-semibold">${MXN.format(netEf)}</div>
        </div>
      </div>
      <div class="col-12 col-md-3">
        <div class="border rounded p-2 h-100">
          <div class="text-muted">Total tarjetas (sistema)</div>
          <div class="fw-semibold">${MXN.format(tjSys)}</div>
        </div>
      </div>
      <div class="col-12 col-md-3">
        <div class="border rounded p-2 h-100">
          <div class="text-muted">Transferencias (sistema)</div>
          <div class="fw-semibold">${MXN.format(transf_sys)}</div>
        </div>
      </div>
    </div>
  `;
}

function veredictoFromDiff(d){
  d = Number(d||0);
  return d===0 ? 'CUADRA' : (d>0 ? 'A_FAVOR' : 'EN_CONTRA');
}
function badgeVeredicto(diff){
  const v = veredictoFromDiff(diff);
  const cls = v==='CUADRA' ? 'success' : (v==='A_FAVOR' ? 'primary' : 'danger');
  return `<span class="badge bg-${cls}">${v}</span>`;
}
function rowConc(name, declarado, sistema){
  const diff = Number(declarado||0) - Number(sistema||0);
  return `
    <tr>
      <td>${name}</td>
      <td class="text-end">${MXN.format(Number(declarado||0))}</td>
      <td class="text-end">${MXN.format(Number(sistema||0))}</td>
      <td class="text-end">${MXN.format(diff)}</td>
      <td class="text-center">${badgeVeredicto(diff)}</td>
    </tr>`;
}
function bindIrPostcorteUnique(){
  if (!els || !els.btnIrPostcorte) return;
  const old = els.btnIrPostcorte;
  const clone = old.cloneNode(true);
  old.replaceWith(clone);
  els.btnIrPostcorte = clone;
  els.btnIrPostcorte.disabled = !!(els.bannerFaltaCorte && !els.bannerFaltaCorte.classList.contains('d-none'));

  els.btnIrPostcorte.addEventListener('click', async (e)=>{
    e.preventDefault(); e.stopPropagation();
    if (els.btnIrPostcorte.__busy) return;
    els.btnIrPostcorte.__busy = true;
    try { await irAPostcorte(); }
    finally { els.btnIrPostcorte.__busy = false; }
  });
}

/* =============== Bind botones reales =============== */
export function bindModalButtons(){
  if (!els.modal) return;
  if (els.modal.dataset.bound === '1') return;
  els.modal.dataset.bound = '1';

  const stop = (fn)=> (ev)=>{ ev.preventDefault(); ev.stopPropagation(); fn(); };

  if (els.btnGuardarPrecorte){
    els.btnGuardarPrecorte.addEventListener('click', stop(guardarPrecorte));
    els.btnGuardarPrecorte.disabled = true;
  }

  if (els.btnContinuarConc){
    els.btnContinuarConc.addEventListener('click', (ev)=>{
      ev.preventDefault(); ev.stopPropagation();
      if (!state.pasoGuardado){
        toast('Primero guarda el precorte.','warn', 5000, 'Validación');
        return;
      }
      setStep(2);
    });
    els.btnContinuarConc.disabled = true;
  }

  if (els.btnSincronizarPOS){
    els.btnSincronizarPOS.addEventListener('click', stop(()=> sincronizarPOS(false)));
  }

  // Paso 3 (listeners por si ya existen los botones en el DOM)
  if (els.pc3BtnG) els.pc3BtnG.addEventListener('click', stop(()=> guardarPostcorte(false)));
  if (els.pc3BtnV) els.pc3BtnV.addEventListener('click', stop(()=> guardarPostcorte(true)));

  if (els.btnCerrarSesion){
    els.btnCerrarSesion.addEventListener('click', stop(()=>{
      try { bootstrap.Modal.getInstance(els.modal)?.hide(); } catch(_){}
      toast('Sesión cerrada.', 'ok', 6000, 'Listo');
      import('./mainTable.js').then(m => m.cargarTabla().catch(()=>{}));
    }));
  }
}

/* =============== Paso 3: Postcorte =============== */
// === Paso 3: crear postcorte (sin rutas /caja) ===
async function irAPostcorte(){
  if (!state.precorteId){
    toast('No hay precorte activo','err',9000,'Error');
    return;
  }
  // si ya lo teníamos, reanudar
  if (state.postcorteId){
    setStep(3);
    await renderPaso3();
    return;
  }

  try{
    // ÚNICA ruta válida en tu API
    const j = await POST_FORM(`${BASE}/api/postcortes?precorte_id=${encodeURIComponent(state.precorteId)}`, {});
    if (!j?.ok) throw new Error(j?.error || 'No se pudo generar el Post-corte');

    state.postcorteId = j.postcorte_id;
    if (j.sesion_id) state.sesionId = j.sesion_id;
    if (state.sesionId) rememberPostcorte(state.sesionId, state.postcorteId);

    setStep(3);
    await renderPaso3();
    toast(`Post-corte #${j.postcorte_id} generado`, 'ok', 4000, 'Listo');
  }catch(e){
    toast(`Error generando Post-corte: ${e.message}`,'err',9000,'Error');
  }
}

/* ===== Paso 3: pinta resumen y conecta botones ===== */
async function renderPaso3(){
  const grid  = document.querySelector('#pc3Grid');
  const notas = document.querySelector('#pc3Notas, #postcorteNotas');
  const btnG  = document.querySelector('#btnPCGuardar, #btnGuardarPostcorte');
  const btnV  = document.querySelector('#btnPCValidar, #btnValidarPostcorte');
  const btnClose = document.querySelector('#btnCerrarSesion,[data-bs-dismiss="modal"]');

  if (!grid || !btnV || !btnClose) return;

  // ocultar "Guardar borrador"
  if (btnG) btnG.classList.add('d-none');

  // mover "Validar y cerrar" al lado de Cerrar (mismo contenedor)
  //try { btnClose.parentNode.insertBefore(btnV, btnClose); } catch(_) {}

  // resumen con datos frescos del precorte
  const r = await GET(`${BASE}/api/caja/precorte_totales.php?id=${state.precorteId}`);
  if (!r?.ok){ toast('No fue posible cargar totales de precorte','err',9000,'Error'); return; }
  const d = r.data || {};

  const efD = Number(d?.efectivo?.declarado||0), efS = Number(d?.efectivo?.sistema||0);
  const crD = Number(d?.tarjeta_credito?.declarado||0), crS = Number(d?.tarjeta_credito?.sistema||0);
  const dbD = Number(d?.tarjeta_debito ?.declarado||0), dbS = Number(d?.tarjeta_debito ?.sistema||0);
  const trD = Number(d?.transferencias?.declarado||0), trS = Number(d?.transferencias?.sistema||0);

  const tjD = crD + dbD, tjS = crS + dbS;

  const row = (label, dec, sys) => {
    const diff = +(dec - sys).toFixed(2);
    const ver  = diff === 0 ? 'CUADRA' : (diff > 0 ? 'A_FAVOR' : 'EN_CONTRA');
    const cls  = ver==='CUADRA' ? 'success' : (ver==='A_FAVOR' ? 'primary' : 'danger');
    return `<tr>
      <td>${label}</td>
      <td class="text-end">${fmt(dec)}</td>
      <td class="text-end">${fmt(sys)}</td>
      <td class="text-end">${fmt(diff)}</td>
      <td class="text-center"><span class="badge bg-${cls}">${ver}</span></td>
    </tr>`;
  };

  grid.innerHTML = `
    <table class="table table-sm align-middle mb-3">
      <thead><tr>
        <th>Categoría</th><th class="text-end">Declarado</th>
        <th class="text-end">Sistema</th><th class="text-end">Diferencia</th><th class="text-center">Veredicto</th>
      </tr></thead>
      <tbody>
        ${row('Efectivo', efD, efS)}
        ${row('Tarjetas (C + D)', tjD, tjS)}
        ${row('Transferencias', trD, trS)}
      </tbody>
    </table>
    <label class="form-label">Notas del postcorte</label>
  `;

  // re-bind limpio (evita doble diálogo)
  const cloneV = btnV.cloneNode(true);
  btnV.replaceWith(cloneV);

  cloneV.addEventListener('click', async (ev)=>{
    ev.preventDefault();
    await guardarPostcorte(true);
  });
}

function rowConcWithSelect(name, declarado, sistema, selectId){
  const diff = Number(declarado||0) - Number(sistema||0);
  const opts = ['CUADRA','A_FAVOR','EN_CONTRA'].map(v=>`<option value="${v}">${v}</option>`).join('');
  const badge = badgeVeredicto(diff);
  return `
    <tr>
      <td>${name}</td>
      <td class="text-end">${MXN.format(Number(declarado||0))}</td>
      <td class="text-end">${MXN.format(Number(sistema||0))}</td>
      <td class="text-end">${MXN.format(diff)}</td>
      <td class="text-center">
        <select id="${selectId}" class="form-select form-select-sm" style="max-width: 140px; margin-inline:auto">
          ${opts}
        </select>
      </td>
    </tr>`;
}

/* Guarda/valida el postcorte */
let _pcSaving = false; // flag anti-doble click

/* ===== Guardar/Validar con diálogo bonito ===== */
/* ===== Guardar/Validar con diálogo bonito + fallbacks de ruta ===== */
let __pcSaving = false;
/* ===== Guardar/Validar con diálogo bonito (rutas corregidas) ===== */
/* ===== Guardar/Validar con diálogo bonito ===== */
async function guardarPostcorte(validar){
  if (!state?.postcorteId){
    toast('No hay postcorte creado aún.','err',9000,'Error');
    return;
  }
  if (guardarPostcorte.__busy) return;
  guardarPostcorte.__busy = true;

  // Relee diferencias para el resumen de confirmación
  const tot = await GET(`${BASE}/api/caja/precorte_totales.php?id=${state.precorteId}`);
  if (!tot?.ok){
    toast('No fue posible recalcular diferencias.','err',9000,'Error');
    guardarPostcorte.__busy = false;
    return;
  }
  const d = tot.data || {};
  const efD = +Number(d?.efectivo?.declarado||0);
  const efS = +Number(d?.efectivo?.sistema  ||0);
  const crD = +Number(d?.tarjeta_credito?.declarado||0);
  const crS = +Number(d?.tarjeta_credito?.sistema  ||0);
  const dbD = +Number(d?.tarjeta_debito ?.declarado||0);
  const dbS = +Number(d?.tarjeta_debito ?.sistema  ||0);
  const trD = +Number(d?.transferencias?.declarado||0);
  const trS = +Number(d?.transferencias?.sistema  ||0);

  const dif = {
    ef: +(efD-efS).toFixed(2),
    cr: +(crD-crS).toFixed(2),
    db: +(dbD-dbS).toFixed(2),
    tj: +((crD+dbD)-(crS+dbS)).toFixed(2),
    tr: +(trD-trS).toFixed(2),
  };

  if (validar){
    const html = `
      <div class="mb-2">Se guardará el postcorte y se cerrará la sesión.</div>
      <ul class="list-unstyled mb-0 small">
        <li class="mb-1"><span class="text-muted">Diferencia efectivo:</span> <b>${MXN.format(dif.ef)}</b></li>
        <li class="mb-1"><span class="text-muted">Diferencia tarjetas:</span> <b>${MXN.format(dif.tj)}</b>
          <span class="text-muted"> (Crédito ${MXN.format(dif.cr)}, Débito ${MXN.format(dif.db)})</span>
        </li>
        <li><span class="text-muted">Diferencia transferencias:</span> <b>${MXN.format(dif.tr)}</b></li>
      </ul>`;
    const ok = await confirmElegante('Validar y cerrar', html, 'Cancelar', 'Aceptar');
    if (!ok){ guardarPostcorte.__busy = false; return; }
  }

  // veredictos automáticos (si no usas selects manuales)
  const ver = (v)=> v===0 ? 'CUADRA' : (v>0 ? 'A_FAVOR' : 'EN_CONTRA');
  const payload = {
    veredicto_efectivo:       ver(dif.ef),
    veredicto_tarjetas:       ver(dif.tj),
    veredicto_transferencias: ver(dif.tr),
    notas: (document.querySelector('#pc3Notas, #postcorteNotas')?.value || '').trim()
  };
  if (validar){
    payload.validado = 1;
    payload.sesion_estatus = 'CERRADA';
  }

  // deshabilita mientras guarda
  const btnV = document.querySelector('#btnPCValidar');
  const btnC = document.querySelector('#btnPCCancelar');
  if (btnV) btnV.disabled = true;
  if (btnC) btnC.disabled = true;

  try{
    // **ÚNICA ruta de update en tu API**
    const res = await POST_FORM(`${BASE}/api/postcortes?id=${encodeURIComponent(state.postcorteId)}`, payload);
    if (!res?.ok) throw new Error(res?.error || 'falló guardado');

    toast(validar ? 'Postcorte validado y cerrado.' : 'Postcorte guardado.','ok',4000,'Listo');

    if (validar){
      // limpiar “pendiente” de sesión y cerrar modal
      if (state.sesionId) forgetPostcorte(state.sesionId);
      try { bootstrap.Modal.getInstance(els.modal)?.hide(); } catch(_){}

      // refrescar tabla desde BD y ocultar el CTA del wizard
      try { window?.recargarTablaCajas?.(); } catch(_){}
      document
        .querySelectorAll(`[data-caja-action="wizard"][data-sesion="${state.sesionId}"]`)
        .forEach(b => b.classList.add('d-none'));
    }else{
      // re-habilitar si sólo fue borrador
      if (btnV) btnV.disabled = false;
      if (btnC) btnC.disabled = false;
    }
  }catch(e){
    console.error('[postcorte] save error', e);
    toast('No fue posible guardar/validar el postcorte','err',9000,'Error');
    if (btnV) btnV.disabled = false;
    if (btnC) btnC.disabled = false;
  }finally{
    guardarPostcorte.__busy = false;
  }
}

// ===== Persistencia ligera para reanudar paso 3 por sesión =====
function rememberPostcorte(sesionId, postcorteId){
  try { sessionStorage.setItem(`postcorte:${sesionId}`, String(postcorteId)); } catch(_) {}
}
function recallPostcorte(sesionId){
  try {
    const v = sessionStorage.getItem(`postcorte:${sesionId}`);
    return v ? parseInt(v, 10) : 0;
  } catch(_) { return 0; }
}
function forgetPostcorte(sesionId){
  try { sessionStorage.removeItem(`postcorte:${sesionId}`); } catch(_) {}
}

/* =============== Fallback delegado (si no hay botones reales) =============== */
function wireDelegates(){
  if (!els.modal) return;
  if (els.__wired) return; els.__wired = true;

  const hasBtns = !!(els.btnGuardarPrecorte || els.btnContinuarConc || els.btnSincronizarPOS || els.btnIrPostcorte || els.pc3BtnG || els.pc3BtnV);
  if (hasBtns) return;

  els.modal.querySelectorAll(
    '#czBtnGuardarPrecorte,#btnGuardarPrecorte,[data-action="guardar-precorte"],' +
    '#czBtnContinuarConciliacion,#btnContinuarConc,[data-action="continuar-conc"],' +
    '#czBtnSincronizarPOS,#btnSincronizarPOS,[data-action="sincronizar-pos"],' +
    '#czBtnIrPostcorte,#btnIrPostcorte,[data-action="ir-postcorte"],' +
    '#btnGuardarPostcorte,#btnPCGuardar,#btnValidarPostcorte,#btnPCValidar'
  ).forEach(b=> b.setAttribute('type','button'));

  els.modal.addEventListener('click', (e)=>{
    const save = e.target.closest('#czBtnGuardarPrecorte,#btnGuardarPrecorte,[data-action="guardar-precorte"]');
    if (save){ e.preventDefault(); guardarPrecorte(); return; }

    const cont = e.target.closest('#czBtnContinuarConciliacion,#btnContinuarConc,[data-action="continuar-conc"]');
    if (cont){
      e.preventDefault();
      if (!state.pasoGuardado){ toast('Primero guarda el precorte.','warn',5000,'Validación'); return; }
      setStep(2); return;
    }

    const sync = e.target.closest('#czBtnSincronizarPOS,#btnSincronizarPOS,[data-action="sincronizar-pos"]');
    if (sync){ e.preventDefault(); sincronizarPOS(false); return; }

    const go3  = e.target.closest('#czBtnIrPostcorte,#btnIrPostcorte,[data-action="ir-postcorte"]');
    if (go3){
      e.preventDefault();
      if (els.btnIrPostcorte?.disabled){ toast('Aún no hay corte en POS','warn',6000,'Aviso'); return; }
      irAPostcorte(); return;
    }

    const pcSave = e.target.closest('#btnGuardarPostcorte,#btnPCGuardar');
    if (pcSave){ e.preventDefault(); guardarPostcorte(false); return; }

    const pcVal = e.target.closest('#btnValidarPostcorte,#btnPCValidar');
    if (pcVal){ e.preventDefault(); guardarPostcorte(true); return; }
  });
}

/* =============== Diálogos bonitos =============== */
function mostrarAvisoElegante(titulo, htmlCuerpo, onRetry){
  if (window.bootstrap?.Modal) {
    const el = document.createElement('div');
    el.className = 'modal fade'; el.tabIndex = -1;
    el.innerHTML = `
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">${titulo}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body"><p class="mb-0">${htmlCuerpo}</p></div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cerrar</button>
            <button type="button" class="btn btn-primary" data-role="retry">Reintentar</button>
          </div>
        </div>
      </div>`;
    document.body.appendChild(el);
    const m = new bootstrap.Modal(el, {backdrop:'static',keyboard:true});
    el.addEventListener('hidden.bs.modal', ()=> el.remove(), {once:true});
    el.querySelector('[data-role="retry"]').onclick = ()=>{ m.hide(); onRetry && onRetry(); };
    m.show();
    return;
  }
  const ov = document.createElement('div');
  ov.style.cssText='position:fixed;inset:0;z-index:99999;background:rgba(0,0,0,.45);display:flex;align-items:center;justify-content:center;padding:16px';
  ov.innerHTML = `
    <div style="background:#fff;max-width:520px;width:100%;border-radius:14px;box-shadow:0 12px 40px rgba(0,0,0,.25);overflow:hidden">
      <div style="padding:12px 16px;border-bottom:1px solid #eee;display:flex;gap:8px;align-items:center">
        <strong style="font-size:16px">${titulo}</strong>
        <span style="margin-left:auto;cursor:pointer;font-weight:bold" data-x>×</span>
      </div>
      <div style="padding:16px;font-size:14px">${htmlCuerpo}</div>
      <div style="padding:12px 16px;display:flex;gap:8px;justify-content:flex-end;background:#fafafa;border-top:1px solid #eee">
        <button type="button" data-x class="btn btn-light">Cerrar</button>
        <button type="button" data-retry class="btn btn-primary">Reintentar</button>
      </div>
    </div>`;
  document.body.appendChild(ov);
  const close = ()=> ov.remove();
  ov.querySelector('[data-x]').onclick = close;
  ov.querySelector('[data-retry]').onclick = ()=>{ close(); onRetry && onRetry(); };
}

function confirmElegante(titulo, htmlCuerpo, txtCancel='Cancelar', txtOk='Aceptar'){
  return new Promise((resolve)=>{
    if (window.bootstrap?.Modal){
      const el = document.createElement('div');
      el.className = 'modal fade'; el.tabIndex=-1;
      el.innerHTML = `
        <div class="modal-dialog modal-dialog-centered">
          <div class="modal-content">
            <div class="modal-header" style="background: #f8f8f8; padding: 5px 18px;">
              <h5 class="modal-title" style="font-weight: bolder;">${titulo}</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <div class="modal-body">${htmlCuerpo}</div>
            <div class="modal-footer">
              <button class="btn btn-outline-secondary" data-role="cancel" type="button">${txtCancel}</button>
              <button class="btn btn-primary" data-role="ok" type="button">${txtOk}</button>
            </div>
          </div>
        </div>`;
      document.body.appendChild(el);
      const m = new bootstrap.Modal(el, {backdrop:'static', keyboard:true});
      const btnOk = el.querySelector('[data-role="ok"]');
      const btnCa = el.querySelector('[data-role="cancel"]');

      const setBusy = (v)=> {
        btnOk.disabled = v; btnCa.disabled = v;
        btnOk.innerHTML = v ? 'Guardando…' : txtOk;
      };
      const done = (v)=>{ try{ m.hide(); }catch(_){} el.addEventListener('hidden.bs.modal', ()=> el.remove(), {once:true}); resolve(v); };

      btnCa.onclick = ()=> done(false);
      btnOk.onclick = ()=> { setBusy(true); done(true); };
      el.addEventListener('keydown', (ev)=>{
        if (ev.key === 'Escape') { ev.preventDefault(); btnCa.click(); }
        if (ev.key === 'Enter')  { ev.preventDefault(); btnOk.click(); }
      });

      m.show();
      return;
    }
    resolve( confirm(`${titulo}\n\n${htmlCuerpo.replace(/<[^>]*>/g,'')}`) );
  });
}

/* =============== Fallback modal (debug) =============== */
function fallbackModal(html){
  let ov = document.getElementById('__debug_fallback_modal');
  if (!ov){
    ov = document.createElement('div');
    ov.id='__debug_fallback_modal';
    ov.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:99999;display:flex;align-items:center;justify-content:center';
    ov.innerHTML = `
      <div style="background:#fff;max-width:720px;width:92%;border-radius:10px;box-shadow:0 10px 40px rgba(0,0,0,.25);overflow:hidden">
        <div style="padding:10px 14px;border-bottom:1px solid #eee;display:flex;align-items:center;gap:8px">
          <strong>Precorte</strong>
          <span style="margin-left:auto;cursor:pointer;font-weight:bold" id="__debug_fallback_close">×</span>
        </div>
        <div id="__debug_fallback_body" style="padding:14px;max-height:70vh;overflow:auto"></div>
      </div>`;
    document.body.appendChild(ov);
    ov.querySelector('#__debug_fallback_close').onclick=()=>ov.remove();
  }
  ov.querySelector('#__debug_fallback_body').innerHTML = html;
  ov.style.display='flex';
}

// acceso global (como lo usas en la tabla)
if (!window.abrirWizard) window.abrirWizard = abrirWizard;
// Exponer utils de postcorte pendiente para que la tabla los use
if (!window.czRecallPostcorte) window.czRecallPostcorte = recallPostcorte;
if (!window.czForgetPostcorte) window.czForgetPostcorte = forgetPostcorte;