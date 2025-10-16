// assets/js/caja/config.js
export const BASE  = (window.__BASE__ || '').replace(/\/+$/,'');   // ej: "/terrena/ui"
export const API   = `${BASE}/api`;                                // /api

export const api = {
  // nuevo (Laravel endpoints)
  //cajas:            (qs='') => `${API}/cajas${qs ? `?${qs}` : ''}`,
  cajas:            (qs='') => `${API}/caja/cajas${qs ? `?${qs}` : ''}`,
	precorte_create:  ()      => `${API}/precortes`,
  precorte_update:  (id)    => `${API}/precortes/${encodeURIComponent(id)}`,
  precorte_totales: (id)    => `${API}/precortes/${encodeURIComponent(id)}/totales`,
  postcorte_create: ()      => `${API}/postcortes`,
  postcorte_update: (id)    => `${API}/postcortes/${encodeURIComponent(id)}`, // Usa para guardar/validar postcorte
  precorte_status:  (id)    => `${API}/precortes/${encodeURIComponent(id)}/status`,

  // legacy (mientras migras; comenta cuando todo sea Laravel)
  /*legacy: {
    cajas:            (qs='') => `${API}/caja/cajas.php${qs ? `?${qs}` : ''}`,
    precorte_create:  ()      => `${API}/caja/precorte_create.php`,
    precorte_update:  (id)    => `${API}/caja/precorte_update.php?id=${encodeURIComponent(id)}`,
    precorte_totales: (id)    => `${API}/caja/precorte_totales.php?id=${encodeURIComponent(id)}`,
    postcorte_update: (id)    => `${API}/caja/postcortes.php?id=${encodeURIComponent(id)}`,
  }*/
};

// Utilidades UI
export const DEBUG  = true;
export const DENOMS = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1, 0.5];
export const MXN    = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' });