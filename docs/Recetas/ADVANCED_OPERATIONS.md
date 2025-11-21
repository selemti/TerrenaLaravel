# Operaciones Avanzadas (Futuro / Dise?o aprobado)

Este documento describe features avanzados que el sistema debe soportar. No todos son ��d��a 1��, pero deben ser contemplados al dise?ar tablas, jobs y pantallas.

---

## 1?? Costo de mano de obra (labor cost) por receta

### Objetivo
Incluir costo de preparaci��n (minutos de chef / auxiliar / barra) dentro del costo total de una receta y de una producci��n.

### C��mo se modela
- Tabla `labor_roles`
  - rol: Cocinero L��nea / Auxiliar Barra / Reposter��a
  - rate_per_hour

- Tabla propuesta `recipe_labor`
  - recipe_id
  - labor_role_id
  - minutos_estimados

- Al calcular costo est��ndar de la receta:
  costo_insumos + �� (minutos_estimados * rate_per_hour / 60)

### Uso
- En `ProductionOrder`: ��esta salsa tard�� 15 min de cocinero + 5 min de auxiliar��
- En costeo final de PLU: ya incluye mano de obra.

---

## 2?? Rendimientos avanzados y merma por etapa

### Problema
No todo lo que compras se convierte 1:1 en producto usable.
Ej:
- Pechuga cruda �� Pechuga limpia (sin grasa)
- Cebolla entera �� Cebolla fileteada
- Cilantro �� Hojas limpias
- Pi?a entera �� Pi?a pelada usable

### Propuesta
- Tabla `prep_steps`
  - step_id
  - nombre (Deshuesar pechuga, Pelar pi?a, Filetear cebolla)
  - rendimiento_esperado_% (ej. 82%)

- Tabla `prep_outputs`
  - step_id
  - item_raw_id (ej. Pechuga cruda)
  - item_prepped_id (ej. Pechuga limpia fileteable)
  - merma_tipo (hueso, c��scara, etc.)

### Uso
- Producci��n puede registrar:
  - ��Recib�� 10 kg de pechuga cruda��
  - ��Obtuve 8.2 kg de pechuga limpia��
- Esa pechuga limpia se convierte en el item que usan las recetas (y el costo por kg sube autom��ticamente porque ya absorbi�� la merma).

Esto es clave para costeo real y para cuando un gerente pregunta ��por qu�� el pollo ��me cuesta�� m��s caro que al proveedor��.

---

## 3?? Multi-sucursal y transferencias internas

### Objetivo
Permitir que una cocina central produzca subrecetas y las env��e a otra sucursal con trazabilidad de lote.

### Flujo
1. Sucursal A genera producci��n (ej. 10 L Salsa Verde Base).
2. Crea una **Orden de Transferencia** hacia Sucursal B:
   - lote_id
   - cantidad_enviada
3. Sucursal B recibe:
   - Se genera `mov_inv` ENTRADA en B.
   - Se genera `mov_inv` SALIDA en A.
4. Ambas sucursales heredan la caducidad original del lote.

### Notas
- Esto requiere una tabla `transfer_orders` (+ `transfer_order_lines`) con estados:
  - BORRADOR / ENVIADA / RECIBIDA.
- Las salidas/entradas deben mantener `inventory_batch_id` para mantener trazabilidad sanitaria (��qu�� lote se us�� en qu�� ticket en qu�� sucursal��).

---

## 4?? Control de caducidad y bloqueo (RECALL / BLOQUEADO)

### Objetivo
Evitar que cocina/venta use producto caducado o en retiro sanitario.

### Estados de batch en `inventory_batch.estado`:
- `ACTIVO`: se puede consumir.
- `BLOQUEADO`: no usar temporalmente (ej. sospecha de contaminaci��n).
- `RECALL`: debe retirarse de TODAS las sucursales.

