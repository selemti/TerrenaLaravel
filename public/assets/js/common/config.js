// assets/js/common/helpers.js
// Utilidades de fetch y UI SIN depender de config.js

export const $ = (sel, root = document) => root.querySelector(sel);
export const esc = (s) => String(s ?? '')
  .replaceAll('&', '&amp;').replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#39;');

// Toasthttp sencillo (puedes mapearlo a tu toast real si ya existe)
export function toast(msg, type = 'info', ms = 4000, title = '') {
  try {
    if (window?.terrenaToast) return window.terrenaToast(msg, type, ms, title);
  } catch {}
  console[(type === 'err' || type === 'error') ? 'error' : 'log'](`[${title||type}] ${msg}`);
}

// Fetch helpers
async function doFetch(url, opts = {}) {
  const res = await fetch(url, {
    credentials: 'same-origin',
    ...opts,
    headers: { ...(opts.headers || {}) }
  });

  const ct = res.headers.get('Content-Type') || '';
  const out = {
    status: res.status,
    ok: res.ok,
    ct,
    len: Number(res.headers.get('Content-Length') || 0),
    payload: null,
    text: ''
  };

  if (ct.includes('application/json')) {
    try { out.payload = await res.json(); } catch { out.payload = null; }
  } else {
    try { out.text = await res.text(); } catch { out.text = ''; }
  }

  // Normalizamos respuesta: si venía JSON con {ok:..., ...} lo devolvemos directo
  if (out.payload && typeof out.payload === 'object') {
    return { ...out.payload, __meta: out };
  }
  // Si no venía JSON, devolvemos un contenedor mínimo
  return { ok: res.ok, status: res.status, text: out.text, __meta: out };
}

export async function GET(url) {
  return doFetch(url, { method: 'GET' }).then(r => {
    if (r?.ok) return r;
    const err = new Error(`GET ${url} → ${r?.status ?? 'error'}.`);
    err.status = r?.status; err.payload = r;
    throw err;
  });
}

// GET que no truena: devuelve null/undefined si falla
export async function GET_SOFT(url) {
  try { return await doFetch(url, { method: 'GET' }); }
  catch { return null; }
}

// POST formulario (FormData). Si data es objeto plano, se mapea a FormData.
export async function POST_FORM(url, data = {}) {
  let body;
  if (data instanceof FormData) {
    body = data;
  } else {
    body = new FormData();
    Object.entries(data).forEach(([k, v]) => body.append(k, v == null ? '' : v));
  }
  const r = await doFetch(url, { method: 'POST', body });
  if (!r?.ok) {
    const err = new Error(`POST ${url} → ${r?.status ?? 'error'}.`);
    err.status = r?.status; err.payload = r;
    throw err;
  }
  return r;
}

// Intenta primary; si 404 u otro error “duro”, intenta secondary
export async function GET_FALLBACK(primaryUrl, secondaryUrl) {
  try {
    const r = await GET(primaryUrl);
    if (r?.ok) return r;
    throw Object.assign(new Error('falló primary'), { status: r?.status });
  } catch (e) {
    if (!secondaryUrl) throw e;
    return GET(secondaryUrl); // si esto falla, que truene
  }
}
