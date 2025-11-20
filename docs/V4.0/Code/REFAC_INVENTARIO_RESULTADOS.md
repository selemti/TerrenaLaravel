# Refactor Inventario – Alineación BD ↔ Código

## 1. Resumen
- MISMATCH corregidos (confirmados contra BD): 6
- FANTASMA atendidos (eliminados o marcados con TODO): 2
- Casos donde el mapa se contradice con BD (conflictos): 0

## 2. Cambios por tabla/columna
| Tabla | Columna | Tipo (MISMATCH/FANTASMA) | Archivos afectados | Acción |
|-------|---------|---------------------------|-------------------|---------|
| mov_inv | ts | MISMATCH | app/Services/Inventory/TransferService.php | cambié fecha_movimiento → ts en modelo/servicio/consulta |
| mov_inv | tipo | MISMATCH | app/Services/Inventory/TransferService.php | cambié tipo_movimiento → tipo en modelo/servicio/consulta |
| mov_inv | ref_tipo | MISMATCH | app/Services/Inventory/TransferService.php | cambié referencia_tipo → ref_tipo en modelo/servicio/consulta |
| mov_inv | ref_id | MISMATCH | app/Services/Inventory/TransferService.php | cambié referencia_id → ref_id en modelo/servicio/consulta |
| mov_inv | sucursal_id | MISMATCH | app/Services/Inventory/TransferService.php | cambié almacen_id → sucursal_id en modelo/servicio/consulta |
| mov_inv | tipo | MISMATCH | app/Services/Operations/PosConsumptionService.php | cambié tipo_movimiento → tipo en modelo/servicio/consulta |
| stock | various | FANTASMA | app/Services/Inventory/TransferService.php | dejé TODO indicando que tabla no existe en BD |
| stock | various | FANTASMA | database/seeders/InventoryOptimizationSeeder.php | dejé TODO indicando que tabla no existe en BD |

## 3. Archivos modificados
- app/Services/Inventory/TransferService.php
  - cambié campos fecha_movimiento → ts, tipo_movimiento → tipo, referencia_tipo → ref_tipo, referencia_id → ref_id, almacen_id → sucursal_id para alinearlo con BD
  - dejé TODOs sobre la tabla 'stock' que no existe en BD y se usaba en la validación de stock
- app/Services/Operations/PosConsumptionService.php
  - cambié campo tipo_movimiento → tipo para alinearlo con BD
- database/seeders/InventoryOptimizationSeeder.php
  - dejé TODOs sobre la tabla 'stock' que no existe en BD y se usaba en creación de índices y vistas
  - actualicé la vista vw_kardex_optimized para usar los nombres correctos de columnas en BD

## 4. Conflictos mapa ↔ BD
No se encontraron conflictos donde el mapa se contradiga con la BD. Todos los casos verificados coincidieron con la estructura real de la base de datos.

## 5. TODOs importantes
- TODO: tabla 'stock' no existe en BD. Revisar diseño de Inventario (en TransferService y seeder).
- TODO: vista 'vw_stock_resumen_optimized' referencia tabla 'stock' que no existe en BD. Revisar diseño de Inventario.
- TODO: en lugar de usar tabla 'stock', se está calculando stock desde mov_inv para validación de transferencias.