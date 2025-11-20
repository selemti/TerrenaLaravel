# 🎯 PROMPT MAESTRO CODEX - BACKEND SATURDAY (1 NOV 2025)

**Agente**: GitHub Copilot Agent (Codex)
**Fecha de Ejecución**: Sábado 1 de Noviembre 2025
**Horario**: 09:00 - 15:00 (6 horas)
**Objetivo**: Backend crítico para despliegue Catálogos + Recetas

---

## 📋 CONTEXTO CRÍTICO

### Situación Actual
- **Proyecto**: TerrenaLaravel - Sistema ERP para restaurantes multi-sucursal
- **Estado**: 60% implementado, DB normalizada, Livewire funcional
- **Meta**: Despliegue THIS WEEKEND para captura de catálogos y recetas
- **Próximo Paso**: Despliegue completo siguiente fin de semana con POS

### Agentes en Paralelo
- **Qwen**: Frontend validaciones + UX (09:00-15:00)
- **Codex (TÚ)**: Backend services + tests (09:00-15:00)
- **Claude**: Coordinación general + deployment guide
- **ChatGPT**: Documentación final (domingo)

### Stack Técnico
```
Laravel 11 (PHP 8.2+)
PostgreSQL 9.5 (schema: selemti)
Livewire 3.7 + Alpine.js 3.15
Spatie Permissions
PHPUnit 10
```

---

## 🎯 PLAN DE TRABAJO (6 HORAS)

### BLOQUE 1: Recipe Cost Snapshots (09:00 - 11:00) ⏱️ 2h

**Objetivo**: Implementar sistema de snapshots para costos históricos de recetas.

**¿Por qué?**: Actualmente `RecipeCostController::calculateCostAtDate()` recalcula costos en tiempo real, pero necesitamos snapshots para:
- Performance (evitar cálculo recursivo en cada consulta)
- Auditoría (trazabilidad de cambios de costo)
- Reportes históricos (P&L, pricing analysis)

#### 1.1 Crear Migration `recipe_cost_snapshots`

**Archivo**: `database/migrations/2025_11_01_090000_create_recipe_cost_snapshots.sql`

```sql
-- Migration PostgreSQL para schema selemti
CREATE TABLE IF NOT EXISTS selemti.recipe_cost_snapshots (
    id BIGSERIAL PRIMARY KEY,
    recipe_id VARCHAR(50) NOT NULL,
    snapshot_date TIMESTAMP NOT NULL,
    cost_total DECIMAL(15,4) NOT NULL DEFAULT 0,
    cost_per_portion DECIMAL(15,4) NOT NULL DEFAULT 0,
    portions DECIMAL(10,3) NOT NULL DEFAULT 1,
    cost_breakdown JSONB NOT NULL DEFAULT '[]'::jsonb,
    reason VARCHAR(100) NOT NULL, -- 'MANUAL', 'AUTO_THRESHOLD', 'INGREDIENT_CHANGE', 'SCHEDULED'
    created_by_user_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_recipe_cost_snap_recipe
        FOREIGN KEY (recipe_id)
        REFERENCES selemti.recipes(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_recipe_cost_snap_user
        FOREIGN KEY (created_by_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);

-- Índices para performance
CREATE INDEX idx_recipe_cost_snap_recipe_date
    ON selemti.recipe_cost_snapshots(recipe_id, snapshot_date DESC);

CREATE INDEX idx_recipe_cost_snap_date
    ON selemti.recipe_cost_snapshots(snapshot_date DESC);

COMMENT ON TABLE selemti.recipe_cost_snapshots IS
    'Snapshots históricos de costos de recetas para auditoría y performance';

COMMENT ON COLUMN selemti.recipe_cost_snapshots.cost_breakdown IS
    'JSONB array con detalle: [{"item_id": "...", "item_name": "...", "qty": 1.5, "uom": "KG", "unit_cost": 45.50, "total_cost": 68.25}]';

COMMENT ON COLUMN selemti.recipe_cost_snapshots.reason IS
    'MANUAL: Creado manualmente por usuario
     AUTO_THRESHOLD: Creado automáticamente por cambio >2% en costo
     INGREDIENT_CHANGE: Creado por modificación de ingredientes
     SCHEDULED: Creado por job programado (cierre de día)';
```

**Validaciones**:
- ✅ Ejecutar migration en PostgreSQL local
- ✅ Verificar índices con `\d+ selemti.recipe_cost_snapshots`
- ✅ Verificar FKs funcionan correctamente

#### 1.2 Crear Modelo `RecipeCostSnapshot`

**Archivo**: `app/Models/Rec/RecipeCostSnapshot.php`

```php
<?php

namespace App\Models\Rec;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * RecipeCostSnapshot
 *
 * Almacena snapshots históricos de costos de recetas para:
 * - Evitar recálculos costosos (BOM implosion recursiva)
 * - Auditoría de cambios de costo
 * - Reportes históricos de rentabilidad
 *
 * @property int $id
 * @property string $recipe_id
 * @property \Carbon\Carbon $snapshot_date
 * @property float $cost_total
 * @property float $cost_per_portion
 * @property float $portions
 * @property array $cost_breakdown JSONB array con detalle de ingredientes
 * @property string $reason MANUAL|AUTO_THRESHOLD|INGREDIENT_CHANGE|SCHEDULED
 * @property int|null $created_by_user_id
 * @property \Carbon\Carbon $created_at
 *
 * @property-read Receta $recipe
 * @property-read User|null $createdBy
 */
class RecipeCostSnapshot extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.recipe_cost_snapshots';

    // No timestamps, solo created_at (snapshots son inmutables)
    public const UPDATED_AT = null;

    protected $fillable = [
        'recipe_id',
        'snapshot_date',
        'cost_total',
        'cost_per_portion',
        'portions',
        'cost_breakdown',
        'reason',
        'created_by_user_id',
    ];

    protected $casts = [
        'snapshot_date' => 'datetime',
        'cost_total' => 'decimal:4',
        'cost_per_portion' => 'decimal:4',
        'portions' => 'decimal:3',
        'cost_breakdown' => 'array', // JSONB
        'created_at' => 'datetime',
    ];

    /**
     * Razones válidas para crear snapshot
     */
    public const REASON_MANUAL = 'MANUAL';
    public const REASON_AUTO_THRESHOLD = 'AUTO_THRESHOLD';
    public const REASON_INGREDIENT_CHANGE = 'INGREDIENT_CHANGE';
    public const REASON_SCHEDULED = 'SCHEDULED';

    /**
     * Relación con receta
     */
    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Receta::class, 'recipe_id', 'id');
    }

    /**
     * Usuario que creó el snapshot
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    /**
     * Scope: Snapshots de una receta específica
     */
    public function scopeForRecipe($query, string $recipeId)
    {
        return $query->where('recipe_id', $recipeId);
    }

    /**
     * Scope: Snapshot más reciente antes de una fecha
     */
    public function scopeBeforeDate($query, \Carbon\Carbon $date)
    {
        return $query->where('snapshot_date', '<=', $date);
    }

    /**
     * Scope: Último snapshot de cada receta
     */
    public function scopeLatestPerRecipe($query)
    {
        return $query->whereIn('id', function ($subquery) {
            $subquery->selectRaw('MAX(id)')
                ->from('selemti.recipe_cost_snapshots')
                ->groupBy('recipe_id');
        });
    }

    /**
     * Obtener el snapshot más reciente de una receta en una fecha específica
     */
    public static function getForRecipeAtDate(string $recipeId, \Carbon\Carbon $date): ?self
    {
        return self::forRecipe($recipeId)
            ->beforeDate($date)
            ->orderBy('snapshot_date', 'desc')
            ->first();
    }

    /**
     * Obtener el último snapshot de una receta
     */
    public static function getLatestForRecipe(string $recipeId): ?self
    {
        return self::forRecipe($recipeId)
            ->orderBy('snapshot_date', 'desc')
            ->first();
    }
}
```

