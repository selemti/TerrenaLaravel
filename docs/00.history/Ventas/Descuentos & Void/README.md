# Reporte de excepciones: descuentos y void

## Cambios de logica (2025-11-06)
- Los pagos por ticket ahora se separan en dos sumas: cobros positivos (`payment_total`) y ajustes negativos (`payment_adjustment_total`). Los ajustes se excluyen de la verificacion principal contra el neto del ticket y se registran aparte en las notas.
- El reporte agrega el conteo de movimientos positivos y ajustes para cada ticket. Cuando existen ajustes relevantes (por ejemplo retiros en efectivo o cambios), se anota `Ajustes fuera de pago` en las notas de la categoria correspondiente.
- Las alertas por `Cerrados sin pago`, `Anulados con cobros` y `Pagos vs Neto` incluyen los nuevos ajustes en sus notas para facilitar el analisis de la diferencia real.
- Cada transaccion expuesta al frontend incluye banderas (`is_refund`, `is_void`, `is_adjustment`, `direction`) para clasificarla en la vista y resaltar reembolsos, voids y salidas de efectivo.
- Se corrigio la normalizacion de montos: `gross_total` ahora usa el subtotal original y `net_total` respeta el total pagado en POS. Con esto los descuentos al 100% provenientes de `ticket_discount` se detectan correctamente y los registros de `Pagos vs Neto` ya no se inflan con diferencias ficticias.
- El panel de detalle añade los items del ticket (cantidad, precio, descuento y total) y muestra la diferencia contra los cobros netos (`payment_total + ajustes`) para cuadrar la informacion con el POS.

## Ajustes de interfaz
- La tarjeta principal ahora muestra `Impacto global de excepciones` y resalta el subtotal de descuentos detectados para ayudar a reconciliarlo con el resumen.
- El bloque `Resumen de descuentos` destaca el total con un badge de alto contraste y mantiene la tabla ordenada por monto.
- La tarjeta de `Categorias activas` exhibe todas las categorias principales y suma un chip `+n mas` cuando hay mas de tres activas.
- Las filas del detalle por categoria son expandibles: al hacer clic se muestra un panel con notas completas, resumen de montos (neto, cobros, ajustes, diferencia), chips de descuentos y chips de movimientos clasificados por tipo.
- La seccion de filtros replica el layout del reporte de Mix de ventas (agrupacion en fila, botones alineados a la derecha y limites de fecha).

## Consideraciones operativas
- Los ajustes negativos siguen almacenados en la base como montos negativos; ahora se conservan para auditoria pero no generan alertas por `Pagos vs Neto` si los cobros positivos cubren el neto.
- Los movimientos `REFUND` y `VOID_TRANS` continúan visibles en el detalle y se destacan con badges propios para diferenciarlos de ajustes manuales.
- Si una terminal no reporta descuentos o movimientos, el panel de detalle lo comunica explicitamente (`Sin notas`, `Sin descuentos`, `Sin movimientos`) para evitar dudas al analizar la excepcion.

## Excepciones de Venta del Día (Caja)

### Flujo de datos
1. La vista `resources/views/caja/cortes.blade.php` invoca a `CajaController@index`, el cual fija la fecha seleccionada (`?date=YYYY-MM-DD`) y, además de las sesiones de caja, llama a `obtenerAnulaciones($date)` para poblar el widget **Excepciones de Venta del Día**.
2. `obtenerAnulaciones` (`app/Http/Controllers/Api/Caja/CajaController.php:174`) ejecuta una `CTE` que unifica cinco conjuntos:
   - **Anulación**: tickets con `t.voided = true`, monto = `t.total_price`, razón = `t.void_reason`.
   - **Devolución**: tickets con `t.refunded = true` (y no anulados), monto = `t.total_price`, razón fija “Reembolso completo”.
   - **Desperdicio**: tickets con `t.wasted = true`, monto = `t.total_price`.
   - **Descuento**: tickets no anulados con `t.total_discount > 0`, monto = `t.total_discount`, razón = `STRING_AGG` de `ticket_discount.name` o `ticket_item_discount.name`.
   - **Ajuste**: tickets con `t.adjustment_amount <> 0`, monto = `ABS(t.adjustment_amount)`, razón indica si fue positivo o negativo.
