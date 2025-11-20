# Conteo físico y Conversión a Unidad Base

## Objetivo
Evitar discrepancias cuando almacén cuenta por “cajas” y cocina por “piezas” o “litros” sueltos. Todo se consolida en **UOM base**.

## Flujo de conversión
1. El usuario elige la presentación que está contando (si aplica) o captura directamente en base.
2. La aplicación calcula:
cantidad_base = cantidad_capturada × factor_a_base

markdown
Copiar código
3. El **kardex** solo persiste cantidades en base.

## Donde se usa
- Recepciones de compra (presentación proveedor → **base**).
- Conteos cíclicos e inventario anual (presentación o suelto → **base**).
- Producción/mermas (consumo/ajuste → **base**).

## Ejemplo (leche)
- Recepción: 10 cajas × (12 × 1.2 L) → 10 × 14.4 = **144 L** en kardex.
- Cocina: 3 botellas sueltas de 1.2 L → 3 × 1.2 = **3.6 L** en kardex.

## Validaciones recomendadas
- No permitir presentaciones sin **factor_a_base**.
- Advertir si el factor no coincide con la UOM base del insumo.
- Redondeo configurable por familia (p. ej., 3 decimales para litros).

## Reportes
- Movimiento y existencias siempre en UOM base.
- Si el usuario desea “ver en cajas”, se hace *rendering* inverso (base ÷ factor de una presentación elegida).