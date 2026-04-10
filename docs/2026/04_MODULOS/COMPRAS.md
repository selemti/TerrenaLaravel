# Módulo de Compras
> Actualizado: Abril 2026

## Flujo

```
ReplenishmentService (sugerencias automáticas por punto de reorden)
        │
        ▼
PurchaseSuggestion → aprobación → PurchaseRequest
        │
        ▼
PurchaseOrder (OC) → aprobación → envío a proveedor
        │
        ▼
GRN / Recepción (ReceptionService) → validación → posteo a inventario → costeo WAC
        │
        └── Devolución (ReturnService) → nota de crédito (si aplica)
```

---

## Componentes Livewire

| Componente | Ruta | Estado |
|-----------|------|--------|
| ReplenishmentDashboard | `/purchasing/replenishment` | ✅ |
| PurchasingRequestsIndex | `/purchasing/requests` | ✅ |
| PurchasingRequestsCreate | `/purchasing/requests/create` | ✅ |
| PurchasingRequestsDetail | `/purchasing/requests/{id}/detail` | ✅ |
| PurchasingOrdersIndex | `/purchasing/orders` | ✅ |
| PurchasingOrdersDetail | `/purchasing/orders/{id}/detail` | ✅ |

---

## Servicios

| Servicio | Líneas | Estado |
|----------|--------|--------|
| PurchasingService | 685 | ✅ completo |
| ReplenishmentService | 524 | ✅ completo |
| DemandCalculationService | 97 | ✅ completo |
| ReceptionService | 276 | ✅ completo |
| ReturnService | 159 | ✅ completo |

---

## Modelos

| Modelo | Tabla | Descripción |
|--------|-------|------------|
| PurchaseRequest | `purchase_requests` | Solicitud de compra |
| PurchaseRequestLine | `purchase_request_lines` | Línea de solicitud |
| PurchaseOrder | `purchase_orders` | Orden de compra |
| PurchaseOrderLine | `purchase_order_lines` | Línea de OC |
| PurchaseSuggestion | `purchase_suggestions` | Sugerencia automática |
| PurchaseSuggestionLine | `purchase_suggestion_lines` | Línea de sugerencia |

---

## Estados de OC

```
borrador → pendiente_aprobacion → aprobada → enviada → parcialmente_recibida → cerrada
                                                                │
                                                                └──► devolucion → nota_credito
```

---

## Reposición Automática

El `ReplenishmentService` calcula sugerencias basadas en:
1. `stock_policy.punto_reorden` — nivel de reorden por ítem/almacén
2. `DemandCalculationService` — demanda histórica (promedio móvil)
3. Lead time del proveedor (`item_vendor.lead_time_dias`)

Las sugerencias se generan como `PurchaseSuggestion` y pueden aprobarse/rechazarse/convertirse a OC.
