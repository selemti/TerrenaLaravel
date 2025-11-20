# Modificaciones a PostcorteController

**Archivo**: `app/Http/Controllers/Api/Caja/PostcorteController.php`
**Fecha**: 2025-11-11
**Propósito**: Agregar lógica de aprobación para postcortes irregulares

---

## 1. Agregar Import

**Ubicación**: Línea 7 (después de `UpdatePostcorteRequest`)

```php
use App\Services\Caja\AlertasService;
```

---

## 2. Agregar Propiedad de Servicio

**Ubicación**: Línea 13 (dentro de la clase, después de `class PostcorteController extends Controller`)

```php
    protected $alertasService;

    public function __construct(AlertasService $alertasService)
    {
        $this->alertasService = $alertasService;
    }
```

---

## 3. Modificar Método `create()`

**Ubicación**: Línea 85-91 (después de `$id = (int) $result->id;` y antes del return)

**Agregar código**:

```php
            $id = (int) $result->id;

            // Check if session has skipped_precorte = true (irregular workflow)
            $sesionData = DB::connection('pgsql')->selectOne(
                "SELECT skipped_precorte, cajero_usuario_id FROM selemti.sesion_cajon WHERE id = ?",
                [$sid]
            );

            $requiresApproval = $sesionData && $sesionData->skipped_precorte === true;

            // If irregular, mark postcorte as requiring approval
            if ($requiresApproval) {
                // Get motivo_irregular from request if provided
                $motivoIrregular = trim($request->input('motivo_irregular', ''));

                DB::connection('pgsql')->update(
                    "UPDATE selemti.postcorte SET requiere_aprobacion = true, motivo_irregular = ? WHERE id = ?",
                    [$motivoIrregular ?: 'Sesión cerrada antes de hacer precorte', $id]
                );

                // Create approval alerts
                $this->alertasService->crearAlertaAprobacion($id, $sid);
            }

            return response()->json([
                'ok' => true,
                'postcorte_id' => $id,
                'sesion_id' => $sid,
                'requiere_aprobacion' => $requiresApproval
            ]);
```

---

## 4. Modificar Método `update()`

**Ubicación**: Línea 201-207 (en la sección de actualización de estado de sesión)

**Reemplazar**:

```php
            // Update session status if requested
            if ($sesionEstatus && in_array($sesionEstatus, ['CERRADA', 'CONCILIADA'])) {
                DB::connection('pgsql')->update("UPDATE selemti.sesion_cajon SET estatus = ? WHERE id = ?", [$sesionEstatus, $sid]);
            } elseif ($valid) {
                // If validated but no explicit status provided, ensure it's at least CERRADA
                DB::connection('pgsql')->update("UPDATE selemti.sesion_cajon SET estatus = 'CERRADA' WHERE id = ? AND estatus != 'CERRADA' AND estatus != 'CONCILIADA'", [$sid]);
            }
```

**Por**:

```php
            // Check if postcorte requires approval before closing session
            $postcorteData = DB::connection('pgsql')->selectOne(
                "SELECT requiere_aprobacion, aprobado_por FROM selemti.postcorte WHERE id = ?",
                [$postId]
            );

            $requiresApproval = $postcorteData && $postcorteData->requiere_aprobacion === true;
            $isApproved = $postcorteData && $postcorteData->aprobado_por !== null;

            // Update session status if requested
            if ($sesionEstatus && in_array($sesionEstatus, ['CERRADA', 'CONCILIADA'])) {
                // Only allow closing if doesn't require approval OR is already approved
                if (!$requiresApproval || $isApproved) {
                    DB::connection('pgsql')->update("UPDATE selemti.sesion_cajon SET estatus = ? WHERE id = ?", [$sesionEstatus, $sid]);
                }
            } elseif ($valid) {
                // If validated but no explicit status provided, ensure it's at least CERRADA
                // Only if doesn't require approval OR is already approved
                if (!$requiresApproval || $isApproved) {
                    DB::connection('pgsql')->update("UPDATE selemti.sesion_cajon SET estatus = 'CERRADA' WHERE id = ? AND estatus != 'CERRADA' AND estatus != 'CONCILIADA'", [$sid]);
                }
            }
```

---

## 5. Agregar Nuevos Métodos

**Ubicación**: Al final de la clase, antes del último `}`

