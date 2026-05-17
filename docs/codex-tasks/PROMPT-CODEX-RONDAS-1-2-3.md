# Prompt para Codex — E2E Rondas 1, 2 y 3

Copia y pega esto directamente en Codex.

---

Proyecto: TerrenaLaravel (Laravel 12 + PostgreSQL 9.5)
Schema escribible: selemti | Schema READ ONLY: public (FloreantPOS — NUNCA escribir)
NUNCA agregar public a DB_SCHEMA en phpunit.xml.

Lee los siguientes specs completos antes de escribir código:
- docs/codex-tasks/e2e-ronda1-seeder-fixes.md
- docs/codex-tasks/e2e-ronda2-pos-flow.md
- docs/codex-tasks/e2e-ronda3-selector-logic.md

---

CONTEXTO DE NEGOCIO CLAVE (define la arquitectura de las 3 rondas):

El campo selemti.items.tipo_venta_pos (VARCHAR(20), ya migrado) define el comportamiento
POS de cada ítem. Es la fuente de verdad — no el mapping ni la receta:

  NULL            → insumo puro, no aparece en POS
  PRODUCCION      → se fabrica internamente (Salsa Roja, Pollo Deshebrado), no se vende directo
  PLATILLO        → tiene receta de venta (Chilaquiles, Enchiladas, Picada)
  SELECTOR_DEFINE → sin receta base; el modifier SELECTOR define qué SKU se descuenta
                    (Malanga sabores, Suerox sabores, chicles, cualquier producto con variante)
  DIRECTO         → se vende tal cual, sin receta ni selector

Para SELECTOR_DEFINE: el menu item en POS es genérico ("Malanga"). El cliente elige el
sabor como modifier SELECTOR. Ese modifier es el único que descuenta inventario.
No existe receta base porque el producto se compra y se vende tal cual; solo cambia
el sabor/variante. Mismo patrón para Suerox, chicles, y cualquier producto con variantes.

Para PLATILLO: el modifier SELECTOR reemplaza un slot de la receta base (identificado
por uom_receta coincidente). El modifier ADICIONAL suma sobre la receta.

---

RONDA 1 — Fixes bloqueadores en TransactionalFlowSeeder:

1. Hacer idempotente: al inicio de run(), detectar si ya existe una corrida anterior
   (checar mov_inv WHERE tipo='APERTURA'). Si existe, preguntar al usuario si limpiar
   y re-ejecutar. Implementar limpiarCorrida() que elimina en orden FK-safe los
   movimientos, lotes y documentos creados por el seeder.

2. Corregir seedProduccion(): agregar item_producido_codigo a cada receta PROD_* en
   RestaurantDataArrays.php (ej: REC-PROD-001 → 'PROD-001'). Usar ese item como output
   de ProductionService, NO el primer ingrediente. Después de producir, los ítems
   PROD-001 a PROD-009 deben tener stock en inventory_batch.

3. userId dinámico: resolver el primer usuario activo de selemti.users al inicio de run().
   Lanzar RuntimeException si no existe ninguno.

4. Agregar APERTURA (signo=+1, afecta_costo=true) a cat_tipo_mov_inv. Verificar que
   los 9 tipos canónicos estén presentes: RECEPCION_COMPRA, PRODUCCION_ENTRADA,
   PRODUCCION_SALIDA, MERMA, TRASPASO_ENTRADA, TRASPASO_SALIDA, AJUSTE_ENTRADA,
   AJUSTE_SALIDA, VENTA_POS.

---

RONDA 2 — Paso POS al final de TransactionalFlowSeeder:

5. Crear SyntheticPosConsumptionService extendiendo PosConsumptionService con los
   métodos protegidos ticketItemsForProcessing() y modifiersForTicketItem() inyectados
   (mismo patrón de PosConsumptionServiceTest — NO leer public.*).
   dispatchIngestedEvent() debe ser no-op.

6. Agregar seedPosConsumo() que use SyntheticPosConsumptionService para confirmar
   1 ticket por cada entrada activa en pos_menu_item_recipe_mapping. Cubrir:
   - ticket con solo receta base (sin modifiers)
   - ticket con 1 modifier ADICIONAL
   - ticket con 1 modifier SELECTOR
   Registrar el paso en run() inyectando PosModifierService y UomConversionService.

---

RONDA 3 — Lógica SELECTOR híbrida en PosConsumptionService:

7. En confirmTicket(), separar el procesamiento de modifiers por tipo_efecto:
   - Primero procesar todos los SELECTORs; construir array selectorUoms (uom → item_id)
   - Luego llamar deductRecipeIngredients() pasando selectorUoms
   - Finalmente procesar ADICIONAL

8. En deductRecipeIngredients(), recibir selectorUoms y saltarse ingredientes cuyo
   uom_receta ya fue cubierto por un SELECTOR (slot reemplazado).

9. Detectar si el menu item es SELECTOR_DEFINE usando pos_menu_item_recipe_mapping:
   si recipe_id IS NULL → SELECTOR_DEFINE → no llamar deductRecipeIngredients(),
   solo procesar los modifiers SELECTOR.

10. Agregar 4 tests nuevos en PosConsumptionServiceTest:
    A) PLATILLO + SELECTOR reemplaza slot de receta (mismo uom) → ingrediente base NO descontado
    B) PLATILLO + ADICIONAL suma sobre receta base
    C) SELECTOR_DEFINE: menu item sin receta (recipe_id=null) + SELECTOR = único descuento
    D) PLATILLO + SELECTOR con uom diferente al de la receta → fallback suma (safe)

---

Criterio de aceptación:
- php artisan test pasa sin regresiones (base: 342 tests / 1373 assertions)
- Segunda corrida de TransactionalFlowSeeder no duplica movimientos (idempotente)
- inventory_batch de PROD-001 a PROD-009 tienen cantidad_actual > 0 tras seedProduccion()
- mov_inv contiene los 10 tipos canónicos incluyendo APERTURA y VENTA_POS
- 0 batches con cantidad_actual < 0 tras el paso POS
- Los 4 tests nuevos pasan
- NUNCA escribir en public.*, NUNCA leer pos_ticket_item_processed con user_id NULL
