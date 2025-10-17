<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use App\Http\Requests\Caja\CreatePostcorteRequest;
use App\Http\Requests\Caja\UpdatePostcorteRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

class PostcorteController extends Controller
{
    /**
     * Crear postcorte desde precorte
     *
     * Note: Session status will be automatically set to 'CERRADA' by the
     * trg_postcorte_after_insert trigger when the postcorte is created.
     */
    public function create(CreatePostcorteRequest $request): JsonResponse
    {
        $precorteId = (int) $request->validated('precorte_id');

        try {
            if ($precorteId <= 0) {
                return response()->json(['ok' => false, 'error' => 'missing_precorte_or_id'], 400);
            }

            $ses = $this->getSesionByPrecorte($precorteId);
            
            if (!$ses) {
                return response()->json(['ok' => false, 'error' => 'precorte_not_found'], 404);
            }

            $sid = (int) $ses['sesion_id'];
            $tid = (int) $ses['terminal_id'];
            $a = $ses['apertura_ts'];
            $b = $ses['cierre_ts'];

            $dec = $this->totalesDeclarados($precorteId);
            $sys = $this->totalesSistema($tid, $a, $b);

            $difEf = $dec['efectivo'] - $sys['efectivo'];
            $difTj = $dec['tarjetas'] - $sys['tarjetas'];
            $difTr = $dec['transfer'] - $sys['transfer'];

            $usr = auth()->user()->id ?? 1;
            $notas = trim($request->validated('notas') ?? '');

            $sql = "
                INSERT INTO selemti.postcorte (
                    sesion_id,
                    sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo,
                    sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas,
                    sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias,
                    creado_en, creado_por, notas
                ) VALUES (
                    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?
                )
                ON CONFLICT (sesion_id) DO UPDATE SET
                    sistema_efectivo_esperado = EXCLUDED.sistema_efectivo_esperado,
                    declarado_efectivo = EXCLUDED.declarado_efectivo,
                    diferencia_efectivo = EXCLUDED.diferencia_efectivo,
                    veredicto_efectivo = EXCLUDED.veredicto_efectivo,
                    sistema_tarjetas = EXCLUDED.sistema_tarjetas,
                    declarado_tarjetas = EXCLUDED.declarado_tarjetas,
                    diferencia_tarjetas = EXCLUDED.diferencia_tarjetas,
                    veredicto_tarjetas = EXCLUDED.veredicto_tarjetas,
                    sistema_transferencias = EXCLUDED.sistema_transferencias,
                    declarado_transferencias = EXCLUDED.declarado_transferencias,
                    diferencia_transferencias = EXCLUDED.diferencia_transferencias,
                    veredicto_transferencias = EXCLUDED.veredicto_transferencias,
                    notas = EXCLUDED.notas
                RETURNING id
            ";

            $result = DB::selectOne($sql, [
                $sid,
                $sys['efectivo'], $dec['efectivo'], $difEf, $this->ver($difEf),
                $sys['tarjetas'], $dec['tarjetas'], $difTj, $this->ver($difTj),
                $sys['transfer'], $dec['transfer'], $difTr, $this->ver($difTr),
                $usr, $notas
            ]);

            $id = (int) $result->id;

            return response()->json([
                'ok' => true,
                'postcorte_id' => $id,
                'sesion_id' => $sid
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en create postcorte (precorte_id: $precorteId): " . $e->getMessage());
            
            // Auditoría
            try {
                DB::insert("
                    INSERT INTO selemti.auditoria (quien, que, payload) 
                    VALUES (1, 'postcorte.error', ?)
                ", [json_encode([
                    'precorte_id' => $precorteId,
                    'msg' => $e->getMessage()
                ])]);
            } catch (\Exception $e2) {}

            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al crear postcorte'
            ], 500);
        }
    }

    /**
     * Actualizar postcorte
     *
     * When validado=true, marks the postcorte as validated and can
     * optionally update the session status to 'CONCILIADA'.
     */
    public function update(UpdatePostcorteRequest $request, $postId = null): JsonResponse
    {
        $validated = $request->validated();
        $postId = $postId ?? (int) $request->input('id', 0);

        try {
            if ($postId <= 0) {
                return response()->json(['ok' => false, 'error' => 'missing_id'], 400);
            }

            $ses = $this->getSesionByPostId($postId);
            
            if (!$ses) {
                return response()->json(['ok' => false, 'error' => 'postcorte_not_found'], 404);
            }

            $sid = (int) $ses['sesion_id'];
            $tid = (int) $ses['terminal_id'];
            $a = $ses['apertura_ts'];
            $b = $ses['cierre_ts'];

            $pid = $this->getUltimoPrecorteDeSesion($sid);
            
            if (!$pid) {
                return response()->json(['ok' => false, 'error' => 'no_precorte_for_session'], 409);
            }

            $dec = $this->totalesDeclarados($pid);
            $sys = $this->totalesSistema($tid, $a, $b);

            $difEf = $dec['efectivo'] - $sys['efectivo'];
            $difTj = $dec['tarjetas'] - $sys['tarjetas'];
            $difTr = $dec['transfer'] - $sys['transfer'];

            $verE = $validated['veredicto_efectivo'] ?? $this->ver($difEf);
            $verT = $validated['veredicto_tarjetas'] ?? $this->ver($difTj);
            $verR = $validated['veredicto_transferencias'] ?? $this->ver($difTr);
            $notas = trim($validated['notas'] ?? '');
            $valid = $validated['validado'] ?? null;
            $sesionEstatus = $validated['sesion_estatus'] ?? null;
            $usr = auth()->user()->id ?? 1;

            $sql = "
                UPDATE selemti.postcorte SET
                    sistema_efectivo_esperado = ?,
                    declarado_efectivo = ?,
                    diferencia_efectivo = ?,
                    veredicto_efectivo = ?,
                    sistema_tarjetas = ?,
                    declarado_tarjetas = ?,
                    diferencia_tarjetas = ?,
                    veredicto_tarjetas = ?,
                    sistema_transferencias = ?,
                    declarado_transferencias = ?,
                    diferencia_transferencias = ?,
                    veredicto_transferencias = ?,
                    notas = ?,
                    validado = COALESCE(?, validado),
                    validado_por = CASE WHEN COALESCE(?, false) = true THEN ? ELSE validado_por END,
                    validado_en = CASE WHEN COALESCE(?, false) = true THEN NOW() ELSE validado_en END
                WHERE id = ?
                RETURNING id, sesion_id
            ";

            $result = DB::selectOne($sql, [
                $sys['efectivo'], $dec['efectivo'], $difEf, $verE,
                $sys['tarjetas'], $dec['tarjetas'], $difTj, $verT,
                $sys['transfer'], $dec['transfer'], $difTr, $verR,
                $notas,
                $valid === null ? null : (bool) $valid,
                $valid === null ? null : (bool) $valid,
                $usr,
                $valid === null ? null : (bool) $valid,
                $postId
            ]);

            if (!$result) {
                return response()->json(['ok' => false, 'error' => 'update_failed'], 500);
            }

            // Update session status if requested
            if ($sesionEstatus && in_array($sesionEstatus, ['CERRADA', 'CONCILIADA'])) {
                DB::update("UPDATE selemti.sesion_cajon SET estatus = ? WHERE id = ?", [$sesionEstatus, $sid]);
            } elseif ($valid) {
                // If validated but no explicit status provided, ensure it's at least CERRADA
                DB::update("UPDATE selemti.sesion_cajon SET estatus = 'CERRADA' WHERE id = ? AND estatus != 'CERRADA' AND estatus != 'CONCILIADA'", [$sid]);
            }

            return response()->json([
                'ok' => true,
                'postcorte_id' => (int) $result->id,
                'sesion_id' => (int) $result->sesion_id
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en update postcorte (id: $postId): " . $e->getMessage());

            // Auditoría
            try {
                DB::insert("
                    INSERT INTO selemti.auditoria (quien, que, payload) 
                    VALUES (1, 'postcorte.error', ?)
                ", [json_encode([
                    'id' => $postId,
                    'msg' => $e->getMessage()
                ])]);
            } catch (\Exception $e2) {}

            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al actualizar postcorte'
            ], 500);
        }
    }

    /**
     * Crear o actualizar (ruteador)
     */
    public function createOrUpdateLegacy(Request $request, $id = null): JsonResponse
    {
        $postId = $id ?? (int) $request->input('id', 0);
        $precorteId = (int) $request->input('precorte_id', 0);

        if ($postId > 0) {
            return $this->update($request, $postId);
        } elseif ($precorteId > 0) {
            return $this->create($request);
        } else {
            return response()->json(['ok' => false, 'error' => 'missing_id_or_precorte_id'], 400);
        }
    }

    // ============ HELPERS PRIVADOS ============

    private function ver(float $d): string
    {
        return abs($d) < 0.005 ? 'CUADRA' : ($d > 0 ? 'A_FAVOR' : 'EN_CONTRA');
    }

    private function getSesionByPrecorte(int $precorteId): ?array
    {
        $result = DB::selectOne("
            SELECT p.sesion_id, s.terminal_id, s.apertura_ts, s.cierre_ts, s.opening_float 
            FROM selemti.precorte p 
            JOIN selemti.sesion_cajon s ON s.id = p.sesion_id 
            WHERE p.id = ?
        ", [$precorteId]);

        return $result ? (array) $result : null;
    }

    private function getSesionByPostId(int $postId): ?array
    {
        $result = DB::selectOne("
            SELECT pc.sesion_id, s.terminal_id, s.apertura_ts, s.cierre_ts, s.opening_float 
            FROM selemti.postcorte pc 
            JOIN selemti.sesion_cajon s ON s.id = pc.sesion_id 
            WHERE pc.id = ?
        ", [$postId]);

        return $result ? (array) $result : null;
    }

    private function getUltimoPrecorteDeSesion(int $sesionId): ?int
    {
        $result = DB::selectOne("
            SELECT id 
            FROM selemti.precorte 
            WHERE sesion_id = ? 
            ORDER BY id DESC 
            LIMIT 1
        ", [$sesionId]);

        return $result ? (int) $result->id : null;
    }

    private function totalesDeclarados(int $precorteId): array
    {
        $ef = (float) DB::selectOne("
            SELECT COALESCE(SUM(COALESCE(subtotal, denominacion * cantidad)), 0) 
            FROM selemti.precorte_efectivo 
            WHERE precorte_id = ?
        ", [$precorteId])->coalesce ?? 0;

        $cr = (float) DB::selectOne("
            SELECT COALESCE(SUM(monto), 0) 
            FROM selemti.precorte_otros 
            WHERE precorte_id = ? 
              AND UPPER(tipo) IN ('CREDITO')
        ", [$precorteId])->coalesce ?? 0;

        $dbt = (float) DB::selectOne("
            SELECT COALESCE(SUM(monto), 0) 
            FROM selemti.precorte_otros 
            WHERE precorte_id = ? 
              AND UPPER(tipo) IN ('DEBITO', 'DÉBITO')
        ", [$precorteId])->coalesce ?? 0;

        $tr = (float) DB::selectOne("
            SELECT COALESCE(SUM(monto), 0) 
            FROM selemti.precorte_otros 
            WHERE precorte_id = ? 
              AND UPPER(tipo) IN ('TRANSFER', 'TRANSFERENCIA', 'TRANSFERENCIAS')
        ", [$precorteId])->coalesce ?? 0;

        return [
            'efectivo' => $ef,
            'credito' => $cr,
            'debito' => $dbt,
            'tarjetas' => $cr + $dbt,
            'transfer' => $tr
        ];
    }

    private function totalesSistema(int $terminalId, string $a, ?string $b): array
    {
        $a = $a ?: date('Y-m-d 00:00:00');
        $b = $b ?: date('Y-m-d 23:59:59');

        $sqlEf = "
            SELECT COALESCE(SUM(amount), 0) 
            FROM public.transactions 
            WHERE terminal_id = ? 
              AND transaction_time BETWEEN ? AND ? 
              AND UPPER(payment_type) = 'CASH' 
              AND UPPER(transaction_type) = 'CREDIT'
        ";

        $sqlCr = "
            SELECT COALESCE(SUM(amount), 0) 
            FROM public.transactions 
            WHERE terminal_id = ? 
              AND transaction_time BETWEEN ? AND ? 
              AND UPPER(payment_type) = 'CREDIT_CARD' 
              AND UPPER(transaction_type) = 'CREDIT'
        ";

        $sqlDb = "
            SELECT COALESCE(SUM(amount), 0) 
            FROM public.transactions 
            WHERE terminal_id = ? 
              AND transaction_time BETWEEN ? AND ? 
              AND UPPER(payment_type) = 'DEBIT_CARD' 
              AND UPPER(transaction_type) = 'CREDIT'
        ";

        $sqlTr = "
            SELECT COALESCE(SUM(amount), 0) 
            FROM public.transactions 
            WHERE terminal_id = ? 
              AND transaction_time BETWEEN ? AND ? 
              AND UPPER(payment_type) = 'CUSTOM_PAYMENT' 
              AND UPPER(transaction_type) = 'CREDIT' 
              AND UPPER(COALESCE(custom_payment_name, '')) LIKE 'TRANSFER%'
        ";

        $bind = [$terminalId, $a, $b];

        $ef = (float) (DB::selectOne($sqlEf, $bind)->coalesce ?? 0);
        $cr = (float) (DB::selectOne($sqlCr, $bind)->coalesce ?? 0);
        $dbt = (float) (DB::selectOne($sqlDb, $bind)->coalesce ?? 0);
        $tr = (float) (DB::selectOne($sqlTr, $bind)->coalesce ?? 0);

        return [
            'efectivo' => $ef,
            'credito' => $cr,
            'debito' => $dbt,
            'tarjetas' => $cr + $dbt,
            'transfer' => $tr
        ];
    }
}