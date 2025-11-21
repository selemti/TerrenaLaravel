# Política de Forecast y Produmix
Versión: 2025-10-27  
Estado: ACTIVO / OBLIGATORIO

## Produmix
- Plan diario de producción por sucursal basado en ventas recientes POS, inventario actual de producto terminado y par objetivo.
- Produmix genera las órdenes que luego se declaran con `ProductionService`.
- Cuando Produmix no se cumple:
  - `MenuAvailabilityService` puede marcar SKU como AGOTADO.
  - También puede reroutear el SKU a cocina/KDS.
  - Ambas acciones son de intervención operativa Nivel 1, requieren permiso `can_manage_menu_availability` y registro en `selemti.menu_availability_log`.

## Corte operativo cocina/barra
- Inventario inicial + producción declarada − venta POS − merma declarada vs inventario físico final.
- Diferencia se guarda con `user_id`, `timestamp` y `motivo` (ver `docs/AUDIT_LOG_POLICY.md`).
- Equivalente a arqueo de caja chica pero para operación de alimentos.

## Permiso `can_manage_produmix`
- Gerente de Sucursal y Dirección pueden publicar/aprobar Produmix diario.  
- Cocina ejecuta producción; no modifica Produmix.

## Referencias
- `docs/Produccion/PRODUMIX.md`  
- `docs/Produccion/PRODUCTION_FLOW.md`  
- `docs/POS/LIVE_AVAILABILITY.md`
