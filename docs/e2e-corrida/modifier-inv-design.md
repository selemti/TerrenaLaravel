# Diseño: Modificadores POS → Inventario

## Problema

FloreantPOS registra modificadores como texto libre en `public.ticket_item_modifier`:
- No hay FK confiable a `menu_modifier` (la tabla `ticket_item_modifier_relation` está vacía)
- El `group_id` en `ticket_item_modifier` no coincide con `menu_modifier_group.id` del catálogo
- Un modificador como "Pollo" aparece en 10+ grupos diferentes (proteína de picada, enchiladas, chilaquiles...)

**Clave de lookup confiable:** `TRIM(modifier_name)` + contexto del `item_name` del ticket_item padre.

## Dos tipos de efecto de modificador

### Tipo 1 — Selector (reemplaza un slot de la receta base)
Ejemplo: "Salsa Picada" — el cliente elige UNA salsa por picada.
- La receta base de Picada tiene un slot de "salsa" genérico
- El modificador selecciona CUÁL item producible se descuenta: Salsa Roja, Salsa Verde, Chileseco o Frijoles
- **Efecto:** descuenta solo el item del modificador (NO la salsa genérica de la receta base)

### Tipo 2 — Adicional (suma al costo de la receta base)
Ejemplo: "Proteína Picada" — el cliente elige proteína extra
- La receta base de Picada ya cubre la masa/tortilla
- El modificador AGREGA ingredientes encima: Pollo Deshebrado, Chorizo, Huevo, etc.
- "Sencilla" = sin proteína adicional → sin descuento extra
- **Efecto:** descuenta el item del modificador ADEMÁS de la receta base

## Nuevas tablas

### `selemti.pos_menu_item_recipe_mapping`
Puente entre `public.menu_item.id` y `selemti.recipes.id`

```sql
id               BIGSERIAL PK
menu_item_id     INTEGER NOT NULL  -- public.menu_item.id (READ ONLY ref)
menu_item_name   VARCHAR(120)      -- desnormalizado para legibilidad
recipe_id        BIGINT → selemti.recipes.id
porciones_por_orden INTEGER DEFAULT 1  -- "Picada x1" produce 3 piezas → porciones_por_orden=3
activo           BOOLEAN DEFAULT TRUE
created_at, updated_at
```

### `selemti.pos_modifier_inv_mapping`
Mapeo de cada modificador hacia el item de inventario que consume

```sql
id                    BIGSERIAL PK
menu_modifier_id      INTEGER       -- public.menu_modifier.id (fuente canónica)
modifier_name_trim    VARCHAR(120)  -- TRIM(name) — fallback lookup
menu_modifier_group_id INTEGER      -- public.menu_modifier_group.id — contexto/desambigua
item_id               VARCHAR(36)   -- selemti.items.id (NULL = sin efecto en inventario)
qty_por_unidad        DECIMAL(10,6) DEFAULT 0  -- qty a descontar por modifier.item_count=1
uom                   VARCHAR(20)   -- UOM de qty_por_unidad
qty_source            VARCHAR(10) DEFAULT 'MANUAL'  -- 'MANUAL' | 'RECIPE'
recipe_id             BIGINT        -- si qty_source='RECIPE', se toma de selemti.recipes output qty
tipo_efecto           VARCHAR(10) DEFAULT 'ADICIONAL'  -- 'SELECTOR' | 'ADICIONAL'
afecta_costo          BOOLEAN DEFAULT TRUE
activo                BOOLEAN DEFAULT TRUE
created_at, updated_at

UNIQUE (menu_modifier_id)
```

## Items producibles que hay que agregar al catálogo

### Salsas (producibles, se hacen en batch diario/semanal)
| codigo | nombre | UOM base | Receta de producción |
|--------|--------|----------|----------------------|
| PROD-SAL-ROJA | Salsa Roja Base | KG | tomate, chile ancho, ajo, cebolla |
| PROD-SAL-VERDE | Salsa Verde Base | KG | tomate verde, chile serrano, ajo |
| PROD-SAL-CHSECO | Salsa Chile Seco | KG | chile ancho, chile pasilla, ajo |
| PROD-FRIJOL | Frijoles Refritos | KG | frijol negro, manteca, cebolla |
| PROD-MOLE | Mole | KG | chile mulato, chile ancho, chocolate, especias |
| PROD-SAL-ENCNIL | Salsa Enchiladas Verdes | KG | tomate verde, cilantro, chile |

