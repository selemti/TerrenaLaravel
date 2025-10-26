
---

### 2. `docs/Replenishment/STATUS_SPRINT_1.4.md`

```md
# 🧭 STATUS SPRINT 1.4 – Costeo de Recepción y Nota de Crédito

**Objetivo:** Registrar el costo de lo recibido y preparar impacto financiero básico (sin contabilidad formal todavía).  
**Estado general:** 📋 Planificado  
**Fecha:** 2025-10-25  
**Esquema BD:** `selemti`

---

## 1. Punto de partida
- Después de Sprint 1.3 ya sabemos:
  - qué qty entró por item
  - a qué almacén entró
  - costo_unitario estimado / cotizado
- Aún NO guardamos:
  - costo final aplicado por línea
  - valor total de la recepción
  - nota de crédito del proveedor

---

## 2. Reglas de negocio

### 2.1 Costo último
- Cada recepción posteada debe actualizar el "último costo de compra" del item.
- Ese costo último se usará para sugerencias futuras y reportes.

### 2.2 Valor total de la recepción
- Para cada línea:
  - `total_linea = qty_recibida * costo_unitario_final`
- `total_recepcion = SUM(total_linea)`  
- Esto se guarda en la cabecera de la recepción para auditoría y para cuentas por pagar.

### 2.3 Nota de crédito del proveedor
- Cuando hay devolución parcial o ajuste de precio:
  - registrar una “nota de crédito” ligada a la recepción / PO
  - guardar: monto, fecha, folio proveedor
- Esa nota de crédito alimenta conciliación con proveedor.

---

## 3. Trabajo técnico Sprint 1.4

### 3.1 Extensión de datos de recepción
Agregar campos (si no existen todavía) en la cabecera de recepción:
- `total_valorizado`
- `last_cost_applied` (bool)
- `currency` (placeholder para multi-moneda futuro)

### 3.2 ReceivingService
Agregar método nuevo:
```php
public function finalizeCosting(int $recepcionId, int $userId): array
esponsabilidad:

calcular totales valorizados (total_valorizado)

marcar last_cost_applied=true

actualizar "último costo" del item en tablas maestras de items/proveedores

return:

[
  'recepcion_id' => ...,
  'total_valorizado' => ...,
  'status' => 'COSTO_FINAL_APLICADO',
]

3.3 Controller

Agregar endpoint:

POST /api/purchasing/receptions/{recepcion_id}/costing

Llama finalizeCosting()

Permiso esperado futuro: inventory.receptions.cost_finalize

4. Criterio de cierre Sprint 1.4

Existe finalizeCosting() con TODOs claros.

Existe acción en controller que lo llama.

Ruta expuesta y protegible por permiso.

Estructura para registrar nota de crédito está documentada (aunque la lógica real se completa en Sprint 1.5).