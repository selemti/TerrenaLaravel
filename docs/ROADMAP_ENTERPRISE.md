# Roadmap Operativo & Estratégico
Versión: 2025-10-27
Estado: ACTIVO / OBLIGATORIO

## Fase Operativa (Nivel 1 – ya funcional)
- Recetas con implosión (receta → subreceta → insumo crudo).
- Producción y merma (`ProductionService`).
- Inventario multi-almacén.
- Reproceso POS (`inv_consumo_pos`, `ticket_item_modifiers`, `pos_map`).
- Disponibilidad POS / agotados / reroute a cocina (`MenuAvailabilityService`).
- Compras, recepción y costeo por lote.
- Seguridad y roles.

## Fase Gerencial (Nivel 2 – siguiente sprint inmediato)
- Produmix (plan diario de producción por sucursal).
- Corte de cocina/barra por turno (arqueo productivo).
- Consolidación diaria de ventas y KPIs en tablas de resumen en `selemti` (venta neta, costo teórico, merma, margen).
- Auditoría centralizada con bitácora por acción.
- Reportes exportables a Excel.

## Fase Estratégica (Nivel 3 – futuro)
- Forecast avanzado (clima, día de la semana, temporada).
- Control de caducidad / recall de lote.
- Mano de obra en costo receta (labor cost).
- Transferencias automáticas cocina central → sucursales.
- Integración contable externa.

## Principios no negociables
- Ningún movimiento de inventario / costo / disponibilidad POS sin: permiso, motivo, user_id, timestamp.
- Nada se puede vender en POS si no tiene receta que implosiona hasta insumo inventariable con costo.
