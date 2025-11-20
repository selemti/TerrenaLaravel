# 🚀 PROMPT CODEX - TRANSFERENCIAS BACKEND + API (SEMANA 1)

**Proyecto**: TerrenaLaravel ERP
**Módulo**: Transferencias entre Almacenes
**Fase**: 1 - Semana 1
**Duración**: 6 horas (lunes-viernes 2h/día o sábado completo)
**Agent**: Codex (GitHub Copilot)
**Fecha**: Noviembre 1-7, 2025

---

## 🎯 OBJETIVO

Completar el backend del módulo de Transferencias entre almacenes, implementando:

1. ✅ Service layer completo con lógica de negocio real
2. ✅ API Controller con endpoints REST
3. ✅ Modelos Eloquent con relaciones
4. ✅ Migraciones para completar tablas faltantes
5. ✅ Feature tests (8-10 tests)

**Success Criteria**:
- TransferService 100% funcional (no TODOs)
- API endpoints testeados y funcionando
- Tests passing 100%
- Lógica de estado (SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA)

---

## 📊 ESTADO ACTUAL

### ✅ Ya Existe
- `app/Services/Inventory/TransferService.php` (con TODOs, necesita completarse)
- `app/Livewire/Transfers/Create.php` (básico)
- `app/Livewire/Transfers/Index.php` (básico)
- Tablas BD: `selemti.transfer_cab`, `selemti.transfer_det`
- Controller web: `app/Http/Controllers/Inventory/TransferController.php`

### ❌ Falta Implementar
- TransferService con lógica real (reemplazar TODOs)
- API REST Controller (`app/Http/Controllers/Api/Inventory/TransferController.php`)
- Modelos Eloquent para Transfer (actualmente no existen modelos formales)
- Feature tests
- Validación de stocks antes de aprobar
- Posteo automático a `mov_inv` (kardex)

---

## 📋 PLAN DE TRABAJO (6 HORAS)

### BLOQUE 1: Modelos y Migrations (2h) - 09:00-11:00

#### Tarea 1.1: Crear Modelos Eloquent (45 min)

**Archivo**: `app/Models/Inventory/TransferHeader.php`

```php
<?php

namespace App\Models\Inventory;

use App\Models\Catalogs\Almacen;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TransferHeader extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.transfer_cab';

    public const STATUS_SOLICITADA = 'SOLICITADA';
    public const STATUS_APROBADA = 'APROBADA';
    public const STATUS_EN_TRANSITO = 'EN_TRANSITO';
    public const STATUS_RECIBIDA = 'RECIBIDA';
    public const STATUS_POSTEADA = 'POSTEADA';
    public const STATUS_CANCELADA = 'CANCELADA';

    protected $fillable = [
        'origen_almacen_id',
        'destino_almacen_id',
        'estado',
        'creada_por',
        'aprobada_por',
        'despachada_por',
        'recibida_por',
        'posteada_por',
        'guia',
        'fecha_solicitada',
        'fecha_aprobada',
        'fecha_despachada',
        'fecha_recibida',
        'fecha_posteada',
        'observaciones',
        'observaciones_recepcion',
    ];

    protected $casts = [
        'fecha_solicitada' => 'datetime',
        'fecha_aprobada' => 'datetime',
        'fecha_despachada' => 'datetime',
        'fecha_recibida' => 'datetime',
        'fecha_posteada' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relaciones
    public function origenAlmacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'origen_almacen_id');
    }

    public function destinoAlmacen(): BelongsTo
    {
        return $this->belongsTo(Almacen::class, 'destino_almacen_id');
    }

    public function creadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creada_por');
    }

    public function aprobadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'aprobada_por');
    }

    public function despachadaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'despachada_por');
    }

    public function recibidaPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recibida_por');
    }

    public function lineas(): HasMany
    {
        return $this->hasMany(TransferLine::class, 'transfer_id');
    }

    // Scopes
    public function scopePendientes($query)
    {
        return $query->whereIn('estado', [
            self::STATUS_SOLICITADA,
            self::STATUS_APROBADA,
            self::STATUS_EN_TRANSITO,
            self::STATUS_RECIBIDA,
        ]);
    }

    public function scopeCompletadas($query)
    {
        return $query->where('estado', self::STATUS_POSTEADA);
    }

    // Métodos de negocio
    public function puedeAprobar(): bool
    {
        return $this->estado === self::STATUS_SOLICITADA;
    }

    public function puedeDespachar(): bool
    {
        return $this->estado === self::STATUS_APROBADA;
    }

    public function puedeRecibir(): bool
    {
        return $this->estado === self::STATUS_EN_TRANSITO;
    }

    public function puedePostear(): bool
    {
        return $this->estado === self::STATUS_RECIBIDA;
    }
}
```

**Archivo**: `app/Models/Inventory/TransferLine.php`

```php
<?php

namespace App\Models\Inventory;

use App\Models\Inv\Item;
use App\Models\Catalogs\Unidad;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TransferLine extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.transfer_det';

    public $timestamps = false;

    protected $fillable = [
        'transfer_id',
        'linea',
        'item_id',
        'cantidad_solicitada',
        'cantidad_despachada',
        'cantidad_recibida',
        'uom_id',
        'costo_unitario',
        'lote',
        'observaciones',
    ];

    protected $casts = [
        'cantidad_solicitada' => 'decimal:3',
        'cantidad_despachada' => 'decimal:3',
        'cantidad_recibida' => 'decimal:3',
        'costo_unitario' => 'decimal:4',
    ];

    public function header(): BelongsTo
    {
        return $this->belongsTo(TransferHeader::class, 'transfer_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(Item::class, 'item_id', 'id');
    }

    public function uom(): BelongsTo
    {
        return $this->belongsTo(Unidad::class, 'uom_id');
    }

    public function getDiferenciaAttribute(): float
    {
        return (float) ($this->cantidad_recibida - $this->cantidad_despachada);
    }

    public function getVarianzaPorcentajeAttribute(): ?float
    {
        if ($this->cantidad_despachada == 0) {
            return null;
        }

        return (($this->cantidad_recibida - $this->cantidad_despachada) / $this->cantidad_despachada) * 100;
    }
}
```

#### Tarea 1.2: Migration para Completar Tablas (30 min)

