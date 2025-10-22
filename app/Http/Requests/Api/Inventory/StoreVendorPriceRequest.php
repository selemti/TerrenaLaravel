<?php

namespace App\Http\Requests\Api\Inventory;

use Illuminate\Foundation\Http\FormRequest;

class StoreVendorPriceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
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

    protected function prepareForValidation(): void
    {
        $itemId = $this->input('item_id');
        $vendorId = $this->input('vendor_id');
        $packUom = $this->input('pack_uom');

        $this->merge([
            'item_id' => $itemId !== null ? trim((string) $itemId) : $itemId,
            'vendor_id' => $vendorId !== null ? trim((string) $vendorId) : $vendorId,
            'pack_uom' => $packUom !== null ? strtoupper(trim((string) $packUom)) : $packUom,
        ]);
    }

    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }

            $itemId = (string) $this->input('item_id');
            $vendorId = (string) $this->input('vendor_id');

            $vendorExists = \Illuminate\Support\Facades\DB::connection('pgsql')
                ->table('selemti.item_vendor')
                ->whereRaw('item_id::text = ?', [$itemId])
                ->whereRaw('vendor_id::text = ?', [$vendorId])
                ->exists();

            if (! $vendorExists) {
                $validator->errors()->add('vendor_id', 'El proveedor no está asociado al ítem indicado.');
            }

            $uom = $this->input('pack_uom');

            $uomExists = \Illuminate\Support\Facades\DB::connection('pgsql')
                ->table('selemti.unidades_medida')
                ->where(function ($query) use ($uom) {
                    $query->whereRaw('UPPER(codigo) = ?', [$uom])
                        ->orWhereRaw('UPPER(nombre) = ?', [$uom]);
                })
                ->exists();

            if (! $uomExists) {
                $validator->errors()->add('pack_uom', 'La unidad de medida indicada no existe en el catálogo.');
            }
        });
    }
}
