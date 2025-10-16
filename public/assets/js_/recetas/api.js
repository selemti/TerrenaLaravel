(() => {
  const API = window.__API_BASE + '/recetas';

  async function ping() { return GET(`${API}/`); }
  async function health() { return GET(`${API}/health`); }

  // Catálogos
  async function searchMenuItems(q='', group_id=null, active=1, limit=20) {
    const u = new URL(`${API}/menu-items`, location.origin);
    if (q) u.searchParams.set('q', q);
    if (group_id) u.searchParams.set('group_id', group_id);
    if (active != null) u.searchParams.set('active', active);
    if (limit) u.searchParams.set('limit', limit);
    return GET(u.toString());
  }
  async function getMenuItem(id){ return GET(`${API}/menu-items/${id}`); }
  async function getMenuItemGroups(){ return GET(`${API}/menu-item-groups`); }
  async function getBOM(id){ return GET(`${API}/menu-items/${id}/bom`); }

  // Modificadores
  async function getModGroups(menu_item_id){ 
    const u = new URL(`${API}/modificadores/grupos`, location.origin);
    u.searchParams.set('menu_item_id', menu_item_id);
    return GET(u.toString());
  }
  async function getModGroupItems(grupo_id){
    return GET(`${API}/modificadores/grupo/${grupo_id}/items`);
  }

  // Costos
  async function getCostosMenuItem(id){ return GET(`${API}/costos/menu-item/${id}`); }
  async function simularCosto(id, mods = []) {
    const u = new URL(`${API}/costos/menu-item/${id}/simular`, location.origin);
    if (mods.length) {
      // mods como "id:qty,id:qty"
      u.searchParams.set('mods', mods.map(m => `${m.id}:${m.qty||1}`).join(','));
    }
    return GET(u.toString());
  }
  async function precioSugerido(id, {margen, round, mode}) {
    const u = new URL(`${API}/costos/menu-item/${id}/precio-sugerido`, location.origin);
    if (margen!=null) u.searchParams.set('margen', margen);
    if (round!=null)  u.searchParams.set('round', round);
    if (mode)         u.searchParams.set('mode', mode);
    return GET(u.toString());
  }

  // Unidades / Conversiones (CRUD)
  async function getUnidades(){ return GET(`${API}/unidades`); }
  async function getConversiones(params = {}) {
    const u = new URL(`${API}/conversiones`, location.origin);
    Object.entries(params).forEach(([k,v]) => v!=null && u.searchParams.set(k,v));
    return GET(u.toString());
  }
  async function postConversion(body){ return POST_FORM(`${API}/conversiones`, body); }
  async function putConversion(id, body){ return POST_FORM(`${API}/conversiones/${id}?_method=PUT`, body); }
  async function delConversion(id){ return POST_FORM(`${API}/conversiones/${id}?_method=DELETE`, {}); }

  // Costos de insumo (WAC)
  async function getCostItems(params = {}) {
    const u = new URL(`${API}/costos/items`, location.origin);
    Object.entries(params).forEach(([k,v]) => v!=null && u.searchParams.set(k,v));
    return GET(u.toString());
  }
  async function getCostItem(id){ return GET(`${API}/costos/items/${id}`); }
  async function postCostItem(id, body){ return POST_FORM(`${API}/costos/items/${id}`, body); }

  window.__RECETAS_API__ = {
    ping, health,
    searchMenuItems, getMenuItem, getMenuItemGroups, getBOM,
    getModGroups, getModGroupItems,
    getCostosMenuItem, simularCosto, precioSugerido,
    getUnidades, getConversiones, postConversion, putConversion, delConversion,
    getCostItems, getCostItem, postCostItem
  };
})();
