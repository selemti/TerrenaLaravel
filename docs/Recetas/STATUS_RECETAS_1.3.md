# ?? STATUS SPRINT 1.3 每 Recepci車n ↙ Kardex ↙ Cierre

Objetivo: Cerrar el flujo de recepci車n de compra hasta dejar inventario actualizado y la recepci車n cerrada de forma inmutable.

Estado general: ?? En progreso  
Fecha: 2025-10-25  
Esquema BD: `selemti`

---

## 1. Punto de partida
- Ya existe `/api/purchasing/receptions/*`.
- `ReceivingService` tiene m谷todos stub (createDraftReception, updateReceptionLines, validateReception, postToInventory).
- A迆n NO aplicamos reglas reales de tolerancia ni generamos movimiento de inventario final.

---

## 2. Reglas clave de negocio

### 2.1 Tolerancia en recepci車n
- config('inventory.reception_tolerance_pct', 5)
- diferencia_pct = abs(qty_recibida - qty_ordenada) / qty_ordenada * 100
- Si ALGUNA l赤nea excede tolerancia:
  - marcar recepci車n como `REQUIERE_APROBACION`
  - bloquear postToInventory hasta aprobaci車n

### 2.2 Permisos
- inventory.receptions.validate        ↙ puede pasar EN_PROCESO ↙ VALIDADA
- inventory.receptions.approve_diff    ↙ puede aprobar cuando hay diferencias fuera de tolerancia
- inventory.receptions.post            ↙ puede postear a Kardex (inmutable)

### 2.3 Posteo a inventario
- Para cada l赤nea recibida generar mov_inv:
  - tipo_mov = 'COMPRA'
  - qty positiva
  - item_id, almacen_id, costo_unitario
  - timestamps
- Cambiar recepci車n:
  - VALIDADA ↙ POSTEADA_A_INVENTARIO ↙ CERRADA
- Una vez posteada, no se puede editar qty_recibida.

---

## 3. Trabajo t谷cnico Sprint 1.3

### 3.1 ReceivingService
- validateReception($recepcionId, $userId):
  - calcular diferencias contra la orden
  - set estado='VALIDADA'
  - set requiere_aprobacion=true/false
  - guardar qui谷n valid車 y cu芍ndo
  - return [
      'recepcion_id' => ...,
      'status' => 'VALIDADA',
      'requiere_aprobacion' => bool
    ]

- postToInventory($recepcionId, $userId):
  - checar que estado actual sea VALIDADA
  - si requiere_aprobacion=true y NO aprobada ↙ rechazar
  - (TODO) insertar mov_inv por cada rengl車n
  - set estado final = 'CERRADA'
  - return [
      'recepcion_id' => ...,
      'movimientos_generados' => <N>,
      'status' => 'CERRADA'
    ]

### 3.2 ReceivingController
- validateReception(): llama service->validateReception
- postReception(): llama service->postToInventory
- agregar comentarios TODO de autorizaci車n usando los permisos arriba

---

## 4. Criterio de cierre Sprint 1.3
- M谷todos validateReception y postToInventory ya contienen toda la l車gica de flujo (aunque con TODOs en lugar de SQL real).
- Controller ya llama esas versiones.
- Rutas ya existen, no cambian.