### Reglas
- `VENTA_POS` no puede consumir de un batch BLOQUEADO o RECALL.
- Producci��n no puede usar insumo BLOQUEADO/RECALL.
- Interfaz para gerente: marcar un lote como BLOQUEADO y capturar motivo.

### Opcional
- Job nocturno que revise caducidad:
  - Si `fecha_caducidad` < hoy �� mover batch a BLOQUEADO autom��ticamente.
  - Generar `alert_events` para gerente.

---

## 5?? Etiquetado sanitario de lote
(Futuro, pero ya se debe contemplar el campo)

- Cada `inventory_batch` deber��a poder almacenar:
  - `codigo_lote_interno`
  - `fecha_preparacion`
  - `fecha_caducidad`
  - `temperatura_requerida`
  - `responsable_preparacion`
- Esta info es lo que se imprime/etiqueta en la bandeja en cocina.

---

## 6?? Auditor��a de producci��n vs consumo

Cruzar:
- ?Cu��nto Salsa Verde producimos esta ma?ana?
- ?Cu��ntos tickets con Salsa Verde se vendieron despu��s?
- ?Cu��nto stock deber��a quedar?
- ?Cu��nto stock queda f��sicamente?

Esto permite detectar fuga (robo, sobre-porcionado, fallas en captura) sin esperar al inventario mensual.

---


---

## 7.0 Costo por Lote y Revaluación de Inventarios

Para un control financiero preciso, el sistema maneja un esquema de costeo dual que separa el costo real de producción del costo estándar para análisis.

### 7.1 Costo por Lote (Costo Real)

-   **Concepto:** Cada lote (`inventory_batch`) que se produce o se recibe de un proveedor tiene su propio costo unitario (`unit_cost`). Este es el costo "real" y se utiliza para la valoración contable del inventario.
-   **Cálculo en Producción:** Cuando se crea un lote de una sub-receta, su `unit_cost` se calcula basándose en el costo promedio ponderado de los insumos consumidos en esa orden de producción específica.
-   **Impacto:** Este es el costo que se utiliza para calcular el Costo de Mercancía Vendida (CMV) cuando un producto final se vende.

### 7.2 Revaluación de Lotes

-   **Escenario:** A veces, el costo de un lote debe ser ajustado post-producción. Por ejemplo, si se descubre un error en el precio de compra de una materia prima clave.
-   **Mecanismo:** Se utiliza el tipo de movimiento `AJUSTE_COSTO_BATCH`. Este es un movimiento no físico (no altera la cantidad en stock) que modifica el `unit_cost` del lote y genera un asiento contable para registrar la revaluación del inventario.

### 7.3 Costo Estándar y Snapshots Diarios

-   **Concepto:** El costo estándar es un costo de referencia o "ideal" para una receta, calculado con los precios más actuales de los insumos. No se utiliza para la contabilidad del inventario, sino para el análisis y la toma de decisiones.
-   **Proceso:** El job `RecipeCostSnapshotJob` se ejecuta cada noche.
    1.  Obtiene los costos más recientes de todas las materias primas.
    2.  Recalcula el costo de cada receta y sub-receta.
    3.  Guarda este costo en la tabla `recipe_cost_history` con la fecha del día.
-   **Uso:**
    -   **Ingeniería de Menú:** Analizar la rentabilidad de los platos con un costo consistente.
    -   **Fijación de Precios:** Tomar decisiones de precios basándose en un costo estable y actualizado.
    -   **Detección de Variaciones:** Comparar el costo real de producción de un lote con el costo estándar del día para identificar ineficiencias, mermas excesivas o problemas de compra.

---

## Estado de este documento
- Este documento describe features de nivel "madurez cadena".
- La base de datos actual (production_order, mov_inv, inventory_batch, alert_rules, etc.) ya es compatible con casi todo, sólo requiere completar servicios y pantallas.
- Esto sirve de guía a ingeniería para Sprint Recetas 2.1+ y también para auditoría / inocuidad.

*Versión 2.1 — Octubre 2025*