**Archivo**: `database/migrations/2025_11_01_090000_complete_transfer_tables.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Agregar columnas faltantes a transfer_cab
        DB::statement("
            ALTER TABLE selemti.transfer_cab
            ADD COLUMN IF NOT EXISTS aprobada_por INTEGER,
            ADD COLUMN IF NOT EXISTS posteada_por INTEGER,
            ADD COLUMN IF NOT EXISTS fecha_solicitada TIMESTAMP,
            ADD COLUMN IF NOT EXISTS fecha_aprobada TIMESTAMP,
            ADD COLUMN IF NOT EXISTS fecha_despachada TIMESTAMP,
            ADD COLUMN IF NOT EXISTS fecha_recibida TIMESTAMP,
            ADD COLUMN IF NOT EXISTS fecha_posteada TIMESTAMP,
            ADD COLUMN IF NOT EXISTS observaciones TEXT,
            ADD COLUMN IF NOT EXISTS observaciones_recepcion TEXT,
            ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
        ");

        // Agregar columnas faltantes a transfer_det
        DB::statement("
            ALTER TABLE selemti.transfer_det
            ADD COLUMN IF NOT EXISTS cantidad_despachada DECIMAL(12,3) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS cantidad_recibida DECIMAL(12,3) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS costo_unitario DECIMAL(12,4),
            ADD COLUMN IF NOT EXISTS lote VARCHAR(64),
            ADD COLUMN IF NOT EXISTS observaciones TEXT;
        ");

        // Renombrar columna 'cantidad' a 'cantidad_solicitada' si existe
        DB::statement("
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'selemti'
                    AND table_name = 'transfer_det'
                    AND column_name = 'cantidad'
                ) THEN
                    ALTER TABLE selemti.transfer_det RENAME COLUMN cantidad TO cantidad_solicitada;
                END IF;
            END $$;
        ");

        // Agregar índices
        DB::statement("CREATE INDEX IF NOT EXISTS idx_transfer_cab_estado ON selemti.transfer_cab(estado);");
        DB::statement("CREATE INDEX IF NOT EXISTS idx_transfer_cab_origen ON selemti.transfer_cab(origen_almacen_id);");
        DB::statement("CREATE INDEX IF NOT EXISTS idx_transfer_cab_destino ON selemti.transfer_cab(destino_almacen_id);");
        DB::statement("CREATE INDEX IF NOT EXISTS idx_transfer_cab_fecha_solicita ON selemti.transfer_cab(fecha_solicitada);");
        DB::statement("CREATE INDEX IF NOT EXISTS idx_transfer_det_item ON selemti.transfer_det(item_id);");

        // Actualizar constraint de estado si no existe
        DB::statement("
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_constraint
                    WHERE conname = 'transfer_cab_estado_check'
                ) THEN
                    ALTER TABLE selemti.transfer_cab
                    ADD CONSTRAINT transfer_cab_estado_check
                    CHECK (estado IN ('SOLICITADA', 'APROBADA', 'EN_TRANSITO', 'RECIBIDA', 'POSTEADA', 'CANCELADA'));
                END IF;
            END $$;
        ");
    }

    public function down(): void
    {
        // No hacemos rollback de columnas para evitar pérdida de datos
        // Solo eliminamos índices
        DB::statement("DROP INDEX IF EXISTS selemti.idx_transfer_cab_estado;");
        DB::statement("DROP INDEX IF EXISTS selemti.idx_transfer_cab_origen;");
        DB::statement("DROP INDEX IF EXISTS selemti.idx_transfer_cab_destino;");
        DB::statement("DROP INDEX IF EXISTS selemti.idx_transfer_cab_fecha_solicita;");
        DB::statement("DROP INDEX IF EXISTS selemti.idx_transfer_det_item;");
    }
};
```

#### Tarea 1.3: Factory para Testing (15 min)

**Archivo**: `database/factories/Inventory/TransferHeaderFactory.php`

```php
<?php

namespace Database\Factories\Inventory;

use App\Models\Inventory\TransferHeader;
use Illuminate\Database\Eloquent\Factories\Factory;

class TransferHeaderFactory extends Factory
{
    protected $model = TransferHeader::class;

    public function definition(): array
    {
        return [
            'origen_almacen_id' => 57, // ALM-GEN
            'destino_almacen_id' => 58, // SELEMTI
            'estado' => TransferHeader::STATUS_SOLICITADA,
            'creada_por' => 1,
            'fecha_solicitada' => now(),
            'observaciones' => $this->faker->optional()->sentence(),
        ];
    }

    public function aprobada(): static
    {
        return $this->state(fn (array $attributes) => [
            'estado' => TransferHeader::STATUS_APROBADA,
            'aprobada_por' => 1,
            'fecha_aprobada' => now(),
        ]);
    }

    public function enTransito(): static
    {
        return $this->state(fn (array $attributes) => [
            'estado' => TransferHeader::STATUS_EN_TRANSITO,
            'aprobada_por' => 1,
            'despachada_por' => 1,
            'fecha_aprobada' => now()->subHours(2),
            'fecha_despachada' => now(),
            'guia' => 'GUIA-' . $this->faker->numerify('####'),
        ]);
    }

    public function recibida(): static
    {
        return $this->state(fn (array $attributes) => [
            'estado' => TransferHeader::STATUS_RECIBIDA,
            'aprobada_por' => 1,
            'despachada_por' => 1,
            'recibida_por' => 1,
            'fecha_aprobada' => now()->subHours(4),
            'fecha_despachada' => now()->subHours(2),
            'fecha_recibida' => now(),
        ]);
    }
}
```

---

### BLOQUE 2: TransferService Completo (2h) - 11:00-13:00

#### Tarea 2.1: Completar TransferService (1h 30min)

**Archivo**: `app/Services/Inventory/TransferService.php`

Reemplazar los métodos con TODOs por implementaciones reales:

```php
<?php

namespace App\Services\Inventory;

use App\Models\Inventory\TransferHeader;
use App\Models\Inventory\TransferLine;
use App\Models\Inv\Item;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use InvalidArgumentException;
use RuntimeException;

class TransferService
{
    /**
     * Crea una transferencia SOLICITADA entre almacenes.
     */
    public function createTransfer(int $fromAlmacenId, int $toAlmacenId, array $lines, int $userId): array
    {
        $this->guardPositiveId($fromAlmacenId, 'almacén origen');
        $this->guardPositiveId($toAlmacenId, 'almacén destino');
        $this->guardPositiveId($userId, 'user');

        if ($fromAlmacenId === $toAlmacenId) {
            throw new InvalidArgumentException('El almacén origen y destino no pueden ser el mismo.');
        }

        if (empty($lines)) {
            throw new InvalidArgumentException('Se requiere al menos un ítem para la transferencia.');
        }

        DB::beginTransaction();

        try {
            // Crear cabecera
            $header = TransferHeader::create([
                'origen_almacen_id' => $fromAlmacenId,
                'destino_almacen_id' => $toAlmacenId,
                'estado' => TransferHeader::STATUS_SOLICITADA,
                'creada_por' => $userId,
                'fecha_solicitada' => now(),
            ]);

            // Crear líneas
            foreach ($lines as $index => $line) {
                $this->validateLine($line);

                TransferLine::create([
                    'transfer_id' => $header->id,
                    'linea' => $index + 1,
                    'item_id' => $line['item_id'],
                    'cantidad_solicitada' => $line['cantidad'],
                    'uom_id' => $line['uom_id'],
                ]);
            }

            DB::commit();

            Log::info('Transferencia creada', [
                'transfer_id' => $header->id,
                'from' => $fromAlmacenId,
                'to' => $toAlmacenId,
                'lines' => count($lines),
            ]);

            return [
                'transfer_id' => $header->id,
                'status' => TransferHeader::STATUS_SOLICITADA,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Error creando transferencia', ['error' => $e->getMessage()]);
            throw $e;
        }
    }

    /**
     * Aprueba la transferencia y avanza a estado APROBADA.
     * Valida que haya stock suficiente en origen.
     */
    public function approveTransfer(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        $transfer = TransferHeader::with('lineas.item')->findOrFail($transferId);

        if (!$transfer->puedeAprobar()) {
            throw new RuntimeException("La transferencia no puede ser aprobada en estado: {$transfer->estado}");
        }

        // Validar stock disponible en origen
        foreach ($transfer->lineas as $linea) {
            $stockDisponible = $this->getStockDisponible($linea->item_id, $transfer->origen_almacen_id);

            if ($stockDisponible < $linea->cantidad_solicitada) {
                throw new RuntimeException(
                    "Stock insuficiente para {$linea->item->nombre}. Disponible: {$stockDisponible}, Solicitado: {$linea->cantidad_solicitada}"
                );
            }
        }

        DB::beginTransaction();

        try {
            $transfer->update([
                'estado' => TransferHeader::STATUS_APROBADA,
                'aprobada_por' => $userId,
                'fecha_aprobada' => now(),
            ]);

            DB::commit();

            Log::info('Transferencia aprobada', ['transfer_id' => $transferId]);

            return [
                'transfer_id' => $transferId,
                'status' => TransferHeader::STATUS_APROBADA,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Marca la transferencia como EN_TRANSITO cuando sale de origen.
     */
    public function markInTransit(int $transferId, int $userId, ?string $guia = null): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        $transfer = TransferHeader::findOrFail($transferId);

        if (!$transfer->puedeDespachar()) {
            throw new RuntimeException("La transferencia no puede ser despachada en estado: {$transfer->estado}");
        }

        DB::beginTransaction();

        try {
            $transfer->update([
                'estado' => TransferHeader::STATUS_EN_TRANSITO,
                'despachada_por' => $userId,
                'fecha_despachada' => now(),
                'guia' => $guia,
            ]);

            // Actualizar cantidad_despachada = cantidad_solicitada por defecto
            foreach ($transfer->lineas as $linea) {
                $linea->update([
                    'cantidad_despachada' => $linea->cantidad_solicitada,
                ]);
            }

            DB::commit();

            Log::info('Transferencia en tránsito', ['transfer_id' => $transferId, 'guia' => $guia]);

            return [
                'transfer_id' => $transferId,
                'status' => TransferHeader::STATUS_EN_TRANSITO,
                'guia' => $guia,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Registra cantidades recibidas en destino y pasa a RECIBIDA.
     */
    public function receiveTransfer(int $transferId, array $receivedLines, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

        if (!$transfer->puedeRecibir()) {
            throw new RuntimeException("La transferencia no puede ser recibida en estado: {$transfer->estado}");
        }

        DB::beginTransaction();

        try {
            // Actualizar cantidades recibidas
            foreach ($receivedLines as $received) {
                $linea = $transfer->lineas->where('id', $received['line_id'])->first();

                if (!$linea) {
                    throw new RuntimeException("Línea {$received['line_id']} no encontrada");
                }

                $linea->update([
                    'cantidad_recibida' => $received['cantidad_recibida'],
                    'observaciones' => $received['observaciones'] ?? null,
                ]);
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_RECIBIDA,
                'recibida_por' => $userId,
                'fecha_recibida' => now(),
            ]);

            DB::commit();

            Log::info('Transferencia recibida', ['transfer_id' => $transferId]);

            return [
                'transfer_id' => $transferId,
                'status' => TransferHeader::STATUS_RECIBIDA,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Postea la transferencia al inventario (mov_inv).
     * Genera 2 movimientos: salida en origen + entrada en destino.
     */
    public function postTransferToInventory(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        $transfer = TransferHeader::with('lineas.item.uom')->findOrFail($transferId);

        if (!$transfer->puedePostear()) {
            throw new RuntimeException("La transferencia no puede ser posteada en estado: {$transfer->estado}");
        }

        DB::beginTransaction();

        try {
            foreach ($transfer->lineas as $linea) {
                // Movimiento de SALIDA en almacén origen
                DB::connection('pgsql')->table('selemti.mov_inv')->insert([
                    'item_id' => $linea->item_id,
                    'almacen_id' => $transfer->origen_almacen_id,
                    'tipo' => 'TRANSFER_OUT',
                    'qty' => -1 * $linea->cantidad_recibida, // Negativo = salida
                    'uom' => $linea->uom->clave ?? 'KG',
                    'ref_tipo' => 'TRANSFER',
                    'ref_id' => $transfer->id,
                    'ts' => now(),
                    'user_id' => $userId,
                ]);

                // Movimiento de ENTRADA en almacén destino
                DB::connection('pgsql')->table('selemti.mov_inv')->insert([
                    'item_id' => $linea->item_id,
                    'almacen_id' => $transfer->destino_almacen_id,
                    'tipo' => 'TRANSFER_IN',
                    'qty' => $linea->cantidad_recibida, // Positivo = entrada
                    'uom' => $linea->uom->clave ?? 'KG',
                    'ref_tipo' => 'TRANSFER',
                    'ref_id' => $transfer->id,
                    'ts' => now(),
                    'user_id' => $userId,
                ]);
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_POSTEADA,
                'posteada_por' => $userId,
                'fecha_posteada' => now(),
            ]);

            DB::commit();

            Log::info('Transferencia posteada a inventario', ['transfer_id' => $transferId]);

            return [
                'transfer_id' => $transferId,
                'status' => TransferHeader::STATUS_POSTEADA,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Error posteando transferencia', [
                'transfer_id' => $transferId,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    // Métodos auxiliares privados

    private function getStockDisponible(string $itemId, int $almacenId): float
    {
        // Consultar stock actual en mov_inv
        $result = DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->where('item_id', $itemId)
            ->where('almacen_id', $almacenId)
            ->selectRaw('SUM(qty) as total_qty')
            ->first();

        return (float) ($result->total_qty ?? 0);
    }

    private function validateLine(array $line): void
    {
        if (!isset($line['item_id']) || !isset($line['cantidad']) || !isset($line['uom_id'])) {
            throw new InvalidArgumentException('Cada línea debe tener item_id, cantidad y uom_id');
        }

        if ($line['cantidad'] <= 0) {
            throw new InvalidArgumentException('La cantidad debe ser mayor a 0');
        }

        // Verificar que el item existe
        $item = Item::find($line['item_id']);
        if (!$item) {
            throw new InvalidArgumentException("Item {$line['item_id']} no encontrado");
        }
    }

    private function guardPositiveId(int $value, string $name): void
    {
        if ($value <= 0) {
            throw new InvalidArgumentException("El {$name} debe ser un ID positivo.");
        }
    }
}
```

#### Tarea 2.2: Documentar Service (30 min)

Agregar docblocks completos con ejemplos de uso en cada método.

---

### BLOQUE 3: API Controller + Tests (2h) - 13:00-15:00

#### Tarea 3.1: Crear API Controller (45 min)

**Archivo**: `app/Http/Controllers/Api/Inventory/TransferController.php`

