### ✅ Archivo 2 — `docs/Replenishment/STATUS_SPRINT_1.9.md`
> 🆕 Crea este archivo nuevo.

```markdown
# STATUS_SPRINT_1.9 – Control de Tolerancia y Autorización Operativa

## Objetivo
Completar el flujo de recepción de compras agregando:
1. Endpoint de aprobación fuera de tolerancia.
2. Nuevo permiso `inventory.receptions.override_tolerance`.
3. Transición de estados completa: EN_PROCESO → VALIDADA → (aprobada si aplica) → CERRADA.

---

## 1. Endpoint backend
**Ruta:** `POST /api/purchasing/receptions/{recepcion_id}/approve`  
**Controlador:** `ReceivingController@approveReception`  
**Servicio:** `ReceivingService::approveReception(int $recepcionId, int $userId): array`

**Comportamiento:**
- Requiere permiso `inventory.receptions.override_tolerance`.
- Marca `aprobada_fuera_tolerancia = true`.
- Retorna:
```json
{
  "ok": true,
  "data": {
    "recepcion_id": 123,
    "status": "VALIDADA",
    "requiere_aprobacion": false,
    "aprobada_por": 45
  },
  "message": "Recepción autorizada fuera de tolerancia"
}
2. Reglas de flujo
Paso	Endpoint	Estado resultante	Notas
Crear recepción	/create-from-po	EN_PROCESO	desde PO aprobada
Capturar líneas	/lines	EN_PROCESO	qty física
Validar	/validate	VALIDADA	Calcula tolerancia, puede marcar requiere_aprobacion=true
Aprobar	/approve	VALIDADA	Limpia bloqueo de tolerancia
Postear	/post	CERRADA	Crea movimientos inventario tipo COMPRA

3. Permisos delegables
Permiso	Descripción	Endpoint asociado
inventory.receptions.validate	Puede validar recepción	/validate
inventory.receptions.override_tolerance	Puede autorizar tolerancia	/approve
inventory.receptions.post	Puede postear inventario	/post

Los permisos son asignables a usuarios individuales y no dependen de su puesto o rol.

4. Entregables Sprint 1.9
ReceivingService

Añadir método approveReception().

Completar PHPDoc de validateReception(), approveReception(), postToInventory().

TODOs claros, sin SQL real.

ReceivingController

Nuevo método:

php
Copiar código
public function approve(int $recepcion_id, Request $request): JsonResponse
{
    // TODO: autorización inventory.receptions.override_tolerance
    $userId = (int) ($request->user()->id ?? $request->input('user_id'));
    $data = $this->receivingService->approveReception($recepcion_id, $userId);

    return response()->json([
        'ok' => true,
        'data' => $data,
        'message' => 'Recepción autorizada fuera de tolerancia',
    ]);
}
routes/api.php

php
Copiar código
Route::prefix('purchasing')->group(function () {
    Route::prefix('receptions')->group(function () {
        Route::post('/{recepcion_id}/approve', [ReceivingController::class, 'approve']);
    });
});
Con esto, el flujo de recepción está cerrado de extremo a extremo.

yaml
Copiar código

---