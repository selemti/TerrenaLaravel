(() => {
  const API   = window.__RECETAS_API__;
  const CFG   = window.__RECETAS_CFG__?.cfg || {};
  const state = window.__RECETAS_STATE__;
  const { qs, renderOptions } = window.__UI_COMMON__;
  const { renderBOM, renderKPI } = window.__UI_COSTOS__;

  async function init() {
    // Elementos
    const selGrupo = qs('#filtroGrupo');
    const inputBusc = qs('#buscadorMenuItem');
    const listResultados = qs('#resultadosBusqueda');
    const tbodyBOM = qs('#tbodyBOM');
    const kpiBox   = qs('#kpiCostos');

    // Cargar grupos p/ filtro
    try {
      const g = await API.getMenuItemGroups();
      state.catalog.groups = g?.rows || g?.data || g || [];
      renderOptions(selGrupo, state.catalog.groups, { label:'nombre' });
    } catch(e){ toast('No se pudieron cargar grupos','err'); }

    // Buscador básico
    let t;
    inputBusc?.addEventListener('input', async (e)=>{
      clearTimeout(t);
      const q = e.target.value.trim();
      t = setTimeout(async ()=>{
        try{
          const group_id = selGrupo?.value || null;
          const r = await API.searchMenuItems(q, group_id||null, 1, 20);
          const rows = r?.rows || r?.data || [];
          listResultados.innerHTML = rows.map(x =>
            `<button class="list-group-item list-group-item-action" data-id="${x.id}">${x.nombre || x.name}</button>`
          ).join('');
        }catch(err){
          toast('Error buscando platillos','err');
        }
      }, 250);
    });

    // Click en un resultado → carga detalle
    listResultados?.addEventListener('click', async (e)=>{
      const btn = e.target.closest('button[data-id]');
      if (!btn) return;
      const id = +btn.dataset.id;
      await cargarItem(id);
      inputBusc.blur();
    });

    async function cargarItem(id){
      try{
        const [det, bom, mods, costos] = await Promise.all([
          API.getMenuItem(id),
          API.getBOM(id),
          API.getModGroups(id),
          API.getCostosMenuItem(id)
        ]);
        state.selectedItem = det?.data || det || { id };
        state.bom = bom?.rows || bom?.data || [];
        state.mods = {
          obligatorios: (mods?.obligatorios || []),
          opcionales:   (mods?.opcionales   || []),
        };

        // Pinta BOM
        renderBOM(tbodyBOM, state.bom);

        // Simulación inicial (solo obligatorios)
        const modsInicial = [
          ...state.mods.obligatorios.map(m => ({ id: m.id, qty: m.qty_default || 1 }))
        ];
        const sim = await API.simularCosto(id, modsInicial);
        const costoBase = costos?.costo_base ?? sim?.costo_base ?? 0;
        const costoMods = sim?.costo_mods ?? 0;
        const costoTotal= sim?.costo_total ?? (costoBase + costoMods);

        // Precio sugerido
        const pr = await API.precioSugerido(id, {
          margen: CFG.margen_objetivo_pct,
          round:  CFG.round_rule,
          mode:   CFG.round_mode
        });

        state.sim = {
          modsSeleccionados: modsInicial,
          costoBase, costoMods, costoTotal,
          precioSugerido: pr?.precio ?? 0,
          margenObjetivo: CFG.margen_objetivo_pct
        };
        renderKPI(kpiBox, state.sim);
        toast('Platillo cargado', 'ok');

      }catch(err){
        console.error(err);
        toast('No se pudo cargar el platillo','err');
      }
    }
  }

  document.addEventListener('DOMContentLoaded', init);
})();
