# Operaciones Avanzadas (Futuro / Dise?o aprobado)

Este documento describe features avanzados que el sistema debe soportar. No todos son ¡°d¨ªa 1¡±, pero deben ser contemplados al dise?ar tablas, jobs y pantallas.

---

## 1?? Costo de mano de obra (labor cost) por receta

### Objetivo
Incluir costo de preparaci¨®n (minutos de chef / auxiliar / barra) dentro del costo total de una receta y de una producci¨®n.

### C¨®mo se modela
- Tabla `labor_roles`
  - rol: Cocinero L¨ªnea / Auxiliar Barra / Reposter¨ªa
  - rate_per_hour

- Tabla propuesta `recipe_labor`
  - recipe_id
  - labor_role_id
  - minutos_estimados

- Al calcular costo est¨¢ndar de la receta:
  costo_insumos + ¦² (minutos_estimados * rate_per_hour / 60)

### Uso
- En `ProductionOrder`: ¡°esta salsa tard¨® 15 min de cocinero + 5 min de auxiliar¡±
- En costeo final de PLU: ya incluye mano de obra.

---

## 2?? Rendimientos avanzados y merma por etapa

### Problema
No todo lo que compras se convierte 1:1 en producto usable.
Ej:
- Pechuga cruda ¡ú Pechuga limpia (sin grasa)
- Cebolla entera ¡ú Cebolla fileteada
- Cilantro ¡ú Hojas limpias
- Pi?a entera ¡ú Pi?a pelada usable

### Propuesta
- Tabla `prep_steps`
  - step_id
  - nombre (Deshuesar pechuga, Pelar pi?a, Filetear cebolla)
  - rendimiento_esperado_% (ej. 82%)

- Tabla `prep_outputs`
  - step_id
  - item_raw_id (ej. Pechuga cruda)
  - item_prepped_id (ej. Pechuga limpia fileteable)
  - merma_tipo (hueso, c¨¢scara, etc.)

### Uso
- Producci¨®n puede registrar:
  - ¡°Recib¨ª 10 kg de pechuga cruda¡±
  - ¡°Obtuve 8.2 kg de pechuga limpia¡±
- Esa pechuga limpia se convierte en el item que usan las recetas (y el costo por kg sube autom¨¢ticamente porque ya absorbi¨® la merma).

Esto es clave para costeo real y para cuando un gerente pregunta ¡°por qu¨¦ el pollo ¡®me cuesta¡¯ m¨¢s caro que al proveedor¡±.

---

## 3?? Multi-sucursal y transferencias internas

### Objetivo
Permitir que una cocina central produzca subrecetas y las env¨ªe a otra sucursal con trazabilidad de lote.

### Flujo
1. Sucursal A genera producci¨®n (ej. 10 L Salsa Verde Base).
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
- Las salidas/entradas deben mantener `inventory_batch_id` para mantener trazabilidad sanitaria (¡°qu¨¦ lote se us¨® en qu¨¦ ticket en qu¨¦ sucursal¡±).

---

## 4?? Control de caducidad y bloqueo (RECALL / BLOQUEADO)

### Objetivo
Evitar que cocina/venta use producto caducado o en retiro sanitario.

### Estados de batch en `inventory_batch.estado`:
- `ACTIVO`: se puede consumir.
- `BLOQUEADO`: no usar temporalmente (ej. sospecha de contaminaci¨®n).
- `RECALL`: debe retirarse de TODAS las sucursales.

### Reglas
- `VENTA_POS` no puede consumir de un batch BLOQUEADO o RECALL.
- Producci¨®n no puede usar insumo BLOQUEADO/RECALL.
- Interfaz para gerente: marcar un lote como BLOQUEADO y capturar motivo.

### Opcional
- Job nocturno que revise caducidad:
  - Si `fecha_caducidad` < hoy ¡ú mover batch a BLOQUEADO autom¨¢ticamente.
  - Generar `alert_events` para gerente.

---

## 5?? Etiquetado sanitario de lote
(Futuro, pero ya se debe contemplar el campo)

- Cada `inventory_batch` deber¨ªa poder almacenar:
  - `codigo_lote_interno`
  - `fecha_preparacion`
  - `fecha_caducidad`
  - `temperatura_requerida`
  - `responsable_preparacion`
- Esta info es lo que se imprime/etiqueta en la bandeja en cocina.

---

## 6?? Auditor¨ªa de producci¨®n vs consumo

Cruzar:
- ?Cu¨¢nto Salsa Verde producimos esta ma?ana?
- ?Cu¨¢ntos tickets con Salsa Verde se vendieron despu¨¦s?
- ?Cu¨¢nto stock deber¨ªa quedar?
- ?Cu¨¢nto stock queda f¨ªsicamente?

Esto permite detectar fuga (robo, sobre-porcionado, fallas en captura) sin esperar al inventario mensual.

---

## Estado de este documento
- Este documento describe features de nivel ¡°madurez cadena¡±.
- La base de datos actual (production_order, mov_inv, inventory_batch, alert_rules, etc.) ya es compatible con casi todo, s¨®lo requiere completar servicios y pantallas.
- Esto sirve de gu¨ªa a ingenier¨ªa para Sprint Recetas 2.1+ y tambi¨¦n para auditor¨ªa / inocuidad.

