// Config y constantes globales
export const BASE  = (window.__BASE__ || '').replace(/\/+$/, ''); // ej: /terrena/terrena
export const API   = `${BASE}/api/`;
export const api   = {
  cajas:            (qs = '') => `${API}/cajas.php${qs ? `?${qs}` : ''}`,
  precorte_create:  ()       => `${API}/precorte_create.php`,
  precorte_update:  (id)     => `${API}/precorte_update.php?id=${encodeURIComponent(id)}`,
  precorte_totales: (id)     => `${API}/precorte_totales.php?id=${encodeURIComponent(id)}`
};

export const DEBUG  = true;
export const DENOMS = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1, 0.5];
export const MXN    = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' });
(() => {
  window.__CFG__ = window.__CFG__ || {};
  // Puedes meter aquí flags globales
})();