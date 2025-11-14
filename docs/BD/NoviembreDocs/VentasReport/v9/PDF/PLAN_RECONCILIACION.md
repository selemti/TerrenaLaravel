# Plan de reconciliación Terrena × FloreantPOS

Objetivo: Mostrar los mismos datos que los reportes de FloreantPOS en nuestros endpoints, con mejoras (filtros, pivots y exportes), y eliminar discrepancias.

## Hipótesis de diferencias (a validar)

- Inclusión/Exclusión de pagos: REFUND / VOID_TRANS, transacciones voided.
- Timezone y fecha base: `folio_date` vs `create_date` / `closing_date`.
- Redondeo en PG 9.5: `ROUND(double,2)` vs `ROUND(numeric,2)` — desajustes por casting.
- Propinas / Servicio: si Floreant los expone en totales o no; en Terrena los separamos.
- Descuento en encabezado vs línea: `ticket.total_discount` vs SUM(`ticket_item.discount`).
- Normalización de métodos: `fn_normalizar_forma_pago` — mapping de subtipos.

## Procedimiento

1) Selección de días y sucursales de referencia (mínimo 3 fechas con volumen):
   - Por ejemplo: 2025-10-24 (PRINCIPAL), 2025-10-30 (PRINCIPAL), 2025-11-03.

2) Ejecutar `AUDIT_DIVERGENCIAS.sql` reemplazando los marcadores:
   - `{{START}}` y `{{END}}` por el día a comparar.
   - Revisar secciones: SUMMARY, BALANCE, BALANCE_METHOD, MENU_USAGE.

3) Si hay diferencias:
   - REFUND/VOID_TRANS: confirmar que Floreant los excluye; Terrena ya los excluye.
   - Redondeos: forzar `::numeric` antes de `ROUND`, estandarizar a 2 decimales.
   - Fecha base: confirmar que Floreant usa `folio_date` (o equivalente); si no, ajustar.
   - Descuento: confirmar fuente en Floreant (encabezado vs línea) y alinear.

4) Validar Journal por ticket:
   - Suma de líneas (total − descuento) ≈ neto de ticket.
   - Suma de pagos válidos ≈ cobrado; comparar contra Balance.

5) Documentar hallazgos y aplicar ajustes en vistas o controladores.

## Entregables y estado

- Vistas implementadas (PG 9.5 compatible), controladores y blades con exportes.
- Mix de ventas con pivot de formas de pago y multiselect de sucursales.
- Fallback en Excepciones si la vista falta.

## Próximos pasos

- Exportes Excel para los 6 reportes.
- Paginación server-side en Detalle/Journal para rangos largos.
- Si Floreant considera propinas/servicio en algún total, añadir toggle de inclusión.

