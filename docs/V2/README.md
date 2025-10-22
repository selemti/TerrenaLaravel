# V2 Notes

## Costos e inventario

- El costo unitario "a fecha" debe consultarse mediante la función `selemti.fn_item_unit_cost_at`, que considera el histórico de precios y conversiones de unidad.
- La interfaz de `/inventory/items` ahora obtiene el precio vigente del proveedor preferente a través de las vistas `selemti.vw_item_last_price` y `selemti.vw_item_last_price_pref`.
- Consulta `docs/V2/sql_bootstrap_costing.sql` para precargar prefijos de categorías y conversiones básicas de unidades de medida.
- API REST:
  - `POST /api/inventory/prices` registra precios históricos por proveedor (cierra la vigencia anterior vía trigger).
  - `GET /api/recipes/{id}/cost?at=YYYY-MM-DD` consulta el costo de porción en la fecha indicada usando `selemti.fn_recipe_cost_at`.
  - `GET /api/alerts?handled=0|1` y `POST /api/alerts/{id}/ack` permiten revisar y atender alertas generadas por variaciones de costo.
