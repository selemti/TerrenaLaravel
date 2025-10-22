# V2 Notes

## Costos e inventario

- El costo unitario "a fecha" debe consultarse mediante la función `selemti.fn_item_unit_cost_at`, que considera el histórico de precios y conversiones de unidad.
- La interfaz de `/inventory/items` ahora obtiene el precio vigente del proveedor preferente a través de las vistas `selemti.vw_item_last_price` y `selemti.vw_item_last_price_pref`.
- Consulta `docs/V2/sql_bootstrap_costing.sql` para precargar prefijos de categorías y conversiones básicas de unidades de medida.
- API REST:
  - `POST /api/inventory/prices` registra precios históricos por proveedor (cierra la vigencia anterior vía trigger).
  - `GET /api/recipes/{id}/cost?at=YYYY-MM-DD` consulta el costo de porción en la fecha indicada usando `selemti.fn_recipe_cost_at`.
  - `GET /api/alerts?handled=0|1` y `POST /api/alerts/{id}/ack` permiten revisar y atender alertas generadas por variaciones de costo.
  - Todos los endpoints protegidos requieren sesión autenticada (`auth` web) y el rol `inventario.manager` para autorizar la acción.

## Captura de precio desde UI

- Desde `/inventory/items` se puede abrir el formulario **Cargar precio** que lista los ítems y proveedores preferentes. El componente Livewire `Inventory\ItemPriceCreate` valida contra catálogo de UOM y `item_vendor` antes de registrar el precio.
- Tras guardar, se dispara un toast de confirmación y el listado de ítems se refresca con la vigencia y el proveedor preferente.
- La vista Livewire `Inventory\AlertsList` disponible en `/inventory/alerts` muestra las alertas de costo pendientes/atendidas con filtros por fecha y receta, permitiendo marcarlas como atendidas.

> Capturas de referencia: ejecutar la app y visitar `/inventory/items` y `/inventory/alerts` para ver el modal de carga y la tabla de alertas.

## Referencias rápidas

- Especificación OpenAPI: `docs/V2/openapi.yml` documenta los endpoints de precios, costos de recetas y alertas.
- Colección Postman: `docs/V2/postman_inventory_costs.json` con ejemplos para registrar precios, consultar costos y revisar alertas.

### FAQs

- **¿Por qué el precio vigente no se muestra?** Verifica que exista un proveedor marcado como preferente (`selemti.item_vendor.preferente = true`) y que tenga precio vigente en `selemti.item_vendor_prices` (sin `effective_to`).
