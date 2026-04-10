# Módulo de Inventario
> Actualizado: Abril 2026 | Basado en: D:\Tavo\2025\UX\Inventarios\v3\Definicion_Inventarios_v2.md

## Flujo Completo

```
Paso 0: Maestros (items, unidades, presentaciones, proveedores)
        │
        ▼
OC (PurchaseOrder) → aprobación
        │
        ▼
GRN / Recepción (ReceptionService) → costeo WAC
        │
        ▼
Stock (inventory_batch + cost_layer)
        │
        ├──────────────────────────────┐
        ▼                              ▼
Transferencias inter-almacén    Producción (consume insumos)
        │                              │
        │                              ▼
        │                    Consumo POS (batch cada 60s)
        │
        ▼
Conteo Físico → ajustes
        │
        ▼
Mermas / Bajas manuales
```

---

## Decisiones de Diseño Clave

| Decisión | Valor |
|----------|-------|
| Algoritmo de costeo | WAC (Costo Promedio Ponderado) principal |
| Rotación de lotes | FEFO recomendado, PEPS configurable por sucursal |
| Unidad canónica | Única por ítem, conversiones explícitas |
| Consumo POS | Batch job cada 60s (no en tiempo real) |
| Caducidad/lotes | Obligatorio para perecederos, opcional para no perecederos |
| Motor de alertas | AlertEngine genérico, reglas configurables |

---

## Componentes Livewire

| Componente | Ruta | Descripción |
|-----------|------|------------|
| InventoryItemsManage | `/inventory/items` | CRUD de ítems/insumos |
| InventoryInsumoCreate | `/inventory/items/new` | Crear nuevo insumo |
| InventoryReceptionsIndex | `/inventory/receptions` | Lista de recepciones |
| InventoryReceptionCreate | `/inventory/receptions/new` | Nueva recepción |
| InventoryReceptionDetail | `/inventory/receptions/{id}/detail` | Detalle GRN |
| InventoryLotsIndex | `/inventory/lots` | Gestión de lotes |
| InventoryAlertsList | `/inventory/alerts` | Alertas de stock |
| InventoryCountIndex | `/inventory/counts` | Conteos físicos |
| OrquestadorPanel | `/inventory/orquestador` | Panel de jobs batch |
| PhysicalCounts | (integrado) | Captura de conteo |

---

## Servicios

| Servicio | Líneas | Estado | Descripción |
|----------|--------|--------|------------|
| TransferService | 315 | ✅ | Transferencias inter-almacén |
| ReceptionService | 276 | ✅ | Recepciones GRN |
| ReceivingService | 240 | ✅ | Wrapper de recepción |
| InventoryCountService | 232 | ✅ | Conteos físicos |
| ProductionService (Inv/) | 283 | ✅ | Consumo de producción |
| UomConversionService | 495 | ✅ | Conversiones de unidades |
| InventoryMovementService | 148 | ✅ | Movimientos manuales |
| AlertEngine | 186 | ✅ | Motor de alertas |

---

## API Endpoints Clave

```
GET  /api/inventory/stock/list          → Stock actual por almacén
GET  /api/inventory/items/{id}/kardex   → Movimientos históricos del ítem
GET  /api/inventory/items/{id}/batches  → Lotes activos
POST /api/inventory/movements           → Movimiento manual (ajuste, merma)
POST /api/inventory/transfers           → Crear transferencia
POST /api/inventory/orquestador/daily-close → Cierre diario (recalculo WAC)
```

---

## Tablas Principales

```
items (maestro)
  ├── unidades_medida (unidad canónica)
  ├── item_vendor (proveedor + presentación + costo)
  └── inventory_batch (lotes)
        ├── cost_layer (capas FIFO/WAC)
        └── historial_costos_item (snapshot mensual)
```

---

## SQL de Deployment

El schema completo de inventario en PG95 está en:
- `D:\Tavo\2025\UX\Inventarios\v3\selemti_deploy_inventarios_PG95_CONSOLIDADO_FINAL.sql`
- Hotfixes: `D:\Tavo\2025\UX\Inventarios\v3\selemti_hotfix_pg95_v2.sql`
- Validación post-deploy: `D:\Tavo\2025\UX\Inventarios\v3\selemti_post_hotfix_checks_v2.sql`

---

## Puntos Pendientes

- [ ] UI para módulo de **Producción** (API existe, sin Livewire frontend)
- [ ] UI para **Kardex** (`/api/inventory/items/{id}/kardex` funciona, sin vista)
- [ ] Consolidar modelos duplicados: `Inv/Item` vs `Inventory/Item`
- [ ] Dashboard de stock con niveles actuales y alertas visuales
