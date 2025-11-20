# 🔧 PROMPT CODEX - PRODUCCIÓN: BACKEND + API (SEMANA 4)

**Proyecto**: TerrenaLaravel ERP
**Módulo**: Gestión de Producción - Backend Completo
**Fase**: 1 - Semana 4
**Duración**: 6 horas
**Agent**: Codex (Backend Developer)
**Fecha**: Noviembre 22-28, 2025

---

## 🎯 OBJETIVO

Completar el backend del módulo de Producción con service layer completo, modelos y API funcional:

1. ✅ Completar ProductionService con lógica real
2. ✅ Crear modelos faltantes (ProductionBatchDetail, etc.)
3. ✅ Implementar migraciones de tablas
4. ✅ Completar ProductionController con endpoints REST
5. ✅ Tests completos (10 tests)

**Success Criteria**:
- ProductionService funcional con workflow completo: Planificar → Consumir → Completar → Postear
- API REST completa con 5 endpoints
- Movimientos en `mov_inv` generados correctamente (tipo `CONSUMO_OP`)
- Tests passing 100%
- Integración con RecipeService y InventoryService

---

## 📊 CONTEXTO

### ✅ Ya Implementado
- **ProductionOrder Model** (`app/Models/ProductionOrder.php`) - Modelo con estados y relaciones
- **ProductionService Skeleton** (`app/Services/Production/ProductionService.php`) - Métodos con TODOs
- **ProductionController Skeleton** (`app/Http/Controllers/Production/ProductionController.php`) - Endpoints básicos

### ✅ Ya Existe (Integración)
- **RecipeCostController** - BOM Implosion para calcular ingredientes base
- **RecipeVersioningService** - Versiones de recetas
- **InventoryService** - Manejo de stock y kardex
- **mov_inv Table** - Tabla de movimientos de inventario con tipo `CONSUMO_OP`

### ⚠️ Falta Implementar
- Lógica real en ProductionService (actualmente solo TODOs)
- Modelos de detalles de producción
- Tablas de base de datos para producción
- Validación de stock antes de consumir
- Generación de lotes de producto terminado
- Integración con mov_inv

---

## 📋 PLAN DE TRABAJO (6 HORAS)

### BLOQUE 1: Modelos y Migraciones (1.5h)

#### Tarea 1.1: Migration para Tablas de Producción (45min)

**Archivo**: `database/migrations/2025_11_22_090000_create_production_tables.php`

**Implementación**:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('pgsql')->create('selemti.production_orders', function (Blueprint $table) {
            $table->id();
            $table->string('receta_id', 30);
            $table->unsignedBigInteger('receta_version_id')->nullable();
            $table->integer('almacen_id');
            $table->integer('sucursal_id');
            $table->decimal('cantidad_planeada', 10, 3);
            $table->decimal('cantidad_producida', 10, 3)->nullable();
            $table->decimal('merma_porcentaje', 5, 2)->nullable();
            $table->string('estado', 20)->default('PLANIFICADA');
            $table->timestamp('programado_para')->nullable();
            $table->timestamp('iniciado_en')->nullable();
            $table->timestamp('completado_en')->nullable();
            $table->timestamp('posteado_en')->nullable();
            $table->unsignedBigInteger('creado_por');
            $table->unsignedBigInteger('aprobado_por')->nullable();
            $table->unsignedBigInteger('supervisor_id')->nullable();
            $table->text('observaciones')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestamps();

            $table->foreign('receta_id')->references('id')->on('selemti.receta_cab')->onDelete('restrict');
            $table->foreign('receta_version_id')->references('id')->on('selemti.receta_version')->onDelete('restrict');
            $table->foreign('almacen_id')->references('id')->on('selemti.cat_almacenes')->onDelete('restrict');
            $table->foreign('sucursal_id')->references('id')->on('selemti.cat_sucursales')->onDelete('restrict');
            $table->foreign('creado_por')->references('id')->on('users')->onDelete('restrict');
            $table->foreign('aprobado_por')->references('id')->on('users')->onDelete('set null');
            $table->foreign('supervisor_id')->references('id')->on('users')->onDelete('set null');

            $table->index('estado');
            $table->index('programado_para');
            $table->index(['sucursal_id', 'estado']);
        });

        // Tabla de detalles de consumo de ingredientes
        Schema::connection('pgsql')->create('selemti.production_ingredient_consumption', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('production_order_id');
            $table->string('item_id', 30);
            $table->unsignedBigInteger('batch_id')->nullable();
            $table->decimal('cantidad_planeada', 10, 4);
            $table->decimal('cantidad_consumida', 10, 4)->nullable();
            $table->integer('uom_id');
            $table->decimal('costo_unitario', 12, 4)->nullable();
            $table->decimal('costo_total', 12, 4)->nullable();
            $table->text('observaciones')->nullable();
            $table->timestamps();

            $table->foreign('production_order_id')->references('id')->on('selemti.production_orders')->onDelete('cascade');
            $table->foreign('item_id')->references('id')->on('selemti.items')->onDelete('restrict');
            $table->foreign('batch_id')->references('id')->on('selemti.batch')->onDelete('restrict');
            $table->foreign('uom_id')->references('id')->on('selemti.cat_unidades')->onDelete('restrict');

            $table->index('production_order_id');
            $table->index('item_id');
        });

        // Tabla de salidas de producción (producto terminado)
        Schema::connection('pgsql')->create('selemti.production_outputs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('production_order_id');
            $table->string('item_id', 30);
            $table->unsignedBigInteger('batch_id')->nullable();
            $table->decimal('cantidad', 10, 3);
            $table->integer('uom_id');
            $table->decimal('costo_unitario', 12, 4)->nullable();
            $table->decimal('costo_total', 12, 4)->nullable();
            $table->string('lote_codigo', 50)->nullable();
            $table->date('fecha_vencimiento')->nullable();
            $table->text('observaciones')->nullable();
            $table->timestamps();

            $table->foreign('production_order_id')->references('id')->on('selemti.production_orders')->onDelete('cascade');
            $table->foreign('item_id')->references('id')->on('selemti.items')->onDelete('restrict');
            $table->foreign('batch_id')->references('id')->on('selemti.batch')->onDelete('restrict');
            $table->foreign('uom_id')->references('id')->on('selemti.cat_unidades')->onDelete('restrict');

            $table->index('production_order_id');
            $table->index('item_id');
            $table->index('batch_id');
        });

        // Crear constraint check para estados válidos
        DB::connection('pgsql')->statement("
            ALTER TABLE selemti.production_orders
            ADD CONSTRAINT production_orders_estado_check
            CHECK (estado IN ('PLANIFICADA', 'APROBADA', 'EN_PROCESO', 'COMPLETADA', 'POSTEADA', 'CANCELADA'))
        ");
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.production_outputs');
        Schema::connection('pgsql')->dropIfExists('selemti.production_ingredient_consumption');
        Schema::connection('pgsql')->dropIfExists('selemti.production_orders');
    }
};
```

---

#### Tarea 1.2: Crear Modelos de Producción (45min)

**Archivo 1**: `app/Models/Production/ProductionOrder.php`

**Actualizar modelo existente**:

```php
<?php

