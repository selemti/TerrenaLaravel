<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

class PrecorteController extends Controller
{
    /**
     * Preflight: verifica tickets abiertos antes de permitir precorte
     */
    public function preflight(Request $request, $sesionId = null): JsonResponse
    {
        $sesionId = $sesionId ?? $request->input('sesion_id', 0);
        
        if (!$sesionId) {
            return response()->json(['ok' => false, 'error' => 'missing_sesion_id'], 400);
        }

        try {
            $row = DB::selectOne("SELECT terminal_id FROM selemti.sesion_cajon WHERE id = ?", [$sesionId]);
            
            if (!$row) {
                return response()->json(['ok' => false, 'error' => 'sesion_not_found'], 404);
            }

            $tid = (int) $row->terminal_id;
            $result = DB::selectOne("SELECT COUNT(*) AS c FROM public.ticket WHERE terminal_id = ? AND closing_date IS NULL", [$tid]);
            $open = (int) ($result->c ?? 0);
            $blocked = $open > 0;

            return response()->json([
                'ok' => !$blocked,
                'tickets_abiertos' => $open,
                'bloqueo' => $blocked,
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en preflight (sesion_id: $sesionId): " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error en preflight'
            ], 500);
        }
    }

    /**
     * Crear o recuperar precorte existente (LÓGICA EXACTA DE SLIM)
     */
    public function createLegacy(Request $request): JsonResponse
    {
        $bdate = trim($request->input('bdate', ''));
        $storeId = (int) $request->input('store_id', 0);
        $terminalId = (int) $request->input('terminal_id', 0);
        $userId = (int) $request->input('user_id', 0);
        $sesionId = (int) $request->input('sesion_id', 0);

        try {
            // Si no tenemos sesion_id, buscarla por terminal y fecha
            if ($sesionId <= 0) {
                if (!$terminalId) {
                    return response()->json(['ok' => false, 'error' => 'missing_terminal_id'], 400);
                }

                if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $bdate)) {
                    $bdate = date('Y-m-d');
                }

                $d0 = $bdate . ' 00:00:00';
                $d1 = date('Y-m-d', strtotime($bdate . ' +1 day')) . ' 00:00:00';

                $result = DB::selectOne("
                    SELECT id 
                    FROM selemti.sesion_cajon 
                    WHERE terminal_id = ? 
                      AND apertura_ts < ? 
                      AND COALESCE(cierre_ts, ?) >= ? 
                    ORDER BY apertura_ts DESC 
                    LIMIT 1
                ", [$terminalId, $d1, $d1, $d0]);

                $sesionId = $result ? (int) $result->id : 0;

                if ($sesionId <= 0) {
                    return response()->json(['ok' => false, 'error' => 'sesion_not_found'], 404);
                }
            }

            // Buscar precorte existente
            $existing = DB::selectOne("
                SELECT id, estatus, created_at 
                FROM selemti.precorte 
                WHERE sesion_id = ? 
                ORDER BY id DESC 
                LIMIT 1
            ", [$sesionId]);

            if ($existing) {
                return response()->json([
                    'ok' => true,
                    'precorte_id' => (int) $existing->id,
                    'estatus' => $existing->estatus ?? 'PENDIENTE',
                    'creado_en' => $existing->created_at,
                    'ya_existia' => true
                ]);
            }

            // Crear nuevo precorte
            $result = DB::selectOne("
                INSERT INTO selemti.precorte (sesion_id, estatus, created_at) 
                VALUES (?, 'PENDIENTE', NOW()) 
                RETURNING id, created_at
            ", [$sesionId]);

            return response()->json([
                'ok' => true,
                'precorte_id' => (int) $result->id,
                'estatus' => 'PENDIENTE',
                'creado_en' => $result->created_at,
                'ya_existia' => false
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en createLegacy precorte: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'create_failed',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al crear precorte'
            ], 500);
        }
    }

    /**
     * Actualizar precorte (LÓGICA EXACTA DE SLIM)
     */
    public function updateLegacy(Request $request): JsonResponse
    {
        $precorteId = (int) $request->input('id', 0);

        if ($precorteId <= 0) {
            return response()->json(['ok' => false, 'error' => 'missing_precorte_id'], 400);
        }

        $denomsJson = $request->input('denoms_json', '[]');
        $declCredito = (float) $request->input('declarado_credito', 0);
        $declDebito = (float) $request->input('declarado_debito', 0);
        $declTransfer = (float) $request->input('declarado_transfer', 0);
        $notas = trim($request->input('notas', ''));

        // Parsear denominaciones
        $denoms = json_decode($denomsJson, true);
        if (!is_array($denoms)) $denoms = [];

        $totalEfectivo = 0.0;
        foreach ($denoms as $row) {
            $den = isset($row['den']) ? (float) $row['den'] : (float) ($row['denominacion'] ?? 0);
            $qty = isset($row['qty']) ? (int) $row['qty'] : (int) ($row['cantidad'] ?? 0);
            if ($den > 0 && $qty > 0) {
                $totalEfectivo += $den * $qty;
            }
        }

        $totalOtros = $declCredito + $declDebito + $declTransfer;

        try {
            DB::beginTransaction();

            // 1. Eliminar denominaciones anteriores
            DB::delete("DELETE FROM selemti.precorte_efectivo WHERE precorte_id = ?", [$precorteId]);

            // 2. Insertar nuevas denominaciones
            foreach ($denoms as $row) {
                $den = isset($row['den']) ? (float) $row['den'] : (float) ($row['denominacion'] ?? 0);
                $qty = isset($row['qty']) ? (int) $row['qty'] : (int) ($row['cantidad'] ?? 0);

                if ($den > 0 && $qty > 0) {
                    $subtotal = $den * $qty;
                    DB::insert("
                        INSERT INTO selemti.precorte_efectivo (precorte_id, denominacion, cantidad, subtotal) 
                        VALUES (?, ?, ?, ?)
                    ", [$precorteId, $den, $qty, $subtotal]);
                }
            }

            // 3. Eliminar otros métodos anteriores
            DB::delete("DELETE FROM selemti.precorte_otros WHERE precorte_id = ?", [$precorteId]);

            // 4. Insertar nuevos métodos de pago
            if ($declCredito > 0) {
                DB::insert("
                    INSERT INTO selemti.precorte_otros (precorte_id, tipo, monto, notas) 
                    VALUES (?, 'CREDITO', ?, ?)
                ", [$precorteId, $declCredito, $notas]);
            }

            if ($declDebito > 0) {
                DB::insert("
                    INSERT INTO selemti.precorte_otros (precorte_id, tipo, monto, notas) 
                    VALUES (?, 'DEBITO', ?, ?)
                ", [$precorteId, $declDebito, $notas]);
            }

            if ($declTransfer > 0) {
                DB::insert("
                    INSERT INTO selemti.precorte_otros (precorte_id, tipo, monto, notas) 
                    VALUES (?, 'TRANSFER', ?, ?)
                ", [$precorteId, $declTransfer, $notas]);
            }

            // 5. Actualizar totales en precorte
            $updateSql = "UPDATE selemti.precorte SET declarado_efectivo = ?, declarado_otros = ?";
            $params = [$totalEfectivo, $totalOtros];

            if (!empty($notas)) {
                $updateSql .= ", notas = ?";
                $params[] = $notas;
            }

            $updateSql .= " WHERE id = ?";
            $params[] = $precorteId;

            DB::update($updateSql, $params);

            // 6. Obtener resultado
            $result = DB::selectOne("
                SELECT declarado_efectivo, declarado_otros, COALESCE(notas, '') AS notas 
                FROM selemti.precorte 
                WHERE id = ?
            ", [$precorteId]);

            if (!$result) {
                $result = (object) ['declarado_efectivo' => 0, 'declarado_otros' => 0, 'notas' => ''];
            }

            DB::commit();

            return response()->json([
                'ok' => true,
                'precorte_id' => $precorteId,
                'declarado_efectivo' => (float) $result->declarado_efectivo,
                'declarado_otros' => (float) $result->declarado_otros,
                'notas' => $result->notas,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error("Error en updateLegacy precorte (id: $precorteId): " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'update_failed',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al actualizar precorte'
            ], 500);
        }
    }

    /**
     * Resumen/totales (LÓGICA EXACTA DE SLIM)
     */
    public function resumenLegacy(Request $request, $id = null): JsonResponse
    {
        $precorteId = $id ?? (int) $request->input('id', 0);
        $sesionId = (int) $request->input('sesion_id', 0);
        $terminalId = (int) $request->input('terminal_id', 0);
        $userId = (int) $request->input('user_id', 0);

        try {
            // Buscar precorte por diferentes criterios
            if (!$precorteId) {
                if ($sesionId > 0) {
                    $result = DB::selectOne("
                        SELECT id 
                        FROM selemti.precorte 
                        WHERE sesion_id = ? 
                        ORDER BY id DESC 
                        LIMIT 1
                    ", [$sesionId]);
                    $precorteId = $result ? (int) $result->id : 0;
                } elseif ($terminalId > 0 && $userId > 0) {
                    $result = DB::selectOne("
                        SELECT id 
                        FROM selemti.sesion_cajon 
                        WHERE terminal_id = ? 
                          AND cajero_usuario_id = ? 
                          AND cierre_ts IS NULL 
                        ORDER BY apertura_ts DESC 
                        LIMIT 1
                    ", [$terminalId, $userId]);

                    $sid = $result ? (int) $result->id : 0;

                    if ($sid > 0) {
                        $result = DB::selectOne("
                            SELECT id 
                            FROM selemti.precorte 
                            WHERE sesion_id = ? 
                            ORDER BY id DESC 
                            LIMIT 1
                        ", [$sid]);
                        $precorteId = $result ? (int) $result->id : 0;
                        $sesionId = $sid;
                    }
                }
            }

            if (!$precorteId) {
                return response()->json(['ok' => false, 'error' => 'precorte_not_found'], 404);
            }

            // Obtener sesión
            $precorte = DB::selectOne("SELECT sesion_id FROM selemti.precorte WHERE id = ?", [$precorteId]);
            
            if (!$precorte) {
                return response()->json(['ok' => false, 'error' => 'precorte_not_found'], 404);
            }

            $sid = (int) $precorte->sesion_id;

            // Verificar que existe el corte POS
            if (!$this->hasPOSCutBySesion($sid)) {
                return response()->json([
                    'ok' => false,
                    'error' => 'pos_cut_missing',
                    'require_pos_cut' => true,
                    'sesion_id' => $sid,
                    'precorte_id' => $precorteId
                ], 412);
            }

            // Obtener opening_float
            $sesion = DB::selectOne("SELECT opening_float FROM selemti.sesion_cajon WHERE id = ?", [$sid]);
            $openingFloat = (float) ($sesion->opening_float ?? 0);

            // Obtener total efectivo declarado
            $result = DB::selectOne("
                SELECT COALESCE(SUM(subtotal), 0) AS s 
                FROM selemti.precorte_efectivo 
                WHERE precorte_id = ?
            ", [$precorteId]);
            $declEf = (float) ($result->s ?? 0);

            // Obtener otros métodos declarados
            $declCredito = 0.0;
            $declDebito = 0.0;
            $declTransfer = 0.0;

            // Verificar que existe la tabla precorte_otros
            $hasOtros = DB::selectOne("SELECT to_regclass('selemti.precorte_otros') AS t");
            
            if ($hasOtros && $hasOtros->t) {
                $otros = DB::select("
                    SELECT UPPER(tipo) AS tipo, COALESCE(SUM(monto), 0) AS monto 
                    FROM selemti.precorte_otros 
                    WHERE precorte_id = ? 
                    GROUP BY UPPER(tipo)
                ", [$precorteId]);

                foreach ($otros as $r) {
                    if ($r->tipo === 'CREDITO') $declCredito = (float) $r->monto;
                    if ($r->tipo === 'DEBITO') $declDebito = (float) $r->monto;
                    if ($r->tipo === 'TRANSFER') $declTransfer = (float) $r->monto;
                }
            }

            // Obtener datos del sistema desde vista de conciliación
            $conc = DB::selectOne("SELECT * FROM selemti.vw_conciliacion_sesion WHERE sesion_id = ?", [$sid]);

            $sysE = 0;
            $sysC = 0;
            $sysD = 0;
            $sysT = 0;

            if ($conc) {
                $sysE = (float) ($conc->sistema_efectivo_esperado ?? 0);
                $sysC = (float) ($conc->sys_credito ?? $conc->sys_credit ?? 0);
                $sysD = (float) ($conc->sys_debito ?? $conc->sys_debit ?? 0);
                $sysT = (float) ($conc->sys_transfer ?? $conc->transfer ?? 0);
                
                if ($sysT <= 0.0001) {
                    $sysT = $this->sysTransfersFromTransactions($sid);
                }
            } else {
                $sysT = $this->sysTransfersFromTransactions($sid);
            }

            $data = [
                'efectivo' => ['declarado' => $declEf, 'sistema' => $sysE],
                'tarjeta_credito' => ['declarado' => $declCredito, 'sistema' => $sysC],
                'tarjeta_debito' => ['declarado' => $declDebito, 'sistema' => $sysD],
                'transferencias' => ['declarado' => $declTransfer, 'sistema' => $sysT],
            ];

            return response()->json([
                'ok' => true,
                'data' => $data,
                'opening_float' => $openingFloat,
                'precorte_id' => $precorteId,
                'sesion_id' => $sid,
                'has_pos_cut' => true
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en resumenLegacy: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'internal_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al obtener resumen'
            ], 500);
        }
    }

    /**
     * Status del precorte (GET/POST)
     */
    public function statusLegacy(Request $request, $id = null): JsonResponse
    {
        $precorteId = $id ?? (int) $request->input('id', 0);

        if ($precorteId <= 0) {
            return response()->json(['ok' => false, 'error' => 'missing_precorte_id'], 400);
        }

        $sesionEstatus = strtoupper(trim($request->input('sesion_estatus', '')));
        $precorteEstatus = strtoupper(trim($request->input('precorte_estatus', '')));
        $nota = trim($request->input('nota', $request->input('notas', '')));

        // Si es GET y no hay parámetros, solo devolver estado
        if ($request->isMethod('GET') && !$sesionEstatus && !$precorteEstatus) {
            $result = DB::selectOne("
                SELECT id, sesion_id, estatus 
                FROM selemti.precorte 
                WHERE id = ?
            ", [$precorteId]);

            if (!$result) {
                return response()->json(['ok' => false, 'error' => 'precorte_not_found'], 404);
            }

            return response()->json([
                'ok' => true,
                'id' => (int) $result->id,
                'sesion_id' => (int) $result->sesion_id,
                'estatus' => $result->estatus
            ]);
        }

        // Actualizar estado
        try {
            DB::beginTransaction();

            $sets = [];
            $params = [];

            if ($precorteEstatus !== '') {
                $sets[] = "estatus = ?";
                $params[] = $precorteEstatus;
            }

            if ($nota !== '') {
                $sets[] = "notas = ?";
                $params[] = $nota;
            }

            if ($sets) {
                $sql = "UPDATE selemti.precorte SET " . implode(', ', $sets) . " WHERE id = ?";
                $params[] = $precorteId;
                DB::update($sql, $params);
            }

            if ($sesionEstatus !== '') {
                $sesion = DB::selectOne("SELECT sesion_id FROM selemti.precorte WHERE id = ?", [$precorteId]);
                
                if ($sesion) {
                    DB::update("UPDATE selemti.sesion_cajon SET estatus = ? WHERE id = ?", [
                        $sesionEstatus,
                        $sesion->sesion_id
                    ]);
                }
            }

            DB::commit();

            return response()->json([
                'ok' => true,
                'precorte_id' => $precorteId,
                'precorte_estatus' => $precorteEstatus ?: null,
                'sesion_estatus' => $sesionEstatus ?: null
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error("Error en statusLegacy: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'status_update_failed',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al actualizar estado'
            ], 500);
        }
    }

    /**
     * Enviar precorte (cambiar a ENVIADO)
     */
    public function enviar(Request $request, $id): JsonResponse
    {
        try {
            $result = DB::selectOne("
                UPDATE selemti.precorte 
                SET estatus = 'ENVIADO' 
                WHERE id = ? 
                RETURNING id, estatus
            ", [$id]);

            if (!$result) {
                return response()->json(['ok' => false, 'error' => 'precorte_not_found'], 404);
            }

            return response()->json([
                'ok' => true,
                'precorte_id' => (int) $result->id,
                'estatus' => $result->estatus
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en enviar precorte: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al enviar precorte'
            ], 500);
        }
    }

    /**
     * Crear o actualizar (ruteador)
     */
    public function createOrUpdateLegacy(Request $request, $id = null): JsonResponse
    {
        if ($id) {
            $request->merge(['id' => $id]);
            return $this->updateLegacy($request);
        }
        return $this->createLegacy($request);
    }

    // ============ HELPERS PRIVADOS ============

    private function hasPOSCutBySesion(int $sesionId): bool
    {
        try {
            $reg = DB::selectOne("SELECT to_regclass('selemti.vw_sesion_dpr') AS t");
            if (!$reg || !$reg->t) return false;

            $result = DB::selectOne("SELECT 1 FROM selemti.vw_sesion_dpr WHERE sesion_id = ? LIMIT 1", [$sesionId]);
            return (bool) $result;
        } catch (\Exception $e) {
            return false;
        }
    }

    private function sysTransfersFromTransactions(int $sesionId): float
    {
        try {
            $sesion = DB::selectOne("
                SELECT terminal_id, apertura_ts, COALESCE(cierre_ts, (apertura_ts::date + INTERVAL '1 day')) AS fin 
                FROM selemti.sesion_cajon 
                WHERE id = ?
            ", [$sesionId]);

            if (!$sesion) return 0.0;

            $terminalId = (int) $sesion->terminal_id;
            $a = $sesion->apertura_ts;
            $b = $sesion->fin;

            $hasSubType = $this->hasColumn('public', 'transactions', 'payment_sub_type');
            $hasTermCol = $this->hasColumn('public', 'transactions', 'terminal_id');

            $whereTipo = $hasSubType 
                ? "payment_sub_type = 'CUSTOM PAYMENT'" 
                : "payment_type = 'CUSTOM_PAYMENT'";

            $nombreOk = "UPPER(custom_payment_name) IN ('TRANSFERENCIA', 'TRANFERENCIA')";
            $timeGate = "
                transaction_time >= (?::timestamptz AT TIME ZONE current_setting('TIMEZONE'))
                AND transaction_time < (?::timestamptz AT TIME ZONE current_setting('TIMEZONE'))
            ";

            $sql = "
                SELECT COALESCE(SUM(amount), 0) AS s 
                FROM public.transactions 
                WHERE {$whereTipo} 
                  AND transaction_type = 'CREDIT' 
                  AND {$nombreOk} 
                  AND {$timeGate}
            ";

            $params = [$a, $b];

            if ($hasTermCol) {
                $sql .= " AND terminal_id = ?";
                $params[] = $terminalId;
            }

            $result = DB::selectOne($sql, $params);
            return (float) ($result->s ?? 0);

        } catch (\Exception $e) {
            \Log::error("Error en sysTransfersFromTransactions: " . $e->getMessage());
            return 0.0;
        }
    }

    private function hasColumn(string $schema, string $table, string $column): bool
    {
        try {
            $result = DB::selectOne("
                SELECT 1 
                FROM information_schema.columns 
                WHERE table_schema = ? 
                  AND table_name = ? 
                  AND column_name = ? 
                LIMIT 1
            ", [$schema, $table, $column]);

            return (bool) $result;
        } catch (\Exception $e) {
            return false;
        }
    }
}