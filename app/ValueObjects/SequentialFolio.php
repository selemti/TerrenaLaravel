<?php

namespace App\ValueObjects;

use Illuminate\Support\Facades\DB;

/**
 * Value Object para folios secuenciales tipo PREFIX-YYYYMMDD-NNNN.
 * Reemplaza generateFolio() en PurchasingService y nextFolio() en InventoryCountService.
 */
final readonly class SequentialFolio
{
    public function __construct(
        public string $prefix,
        public string $date,
        public int $sequence,
    ) {}

    public function toString(): string
    {
        return sprintf('%s-%s-%04d', $this->prefix, $this->date, $this->sequence);
    }

    public function __toString(): string
    {
        return $this->toString();
    }

    /**
     * Genera el siguiente folio para una tabla dada, contando registros del día.
     *
     * @param  string  $table  Tabla completa con schema (ej. 'selemti.purchase_requests')
     * @param  string  $dateColumn  Columna de fecha a usar para contar (default: 'created_at')
     * @param  string  $connection  Conexión DB (default: 'pgsql')
     */
    public static function generate(
        string $prefix,
        string $table,
        string $dateColumn = 'created_at',
        string $connection = 'pgsql',
    ): self {
        $today = now()->format('Ymd');

        $count = DB::connection($connection)
            ->table($table)
            ->whereDate($dateColumn, now()->toDateString())
            ->count();

        return new self(
            prefix: strtoupper($prefix),
            date: $today,
            sequence: $count + 1,
        );
    }

    /**
     * Genera folio con filtro por sucursal/branch (para conteos físicos).
     */
    public static function generateForBranch(
        string $prefix,
        string $table,
        ?string $branchId,
        string $branchColumn = 'sucursal_id',
        string $connection = 'pgsql',
    ): self {
        $today = now()->format('Ymd');
        $resolvedPrefix = $branchId ? strtoupper(str_replace('-', '', $branchId)) : strtoupper($prefix);

        $count = DB::connection($connection)
            ->table($table)
            ->when($branchId, fn ($q) => $q->where($branchColumn, $branchId))
            ->whereDate('created_at', now()->toDateString())
            ->count();

        return new self(
            prefix: $resolvedPrefix,
            date: $today,
            sequence: $count + 1,
        );
    }
}