**Validaciones**:
- ✅ Verificar namespace correcto (`App\Models\Rec`)
- ✅ Probar relaciones: `RecipeCostSnapshot::first()->recipe->nombre`
- ✅ Probar scopes: `RecipeCostSnapshot::forRecipe('REC-001')->get()`

#### 1.3 Crear Service `RecipeCostSnapshotService`

**Archivo**: `app/Services/Recipes/RecipeCostSnapshotService.php`

```php
<?php

namespace App\Services\Recipes;

use App\Models\Rec\Receta;
use App\Models\Rec\RecipeCostSnapshot;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

/**
 * RecipeCostSnapshotService
 *
 * Gestiona la creación y recuperación de snapshots de costos de recetas.
 *
 * Casos de uso:
 * 1. Snapshot manual por usuario
 * 2. Snapshot automático cuando costo cambia >2%
 * 3. Snapshot automático cuando se modifican ingredientes
 * 4. Snapshot programado (cierre de día)
 *
 * @see RecipeCostSnapshot
 * @see RecipeCostController
 */
class RecipeCostSnapshotService
{
    /**
     * Umbral de cambio de costo para snapshot automático (2%)
     */
    public const COST_CHANGE_THRESHOLD = 0.02;

    /**
     * Crear snapshot de costo de una receta
     *
     * @param string $recipeId ID de la receta
     * @param string $reason Razón del snapshot (MANUAL, AUTO_THRESHOLD, etc.)
     * @param int|null $userId Usuario que crea el snapshot (null para automático)
     * @param Carbon|null $date Fecha del snapshot (default: now)
     * @return RecipeCostSnapshot
     * @throws \Exception Si falla el cálculo de costo
     */
    public function createSnapshot(
        string $recipeId,
        string $reason = RecipeCostSnapshot::REASON_MANUAL,
        ?int $userId = null,
        ?Carbon $date = null
    ): RecipeCostSnapshot {
        $date = $date ?? now();

        DB::beginTransaction();
        try {
            // Calcular costo actual usando RecipeCostController
            $costData = app(\App\Http\Controllers\Api\Inventory\RecipeCostController::class)
                ->calculateCostAtDate($recipeId, $date);

            if (!$costData || !isset($costData['cost_total'])) {
                throw new \Exception("No se pudo calcular el costo para la receta {$recipeId}");
            }

            // Crear snapshot
            $snapshot = RecipeCostSnapshot::create([
                'recipe_id' => $recipeId,
                'snapshot_date' => $date,
                'cost_total' => $costData['cost_total'],
                'cost_per_portion' => $costData['cost_per_portion'],
                'portions' => $costData['portions'] ?? 1,
                'cost_breakdown' => $costData['cost_breakdown'] ?? [],
                'reason' => $reason,
                'created_by_user_id' => $userId,
            ]);

            Log::info("Snapshot de costo creado", [
                'recipe_id' => $recipeId,
                'snapshot_id' => $snapshot->id,
                'cost_total' => $snapshot->cost_total,
                'reason' => $reason,
            ]);

            DB::commit();
            return $snapshot;

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Error creando snapshot de costo", [
                'recipe_id' => $recipeId,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Verificar si el costo de una receta ha cambiado más del threshold
     * y crear snapshot automático si es necesario
     *
     * @param string $recipeId ID de la receta
     * @param float $newCostTotal Nuevo costo total
     * @return bool True si se creó snapshot
     */
    public function checkAndCreateIfThresholdExceeded(
        string $recipeId,
        float $newCostTotal
    ): bool {
        // Obtener último snapshot
        $lastSnapshot = RecipeCostSnapshot::getLatestForRecipe($recipeId);

        if (!$lastSnapshot) {
            // No hay snapshot previo, crear primero
            $this->createSnapshot(
                $recipeId,
                RecipeCostSnapshot::REASON_MANUAL,
                null,
                now()
            );
            return true;
        }

        // Calcular cambio porcentual
        $oldCost = (float) $lastSnapshot->cost_total;
        if ($oldCost == 0) {
            return false; // Evitar división por cero
        }

        $percentChange = abs(($newCostTotal - $oldCost) / $oldCost);

        // Si cambio >2%, crear snapshot automático
        if ($percentChange > self::COST_CHANGE_THRESHOLD) {
            $this->createSnapshot(
                $recipeId,
                RecipeCostSnapshot::REASON_AUTO_THRESHOLD,
                null,
                now()
            );

            Log::warning("Costo de receta cambió >{COST_CHANGE_THRESHOLD * 100}%", [
                'recipe_id' => $recipeId,
                'old_cost' => $oldCost,
                'new_cost' => $newCostTotal,
                'change_percent' => round($percentChange * 100, 2),
            ]);

            return true;
        }

        return false;
    }

    /**
     * Obtener costo de una receta en una fecha específica
     *
     * Primero busca en snapshots (rápido), si no existe recalcula (lento).
     *
     * @param string $recipeId ID de la receta
     * @param Carbon $date Fecha de consulta
     * @return array Con cost_total, cost_per_portion, cost_breakdown
     */
    public function getCostAtDate(string $recipeId, Carbon $date): array
    {
        // Buscar snapshot más reciente antes de la fecha
        $snapshot = RecipeCostSnapshot::getForRecipeAtDate($recipeId, $date);

        if ($snapshot) {
            Log::debug("Costo obtenido de snapshot", [
                'recipe_id' => $recipeId,
                'snapshot_id' => $snapshot->id,
                'snapshot_date' => $snapshot->snapshot_date,
            ]);

            return [
                'cost_total' => (float) $snapshot->cost_total,
                'cost_per_portion' => (float) $snapshot->cost_per_portion,
                'portions' => (float) $snapshot->portions,
                'cost_breakdown' => $snapshot->cost_breakdown,
                'from_snapshot' => true,
                'snapshot_date' => $snapshot->snapshot_date,
            ];
        }

        // No hay snapshot, recalcular (performance hit)
        Log::warning("No hay snapshot, recalculando costo (lento)", [
            'recipe_id' => $recipeId,
            'date' => $date,
        ]);

        $costData = app(\App\Http\Controllers\Api\Inventory\RecipeCostController::class)
            ->calculateCostAtDate($recipeId, $date);

        $costData['from_snapshot'] = false;

        return $costData;
    }

    /**
     * Crear snapshots para todas las recetas activas
     *
     * Útil para jobs programados (cierre de día).
     *
     * @param string $reason Razón del snapshot
     * @param Carbon|null $date Fecha del snapshot
     * @return int Número de snapshots creados
     */
    public function createSnapshotsForAllRecipes(
        string $reason = RecipeCostSnapshot::REASON_SCHEDULED,
        ?Carbon $date = null
    ): int {
        $date = $date ?? now();
        $count = 0;

        $recipes = Receta::where('activo', true)->get();

        foreach ($recipes as $recipe) {
            try {
                $this->createSnapshot($recipe->id, $reason, null, $date);
                $count++;
            } catch (\Exception $e) {
                Log::error("Error creando snapshot para receta", [
                    'recipe_id' => $recipe->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        Log::info("Snapshots masivos creados", [
            'total' => $count,
            'reason' => $reason,
            'date' => $date,
        ]);

        return $count;
    }
}
```

