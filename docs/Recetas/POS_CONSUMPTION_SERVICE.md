# POS Consumption Service

## Resumen general
El servicio *POS Consumption* procesa las ventas provenientes del POS para traducirlas en movimientos de inventario dentro del esquema `selemti`. El objetivo es mapear cada ticket y sus líneas a las recetas y subrecetas correspondientes, generando consumos reales de insumos y empaques.

## Tablas involucradas en `selemti`
- `selemti.inv_consumo_pos`: almacena la cabecera del consumo por ticket.
- `selemti.inv_consumo_pos_det`: detalle por artículo/receta consumida.
- `selemti.ticket_item_modifiers`: registra los modificadores asociados a cada línea de ticket (extra queso, empaques, etc.).

Todas las banderas de reproceso y control de flujo se agregan exclusivamente sobre estas tablas del esquema `selemti`.

## Política de Integración POS vs Inventario
- A partir del 27/oct/2025 queda prohibido modificar el esquema `public` de la base de datos (tablas del POS: `public.ticket`, `public.ticket_item`, `public.ticket_item_modifier`, etc.).
- El esquema `public` es de solo lectura para nuestro sistema.
- Toda la lógica operativa nueva (reproceso, banderas de control, auditoría, empaques to-go, etc.) vive en el esquema `selemti`, en tablas como:
  - `selemti.inv_consumo_pos`
  - `selemti.inv_consumo_pos_det`
  - `selemti.ticket_item_modifiers`
  - `selemti.pos_map`
  - `selemti.mov_inv`
- Justificación: así no rompemos el POS, mantenemos trazabilidad histórica y podemos auditar inventario sin tocar ventas originales.

## Esquema `public` (solo lectura)
El esquema `public` contiene la información original del POS y se trata como fuente inmutable. Ninguna migración ni job debe modificar `public.ticket_items` u otras tablas POS: solamente se consultan para obtener datos base.

## Definición de banderas operativas
Los siguientes campos fueron agregados en `selemti.inv_consumo_pos` y `selemti.inv_consumo_pos_det`:

- `requiere_reproceso` (boolean):
  - `true`  = la línea de ticket todavía no ha sido confirmada contra inventario (por ejemplo, porque en su momento no existía el mapeo POS→receta).
  - `false` = la línea ya está lista para confirmación o ya se generó el asiento.
- `procesado` (boolean):
  - `false` = aún NO se ha descontado inventario de forma final.
  - `true`  = ya se descontó inventario; ya existe movimiento definitivo en `selemti.mov_inv`.
- `fecha_proceso` (timestamp):
  - marca el momento en que se confirmó o reprocesó el ticket.
  - esta fecha puede diferir de la fecha de la venta original en el POS.

Estas banderas sustituyen la idea anterior de modificar `public.ticket_item`, y son las que usa el dashboard para semáforos rojo/amarillo/verde.

## Flujo de reprocesamiento
1. El servicio detecta tickets o líneas marcadas con `requiere_reproceso=true` en `selemti.inv_consumo_pos` y `selemti.inv_consumo_pos_det`.
2. Se consultan los datos del POS (`public`) para reconstruir productos, modificadores y cantidades.
3. Se calculan consumos e impactos de inventario con las recetas mapeadas.
4. Al finalizar, se actualizan los flags `procesado` y `fecha_proceso` en las tablas de `selemti`.

## Consideraciones
- El POS es la fuente de verdad de ventas; las tablas en `selemti` son derivadas para inventario.
- Cualquier ajuste (nuevos flags, logs, reprocesos) debe aplicarse en `selemti`.
- Mantener las migraciones alineadas para evitar tocar el esquema `public` durante deploys.

## Flujo de Reproceso Histórico
1. Se captura una venta en el POS → aparece en `public.ticket` y `public.ticket_item`.
2. En ese momento, tal vez no había receta mapeada en `selemti.pos_map`, entonces no se pudo descargar inventario. La venta queda marcada en `selemti.inv_consumo_pos` con `requiere_reproceso = true`, `procesado = false`.
3. Días después, operaciones da de alta la receta y el mapeo POS→receta.
4. Ejecutamos reproceso: expandimos consumo con `fn_expandir_consumo_ticket`, confirmamos con `fn_confirmar_consumo_ticket` usando modo reproceso.
5. Ese reproceso genera movimientos de inventario en `selemti.mov_inv` con tipo especial (por ejemplo `AJUSTE_REPROCESO_POS`) y deja rastro en log.
6. Después del reproceso, marcamos `requiere_reproceso = false`, `procesado = true`, `fecha_proceso = NOW()`.
7. Esto permite:
   - bajar inventario aunque el ticket sea viejo,
   - mantener auditoría de cuándo se hizo el cargo real,
   - y alimentar el dashboard para que ya no salga en rojo.

Este flujo también se aplica cuando se arreglan errores de captura de recetas o de modifiers (por ejemplo "extra pollo") después de la venta.

## Impacto en dashboards y auditoría
- El dashboard `/pos/dashboard/missing-recipes` usa estas banderas para listar:
  - tickets con líneas sin receta asignada,
  - tickets aún no procesados,
  - tickets que requieren reproceso.
- Contabilidad puede justificar diferencias de inventario viendo `fecha_proceso` vs fecha real del ticket.
