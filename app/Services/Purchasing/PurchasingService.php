<?php

namespace App\Services\Purchasing;

use Carbon\CarbonImmutable;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use RuntimeException;

class PurchasingService
{
    /**
     * CREA una solicitud de compra (purchase_request) + sus líneas.
     * Versión CRUD directa en BD (usa DB::connection).
     */
    public function createRequest(array $payload): array
    {
        $data = $this->validateRequestPayload($payload);

        return DB::connection('pgsql')->transaction(function () use ($data) {
            $folio = $data['folio'] ?? $this->generateFolio('PR', 'selemti.purchase_requests');

            $requestId = DB::connection('pgsql')
                ->table('selemti.purchase_requests')
                ->insertGetId([
                    'folio'              => $folio,
                    'sucursal_id'        => $data['sucursal_id'] ?? null,
                    'created_by'         => $data['created_by'],
                    'requested_by'       => $data['requested_by'] ?? null,
                    'requested_at'       => $data['requested_at'] ?? CarbonImmutable::now(),
                    'estado'             => $data['estado'] ?? 'BORRADOR',
                    'importe_estimado'   => $this->calculateEstimatedAmount($data['lineas']),
                    'notas'              => $data['notas'] ?? null,
                    'meta'               => $this->encodeMeta($data['meta'] ?? null),
                    'created_at'         => CarbonImmutable::now(),
                    'updated_at'         => CarbonImmutable::now(),
                ]);

            foreach ($data['lineas'] as $line) {
                DB::connection('pgsql')
                    ->table('selemti.purchase_request_lines')
                    ->insert([
                        'request_id'           => $requestId,
                        'item_id'              => $line['item_id'],
                        'qty'                  => $line['qty'],
                        'uom'                  => $line['uom'],
                        'fecha_requerida'      => $line['fecha_requerida'] ?? null,
                        'preferred_vendor_id'  => $line['preferred_vendor_id'] ?? null,
                        'last_price'           => $line['last_price'] ?? null,
                        'estado'               => $line['estado'] ?? 'PENDIENTE',
                        'meta'                 => $this->encodeMeta($line['meta'] ?? null),
                        'created_at'           => CarbonImmutable::now(),
                        'updated_at'           => CarbonImmutable::now(),
                    ]);
            }

            return $this->findRequestById($requestId);
        });
    }

    /**
     * AGREGA cotización de proveedor a una solicitud.
     * Cambia estado de la solicitud a COTIZADA.
     */
    public function submitQuote(int $requestId, array $payload): array
    {
        $request = $this->findRequestById($requestId);

        if (!$request) {
            throw new RuntimeException('Solicitud de compra no encontrada');
        }

        $data = $this->validateQuotePayload($requestId, $payload);

        return DB::connection('pgsql')->transaction(function () use ($requestId, $data) {
            $quoteId = DB::connection('pgsql')
                ->table('selemti.purchase_vendor_quotes')
                ->insertGetId([
                    'request_id'      => $requestId,
                    'vendor_id'       => $data['vendor_id'],
                    'folio_proveedor' => $data['folio_proveedor'] ?? null,
                    'estado'          => $data['estado'] ?? 'RECIBIDA',
                    'enviada_en'      => $data['enviada_en'] ?? CarbonImmutable::now(),
                    'recibida_en'     => $data['recibida_en'] ?? CarbonImmutable::now(),
                    'subtotal'        => $data['subtotal'],
                    'descuento'       => $data['descuento'],
                    'impuestos'       => $data['impuestos'],
                    'total'           => $data['total'],
                    'capturada_por'   => $data['capturada_por'] ?? null,
                    'aprobada_por'    => null,
                    'aprobada_en'     => null,
                    'notas'           => $data['notas'] ?? null,
                    'meta'            => $this->encodeMeta($data['meta'] ?? null),
                    'created_at'      => CarbonImmutable::now(),
                    'updated_at'      => CarbonImmutable::now(),
                ]);

            foreach ($data['lineas'] as $line) {
                DB::connection('pgsql')
                    ->table('selemti.purchase_vendor_quote_lines')
                    ->insert([
                        'quote_id'         => $quoteId,
                        'request_line_id'  => $line['request_line_id'],
                        'item_id'          => $line['item_id'],
                        'qty_oferta'       => $line['qty_oferta'],
                        'uom_oferta'       => $line['uom_oferta'],
                        'precio_unitario'  => $line['precio_unitario'],
                        'pack_size'        => $line['pack_size'] ?? 1,
                        'pack_uom'         => $line['pack_uom'] ?? null,
                        'monto_total'      => $line['monto_total'],
                        'meta'             => $this->encodeMeta($line['meta'] ?? null),
                        'created_at'       => CarbonImmutable::now(),
                        'updated_at'       => CarbonImmutable::now(),
                    ]);
            }

            DB::connection('pgsql')
                ->table('selemti.purchase_requests')
                ->where('id', $requestId)
                ->update([
                    'estado'     => 'COTIZADA',
                    'updated_at' => CarbonImmutable::now(),
                ]);

            return $this->findQuoteById($quoteId);
        });
    }

