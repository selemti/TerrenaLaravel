# 🧭 STATUS SPRINT 1.2 – Recepciones de Compra & Kardex

Estado general: 🟨 En progreso  
Fecha: 2025-10-26

## 1. Rutas expuestas (Laravel)
- POST /api/purchasing/receptions/create-from-po/{purchase_order_id} -> Purchasing\ReceivingController@createFromPO
- POST /api/purchasing/receptions/{recepcion_id}/lines -> Purchasing\ReceivingController@setLines
- POST /api/purchasing/receptions/{recepcion_id}/validate -> Purchasing\ReceivingController@validateReception
- POST /api/purchasing/receptions/{recepcion_id}/post -> Purchasing\ReceivingController@postReception

## 2. Backend
- Service: `App\Services\Inventory\ReceivingService` ya expone createDraftReception() y updateReceptionLines() con validaciones básicas de IDs y TODOs para persistencia.
- Controller: `App\Http\Controllers\Purchasing\ReceivingController` inyecta el servicio por constructor, responde con `{ok, data, message}` y deja comentarios `TODO` para autorización `inventory.receptions.*`.
- Los endpoints reciben Request, normalizan arrays (`lines`) y están listos para enganchar policies una vez definidas.

## 3. Pendiente para cerrar sprint
- Persistir recepción EN_PROCESO en `recepcion_cab`/`recepcion_det` a partir de la purchase order.
- Implementar actualización real de líneas con tolerancias preliminares.
- Conectar con catálogos (proveedores, almacenes, items) antes de QA end-to-end.

## 4. Riesgos / Bloqueantes
- Dependencia total de datos maestros (POs reales, items con costos) para probar el flujo.
- Riesgo de generar recepciones duplicadas si no se valida el estado de la purchase order.
- Falta de policies podría exponer endpoints sensibles en ambientes compartidos.

## 5. Siguiente paso inmediato
Implementar persistencia real en `ReceivingService::createDraftReception()` para que genere cabecera/detalle EN_PROCESO a partir de la PO.