**Validaciones**:
- ✅ Verificar namespace correcto
- ✅ Probar `createSnapshot()` manualmente
- ✅ Probar `getCostAtDate()` con y sin snapshot existente
- ✅ Verificar logs en `storage/logs/laravel.log`

#### 1.4 Crear Feature Test

**Archivo**: `tests/Feature/RecipeCostSnapshotTest.php`

```php
<?php

namespace Tests\Feature;

use App\Models\Rec\Receta;
use App\Models\Rec\RecipeCostSnapshot;
use App\Services\Recipes\RecipeCostSnapshotService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RecipeCostSnapshotTest extends TestCase
{
    use RefreshDatabase;

    protected RecipeCostSnapshotService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(RecipeCostSnapshotService::class);
    }

    /** @test */
    public function it_creates_manual_snapshot()
    {
        // Arrange: Crear receta de prueba
        $recipe = Receta::factory()->create([
            'id' => 'REC-TEST-001',
            'nombre' => 'Hamburguesa Test',
            'activo' => true,
        ]);

        // Act: Crear snapshot manual
        $snapshot = $this->service->createSnapshot(
            'REC-TEST-001',
            RecipeCostSnapshot::REASON_MANUAL,
            1 // user_id
        );

        // Assert
        $this->assertInstanceOf(RecipeCostSnapshot::class, $snapshot);
        $this->assertEquals('REC-TEST-001', $snapshot->recipe_id);
        $this->assertEquals(RecipeCostSnapshot::REASON_MANUAL, $snapshot->reason);
        $this->assertEquals(1, $snapshot->created_by_user_id);
        $this->assertNotNull($snapshot->cost_total);
        $this->assertNotNull($snapshot->cost_per_portion);
    }

    /** @test */
    public function it_retrieves_cost_from_snapshot()
    {
        // Arrange: Crear receta y snapshot
        $recipe = Receta::factory()->create(['id' => 'REC-TEST-002']);

        RecipeCostSnapshot::create([
            'recipe_id' => 'REC-TEST-002',
            'snapshot_date' => Carbon::parse('2025-10-15 10:00:00'),
            'cost_total' => 125.50,
            'cost_per_portion' => 62.75,
            'portions' => 2,
            'cost_breakdown' => [
                ['item_id' => 'ITEM-001', 'item_name' => 'Carne', 'total_cost' => 80.00],
                ['item_id' => 'ITEM-002', 'item_name' => 'Pan', 'total_cost' => 45.50],
            ],
            'reason' => RecipeCostSnapshot::REASON_MANUAL,
        ]);

        // Act: Consultar costo en fecha del snapshot
        $costData = $this->service->getCostAtDate(
            'REC-TEST-002',
            Carbon::parse('2025-10-15 12:00:00')
        );

        // Assert: Debe obtener de snapshot (no recalcular)
        $this->assertTrue($costData['from_snapshot']);
        $this->assertEquals(125.50, $costData['cost_total']);
        $this->assertEquals(62.75, $costData['cost_per_portion']);
        $this->assertCount(2, $costData['cost_breakdown']);
    }

    /** @test */
    public function it_creates_automatic_snapshot_when_threshold_exceeded()
    {
        // Arrange: Crear receta y snapshot inicial
        $recipe = Receta::factory()->create(['id' => 'REC-TEST-003']);

        $initialSnapshot = $this->service->createSnapshot(
            'REC-TEST-003',
            RecipeCostSnapshot::REASON_MANUAL
        );

        $oldCost = (float) $initialSnapshot->cost_total;

        // Act: Simular cambio de costo >2%
        $newCost = $oldCost * 1.05; // +5% cambio
        $created = $this->service->checkAndCreateIfThresholdExceeded(
            'REC-TEST-003',
            $newCost
        );

        // Assert: Debe haber creado snapshot automático
        $this->assertTrue($created);

        $autoSnapshot = RecipeCostSnapshot::forRecipe('REC-TEST-003')
            ->where('reason', RecipeCostSnapshot::REASON_AUTO_THRESHOLD)
            ->first();

        $this->assertNotNull($autoSnapshot);
    }

    /** @test */
    public function it_does_not_create_snapshot_when_threshold_not_exceeded()
    {
        // Arrange
        $recipe = Receta::factory()->create(['id' => 'REC-TEST-004']);

        $initialSnapshot = $this->service->createSnapshot(
            'REC-TEST-004',
            RecipeCostSnapshot::REASON_MANUAL
        );

        $oldCost = (float) $initialSnapshot->cost_total;

        // Act: Cambio <2%
        $newCost = $oldCost * 1.01; // +1% cambio
        $created = $this->service->checkAndCreateIfThresholdExceeded(
            'REC-TEST-004',
            $newCost
        );

        // Assert: No debe crear snapshot
        $this->assertFalse($created);

        $count = RecipeCostSnapshot::forRecipe('REC-TEST-004')->count();
        $this->assertEquals(1, $count); // Solo el inicial
    }

    /** @test */
    public function it_creates_snapshots_for_all_active_recipes()
    {
        // Arrange: Crear 5 recetas (3 activas, 2 inactivas)
        Receta::factory()->count(3)->create(['activo' => true]);
        Receta::factory()->count(2)->create(['activo' => false]);

        // Act: Crear snapshots masivos
        $count = $this->service->createSnapshotsForAllRecipes(
            RecipeCostSnapshot::REASON_SCHEDULED
        );

        // Assert: Solo debe crear 3 snapshots (recetas activas)
        $this->assertEquals(3, $count);

        $totalSnapshots = RecipeCostSnapshot::count();
        $this->assertEquals(3, $totalSnapshots);
    }
}
```

**Validaciones**:
- ✅ Ejecutar `php artisan test tests/Feature/RecipeCostSnapshotTest.php`
- ✅ Todos los tests deben pasar (5/5)
- ✅ Verificar cobertura de código >80%

---

### BLOQUE 2: Recipe BOM Implosion (11:00 - 13:00) ⏱️ 2h

**Objetivo**: Implementar implosión de BOM para obtener ingredientes base de recetas compuestas.

**¿Por qué?**: Las recetas pueden contener otras recetas como ingredientes (ej: "Hamburguesa" contiene "Pan Casero"). Necesitamos "explosión inversa" (implosión) para obtener SOLO ingredientes base (raw materials) y calcular costos correctamente.

