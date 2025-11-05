-- ═══════════════════════════════════════════════════════════════════════════════════
-- SCRIPT PARA SINCRONIZAR MIGRACIONES - PARTE 1: REGISTRAR MIGRACIONES SEGURAS
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Este script registra migraciones cuyas tablas/cambios YA EXISTEN en la base de datos
-- Fecha: 2025-11-05
-- ───────────────────────────────────────────────────────────────────────────────────

-- Batch 10: Migraciones de octubre que ya están aplicadas
INSERT INTO migrations (migration, batch) VALUES
('2025_10_24_015559_add_fecha_recepcion_to_recepcion_cab_table', 10),
('2025_10_24_100000_create_replenishment_suggestions_table', 10),
('2025_10_24_120000_create_purchase_suggestions_table', 10),
('2025_10_24_120101_create_purchase_suggestion_lines_table', 10),
('2025_10_26_000004_add_unit_cost_to_inventory_batch', 10),
('2025_10_26_000005_create_pos_map_table', 10),
('2025_10_26_000006_create_ticket_item_modifiers_table', 10),
('2025_10_27_100239_create_pos_reverse_log_table', 10),
('2025_10_27_100252_create_pos_reprocess_log_table', 10),
('2025_10_27_153528_create_personal_access_tokens_table', 10),
('2025_10_28_000001_update_inv_consumo_flags', 10),
('2025_10_28_000002_drop_public_ticket_trigger', 10),
('2025_10_28_000010_create_audit_log_table', 10),
('2025_10_28_200000_add_indexes_to_audit_log_table', 10),
('2025_10_28_200001_add_foreign_key_to_audit_log_table', 10),
('2025_10_30_000000_add_remember_token_to_selemti_users', 10);

-- Verificar que se registraron correctamente
SELECT 'Migraciones registradas en batch 10:' as mensaje, COUNT(*) as total
FROM migrations
WHERE batch = 10;

SELECT migration FROM migrations WHERE batch = 10 ORDER BY migration;