3. La consulta retorna máximo 50 renglones ordenados por prioridad (anulaciones primero) y hora de creación descendente. Cada objeto incluye el `ticket_internal_id`, folio, terminal, usuario y monto que luego se muestran en la tabla compacta (primeros 5) y en el modal de historial.
4. El detalle por ticket (botón “Ver detalle”) no se alimenta de este query; la vista dispara `GET /api/caja/ticket/{ticketId}`, que vuelve a consultar `ticket`, `ticket_item`, `ticket_discount`, `ticket_item_discount` y `transactions` para renderizar totales, items, descuentos y movimientos.

### Limitaciones actuales
- El widget solo lee tablas `ticket*`; no cruza contra `transactions`, por lo que diferencias entre cobros y neto se detectan únicamente en el reporte de excepciones completo (`SalesExceptionsController`) y no aquí.
- Se usa `t.total_discount` como monto único para la fila “Descuento”, de modo que, si un ticket acumula varias campañas, la tabla solo refleja la suma global.
- El `STRING_AGG` de razones excluye montos, por lo que no es posible saber qué proporción corresponde a cada cupón sin abrir el modal de detalle.
- Solo se devuelven 50 registros; si en un día hay más de 50 excepciones se truncarán las de menor prioridad/hora.

### Error con descuentos 100 % (ticket 27034)
- En la tabla `public.ticket_discount` los campos relevantes son `type` (modo de descuento) y `value`. Para descuentos porcentuales (`type = 1`) el `value` se guarda en porcentaje (p.ej. 100 = 100 %), *no* en pesos.
- El reporte consolidado (`SalesExceptionsController`, línea 447) mapea `discount_amount = COALESCE(td.value, 0)` y lo usa textualmente al generar el resumen (`discountSummary`, líneas 565‑584). Esto provoca que un ticket con dos cupones al 100 % reporte “$100 + $100” aunque el descuento real sea el subtotal del ticket.
- Ejemplo real: el ticket 27034 (sub_total 138, total_discount 138) tiene dos filas en `ticket_discount` (`JGM` y `Rector`, ambas `value=100`). El widget de caja muestra el total correcto ($138), pero el “Resumen de descuentos” suma $200 porque interpreta cada `value` como pesos.
- Además, para ese mismo ticket existen dos transacciones (`transactions` 27119/27120) que netean en cero; como `obtenerAnulaciones` no analiza los movimientos, la alerta de “Descuentos 100 %” no explica el contra‑cobro en efectivo.

### Próximos pasos sugeridos
1. **Corregir el cálculo del resumen**: cuando `ticket_discount.type = 1` (porcentaje) hay que multiplicar el porcentaje por la base (sub_total o item.sub_total) para obtener el monto real, en lugar de usar `td.value`.
2. **Separar descuentos múltiples**: devolver cada cupón como registro individual en el widget/modal, incluyendo monto calculado y scope (ticket vs item).
3. **Cruzar con transacciones**: para casos como 27034 (cobros positivos y reversos negativos) convendría adjuntar `payment_total`, `adjustments` y `refund_total` al resultado del widget, o al menos mostrar un badge que indique que el monto fue compensado por un movimiento de caja.

## Estudio de datos (cortes del 5 y 6 de noviembre)

Para validar el “monto alto” detectado en el corte de caja ejecuté una extracción directa desde PostgreSQL (`public.ticket*`) filtrada por fecha.

| Fecha        | Tickets con descuento | Total real (∑ `ticket.total_discount`) | Suma actual del resumen (`ticket_discount.value` + `ticket_item_discount.amount`) | Diferencia |
|--------------|----------------------|----------------------------------------|----------------------------------------------------------------------------------|------------|
| 2025-11-05   | 2                    | $42.00                                  | $42.00                                                                           | $0.00      |
| 2025-11-06   | 5                    | $292.80                                 | $344.80                                                                          | **$52.00** |

Detalles relevantes del 6 de noviembre:

- `ticket 27031` (Rector 100 %): subtotal $110, descuento real $110; el resumen solo suma $100 porque lee `value=100`.
- `ticket 27034` (JGM + Rector, ambos al 100 %): subtotal $138, descuento real $138, pero el resumen agrega $200 (dos entradas con `value=100`).
- Los registros de “40% Colaborador” se calculan correctamente porque `ticket_item_discount` guarda el monto ($6.40, $14.00, etc.).

Conclusión: el exceso en el corte proviene exclusivamente de descuentos porcentuales registrados en `ticket_discount`. Basta con traducir cada `value` a pesos reales antes de agregarlos para que el resumen coincida con el POS y con `ticket.total_discount`.
