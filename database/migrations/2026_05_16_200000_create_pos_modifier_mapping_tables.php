<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
            CREATE TABLE IF NOT EXISTS selemti.pos_menu_item_recipe_mapping (
                id                  BIGSERIAL PRIMARY KEY,
                menu_item_id        INTEGER NOT NULL,
                menu_item_name      VARCHAR(120),
                recipe_id           BIGINT REFERENCES selemti.recipes(id) ON DELETE SET NULL,
                porciones_por_orden INTEGER NOT NULL DEFAULT 1,
                activo              BOOLEAN NOT NULL DEFAULT TRUE,
                created_at          TIMESTAMP,
                updated_at          TIMESTAMP,
                CONSTRAINT uq_pos_menu_item_recipe UNIQUE (menu_item_id)
            );

            CREATE TABLE IF NOT EXISTS selemti.pos_modifier_inv_mapping (
                id                       BIGSERIAL PRIMARY KEY,
                menu_modifier_id         INTEGER NOT NULL,
                modifier_name_trim       VARCHAR(120) NOT NULL,
                menu_modifier_group_id   INTEGER,
                menu_modifier_group_name VARCHAR(120),
                item_id                  VARCHAR(36) REFERENCES selemti.items(id) ON DELETE SET NULL,
                qty_por_unidad           DECIMAL(10,6) NOT NULL DEFAULT 0,
                uom                      VARCHAR(20) NOT NULL DEFAULT 'KG',
                qty_source               VARCHAR(10) NOT NULL DEFAULT 'MANUAL'
                                             CHECK (qty_source IN ('MANUAL','RECIPE')),
                recipe_id                BIGINT REFERENCES selemti.recipes(id) ON DELETE SET NULL,
                tipo_efecto              VARCHAR(10) NOT NULL DEFAULT 'ADICIONAL'
                                             CHECK (tipo_efecto IN ('SELECTOR','ADICIONAL')),
                afecta_costo             BOOLEAN NOT NULL DEFAULT TRUE,
                activo                   BOOLEAN NOT NULL DEFAULT TRUE,
                created_at               TIMESTAMP,
                updated_at               TIMESTAMP,
                CONSTRAINT uq_pos_modifier UNIQUE (menu_modifier_id)
            );

            CREATE INDEX IF NOT EXISTS idx_pos_mod_name
                ON selemti.pos_modifier_inv_mapping (modifier_name_trim);
            CREATE INDEX IF NOT EXISTS idx_pos_mod_group
                ON selemti.pos_modifier_inv_mapping (menu_modifier_group_id);
            CREATE INDEX IF NOT EXISTS idx_pos_menuitem
                ON selemti.pos_menu_item_recipe_mapping (menu_item_id);

            CREATE TABLE IF NOT EXISTS selemti.pos_ticket_item_processed (
                ticket_item_id  INTEGER PRIMARY KEY,
                ticket_id       INTEGER NOT NULL,
                processed_at    TIMESTAMP NOT NULL DEFAULT NOW(),
                user_id         INTEGER
            );

            CREATE INDEX IF NOT EXISTS idx_pos_ticket_item_processed_ticket
                ON selemti.pos_ticket_item_processed (ticket_id);
        SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
            DROP TABLE IF EXISTS selemti.pos_ticket_item_processed;
            DROP TABLE IF EXISTS selemti.pos_modifier_inv_mapping;
            DROP TABLE IF EXISTS selemti.pos_menu_item_recipe_mapping;
        SQL);
    }
};