    /**
     * APRUEBA una cotización → actualiza estado de la solicitud.
     */
    public function approveQuote(int $quoteId, int $userId): array
    {
        $quote = $this->findQuoteById($quoteId);

        if (!$quote) {
            throw new RuntimeException('Cotización no encontrada');
        }

        if ($quote['estado'] === 'APROBADA') {
            return $quote;
        }

        DB::connection('pgsql')->transaction(function () use ($quoteId, $userId, $quote) {
            DB::connection('pgsql')
                ->table('selemti.purchase_vendor_quotes')
                ->where('id', $quoteId)
                ->update([
                    'estado'       => 'APROBADA',
                    'aprobada_por' => $userId,
                    'aprobada_en'  => CarbonImmutable::now(),
                    'updated_at'   => CarbonImmutable::now(),
                ]);

            DB::connection('pgsql')
                ->table('selemti.purchase_requests')
                ->where('id', $quote['request_id'])
                ->update([
                    'estado'     => 'APROBADA',
                    'updated_at' => CarbonImmutable::now(),
                ]);
        });

        return $this->findQuoteById($quoteId);
    }

    /**
     * GENERA Orden de compra (purchase_order) desde cotización aprobada.
     * También llena las líneas de la orden.
     */
    public function issuePurchaseOrder(int $quoteId, array $payload): array
    {
        $quote = $this->findQuoteById($quoteId);

        if (!$quote) {
            throw new RuntimeException('Cotización no encontrada');
        }

        if ($quote['estado'] !== 'APROBADA') {
            throw new RuntimeException('Solo se pueden generar órdenes desde una cotización aprobada');
        }

        $data = $this->validateOrderPayload($quote, $payload);

        return DB::connection('pgsql')->transaction(function () use ($quote, $data) {
            $folio = $data['folio'] ?? $this->generateFolio('OC', 'selemti.purchase_orders');

            $orderId = DB::connection('pgsql')
                ->table('selemti.purchase_orders')
                ->insertGetId([
                    'folio'         => $folio,
                    'quote_id'      => $quote['id'],
                    'vendor_id'     => $quote['vendor_id'],
                    'sucursal_id'   => $data['sucursal_id'] ?? null,
                    'estado'        => $data['estado'] ?? 'BORRADOR',
                    'fecha_promesa' => $data['fecha_promesa'] ?? null,
                    'subtotal'      => $data['subtotal'],
                    'descuento'     => $data['descuento'],
                    'impuestos'     => $data['impuestos'],
                    'total'         => $data['total'],
                    'creado_por'    => $data['creado_por'],
                    'aprobado_por'  => $data['aprobado_por'] ?? null,
                    'aprobado_en'   => $data['aprobado_por'] ? CarbonImmutable::now() : null,
                    'notas'         => $data['notas'] ?? null,
                    'meta'          => $this->encodeMeta($data['meta'] ?? null),
                    'created_at'    => CarbonImmutable::now(),
                    'updated_at'    => CarbonImmutable::now(),
                ]);

            foreach ($data['lineas'] as $line) {
                DB::connection('pgsql')
                    ->table('selemti.purchase_order_lines')
                    ->insert([
                        'order_id'         => $orderId,
                        'request_line_id'  => $line['request_line_id'] ?? null,
                        'item_id'          => $line['item_id'],
                        'qty'              => $line['qty'],
                        'uom'              => $line['uom'],
                        'precio_unitario'  => $line['precio_unitario'],
                        'descuento'        => $line['descuento'] ?? 0,
                        'impuestos'        => $line['impuestos'] ?? 0,
                        'total'            => $line['total'],
                        'meta'             => $this->encodeMeta($line['meta'] ?? null),
                        'created_at'       => CarbonImmutable::now(),
                        'updated_at'       => CarbonImmutable::now(),
                    ]);
            }

            DB::connection('pgsql')
                ->table('selemti.purchase_requests')
                ->where('id', $quote['request_id'])
                ->update([
                    'estado'     => 'ORDENADA',
                    'updated_at' => CarbonImmutable::now(),
                ]);

            return $this->findOrderById($orderId);
        });
    }

