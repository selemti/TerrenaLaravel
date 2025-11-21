# Sprint Recetas 1.4 - Replenishment para consumibles y prep

## ?? Objetivo
Extender Replenishment para que ya no s¨®lo cubra comida cruda, sino tambi¨¦n:
- subrecetas cr¨ªticas (ej. Salsa Verde Base en c¨¢mara)
- consumibles operativos (vasos, tapas, charolas, guantes, desinfectante)

Queremos:
1. Ver en la misma vista qu¨¦ insumos se est¨¢n agotando (pollo crudo, leche) y qu¨¦ consumibles operativos se est¨¢n agotando (vasos fr¨ªos, tapa domo, guantes).
2. Generar sugerencias de compra para ambos.
3. Que compras pueda emitir solicitudes de compra con ambos tipos de ¨ªtems.

---

## ?? Alcance funcional

1. **Pol¨ªtica de stock m¨ªnimo/m¨¢ximo por sucursal**
   - Para cada `item_id`, definir:
     - `stock_min`
     - `stock_max`
     - `reorder_multiple` (ej. se compran cajas de 50 tapas, no piezas sueltas)
   - Esto aplica tanto a comida como a consumibles.

2. **Replenishment unificado**
   - El job que hoy calcula ¡°sugerencia de compra¡± debe incluir:
     - Items perecederos (pollo, quesos, frutas)
     - Items de barra / jarabes
     - Items de empaque (vasos, tapas, charolas)
     - Items de limpieza (desinfectante)
   - Cada sugerencia indica:
     - `sucursal_id`
     - `item_id`
     - `cantidad_sugerida`
     - `proveedor_sugerido_id`
     - tipo item (para que compras entienda si es comida o consumible operativo)

3. **Salida a flujo actual de compras**
   - Al aceptar la sugerencia, se genera requisici¨®n / request igual que en Sprint Compras.
   - No creamos un flujo paralelo. Consumible y comida caen al mismo pipeline de compra.

---

## ?? Tablas / servicios tocados
- `stock_policy` (o tabla equivalente por sucursal + item)
- `purchase_suggestion` / `purchase_suggestion_lines`
- `item_vendor`, `item_vendor_prices`
- `req_cab`, `req_det` (solicitud de compra resultante)

---

## ?? Entregables Sprint 1.4
- Campo o tabla para stock_min / stock_max por (sucursal_id, item_id).
- Extensi¨®n del generador de sugerencias de compra para incluir items con `es_consumible_operativo = true` y items tipo `ELABORADO` cr¨ªticos (ej. jarabe base, topping clave).
- Ajustes UI en Replenishment para mostrar ¡°Consumo operativo¡±.