```php
<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Inventory\TransferService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class TransferController extends Controller
{
    public function __construct(private readonly TransferService $transferService)
    {
        $this->middleware(['auth:sanctum', 'permission:can_manage_transfers']);
    }

    /**
     * GET /api/inventory/transfers
     * Lista transferencias con filtros opcionales
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = \App\Models\Inventory\TransferHeader::query()
                ->with(['origenAlmacen', 'destinoAlmacen', 'creadaPor']);

            // Filtros
            if ($request->filled('estado')) {
                $query->where('estado', $request->input('estado'));
            }

            if ($request->filled('almacen_origen_id')) {
                $query->where('origen_almacen_id', $request->input('almacen_origen_id'));
            }

            if ($request->filled('almacen_destino_id')) {
                $query->where('destino_almacen_id', $request->input('almacen_destino_id'));
            }

            $transfers = $query->orderByDesc('created_at')->paginate(20);

            return response()->json([
                'ok' => true,
                'data' => $transfers,
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            Log::error('Error listando transferencias', ['error' => $e->getMessage()]);

            return response()->json([
                'ok' => false,
                'error' => 'TRANSFERS_LIST_ERROR',
                'message' => 'Error al listar transferencias',
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * POST /api/inventory/transfers
     * Crea una nueva transferencia
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'origen_almacen_id' => ['required', 'integer', 'exists:selemti.cat_almacenes,id'],
            'destino_almacen_id' => ['required', 'integer', 'exists:selemti.cat_almacenes,id', 'different:origen_almacen_id'],
            'lineas' => ['required', 'array', 'min:1'],
            'lineas.*.item_id' => ['required', 'string', 'exists:selemti.items,id'],
            'lineas.*.cantidad' => ['required', 'numeric', 'min:0.001'],
            'lineas.*.uom_id' => ['required', 'integer', 'exists:selemti.cat_unidades,id'],
        ]);

        try {
            $result = $this->transferService->createTransfer(
                fromAlmacenId: $validated['origen_almacen_id'],
                toAlmacenId: $validated['destino_almacen_id'],
                lines: $validated['lineas'],
                userId: auth()->id()
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia creada exitosamente',
                'timestamp' => now()->toIso8601String(),
            ], 201);
        } catch (Throwable $e) {
            Log::error('Error creando transferencia', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'TRANSFER_CREATE_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }

    /**
     * GET /api/inventory/transfers/{id}
     * Detalle de una transferencia
     */
    public function show(int $id): JsonResponse
    {
        try {
            $transfer = \App\Models\Inventory\TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'lineas.item.uom',
                'creadaPor',
                'aprobadaPor',
                'despachadaPor',
                'recibidaPor',
            ])->findOrFail($id);

            return response()->json([
                'ok' => true,
                'data' => $transfer,
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'ok' => false,
                'error' => 'TRANSFER_NOT_FOUND',
                'message' => 'Transferencia no encontrada',
                'timestamp' => now()->toIso8601String(),
            ], 404);
        }
    }

    /**
     * POST /api/inventory/transfers/{id}/approve
     * Aprueba una transferencia
     */
    public function approve(int $id): JsonResponse
    {
        try {
            $result = $this->transferService->approveTransfer(
                transferId: $id,
                userId: auth()->id()
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia aprobada',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            Log::error('Error aprobando transferencia', [
                'transfer_id' => $id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'APPROVAL_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }

    /**
     * POST /api/inventory/transfers/{id}/ship
     * Marca transferencia en tránsito
     */
    public function ship(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'guia' => ['nullable', 'string', 'max:64'],
        ]);

        try {
            $result = $this->transferService->markInTransit(
                transferId: $id,
                userId: auth()->id(),
                guia: $validated['guia'] ?? null
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia despachada',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'ok' => false,
                'error' => 'SHIP_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }

    /**
     * POST /api/inventory/transfers/{id}/receive
     * Registra recepción de transferencia
     */
    public function receive(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'lineas' => ['required', 'array', 'min:1'],
            'lineas.*.line_id' => ['required', 'integer'],
            'lineas.*.cantidad_recibida' => ['required', 'numeric', 'min:0'],
            'lineas.*.observaciones' => ['nullable', 'string', 'max:500'],
        ]);

        try {
            $result = $this->transferService->receiveTransfer(
                transferId: $id,
                receivedLines: $validated['lineas'],
                userId: auth()->id()
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia recibida',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'ok' => false,
                'error' => 'RECEIVE_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }

    /**
     * POST /api/inventory/transfers/{id}/post
     * Postea transferencia al inventario
     */
    public function post(int $id): JsonResponse
    {
        try {
            $result = $this->transferService->postTransferToInventory(
                transferId: $id,
                userId: auth()->id()
            );

            return response()->json([
                'ok' => true,
                'data' => $result,
                'message' => 'Transferencia posteada a inventario',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $e) {
            Log::error('Error posteando transferencia', [
                'transfer_id' => $id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'POST_ERROR',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);
        }
    }
}
```

#### Tarea 3.2: Registrar Rutas API (15 min)

**Archivo**: `routes/api.php`

Agregar al final del archivo:

```php
// Transferencias entre almacenes
Route::prefix('inventory/transfers')->middleware(['auth:sanctum'])->group(function () {
    Route::get('/', [App\Http\Controllers\Api\Inventory\TransferController::class, 'index']);
    Route::post('/', [App\Http\Controllers\Api\Inventory\TransferController::class, 'store']);
    Route::get('/{id}', [App\Http\Controllers\Api\Inventory\TransferController::class, 'show']);
    Route::post('/{id}/approve', [App\Http\Controllers\Api\Inventory\TransferController::class, 'approve']);
    Route::post('/{id}/ship', [App\Http\Controllers\Api\Inventory\TransferController::class, 'ship']);
    Route::post('/{id}/receive', [App\Http\Controllers\Api\Inventory\TransferController::class, 'receive']);
    Route::post('/{id}/post', [App\Http\Controllers\Api\Inventory\TransferController::class, 'post']);
});
```

#### Tarea 3.3: Feature Tests (1h)

**Archivo**: `tests/Feature/TransferServiceTest.php`

```php
<?php

namespace Tests\Feature;

use App\Models\Catalogs\Almacen;
use App\Models\Inventory\TransferHeader;
use App\Models\Inv\Item;
use App\Services\Inventory\TransferService;
use Database\Factories\Inventory\TransferHeaderFactory;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TransferServiceTest extends TestCase
{
    use RefreshDatabase;

    private TransferService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(TransferService::class);
    }

    public function test_it_creates_a_transfer_successfully(): void
    {
        $result = $this->service->createTransfer(
            fromAlmacenId: 57,
            toAlmacenId: 58,
            lines: [
                ['item_id' => 'ITEM-001', 'cantidad' => 10, 'uom_id' => 1],
                ['item_id' => 'ITEM-002', 'cantidad' => 5, 'uom_id' => 1],
            ],
            userId: 1
        );

        $this->assertArrayHasKey('transfer_id', $result);
        $this->assertEquals(TransferHeader::STATUS_SOLICITADA, $result['status']);

        $transfer = TransferHeader::find($result['transfer_id']);
        $this->assertNotNull($transfer);
        $this->assertEquals(2, $transfer->lineas()->count());
    }

    public function test_it_rejects_same_origin_and_destination(): void
    {
        $this->expectException(\InvalidArgumentException::class);

        $this->service->createTransfer(
            fromAlmacenId: 57,
            toAlmacenId: 57, // Mismo almacén
            lines: [['item_id' => 'ITEM-001', 'cantidad' => 10, 'uom_id' => 1]],
            userId: 1
        );
    }

    public function test_it_approves_a_transfer_with_sufficient_stock(): void
    {
        // Setup: crear transferencia y simular stock
        $transfer = TransferHeader::factory()->create();
        // TODO: Agregar stock simulado en mov_inv

        $result = $this->service->approveTransfer($transfer->id, 1);

        $this->assertEquals(TransferHeader::STATUS_APROBADA, $result['status']);

        $transfer->refresh();
        $this->assertEquals(TransferHeader::STATUS_APROBADA, $transfer->estado);
        $this->assertNotNull($transfer->aprobada_por);
    }

    public function test_it_rejects_approval_without_sufficient_stock(): void
    {
        $transfer = TransferHeader::factory()->create();

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Stock insuficiente');

        $this->service->approveTransfer($transfer->id, 1);
    }

    public function test_it_marks_transfer_in_transit(): void
    {
        $transfer = TransferHeader::factory()->aprobada()->create();

        $result = $this->service->markInTransit($transfer->id, 1, 'GUIA-1234');

        $this->assertEquals(TransferHeader::STATUS_EN_TRANSITO, $result['status']);
        $this->assertEquals('GUIA-1234', $result['guia']);

        $transfer->refresh();
        $this->assertEquals(TransferHeader::STATUS_EN_TRANSITO, $transfer->estado);
        $this->assertEquals('GUIA-1234', $transfer->guia);
    }

    public function test_it_receives_transfer_with_quantities(): void
    {
        $transfer = TransferHeader::factory()->enTransito()->create();
        $linea = $transfer->lineas()->first();

        $result = $this->service->receiveTransfer(
            transferId: $transfer->id,
            receivedLines: [
                [
                    'line_id' => $linea->id,
                    'cantidad_recibida' => 9.5, // Recibe menos de lo despachado
                    'observaciones' => 'Falta 0.5 unidades',
                ],
            ],
            userId: 1
        );

        $this->assertEquals(TransferHeader::STATUS_RECIBIDA, $result['status']);

        $linea->refresh();
        $this->assertEquals(9.5, $linea->cantidad_recibida);
        $this->assertEquals('Falta 0.5 unidades', $linea->observaciones);
    }

    public function test_it_posts_transfer_to_inventory(): void
    {
        $transfer = TransferHeader::factory()->recibida()->create();
        $linea = $transfer->lineas()->first();
        $linea->update(['cantidad_recibida' => 10]);

        $result = $this->service->postTransferToInventory($transfer->id, 1);

        $this->assertEquals(TransferHeader::STATUS_POSTEADA, $result['status']);

        // Verificar movimientos en mov_inv
        $movOrigen = DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->where('ref_tipo', 'TRANSFER')
            ->where('ref_id', $transfer->id)
            ->where('tipo', 'TRANSFER_OUT')
            ->first();

        $movDestino = DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->where('ref_tipo', 'TRANSFER')
            ->where('ref_id', $transfer->id)
            ->where('tipo', 'TRANSFER_IN')
            ->first();

        $this->assertNotNull($movOrigen);
        $this->assertNotNull($movDestino);
        $this->assertEquals(-10, $movOrigen->qty); // Salida negativa
        $this->assertEquals(10, $movDestino->qty); // Entrada positiva
    }

    public function test_it_rejects_posting_non_received_transfer(): void
    {
        $transfer = TransferHeader::factory()->aprobada()->create(); // Solo aprobada, no recibida

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('no puede ser posteada');

        $this->service->postTransferToInventory($transfer->id, 1);
    }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN

Al terminar las 6 horas, verifica:

### Backend
- [ ] Modelos TransferHeader y TransferLine creados con relaciones
- [ ] Migration ejecutada exitosamente
- [ ] Factory creado y funcional
- [ ] TransferService completamente implementado (0 TODOs)
- [ ] API Controller con 7 endpoints
- [ ] Rutas API registradas

### Tests
- [ ] 8 tests creados
- [ ] Todos los tests pasan (8/8) ✅
- [ ] Cobertura >80% en TransferService

### Validación Manual
- [ ] Crear transferencia vía API: `POST /api/inventory/transfers`
- [ ] Aprobar transferencia: `POST /api/inventory/transfers/{id}/approve`
- [ ] Despachar: `POST /api/inventory/transfers/{id}/ship`
- [ ] Recibir: `POST /api/inventory/transfers/{id}/receive`
- [ ] Postear: `POST /api/inventory/transfers/{id}/post`
- [ ] Verificar movimientos en `mov_inv`

---

## 📦 ENTREGABLES

1. **Código**
   - `app/Models/Inventory/TransferHeader.php`
   - `app/Models/Inventory/TransferLine.php`
   - `app/Services/Inventory/TransferService.php` (completado)
   - `app/Http/Controllers/Api/Inventory/TransferController.php`
   - `database/migrations/2025_11_01_090000_complete_transfer_tables.php`
   - `database/factories/Inventory/TransferHeaderFactory.php`
   - `tests/Feature/TransferServiceTest.php`
   - `routes/api.php` (actualizado)

2. **Documentación**
   - Docblocks completos en todos los métodos
   - README con ejemplos de uso de API

3. **Tests**
   - 8 tests feature pasando

---

## 🚀 COMANDOS ÚTILES

```bash
# Ejecutar migration
php artisan migrate

