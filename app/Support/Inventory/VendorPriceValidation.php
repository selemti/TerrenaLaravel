<?php

namespace App\Support\Inventory;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Support\Facades\DB;

class VendorPriceValidation
{
    public static function sanitize(array $input): array
    {
        $itemId = $input['item_id'] ?? null;
        $vendorId = $input['vendor_id'] ?? null;
        $packUom = $input['pack_uom'] ?? null;

        $input['item_id'] = $itemId !== null ? trim((string) $itemId) : $itemId;
        $input['vendor_id'] = $vendorId !== null ? trim((string) $vendorId) : $vendorId;
        $input['pack_uom'] = $packUom !== null ? strtoupper(trim((string) $packUom)) : $packUom;

        return $input;
    }

    public static function rules(): array
    {
        return [
            'item_id' => ['required'],
            'vendor_id' => ['required'],
            'price' => ['required', 'numeric', 'gte:0'],
            'pack_qty' => ['required', 'numeric', 'gt:0'],
            'pack_uom' => ['required', 'string', 'max:16'],
            'effective_from' => ['nullable', 'date'],
            'notes' => ['nullable', 'string'],
            'source' => ['nullable', 'string', 'max:50'],
        ];
    }

    public static function afterValidation(Validator $validator, array $input): void
    {
        if ($validator->errors()->isNotEmpty()) {
            return;
        }

        $itemId = isset($input['item_id']) ? (string) $input['item_id'] : null;
        $vendorId = isset($input['vendor_id']) ? (string) $input['vendor_id'] : null;

        if ($itemId !== null && $vendorId !== null) {
            $vendorExists = DB::connection('pgsql')
                ->table('selemti.item_vendor')
                ->whereRaw('item_id::text = ?', [$itemId])
                ->whereRaw('vendor_id::text = ?', [$vendorId])
                ->exists();

            if (! $vendorExists) {
                $validator->errors()->add('vendor_id', 'El proveedor no está asociado al ítem indicado.');
            }
        }

        $uom = $input['pack_uom'] ?? null;

        if ($uom !== null) {
            $uomExists = DB::connection('pgsql')
                ->table('selemti.unidades_medida')
                ->where(function ($query) use ($uom) {
                    $query->whereRaw('UPPER(codigo) = ?', [$uom])
                        ->orWhereRaw('UPPER(nombre) = ?', [$uom]);
                })
                ->exists();

            if (! $uomExists) {
                $validator->errors()->add('pack_uom', 'La unidad de medida indicada no existe en el catálogo.');
            }
        }
    }
}
