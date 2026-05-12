# Taxonomía de Mermas y Pérdidas (AS-IS)
**Vigencia:** Abril 2026

## 1. Definición del Problema
El sistema TerrenaLaravel padece de una "fuga silenciosa" de valor en el inventario debido a la ausencia de una taxonomía de pérdidas estandarizada y obligatoria. Actualmente, la disminución del stock físico ocurre por múltiples vías (consumo POS, desperdicio en producción, conteos físicos erróneos, caducidad), pero estas se registran bajo criterios dispares, lo que contamina el cálculo del **Costo Promedio Ponderado (WAC)** y distorsiona el **Food Cost**. Al no distinguir entre una pérdida inevitable (merma técnica) y una evitable (desperdicio o robo), la gerencia carece de palancas operativas para corregir la rentabilidad.

---

## 2. Qué es merma explícita hoy
Es toda disminución de stock que el usuario o el sistema registra con intención de documentar un desperdicio físico.
- **Origen:** Principalmente el módulo de **Producción** (`ProductionService`).
- **Registro SQL:** Se inserta un movimiento tipo `MERMA` en la tabla `selemti.mov_inv` y un registro detallado en `selemti.inventory_wastes`.
- **Estatus:** Es trazable, tiene un motivo asociado y un responsable (usuario_id). Representa la pérdida "declarada" durante la transformación de insumos a productos terminados.

---

## 3. Qué es merma implícita hoy
Es la pérdida de valor que el sistema **asume** que ocurrió basándose exclusivamente en las ventas.
- **Origen:** Ventas en el POS sincronizadas vía `POS_SYNC`.
- **Registro SQL:** Movimientos tipo `MODIFIER_RECIPE` o deducciones ejecutadas por `fn_confirmar_consumo_ticket`.
- **Riesgo:** Se le llama "implícita" porque no hay validación física. Si la receta dice que un taco lleva 50g de carne, el sistema deduce 50g. Si el cocinero usó 70g o tiró 20g al suelo, esa diferencia queda oculta hasta el siguiente conteo físico.

---

## 4. Diferencia entre Categorías (Estado Real)
Bajo la auditoría del código y el esquema `selemti`, así se comportan hoy:

| Categoría | Registro Técnico | Descripción Real en TerrenaLaravel |
| :--- | :--- | :--- |
| **Merma** | `tipo = 'MERMA'` | Pérdida de insumos durante la producción (ej. recortes de carne). |
| **Desperdicio** | `inventory_wastes` | Subtipo de merma, a menudo registrado como notas o motivos en producción. |
| **Pérdida** | `perdida_log` | Registro forense para eventos catastróficos o irregulares (ej. caducidad). |
| **Ajuste** | `tipo = 'AJUSTE'` | Resultado de un **Inventory Count**. Es la bolsa donde caen todas las mermas no declaradas. |
| **Robo Presunto** | No formalizado | No existe un `tipo` o `clase` obligatorio en el código para esto; se oculta en "Ajustes Negativos". |
| **Consumo Interno** | Manual / Ajuste | Se suele registrar como un ajuste con nota manual, careciendo de un flujo de autorización. |

---

## 5. Cómo impactan estas categorías al Kardex y al WAC
1. **Impacto en Existencias:** Todas las categorías mencionadas (Ajuste, Merma, Consumo POS) disminuyen la cantidad física en el Kardex (`mov_inv`).
2. **Impacto en Costo (WAC):**
   - Los movimientos de **Merma** y **Ajuste** suelen registrarse con `costo_unit = 0` (según `InventoryCountService:223`).
   - **Efecto Crítico:** Al retirar unidades con costo cero, el sistema simplemente reduce el valor total del inventario pero mantiene el último costo promedio. Sin embargo, si un ajuste de entrada se hiciera incorrectamente, podría diluir el costo promedio de forma artificial.
   - **El "Castigo" Financiero:** La pérdida de valor no se "vende", por lo que el costo de lo vendido (COGS) sube proporcionalmente al desperdicio, reflejándose en un Food Cost elevado.

---

## 6. Qué módulos generan o absorben estas pérdidas
- **Módulo de Producción:** Generador primario de Merma Explícita.
- **Módulo de Conteos (Inventory Counts):** El gran "absorbedor". Cualquier error no registrado en el día a día termina manifestándose como una "Variación de Conteo" (Ajuste).
- **Módulo POS_SYNC:** Generador de consumo teórico (Merma Implícita).
- **Módulo de Auditoría (`perdida_log`):** Repositorio forense persistente pero subutilizado por la capa Livewire.

---

## 7. Qué sí clasifica hoy el sistema y qué no
- **SÍ CLASIFICA:**
  - Diferencia entre Producción (`MERMA`) y Conteos (`AJUSTE`).
  - Motivos de variación en líneas de conteo (`inventory_count_lines.motivo`).
- **NO CLASIFICA (Vacíos de Verdad):**
  - No distingue entre merma evitable (negligencia) e inevitable (proceso).
  - No existe un flujo de "Deltas de Receta" (cuando el cocinero acepta que usó más insumo del teóricamente dictado).
  - La tabla `perdida_log` no está conectada a un workflow administrativo de "Baja de Inventario" con firma digital.

---

## 8. Riesgos operativos y financieros
1. **Contaminación del WAC por Ajustes Ciegos:** Realizar ajustes masivos de inventario sin clasificar el motivo impide saber si el costo del platillo es alto por el precio del proveedor o por el robo en cocina.
2. **Invisibilidad del "Desperdicio en Barra":** Los insumos que se dañan o caducan y no se cuentan hasta el fin de mes distorsionan la visión semanal de rentabilidad.
3. **Falta de Responsabilidad en Merma:** Al ser la producción el único lugar que registra `MERMA`, otros puntos de fricción (Almacén Central) quedan impunes ante pérdidas físicas.

---

## 9. Reglas de gobierno actuales
De acuerdo al manual de arquitectura (Sección 5):
1. **Inmutabilidad del Kardex:** Queda estrictamente prohibido "corregir" el stock físico mediante edición directa de la tabla `inventory_batch`. Toda pérdida debe pasar por un movimiento de salida (`MERMA` o `AJUSTE`).
2. **Obligatoriedad de Referencia:** Cualquier movimiento de pérdida en `mov_inv` debe tener un `ref_tipo` y `ref_id` válido apuntando a un Conteo o a una Orden de Producción.
3. **Costo Cero en Salidas:** Las salidas por merma no generan "ingreso" ni recalculan el WAC hacia arriba; se asumen como pérdida patrimonial total.

---

## 10. Delimitación del problema
- El sistema TerrenaLaravel posee las **tablas receptoras** para una excelente taxonomía (especialmente `perdida_log` e `inventory_wastes`).
- El problema no es de almacenamiento de datos, sino de **captura incompleta** en la interfaz de usuario y falta de validación en los Services.
- Esta ficha documenta que, hoy por hoy, el sistema es reactivo: detecta la pérdida cuando el insumo ya no está (Conteo), pero no previene ni clasifica la fuga en el momento que sucede (Operación).
