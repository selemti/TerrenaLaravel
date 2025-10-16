(() => {
  const state = {
    selectedItem: null,     // {id, name, group_id, ...}
    bom: [],                // [{insumo_id, nombre, qty, um, costo_unitario, costo_linea, ...}, ...]
    mods: {                 // por grupo
      obligatorios: [],
      opcionales: []
    },
    sim: {                  // simulación
      modsSeleccionados: [], // [{mod_item_id, qty}]
      costoBase: 0,
      costoMods: 0,
      costoTotal: 0,
      precioSugerido: 0,
      margenObjetivo: 0
    },
    catalog: {
      groups: [], // menu_item_groups
    }
  };
  window.__RECETAS_STATE__ = state;
})();
