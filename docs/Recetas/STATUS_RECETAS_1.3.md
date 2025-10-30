# ?? STATUS SPRINT 1.3 �C Recepci��n �� Kardex �� Cierre

Objetivo: Cerrar el flujo de recepci��n de compra hasta dejar inventario actualizado y la recepci��n cerrada de forma inmutable.

Estado general: ?? En progreso  
Fecha: 2025-10-25  
Esquema BD: `selemti`

---

## 1. Punto de partida
- Ya existe `/api/purchasing/receptions/*`.
- `ReceivingService` tiene m��todos stub (createDraftReception, updateReceptionLines, validateReception, postToInventory).
- A��n NO aplicamos reglas reales de tolerancia ni generamos movimiento de inventario final.

---

## 2. Reglas clave de negocio

### 2.1 Tolerancia en recepci��n
- config('inventory.reception_tolerance_pct', 5)
- diferencia_pct = abs(qty_recibida - qty_ordenada) / qty_ordenada * 100
- Si ALGUNA l��nea excede tolerancia:
  - marcar recepci��n como `REQUIERE_APROBACION`
  - bloquear postToInventory hasta aprobaci��n

### 2.2 Permisos
- inventory.receptions.validate        �� puede pasar EN_PROCESO �� VALIDADA
- inventory.receptions.approve_diff    �� puede aprobar cuando hay diferencias fuera de tolerancia
- inventory.receptions.post            �� puede postear a Kardex (inmutable)

### 2.3 Posteo a inventario
- Para cada l��nea recibida generar mov_inv:
  - tipo_mov = 'COMPRA'
  - qty positiva
  - item_id, almacen_id, costo_unitario
  - timestamps
- Cambiar recepci��n:
  - VALIDADA �� POSTEADA_A_INVENTARIO �� CERRADA
- Una vez posteada, no se puede editar qty_recibida.

---

## 3. Trabajo t��cnico Sprint 1.3

### 3.1 ReceivingService
- validateReception($recepcionId, $userId):
  - calcular diferencias contra la orden
  - set estado='VALIDADA'
  - set requiere_aprobacion=true/false
  - guardar qui��n valid�� y cu��ndo
  - return [
      'recepcion_id' => ...,
      'status' => 'VALIDADA',
      'requiere_aprobacion' => bool
    ]

- postToInventory($recepcionId, $userId):
  - checar que estado actual sea VALIDADA
  - si requiere_aprobacion=true y NO aprobada �� rechazar
  - (TODO) insertar mov_inv por cada rengl��n
  - set estado final = 'CERRADA'
  - return [
      'recepcion_id' => ...,
      'movimientos_generados' => <N>,
      'status' => 'CERRADA'
    ]

### 3.2 ReceivingController
- validateReception(): llama service->validateReception
- postReception(): llama service->postToInventory
- agregar comentarios TODO de autorizaci��n usando los permisos arriba

---

## 4. Criterio de cierre Sprint 1.3
- M��todos validateReception y postToInventory ya contienen toda la l��gica de flujo (aunque con TODOs en lugar de SQL real).
- Controller ya llama esas versiones.
- Rutas ya existen, no cambian.
