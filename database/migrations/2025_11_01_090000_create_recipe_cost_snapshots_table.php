<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        $driver = DB::connection('pgsql')->getDriverName();

        if ($driver === 'pgsql') {
            DB::unprepared(<<<'SQL'
CREATE TABLE IF NOT EXISTS selemti.recipe_cost_snapshots (
    id BIGSERIAL PRIMARY KEY,
    recipe_id VARCHAR(50) NOT NULL,
    snapshot_date TIMESTAMP NOT NULL,
    cost_total DECIMAL(15,4) NOT NULL DEFAULT 0,
    cost_per_portion DECIMAL(15,4) NOT NULL DEFAULT 0,
    portions DECIMAL(10,3) NOT NULL DEFAULT 1,
    cost_breakdown JSONB NOT NULL DEFAULT '[]'::jsonb,
    reason VARCHAR(100) NOT NULL,
    created_by_user_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recipe_cost_snap_recipe
        FOREIGN KEY (recipe_id)
        REFERENCES selemti.receta_cab(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_recipe_cost_snap_user
        FOREIGN KEY (created_by_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_recipe_cost_snap_recipe_date
    ON selemti.recipe_cost_snapshots(recipe_id, snapshot_date DESC);

CREATE INDEX IF NOT EXISTS idx_recipe_cost_snap_date
    ON selemti.recipe_cost_snapshots(snapshot_date DESC);

COMMENT ON TABLE selemti.recipe_cost_snapshots IS
    'Snapshots historicos de costos de recetas para auditoria y performance';

COMMENT ON COLUMN selemti.recipe_cost_snapshots.cost_breakdown IS
    'JSONB array con detalle: [{"item_id": "...", "item_name": "...", "qty": 1.5, "uom": "KG", "unit_cost": 45.50, "total_cost": 68.25}]';

COMMENT ON COLUMN selemti.recipe_cost_snapshots.reason IS
    'MANUAL: Creado manualmente por usuario\n     AUTO_THRESHOLD: Creado automaticamente por cambio >2% en costo\n     INGREDIENT_CHANGE: Creado por modificacion de ingredientes\n     SCHEDULED: Creado por job programado (cierre de dia)';
SQL);
        } else {
            DB::unprepared('CREATE TABLE IF NOT EXISTS "selemti.recipe_cost_snapshots" (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                recipe_id TEXT NOT NULL,
                snapshot_date TEXT NOT NULL,
                cost_total REAL NOT NULL DEFAULT 0,
                cost_per_portion REAL NOT NULL DEFAULT 0,
                portions REAL NOT NULL DEFAULT 1,
                cost_breakdown TEXT NOT NULL DEFAULT "[]",
                reason TEXT NOT NULL,
                created_by_user_id INTEGER,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )');

            DB::unprepared('CREATE INDEX IF NOT EXISTS idx_recipe_cost_snap_recipe_date ON "selemti.recipe_cost_snapshots" (recipe_id, snapshot_date)');
            DB::unprepared('CREATE INDEX IF NOT EXISTS idx_recipe_cost_snap_date ON "selemti.recipe_cost_snapshots" (snapshot_date)');
        }
    }

    public function down(): void
    {
        $driver = DB::connection('pgsql')->getDriverName();

        if ($driver === 'pgsql') {
            DB::unprepared('DROP TABLE IF EXISTS selemti.recipe_cost_snapshots CASCADE');
        } else {
            DB::unprepared('DROP TABLE IF EXISTS "selemti.recipe_cost_snapshots"');
        }
    }
};