# Ejecutar tests
php artisan test --filter=TransferServiceTest

# Verificar rutas API
php artisan route:list --path=inventory/transfers

# Crear transferencia de prueba (via Tinker)
php artisan tinker
$transfer = \App\Models\Inventory\TransferHeader::factory()->create();

# Verificar tablas
psql -h localhost -U postgres -d pos -c "\d selemti.transfer_cab"
```

---

## 📝 NOTAS IMPORTANTES

1. **Validación de Stock**: El método `approveTransfer()` valida stock real consultando `mov_inv`
2. **Transacciones**: Todos los métodos usan `DB::transaction()` para atomicidad
3. **Logging**: Eventos importantes se registran en logs
4. **Estados**: Flujo estricto: SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA
5. **Kardex**: El posteo genera 2 movimientos (salida origen + entrada destino)

---

## 🔒 VALIDACIONES COMPLETAS DEL MÓDULO

### 1. VALIDACIONES DE ENTRADA (Input Validation)

#### 1.1 Validación de Creación de Transferencia (createTransfer)

**Parámetros requeridos**:
```php
// TransferController@store
$validated = $request->validate([
    'origen_almacen_id' => [
        'required',
        'integer',
        'exists:selemti.cat_almacenes,id',
        'gt:0',
    ],
    'destino_almacen_id' => [
        'required',
        'integer',
        'exists:selemti.cat_almacenes,id',
        'different:origen_almacen_id', // No puede ser igual al origen
        'gt:0',
    ],
    'lineas' => [
        'required',
        'array',
        'min:1', // Al menos una línea
        'max:100', // Máximo 100 líneas por transferencia
    ],
    'lineas.*.item_id' => [
        'required',
        'string',
        'exists:selemti.items,id',
        'max:64',
    ],
    'lineas.*.cantidad' => [
        'required',
        'numeric',
        'min:0.001', // No permite cero
        'max:999999.999', // Límite razonable
        'regex:/^\d+(\.\d{1,3})?$/', // Máximo 3 decimales
    ],
    'lineas.*.uom_id' => [
        'required',
        'integer',
        'exists:selemti.cat_unidades,id',
    ],
    'observaciones' => [
        'nullable',
        'string',
        'max:1000',
    ],
]);

// Validación adicional de negocio
foreach ($validated['lineas'] as $linea) {
    // Verificar que el item exista y esté activo
    $item = Item::find($linea['item_id']);
    if (!$item || !$item->activo) {
        throw new InvalidArgumentException("Item {$linea['item_id']} no está activo");
    }

    // Verificar que la UOM sea válida para el item
    // (opcional: puede agregar validación de UOM compatible con el item)
}

// Validación de almacenes activos
$origenAlmacen = Almacen::find($validated['origen_almacen_id']);
$destinoAlmacen = Almacen::find($validated['destino_almacen_id']);

if (!$origenAlmacen || !$origenAlmacen->activo) {
    throw new InvalidArgumentException("Almacén origen no está activo");
}

if (!$destinoAlmacen || !$destinoAlmacen->activo) {
    throw new InvalidArgumentException("Almacén destino no está activo");
}
```

#### 1.2 Validación de Aprobación (approveTransfer)

**Validaciones**:
- Transfer ID debe ser positivo y existente
- User ID debe ser positivo y existente
- Estado actual debe ser SOLICITADA
- Stock suficiente en almacén origen para CADA línea

```php
// Validación de estado
if ($transfer->estado !== TransferHeader::STATUS_SOLICITADA) {
    throw new RuntimeException(
        "Solo se pueden aprobar transferencias en estado SOLICITADA. Estado actual: {$transfer->estado}"
    );
}

// Validación de stock línea por línea
foreach ($transfer->lineas as $linea) {
    $stockDisponible = $this->getStockDisponible(
        $linea->item_id,
        $transfer->origen_almacen_id
    );

    if ($stockDisponible < $linea->cantidad_solicitada) {
        throw new RuntimeException(
            "Stock insuficiente para {$linea->item->nombre}. " .
            "Disponible: {$stockDisponible}, Solicitado: {$linea->cantidad_solicitada}"
        );
    }
}

// Validación de permisos
if (!auth()->user()->can('inventory.transfers.approve')) {
    throw new UnauthorizedException('No tiene permisos para aprobar transferencias');
}
```

#### 1.3 Validación de Despacho (markInTransit)

**Validaciones**:
```php
$validated = $request->validate([
    'guia' => [
        'nullable',
        'string',
        'max:64',
        'regex:/^[A-Z0-9\-]+$/', // Solo alfanumérico y guiones
    ],
]);

// Estado debe ser APROBADA
if ($transfer->estado !== TransferHeader::STATUS_APROBADA) {
    throw new RuntimeException(
        "Solo se pueden despachar transferencias APROBADAS. Estado actual: {$transfer->estado}"
    );
}