    /**
     * NUEVO: Lista sugerencias de compra con filtros y sus líneas.
     */
    public function listSuggestions(array $filters = []): array
    {
        $query = DB::connection('pgsql')
            ->table('selemti.purchase_suggestions as ps')
            ->select([
                'ps.*',
                's.nombre as sucursal_nombre',
                'a.nombre as almacen_nombre',
            ])
            ->leftJoin('selemti.cat_sucursales as s', 's.id', '=', 'ps.sucursal_id')
            ->leftJoin('selemti.cat_almacenes as a', 'a.id', '=', 'ps.almacen_id');

        if (!empty($filters['estado'])) {
            $query->where('ps.estado', $filters['estado']);
        }

        if (!empty($filters['prioridad'])) {
            $query->where('ps.prioridad', $filters['prioridad']);
        }

        if (!empty($filters['sucursal_id'])) {
            $query->where('ps.sucursal_id', $filters['sucursal_id']);
        }

        $suggestions = $query
            ->orderBy('ps.sugerido_en', 'desc')
            ->get();

        return $suggestions->map(function ($suggestion) {
            $lines = DB::connection('pgsql')
                ->table('selemti.purchase_suggestion_lines as psl')
                ->select([
                    'psl.*',
                    'i.nombre as item_nombre',
                    'i.item_code as item_codigo',
                ])
                ->leftJoin('selemti.items as i', 'i.id', '=', 'psl.item_id')
                ->where('psl.suggestion_id', $suggestion->id)
                ->get()
                ->map(fn ($row) => (array) $row)
                ->all();

            $payload = (array) $suggestion;
            $payload['lines'] = $lines;

            return $payload;
        })->all();
    }

    /**
     * NUEVO: Aprueba sugerencia (estado = APROBADA).
     */
    public function approveSuggestion(int $suggestionId, int $userId): array
    {
        return DB::connection('pgsql')->transaction(function () use ($suggestionId, $userId) {
            DB::connection('pgsql')
                ->table('selemti.purchase_suggestions')
                ->where('id', $suggestionId)
                ->update([
                    'estado'                => 'APROBADA',
                    'revisado_por_user_id'  => $userId,
                    'revisado_en'           => CarbonImmutable::now(),
                    'updated_at'            => CarbonImmutable::now(),
                ]);

            $suggestion = DB::connection('pgsql')
                ->table('selemti.purchase_suggestions')
                ->where('id', $suggestionId)
                ->first();

            return (array) $suggestion;
        });
    }

