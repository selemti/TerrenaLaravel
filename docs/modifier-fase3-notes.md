## Fase 3 - Extensión de corrección de modificadores

- Inventario: se añadió `ModifierValidationService` y `InventoryMovementService` para resolver grupo correcto vía `menu_modifier.group_id` y consumir recetas ligadas a modificadores.
- Recetas: nuevo `RecipeCostService` suma costo base de receta + costo de modificadores usando grupo correcto.
- Compras: `DemandCalculationService` calcula demanda de modificadores con joins usando `ticket_item_modifier.item_id -> menu_modifier.id`.
- Modelos: se agregó `ModifierGroup`, `TicketItemModifier` y relación `modifierGroup` en `MenuModifier`, con accesores `correct_group` e `is_consistent` compatibles con misceláneos (`item_id = 0`).
- Pruebas: `ModifierConsistencyTest` cubre obtención de grupo correcto y consumo de receta de modificador; se salta si no hay driver SQLite disponible.