// Validación opcional: todas las líneas deben tener cantidad_despachada > 0
foreach ($transfer->lineas as $linea) {
    if ($linea->cantidad_despachada <= 0) {
        throw new RuntimeException(
            "La línea {$linea->linea} debe tener cantidad despachada > 0"
        );
    }
}
```

#### 1.4 Validación de Recepción (receiveTransfer)

**Validaciones más complejas**:
```php
$validated = $request->validate([
    'lineas' => [
        'required',
        'array',
        'min:1',
    ],
    'lineas.*.line_id' => [
        'required',
        'integer',
        'exists:selemti.transfer_det,id',
    ],
    'lineas.*.cantidad_recibida' => [
        'required',
        'numeric',
        'min:0', // Permite 0 (pérdida total)
        'max:999999.999',
        'regex:/^\d+(\.\d{1,3})?$/',
    ],
    'lineas.*.observaciones' => [
        'nullable',
        'string',
        'max:500',
    ],
]);

// Validación de estado
if ($transfer->estado !== TransferHeader::STATUS_EN_TRANSITO) {
    throw new RuntimeException(
        "Solo se pueden recibir transferencias EN_TRANSITO. Estado actual: {$transfer->estado}"
    );
}

// Validación: todas las líneas recibidas deben pertenecer a esta transferencia
foreach ($validated['lineas'] as $receivedLine) {
    $linea = $transfer->lineas->where('id', $receivedLine['line_id'])->first();

    if (!$linea) {
        throw new RuntimeException(
            "La línea {$receivedLine['line_id']} no pertenece a esta transferencia"
        );
    }

    // Validación opcional: cantidad recibida no puede exceder cantidad despachada + tolerancia
    $tolerancia = 0.05; // 5% tolerancia
    $maxRecibida = $linea->cantidad_despachada * (1 + $tolerancia);

    if ($receivedLine['cantidad_recibida'] > $maxRecibida) {
        throw new RuntimeException(
            "Cantidad recibida ({$receivedLine['cantidad_recibida']}) excede " .
            "cantidad despachada + 5% tolerancia ({$maxRecibida}) para línea {$linea->linea}"
        );
    }
}

// Validación: todas las líneas de la transferencia deben tener cantidad recibida
$lineasRecibidas = collect($validated['lineas'])->pluck('line_id');
foreach ($transfer->lineas as $linea) {
    if (!$lineasRecibidas->contains($linea->id)) {
        throw new RuntimeException(
            "Falta especificar cantidad recibida para línea {$linea->linea}"
        );
    }
}
```

#### 1.5 Validación de Posteo (postTransferToInventory)

**Validaciones**:
```php
// Estado debe ser RECIBIDA
if ($transfer->estado !== TransferHeader::STATUS_RECIBIDA) {
    throw new RuntimeException(
        "Solo se pueden postear transferencias RECIBIDAS. Estado actual: {$transfer->estado}"
    );
}

// Validación: todas las líneas deben tener cantidad_recibida especificada
foreach ($transfer->lineas as $linea) {
    if (is_null($linea->cantidad_recibida)) {
        throw new RuntimeException(
            "La línea {$linea->linea} no tiene cantidad recibida especificada"
        );
    }
}

// Validación: no debe estar ya posteada (evitar double-posting)
$yaPosteada = DB::connection('pgsql')
    ->table('selemti.mov_inv')
    ->where('ref_tipo', 'TRANSFER')
    ->where('ref_id', $transfer->id)
    ->exists();

if ($yaPosteada) {
    throw new RuntimeException(
        "Esta transferencia ya fue posteada al inventario previamente"
    );
}

// Validación de permisos
if (!auth()->user()->can('inventory.transfers.post')) {
    throw new UnauthorizedException('No tiene permisos para postear transferencias');
}
```

### 2. VALIDACIONES DE NEGOCIO (Business Rules)

#### 2.1 Máquina de Estados (State Machine)

**Flujo estricto**:
```
SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA
                ↓
            CANCELADA (desde cualquier estado anterior a POSTEADA)
```

**Validaciones de transición**:
```php
class TransferHeader extends Model
{
    public function puedeAprobar(): bool
    {
        return $this->estado === self::STATUS_SOLICITADA;
    }

    public function puedeDespachar(): bool
    {
        return $this->estado === self::STATUS_APROBADA;
    }

    public function puedeRecibir(): bool
    {
        return $this->estado === self::STATUS_EN_TRANSITO;
    }

    public function puedePostear(): bool
    {
        return $this->estado === self::STATUS_RECIBIDA;
    }

    public function puedeCancelar(): bool
    {
        return in_array($this->estado, [
            self::STATUS_SOLICITADA,
            self::STATUS_APROBADA,
            self::STATUS_EN_TRANSITO,
            self::STATUS_RECIBIDA,
        ]);
    }
}
```

#### 2.2 Validación de Stock Disponible

**Algoritmo**:
```php
private function getStockDisponible(string $itemId, int $almacenId): float
{
    // Consulta suma de movimientos en kardex
    $result = DB::connection('pgsql')
        ->table('selemti.mov_inv')
        ->where('item_id', $itemId)
        ->where('almacen_id', $almacenId)
        ->selectRaw('COALESCE(SUM(qty), 0) as total_qty')
        ->first();

    $stock = (float) ($result->total_qty ?? 0);

    // Validación: stock no puede ser negativo (indica error en kardex)
    if ($stock < 0) {
        Log::warning('Stock negativo detectado', [
            'item_id' => $itemId,
            'almacen_id' => $almacenId,
            'stock' => $stock,
        ]);
    }

    return max(0, $stock); // Retornar 0 si es negativo
}
```

#### 2.3 Validación de Varianza en Recepción

**Cálculo de diferencias**:
```php
class TransferLine extends Model
{
    public function getDiferenciaAttribute(): float
    {
        return (float) ($this->cantidad_recibida - $this->cantidad_despachada);
    }

    public function getVarianzaPorcentajeAttribute(): ?float
    {
        if ($this->cantidad_despachada == 0) {
            return null;
        }

        return (($this->cantidad_recibida - $this->cantidad_despachada)
                / $this->cantidad_despachada) * 100;
    }

    public function tieneVarianzaSignificativa(float $umbral = 5.0): bool
    {
        $varianza = $this->varianza_porcentaje;
        return $varianza !== null && abs($varianza) > $umbral;
    }
}
```

**Validación en Service**:
```php
// En receiveTransfer(), después de actualizar cantidades
$lineasConVarianza = [];
foreach ($transfer->lineas as $linea) {
    if ($linea->tieneVarianzaSignificativa(5.0)) {
        $lineasConVarianza[] = [
            'linea' => $linea->linea,
            'item' => $linea->item->nombre,
            'despachada' => $linea->cantidad_despachada,
            'recibida' => $linea->cantidad_recibida,
            'varianza' => $linea->varianza_porcentaje,
        ];
    }
}

