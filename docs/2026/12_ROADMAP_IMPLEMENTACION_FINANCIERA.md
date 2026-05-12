# Roadmap de Implementación Financiera (2026)
**Vigencia:** Abril 2026

## 1. Objetivo del Roadmap
Este documento define el orden cronológico y lógico de implementación del **Modelo Financiero Canónico** en TerrenaLaravel. Su propósito es guiar la transición desde el estado actual fragmentado hacia un sistema de gobernanza financiera íntegro, sin comprometer la operación diaria del POS ni la estabilidad de la base de datos productiva.

---

## 2. Principios de Implementación
Para garantizar una transición segura, toda intervención debe regirse por:
- **No romper operación en POS:** La prioridad absoluta es que el restaurante pueda seguir transaccionando sin latencias ni bloqueos.
- **No alterar históricos sin control:** Los datos del pasado son evidencia de auditoría; no se deben recalcular ni modificar masivamente.
- **No recalcular datos en PHP:** La lógica financiera pesada debe residir en PostgreSQL para garantizar consistencia entre reportes y dashboards.
- **Autoridad Contable de PostgreSQL:** El motor de base de datos es la fuente de verdad definitiva; Laravel actúa como interfaz de gestión y visualización.

---

## 3. Fases de Implementación

### Fase 1 — Canonización de Ingresos (BAJO RIESGO / ALTO IMPACTO)
**Foco:** Saneamiento de la base monetaria.
- **SSOT de Ingresos:** Forzar el uso de `public.transactions` como la única fuente de verdad para reportes de liquidación.
- **Normalización de Descuentos (% vs $):** Implementar la resolución explícita del valor del descuento antes de cualquier cálculo para corregir la interpretación errónea de cortesías.
- **Desacoplamiento de Descuentos:** Eliminar de los flujos de arqueo la dependencia de `ticket.total_discount`, utilizando en su lugar la composición de `ticket_discount`.
- **Aislamiento del BUG-04:** Implementar un filtro en la consulta de liquidación que identifique cortesías al 100% basándose en el valor relativo del cupón.

### Fase 2 — Clasificación de Inventario
**Foco:** Eliminar la "fuga silenciosa" de valor.
- **Obligatoriedad de Motivos:** Activar el uso de la tabla `selemti.perdida_log` como requisito para guardar cualquier ajuste manual o merma en la UI de Livewire.
- **Separación de Flujos:** Asegurar que los movimientos tipo `MERMA`, `AJUSTE` y `PRODUCCIÓN` sean mutuamente excluyentes y trazables.
- **Preservación del Kardex:** Mantener la inmutabilidad de `inventory_batch`; toda corrección debe ser un nuevo movimiento, nunca una edición de registro.

### Fase 3 — Snapshot de Costos (WAC)
**Foco:** Estabilización de la valoración.
- **Persistencia en el Movimiento:** Modificar el trigger o servicio de salida de inventario para capturar el costo promedio ponderado (WAC) del momento exacto del consumo y guardarlo en una columna dedicada de `mov_inv`.
- **Inmutabilidad Histórica:** Una vez guardado el costo en el movimiento, queda prohibido recalcularlo ante cambios de precios de proveedores futuros.
- **Preparación de Datos:** Establecer la base de datos necesaria para un Food Cost retrospectivo real.

### Fase 4 — Conciliación Caja ↔ Caja Chica
**Foco:** Integridad del flujo de efectivo total.
- **Salida Controlada:** Introducir en el flujo de la Caja Operativa un registro formal de "Transferencia a CashFund" / "Gastos Operativos".
- **Integración al Postcorte:** Modificar el algoritmo de `fn_generar_postcorte` para que reste estas transferencias autorizadas del saldo esperado en gaveta.
- **Eliminación de Faltantes:** Sanear el arqueo físico eliminando los faltantes artificiales causados por la extracción de dinero para Caja Chica.

### Fase 5 — Food Cost Real
**Foco:** La métrica de convergencia final.
- **Migración de Cálculo:** Actualizar los reportes analíticos para que utilicen el **Snapshot de Costo WAC** persistido en la Fase 3.
- **Doble Reporte:** Presentar la comparativa entre **Food Cost Teórico** (Receta perfecta) vs **Food Cost Real** (Recetas + Mermas + Desperdicios).

---

## 4. Dependencias entre Fases
- **Food Cost Real (F5)** depende estrictamente del **Snapshot de Costos (F3)**.
- **Snapshot de Costos (F3)** requiere un **Inventario Clasificado (F2)** para no capturar promedios contaminados.
- **Conciliación de Caja (F4)** depende de tener un **SSOT de Ingresos (F1)** limpio para saber exactamente cuánto dinero debería haber antes de transferir a Caja Chica.

---

## 5. Riesgos por Fase
- **Fase 1 (Bajo):** Posibles discrepancias mínimas con reportes históricos que usaban lógica fragmentada.
- **Fase 2 (Bajo):** Resistencia del personal a clasificar cada merma (Riesgo operativo/humano).
- **Fase 3 (Medio):** Requiere precisión técnica en la captura del WAC al momento de la salida para no degradar el performance.
- **Fase 4 (Medio):** Modificación de la función núcleo `fn_generar_postcorte`.
- **Fase 5 (Bajo):** Principalmente de visualización, una vez que las otras fases han estabilizado la data.

---

## 6. Quick Wins
- **Forzar el campo 'Motivo' en la UI:** Genera data de auditoría hoy mismo sin tocar el motor de base de datos.
- **Cambiar el origen de datos de Jasper a 'transactions':** Sanea la visión de ingresos en días de alto volumen de descuentos.
- **Reporte de 'Mermas por Motivo':** Da visibilidad inmediata a la gerencia sobre dónde se pierde valor.

---

## 7. Qué NO hacer todavía
- **No tocar `fn_generar_postcorte`** hasta que las Fases 1 y 2 estén estables.
- **No migrar estructuras de tablas grandes** ni hacer cambios de esquema (DDL) que requieran downtime.
- **No recalcular históricos de años anteriores;** el modelo canónico nace con un "punto cero" de implementación.

---

## 8. Indicadores de Éxito
- **Conciliación de Caja:** Margen de error menor al 1% entre saldo esperado y contado tras puenteo de CashFund.
- **Variación de Food Cost:** Divergencia menor al 2% entre lo reportado por el sistema y el valor del inventario real.
- **Consistencia:** 100% de los movimientos de merma cuentan con un responsable y un motivo asociado en `perdida_log`.
