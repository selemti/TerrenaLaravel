// assets/js/caja/config.js
// Siempre legacy (.php). Incluye "legacy" para máxima compatibilidad.

// assets/js/caja/config.js
export const BASE  = (window.__BASE__ || '').replace(/\/+$/,'');   // ej: "/terrena"
//export const API   = `${BASE}/api`;                                // 👈 sin "/caja" fijo

export const api = {
 // Cajas
  cajasIndex: (qs = '') => `${BASE}/api/caja/cajas${qs ? `?${qs}` : ''}`,

  // Sesión / conciliación / formas de pago
  sesionActiva:                 `${BASE}/api/caja/sesiones/activa`,
  conciliacionBySesion: (id) => `${BASE}/api/caja/conciliacion/${id}`,
  formasPago:                   `${BASE}/api/caja/formas-pago`,

  // Precortes
  precortesCreate:                `${BASE}/api/caja/precortes`,                    // POST
  precortesPreflight:     (sid) => `${BASE}/api/caja/precortes/preflight/${sid ?? ''}`.replace(/\/$/, ''),
  precortesShow:          (id)  => `${BASE}/api/caja/precortes/${id}`,            // GET
  precortesUpdate:        (id)  => `${BASE}/api/caja/precortes/${id}`,            // POST (OJO: NO PUT)
  precortesEnviar:        (id)  => `${BASE}/api/caja/precortes/${id}/enviar`,     // POST
  precortesStatus:        (id)  => `${BASE}/api/caja/precortes/${id}/status`,     // GET
  precortesTotales:       (id)  => `${BASE}/api/caja/precortes/${id}/totales`,    // GET
  precortesTotalesSesion: (sid) => `${BASE}/api/caja/precortes/sesion/${sid}/totales`, // GET

  // Postcortes
  postcortesCreate:              `${BASE}/api/caja/postcortes`,                   // POST
  postcortesUpdate:        (id) => `${BASE}/api/caja/postcortes/${id}`,           // POST (OJO: NO PUT)
  postcortesShow:          (id) => `${BASE}/api/caja/postcortes/${id}`,           // GET
  postcortesDetalle:       (id) => `${BASE}/api/caja/postcortes/${id}/detalle`,   // GET

  // (Opcional) endpoints legacy de compatibilidad mientras migras
  legacyPreflight:         (sid) => `${BASE}/api/legacy/sprecorte/preflight/${sid ?? ''}`.replace(/\/$/, ''),
};

// Utilidades UI
export const DEBUG  = true;
export const DENOMS = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1, 0.5];
export const MXN    = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' });