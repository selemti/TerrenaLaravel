# 🧭 STATUS SPRINT 1.5 – Devoluciones a Proveedor

Estado general: 🟨 En progreso  
Fecha: 2025-10-26

## 1. Rutas expuestas (Laravel)
- POST /api/purchasing/returns/create-from-po/{purchase_order_id} -> Purchasing\ReturnController@createFromPO
- POST /api/purchasing/returns/{return_id}/approve -> Purchasing\ReturnController@approve
- POST /api/purchasing/returns/{return_id}/ship -> Purchasing\ReturnController@ship
- POST /api/purchasing/returns/{return_id}/confirm -> Purchasing\ReturnController@confirm
- POST /api/purchasing/returns/{return_id}/post -> Purchasing\ReturnController@post
- POST /api/purchasing/returns/{return_id}/credit-note -> Purchasing\ReturnController@creditNote

## 2. Backend
- `ReturnService` implementa stubs para creación BORRADOR, aprobación, tránsito, recepción, ajuste inventario y nota de crédito; todos con guards básicos de IDs.
- `ReturnController` inyecta el servicio, normaliza inputs (`tracking`, `lines`, `notaCreditoData`), responde `{ok, data, message}` y ya deja `TODO` de autorización `purchasing.returns.*`.
- Rutas se agrupan bajo `/api/purchasing/returns`, listas para policies y feature flags en ambientes QA/Prod.

## 3. Pendiente para cerrar sprint
- Persistir estados y tracking real en DB (cabecera y detalle de devolución).
- Generar movimientos negativos `mov_inv` tipo `DEVOLUCION_PROVEEDOR`.
- Registrar nota de crédito (folio/monto/fecha) y enlazarla con cuentas por pagar.

## 4. Riesgos / Bloqueantes
- Dependemos de recepciones posteadas con lotes disponibles para devolver.
- Sin policies activas, cualquier usuario podría emitir devoluciones y afectar inventario.
- Falta definición contable para reflejar notas de crédito en finanzas.

## 5. Siguiente paso inmediato
Persistir estados `BORRADOR→APROBADA` y tracking en `ReturnService::approveReturn()` y `markShipped()`.