#### 2.1 Crear Service Method `RecipeCostController::implodeRecipeBom()`

**Archivo**: `app/Http/Controllers/Api/Inventory/RecipeCostController.php`

**Agregar método al controlador existente**:

```php
/**
 * Implosionar BOM de receta para obtener solo ingredientes base
 *
 * Recorre recursivamente los ingredientes de una receta y sub-recetas
 * hasta obtener solo items (no recetas).
 *
 * Ejemplo:
 * Hamburguesa
 *   ├─ Pan Casero (receta)
 *   │   ├─ Harina (item) - 500g
 *   │   └─ Mantequilla (item) - 50g
 *   ├─ Carne Molida (item) - 200g
 *   └─ Queso (item) - 100g
 *
 * Resultado implosionado:
 *   - Harina: 500g
 *   - Mantequilla: 50g
 *   - Carne Molida: 200g
 *   - Queso: 100g
 *
 * GET /api/recipes/{id}/bom/implode
 *
 * @param string $id Recipe ID
 * @return JsonResponse
 */
public function implodeRecipeBom(string $id): JsonResponse
{
    try {
        $recipe = Receta::findOrFail($id);

        // Array para acumular ingredientes base
        $baseIngredients = [];

        // Recursivamente implosionar BOM
        $this->implodeRecipeBomRecursive(
            $id,
            1.0, // factor inicial = 1 (cantidad completa)
            $baseIngredients
        );

        // Convertir a array de valores (sin keys)
        $result = array_values($baseIngredients);

        return response()->json([
            'ok' => true,
            'data' => [
                'recipe_id' => $id,
                'recipe_name' => $recipe->nombre,
                'base_ingredients' => $result,
                'total_ingredients' => count($result),
            ],
            'timestamp' => now()->toIso8601String(),
        ]);

    } catch (\Exception $e) {
        Log::error('Error imploding recipe BOM', [
            'recipe_id' => $id,
            'error' => $e->getMessage(),
        ]);

        return response()->json([
            'ok' => false,
            'error' => 'BOM_IMPLOSION_ERROR',
            'message' => 'Error al implosionar BOM de receta',
            'timestamp' => now()->toIso8601String(),
        ], 500);
    }
}

/**
 * Método recursivo privado para implosión de BOM
 *
 * @param string $recipeId ID de la receta a implosionar
 * @param float $factor Factor multiplicador de cantidad (para sub-recetas)
 * @param array &$baseIngredients Array de referencia para acumular ingredientes
 * @param int $depth Profundidad actual (evitar loops infinitos)
 * @return void
 */
private function implodeRecipeBomRecursive(
    string $recipeId,
    float $factor,
    array &$baseIngredients,
    int $depth = 0
): void {
    // Protección contra loops infinitos
    if ($depth > 10) {
        Log::warning('Max BOM implosion depth reached', [
            'recipe_id' => $recipeId,
            'depth' => $depth,
        ]);
        return;
    }

    // Obtener ingredientes de la receta actual
    $recipe = Receta::with(['detalles.item', 'detalles.subreceta'])->findOrFail($recipeId);

    foreach ($recipe->detalles as $detalle) {
        // Caso 1: Es un ITEM (ingrediente base)
        if ($detalle->item_id) {
            $item = $detalle->item;
            $key = $item->id; // Usar item_id como key para agrupar

            // Calcular cantidad ajustada por factor
            $adjustedQty = $detalle->cantidad * $factor;

            // Si ya existe este item, sumar cantidades
            if (isset($baseIngredients[$key])) {
                $baseIngredients[$key]['qty'] += $adjustedQty;
            } else {
                $baseIngredients[$key] = [
                    'item_id' => $item->id,
                    'item_code' => $item->codigo,
                    'item_name' => $item->nombre,
                    'qty' => $adjustedQty,
                    'uom' => $detalle->unidad_id,
                    'category' => $item->categoria->nombre ?? 'Sin categoría',
                ];
            }
        }
        // Caso 2: Es una SUB-RECETA (recursión)
        elseif ($detalle->receta_id) {
            // Factor acumulativo = factor actual * cantidad de sub-receta
            $newFactor = $factor * $detalle->cantidad;

            // Llamada recursiva
            $this->implodeRecipeBomRecursive(
                $detalle->receta_id,
                $newFactor,
                $baseIngredients,
                $depth + 1
            );
        }
    }
}
```

**Validaciones**:
- ✅ Agregar route en `routes/api.php`: `Route::get('/recipes/{id}/bom/implode', [RecipeCostController::class, 'implodeRecipeBom']);`
- ✅ Probar con Postman: `GET /api/recipes/REC-001/bom/implode`
- ✅ Verificar que agrupa cantidades de items repetidos
- ✅ Verificar que maneja sub-recetas recursivamente

#### 2.2 Agregar Endpoint a API Documentation

**Archivo**: `docs/UI-UX/MASTER/10_API_SPECS/API_RECETAS.md`

**Agregar después del endpoint 6**:

```markdown
### 7. GET /api/recipes/{id}/bom/implode

Implosiona el BOM (Bill of Materials) de una receta para obtener SOLO ingredientes base.

**¿Qué hace?**:
- Recorre recursivamente todos los ingredientes de una receta
- Si encuentra sub-recetas, las "explota" hasta llegar a items (raw materials)
- Agrupa ingredientes repetidos sumando cantidades
- Retorna lista plana de items base necesarios

**Use Case**:
- Calcular costo total de receta compuesta
- Generar requisiciones de compra
- Validar disponibilidad de stock para producción

#### Request

```http
GET /api/recipes/REC-HAMBUR-001/bom/implode
Authorization: Bearer {token}
```

#### Response 200 OK

```json
{
  "ok": true,
  "data": {
    "recipe_id": "REC-HAMBUR-001",
    "recipe_name": "Hamburguesa Clásica",
    "base_ingredients": [
      {
        "item_id": "ITEM-HAR-001",
        "item_code": "HAR-TRIG-500",
        "item_name": "Harina de Trigo",
        "qty": 0.5,
        "uom": "KG",
        "category": "Harinas"
      },
      {
        "item_id": "ITEM-MAN-002",
        "item_code": "MAN-SIN-250",
        "item_name": "Mantequilla sin sal",
        "qty": 0.05,
        "uom": "KG",
        "category": "Lácteos"
      },
      {
        "item_id": "ITEM-CAR-003",
        "item_code": "CAR-MOL-RES",
        "item_name": "Carne molida de res",
        "qty": 0.2,
        "uom": "KG",
        "category": "Carnes"
      },
      {
        "item_id": "ITEM-QUE-004",
        "item_code": "QUE-CHE-AMA",
        "item_name": "Queso cheddar",
        "qty": 0.1,
        "uom": "KG",
        "category": "Lácteos"
      }
    ],
    "total_ingredients": 4
  },
  "timestamp": "2025-11-01T10:30:00.000000Z"
}
```

#### Ejemplo cURL

```bash
curl -X GET "https://app.terrena.com/api/recipes/REC-HAMBUR-001/bom/implode" \
  -H "Authorization: Bearer 1|abc123..." \
  -H "Accept: application/json"
