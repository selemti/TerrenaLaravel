<?php

namespace Database\Factories\Inventory;

use App\Models\Inventory\TransferLine;
use Illuminate\Database\Eloquent\Factories\Factory;

class TransferLineFactory extends Factory
{
    protected $model = TransferLine::class;

    public function definition(): array
    {
        return [
            'linea' => 1,
            'item_id' => 'ITEM-001',
            'cantidad_solicitada' => 5,
            'cantidad_despachada' => 0,
            'cantidad_recibida' => 0,
            'uom_id' => 1,
            'costo_unitario' => 0,
        ];
    }
}
