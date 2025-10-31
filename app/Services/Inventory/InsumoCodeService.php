<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;

class InsumoCodeService
{
    /**
     * Genera el siguiente código interno para un insumo en selemti.items.
     *
     * Formato final: CAT-SUB-00001
     *
     * Donde:
     *   CAT = categoria_codigo (ej. MP, PT, EM, LIM, SRV)
     *   SUB = subcategoria_codigo (ej. LAC, BOT, DET...)
     *   consecutivo = contador incremental por cada par (CAT,SUB)
     *
     * IMPORTANTE:
     * - Esto NO toca public.item (POS).
     * - Opera sobre selemti.items extrayendo el consecutivo del campo id.
     *
     * TODO FUTURO:
     * - Encapsular en una transacción con bloqueo por (CAT,SUB) para evitar colisiones.
     */
    public function generateCode(string $cat, string $sub): array
    {
        $cat = strtoupper(trim($cat));
        $sub = strtoupper(trim($sub));

        // Consultar el consecutivo máximo en selemti.items analizando el patrón del id
        $pattern = $cat . '-' . $sub . '-%';
        $maxId = DB::connection('pgsql')->table('selemti.items')
            ->where('id', 'like', $pattern)
            ->orderByRaw('id DESC')
            ->value('id');

        $next = 1;
        if ($maxId) {
            // Extraer el consecutivo del formato CAT-SUB-00001
            $parts = explode('-', $maxId);
            if (count($parts) === 3) {
                $next = (int) $parts[2] + 1;
            }
        }

        $codigo = sprintf('%s-%s-%05d', $cat, $sub, $next);

        return [
            'codigo'       => $codigo,
            'consecutivo'  => $next,
            'categoria'    => $cat,
            'subcategoria' => $sub,
        ];
    }
}