```

#### Notas

- **Recursión**: Maneja hasta 10 niveles de sub-recetas (protección contra loops)
- **Agrupación**: Si un item aparece en múltiples sub-recetas, suma las cantidades
- **Performance**: Puede ser lento para recetas muy complejas (>50 ingredientes)
```

**Validaciones**:
- ✅ Actualizar documentación
- ✅ Verificar formato Markdown correcto

#### 2.3 Crear Feature Test para BOM Implosion

**Archivo**: `tests/Feature/RecipeBomImplosionTest.php`

```php
<?php

namespace Tests\Feature;

use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Inv\Item;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RecipeBomImplosionTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_implodes_simple_recipe_with_only_items()
    {
        // Arrange: Receta simple con solo items
        $recipe = Receta::factory()->create(['id' => 'REC-SIMPLE']);

        $item1 = Item::factory()->create(['id' => 'ITEM-001', 'nombre' => 'Harina']);
        $item2 = Item::factory()->create(['id' => 'ITEM-002', 'nombre' => 'Azúcar']);

        RecetaDetalle::create([
            'receta_id' => 'REC-SIMPLE',
            'item_id' => 'ITEM-001',
            'cantidad' => 0.5,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-SIMPLE',
            'item_id' => 'ITEM-002',
            'cantidad' => 0.2,
            'unidad_id' => 'KG',
        ]);

        // Act
        $response = $this->getJson('/api/recipes/REC-SIMPLE/bom/implode');

        // Assert
        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'data' => [
                    'recipe_id' => 'REC-SIMPLE',
                    'total_ingredients' => 2,
                ],
            ]);

        $ingredients = $response->json('data.base_ingredients');
        $this->assertCount(2, $ingredients);

        // Verificar ingredientes
        $this->assertEquals('ITEM-001', $ingredients[0]['item_id']);
        $this->assertEquals(0.5, $ingredients[0]['qty']);

        $this->assertEquals('ITEM-002', $ingredients[1]['item_id']);
        $this->assertEquals(0.2, $ingredients[1]['qty']);
    }

    /** @test */
    public function it_implodes_complex_recipe_with_subrecipes()
    {
        // Arrange: Receta compuesta
        // Hamburguesa -> Pan Casero (receta) + Carne (item) + Queso (item)
        // Pan Casero -> Harina (item) + Mantequilla (item)

        $hamburguesa = Receta::factory()->create(['id' => 'REC-HAMBUR', 'nombre' => 'Hamburguesa']);
        $panCasero = Receta::factory()->create(['id' => 'REC-PAN', 'nombre' => 'Pan Casero']);

        $harina = Item::factory()->create(['id' => 'ITEM-HAR', 'nombre' => 'Harina']);
        $mantequilla = Item::factory()->create(['id' => 'ITEM-MAN', 'nombre' => 'Mantequilla']);
        $carne = Item::factory()->create(['id' => 'ITEM-CAR', 'nombre' => 'Carne']);
        $queso = Item::factory()->create(['id' => 'ITEM-QUE', 'nombre' => 'Queso']);

        // Pan Casero = 0.5kg Harina + 0.05kg Mantequilla
        RecetaDetalle::create([
            'receta_id' => 'REC-PAN',
            'item_id' => 'ITEM-HAR',
            'cantidad' => 0.5,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-PAN',
            'item_id' => 'ITEM-MAN',
            'cantidad' => 0.05,
            'unidad_id' => 'KG',
        ]);

        // Hamburguesa = 1x Pan Casero + 0.2kg Carne + 0.1kg Queso
        RecetaDetalle::create([
            'receta_id' => 'REC-HAMBUR',
            'receta_id_ingrediente' => 'REC-PAN', // Sub-receta
            'cantidad' => 1,
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-HAMBUR',
            'item_id' => 'ITEM-CAR',
            'cantidad' => 0.2,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-HAMBUR',
            'item_id' => 'ITEM-QUE',
            'cantidad' => 0.1,
            'unidad_id' => 'KG',
        ]);

        // Act
        $response = $this->getJson('/api/recipes/REC-HAMBUR/bom/implode');

        // Assert
        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'data' => [
                    'recipe_id' => 'REC-HAMBUR',
                    'total_ingredients' => 4, // Harina, Mantequilla, Carne, Queso
                ],
            ]);

        $ingredients = $response->json('data.base_ingredients');
        $this->assertCount(4, $ingredients);

        // Verificar que NO incluye sub-receta (Pan Casero), solo items base
        $itemIds = array_column($ingredients, 'item_id');
        $this->assertContains('ITEM-HAR', $itemIds);
        $this->assertContains('ITEM-MAN', $itemIds);
        $this->assertContains('ITEM-CAR', $itemIds);
        $this->assertContains('ITEM-QUE', $itemIds);
    }

    /** @test */
    public function it_aggregates_duplicate_ingredients_from_multiple_subrecipes()
    {
        // Arrange: Dos sub-recetas que usan el mismo ingrediente
        // Pizza -> Masa (receta) + Salsa (receta)
        // Masa -> 0.5kg Harina
        // Salsa -> 0.1kg Harina (para espesar)
        // Resultado: 0.6kg Harina total

        $pizza = Receta::factory()->create(['id' => 'REC-PIZZA']);
        $masa = Receta::factory()->create(['id' => 'REC-MASA']);
        $salsa = Receta::factory()->create(['id' => 'REC-SALSA']);

        $harina = Item::factory()->create(['id' => 'ITEM-HAR', 'nombre' => 'Harina']);

        // Masa = 0.5kg Harina
        RecetaDetalle::create([
            'receta_id' => 'REC-MASA',
            'item_id' => 'ITEM-HAR',
            'cantidad' => 0.5,
            'unidad_id' => 'KG',
        ]);

        // Salsa = 0.1kg Harina
        RecetaDetalle::create([
            'receta_id' => 'REC-SALSA',
            'item_id' => 'ITEM-HAR',
            'cantidad' => 0.1,
            'unidad_id' => 'KG',
        ]);

        // Pizza = Masa + Salsa
        RecetaDetalle::create([
            'receta_id' => 'REC-PIZZA',
            'receta_id_ingrediente' => 'REC-MASA',
            'cantidad' => 1,
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-PIZZA',
            'receta_id_ingrediente' => 'REC-SALSA',
            'cantidad' => 1,
        ]);

        // Act
        $response = $this->getJson('/api/recipes/REC-PIZZA/bom/implode');

        // Assert
        $response->assertStatus(200);

        $ingredients = $response->json('data.base_ingredients');
        $this->assertCount(1, $ingredients); // Solo 1 item (Harina agregada)

        $harinaData = $ingredients[0];
        $this->assertEquals('ITEM-HAR', $harinaData['item_id']);
        $this->assertEquals(0.6, $harinaData['qty']); // 0.5 + 0.1
    }
}
```

**Validaciones**:
- ✅ Ejecutar `php artisan test tests/Feature/RecipeBomImplosionTest.php`
- ✅ Todos los tests deben pasar (3/3)
- ✅ Verificar cobertura de código >80%

