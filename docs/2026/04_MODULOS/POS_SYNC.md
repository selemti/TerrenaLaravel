# Módulo POS Sync — Integración FloreantPOS ↔ Laravel
> Actualizado: Abril 2026

## Objetivo

Sincronizar los datos de ventas del POS (FloreantPOS Java) con el ERP Laravel para:
1. Consumo teórico de inventario (descuento de stock por venta)
2. Reportes de ventas consolidados
3. Conciliación de caja

---

## Arquitectura de Integración

```
FloreantPOS (Java)
  schema: public (PostgreSQL)
  → tickets, ticket_items, transactions, drawer_assigned_history

                    ↕ (lectura directa, mismo servidor PostgreSQL)

Laravel ERP
  schema: selemti (PostgreSQL)
  → pos_item_mapping, inventory_batch, movimientos
```

No hay API entre FloreantPOS y Laravel — ambos acceden directamente a PostgreSQL.

---

## Mapeo de Productos

`pos_item_mapping` relaciona:
- `menu_item.id` (FloreantPOS) → `items.id` (selemti)
- Con factor de conversión y unidad

La UI de mapeo está en `/pos/map` (PosMapIndex Livewire).

---

## Consumo de Inventario por Ventas

`PosConsumptionService` (461 líneas) — ✅ implementado

Proceso batch que corre cada 60 segundos:
1. Lee tickets nuevos desde `public.ticket` (no procesados aún)
2. Por cada `ticket_item`, busca el insumo mapeado en `pos_item_mapping`
3. Calcula cantidad consumida (ticket_item.quantity × factor_conversión)
4. Decrementa `inventory_batch.cantidad_actual` (FEFO)
5. Registra en `movimientos` como salida tipo "VENTA"
6. Actualiza cost_layer y costo promedio WAC

---

## Servicios

| Servicio | Líneas | Descripción |
|----------|--------|------------|
| PosConsumptionService (Pos/) | 461 | Motor principal de consumo |
| PosSyncService | 168 | Sincronización general |
| TicketRepository | 166 | Lectura de tickets FloreantPOS |
| ConsumoPosRepository | 141 | Repositorio de consumo |
| RecetaRepository | 98 | Acceso a recetas para consumo |
| CostosRepository | 96 | Acceso a costos |
| InventarioRepository | 95 | Acceso a stock |

---

## Componentes POS

| Componente | Ruta | Descripción |
|-----------|------|------------|
| PosMapIndex | `/pos/map` | Mapeo visual items POS → insumos |
| PosMappingIndex | `/pos/mapping` | Índice de mapeos |
| PosMappingForm | (integrado) | Formulario de mapeo |
| PosMap | (modelo Livewire) | Gestión de mapeo |

---

## Diagnóstico

`GET /api/reports/sales/diagnostics` — muestra diferencias entre ventas POS y consumo registrado.

`PosConsumptionDiagnostics` (DTO, 113 líneas) — estructura de resultado del diagnóstico.

---

## Notas de Sincronización

- El trigger de consumo puede desactivarse temporalmente (`TRIGGER_INVENTARIO_TICKET_DESACTIVADO.md`)
- La sincronización de Floreant ↔ Laravel está documentada en `docs/SINCRONIZACION_FLOREANT_LARAVEL.md`
- En producción, FloreantPOS y Laravel usan el mismo servidor PostgreSQL (100.126.124.101)