    /**
     * NUEVO: Convierte una sugerencia aprobada en una purchase_request real.
     */
    public function convertSuggestionToRequest(int $suggestionId, int $userId): array
    {
        return DB::connection('pgsql')->transaction(function () use ($suggestionId, $userId) {
            // 1. Traer sugerencia
            $suggestion = DB::connection('pgsql')
                ->table('selemti.purchase_suggestions')
                ->where('id', $suggestionId)
                ->first();

            if (!$suggestion) {
                throw new RuntimeException('Sugerencia no encontrada');
            }

            // 2. Traer detalle
            $lines = DB::connection('pgsql')
                ->table('selemti.purchase_suggestion_lines')
                ->where('suggestion_id', $suggestionId)
                ->get();

            // 3. Crear la solicitud de compra (purchase_request)
            $folio = $this->generateFolio('REQ', 'selemti.purchase_requests');

            $requestId = DB::connection('pgsql')
                ->table('selemti.purchase_requests')
                ->insertGetId([
                    'folio'                 => $folio,
                    'sucursal_id'           => $suggestion->sucursal_id,
                    'created_by'            => $userId,
                    'requested_by'          => $userId,
                    'requested_at'          => CarbonImmutable::now(),
                    'estado'                => 'PENDIENTE',
                    'importe_estimado'      => $suggestion->total_estimado ?? 0,
                    'notas'                 => $suggestion->notas,
                    'meta'                  => $suggestion->meta,
                    'fecha_requerida'       => null,
                    'almacen_destino_id'    => $suggestion->almacen_id,
                    'justificacion'         => "Generada automáticamente desde sugerencia {$suggestion->folio}",
                    'urgente'               => $suggestion->prioridad === 'URGENTE',
                    'origen_suggestion_id'  => $suggestionId,
                    'created_at'            => CarbonImmutable::now(),
                    'updated_at'            => CarbonImmutable::now(),
                ]);

            // 4. Por cada línea sugerida -> línea en purchase_request_lines
            foreach ($lines as $line) {
                $qtyToRequest = $line->qty_ajustada ?? $line->qty_sugerida;

                DB::connection('pgsql')
                    ->table('selemti.purchase_request_lines')
                    ->insert([
                        'request_id'           => $requestId,
                        'item_id'              => $line->item_id,
                        'qty'                  => $qtyToRequest,
                        'uom'                  => $line->uom,
                        'fecha_requerida'      => null,
                        'preferred_vendor_id'  => $line->proveedor_sugerido_id,
                        'last_price'           => $line->costo_unitario_estimado,
                        'estado'               => 'PENDIENTE',
                        'meta'                 => null,
                        'created_at'           => CarbonImmutable::now(),
                        'updated_at'           => CarbonImmutable::now(),
                    ]);
            }

            // 5. Marcar la sugerencia como CONVERTIDA
            DB::connection('pgsql')
                ->table('selemti.purchase_suggestions')
                ->where('id', $suggestionId)
                ->update([
                    'estado'                     => 'CONVERTIDA',
                    'convertido_a_request_id'    => $requestId,
                    'convertido_en'              => CarbonImmutable::now(),
                    'updated_at'                 => CarbonImmutable::now(),
                ]);

            return [
                'request_id'    => $requestId,
                'suggestion_id' => $suggestionId,
            ];
        });
    }

    /* --------------------------- helpers internos --------------------------- */

    protected function validateRequestPayload(array $payload): array
    {
        $validator = Validator::make($payload, [
            'folio'                 => ['nullable', 'string', 'max:40'],
            'sucursal_id'           => ['nullable', 'string', 'max:36'],
            'created_by'            => ['required', 'integer'],
            'requested_by'          => ['nullable', 'integer'],
            'requested_at'          => ['nullable', 'date'],
            'estado'                => ['nullable', Rule::in(['BORRADOR', 'COTIZADA', 'APROBADA', 'ORDENADA'])],
            'notas'                 => ['nullable', 'string'],
            'meta'                  => ['nullable'],
            'lineas'                => ['required', 'array', 'min:1'],
            'lineas.*.item_id'      => ['required', 'integer'],
            'lineas.*.qty'          => ['required', 'numeric'],
            'lineas.*.uom'          => ['required', 'string', 'max:20'],
            'lineas.*.fecha_requerida'     => ['nullable', 'date'],
            'lineas.*.preferred_vendor_id' => ['nullable', 'integer'],
            'lineas.*.last_price'          => ['nullable', 'numeric'],
            'lineas.*.estado'              => ['nullable', 'string', 'max:24'],
            'lineas.*.meta'                => ['nullable'],
        ]);

        return $validator->validate();
    }