### Proteínas preparadas (producibles)
| codigo | nombre | UOM base | Nota |
|--------|--------|----------|------|
| PROD-POLLO-DESH | Pollo Deshebrado | KG | de pechuga cruda cocida y deshebrada |
| PROD-PICADILLO | Picadillo | KG | carne molida + verduras |
| PROD-CHORIZO | Chorizo Frito | KG | chorizo crudo frito |
| PROD-PASTOR | Pastor | KG | probablemente comprado listo — ítem de compra |
| PROD-CECINA | Cecina | KG | comprada lista — ítem de compra |
| PROD-MILANESA | Milanesa | KG | de pechuga/res empanizada |
| PROD-PECHUGA-A | Pechuga Asada | KG | pechuga cruda marinada/asada |

### Bases de platillos (producibles — batch)
| codigo | nombre | UOM base |
|--------|--------|----------|
| PROD-MASA-PICADA | Masa Picada | KG |
| PROD-CALDO-POLLO | Caldo de Pollo | L |

## Lógica de `PosConsumptionService::confirmTicket`

```
por cada ticket_item en el ticket:
  1. Buscar recipe_id en pos_menu_item_recipe_mapping por menu_item_id
     Si no hay mapeo → registrar en log, saltar (no bloquear)

  2. Calcular porciones = ticket_item.item_count × porciones_por_orden

  3. Descontar ingredientes de la receta base:
     - Obtener recipe_version_items activos
     - Por cada ingrediente: descontar qty × porciones (FEFO de inventory_batch)
     - Generar mov_inv tipo='VENTA_POS' por cada ingrediente

  4. Procesar modifiers del ticket_item:
     por cada ticket_item_modifier:
       a. Lookup en pos_modifier_inv_mapping por menu_modifier_id (si hay relation)
          o por TRIM(modifier_name) + menu_modifier_group_id (fallback)
       b. Si item_id IS NULL → sin efecto (Sencilla, estilos de cocción, etc.)
       c. Si qty_source='RECIPE' → derivar qty del output de la sub-receta
       d. Descontar item_id × (qty_por_unidad × modifier.item_count) por FEFO
       e. Generar mov_inv tipo='VENTA_POS'

  5. Actualizar ticket_item.inventory_handled = true
```

## Cantidades de referencia (a validar con el equipo)

| Modifier | Item | qty/unidad | UOM |
|----------|------|-----------|-----|
| Salsa Picada Roja | PROD-SAL-ROJA | 0.080 | KG |
| Salsa Picada Verde | PROD-SAL-VERDE | 0.080 | KG |
| Salsa Picada Chileseco | PROD-SAL-CHSECO | 0.060 | KG |
| Salsa Picada Frijoles | PROD-FRIJOL | 0.080 | KG |
| Salsa Enchiladas Roja | PROD-SAL-ROJA | 0.120 | KG |
| Salsa Enchiladas Verde | PROD-SAL-VERDE | 0.120 | KG |
| Salsa Chilaquiles Roja | PROD-SAL-ROJA | 0.150 | KG |
| Salsa Chilaquiles Verde | PROD-SAL-VERDE | 0.150 | KG |
| Salsa Chilaquiles Mole | PROD-MOLE | 0.120 | KG |
| Proteína Picada Pollo | PROD-POLLO-DESH | 0.080 | KG |
| Proteína Picada Chorizo | PROD-CHORIZO | 0.060 | KG |
| Proteína Picada Huevo | Huevo (INS) | 1.000 | PZ |
| Proteína Picada Sencilla | NULL | — | — |
| Proteína Chilaquiles Pollo | PROD-POLLO-DESH | 0.100 | KG |
| Proteína Chilaquiles Queso de Hebra | Queso Hebra (INS) | 0.060 | KG |
| Proteína Chilaquiles Huevo | Huevo (INS) | 1.000 | PZ |
| Proteína Enchiladas Pollo | PROD-POLLO-DESH | 0.120 | KG |
| Proteína Enchiladas Huevo | Huevo (INS) | 2.000 | PZ |
| Proteína Enfrijoladas Pollo | PROD-POLLO-DESH | 0.100 | KG |
| Proteína Enmoladas Pollo | PROD-POLLO-DESH | 0.100 | KG |
| Relleno Empanada Pollo | PROD-POLLO-DESH | 0.080 | KG |
| Relleno Empanada Picadillo | PROD-PICADILLO | 0.080 | KG |
| Relleno Empanada Queso | Queso Hebra (INS) | 0.060 | KG |
| Relleno Taco Dorado Pollo | PROD-POLLO-DESH | 0.060 | KG |
| Proteína Mollete Chorizo | PROD-CHORIZO | 0.050 | KG |
| Extra Pollo | PROD-POLLO-DESH | 0.100 | KG |
| Extra Chorizo | PROD-CHORIZO | 0.060 | KG |
| Extra Cecina | PROD-CECINA | 0.100 | KG |

*Todas las cantidades son estimados iniciales. El usuario puede ajustarlas vía UI o directamente en la tabla.*
