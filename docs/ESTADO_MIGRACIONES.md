# Reporte de Estado de Migraciones de Laravel

## Fecha de Verificación
29 de noviembre de 2025

## Resumen General
- **Migraciones aplicadas:** 15
- **Migraciones pendientes:** 78
- **Total de migraciones:** 93

## Migraciones YA APLICADAS (15 migraciones)
Estas migraciones ya han sido ejecutadas (Estado: "Ran"):

1. `0001_01_01_000000_create_users_table` - [Batch 1]
2. `0001_01_01_000001_create_cache_table` - [Batch 1]
3. `0001_01_01_000002_create_jobs_table` - [Batch 1]
4. `2025_01_12_000000_add_preferente_to_selemti_item_vendor` - [Batch 1]
5. `2025_01_23_100000_create_cash_funds_table` - [Batch 1]
6. `2025_01_23_100001_create_cash_fund_movements_table` - [Batch 1]
7. `2025_01_23_100002_create_cash_fund_arqueos_table` - [Batch 1]
8. `2025_01_23_110000_create_cash_fund_movement_audit_log_table` - [Batch 1]
9. `2025_09_26_090415_create_cat_unidades_table` - [Batch 1]
10. `2025_09_26_090657_create_cat_unidades_table` - [Batch 1]
11. `2025_09_26_205955_create_permission_tables` - [Batch 1]
12. `2025_10_18_000001_create_cat_sucursales_table` - [Batch 1]
13. `2025_10_18_000002_create_cat_almacenes_table` - [Batch 1]
14. `2025_10_18_000003_create_cat_proveedores_table` - [Batch 1]
15. `2025_10_18_000004_create_cat_uom_conversion_table` - [Batch 1]

## Migraciones PENDIENTES por aplicar (78 migraciones)

### Migraciones relacionadas con inventario (octubre-noviembre 2025)
- `2025_10_18_000005_create_inv_stock_policy_table`
- `2025_10_21_100100_alter_cat_proveedores_add_fields`
- `2025_10_21_100200_alter_item_vendor_add_vendor_sku`
- `2025_10_21_123344_add_preferente_to_selemti_item_vendor`
- `2025_10_21_180000_create_item_categories`
- `2025_10_21_180100_backfill_item_categories`
- `2025_10_21_180200_ensure_items_id_autoincrement`
- `2025_10_21_190100_alter_items_add_item_code`
- `2025_10_21_190200_item_code_trigger_and_counter`
- `2025_10_21_190300_backfill_item_codes`
- `2025_10_21_200000_create_item_vendor_prices`
- `2025_10_21_200100_fn_item_cost_at`
- `2025_10_21_200200_recipe_versioning_and_history`
- `2025_10_21_200300_fn_recipe_cost_at`
- `2025_10_21_200400_sp_snapshot_recipe_cost`
- `2025_10_21_200500_alert_rules_and_events`
- `2025_10_21_200500_create_item_last_price_views`
- `2025_10_21_200600_trg_on_price_change_alerts`

### Migraciones relacionadas con recepción y órdenes de compra
- `2025_10_23_154901_add_descripcion_to_cash_funds_table`
- `2025_10_24_000000_add_almacen_id_to_recepcion_cab`
- `2025_10_24_014612_add_numero_recepcion_to_recepcion_cab_table`
- `2025_10_24_015559_add_fecha_recepcion_to_recepcion_cab_table`
- `2025_10_24_020818_add_missing_inventory_fields_to_recepcion_cab_table`
- `2025_10_24_100000_create_replenishment_suggestions_table`
- `2025_10_24_120000_create_purchase_suggestions_table`
- `2025_10_24_120101_create_purchase_suggestion_lines_table`
- `2025_10_24_120102_alter_purchase_requests_add_fields`

### Migraciones de funcionalidades avanzadas (POS, consumos, etc.)
- `2025_10_26_000002_add_operational_flags_to_items`
- `2025_10_26_000004_add_unit_cost_to_inventory_batch`
- `2025_10_26_000005_create_pos_map_table`
- `2025_10_26_000006_create_ticket_item_modifiers_table`
- `2025_10_27_100239_create_pos_reverse_log_table`
- `2025_10_27_100252_create_pos_reprocess_log_table`
- `2025_10_27_110252_add_flags_to_inv_consumo_pos_and_det`
- `2025_10_27_153528_create_personal_access_tokens_table`

### Actualizaciones y mejoras en el sistema
- `2025_10_28_000001_update_inv_consumo_flags`
- `2025_10_28_000002_drop_public_ticket_trigger`
- `2025_10_28_000003_add_display_fields_to_roles_table`
- `2025_10_28_000010_create_audit_log_table`
- `2025_10_28_200000_add_indexes_to_audit_log_table`
- `2025_10_28_200001_add_foreign_key_to_audit_log_table`
- `2025_10_30_000000_add_remember_token_to_selemti_users`
- `2025_10_30_120000_add_code_columns_to_insumo`

### Módulo de recetas y costos
- `2025_11_01_090000_create_recipe_cost_snapshots_table`
- `2025_11_03_194200_fix_items_inconsistencies`
- `2025_11_03_194300_fix_item_id_data_types`
- `2025_11_03_194400_fix_all_item_id_types`
- `2025_11_03_202400_clean_item_descriptions`

### Módulos completos pendientes
- `2025_11_15_000000_create_inventory_receiving_tables`
- `2025_11_15_010000_create_inventory_counts_tables`
- `2025_11_15_020000_create_production_tables`
- `2025_11_15_030000_create_pos_consumption_tables`
- `2025_11_15_050000_create_purchasing_tables`
- `2025_11_15_060000_create_costing_extension_tables`
- `2025_11_15_070000_create_pos_sync_tables`
- `2025_11_15_080000_create_menu_engineering_tables`
- `2025_11_15_090000_extend_alert_tables`
- `2025_11_15_100000_create_reporting_tables`

### Migraciones recientes (noviembre-diciembre 2025)
- `2025_11_23_160000_add_state_machine_columns_to_recepcion_cab`
- `2025_11_23_161500_add_state_machine_columns_to_traspaso_cab`
- `2025_12_01_120000_create_report_favorites_table`

## Migraciones Relacionadas con Performance de Reportes
Las siguientes migraciones están relacionadas con el desempeño de los reportes de excepciones:

- `2025_10_26_000005_create_pos_map_table` - Posiblemente para mejoras de rendimiento en mapeo de POS
- `2025_10_26_000006_create_ticket_item_modifiers_table` - Tabla relacionada con tickets para rendimiento
- `2025_10_28_000002_drop_public_ticket_trigger` - Elimina trigger para mejorar el rendimiento de tickets

## Recomendación
**Ejecutar inmediatamente:** `php artisan migrate --force` para aplicar las 78 migraciones pendientes, especialmente las críticas para el funcionamiento completo del sistema.

## Nota Importante
Las migraciones pendientes incluyen funcionalidades completas como:
- Módulo de recepción de inventarios
- Módulo de producción
- Módulo de consumo POS
- Módulo de compras
- Reportes avanzados
- Sistema de alertas
- Y muchas mejoras y correcciones

✅ El estado actual muestra que aunque hay migraciones básicas aplicadas, gran parte del sistema aún necesita ser desplegado mediante las migraciones pendientes.