    protected function validateQuotePayload(int $requestId, array $payload): array
    {
        $validator = Validator::make($payload, [
            'vendor_id'           => ['required', 'integer'],
            'folio_proveedor'     => ['nullable', 'string', 'max:60'],
            'estado'              => ['nullable', Rule::in(['RECIBIDA', 'APROBADA', 'RECHAZADA'])],
            'enviada_en'          => ['nullable', 'date'],
            'recibida_en'         => ['nullable', 'date'],
            'capturada_por'       => ['nullable', 'integer'],
            'notas'               => ['nullable', 'string'],
            'meta'                => ['nullable'],
            'lineas'              => ['required', 'array', 'min:1'],
            'lineas.*.request_line_id' => ['required', 'integer'],
            'lineas.*.item_id'         => ['required', 'integer'],
            'lineas.*.qty_oferta'      => ['required', 'numeric'],
            'lineas.*.uom_oferta'      => ['required', 'string', 'max:20'],
            'lineas.*.precio_unitario' => ['required', 'numeric'],
            'lineas.*.pack_size'       => ['nullable', 'numeric'],
            'lineas.*.pack_uom'        => ['nullable', 'string', 'max:20'],
            'lineas.*.monto_total'     => ['nullable', 'numeric'],
            'lineas.*.meta'            => ['nullable'],
        ]);

        $data = $validator->validate();

        $lineCollection = collect($data['lineas'])->map(function (array $line) use ($requestId) {
            $line['monto_total'] = $line['monto_total']
                ?? ($line['qty_oferta'] * $line['precio_unitario']);

            $line['request_line_id'] = $this->assertRequestLineBelongsToRequest(
                $requestId,
                $line['request_line_id']
            );

            return $line;
        });

        $data['lineas']   = $lineCollection->all();
        $data['subtotal'] = $lineCollection->sum('monto_total');
        $data['descuento'] = Arr::get($payload, 'descuento', 0) ?? 0;
        $data['impuestos'] = Arr::get($payload, 'impuestos', 0) ?? 0;
        $data['total']     = $data['subtotal'] - $data['descuento'] + $data['impuestos'];

        return $data;
    }

    protected function validateOrderPayload(array $quote, array $payload): array
    {
        $validator = Validator::make($payload, [
            'folio'         => ['nullable', 'string', 'max:40'],
            'sucursal_id'   => ['nullable', 'string', 'max:36'],
            'estado'        => ['nullable', Rule::in(['BORRADOR', 'APROBADA', 'ENVIADA', 'RECIBIDA', 'CERRADA'])],
            'fecha_promesa' => ['nullable', 'date'],
            'creado_por'    => ['required', 'integer'],
            'aprobado_por'  => ['nullable', 'integer'],
            'notas'         => ['nullable', 'string'],
            'meta'          => ['nullable'],
            'lineas'        => ['nullable', 'array'],
            'lineas.*.request_line_id' => ['nullable', 'integer'],
            'lineas.*.item_id'         => ['required', 'integer'],
            'lineas.*.qty'             => ['required', 'numeric'],
            'lineas.*.uom'             => ['required', 'string', 'max:20'],
            'lineas.*.precio_unitario' => ['required', 'numeric'],
            'lineas.*.descuento'       => ['nullable', 'numeric'],
            'lineas.*.impuestos'       => ['nullable', 'numeric'],
            'lineas.*.total'           => ['nullable', 'numeric'],
            'lineas.*.meta'            => ['nullable'],
        ]);

        $data = $validator->validate();

        $lines = collect($data['lineas'] ?? $this->inferOrderLinesFromQuote($quote))
            ->map(function (array $line) {
                $line['total'] = $line['total']
                    ?? ($line['qty'] * $line['precio_unitario'])
                    - ($line['descuento'] ?? 0)
                    + ($line['impuestos'] ?? 0);

                return $line;
            });

        $data['lineas']   = $lines->all();
        $data['subtotal'] = $lines->sum(function ($line) {
            return ($line['qty'] * $line['precio_unitario']);
        });
        $data['descuento'] = Arr::get($payload, 'descuento', $lines->sum('descuento')) ?? 0;
        $data['impuestos'] = Arr::get($payload, 'impuestos', $lines->sum('impuestos')) ?? 0;
        $data['total']     = $lines->sum('total');

        return $data;
    }

