<?php

namespace App\Services\Inventory;

use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class PosConsumptionService
{
    public function expandTicket(int $ticketId): void
    {
        $connection = DB::connection('pgsql');
        $connection->statement('SELECT selemti.fn_expandir_consumo_ticket(?)', [$ticketId]);
    }

    public function confirmTicket(int $ticketId): void
    {
        $connection = DB::connection('pgsql');

        $connection->transaction(static function () use ($connection, $ticketId) {
            $connection->statement('SELECT selemti.fn_confirmar_consumo_ticket(?)', [$ticketId]);
        }, 5);
    }

    public function reverseTicket(int $ticketId): void
    {
        $connection = DB::connection('pgsql');

        $connection->transaction(static function () use ($connection, $ticketId) {
            $connection->statement('SELECT selemti.fn_reversar_consumo_ticket(?)', [$ticketId]);
        }, 5);
    }

    public function normalizeLine(array $line): array
    {
        $normalized = [
            'item_id' => (int) Arr::get($line, 'item_id'),
            'uom' => Arr::get($line, 'uom'),
            'cantidad' => (float) Arr::get($line, 'cantidad', 0),
            'factor' => (float) Arr::get($line, 'factor', 1),
            'origen' => Arr::get($line, 'origen', 'RECETA'),
            'meta' => Arr::get($line, 'meta', []),
        ];

        if ($normalized['cantidad'] <= 0) {
            throw new \InvalidArgumentException('La cantidad debe ser mayor a cero.');
        }

        return $normalized;
    }
}
