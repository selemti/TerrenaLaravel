//import { DEBUG } from './config.js';

//import { DEBUG } from './config.js';

export const $   = (s, r) => (r || document).querySelector(s);
export const esc = (x) => String(x ?? '').replace(/[&<>"']/g, m => ({
  '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;', "'":'&#39;'
}[m]));

//export function log(...args){ if (DEBUG) console.log('[caja.js]', ...args); }
function log(kind, url, payload){ try{ console.log(`[caja.js] ${kind} ${url}`, payload||''); }catch(_){} }


export function err(...args){ console.error('[caja.js]', ...args); }

const inflight = new Map();

/* ================= HTTP ================= */

// helpers.js
export async function GET(url, { timeout = 15000, headers } = {}) {
  inflight ||= new Map();
  const key = `GET ${url}`;
  if (inflight.has(key)) return inflight.get(key);

  const p = (async () => {
    log('GET', url);
    const ctrl = new AbortController();
    const tmr  = setTimeout(() => ctrl.abort('timeout'), timeout);

    let res, text = '', ct = '';
    try {
      res = await fetch(url, {
        credentials: 'same-origin',
        headers: { 'Accept': 'application/json', ...(headers || {}) },
        signal: ctrl.signal
      });

      text = await res.text();
      ct   = (res.headers.get('content-type') || '').toLowerCase();
      const isJson  = ct.includes('application/json');
      let payload   = null;
      if (isJson && text) { try { payload = JSON.parse(text); } catch(e) { throw new Error(`Parse JSON failed: ${e.message}`); } }

      if (!res.ok) {
        console.error('[caja.js] GET ERR', { status: res.status, ct, len: text.length, text, payload });
        throw { status: res.status, ct, text, payload };
      }

      return payload || text;
    } catch (e) {
      console.error('[caja.js] GET END', e);
      throw e;
    } finally {
      clearTimeout(tmr);
    }
  })();

  inflight.set(key, p);
  p.finally(() => inflight.delete(key));
  return p;
}
// POST_FORM
export async function POST_FORM(url, payload = {}, { timeout = 15000, headers } = {}) {
    log('POST', url, payload);

    const formData = new FormData();
    for (const [key, value] of Object.entries(payload)) {
        formData.append(key, value);
    }

    const ctrl = new AbortController();
    const tmr  = setTimeout(() => ctrl.abort('timeout'), timeout);

    let res, text = '', ct = '';
    try {
        res = await fetch(url, {
            method: 'POST',
            credentials: 'same-origin',
            body: formData,
            headers: { ...headers },
            signal: ctrl.signal
        });

        text = await res.text();
        ct   = (res.headers.get('content-type') || '').toLowerCase();
        const isJson  = ct.includes('application/json');
        let payload   = null;
        if (isJson && text) { try { payload = JSON.parse(text); } catch {} }

        if (!res.ok) {
            console.error('[caja.js] POST ERR', {
                status: res.status, ct, len: text.length,
                text: text,
                payload
            });
            throw {status: res.status, ct, text, payload};
        }

        return payload || text;
    } catch (e) {
        console.error('[caja.js] POST END', e);
        throw e;
    } finally {
        clearTimeout(tmr);
    }
}
/* =============== Fechas =============== */

export function normalizeDate(input){
  const s = String(input || '').trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
  const m = s.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
  return m ? `${m[3]}-${m[2]}-${m[1]}` : s;
}
export function todayISO(){
  const d = new Date(), mm = String(d.getMonth()+1).padStart(2,'0'), dd = String(d.getDate()).padStart(2,'0');
  return `${d.getFullYear()}-${mm}-${dd}`;
}
export function currentDate(){
  const f = document.querySelector('#filtroFecha') || document.querySelector('#fecha');
  return normalizeDate(f?.value || todayISO());
}

/* =============== Toasts =============== */

