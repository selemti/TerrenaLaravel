(() => {
  const LSKEY = 'recetas.cfg.v1';
  const def = {
    margen_objetivo_pct: 65,
    round_rule: 1.00,
    round_mode: 'UP', // UP | NEAREST | DOWN
    iva_pct: 0,       // por ahora 0
  };
  const saved = JSON.parse(localStorage.getItem(LSKEY) || 'null');
  const cfg = Object.assign({}, def, saved || {});
  function save() { localStorage.setItem(LSKEY, JSON.stringify(cfg)); }
  window.__RECETAS_CFG__ = { cfg, save };
})();