---

### BLOQUE 3: Seeders + Final Testing (13:00 - 15:00) ⏱️ 2h

**Objetivo**: Crear seeders production-ready para catálogos y recetas, y tests finales.

#### 3.1 Crear Seeder `CatalogosProductionSeeder`

**Archivo**: `database/seeders/CatalogosProductionSeeder.php`

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

/**
 * CatalogosProductionSeeder
 *
 * Seeder para datos de catálogos en producción.
 *
 * IMPORTANTE: Este seeder está diseñado para ejecutarse EN PRODUCCIÓN
 * para inicializar catálogos básicos antes de que el personal capture datos.
 *
 * Ejecutar con:
 * php artisan db:seed --class=CatalogosProductionSeeder
 */
class CatalogosProductionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::connection('pgsql')->beginTransaction();

        try {
            $this->seedUnidadesMedida();
            $this->seedSucursales();
            $this->seedAlmacenes();
            $this->seedCategorias();
            $this->seedProveedores();

            DB::connection('pgsql')->commit();

            $this->command->info('✅ Catálogos de producción creados exitosamente');

        } catch (\Exception $e) {
            DB::connection('pgsql')->rollBack();
            $this->command->error('❌ Error creando catálogos: ' . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Seed unidades de medida básicas
     */
    private function seedUnidadesMedida(): void
    {
        $now = Carbon::now();

        $unidades = [
            // MASA
            ['codigo' => 'KG', 'nombre' => 'Kilogramo', 'tipo' => 'BASE', 'categoria' => 'MASA', 'es_base' => true, 'factor' => 1.0, 'decimales' => 3],
            ['codigo' => 'GR', 'nombre' => 'Gramo', 'tipo' => 'BASE', 'categoria' => 'MASA', 'es_base' => false, 'factor' => 0.001, 'decimales' => 2],

            // VOLUMEN
            ['codigo' => 'LT', 'nombre' => 'Litro', 'tipo' => 'BASE', 'categoria' => 'VOLUMEN', 'es_base' => true, 'factor' => 1.0, 'decimales' => 3],
            ['codigo' => 'ML', 'nombre' => 'Mililitro', 'tipo' => 'BASE', 'categoria' => 'VOLUMEN', 'es_base' => false, 'factor' => 0.001, 'decimales' => 2],

            // UNIDAD
            ['codigo' => 'PZ', 'nombre' => 'Pieza', 'tipo' => 'BASE', 'categoria' => 'UNIDAD', 'es_base' => true, 'factor' => 1.0, 'decimales' => 0],
            ['codigo' => 'PAQ', 'nombre' => 'Paquete', 'tipo' => 'COMPRA', 'categoria' => 'UNIDAD', 'es_base' => false, 'factor' => 1.0, 'decimales' => 0],
            ['codigo' => 'CAJ', 'nombre' => 'Caja', 'tipo' => 'COMPRA', 'categoria' => 'UNIDAD', 'es_base' => false, 'factor' => 1.0, 'decimales' => 0],
        ];

        foreach ($unidades as $unidad) {
            DB::connection('pgsql')->table('selemti.unidades_medida')->updateOrInsert(
                ['codigo' => $unidad['codigo']],
                [
                    'nombre' => $unidad['nombre'],
                    'tipo' => $unidad['tipo'],
                    'categoria' => $unidad['categoria'],
                    'es_base' => $unidad['es_base'],
                    'factor_conversion_base' => $unidad['factor'],
                    'decimales' => $unidad['decimales'],
                    'activo' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]
            );
        }

        $this->command->info('  → Unidades de medida: 7 creadas');
    }

    /**
     * Seed sucursales iniciales
     */
    private function seedSucursales(): void
    {
        $now = Carbon::now();

        $sucursales = [
            [
                'clave' => 'SUC-01',
                'nombre' => 'Sucursal Principal',
                'rfc' => 'XAXX010101000',
                'direccion' => 'Por definir',
                'telefono' => '0000000000',
                'email' => 'principal@terrena.com',
                'activo' => true,
            ],
        ];

        foreach ($sucursales as $sucursal) {
            DB::connection('pgsql')->table('selemti.cat_sucursales')->updateOrInsert(
                ['clave' => $sucursal['clave']],
                array_merge($sucursal, ['created_at' => $now, 'updated_at' => $now])
            );
        }

        $this->command->info('  → Sucursales: 1 creada');
    }

    /**
     * Seed almacenes iniciales
     */
    private function seedAlmacenes(): void
    {
        $now = Carbon::now();

        // Obtener ID de sucursal principal
        $sucursalId = DB::connection('pgsql')
            ->table('selemti.cat_sucursales')
            ->where('clave', 'SUC-01')
            ->value('id');

        $almacenes = [
            [
                'sucursal_id' => $sucursalId,
                'nombre' => 'Almacén General',
                'tipo' => 'GENERAL',
                'activo' => true,
            ],
            [
                'sucursal_id' => $sucursalId,
                'nombre' => 'Almacén Refrigerados',
                'tipo' => 'FRIO',
                'activo' => true,
            ],
        ];

        foreach ($almacenes as $almacen) {
            DB::connection('pgsql')->table('selemti.cat_almacenes')->updateOrInsert(
                ['sucursal_id' => $almacen['sucursal_id'], 'nombre' => $almacen['nombre']],
                array_merge($almacen, ['created_at' => $now, 'updated_at' => $now])
            );
        }

        $this->command->info('  → Almacenes: 2 creados');
    }

    /**
     * Seed categorías de items
     */
    private function seedCategorias(): void
    {
        $now = Carbon::now();

        $categorias = [
            ['codigo' => 'CAR', 'nombre' => 'Carnes', 'prefijo' => 'CAR'],
            ['codigo' => 'LAC', 'nombre' => 'Lácteos', 'prefijo' => 'LAC'],
            ['codigo' => 'VEG', 'nombre' => 'Vegetales', 'prefijo' => 'VEG'],
            ['codigo' => 'HAR', 'nombre' => 'Harinas y Granos', 'prefijo' => 'HAR'],
            ['codigo' => 'BEB', 'nombre' => 'Bebidas', 'prefijo' => 'BEB'],
            ['codigo' => 'CON', 'nombre' => 'Condimentos', 'prefijo' => 'CON'],
        ];

        foreach ($categorias as $categoria) {
            DB::connection('pgsql')->table('selemti.item_categories')->updateOrInsert(
                ['codigo' => $categoria['codigo']],
                array_merge($categoria, ['created_at' => $now, 'updated_at' => $now])
            );
        }

        $this->command->info('  → Categorías: 6 creadas');
    }

    /**
     * Seed proveedores demo (opcional)
     */
    private function seedProveedores(): void
    {
        $now = Carbon::now();

        $proveedores = [
            [
                'nombre_comercial' => 'Proveedor General',
                'razon_social' => 'Proveedor General S.A. de C.V.',
                'rfc' => 'PGE000101000',
                'tipo' => 'GENERAL',
                'activo' => true,
            ],
        ];

        foreach ($proveedores as $proveedor) {
            DB::connection('pgsql')->table('selemti.cat_proveedores')->updateOrInsert(
                ['rfc' => $proveedor['rfc']],
                array_merge($proveedor, ['created_at' => $now, 'updated_at' => $now])
            );
        }

        $this->command->info('  → Proveedores: 1 creado');
    }
}
```

**Validaciones**:
- ✅ Ejecutar seeder en LOCAL: `php artisan db:seed --class=CatalogosProductionSeeder`
- ✅ Verificar que no hay duplicados (updateOrInsert)
- ✅ Verificar IDs autoincrementales correctos

#### 3.2 Crear Seeder `RecipesProductionSeeder`

**Archivo**: `database/seeders/RecipesProductionSeeder.php`

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

/**
 * RecipesProductionSeeder
 *
 * Seeder para recetas demo en producción.
 *
 * IMPORTANTE: Este seeder crea recetas de EJEMPLO para que el personal
 * entienda cómo capturar recetas reales.
 *
 * Ejecutar con:
 * php artisan db:seed --class=RecipesProductionSeeder
 */
class RecipesProductionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::connection('pgsql')->beginTransaction();

        try {
            $this->seedRecipeDemo();

            DB::connection('pgsql')->commit();

            $this->command->info('✅ Recetas demo creadas exitosamente');

        } catch (\Exception $e) {
            DB::connection('pgsql')->rollBack();
            $this->command->error('❌ Error creando recetas: ' . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Seed receta demo: "Receta de Ejemplo"
     */
    private function seedRecipeDemo(): void
    {
        $now = Carbon::now();

        // Verificar que existan items de ejemplo (opcional)
        $itemsExist = DB::connection('pgsql')
            ->table('selemti.items')
            ->exists();

        if (!$itemsExist) {
            $this->command->warn('  ⚠️  No hay items en catálogo, se creará receta vacía');
        }

        // Crear receta
        $recipeId = DB::connection('pgsql')->table('selemti.recipes')->insertGetId([
            'id' => 'REC-DEMO-001',
            'codigo' => 'DEMO-001',
            'nombre' => 'Receta de Ejemplo',
            'descripcion' => 'Esta es una receta de ejemplo para que el personal aprenda a capturar recetas reales.',
            'porciones' => 4,
            'tiempo_preparacion' => 30,
            'activo' => true,
            'created_by_user_id' => 1, // Admin
            'created_at' => $now,
            'updated_at' => $now,
        ], 'id');

        $this->command->info('  → Receta demo creada: REC-DEMO-001');

        // Crear versión inicial
        DB::connection('pgsql')->table('selemti.recipe_versions')->insert([
            'recipe_id' => 'REC-DEMO-001',
            'version_number' => 1,
            'version_date' => $now,
            'reason' => 'Versión inicial',
            'created_by_user_id' => 1,
            'created_at' => $now,
        ]);

        $this->command->info('  → Versión inicial creada');
    }
}
```

**Validaciones**:
- ✅ Ejecutar seeder en LOCAL
- ✅ Verificar receta aparece en Livewire component
- ✅ Verificar no rompe si no hay items

#### 3.3 Crear Integration Test Completo

**Archivo**: `tests/Feature/WeekendDeploymentIntegrationTest.php`

```php
<?php

namespace Tests\Feature;

use App\Models\Rec\RecipeCostSnapshot;
use App\Services\Recipes\RecipeCostSnapshotService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Integration test para validar funcionalidad crítica del despliegue del fin de semana
 *
 * Verifica:
 * 1. API Catálogos responde correctamente
 * 2. API Recetas responde correctamente
 * 3. Snapshots de costos funcionan end-to-end
 * 4. BOM implosion funciona end-to-end
 */
class WeekendDeploymentIntegrationTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_can_fetch_all_catalog_endpoints()
    {
        // Act & Assert: Todos los endpoints de catálogos deben responder 200

        $this->getJson('/api/catalogs/sucursales')
            ->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    '*' => ['id', 'clave', 'nombre', 'activo'],
                ],
                'timestamp',
            ]);

        $this->getJson('/api/catalogs/almacenes')
            ->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    '*' => ['id', 'sucursal_id', 'nombre', 'tipo', 'activo'],
                ],
                'timestamp',
            ]);

        $this->getJson('/api/catalogs/unidades')
            ->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'count',
                'data',
                'timestamp',
            ]);

        $this->getJson('/api/catalogs/categories')
            ->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data',
                'timestamp',
            ]);

        $this->getJson('/api/catalogs/movement-types')
            ->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    '*' => ['value', 'label', 'description', 'affects_stock', 'sign'],
                ],
                'timestamp',
            ]);
    }

    /** @test */
    public function it_can_calculate_recipe_cost_and_create_snapshot()
    {
        // Arrange: Crear receta de prueba
        $recipe = Receta::factory()->create(['id' => 'REC-INT-001']);

        // Act: Calcular costo (endpoint)
        $response = $this->getJson("/api/recipes/REC-INT-001/cost");

        // Assert
        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    'recipe_id',
                    'recipe_name',
                    'cost_total',
                    'cost_per_portion',
                    'cost_breakdown',
                ],
                'timestamp',
            ]);

        // Act: Crear snapshot
        $service = app(RecipeCostSnapshotService::class);
        $snapshot = $service->createSnapshot('REC-INT-001', RecipeCostSnapshot::REASON_MANUAL, 1);

        // Assert
        $this->assertNotNull($snapshot->id);
        $this->assertEquals('REC-INT-001', $snapshot->recipe_id);
    }

    /** @test */
    public function it_can_implode_recipe_bom_end_to_end()
    {
        // Arrange: Receta con items
        $recipe = Receta::factory()->create(['id' => 'REC-BOM-001']);
        $item1 = Item::factory()->create(['id' => 'ITEM-BOM-001']);
        $item2 = Item::factory()->create(['id' => 'ITEM-BOM-002']);

        RecetaDetalle::create([
            'receta_id' => 'REC-BOM-001',
            'item_id' => 'ITEM-BOM-001',
            'cantidad' => 1.5,
            'unidad_id' => 'KG',
        ]);

        RecetaDetalle::create([
            'receta_id' => 'REC-BOM-001',
            'item_id' => 'ITEM-BOM-002',
            'cantidad' => 0.5,
            'unidad_id' => 'LT',
        ]);

        // Act
        $response = $this->getJson('/api/recipes/REC-BOM-001/bom/implode');

        // Assert
        $response->assertStatus(200)
            ->assertJsonStructure([
                'ok',
                'data' => [
                    'recipe_id',
                    'recipe_name',
                    'base_ingredients' => [
                        '*' => ['item_id', 'item_name', 'qty', 'uom'],
                    ],
                    'total_ingredients',
                ],
                'timestamp',
            ]);

        $this->assertEquals(2, $response->json('data.total_ingredients'));
    }
}
```

**Validaciones**:
- ✅ Ejecutar `php artisan test tests/Feature/WeekendDeploymentIntegrationTest.php`
- ✅ Todos los tests deben pasar (3/3)

#### 3.4 Actualizar DatabaseSeeder Principal

**Archivo**: `database/seeders/DatabaseSeeder.php`

**Agregar llamada a nuevos seeders**:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Seeders existentes...
        // $this->call(UsersSeeder::class);

        // NUEVOS SEEDERS PARA DESPLIEGUE FIN DE SEMANA
        if ($this->command->confirm('¿Desea crear catálogos de producción?', true)) {
            $this->call(CatalogosProductionSeeder::class);
        }

        if ($this->command->confirm('¿Desea crear recetas demo?', true)) {
            $this->call(RecipesProductionSeeder::class);
        }
    }
}
```

**Validaciones**:
- ✅ Ejecutar `php artisan db:seed` y verificar prompts
- ✅ Ejecutar `php artisan db:seed --force` (sin prompts)

---

## ✅ CHECKLIST FINAL (14:45 - 15:00)

### Verificaciones Pre-Commit

- [ ] **Migrations**:
  - [ ] Migration `recipe_cost_snapshots` ejecutada sin errores
  - [ ] Índices creados correctamente
  - [ ] Foreign keys funcionan

- [ ] **Models**:
  - [ ] `RecipeCostSnapshot` tiene todas las relaciones
  - [ ] Scopes funcionan correctamente
  - [ ] Casts correctos (decimal, array, datetime)

- [ ] **Services**:
  - [ ] `RecipeCostSnapshotService` crea snapshots correctamente
  - [ ] Threshold detection funciona (2%)
  - [ ] Snapshots masivos funcionan

- [ ] **Controllers**:
  - [ ] `implodeRecipeBom()` maneja recursión correctamente
  - [ ] Agrega ingredientes duplicados
  - [ ] Maneja loops infinitos (max depth 10)

- [ ] **Seeders**:
  - [ ] `CatalogosProductionSeeder` ejecuta sin errores
  - [ ] `RecipesProductionSeeder` ejecuta sin errores
  - [ ] No hay duplicados (updateOrInsert)

- [ ] **Tests**:
  - [ ] `RecipeCostSnapshotTest`: 5/5 pass
  - [ ] `RecipeBomImplosionTest`: 3/3 pass
  - [ ] `WeekendDeploymentIntegrationTest`: 3/3 pass
  - [ ] Cobertura >80%

- [ ] **Documentation**:
  - [ ] API_RECETAS.md actualizado con endpoint BOM implosion
  - [ ] Comentarios de código claros
  - [ ] Logs informativos en lugares clave

- [ ] **Code Quality**:
  - [ ] Laravel Pint ejecutado (`./vendor/bin/pint`)
  - [ ] No warnings de PHPStan (si aplica)
  - [ ] No console.log() olvidados

### Git Workflow

```bash
# 1. Verificar cambios
git status

