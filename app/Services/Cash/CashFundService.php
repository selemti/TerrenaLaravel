<?php

namespace App\Services\Cash;

use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class CashFundService
{
    public function open(array $payload): int
    {
        $data = $this->normalizeOpening($payload);

        return (int) DB::connection('pgsql')->transaction(function () use ($data) {
            $id = DB::table('caja_fondo')->insertGetId($data);

            if (! empty($data['usuarios'])) {
                $this->syncUsers($id, $data['usuarios']);
            }

            return $id;
        });
    }

    public function registerMovement(int $fundId, array $payload): int
    {
        $data = $this->normalizeMovement($payload);
        $data['fondo_id'] = $fundId;

        return (int) DB::connection('pgsql')->table('caja_fondo_mov')->insertGetId($data);
    }

    public function approveMovement(int $movementId, int $approverId): void
    {
        DB::connection('pgsql')->table('caja_fondo_mov')
            ->where('id', $movementId)
            ->update([
                'estatus' => 'APROBADO',
                'aprobado_por' => $approverId,
                'aprobado_en' => now(),
            ]);
    }

    public function recordAttachments(int $movementId, array $files): void
    {
        $rows = collect($files)
            ->filter(fn ($file) => isset($file['archivo_url']))
            ->map(function ($file) use ($movementId) {
                return [
                    'mov_id' => $movementId,
                    'tipo' => Arr::get($file, 'tipo', 'OTRO'),
                    'archivo_url' => Arr::get($file, 'archivo_url'),
                    'observaciones' => Arr::get($file, 'observaciones'),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            })
            ->values();

        if ($rows->isNotEmpty()) {
            DB::connection('pgsql')->table('caja_fondo_adj')->insert($rows->all());
        }
    }

    public function closeFund(int $fundId, array $payload): void
    {
        $data = $this->normalizeClosing($payload);

        DB::connection('pgsql')->transaction(function () use ($fundId, $data) {
            DB::table('caja_fondo_arqueo')->insert([
                'fondo_id' => $fundId,
                'fecha_cierre' => $data['fecha_cierre'],
                'efectivo_contado' => $data['efectivo_contado'],
                'diferencia' => $data['diferencia'],
                'observaciones' => $data['observaciones'],
                'cerrado_por' => $data['cerrado_por'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('caja_fondo')
                ->where('id', $fundId)
                ->update([
                    'estado' => 'CERRADO',
                    'actualizado_en' => now(),
                ]);
        });
    }

    protected function normalizeOpening(array $payload): array
    {
        $data = [
            'sucursal_id' => Arr::get($payload, 'sucursal_id'),
            'fecha' => Arr::get($payload, 'fecha'),
            'monto_inicial' => (float) Arr::get($payload, 'monto_inicial', 0),
            'moneda' => Arr::get($payload, 'moneda', 'MXN'),
            'estado' => Arr::get($payload, 'estado', 'ABIERTO'),
            'creado_por' => Arr::get($payload, 'creado_por'),
            'creado_en' => now(),
            'meta' => Arr::get($payload, 'meta'),
            'usuarios' => Arr::get($payload, 'usuarios', []),
        ];

        if (! $data['sucursal_id'] || ! $data['creado_por']) {
            throw new \InvalidArgumentException('Sucursal y usuario creador son obligatorios.');
        }

        if (! $data['fecha']) {
            $data['fecha'] = now()->toDateString();
        }

        return $data;
    }

    protected function syncUsers(int $fundId, array $users): void
    {
        DB::table('caja_fondo_usuario')->where('fondo_id', $fundId)->delete();

        $rows = collect($users)
            ->map(function ($user) use ($fundId) {
                return [
                    'fondo_id' => $fundId,
                    'user_id' => Arr::get($user, 'user_id'),
                    'rol' => Arr::get($user, 'rol', 'TITULAR'),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            })
            ->filter(fn ($row) => $row['user_id'])
            ->values();

        if ($rows->isNotEmpty()) {
            DB::table('caja_fondo_usuario')->insert($rows->all());
        }
    }

    protected function normalizeMovement(array $payload): array
    {
        $amount = (float) Arr::get($payload, 'monto', 0);

        if ($amount <= 0) {
            throw new \InvalidArgumentException('El monto debe ser mayor a cero.');
        }

        return [
            'fecha_hora' => Arr::get($payload, 'fecha_hora', now()),
            'tipo' => Arr::get($payload, 'tipo', 'EGRESO'),
            'concepto' => Arr::get($payload, 'concepto'),
            'proveedor_id' => Arr::get($payload, 'proveedor_id'),
            'monto' => $amount,
            'metodo' => Arr::get($payload, 'metodo', 'EFECTIVO'),
            'requiere_comprobante' => (bool) Arr::get($payload, 'requiere_comprobante', false),
            'estatus' => Arr::get($payload, 'estatus', 'CAPTURADO'),
            'creado_por' => Arr::get($payload, 'creado_por'),
            'meta' => Arr::get($payload, 'meta'),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }

    protected function normalizeClosing(array $payload): array
    {
        $counted = (float) Arr::get($payload, 'efectivo_contado', 0);

        return [
            'fecha_cierre' => Arr::get($payload, 'fecha_cierre', now()),
            'efectivo_contado' => $counted,
            'diferencia' => (float) Arr::get($payload, 'diferencia', 0),
            'observaciones' => Arr::get($payload, 'observaciones'),
            'cerrado_por' => Arr::get($payload, 'cerrado_por'),
        ];
    }
}
