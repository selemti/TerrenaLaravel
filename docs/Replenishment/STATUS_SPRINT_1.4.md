# 🧭 STATUS SPRINT 1.4 – Costeo de Recepción y Nota de Crédito

Estado general: 🟨 En progreso  
Fecha: 2025-10-26

## 1. Rutas expuestas (Laravel)
- POST /api/purchasing/receptions/{recepcion_id}/costing -> Purchasing\ReceivingController@finalizeCosting

## 2. Backend
- `ReceivingService` incorpora finalizeCosting() con TODOs para calcular `total_valorizado`, marcar `last_cost_applied` y actualizar costos maestros.
- `ReceivingController` añadió la acción finalizeCosting(), mantiene constructor injection y responde `{ok, data, message}` con comentario `TODO` para permiso `inventory.receptions.cost_finalize`.
- La ruta se registró bajo `/api/purchasing/receptions`, lista para policies cuando se conecte con `Gate`.

## 3. Pendiente para cerrar sprint
- Persistir `total_valorizado`, `currency` y `last_cost_applied` en `recepcion_cab`.
- Actualizar último costo por item/proveedor e integrar con catálogos financieros.
- Documentar/implementar flujo de nota de crédito ligada a recepción y PO.

## 4. Riesgos / Bloqueantes
- Sin datos reales de costos finales, el cálculo puede romper reportes de margen.
- Necesitamos definición de multi-moneda antes de exponer `currency`.
- Falta gobernanza sobre quién puede aplicar costeo final (riesgo de fraude).

## 5. Siguiente paso inmediato
Implementar cálculo y persistencia de `total_valorizado` + `last_cost_applied` en `ReceivingService::finalizeCosting()`.