# 2. Format código
./vendor/bin/pint

# 3. Ejecutar tests
php artisan test

# 4. Commit
git add .
git commit -m "feat(recipes): Add cost snapshots + BOM implosion

- Implement RecipeCostSnapshot model + migration
- Add RecipeCostSnapshotService with threshold detection (2%)
- Implement BOM implosion for composite recipes
- Add production seeders for Catalogs + Recipes
- Add feature tests (11/11 pass)
- Update API docs with new endpoints

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# 5. Push (si tienes rama separada)
git push origin feature/recipe-cost-snapshots
```

---

## 🔍 ERRORES COMUNES Y SOLUCIONES

### Error 1: Migration falla por FK constraint

**Síntoma**:
```
SQLSTATE[23503]: Foreign key violation
```

**Solución**:
```sql
-- Verificar que tabla padre existe
SELECT * FROM selemti.recipes LIMIT 1;

-- Verificar datos huérfanos
SELECT * FROM selemti.recipe_cost_snapshots
WHERE recipe_id NOT IN (SELECT id FROM selemti.recipes);
```

### Error 2: Recursión infinita en BOM implosion

**Síntoma**:
```
Maximum function nesting level reached
```

**Solución**:
- Verificar `if ($depth > 10)` está presente
- Verificar no hay ciclos: Receta A → Receta B → Receta A
- Agregar logging para debug:
```php
Log::debug('BOM implosion', ['recipe_id' => $recipeId, 'depth' => $depth]);
```

### Error 3: Snapshot no se crea automáticamente

**Síntoma**:
Costo cambia >2% pero no se crea snapshot.

**Solución**:
Verificar que `checkAndCreateIfThresholdExceeded()` se llama en los lugares correctos:
- Después de modificar ingredientes de receta
- Después de recibir inventario (cambio de precio)
- En job programado (cierre de día)

### Error 4: Tests fallan por falta de datos

**Síntoma**:
```
SQLSTATE[23503]: Foreign key violation: 7 ERROR:  insert or update on table "recipes" violates foreign key constraint
```

**Solución**:
Usar factories para crear datos relacionados:
```php
$recipe = Receta::factory()
    ->has(RecetaDetalle::factory()->count(3))
    ->create();