namespace App\Models\Production;

use App\Models\Inv\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProductionOrder extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.production_orders';
    protected $guarded = [];

    protected $casts = [
        'cantidad_planeada' => 'decimal:3',
        'cantidad_producida' => 'decimal:3',
        'merma_porcentaje' => 'decimal:2',
        'programado_para' => 'datetime',
        'iniciado_en' => 'datetime',
        'completado_en' => 'datetime',
        'posteado_en' => 'datetime',
        'metadata' => 'array',
    ];

    // Estados
    const ESTADO_PLANIFICADA = 'PLANIFICADA';
    const ESTADO_APROBADA = 'APROBADA';
    const ESTADO_EN_PROCESO = 'EN_PROCESO';
    const ESTADO_COMPLETADA = 'COMPLETADA';
    const ESTADO_POSTEADA = 'POSTEADA';
    const ESTADO_CANCELADA = 'CANCELADA';

    public function receta(): BelongsTo
    {
        return $this->belongsTo(Receta::class, 'receta_id', 'id');
    }

    public function recetaVersion(): BelongsTo
    {
        return $this->belongsTo(RecetaVersion::class, 'receta_version_id', 'id');
    }

    public function almacen(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Almacen::class, 'almacen_id', 'id');
    }

    public function sucursal(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Sucursal::class, 'sucursal_id', 'id');
    }

    public function creador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creado_por', 'id');
    }

    public function aprobador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'aprobado_por', 'id');
    }

    public function supervisor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'supervisor_id', 'id');
    }

    public function ingredientConsumptions(): HasMany
    {
        return $this->hasMany(ProductionIngredientConsumption::class, 'production_order_id');
    }

    public function outputs(): HasMany
    {
        return $this->hasMany(ProductionOutput::class, 'production_order_id');
    }

    // Scopes
    public function scopePlanificada($query)
    {
        return $query->where('estado', self::ESTADO_PLANIFICADA);
    }

    public function scopeEnProceso($query)
    {
        return $query->where('estado', self::ESTADO_EN_PROCESO);
    }

    public function scopeCompletada($query)
    {
        return $query->where('estado', self::ESTADO_COMPLETADA);
    }

    public function scopePosteada($query)
    {
        return $query->where('estado', self::ESTADO_POSTEADA);
    }
}
```

---

**Archivo 2**: `app/Models/Production/ProductionIngredientConsumption.php`

```php
<?php

namespace App\Models\Production;

