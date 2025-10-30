<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;

class InsumoCodeService
{
    /**
     * Genera el siguiente código interno para un insumo en selemti.insumo.
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
     * - Sólo opera sobre selemti.insumo.
     *
     * TODO FUTURO:
     * - Encapsular en una transacción con bloqueo por (CAT,SUB) para evitar colisiones.
     */
    public function generateCode(string $cat, string $sub): array
    {
        $cat = strtoupper(trim($cat));
        $sub = strtoupper(trim($sub));

        // TODO: Esta tabla vive realmente en el esquema selemti. Ajustar conexión/schema en prod.
        $max = DB::table('insumo')
            ->where('categoria_codigo', $cat)
            ->where('subcategoria_codigo', $sub)
            ->max('consecutivo');

        $next = ($max ?? 0) + 1;
        $codigo = sprintf('%s-%s-%05d', $cat, $sub, $next);

        return [
            'codigo'       => $codigo,
            'consecutivo'  => $next,
            'categoria'    => $cat,
            'subcategoria' => $sub,
        ];
    }
}