export function toast(msg, kind='info', ms=6000, title='', opts={}){
  const sticky  = opts.sticky === true || ms === 0;
  const actions = Array.isArray(opts.actions) ? opts.actions : [];

  if (!document.querySelector('style[data-toast-css]')) {
    const style = document.createElement('style');
    style.setAttribute('data-toast-css','1');
    style.textContent = `
#toastWrap{position:fixed;right:16px;bottom:16px;display:flex;flex-direction:column;gap:8px;z-index:9999}
.toast{min-width:280px;max-width:420px;padding:12px 14px;border-radius:8px;color:#fff;box-shadow:0 6px 24px rgba(0,0,0,.2);opacity:.98;transition:opacity .2s,transform .2s}
.toast.ok{background:#198754}.toast.info{background:#0d6efd}
.toast.warn{background:#ffc107;color:#111}.toast.err{background:#dc3545}
.toast.hide{opacity:0;transform:translateY(6px)}
.toast .row{display:flex;align-items:center;gap:8px}
.toast .ttl{font-weight:600;margin-right:auto}
.toast .close{cursor:pointer;font-weight:bold}
.toast .bar{height:3px;background:rgba(255,255,255,.6);width:100%;transform-origin:left}
.toast .acts{display:flex;gap:8px;margin-top:8px;flex-wrap:wrap}
.toast .btn{background:rgba(0,0,0,.18);border:0;color:#fff;padding:6px 10px;border-radius:6px;cursor:pointer}
.toast .btn:hover{background:rgba(0,0,0,.28)}
    `;
    document.head.appendChild(style);
  }
  let wrap = document.getElementById('toastWrap');
  if (!wrap) { wrap = document.createElement('div'); wrap.id='toastWrap'; document.body.appendChild(wrap); }

  const el = document.createElement('div');
  el.className = `toast ${kind}`;
  el.innerHTML = `
    <div class="row">
      ${title ? `<span class="ttl">${esc(title)}</span>` : ''}
      <span class="close" aria-label="Cerrar">×</span>
    </div>
    <div class="msg">${esc(msg)}</div>
    ${actions.length ? `<div class="acts"></div>` : ``}
    ${sticky ? `` : `<div class="bar"></div>`}
  `;
  wrap.appendChild(el);

  const closeBtn = el.querySelector('.close');
  const bar = el.querySelector('.bar');
  const acts = el.querySelector('.acts');

  let timer, start = Date.now(), remaining = ms;
  const close = ()=>{ clearTimeout(timer); el.classList.add('hide'); setTimeout(()=> el.remove(), 200); };
  const pause = ()=>{ if (sticky) return; remaining -= (Date.now() - start); clearTimeout(timer); };
  const resume = ()=>{ if (sticky) return; start = Date.now(); timer = setTimeout(close, remaining); };

  if (!sticky && bar){
    bar.style.transition = `transform ${ms}ms linear`;
    bar.style.transform = 'scaleX(1)';
    requestAnimationFrame(()=> { bar.style.transform = 'scaleX(0)'; });
    timer = setTimeout(close, ms);
    el.addEventListener('mouseenter', pause);
    el.addEventListener('mouseleave', resume);
  }
  closeBtn.addEventListener('click', close);

  if (acts && actions.length){
    actions.forEach(a=>{
      const b = document.createElement('button');
      b.className = 'btn';
      b.textContent = a.label || 'Acción';
      b.addEventListener('click', ()=> a.onClick && a.onClick({ close }));
      acts.appendChild(b);
    });
  }

  return { el, close };
}


export async function GET_SOFT(url){
  try{
    return await GET(url);
  }catch(e){
    if (e?.status === 412 && e?.payload?.error === 'pos_cut_missing'){
      // No disparar error; regresamos un objeto suave
      return { ok:false, soft:true, error:'pos_cut_missing', payload:e.payload };
    }
    throw e;
  }
}


// Intenta varias URLs en orden hasta que una responda ok o no sea 404
// === Fallback genérico por lista de URLs ===
export async function requestWithFallback(method, urls, payload = null) {
  if (!Array.isArray(urls)) urls = [urls];
  let last = null;

  for (const url of urls) {
    try {
      const opts = { method };
      if (method === 'POST') {
        const body = payload instanceof FormData ? payload : new URLSearchParams(payload || {});
        opts.body = body;
      }
      const res = await fetch(url, opts);
      const ct  = res.headers.get('Content-Type') || '';
      const isJSON = ct.includes('application/json');
      const data = isJSON ? await res.json() : await res.text();

      if (res.status === 404) { // Corregido de = a ===
        last = { status: 404, ct, text: isJSON ? JSON.stringify(data) : data };
        continue;
      }
      if (res.ok && (data?.ok !== false)) return data;

      last = { status: res.status, ct, text: isJSON ? JSON.stringify(data) : data };
    } catch (e) {
      last = e;
    }
  }
  throw last || new Error('Todas las URLs fallaron');
}

export const GET_FALLBACK  = (urls)               => requestWithFallback('GET',  urls);
export const POST_FALLBACK = (urls, payload={})   => requestWithFallback('POST', urls, payload);