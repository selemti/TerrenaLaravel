# Sprint Recetas 1.1 - Producci車n posteable a inventario

## ?? Objetivo
Que cocina pueda producir un lote de una subreceta (ej. Salsa Verde Base, Pollo Deshebrado) y que esa producci車n:
1. Descuente autom芍ticamente las materias primas utilizadas.
2. Genere inventario del producto elaborado (batch con lote/caducidad).
3. Quede lista para ser usada en venta POS.

Este sprint conecta Recetas ? Producci車n ? Inventario.

---

## ?? Alcance funcional

1. **Orden de Producci車n**
   - Crear `Orden de Producci車n` desde una receta tipo ELABORADO.
   - Campos:
     - receta_id (ej. Salsa Verde Base)
     - cantidad_objetivo (ej. 3.0 kg)
     - sucursal_id
     - estado: BORRADOR / EN_PROCESO / TERMINADA / POSTEADA_A_INVENTARIO
     - usuario_crea / usuario_cierra
     - fecha_produccion

2. **Explosi車n de insumos**
   - El sistema calcula insumos requeridos seg迆n la receta versi車n activa:
     - jitomate 2.5 kg
     - chile serrano 0.3 kg
     - etc.

3. **Captura de producci車n real**
   - Al cerrar la orden:
     - cantidad_real_producida
     - merma_real (kg o %)
     - notas del cocinero / evidencia (foto opcional)
     - temperatura final (control sanitario inicial)

4. **Posteo a inventario**
   - Al marcar POSTEADA_A_INVENTARIO:
     - Generar `mov_inv` de SALIDA para cada insumo MATERIA_PRIMA.
     - Crear un nuevo `inventory_batch` para el producto ELABORADO con:
       - item_id (ej. Salsa Verde Base)
       - cantidad_actual = cantidad_real_producida
       - fecha_caducidad
       - temperatura_requerida
       - estado_lote = ACTIVO
     - Generar `mov_inv` de ENTRADA para ese batch.

---

## ?? Modelo de datos / tablas involucradas
- `recipes`, `recipe_versions`, `recipe_version_items`
- `items` (tipo = ELABORADO, MATERIA_PRIMA)
- `production_order` / `op_produccion_cab`
- `production_order_lines` / `op_produccion_det`
- `inventory_batch`
- `mov_inv` / `mov_inv_det`
- `cat_tipo_mov_inv`: agregar tipo
  - `PRODUCCION_SALIDA_CRUDO`
  - `PRODUCCION_ENTRADA_ELABORADO`

---

## ????? Roles operativos
- Cocina: crea y completa la orden.
- Gerente/supervisor: autoriza posteo inventario.
- Sistema: bloquea edici車n despu谷s de "POSTEADA_A_INVENTARIO".

---

## ?? Entregables Sprint 1.1
- Modelo Eloquent `ProductionOrder`, `ProductionOrderLine`.
- Servicio `ProductionPostingService`.
- Migraci車n para tipo de movimiento inventario de producci車n.
- Pantalla `/produccion/{id}` con flujo BORRADOR ↙ EN_PROCESO ↙ TERMINADA ↙ POSTEADA_A_INVENTARIO.

