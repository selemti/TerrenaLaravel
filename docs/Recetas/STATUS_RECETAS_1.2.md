# Sprint Recetas 1.2 - Consumo POS autom¨¢tico

## ?? Objetivo
Cuando se vende algo en el POS (ej. "Enchiladas Rellenas con Salsa Verde y Pollo"), el sistema debe:
1. Identificar la receta base del producto vendido.
2. Identificar los modificadores seleccionados (salsa, prote¨ªna, empaque para llevar).
3. Calcular las cantidades de cada insumo/subreceta.
4. Registrar la salida de inventario (`mov_inv`) asociada al ticket.

---

## ?? Alcance funcional

1. **Enlace POS ¡ú Receta**
   - Cada `menu_item` apunta a una `recipe_version`.
   - Cada modificador POS apunta a una `recipe_version` (ej. "Salsa Verde Base", "Prote¨ªna Pollo Deshebrado", "Empaque Platillo Caliente").

2. **Explosi¨®n de receta al momento de venta**
   - Para cada `ticket_item`:
     - Consumir receta base (tortilla, crema, queso, frijol, etc.).
   - Para cada `ticket_item_modifier`:
     - Consumir receta_modificador_id asignada (salsa espec¨ªfica, prote¨ªna espec¨ªfica, empaque si aplica).

3. **Descarga de inventario**
   - Consolidar todas las cantidades por item_id.
   - Generar `mov_inv` tipo `VENTA_POS` con detalle:
     - item_id
     - cantidad_salida
     - batch_id (seg¨²n FEFO / PEPS por sucursal)
     - referencia ticket

4. **Empaque / to-go**
   - Si el ticket trae flag "para llevar", inyectar receta `Empaque Platillo Caliente`:
     - Charola t¨¦rmica
     - Cubiertos desechables
     - Servilleta
     - Vasito salsa

---

## ?? Tablas / campos usados
- `tickets`, `ticket_items`, `ticket_item_modifiers`
- `recipes`, `recipe_versions`, `recipe_version_items`
- `modificadores_pos` (campo `receta_modificador_id`)
- `inventory_batch`
- `mov_inv` tipo `VENTA_POS`

---

## ?? Notas importantes
- Este consumo POS es lo que permite que stock en c¨¢mara / almac¨¦n baje en tiempo real sin captura manual.
- Esto tambi¨¦n alimenta costo de venta por PLU, margen, ingenier¨ªa de men¨².
- Requiere que ya exista stock posteado desde Producci¨®n (Sprint 1.1) para subrecetas tipo Salsa Verde, Pollo Deshebrado, etc.

---

## ?? Entregables Sprint 1.2
- Servicio `PosConsumptionService`.
- Funci¨®n para mapear ticket_item ¡ú recipe_version ¡ú insumos.
- Generaci¨®n autom¨¢tica de `mov_inv` tipo `VENTA_POS`.
- Estrategia FEFO al seleccionar lotes de `inventory_batch`.
- Dashboard t¨¦cnico de auditor¨ªa: "ticket vs consumo registrado".
