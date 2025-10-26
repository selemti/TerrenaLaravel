# Sprint Recetas 2.0 - Costos, m¨¢rgenes y alertas

## ?? Objetivo
Dar visibilidad financiera y operativa:
- Costo est¨¢ndar y costo real por porci¨®n.
- Margen por PLU.
- Popularidad vs contribuci¨®n (ingenier¨ªa de men¨²).
- Alertas cuando sube costo de receta o se cae margen.

---

## ?? Alcance funcional

1. **C¨¢lculo de costo est¨¢ndar de receta**
   - Para cada `recipe_version`:
     - Sumar costo unitario actual de cada ingrediente.
     - Incluir subrecetas (`ELABORADO`) con su costo calculado m¨¢s reciente.
     - Dividir entre `yield_portions` / porciones est¨¢ndar.
   - Guardar snapshot en `recipe_cost_history`.

2. **C¨¢lculo de margen por PLU**
   - Para cada `menu_item`:
     - Precio de venta actual (POS).
     - Costo est¨¢ndar por porci¨®n (arriba).
     - Margen bruto = precio - costo.
   - Guardar en `menu_engineering_snapshots`.

3. **Clasificaci¨®n tipo ingenier¨ªa de men¨²**
   - Para cada `menu_item` en ventana de tiempo (ej. ¨²ltimas 2 semanas por sucursal):
     - Popularidad (ventas totales).
     - Margen contribuci¨®n.
   - Clasificar:
     - Estrella (alto margen / alta demanda)
     - Vaca (bajo margen / alta demanda)
     - Puzzle (alto margen / baja demanda)
     - Perro (bajo margen / baja demanda)

4. **Alertas autom¨¢ticas**
   - Nueva `alert_rules` tipo:
     - ¡°Si margen bruto de PLU cae < X%¡±
     - ¡°Si costo est¨¢ndar de una receta sube > Y% en 7 d¨ªas¡±
   - Generar `alert_events`.

---

## ?? Tablas / funciones involucradas
- `fn_item_unit_cost_at`
- `recipe_cost_history`
- `menu_engineering_snapshots`
- `alert_rules`
- `alert_events`

---

## ?? Entregables Sprint 2.0
- Job nocturno `RecipeCostSnapshotJob`.
- Job nocturno `MenuEngineeringSnapshotJob`.
- Pantalla de ingenier¨ªa de men¨² por sucursal y periodo.
- Pantalla de alertas recientes para gerente / direcci¨®n.