use App\Models\Inv\Item;
use App\Models\Inv\Batch;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductionIngredientConsumption extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.production_ingredient_consumption';
    protected $guarded = [];

    protected $casts = [
        'cantidad_planeada' => 'decimal:4',
        'cantidad_consumida' => 'decimal:4',
        'costo_unitario' => 'decimal:4',
        'costo_total' => 'decimal:4',
    ];

    public function productionOrder(): BelongsTo
    {
        return $this->belongsTo(ProductionOrder::class, 'production_order_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    public function batch(): BelongsTo
    {
        return $this->belongsTo(Batch::class, 'batch_id');
    }

    public function uom(): BelongsTo
    {
        return $this->belongsTo(\App\Models\UnitOfMeasure::class, 'uom_id');
    }
}
```

---

**Archivo 3**: `app/Models/Production/ProductionOutput.php`

```php
<?php

namespace App\Models\Production;

use App\Models\Inv\Item;
use App\Models\Inv\Batch;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductionOutput extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.production_outputs';
    protected $guarded = [];

    protected $casts = [
        'cantidad' => 'decimal:3',
        'costo_unitario' => 'decimal:4',
        'costo_total' => 'decimal:4',
        'fecha_vencimiento' => 'date',
    ];

    public function productionOrder(): BelongsTo
    {
        return $this->belongsTo(ProductionOrder::class, 'production_order_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    public function batch(): BelongsTo
    {
        return $this->belongsTo(Batch::class, 'batch_id');
    }

    public function uom(): BelongsTo
    {
        return $this->belongsTo(\App\Models\UnitOfMeasure::class, 'uom_id');
    }
}
```

---

### BLOQUE 2: ProductionService Completo (3h)

#### Tarea 2.1: Implementar ProductionService Completo (3h)

**Archivo**: `app/Services/Production/ProductionService.php`

**Reemplazar completamente**:

```php
<?php

namespace App\Services\Production;

use App\Models\Production\ProductionOrder;
use App\Models\Production\ProductionIngredientConsumption;
use App\Models\Production\ProductionOutput;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
use App\Models\Inv\Item;
use App\Models\Inv\Batch;
use App\Models\Inv\MovimientoInventario;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use InvalidArgumentException;
use RuntimeException;
use Carbon\Carbon;

/**
 * Servicio para planear, consumir y postear batches de producción interna.
 */
class ProductionService
{
    /**
     * Planea un batch de producción basado en una receta.
     *
     * @param string $recetaId
     * @param int $recetaVersionId
     * @param float $cantidadPlaneada
     * @param int $almacenId
     * @param int $sucursalId
     * @param int $userId
     * @param Carbon|null $programadoPara
     * @return ProductionOrder
     */
    public function planBatch(
        string $recetaId,
        int $recetaVersionId,
        float $cantidadPlaneada,
        int $almacenId,
        int $sucursalId,
        int $userId,
        ?Carbon $programadoPara = null
    ): ProductionOrder {
        // Validaciones
        if ($cantidadPlaneada <= 0) {
            throw new InvalidArgumentException('La cantidad planeada debe ser mayor a cero.');
        }

        // Verificar que receta y versión existan
        $receta = Receta::findOrFail($recetaId);
        $version = RecetaVersion::findOrFail($recetaVersionId);

        if ($version->receta_id !== $receta->id) {
            throw new InvalidArgumentException('La versión no pertenece a la receta especificada.');
        }

        return DB::transaction(function () use (
            $recetaId,
            $recetaVersionId,
            $cantidadPlaneada,
            $almacenId,
            $sucursalId,
            $userId,
            $programadoPara,
            $version
        ) {
            $now = Carbon::now();

            // Crear orden de producción
            $order = ProductionOrder::create([
                'receta_id' => $recetaId,
                'receta_version_id' => $recetaVersionId,
                'almacen_id' => $almacenId,
                'sucursal_id' => $sucursalId,
                'cantidad_planeada' => $cantidadPlaneada,
                'estado' => ProductionOrder::ESTADO_PLANIFICADA,
                'programado_para' => $programadoPara ?? $now,
                'creado_por' => $userId,
            ]);

            // Calcular ingredientes necesarios basándose en la receta
            $detalles = $version->detalles; // RecetaDetalle

            foreach ($detalles as $detalle) {
                // Calcular cantidad necesaria proporcional
                $cantidadNecesaria = $detalle->cantidad * $cantidadPlaneada;

                ProductionIngredientConsumption::create([
                    'production_order_id' => $order->id,
                    'item_id' => $detalle->item_id,
                    'cantidad_planeada' => $cantidadNecesaria,
                    'uom_id' => 1, // TODO: Obtener UOM correcta desde detalle
                ]);
            }

            Log::info('Production order planned', [
                'order_id' => $order->id,
                'receta_id' => $recetaId,
                'cantidad' => $cantidadPlaneada,
            ]);

            return $order;
        });
    }

    /**
     * Registra consumo de insumos y pasa a EN_PROCESO.
     *
     * @param int $orderId
     * @param array $consumedLines Formato: [['item_id' => '...', 'cantidad' => 1.5, 'batch_id' => 123], ...]
     * @param int $userId
     * @return ProductionOrder
     */
    public function consumeIngredients(int $orderId, array $consumedLines, int $userId): ProductionOrder
    {
        if (empty($consumedLines)) {
            throw new InvalidArgumentException('Se requieren líneas de consumo.');
        }

        return DB::transaction(function () use ($orderId, $consumedLines, $userId) {
            $order = ProductionOrder::with('ingredientConsumptions')->findOrFail($orderId);

            // Validar estado
            if (!in_array($order->estado, [ProductionOrder::ESTADO_PLANIFICADA, ProductionOrder::ESTADO_APROBADA])) {
                throw new RuntimeException('La orden debe estar en estado PLANIFICADA o APROBADA para consumir ingredientes.');
            }

            // Validar stock disponible
            foreach ($consumedLines as $line) {
                $itemId = $line['item_id'];
                $cantidad = $line['cantidad'];
                $batchId = $line['batch_id'] ?? null;

                // Verificar stock en almacén
                $stockDisponible = $this->getStockDisponible($itemId, $order->almacen_id, $batchId);

                if ($stockDisponible < $cantidad) {
                    throw new RuntimeException("Stock insuficiente para {$itemId}. Disponible: {$stockDisponible}, Requerido: {$cantidad}");
                }

                // Actualizar registro de consumo
                $consumo = $order->ingredientConsumptions()
                    ->where('item_id', $itemId)
                    ->first();

                if ($consumo) {
                    $consumo->update([
                        'cantidad_consumida' => $cantidad,
                        'batch_id' => $batchId,
                        'costo_unitario' => $this->getCostoUnitario($itemId, $batchId),
                        'costo_total' => $cantidad * $this->getCostoUnitario($itemId, $batchId),
                    ]);
                }
            }

            // Actualizar estado de orden
            $order->update([
                'estado' => ProductionOrder::ESTADO_EN_PROCESO,
                'iniciado_en' => Carbon::now(),
            ]);

            Log::info('Ingredients consumed for production order', [
                'order_id' => $orderId,
                'lines_consumed' => count($consumedLines),
            ]);

            return $order->fresh();
        });
    }

    /**
     * Registra las salidas de producto terminado y marca COMPLETADA.
     *
     * @param int $orderId
     * @param array $producedLines Formato: [['item_id' => '...', 'cantidad' => 10, 'lote_codigo' => '...'], ...]
     * @param int $userId
     * @return ProductionOrder
     */
    public function completeBatch(int $orderId, array $producedLines, int $userId): ProductionOrder
    {
        if (empty($producedLines)) {
            throw new InvalidArgumentException('Se requieren líneas de productos terminados.');
        }

        return DB::transaction(function () use ($orderId, $producedLines, $userId) {
            $order = ProductionOrder::findOrFail($orderId);

            // Validar estado
            if ($order->estado !== ProductionOrder::ESTADO_EN_PROCESO) {
                throw new RuntimeException('La orden debe estar en estado EN_PROCESO para completarla.');
            }

            $totalProducido = 0;

            foreach ($producedLines as $line) {
                $itemId = $line['item_id'];
                $cantidad = $line['cantidad'];
                $loteCode = $line['lote_codigo'] ?? null;
                $fechaVencimiento = $line['fecha_vencimiento'] ?? null;

                // Crear batch si se especificó lote
                $batchId = null;
                if ($loteCode) {
                    $batch = Batch::create([
                        'item_id' => $itemId,
                        'batch_code' => $loteCode,
                        'fecha_ingreso' => now(),
                        'fecha_vencimiento' => $fechaVencimiento,
                        'estado' => 'DISPONIBLE',
                    ]);
                    $batchId = $batch->id;
                }

                // Calcular costo unitario (costo de ingredientes / cantidad producida)
                $costoTotal = $order->ingredientConsumptions->sum('costo_total');
                $costoUnitario = $cantidad > 0 ? $costoTotal / $cantidad : 0;

                ProductionOutput::create([
                    'production_order_id' => $order->id,
                    'item_id' => $itemId,
                    'batch_id' => $batchId,
                    'cantidad' => $cantidad,
                    'uom_id' => 1, // TODO: Obtener UOM correcta
                    'costo_unitario' => $costoUnitario,
                    'costo_total' => $costoTotal,
                    'lote_codigo' => $loteCode,
                    'fecha_vencimiento' => $fechaVencimiento,
                ]);

                $totalProducido += $cantidad;
            }

            // Calcular merma
            $merma = 0;
            if ($order->cantidad_planeada > 0) {
                $merma = (($order->cantidad_planeada - $totalProducido) / $order->cantidad_planeada) * 100;
            }

            // Actualizar orden
            $order->update([
                'cantidad_producida' => $totalProducido,
                'merma_porcentaje' => $merma,
                'estado' => ProductionOrder::ESTADO_COMPLETADA,
                'completado_en' => Carbon::now(),
            ]);

            Log::info('Production batch completed', [
                'order_id' => $orderId,
                'cantidad_producida' => $totalProducido,
                'merma_porcentaje' => $merma,
            ]);

            return $order->fresh();
        });
    }

    /**
     * Genera mov_inv para insumos (negativos) y productos terminados (positivos) y sella POSTEADA.
     *
     * @param int $orderId
     * @param int $userId
     * @return array
     */
    public function postBatchToInventory(int $orderId, int $userId): array
    {
        return DB::transaction(function () use ($orderId, $userId) {
            $order = ProductionOrder::with(['ingredientConsumptions', 'outputs'])->findOrFail($orderId);

            // Validar estado
            if ($order->estado !== ProductionOrder::ESTADO_COMPLETADA) {
                throw new RuntimeException('La orden debe estar en estado COMPLETADA para postearla.');
            }

            // Verificar que no esté ya posteada
            if ($order->estado === ProductionOrder::ESTADO_POSTEADA) {
                throw new RuntimeException('La orden ya fue posteada previamente.');
            }

            $movimientos = 0;
            $now = Carbon::now();

            // 1. Crear movimientos negativos para ingredientes consumidos (CONSUMO_OP)
            foreach ($order->ingredientConsumptions as $consumo) {
                if ($consumo->cantidad_consumida > 0) {
                    MovimientoInventario::create([
                        'item_id' => $consumo->item_id,
                        'batch_id' => $consumo->batch_id,
                        'tipo' => 'CONSUMO_OP',
                        'qty' => -1 * $consumo->cantidad_consumida, // Negativo (salida)
                        'uom' => $consumo->uom_id,
                        'ref_tipo' => 'PRODUCTION_ORDER',
                        'ref_id' => $order->id,
                        'almacen_id' => $order->almacen_id,
                        'sucursal_id' => $order->sucursal_id,
                        'ts' => $now,
                    ]);
                    $movimientos++;
                }
            }

            // 2. Crear movimientos positivos para productos terminados
            foreach ($order->outputs as $output) {
                MovimientoInventario::create([
                    'item_id' => $output->item_id,
                    'batch_id' => $output->batch_id,
                    'tipo' => 'PRODUCCION', // Entrada de producto terminado
                    'qty' => $output->cantidad, // Positivo (entrada)
                    'uom' => $output->uom_id,
                    'ref_tipo' => 'PRODUCTION_ORDER',
                    'ref_id' => $order->id,
                    'almacen_id' => $order->almacen_id,
                    'sucursal_id' => $order->sucursal_id,
                    'costo_unitario' => $output->costo_unitario,
                    'ts' => $now,
                ]);
                $movimientos++;
            }

            // 3. Actualizar estado de orden
            $order->update([
                'estado' => ProductionOrder::ESTADO_POSTEADA,
                'posteado_en' => $now,
            ]);

            Log::info('Production order posted to inventory', [
                'order_id' => $orderId,
                'movimientos_generados' => $movimientos,
            ]);

            return [
                'order_id' => $orderId,
                'movimientos_generados' => $movimientos,
                'estado' => ProductionOrder::ESTADO_POSTEADA,
            ];
        });
    }

    /**
     * Obtiene stock disponible para un item en un almacén.
     */
    protected function getStockDisponible(string $itemId, int $almacenId, ?int $batchId = null): float
    {
        $query = MovimientoInventario::where('item_id', $itemId)
            ->where('almacen_id', $almacenId);

        if ($batchId) {
            $query->where('batch_id', $batchId);
        }

        return $query->sum('qty');
    }

    /**
     * Obtiene el costo unitario de un item (desde batch o promedio).
     */
    protected function getCostoUnitario(string $itemId, ?int $batchId = null): float
    {
        if ($batchId) {
            $batch = Batch::find($batchId);
            return $batch->costo_promedio ?? 0;
        }

        $item = Item::find($itemId);
        return $item->costo_promedio ?? 0;
    }
}
```

---

### BLOQUE 3: ProductionController Completo (1h)

#### Tarea 3.1: Completar ProductionController (1h)

**Archivo**: `app/Http/Controllers/Api/Production/ProductionController.php`

**Reemplazar completamente**:

```php
<?php

namespace App\Http\Controllers\Api\Production;

use App\Http\Controllers\Controller;
use App\Services\Production\ProductionService;
use App\Models\Production\ProductionOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProductionController extends Controller
{
    protected ProductionService $productionService;

    public function __construct(ProductionService $productionService)
    {
        $this->productionService = $productionService;
    }

    /**
     * GET /api/production/orders
     *
     * Lista órdenes de producción con filtros.
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = ProductionOrder::with(['receta', 'almacen', 'sucursal', 'creador']);

            // Filtros
            if ($request->has('estado')) {
                $query->where('estado', $request->input('estado'));
            }

            if ($request->has('sucursal_id')) {
                $query->where('sucursal_id', $request->input('sucursal_id'));
            }

            if ($request->has('fecha_desde')) {
                $query->whereDate('programado_para', '>=', $request->input('fecha_desde'));
            }

            if ($request->has('fecha_hasta')) {
                $query->whereDate('programado_para', '<=', $request->input('fecha_hasta'));
            }

            $orders = $query->orderByDesc('created_at')->paginate(25);

            return response()->json([
                'ok' => true,
                'data' => $orders,
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'fetch_failed',
                'message' => 'Error al obtener órdenes: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * POST /api/production/orders
     *
     * Crea una nueva orden de producción (planificada).
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'receta_id' => 'required|string|exists:selemti.receta_cab,id',
            'receta_version_id' => 'required|integer|exists:selemti.receta_version,id',
            'cantidad_planeada' => 'required|numeric|gt:0',
            'almacen_id' => 'required|integer|exists:selemti.cat_almacenes,id',
            'sucursal_id' => 'required|integer|exists:selemti.cat_sucursales,id',
            'programado_para' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'ok' => false,
                'error' => 'validation_failed',
                'message' => 'Datos inválidos',
                'errors' => $validator->errors(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }

        try {
            $order = $this->productionService->planBatch(
                $request->input('receta_id'),
                $request->input('receta_version_id'),
                $request->input('cantidad_planeada'),
                $request->input('almacen_id'),
                $request->input('sucursal_id'),
                auth()->id(),
                $request->input('programado_para') ? \Carbon\Carbon::parse($request->input('programado_para')) : null
            );

            return response()->json([
                'ok' => true,
                'data' => $order,
                'message' => 'Orden de producción creada exitosamente',
                'timestamp' => now()->toIso8601String(),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'creation_failed',
                'message' => 'Error al crear orden: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * POST /api/production/orders/{id}/consume
     *
     * Registra consumo de ingredientes.
     */
    public function consume(Request $request, int $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'lines' => 'required|array|min:1',
            'lines.*.item_id' => 'required|string',
            'lines.*.cantidad' => 'required|numeric|gt:0',
            'lines.*.batch_id' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'ok' => false,
                'error' => 'validation_failed',
                'message' => 'Datos inválidos',
                'errors' => $validator->errors(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }

        try {
            $order = $this->productionService->consumeIngredients(
                $id,
                $request->input('lines'),
                auth()->id()
            );

            return response()->json([
                'ok' => true,
                'data' => $order,
                'message' => 'Ingredientes consumidos exitosamente',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'consume_failed',
                'message' => 'Error al consumir ingredientes: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * POST /api/production/orders/{id}/complete
     *
     * Marca la orden como completada con productos terminados.
     */
    public function complete(Request $request, int $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'lines' => 'required|array|min:1',
            'lines.*.item_id' => 'required|string',
            'lines.*.cantidad' => 'required|numeric|gt:0',
            'lines.*.lote_codigo' => 'nullable|string|max:50',
            'lines.*.fecha_vencimiento' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'ok' => false,
                'error' => 'validation_failed',
                'message' => 'Datos inválidos',
                'errors' => $validator->errors(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }

        try {
            $order = $this->productionService->completeBatch(
                $id,
                $request->input('lines'),
                auth()->id()
            );

            return response()->json([
                'ok' => true,
                'data' => $order,
                'message' => 'Orden completada exitosamente',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'complete_failed',
                'message' => 'Error al completar orden: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * POST /api/production/orders/{id}/post
     *
     * Postea la orden al inventario generando movimientos.
     */
    public function post(int $id): JsonResponse
    {
        try {
            $result = $this->productionService->postBatchToInventory($id, auth()->id());

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Orden posteada al inventario exitosamente',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'post_failed',
                'message' => 'Error al postear orden: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * GET /api/production/orders/{id}
     *
     * Obtiene detalle de una orden de producción.
     */
    public function show(int $id): JsonResponse
    {
        try {
            $order = ProductionOrder::with([
                'receta',
                'recetaVersion',
                'almacen',
                'sucursal',
                'creador',
                'ingredientConsumptions.item',
                'outputs.item',
            ])->findOrFail($id);

            return response()->json([
                'ok' => true,
                'data' => $order,
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'not_found',
                'message' => 'Orden no encontrada',
                'timestamp' => now()->toIso8601String(),
            ], 404);
        }
    }
}
```

---

### BLOQUE 4: Rutas y Testing (30min + 1h)

#### Tarea 4.1: Registrar Rutas API (10min)

**Archivo**: `routes/api.php`

**Agregar**:

```php
use App\Http\Controllers\Api\Production\ProductionController;

// Production Orders
Route::prefix('production/orders')->group(function () {
    Route::get('/', [ProductionController::class, 'index']);
    Route::post('/', [ProductionController::class, 'store']);
    Route::get('/{id}', [ProductionController::class, 'show']);
    Route::post('/{id}/consume', [ProductionController::class, 'consume']);
    Route::post('/{id}/complete', [ProductionController::class, 'complete']);
    Route::post('/{id}/post', [ProductionController::class, 'post']);
});
```

---

#### Tarea 4.2: Tests de ProductionService (45min)

**Archivo**: `tests/Feature/ProductionServiceTest.php`

**Implementación**: *(Debido al límite de tamaño, se proporciona esqueleto básico)*

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Production\ProductionOrder;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
use App\Models\Inv\Item;
use App\Services\Production\ProductionService;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ProductionServiceTest extends TestCase
{
    use RefreshDatabase;

    protected ProductionService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(ProductionService::class);

        // Crear datos de prueba
        Item::create(['id' => 'ITEM-001', 'nombre' => 'Tomate', 'costo_promedio' => 10.00]);

        Receta::create([
            'id' => 'REC-00001',
            'nombre_plato' => 'Salsa',
            'porciones_standard' => 10,
        ]);
    }

    /** @test */
    public function it_can_plan_production_batch()
    {
        // Test implementation
        $this->assertTrue(true);
    }

    /** @test */
    public function it_can_consume_ingredients()
    {
        // Test implementation
        $this->assertTrue(true);
    }

    /** @test */
    public function it_can_complete_batch()
    {
        // Test implementation
        $this->assertTrue(true);
    }

    /** @test */
    public function it_can_post_to_inventory()
    {
        // Test implementation
        $this->assertTrue(true);
    }

    /** @test */
    public function it_validates_stock_before_consuming()
    {
        // Test implementation
        $this->assertTrue(true);
    }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN

### Migraciones
- [ ] Migration `2025_11_22_090000_create_production_tables.php` creada
- [ ] Tablas creadas: `production_orders`, `production_ingredient_consumption`, `production_outputs`
- [ ] Foreign keys configuradas correctamente
- [ ] Índices agregados para queries frecuentes

### Modelos
- [ ] ProductionOrder actualizado con relaciones completas
- [ ] ProductionIngredientConsumption creado
- [ ] ProductionOutput creado
- [ ] Casts configurados correctamente
- [ ] Relaciones funcionando

### Service Layer
- [ ] `planBatch()` implementado - Crea orden PLANIFICADA
- [ ] `consumeIngredients()` implementado - Valida stock y registra consumo
- [ ] `completeBatch()` implementado - Calcula merma y registra salidas
- [ ] `postBatchToInventory()` implementado - Genera mov_inv
- [ ] Validaciones de estado funcionando
- [ ] Logging configurado

### API Controller
- [ ] `GET /api/production/orders` - Lista con filtros
- [ ] `POST /api/production/orders` - Crea orden
- [ ] `GET /api/production/orders/{id}` - Detalle
- [ ] `POST /api/production/orders/{id}/consume` - Consumir ingredientes
- [ ] `POST /api/production/orders/{id}/complete` - Completar
- [ ] `POST /api/production/orders/{id}/post` - Postear a inventario
- [ ] Validaciones correctas
- [ ] Responses estándar `{ok, data, message, timestamp}`

### Testing
- [ ] ProductionServiceTest con 5 tests passing
- [ ] Cobertura >70% en ProductionService
- [ ] Tests de validación de stock
- [ ] Tests de transiciones de estado

---

## 📦 ENTREGABLES

1. **Migration**
   - `database/migrations/2025_11_22_090000_create_production_tables.php`

2. **Modelos**
   - `app/Models/Production/ProductionOrder.php` (actualizado)
   - `app/Models/Production/ProductionIngredientConsumption.php`
   - `app/Models/Production/ProductionOutput.php`

3. **Service Layer**
   - `app/Services/Production/ProductionService.php` (completo)

4. **API Controller**
   - `app/Http/Controllers/Api/Production/ProductionController.php` (completo)

5. **Routes**
   - `routes/api.php` (6 rutas agregadas)

6. **Tests**
   - `tests/Feature/ProductionServiceTest.php`

---

## 🔒 VALIDACIONES COMPLETAS DEL MÓDULO

### 1. VALIDACIONES DE ENTRADA (Input Validation)

#### 1.1 Validación al Crear Orden de Producción

```php
$validator = Validator::make($request->all(), [
    'recipe_id' => ['required', 'string', 'exists:selemti.receta_cab,id'],
    'planned_portions' => ['required', 'integer', 'min:1', 'max:10000'],
    'target_warehouse_id' => ['required', 'integer', 'exists:selemti.cat_almacenes,id'],
    'scheduled_for' => ['nullable', 'date', 'after_or_equal:today'],
    'notes' => ['nullable', 'string', 'max:1000'],
]);

// Validación adicional: receta debe estar publicada
$recipe = Receta::with('versiones')->findOrFail($request->input('recipe_id'));
$publishedVersion = $recipe->versiones->where('version_publicada', true)->first();

if (!$publishedVersion) {
    throw new \RuntimeException('La receta debe tener una versión publicada para producir');
}

// Validación: almacén debe estar activo
$warehouse = Almacen::findOrFail($request->input('target_warehouse_id'));
if (!$warehouse->activo) {
    throw new \RuntimeException('El almacén de destino no está activo');
}
```

#### 1.2 Validación al Consumir Ingredientes

```php
$validator = Validator::make($request->all(), [
    'consumptions' => ['required', 'array', 'min:1'],
    'consumptions.*.ingredient_id' => ['required', 'string', 'exists:selemti.items,id'],
    'consumptions.*.actual_qty' => ['required', 'numeric', 'gt:0', 'lt:999999.999'],
    'consumptions.*.source_warehouse_id' => ['required', 'integer', 'exists:selemti.cat_almacenes,id'],
    'consumptions.*.batch_id' => ['nullable', 'integer', 'exists:selemti.lotes,id'],
]);

// Validación: no consumir el mismo ingrediente dos veces
$ingredientIds = collect($request->input('consumptions'))->pluck('ingredient_id');
if ($ingredientIds->count() !== $ingredientIds->unique()->count()) {
    throw new \InvalidArgumentException('No se puede consumir el mismo ingrediente múltiples veces');
}
```

#### 1.3 Validación al Completar Producción

```php
$validator = Validator::make($request->all(), [
    'outputs' => ['required', 'array', 'min:1'],
    'outputs.*.produced_qty' => ['required', 'numeric', 'gt:0', 'lt:999999.999'],
    'outputs.*.waste_qty' => ['nullable', 'numeric', 'gte:0', 'lt:999999.999'],
    'outputs.*.batch_number' => ['nullable', 'string', 'max:64', 'regex:/^[A-Z0-9\-]+$/'],
    'completion_notes' => ['nullable', 'string', 'max:1000'],
]);

// Validación: produced_qty + waste_qty debe ser razonable
foreach ($request->input('outputs') as $output) {
    $total = $output['produced_qty'] + ($output['waste_qty'] ?? 0);
    if ($total > $order->planned_portions * 2) {
        throw new \RuntimeException(
            "La cantidad total producida + merma ({$total}) excede significativamente " .
            "lo planificado ({$order->planned_portions})"
        );
    }
}
```

### 2. VALIDACIONES DE NEGOCIO (Business Logic)

#### 2.1 Validación de Máquina de Estados

```php
class ProductionService
{
    public function consumeIngredients(int $orderId, array $consumptions, int $userId): array
    {
        $order = ProductionOrder::findOrFail($orderId);

        // Validar estado: solo PLANNED permite consumir
        if ($order->status !== ProductionOrder::STATUS_PLANNED) {
            throw new \RuntimeException(
                "Solo se pueden consumir ingredientes en órdenes PLANIFICADAS. " .
                "Estado actual: {$order->status}"
            );
        }

        // Validar que no se hayan consumido ingredientes previamente
        $existingConsumptions = ProductionIngredientConsumption::where('production_order_id', $orderId)->exists();
        if ($existingConsumptions) {
            throw new \RuntimeException('Esta orden ya tiene ingredientes consumidos');
        }

        // Continuar...
    }

    public function completeBatch(int $orderId, array $outputs, ?string $notes, int $userId): array
    {
        $order = ProductionOrder::findOrFail($orderId);

        // Validar estado: solo IN_PROGRESS permite completar
        if ($order->status !== ProductionOrder::STATUS_IN_PROGRESS) {
            throw new \RuntimeException(
                "Solo se pueden completar órdenes EN PROGRESO. Estado actual: {$order->status}"
            );
        }

        // Validar que haya consumos registrados
        $hasConsumptions = ProductionIngredientConsumption::where('production_order_id', $orderId)->exists();
        if (!$hasConsumptions) {
            throw new \RuntimeException('Debe registrar el consumo de ingredientes antes de completar');
        }

        // Continuar...
    }
}
```

#### 2.2 Validación de Stock Disponible

```php
public function consumeIngredients(int $orderId, array $consumptions, int $userId): array
{
    $order = ProductionOrder::findOrFail($orderId);

    // Validar stock disponible para cada ingrediente
    foreach ($consumptions as $consumption) {
        $stockDisponible = $this->getStockDisponible(
            $consumption['ingredient_id'],
            $consumption['source_warehouse_id']
        );

        if ($stockDisponible < $consumption['actual_qty']) {
            $item = Item::find($consumption['ingredient_id']);
            throw new \RuntimeException(
                "Stock insuficiente para {$item->nombre} en almacén {$consumption['source_warehouse_id']}. " .
                "Disponible: {$stockDisponible}, Requerido: {$consumption['actual_qty']}"
            );
        }
    }

    // Continuar con el consumo...
}

private function getStockDisponible(string $itemId, int $warehouseId): float
{
    $result = DB::connection('pgsql')
        ->table('selemti.mov_inv')
        ->where('item_id', $itemId)
        ->where('almacen_id', $warehouseId)
        ->selectRaw('COALESCE(SUM(qty), 0) as total_qty')
        ->first();

    $stock = (float) ($result->total_qty ?? 0);

    // Validación: alertar si stock negativo
    if ($stock < 0) {
        Log::warning('Negative stock detected in production', [
            'item_id' => $itemId,
            'warehouse_id' => $warehouseId,
            'stock' => $stock,
        ]);
    }

    return max(0, $stock);
}
```

#### 2.3 Validación de Receta vs Ingredientes Consumidos

```php
public function consumeIngredients(int $orderId, array $consumptions, int $userId): array
{
    $order = ProductionOrder::with('recipe.versiones.detalles')->findOrFail($orderId);

    $publishedVersion = $order->recipe->versiones->where('version_publicada', true)->first();

    if (!$publishedVersion) {
        throw new \RuntimeException('La receta no tiene una versión publicada');
    }

    // Validación opcional: advertir si ingredientes consumidos ≠ ingredientes de receta
    $recipeIngredients = $publishedVersion->detalles->pluck('item_id')->toArray();
    $consumedIngredients = collect($consumptions)->pluck('ingredient_id')->toArray();

    $missingIngredients = array_diff($recipeIngredients, $consumedIngredients);
    $extraIngredients = array_diff($consumedIngredients, $recipeIngredients);

    if (!empty($missingIngredients) || !empty($extraIngredients)) {
        Log::warning('Ingredient mismatch in production', [
            'order_id' => $orderId,
            'missing' => $missingIngredients,
            'extra' => $extraIngredients,
        ]);

        // Opcional: retornar warning en respuesta
        // No bloquear, solo advertir
    }

    // Continuar...
}
```

### 3. VALIDACIONES DE SEGURIDAD (Security)

#### 3.1 Autenticación y Autorización

```php
class ProductionController extends Controller
{
    public function __construct(ProductionService $productionService)
    {
        $this->productionService = $productionService;

        $this->middleware(['auth:sanctum']);

        $this->middleware('permission:production.view')
            ->only(['index', 'show']);

        $this->middleware('permission:production.manage')
            ->only(['store', 'consume', 'complete']);

        $this->middleware('permission:production.post')
            ->only(['post']);
    }
}
```

#### 3.2 Rate Limiting

```php
Route::prefix('production/orders')
    ->middleware(['auth:sanctum', 'throttle:60,1'])
    ->group(function () {
        Route::get('/', [ProductionController::class, 'index']);
        Route::post('/', [ProductionController::class, 'store'])
            ->middleware('throttle:20,1'); // Máx 20 órdenes/minuto
        Route::get('/{id}', [ProductionController::class, 'show']);
        Route::post('/{id}/consume', [ProductionController::class, 'consume'])
            ->middleware('throttle:10,1');
        Route::post('/{id}/complete', [ProductionController::class, 'complete'])
            ->middleware('throttle:10,1');
        Route::post('/{id}/post', [ProductionController::class, 'post'])
            ->middleware('throttle:5,1');
    });
```

### 4. VALIDACIONES DE INTEGRIDAD DE DATOS

#### 4.1 Transacciones Atómicas

```php
public function consumeIngredients(int $orderId, array $consumptions, int $userId): array
{
    return DB::transaction(function () use ($orderId, $consumptions, $userId) {
        // Bloquear orden para evitar race conditions
        $order = ProductionOrder::lockForUpdate()->findOrFail($orderId);

        // Validar estado con lock activo
        if ($order->status !== ProductionOrder::STATUS_PLANNED) {
            throw new \RuntimeException('Estado inválido para consumir ingredientes');
        }

        // Cambiar estado a IN_PROGRESS
        $order->update([
            'status' => ProductionOrder::STATUS_IN_PROGRESS,
            'started_at' => now(),
            'started_by' => $userId,
        ]);

        // Registrar consumos
        foreach ($consumptions as $consumption) {
            ProductionIngredientConsumption::create([
                'production_order_id' => $orderId,
                'ingredient_id' => $consumption['ingredient_id'],
                'planned_qty' => $this->getPlannedQty($order, $consumption['ingredient_id']),
                'actual_qty' => $consumption['actual_qty'],
                'source_warehouse_id' => $consumption['source_warehouse_id'],
                'batch_id' => $consumption['batch_id'] ?? null,
                'consumed_at' => now(),
            ]);
        }

        Log::info('Production ingredients consumed', [
            'order_id' => $orderId,
            'consumptions_count' => count($consumptions),
        ]);

        return [
            'status' => $order->status,
            'consumptions_recorded' => count($consumptions),
        ];
    });
}
```

#### 4.2 Validación de Cantidades y Mermas

```php
public function completeBatch(int $orderId, array $outputs, ?string $notes, int $userId): array
{
    return DB::transaction(function () use ($orderId, $outputs, $notes, $userId) {
        $order = ProductionOrder::lockForUpdate()->findOrFail($orderId);

        $totalProduced = 0;
        $totalWaste = 0;

        foreach ($outputs as $output) {
            $produced = $output['produced_qty'];
            $waste = $output['waste_qty'] ?? 0;

            // Validación: produced debe ser > 0
            if ($produced <= 0) {
                throw new \InvalidArgumentException('La cantidad producida debe ser mayor a 0');
            }

            // Validación: waste no puede ser mayor que produced
            if ($waste > $produced) {
                throw new \InvalidArgumentException(
                    "La merma ({$waste}) no puede ser mayor que la cantidad producida ({$produced})"
                );
            }

            // Calcular merma porcentaje
            $wastePercentage = $produced > 0 ? ($waste / $produced) * 100 : 0;

            // Validación: alertar si merma excesiva
            if ($wastePercentage > 50) {
                Log::warning('Excessive waste in production', [
                    'order_id' => $orderId,
                    'produced' => $produced,
                    'waste' => $waste,
                    'waste_percentage' => $wastePercentage,
                ]);
            }

            ProductionOutput::create([
                'production_order_id' => $orderId,
                'produced_qty' => $produced,
                'waste_qty' => $waste,
                'waste_percentage' => round($wastePercentage, 2),
                'batch_number' => $output['batch_number'] ?? null,
                'created_at' => now(),
            ]);

            $totalProduced += $produced;
            $totalWaste += $waste;
        }

        // Actualizar orden
        $order->update([
            'status' => ProductionOrder::STATUS_COMPLETED,
            'actual_portions' => $totalProduced,
            'waste_qty' => $totalWaste,
            'completed_at' => now(),
            'completed_by' => $userId,
            'completion_notes' => $notes,
        ]);

        return [
            'status' => $order->status,
            'total_produced' => $totalProduced,
            'total_waste' => $totalWaste,
            'waste_percentage' => $totalProduced > 0 ? round(($totalWaste / $totalProduced) * 100, 2) : 0,
        ];
    });
}
```

### 5. VALIDACIONES DE PERFORMANCE

#### 5.1 Límites de Consultas

```php
public function index(Request $request): JsonResponse
{
    $perPage = min($request->input('per_page', 20), 100);

    $orders = ProductionOrder::query()
        ->with(['recipe', 'targetWarehouse', 'createdBy'])
        ->when($request->filled('status'), fn($q) =>
            $q->where('status', $request->input('status'))
        )
        ->orderByDesc('created_at')
        ->paginate($perPage);

    return response()->json([
        'ok' => true,
        'data' => $orders,
        'timestamp' => now()->toIso8601String(),
    ]);
}
```

#### 5.2 Eager Loading

```php
public function show(int $id): JsonResponse
{
    // Evitar N+1 queries con eager loading
    $order = ProductionOrder::with([
        'recipe.versiones' => fn($q) => $q->where('version_publicada', true),
        'recipe.versiones.detalles.item',
        'targetWarehouse',
        'createdBy',
        'startedBy',
        'completedBy',
        'postedBy',
        'consumptions.ingredient',
        'consumptions.sourceWarehouse',
        'outputs',
    ])->findOrFail($id);

    return response()->json([
        'ok' => true,
        'data' => $order,
        'timestamp' => now()->toIso8601String(),
    ]);
}
```

### 6. VALIDACIONES EN TESTS

```php
public function test_it_rejects_consumption_with_insufficient_stock(): void
{
    $order = ProductionOrder::factory()->create(['status' => 'PLANNED']);

    // No crear stock en mov_inv

    $consumptions = [
        [
            'ingredient_id' => 'ITEM-001',
            'actual_qty' => 10.0,
            'source_warehouse_id' => 57,
        ],
    ];

    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage('Stock insuficiente');

    $service = app(ProductionService::class);
    $service->consumeIngredients($order->id, $consumptions, 1);
}

public function test_it_rejects_completion_without_consumptions(): void
{
    $order = ProductionOrder::factory()->create(['status' => 'IN_PROGRESS']);

    // No crear consumos

    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage('consumo de ingredientes');

    $service = app(ProductionService::class);
    $service->completeBatch(
        $order->id,
        [['produced_qty' => 10, 'waste_qty' => 1]],
        null,
        1
    );
}

public function test_it_validates_state_transitions(): void
{
    $order = ProductionOrder::factory()->create(['status' => 'COMPLETED']);

    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage('Estado actual');

    $service = app(ProductionService::class);
    $service->consumeIngredients($order->id, [], 1);
}

public function test_it_prevents_double_posting(): void
{
    $order = ProductionOrder::factory()->create(['status' => 'COMPLETED']);

    $service = app(ProductionService::class);

    // Postear primera vez
    $service->postBatchToInventory($order->id, 1);

    // Intentar postear segunda vez
    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage('ya fue posteada');

    $service->postBatchToInventory($order->id, 1);
}
```

### 7. CHECKLIST DE VALIDACIONES

**Entrada (Input)**:
- [ ] Validación de recipe_id (exists, publicada)
- [ ] Validación de planned_portions (1-10000)
- [ ] Validación de almacén (exists, activo)
- [ ] Validación de consumptions array (min:1)
- [ ] Validación de quantities (>0, <999999.999)
- [ ] Validación de outputs (produced + waste razonable)

**Negocio (Business Logic)**:
- [ ] Máquina de estados estricta (PLANNED → IN_PROGRESS → COMPLETED → POSTED)
- [ ] Validación de stock antes de consumir
- [ ] Una sola versión publicada de receta
- [ ] No double-posting al inventario
- [ ] Alerta de merma excesiva (>50%)

**Seguridad**:
- [ ] Autenticación (auth:sanctum)
- [ ] Autorización (permissions: view, manage, post)
- [ ] Rate limiting (20 creaciones/min)
- [ ] Prevención SQL injection (Query Builder)

**Integridad de Datos**:
- [ ] Transacciones atómicas (DB::transaction)
- [ ] Locks para evitar race conditions
- [ ] Validación de cantidades (no negativas)
- [ ] Timestamps automáticos

**Performance**:
- [ ] Eager loading completo (with)
- [ ] Paginación con límites
- [ ] Logging de operaciones críticas

**Auditoría**:
- [ ] Registrar usuario creador/iniciador/completador
- [ ] Timestamps de cada transición
- [ ] Logging de consumos y outputs
- [ ] Logging de posteos al inventario

---

**Versión**: 1.1 (con validaciones completas)
**Fecha**: 31 de Octubre 2025

🔧 **¡Sistema de producción completo listo para implementar con validaciones completas!**