```php
    /**
     * Get pending postcortes that require approval
     */
    public function pendientesAprobacion(Request $request): JsonResponse
    {
        try {
            $pendientes = DB::connection('pgsql')
                ->select("
                    SELECT
                        p.id,
                        p.sesion_id,
                        s.terminal_id,
                        s.cajero_usuario_id,
                        u.first_name || ' ' || u.last_name as cajero_nombre,
                        p.declarado_efectivo as total_declarado_efectivo,
                        p.sistema_efectivo_esperado as total_sistema_efectivo,
                        p.diferencia_efectivo,
                        p.veredicto_efectivo,
                        p.declarado_tarjetas,
                        p.diferencia_tarjetas,
                        p.declarado_transferencias,
                        p.diferencia_transferencias,
                        p.motivo_irregular,
                        p.creado_en,
                        s.apertura_ts,
                        s.cierre_ts
                    FROM selemti.postcorte p
                    JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
                    LEFT JOIN selemti.users u ON s.cajero_usuario_id = u.id
                    WHERE p.requiere_aprobacion = TRUE
                      AND p.aprobado_por IS NULL
                      AND p.rechazado = FALSE
                    ORDER BY p.creado_en DESC
                ");

            return response()->json([
                'ok' => true,
                'data' => $pendientes
            ]);

        } catch (\Exception $e) {
            \Log::error("Error al obtener postcortes pendientes: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al obtener postcortes pendientes'
            ], 500);
        }
    }

    /**
     * Approve a postcorte that requires approval
     */
    public function aprobar(Request $request, $id): JsonResponse
    {
        try {
            $userId = auth()->user()->id ?? 1;
            $notas = trim($request->input('notas', ''));

            // Get postcorte and session data
            $postcorte = DB::connection('pgsql')->selectOne(
                "SELECT p.*, s.cajero_usuario_id
                 FROM selemti.postcorte p
                 JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
                 WHERE p.id = ?",
                [$id]
            );

            if (!$postcorte) {
                return response()->json(['ok' => false, 'error' => 'postcorte_not_found'], 404);
            }

            if (!$postcorte->requiere_aprobacion) {
                return response()->json(['ok' => false, 'error' => 'does_not_require_approval'], 400);
            }

            if ($postcorte->aprobado_por) {
                return response()->json(['ok' => false, 'error' => 'already_approved'], 400);
            }

            // Approve postcorte
            DB::connection('pgsql')->update(
                "UPDATE selemti.postcorte SET
                    aprobado_por = ?,
                    aprobado_en = NOW(),
                    validado = true,
                    validado_por = ?,
                    validado_en = NOW(),
                    notas = COALESCE(NULLIF(?, ''), notas)
                 WHERE id = ?",
                [$userId, $userId, $notas, $id]
            );

            // Close session
            DB::connection('pgsql')->update(
                "UPDATE selemti.sesion_cajon SET estatus = 'CERRADA' WHERE id = ?",
                [$postcorte->sesion_id]
            );

            // Create alert for cashier
            $this->alertasService->crearAlertaAprobado(
                $id,
                $postcorte->sesion_id,
                $postcorte->cajero_usuario_id
            );

            // Mark all pending alerts for this postcorte as read
            $this->alertasService->marcarLeidasPorPostcorte($id, $userId);

            return response()->json([
                'ok' => true,
                'postcorte_id' => $id,
                'sesion_id' => $postcorte->sesion_id
            ]);

        } catch (\Exception $e) {
            \Log::error("Error al aprobar postcorte (id: $id): " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al aprobar postcorte'
            ], 500);
        }
    }

    /**
     * Reject a postcorte that requires approval
     */
    public function rechazar(Request $request, $id): JsonResponse
    {
        try {
            $userId = auth()->user()->id ?? 1;
            $motivoRechazo = trim($request->input('motivo_rechazo', ''));

            if (empty($motivoRechazo)) {
                return response()->json(['ok' => false, 'error' => 'motivo_required'], 400);
            }

            // Get postcorte and session data
            $postcorte = DB::connection('pgsql')->selectOne(
                "SELECT p.*, s.cajero_usuario_id
                 FROM selemti.postcorte p
                 JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
                 WHERE p.id = ?",
                [$id]
            );

            if (!$postcorte) {
                return response()->json(['ok' => false, 'error' => 'postcorte_not_found'], 404);
            }

            if (!$postcorte->requiere_aprobacion) {
                return response()->json(['ok' => false, 'error' => 'does_not_require_approval'], 400);
            }

            if ($postcorte->rechazado) {
                return response()->json(['ok' => false, 'error' => 'already_rejected'], 400);
            }

            // Reject postcorte
            DB::connection('pgsql')->update(
                "UPDATE selemti.postcorte SET
                    rechazado = true,
                    motivo_rechazo = ?
                 WHERE id = ?",
                [$motivoRechazo, $id]
            );

            // Reopen session for correction
            DB::connection('pgsql')->update(
                "UPDATE selemti.sesion_cajon SET estatus = 'LISTO_PARA_CORTE' WHERE id = ?",
                [$postcorte->sesion_id]
            );

            // Create alert for cashier
            $this->alertasService->crearAlertaRechazado(
                $id,
                $postcorte->sesion_id,
                $postcorte->cajero_usuario_id
            );

            // Mark all pending alerts for this postcorte as read
            $this->alertasService->marcarLeidasPorPostcorte($id, $userId);

            return response()->json([
                'ok' => true,
                'postcorte_id' => $id,
                'sesion_id' => $postcorte->sesion_id
            ]);

        } catch (\Exception $e) {
            \Log::error("Error al rechazar postcorte (id: $id): " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al rechazar postcorte'
            ], 500);
        }
    }
```

---

## Resumen de Cambios

1. **Import**: Agregado `AlertasService`
2. **Constructor**: Inyección de dependencia de AlertasService
3. **Método create()**: Detecta `skipped_precorte` y marca como `requiere_aprobacion`
4. **Método update()**: Valida que postcorte esté aprobado antes de cerrar sesión
5. **Nuevos métodos**:
   - `pendientesAprobacion()`: Lista postcortes pendientes de aprobación
   - `aprobar()`: Aprueba un postcorte irregular
   - `rechazar()`: Rechaza un postcorte irregular y reabre sesión

---

**Aplicado**: ⏳ Pendiente
**Verificado**: ⏳ Pendiente
