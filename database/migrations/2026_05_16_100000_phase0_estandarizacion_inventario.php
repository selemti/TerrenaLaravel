<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::unprepared("
            -- =======================================================================
            -- TAREA 1: Ampliar cat_tipo_mov_inv (fuente única de verdad de tipos de movimiento)
            -- =======================================================================
            
            -- Crear la tabla si no existe (por si se corre en entorno limpio)
            CREATE TABLE IF NOT EXISTS selemti.cat_tipo_mov_inv (
                id BIGSERIAL PRIMARY KEY,
                clave VARCHAR(100) UNIQUE NOT NULL,
                descripcion TEXT
            );

            -- Agregar columnas (PG 9.5 seguro)
            DO $$ BEGIN
              BEGIN ALTER TABLE selemti.cat_tipo_mov_inv ADD COLUMN signo SMALLINT NOT NULL DEFAULT 0; EXCEPTION WHEN duplicate_column THEN NULL; END;
              BEGIN ALTER TABLE selemti.cat_tipo_mov_inv ADD COLUMN afecta_costo BOOLEAN NOT NULL DEFAULT true; EXCEPTION WHEN duplicate_column THEN NULL; END;
              BEGIN ALTER TABLE selemti.cat_tipo_mov_inv ADD COLUMN activo BOOLEAN NOT NULL DEFAULT true; EXCEPTION WHEN duplicate_column THEN NULL; END;
            END $$;

            -- Poblar vocabulario canónico (UPSERT - Idempotente)
            INSERT INTO selemti.cat_tipo_mov_inv (clave, descripcion, signo, afecta_costo, activo)
            VALUES
              ('RECEPCION_COMPRA',   'Entrada por recepción de orden de compra',                  1,  true,  true),
              ('PRODUCCION_ENTRADA', 'Entrada de subreceta o producto elaborado a inventario',    1,  true,  true),
              ('TRASPASO_ENTRADA',   'Entrada de mercancía por traspaso entre almacenes',         1,  false, true),
              ('AJUSTE_ENTRADA',     'Ajuste positivo por conteo físico o corrección',            1,  true,  true),
              ('APERTURA',           'Carga inicial de inventario al arranque del sistema',       1,  true,  true),
              ('PRODUCCION_SALIDA',  'Salida de materia prima para producción interna',           -1, true,  true),
              ('VENTA_POS',          'Salida de inventario por venta en punto de venta',         -1, true,  true),
              ('TRASPASO_SALIDA',    'Salida de mercancía por traspaso entre almacenes',         -1, false, true),
              ('AJUSTE_SALIDA',      'Ajuste negativo por conteo físico o corrección',           -1, true,  true),
              ('MERMA',              'Pérdida por caducidad, daño o merma operativa',            -1, true,  true),
              ('CONSUMO_OPERATIVO',  'Consumo no vendible: limpieza, empaque, capacitación',     -1, true,  true)
            ON CONFLICT (clave) DO UPDATE SET
              descripcion   = EXCLUDED.descripcion,
              signo         = EXCLUDED.signo,
              afecta_costo  = EXCLUDED.afecta_costo,
              activo        = EXCLUDED.activo;

            -- Marcar como inactivas las claves legacy
            UPDATE selemti.cat_tipo_mov_inv
            SET activo = false
            WHERE clave IN ('VENTA_POS', 'AJUSTE_REPROCESO_POS', 'AJUSTE_REVERSO',
                            'APERTURA_INVENTARIO', 'AJUSTE_RECETA_ERRONEA',
                            'AJUSTE_COSTO_BATCH', 'CONSUMO_OPERATIVO',
                            'PRODUCCION_SALIDA_CRUDO', 'PRODUCCION_ENTRADA_ELABORADO')
              AND clave NOT IN (SELECT clave FROM selemti.cat_tipo_mov_inv WHERE signo != 0);

            -- =======================================================================
            -- TAREA 2 y 3: Crear / verificar tablas de recipes y sub_recipe_id
            -- =======================================================================
            CREATE TABLE IF NOT EXISTS selemti.recipes (
                id              BIGSERIAL PRIMARY KEY,
                codigo          VARCHAR(60)  NOT NULL UNIQUE,
                nombre          VARCHAR(200) NOT NULL,
                descripcion     TEXT,
                porciones       NUMERIC(10,3) NOT NULL DEFAULT 1,
                tiempo_preparacion INTEGER,
                activo          BOOLEAN NOT NULL DEFAULT true,
                created_by_user_id INTEGER,
                created_at      TIMESTAMPTZ DEFAULT now(),
                updated_at      TIMESTAMPTZ DEFAULT now()
            );

            CREATE TABLE IF NOT EXISTS selemti.recipe_versions (
                id          BIGSERIAL PRIMARY KEY,
                recipe_id   BIGINT NOT NULL REFERENCES selemti.recipes(id) ON DELETE CASCADE,
                version_no  INTEGER NOT NULL DEFAULT 1,
                notes       TEXT,
                valid_from  DATE,
                valid_to    DATE,
                created_at  TIMESTAMPTZ DEFAULT now(),
                UNIQUE (recipe_id, version_no)
            );

            CREATE TABLE IF NOT EXISTS selemti.recipe_version_items (
                id                  BIGSERIAL PRIMARY KEY,
                recipe_version_id   BIGINT NOT NULL REFERENCES selemti.recipe_versions(id) ON DELETE CASCADE,
                item_id             BIGINT,
                sub_recipe_id       BIGINT REFERENCES selemti.recipes(id),
                qty                 NUMERIC(18,6) NOT NULL,
                uom_receta          VARCHAR(20)   NOT NULL,
                orden               INTEGER DEFAULT 0,
                CONSTRAINT chk_rvi_item_xor_recipe CHECK (
                    (item_id IS NOT NULL AND sub_recipe_id IS NULL) OR
                    (item_id IS NULL AND sub_recipe_id IS NOT NULL)
                )
            );

            CREATE INDEX IF NOT EXISTS idx_recipe_versions_recipe_id ON selemti.recipe_versions(recipe_id);
            CREATE INDEX IF NOT EXISTS idx_recipe_version_items_version_id ON selemti.recipe_version_items(recipe_version_id);

            -- Asegurar sub_recipe_id si la tabla recipe_version_items ya existía
            DO $$ BEGIN
              BEGIN
                ALTER TABLE selemti.recipe_version_items ADD COLUMN sub_recipe_id BIGINT REFERENCES selemti.recipes(id);
              EXCEPTION WHEN duplicate_column THEN NULL;
              END;
              BEGIN
                ALTER TABLE selemti.recipe_version_items ADD CONSTRAINT chk_rvi_item_xor_recipe
                  CHECK ((item_id IS NOT NULL AND sub_recipe_id IS NULL) OR (item_id IS NULL AND sub_recipe_id IS NOT NULL));
              EXCEPTION WHEN duplicate_object THEN NULL;
              END;
            END $$;
        ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Esta migración es en gran parte forward-only para asegurar la estructura
        // No borramos tablas para no perder datos, solo revertimos algunos constraints y columnas
        DB::unprepared("
            DO $$ BEGIN
              BEGIN
                ALTER TABLE selemti.recipe_version_items DROP CONSTRAINT chk_rvi_item_xor_recipe;
              EXCEPTION WHEN undefined_object THEN NULL;
              END;
              
              BEGIN
                ALTER TABLE selemti.recipe_version_items DROP COLUMN sub_recipe_id;
              EXCEPTION WHEN undefined_column THEN NULL;
              END;
              
              BEGIN
                ALTER TABLE selemti.cat_tipo_mov_inv DROP COLUMN signo;
                ALTER TABLE selemti.cat_tipo_mov_inv DROP COLUMN afecta_costo;
                ALTER TABLE selemti.cat_tipo_mov_inv DROP COLUMN activo;
              EXCEPTION WHEN undefined_column THEN NULL;
              END;
            END $$;
        ");
    }
};
