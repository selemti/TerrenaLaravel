# Gemini Task: Crear tablas pos_modifier_inv_mapping y pos_menu_item_recipe_mapping

## Contexto

Proyecto TerrenaLaravel. Stack: PostgreSQL 9.5, schema `selemti`.
**NUNCA tocar el schema `public`** — es FloreantPOS producción, solo lectura.
PG 9.5: usar `DO $$ BEGIN ALTER TABLE ... EXCEPTION WHEN duplicate_column THEN NULL; END $$` para ADD COLUMN idempotente.

## Tarea 1 — Migración Laravel

Crear archivo: `database/migrations/2026_05_16_200000_create_pos_modifier_mapping_tables.php`

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->unprepared("
            -- Tabla 1: mapeo menu_item POS → recipe selemti
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

            -- Tabla 2: mapeo modifier POS → item de inventario
            CREATE TABLE IF NOT EXISTS selemti.pos_modifier_inv_mapping (
                id                      BIGSERIAL PRIMARY KEY,
                menu_modifier_id        INTEGER NOT NULL,
                modifier_name_trim      VARCHAR(120) NOT NULL,
                menu_modifier_group_id  INTEGER,
                menu_modifier_group_name VARCHAR(120),
                item_id                 VARCHAR(36) REFERENCES selemti.items(id) ON DELETE SET NULL,
                qty_por_unidad          DECIMAL(10,6) NOT NULL DEFAULT 0,
                uom                     VARCHAR(20) NOT NULL DEFAULT 'KG',
                qty_source              VARCHAR(10) NOT NULL DEFAULT 'MANUAL'
                                        CHECK (qty_source IN ('MANUAL','RECIPE')),
                recipe_id               BIGINT REFERENCES selemti.recipes(id) ON DELETE SET NULL,
                tipo_efecto             VARCHAR(10) NOT NULL DEFAULT 'ADICIONAL'
                                        CHECK (tipo_efecto IN ('SELECTOR','ADICIONAL')),
                afecta_costo            BOOLEAN NOT NULL DEFAULT TRUE,
                activo                  BOOLEAN NOT NULL DEFAULT TRUE,
                created_at              TIMESTAMP,
                updated_at              TIMESTAMP,
                CONSTRAINT uq_pos_modifier UNIQUE (menu_modifier_id)
            );

            CREATE INDEX IF NOT EXISTS idx_pos_mod_name
                ON selemti.pos_modifier_inv_mapping (modifier_name_trim);
            CREATE INDEX IF NOT EXISTS idx_pos_mod_group
                ON selemti.pos_modifier_inv_mapping (menu_modifier_group_id);
            CREATE INDEX IF NOT EXISTS idx_pos_menuitem
                ON selemti.pos_menu_item_recipe_mapping (menu_item_id);
        ");
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared("
            DROP TABLE IF EXISTS selemti.pos_modifier_inv_mapping;
            DROP TABLE IF EXISTS selemti.pos_menu_item_recipe_mapping;
        ");
    }
};
```

## Tarea 2 — Verificación post-migración

Ejecutar y confirmar que estas queries retornan 0 errores:

```sql
-- Las tablas existen con todas las columnas
SELECT column_name FROM information_schema.columns
WHERE table_schema='selemti' AND table_name='pos_modifier_inv_mapping'
ORDER BY ordinal_position;

SELECT column_name FROM information_schema.columns
WHERE table_schema='selemti' AND table_name='pos_menu_item_recipe_mapping'
ORDER BY ordinal_position;

-- Los índices existen
SELECT indexname FROM pg_indexes
WHERE schemaname='selemti' AND tablename IN ('pos_modifier_inv_mapping','pos_menu_item_recipe_mapping');
```

## Tarea 3 — Registrar la migración en selemti.migrations

Si usas `php artisan migrate` directamente apunta al schema correcto. Verificar:
```sql
SELECT * FROM selemti.migrations WHERE migration LIKE '%pos_modifier%';
```

## Entregable esperado

Confirmación de que las 2 tablas existen en `selemti` con todas sus columnas e índices.
Resultado de las queries de verificación.
