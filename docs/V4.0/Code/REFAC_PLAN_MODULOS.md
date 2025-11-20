# Plan de Refactor BD ↔ Código por Módulos

Estados posibles:
- PENDING      → Aún no se ha trabajado el módulo.
- IN_PROGRESS  → Ejecución en curso (normalmente solo momentáneo).
- DONE         → Refactor inicial completado (ya existe REFAC_<MODULO>_RESULTADOS.md).
- SKIP         → Decidido no tocar por ahora.

| Modulo      | Estado    | Prioridad | Descripcion breve                                           | Tablas_clave                                             | Rutas_codigo_sugeridas                                        | Notas_iniciales                                     |
|-------------|-----------|-----------|-------------------------------------------------------------|----------------------------------------------------------|----------------------------------------------------------------|-----------------------------------------------------|
| Inventario  | DONE      | P0        | Movimientos de inventario, recepciones, stock policy, etc. | selemti.mov_inv, selemti.recepcion_det, selemti.stock_policy | app/Services/Inventory, app/Models/Inventory, app/Http/... | Ya refactorado con Codex. Ver REFAC_INVENTARIO_RESULTADOS.md |
| Recetas     | DONE      | P0        | Recetas, versiones, insumos, mapeo POS ↔ recetas.          | selemti.receta, selemti.receta_version, selemti.receta_insumo, selemti.pos_map | app/Services/Recipes, app/Models/Recipes, app/Http/... | Ya refactorado. Ver REFAC_RECETAS_RESULTADOS.md     |
| Produccion  | DONE      | P0        | Órdenes de producción, consumo de recetas, mermas.         | selemti.op_produccion_cab, selemti.production_orders, selemti.merma     | app/Services/Production, app/Models/Rec/OrdenProduccion, app/Models/ProductionOrder, app/Http/Controllers/Production  | Refactor inicial completado el 2025-11-17. Ver REFAC_Produccion_RESULTADOS.md. Alineación excelente (0 MISMATCH, 0 FANTASMA). |
| Purchasing  | DONE      | P0        | Solicitudes de compra, órdenes, motor de replenishment.    | selemti.po_cab, selemti.po_det, selemti.stock_policy     | app/Services/Purchasing, app/Models/Purchasing, app/Http/...  | Refactor inicial completado el 2025-11-17. Ver REFAC_Purchasing_RESULTADOS.md. Alineación excelente (0 MISMATCH, 0 FANTASMA). |
| POS         | DONE      | P0        | Integración tickets/ventas desde public.*, consumo POS.    | public.ticket, public.ticket_item, public.menu_item, public.transactions, public.terminal | app/Services/Operations/Pos*, app/Models/Pos*, reports POS    | Refactor inicial y auditoría CLAUDE completada. Ver REFAC_POS_RESULTADOS.md y REFAC_POS_AUDE.md. |
| Caja        | DONE      | P1        | Sesiones de cajón, movimientos de caja chica.              | selemti.cash_funds, selemti.cash_fund_movements, selemti.sesion_cajon | app/Services/Cash*, app/Models/Cash*, app/Http/...             | Refactor inicial completado el 2025-11-17. Ver REFAC_Caja_RESULTADOS.md. No se encontraron MISMATCH/FANTASMA CONFIABLE; 2 ERROR_MAPA detectados. |
| Finanzas    | DONE      | P1        | Cortes, conciliaciones, cierre diario.                     | selemti.cortes_diarios, selemti.conciliaciones*          | app/Services/Finance*, app/Models/Finance*, app/Http/...      | Refactor inicial completado el 2025-11-17. Ver REFAC_Finanzas_RESULTADOS.md. No se encontraron MISMATCH/FANTASMA CONFIABLE; 2 ERROR_MAPA detectados. |
| Reports     | DONE      | P1        | Reportes y KPIs multitabla.                                | vistas en selemti.*, vistas en public.vw_*               | app/Services/Reports, app/Http/Controllers/Reports           | Refactor inicial completado el 2025-11-17. Ver REFAC_Reports_RESULTADOS.md. No se encontraron MISMATCH/FANTASMA CONFIABLE. |
| Seguridad   | DONE      | P2        | Roles, permisos (Spatie), policies.                        | selemti.roles, selemti.permissions, selemti.model_has_*  | app/Models/User, app/Models/Role, app/Policies, app/Http/... | Refactor inicial completado el 2025-11-17. Ver REFAC_Seguridad_RESULTADOS.md. No se encontraron MISMATCH/FANTASMA CONFIABLE; 29 ERROR_MAPA detectados. |
| Catalogos   | DONE      | P2        | Unidades, proveedores, sucursales, almacenes, familias.    | selemti.items, selemti.proveedores, selemti.sucursales, selemti.almacenes | app/Models/Catalogs, app/Services/Catalogs, app/Http/...     | Refactor inicial completado el 2025-11-17. Ver REFAC_Catalogos_RESULTADOS.md. No se encontraron MISMATCH/FANTASMA CONFIABLE; 4 ERROR_MAPA detectados. |



👉 Tú puedes ajustar:

Nombres reales de tablas clave.

Rutas de código más precisas, según como tengas organizado app/.

Prioridades.

La idea es que este archivo sea:

Tu checklist global

El input estructurado que Codex leerá para saber:

qué módulo sigue,

qué tablas mirar,

qué carpetas revisar primero.