if (count($lineasConVarianza) > 0) {
    Log::warning('Varianza significativa en recepción', [
        'transfer_id' => $transferId,
        'lineas' => $lineasConVarianza,
    ]);

    // Opcional: enviar notificación a supervisor
}
```

### 3. VALIDACIONES DE BASE DE DATOS (Database Constraints)

#### 3.1 Constraints en Migration

```php
// En migration: 2025_11_01_090000_complete_transfer_tables.php
public function up(): void
{
    // Constraint de estado
    DB::statement("
        ALTER TABLE selemti.transfer_cab
        ADD CONSTRAINT transfer_cab_estado_check
        CHECK (estado IN ('SOLICITADA', 'APROBADA', 'EN_TRANSITO', 'RECIBIDA', 'POSTEADA', 'CANCELADA'));
    ");

    // Constraint: origen != destino
    DB::statement("
        ALTER TABLE selemti.transfer_cab
        ADD CONSTRAINT transfer_cab_almacenes_check
        CHECK (origen_almacen_id != destino_almacen_id);
    ");

    // Foreign Keys
    DB::statement("
        ALTER TABLE selemti.transfer_cab
        ADD CONSTRAINT fk_transfer_cab_origen
        FOREIGN KEY (origen_almacen_id) REFERENCES selemti.cat_almacenes(id)
        ON DELETE RESTRICT,

        ADD CONSTRAINT fk_transfer_cab_destino
        FOREIGN KEY (destino_almacen_id) REFERENCES selemti.cat_almacenes(id)
        ON DELETE RESTRICT,

        ADD CONSTRAINT fk_transfer_cab_creada_por
        FOREIGN KEY (creada_por) REFERENCES selemti.users(id)
        ON DELETE SET NULL,

        ADD CONSTRAINT fk_transfer_cab_aprobada_por
        FOREIGN KEY (aprobada_por) REFERENCES selemti.users(id)
        ON DELETE SET NULL;
    ");

    // Constraints en líneas
    DB::statement("
        ALTER TABLE selemti.transfer_det
        ADD CONSTRAINT transfer_det_cantidad_solicitada_check
        CHECK (cantidad_solicitada > 0),

        ADD CONSTRAINT transfer_det_cantidad_despachada_check
        CHECK (cantidad_despachada >= 0),

        ADD CONSTRAINT transfer_det_cantidad_recibida_check
        CHECK (cantidad_recibida >= 0);
    ");

    DB::statement("
        ALTER TABLE selemti.transfer_det
        ADD CONSTRAINT fk_transfer_det_transfer
        FOREIGN KEY (transfer_id) REFERENCES selemti.transfer_cab(id)
        ON DELETE CASCADE,

        ADD CONSTRAINT fk_transfer_det_item
        FOREIGN KEY (item_id) REFERENCES selemti.items(id)
        ON DELETE RESTRICT,

        ADD CONSTRAINT fk_transfer_det_uom
        FOREIGN KEY (uom_id) REFERENCES selemti.cat_unidades(id)
        ON DELETE RESTRICT;
    ");

    // Índices para performance
    DB::statement("CREATE INDEX idx_transfer_cab_estado ON selemti.transfer_cab(estado);");
    DB::statement("CREATE INDEX idx_transfer_cab_origen ON selemti.transfer_cab(origen_almacen_id);");
    DB::statement("CREATE INDEX idx_transfer_cab_destino ON selemti.transfer_cab(destino_almacen_id);");
    DB::statement("CREATE INDEX idx_transfer_cab_fecha_solicita ON selemti.transfer_cab(fecha_solicitada);");
    DB::statement("CREATE INDEX idx_transfer_det_item ON selemti.transfer_det(item_id);");
    DB::statement("CREATE INDEX idx_transfer_det_transfer ON selemti.transfer_det(transfer_id);");
}
```

#### 3.2 Validaciones de Integridad Referencial

**Verificaciones antes de delete**:
```php
// Antes de eliminar un almacén, verificar transferencias
public function beforeDeleteAlmacen(int $almacenId): void
{
    $transfersPendientes = TransferHeader::query()
        ->where(function($q) use ($almacenId) {
            $q->where('origen_almacen_id', $almacenId)
              ->orWhere('destino_almacen_id', $almacenId);
        })
        ->whereIn('estado', [
            TransferHeader::STATUS_SOLICITADA,
            TransferHeader::STATUS_APROBADA,
            TransferHeader::STATUS_EN_TRANSITO,
            TransferHeader::STATUS_RECIBIDA,
        ])
        ->count();

    if ($transfersPendientes > 0) {
        throw new RuntimeException(
            "No se puede eliminar el almacén. Tiene {$transfersPendientes} transferencias pendientes."
        );
    }
}
```

### 4. VALIDACIONES DE SEGURIDAD (Security)

#### 4.1 Autenticación y Autorización

**Middleware en Controller**:
```php
public function __construct(private readonly TransferService $transferService)
{
    $this->middleware(['auth:sanctum']);

    $this->middleware('permission:inventory.transfers.view')
        ->only(['index', 'show']);

    $this->middleware('permission:inventory.transfers.manage')
        ->only(['store']);

    $this->middleware('permission:inventory.transfers.approve')
        ->only(['approve']);

    $this->middleware('permission:inventory.transfers.ship')
        ->only(['ship']);

    $this->middleware('permission:inventory.transfers.receive')
        ->only(['receive']);

    $this->middleware('permission:inventory.transfers.post')
        ->only(['post']);
}
```

**Validación de propiedad (ownership)**:
```php
// Solo el creador o un supervisor puede cancelar
public function cancelTransfer(int $transferId, int $userId): array
{
    $transfer = TransferHeader::findOrFail($transferId);
    $user = User::findOrFail($userId);

    // Validar que sea el creador o tenga permiso especial
    if ($transfer->creada_por !== $userId &&
        !$user->hasPermissionTo('inventory.transfers.cancel_any')) {
        throw new UnauthorizedException(
            'Solo el creador o un supervisor puede cancelar esta transferencia'
        );
    }

    // ... resto de lógica
}
```

#### 4.2 Prevención de SQL Injection

**Usar Query Builder / Eloquent**:
```php
// ✅ CORRECTO - Uso de Query Builder con bindings
$stock = DB::connection('pgsql')
    ->table('selemti.mov_inv')
    ->where('item_id', $itemId)  // Binding automático
    ->where('almacen_id', $almacenId)
    ->selectRaw('SUM(qty) as total_qty')
    ->first();

// ❌ INCORRECTO - Concatenación directa
$query = "SELECT SUM(qty) FROM selemti.mov_inv WHERE item_id = '$itemId'";
```

#### 4.3 Rate Limiting

**En routes/api.php**:
```php
Route::prefix('inventory/transfers')
    ->middleware(['auth:sanctum', 'throttle:60,1']) // 60 requests por minuto
    ->group(function () {
        Route::get('/', [TransferController::class, 'index']);
        Route::post('/', [TransferController::class, 'store'])
            ->middleware('throttle:10,1'); // Solo 10 creaciones por minuto
        // ...
    });
```

#### 4.4 Validación de Mass Assignment

**En modelos**:
```php
class TransferHeader extends Model
{
    // Definir explícitamente campos fillable
    protected $fillable = [
        'origen_almacen_id',
        'destino_almacen_id',
        'estado',
        'creada_por',
        // ... solo campos seguros
    ];

    // Proteger campos sensibles
    protected $guarded = [
        'id',
        'created_at',
    ];
}
```

### 5. VALIDACIONES DE DATOS (Data Integrity)

#### 5.1 Validación de Fechas

```php
// En TransferService
private function validateFechaLogica(TransferHeader $transfer): void
{
    // fecha_aprobada debe ser >= fecha_solicitada
    if ($transfer->fecha_aprobada && $transfer->fecha_solicitada &&
        $transfer->fecha_aprobada < $transfer->fecha_solicitada) {
        throw new InvalidArgumentException(
            'La fecha de aprobación no puede ser anterior a la fecha de solicitud'
        );
    }

    // fecha_despachada >= fecha_aprobada
    if ($transfer->fecha_despachada && $transfer->fecha_aprobada &&
        $transfer->fecha_despachada < $transfer->fecha_aprobada) {
        throw new InvalidArgumentException(
            'La fecha de despacho no puede ser anterior a la fecha de aprobación'
        );
    }

    // fecha_recibida >= fecha_despachada
    if ($transfer->fecha_recibida && $transfer->fecha_despachada &&
        $transfer->fecha_recibida < $transfer->fecha_despachada) {
        throw new InvalidArgumentException(
            'La fecha de recepción no puede ser anterior a la fecha de despacho'
        );
    }
}
```

#### 5.2 Validación de Normalización de UOM

```php
// Asegurar que todas las cantidades estén en la UOM correcta
private function normalizarCantidad(float $cantidad, int $uomId, string $itemId): float
{
    $item = Item::with('uom')->findOrFail($itemId);
    $uom = Unidad::findOrFail($uomId);

    // Si la UOM es diferente a la base del item, convertir
    if ($uomId !== $item->uom_id) {
        $factor = $this->getConversionFactor($uomId, $item->uom_id);
        return $cantidad * $factor;
    }

    return $cantidad;
}
```

#### 5.3 Validación de Duplicados

```php
// Prevenir creación de transferencias duplicadas en corto tiempo
private function validarDuplicados(int $fromAlmacenId, int $toAlmacenId, array $lines, int $userId): void
{
    // Buscar transferencias idénticas en últimos 5 minutos
    $duplicada = TransferHeader::query()
        ->where('origen_almacen_id', $fromAlmacenId)
        ->where('destino_almacen_id', $toAlmacenId)
        ->where('creada_por', $userId)
        ->where('created_at', '>=', now()->subMinutes(5))
        ->whereHas('lineas', function($q) use ($lines) {
            // Verificar que tengan los mismos items
            $itemIds = collect($lines)->pluck('item_id');
            return $q->whereIn('item_id', $itemIds);
        })
        ->first();

    if ($duplicada) {
        throw new RuntimeException(
            "Ya existe una transferencia similar creada hace menos de 5 minutos (ID: {$duplicada->id})"
        );
    }
}
```

### 6. VALIDACIONES DE PERFORMANCE

#### 6.1 Límites de Consultas

```php
// En index() - limitar resultados
public function index(Request $request): JsonResponse
{
    $perPage = min($request->input('per_page', 20), 100); // Máximo 100 por página

    $transfers = TransferHeader::query()
        ->with(['origenAlmacen', 'destinoAlmacen', 'creadaPor'])
        ->orderByDesc('created_at')
        ->paginate($perPage);

    // ...
}
```

#### 6.2 Validación de N+1 Queries

```php
// ✅ CORRECTO - Eager loading
$transfer = TransferHeader::with([
    'lineas.item.uom',
    'origenAlmacen',
    'destinoAlmacen',
])->findOrFail($transferId);

// ❌ INCORRECTO - Lazy loading (N+1)
$transfer = TransferHeader::findOrFail($transferId);
foreach ($transfer->lineas as $linea) {
    echo $linea->item->nombre; // Query adicional por cada línea
}
```

### 7. VALIDACIONES EN TESTS

**Tests específicos de validación**:

```php
public function test_it_rejects_negative_quantities(): void
{
    $this->expectException(\InvalidArgumentException::class);
    $this->expectExceptionMessage('cantidad debe ser mayor a 0');

    $this->service->createTransfer(
        fromAlmacenId: 57,
        toAlmacenId: 58,
        lines: [
            ['item_id' => 'ITEM-001', 'cantidad' => -5, 'uom_id' => 1],
        ],
        userId: 1
    );
}

public function test_it_rejects_same_origin_and_destination(): void
{
    $this->expectException(\InvalidArgumentException::class);
    $this->expectExceptionMessage('no pueden ser el mismo');

    $this->service->createTransfer(
        fromAlmacenId: 57,
        toAlmacenId: 57, // Mismo almacén
        lines: [['item_id' => 'ITEM-001', 'cantidad' => 10, 'uom_id' => 1]],
        userId: 1
    );
}

public function test_it_rejects_empty_lines(): void
{
    $this->expectException(\InvalidArgumentException::class);
    $this->expectExceptionMessage('al menos un ítem');

    $this->service->createTransfer(
        fromAlmacenId: 57,
        toAlmacenId: 58,
        lines: [], // Vacío
        userId: 1
    );
}

public function test_it_rejects_approval_without_stock(): void
{
    $transfer = TransferHeader::factory()->create();
    // No crear stock en mov_inv

    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage('Stock insuficiente');

    $this->service->approveTransfer($transfer->id, 1);
}

public function test_it_rejects_invalid_state_transitions(): void
{
    $transfer = TransferHeader::factory()->create(['estado' => 'POSTEADA']);

    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage('no puede ser aprobada');

    $this->service->approveTransfer($transfer->id, 1);
}

public function test_it_validates_received_quantities_within_tolerance(): void
{
    $transfer = TransferHeader::factory()->enTransito()->create();
    $linea = $transfer->lineas()->first();
    $linea->update(['cantidad_despachada' => 100]);

    // Intentar recibir 120 (20% más) - debe rechazar
    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage('excede cantidad despachada');

    $this->service->receiveTransfer(
        transferId: $transfer->id,
        receivedLines: [
            ['line_id' => $linea->id, 'cantidad_recibida' => 120],
        ],
        userId: 1
    );
}

public function test_it_prevents_double_posting(): void
{
    $transfer = TransferHeader::factory()->recibida()->create();

    // Postear primera vez
    $this->service->postTransferToInventory($transfer->id, 1);

    // Intentar postear segunda vez
    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage('ya fue posteada');

    $this->service->postTransferToInventory($transfer->id, 1);
}
```

### 8. VALIDACIONES DE LOGGING Y AUDITORÍA

```php
// En cada método crítico del Service
public function approveTransfer(int $transferId, int $userId): array
{
    // Logging antes de operación crítica
    Log::info('Intentando aprobar transferencia', [
        'transfer_id' => $transferId,
        'user_id' => $userId,
        'timestamp' => now()->toIso8601String(),
    ]);

    try {
        // ... lógica de aprobación

        Log::info('Transferencia aprobada exitosamente', [
            'transfer_id' => $transferId,
            'user_id' => $userId,
        ]);

        return $result;
    } catch (\Throwable $e) {
        Log::error('Error aprobando transferencia', [
            'transfer_id' => $transferId,
            'user_id' => $userId,
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
        ]);

        throw $e;
    }
}
```

### 9. CHECKLIST DE VALIDACIONES

Al implementar, verificar que TODAS estas validaciones estén presentes:

**Entrada (Input)**:
- [ ] Validación de tipos de datos (integer, string, decimal)
- [ ] Validación de rangos (min, max)
- [ ] Validación de formato (regex para guía, decimales)
- [ ] Validación de existencia (exists en DB)
- [ ] Validación de relaciones (different, same, etc.)

**Negocio (Business Logic)**:
- [ ] Validación de estados (state machine)
- [ ] Validación de stock disponible
- [ ] Validación de almacenes activos
- [ ] Validación de items activos
- [ ] Validación de varianza (tolerancia en recepción)
- [ ] Validación de duplicados
- [ ] Validación de fechas lógicas

**Base de Datos**:
- [ ] Constraints CHECK en columnas
- [ ] Foreign keys con ON DELETE apropiado
- [ ] Índices para performance
- [ ] Unique constraints donde aplique

**Seguridad**:
- [ ] Autenticación (auth:sanctum)
- [ ] Autorización (permissions)
- [ ] Rate limiting
- [ ] Prevención SQL injection (Query Builder)
- [ ] Validación de mass assignment (fillable/guarded)

**Integridad de Datos**:
- [ ] Normalización de UOM
- [ ] Validación de secuencia de fechas
- [ ] Prevención de double-posting
- [ ] Validación de cantidades (no negativas, no cero donde no aplique)

**Performance**:
- [ ] Eager loading (with)
- [ ] Paginación con límites
- [ ] Índices en columnas de búsqueda frecuente

**Auditoría**:
- [ ] Logging de operaciones críticas
- [ ] Logging de errores con contexto
- [ ] Timestamps automáticos (created_at, updated_at)

---

**Fecha de Creación**: 31 de Octubre 2025
**Versión**: 1.1 (con validaciones completas)
**Autor**: Claude Code

🎯 **¡Listos para implementar Transferencias Backend con validaciones completas!**
