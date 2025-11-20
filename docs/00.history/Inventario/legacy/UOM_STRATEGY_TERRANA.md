Objetivo

Definir una estrategia simple, robusta y auditable para Unidades de Medida (UOM) que cubra compras, inventario, producción/recetas y conteos, minimizando errores operativos y evitando proliferación de UOM.

Principios

3 UOM base (SIEMPRE):
KG (masa), LT (volumen), EA (pieza).
Todo stock y costo estándar se normaliza a una de estas tres.

Presentaciones ≠ UOM base:
Las presentaciones del proveedor (caja, bolsa, charola, etc.) viven como packaging con factor de conversión → base.

Conversión unidireccional canónica:
Cada insumo define su UOM base (kg/lt/ea).
Para cada proveedor-presentación se registra: factor_presentacion_a_base.

Conteos operativos simples:

Almacén puede capturar en presentación (caja, paquete). El sistema convierte a base.

Cocina puede contar en pieza/unidad operativa definida por el insumo (por ej. “botella 1.2 L” → base LT).

Regla de oro: el kardex y valuación se guardan SIEMPRE en base (kg/lt/ea).

Recetas y producción:
Todas las recetas se expresan en UOM base. Si un usuario captura “1 botella 1.2 L”, la UI convierte a 1.2 LT.

Reducción de ruido en catálogos:
No se crean UOM nuevas (nada de “caja”, “botella”, etc. como UOM). Eso es packaging.

Modelo de datos (mínimo viable)

selemti.insumo

id

codigo (único)

nombre

uom_base ENUM {KG, LT, EA}

Otros (perecible, merma_pct…)

selemti.proveedor

id, nombre…

selemti.insumo_proveedor_presentacion

id

insumo_id (FK)

proveedor_id (FK)

presentacion_clave (ej. CAJA_12_X_1.2LT)

descripcion (texto legible)

factor_presentacion_a_base NUMERIC(18,6) > 0
(ej. “caja 12 x 1.2 L” → 14.4 LT)

uom_base (redundante defensiva = del insumo)

sku_proveedor (opcional)

activo

selemti.uom_catalogo_base

Filas fijas: KG, LT, EA

(Opcional) selemti.uom_conversion
Solo si necesitas conversión entre bases (ej. L ↔ kg por densidad): por defecto NO se usa.

Reglas de negocio

Alta de insumo: usuario elige categoría/subcategoría (para código) y UOM base (KG/LT/EA).

Alta de presentación (proveedor-insumo): se captura qué es 1 presentación en base (ej. 14.4 LT).

Compras: OC/recepciones en presentación ⇒ sistema lleva a base.

Conteos:

Almacén puede seleccionar presentación; backend almacena qty_base.

Cocina puede contar en unidad operativa (definida en la ficha del insumo); siempre se baja a base.

Recetas: todas en base. La UI permite equivalencias amigables, pero persiste en KG/LT/EA.

Valuación y kardex: siempre en base.

Validaciones y guardas

uom_base ∈ {KG, LT, EA}.

factor_presentacion_a_base > 0.

Si uom_base = EA, no aceptar factores fraccionarios salvo que el insumo se marque “fraccionable” (opcional).

Bloquear UOM arbitrarias.

UI/UX

Insumo (alta/edición): selector KG/LT/EA (solo 3).

Presentaciones por proveedor:
Tabla: Presentación | Factor → Base | SKU proveedor | Activo
Botón “Añadir presentación”.

Compras: usuario elige presentación, cantidad y costo por presentación. El sistema muestra conversión a base y costo por base (readonly).

Conteos:
Toggle “Contar por presentación” / “Contar por unidad operativa”; debajo se ve qty_base calculada.

# Estrategia de Unidades (UOM) – Terrena

## 1) Unidades base operativas
Se usan **tres** unidades base en inventario: **KG**, **L**, **PZA**.  
Fuente: `selemti.cat_unidades (id, clave, nombre, activo)` con `UNIQUE (clave)`.

- KG — masa
- L  — volumen
- PZA — conteo

El alta de insumos selecciona **una** UOM base (KG/L/PZA).  
> Las **presentaciones de compra** y **factores** NO se configuran aquí.

## 2) Presentaciones por Proveedor–Insumo
Se definen en **Proveedor–Insumo** (IPP), donde:
- `uom_base_id` y `uom_compra_id` referencian `cat_unidades(id)`.
- `insumo_id` referencia `insumo(id)` y `proveedor_id` referencia `proveedor(id)`.

Esto permite:
- Comprar “**caja x12 botellas de 1.2 L**” (UOM compra) y convertir a **L** (UOM base).
- Contar en cocina por **PZA** cuando aplique (inventario teórico y físico consistentes).

## 3) Buenas prácticas
- Mantener **catálogo de conversiones** separado (si aplica) y per-proveedor en IPP.
- No mezclar presentaciones en el alta de insumos; centralizarlo en IPP.