```

---

## 📊 MÉTRICAS DE ÉXITO

Al finalizar las 6 horas, debes tener:

| Métrica | Target | Verificación |
|---------|--------|--------------|
| Migrations ejecutadas | 1 | `\d selemti.recipe_cost_snapshots` |
| Models creados | 1 | `RecipeCostSnapshot` |
| Services creados | 1 | `RecipeCostSnapshotService` |
| Controller methods | 2 | `implodeRecipeBom()`, métodos privados |
| Seeders creados | 2 | `CatalogosProductionSeeder`, `RecipesProductionSeeder` |
| Feature tests | 3 archivos | 11 tests totales |
| Tests passing | 11/11 | `php artisan test` |
| API endpoints | 1 nuevo | `/api/recipes/{id}/bom/implode` |
| Docs actualizados | 1 | `API_RECETAS.md` |
| Code coverage | >80% | `php artisan test --coverage` |

---

## 🎯 DELIVERABLES FINALES

Al terminar las 6 horas, enviar mensaje en Slack con:

```
✅ BACKEND SATURDAY - COMPLETADO

📦 Commits pushed:
- feat(recipes): Add cost snapshots + BOM implosion

🧪 Tests:
- RecipeCostSnapshotTest: 5/5 ✅
- RecipeBomImplosionTest: 3/3 ✅
- WeekendDeploymentIntegrationTest: 3/3 ✅
- TOTAL: 11/11 PASS ✅

📊 Code coverage: 85%

🌱 Seeders ready for production:
- CatalogosProductionSeeder ✅
- RecipesProductionSeeder ✅

📄 Docs updated:
- API_RECETAS.md (endpoint BOM implosion) ✅

🚀 Ready for deployment!
```

---

## 🔗 REFERENCIAS

- **CLAUDE.md**: Arquitectura general del proyecto
- **API_RECETAS.md**: Especificaciones API de recetas
- **RecipeCostController.php**: Controlador existente de costos
- **Laravel Docs - Testing**: https://laravel.com/docs/11.x/testing
- **PostgreSQL JSON**: https://www.postgresql.org/docs/9.5/datatype-json.html

---

**Fecha**: 31 de octubre de 2025
**Creado por**: Claude Code
**Para**: GitHub Copilot Agent (Codex)
**Ejecución**: Sábado 1 de noviembre 2025, 09:00-15:00
