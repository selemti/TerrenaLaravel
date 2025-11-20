# Política de Unidades Base (UOM) en Terrena

## Resumen
- **Solo 3 UOM base:** Kilo (KIL), Litro (LIT), Pieza (PZA).
- Todo el **stock**, **kardex**, **reconteos** y **reportes** operan en **UOM base**.
- Las **presentaciones** (caja x12, botella 1.2L, etc.) se mapean en *Proveedor ↔ Insumo* con **factores de conversión** hacia la UOM base.

## Ventajas
- Cierres y conteos consistentes (no hay mezcla de UOMs).
- Menos errores por “piezas internas” vs “volumen real”.
- Costo unitario normalizado (costo por KIL/LIT/PZA).

## Reglas
1. El **catálogo de UOM para alta de insumos** solo muestra **KIL/LIT/PZA**.
2. En **Proveedor ↔ Insumo** se capturan:
   - Presentación (ej. *caja 12 × 1.2 L*, *pack 10 × 1 L*, *saco 25 kg*, etc.).
   - **Factor a base** (ej. 1 caja = 14.4 **L**; 1 saco = 25 **KIL**).
   - SKU proveedor, claves, etc.
3. **Compras** y **recepciones** pueden capturarse en presentación del proveedor; el sistema **convierte a base** para el kardex.
4. **Conteos**:
   - Almacén puede contar por presentación (el sistema convierte a base).
   - Cocina puede contar por **pieza** cuando aplique (p. ej., “botellas sueltas”), siempre convertido a la base que corresponda.

## Ejemplos
- Leche 1.2 L (base **LIT**):
  - Caja: 12 × 1.2 L → factor caja = **14.4 L**.
  - Pack: 10 × 1.0 L → factor pack = **10.0 L**.
- Botana 60 g (base **PZA** si se controla por empaque/porción).
- Harina 25 kg (base **KIL**): saco = **25 KIL**.

## Notas
- Las conversiones a base se centralizan en un servicio de conversión (dominio *inventory*).
- Reportes de costo y valuación siempre en base.
