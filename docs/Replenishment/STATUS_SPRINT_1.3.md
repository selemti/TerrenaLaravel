# 🧭 STATUS SPRINT 1.3 – Recepción → Kardex → Cierre

**Objetivo:** Cerrar el flujo de recepción de compra hasta dejar inventario actualizado y la recepción cerrada de forma inmutable.  
**Estado general:** 🔄 En progreso  
**Fecha:** 2025-10-25  
**Esquema BD:** `selemti`

---

## 1. Punto de partida
- Ya existe `/api/purchasing/receptions/*`.
- `ReceivingService` tiene métodos stub:
  - createDraftReception()
  - updateReceptionLines()
  - validateReception()
  - postToInventory()
- Aún NO aplicamos reglas reales de tolerancia ni generamos movimiento de inventario final.

---

## 2. Reglas clave de negocio

### 2.1 Tolerancia en recepción
- `config('inventory.reception_tolerance_pct', 5)`
- `diferencia_pct = abs(qty_recibida - qty_ordenada) / qty_ordenada * 100`
- Si ALGUNA línea excede tolerancia:
  - marcar recepción como `REQUIERE_APROBACION`
  - bloquear `postToInventory()` hasta aprobación manual

### 2.2 Permisos
- `inventory.receptions.validate`  
  Puede pasar `EN_PROCESO → VALIDADA`
- `inventory.receptions.approve_diff`  
  Puede autorizar diferencias fuera de tolerancia
- `inventory.receptions.post`  
  Puede postear a Kardex (mov_inv inmutable)

### 2.3 Posteo a inventario
- Por cada línea recibida generar `mov_inv`:
  - `tipo_mov = 'COMPRA'`
  - `qty` positiva
  - `item_id`, `almacen_id`, `costo_unitario`
  - timestamps
- Cambios de estado esperados:
  - `VALIDADA → POSTEADA_A_INVENTARIO → CERRADA`
- Una vez posteada, no se puede editar `qty_recibida`.

---

## 3. Trabajo técnico Sprint 1.3

### 3.1 ReceivingService
Actualizar métodos:

#### `validateReception(int $recepcionId, int $userId): array`
Debe:
- calcular diferencias contra la orden
- set `estado='VALIDADA'`
- set `requiere_aprobacion=true/false`
- guardar quién validó y cuándo
- `return`:
  ```php
  [
    'recepcion_id' => ...,
    'status' => 'VALIDADA',
    'requiere_aprobacion' => bool,
  ]
postToInventory(int $recepcionId, int $userId): array

Debe:

checar que estado actual sea VALIDADA

si requiere_aprobacion=true y NO aprobada → rechazar

(TODO) insertar mov_inv por cada renglón recibido

set estado final = 'CERRADA'

return:

[
  'recepcion_id' => ...,
  'movimientos_generados' => <N>,
  'status' => 'CERRADA',
]

3.2 ReceivingController

validateReception() llama service->validateReception()

postReception() llama service->postToInventory()

dejar comentarios // TODO autorización usando permisos definidos arriba.

4. Criterio de cierre Sprint 1.3

ReceivingService::validateReception() y ReceivingService::postToInventory() ya contienen el flujo descrito (aunque usen TODOs en lugar de SQL real).

ReceivingController llama esas versiones nuevas.

Rutas existentes siguen iguales (no hay rutas nuevas en 1.3).

Handoff listo para Codex.