    protected function inferOrderLinesFromQuote(array $quote): array
    {
        $lines = DB::connection('pgsql')
            ->table('selemti.purchase_vendor_quote_lines')
            ->select([
                'request_line_id',
                'item_id',
                'qty_oferta as qty',
                'uom_oferta as uom',
                'precio_unitario',
                'monto_total as total',
            ])
            ->where('quote_id', $quote['id'])
            ->get();

        return $lines->map(function ($line) {
            $line          = (array) $line;
            $line['descuento'] = 0;
            $line['impuestos'] = 0;
            return $line;
        })->all();
    }

    protected function calculateEstimatedAmount(array $lines): float
    {
        return collect($lines)->sum(function ($line) {
            $qty   = (float) $line['qty'];
            $price = (float) ($line['last_price'] ?? 0);
            return $qty * $price;
        });
    }

    /**
     * Genera folio incremental con prefijo.
     * Ej: "REQ-202510-0007"
     */
    protected function generateFolio(string $prefix, string $table): string
    {
        $sequence = DB::connection('pgsql')
            ->table($table)
            ->select('id')
            ->orderByDesc('id')
            ->limit(1)
            ->value('id');

        $number = ($sequence ?? 0) + 1;

        return sprintf(
            '%s-%s-%04d',
            $prefix,
            CarbonImmutable::now()->format('Ym'),
            $number
        );
    }

    protected function findRequestById(int $requestId): ?array
    {
        $request = DB::connection('pgsql')
            ->table('selemti.purchase_requests')
            ->where('id', $requestId)
            ->first();

        if (!$request) {
            return null;
        }

        $lines = DB::connection('pgsql')
            ->table('selemti.purchase_request_lines')
            ->where('request_id', $requestId)
            ->get()
            ->map(fn ($row) => (array) $row)
            ->all();

        $payload           = (array) $request;
        $payload['lineas'] = $lines;

        return $payload;
    }

    protected function findQuoteById(int $quoteId): ?array
    {
        $quote = DB::connection('pgsql')
            ->table('selemti.purchase_vendor_quotes')
            ->where('id', $quoteId)
            ->first();

        if (!$quote) {
            return null;
        }

        $lines = DB::connection('pgsql')
            ->table('selemti.purchase_vendor_quote_lines')
            ->where('quote_id', $quoteId)
            ->get()
            ->map(fn ($row) => (array) $row)
            ->all();

        $payload           = (array) $quote;
        $payload['lineas'] = $lines;

        return $payload;
    }

    protected function findOrderById(int $orderId): array
    {
        $order = DB::connection('pgsql')
            ->table('selemti.purchase_orders')
            ->where('id', $orderId)
            ->first();

        $lines = DB::connection('pgsql')
            ->table('selemti.purchase_order_lines')
            ->where('order_id', $orderId)
            ->get()
            ->map(fn ($row) => (array) $row)
            ->all();

        $payload           = (array) $order;
        $payload['lineas'] = $lines;

        return $payload;
    }

    /**
     * Valida que una línea pertenece a la request indicada.
     */
    protected function assertRequestLineBelongsToRequest(int $requestId, int $lineId): int
    {
        $belongs = DB::connection('pgsql')
            ->table('selemti.purchase_request_lines')
            ->where('id', $lineId)
            ->where('request_id', $requestId)
            ->exists();

        if (!$belongs) {
            throw new RuntimeException('La línea indicada no pertenece a la solicitud.');
        }

        return $lineId;
    }

    /**
     * Meta en JSON string (o null).
     */
    protected function encodeMeta(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        if (is_string($value)) {
            return $value;
        }

        return json_encode(
            $value,
            JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
        );
    }
}
