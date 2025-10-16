// assets/js/common/helpers.js
// OJO con la ruta de config: desde /common/ hacia /caja/
import { DEBUG } from '../caja/config.js';

export const $   = (s, r) => (r || document).querySelector(s);
export const esc = (x) => String(x ?? '').replace(/[&<>"']/g, m => ({
  '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;', "'":'&#39;'
}[m]));

function log(kind, url, payload){ try{ console.log(`[caja.js] ${kind} ${url}`, payload||''); }catch(_){} }
export function err(...args){ console.error('[caja.js]', ...args); }

const inflight = new Map();

/* ================= HTTP ================= */

export async function GET(url, { timeout = 15000, headers } = {}) {
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
      if (isJson && text) { try { payload = JSON.parse(text); } catch {} }

      if (!res.ok) {
        console.error('[caja.js] GET ERR', {
          status: res.status, ct, len: text.length,
          text: text.slice(0, 2000), payload
        });
        const err = new Error(`GET ${url} → ${res.status}.`);
        err.status  = res.status;
        err.payload = payload || { raw: text.slice(0, 2000) };
        throw err;
      }

      if (!isJson) {
        const err = new Error(`Respuesta no JSON (${ct || 'sin CT'})`);
        err.status  = res.status;
        err.payload = { raw: text.slice(0, 2000) };
        throw err;
      }

      log('GET OK', url, payload);
      return payload ?? { ok: true };
    } finally {
      clearTimeout(tmr);
      log('GET END', { status: res?.status, ok: res?.ok, ct, len: text?.length });
    }
  })().finally(() => inflight.delete(key));

  inflight.set(key, p);
  return p;
}

export async function POST_FORM(url, data){
  const key = `POST ${url} ${JSON.stringify(data||{})}`;
  if (window.__inflight?.has?.(key)) return window.__inflight.get(key);
  window.__inflight ||= new Map();

  const p = (async()=>{
    const body = new URLSearchParams();
    Object.entries(data||{}).forEach(([k,v])=> body.append(k, String(v ?? '')));

    log('POST', url, Object.fromEntries(body.entries()));

    const ctrl = new AbortController();
    const tmr  = setTimeout(()=> ctrl.abort('timeout'), 12000);

    let r, t, ct;
    try{
      r  = await fetch(url, {
        method:'POST',
        credentials:'same-origin',
        headers:{
          'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept':'application/json'
        },
        body,
        signal: ctrl.signal
      });

      t  = await r.text();
      ct = (r.headers.get('Content-Type')||'').toLowerCase();
      log('POST END', {status:r.status, ok:r.ok, ct, len:t.length});

      if (!r.ok){
        const e = new Error(`POST ${url} → ${r.status}.`);
        e.status = r.status;
        try { if (ct.includes('application/json')) e.payload = JSON.parse(t); } catch(_){}
        throw e;
      }
      if (!ct.includes('application/json')){
        const e = new Error(`Respuesta no JSON (${ct||'sin CT'})`);
        e.status = r.status;
        e.payload = { raw: t.slice(0,500) };
        throw e;
      }
      return JSON.parse(t);

    } finally {
      clearTimeout(tmr);
    }
  })().finally(()=> window.__inflight.delete(key));

  window.__inflight.set(key, p);
  return p;
}

/* ======= Fallback de rutas ======= */

export async function requestWithFallback(method, urls, payload=null){
  if (!Array.isArray(urls)) urls = [urls];
  let last = null;

  for (const url of urls){
    try{
      const opts = { method };
      if (method === 'POST'){
        const body = payload instanceof FormData ? payload : new URLSearchParams(payload||{});
        opts.body = body;
        opts.headers = { 'Accept':'application/json' };
      }
      const res = await fetch(url, opts);
      const ct  = res.headers.get('Content-Type') || '';
      const isJSON = ct.includes('application/json');
      const data = isJSON ? await res.json() : await res.text();

      if (res.status === 404) { last = {status:404, ct, text: isJSON?JSON.stringify(data):data}; continue; }
      if (res.ok && (data?.ok !== false)) return data;

      last = {status: res.status, ct, text: isJSON?JSON.stringify(data):data};
    }catch(e){ last = e; }
  }
  throw last || new Error('Todas las URLs fallaron');
}

// Exporta helpers de fallback como named exports
export const GET_FALLBACK  = (urls)               => requestWithFallback('GET',  urls);
export const POST_FALLBACK = (urls, payload={})   => requestWithFallback('POST', urls, payload);

/* =============== Fechas, toasts, etc… =============== */
/* (lo demás de tu archivo puede quedarse tal cual) */

