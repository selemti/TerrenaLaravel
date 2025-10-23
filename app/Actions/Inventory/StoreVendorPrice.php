<?php

namespace App\Actions\Inventory;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class StoreVendorPrice
{
    public function execute(array $payload): array
    {
        $effectiveFrom = isset($payload['effective_from'])
            ? Carbon::parse($payload['effective_from'])
            : now();

        $record = [
            'item_id' => $payload['item_id'],
            'vendor_id' => $payload['vendor_id'],
            'price' => $payload['price'],
            'pack_qty' => $payload['pack_qty'],
            'pack_uom' => strtoupper($payload['pack_uom']),
            'source' => $payload['source'] ?? null,
            'notes' => $payload['notes'] ?? null,
            'effective_from' => $effectiveFrom->toDateTimeString(),
        ];

        DB::connection('pgsql')
            ->table('selemti.item_vendor_prices')
            ->insert($record);

        $latest = DB::connection('pgsql')->selectOne(
            <<<'SQL'
SELECT item_id, vendor_id, price, pack_qty, pack_uom, effective_from
FROM selemti.vw_item_last_price
WHERE item_id::text = ? AND vendor_id::text = ?
LIMIT 1
SQL,
            [(string) $record['item_id'], (string) $record['vendor_id']]
        );

        return $latest ? (array) $latest : $record;
    }
}
