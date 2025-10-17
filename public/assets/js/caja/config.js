// assets/js/caja/config.js
// Siempre legacy (.php). Incluye "legacy" para máxima compatibilidad.

// assets/js/caja/config.js
export const BASE  = (window.__BASE__ || '').replace(/\/+$/,'');   // ej: "/terrena"
//export const API   = `${BASE}/api`;                                // 👈 sin "/caja" fijo

export const api = {
 // Cajas
  cajas: (qs = '') => `${BASE}/api/caja/cajas${qs ? `?${qs}` : ''}`,

  // Sesión / conciliación / formas de pago
  sesionActiva:                 `${BASE}/api/caja/sesiones/activa`,
  conciliacionBySesion: (id) => `${BASE}/api/caja/conciliacion/${id}`,
  formasPago:                   `${BASE}/api/caja/formas-pago`,

  // Precortes (camelCase)
  precortesCreate:                `${BASE}/api/caja/precortes`,                    // POST
  precortesPreflight:     (sid) => `${BASE}/api/caja/precortes/preflight/${sid ?? ''}`.replace(/\/$/, ''),
  precortesShow:          (id)  => `${BASE}/api/caja/precortes/${id}`,            // GET
  precortesUpdate:        (id)  => `${BASE}/api/caja/precortes/${id}`,            // POST (OJO: NO PUT)
  precortesEnviar:        (id)  => `${BASE}/api/caja/precortes/${id}/enviar`,     // POST
  precortesStatus:        (id)  => `${BASE}/api/caja/precortes/${id}/status`,     // GET
  precortesTotales:       (id)  => `${BASE}/api/caja/precortes/${id}/totales`,    // GET
  precortesTotalesSesion: (sid) => `${BASE}/api/caja/precortes/sesion/${sid}/totales`, // GET

  // Aliases con guion bajo para compatibilidad con wizard.js legacy
  precorte_create:  ()    => `${BASE}/api/caja/precortes`,
  precorte_update:  (id)  => `${BASE}/api/caja/precortes/${id}`,
  precorte_totales: (id)  => `${BASE}/api/caja/precortes/${id}/totales`,
  precorte_preflight: (sid) => `${BASE}/api/caja/precortes/preflight/${sid ?? ''}`.replace(/\/$/, ''),

  // Postcortes (camelCase)
  postcortesCreate:              `${BASE}/api/caja/postcortes`,                   // POST
  postcortesUpdate:        (id) => `${BASE}/api/caja/postcortes/${id}`,           // POST (OJO: NO PUT)
  postcortesShow:          (id) => `${BASE}/api/caja/postcortes/${id}`,           // GET
  postcortesDetalle:       (id) => `${BASE}/api/caja/postcortes/${id}/detalle`,   // GET

  // Aliases con guion bajo para postcortes
  postcorte_create: ()    => `${BASE}/api/caja/postcortes`,
  postcorte_update: (id)  => `${BASE}/api/caja/postcortes/${id}`,

  // (Opcional) endpoints legacy de compatibilidad mientras migras
  legacyPreflight:         (sid) => `${BASE}/api/legacy/sprecorte/preflight/${sid ?? ''}`.replace(/\/$/, ''),
};

// Utilidades UI
export const DEBUG  = true;
export const DENOMS = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1, 0.5];
export const MXN    = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' });