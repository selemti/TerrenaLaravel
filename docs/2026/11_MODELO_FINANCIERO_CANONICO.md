# Modelo Financiero Canónico (TO-BE)
**Vigencia:** Abril 2026

## 1. Principios Financieros del Sistema
Para que TerrenaLaravel sea una herramienta de decisión confiable, su arquitectura financiera debe regirse por tres principios innegociables:
- **Causalidad Económica:** Todo movimiento de dinero real debe tener un reflejo contable inmediato. No se permiten "faltantes invisibles" por falta de puentes entre módulos.
- **Trazabilidad de Valor:** El inventario no es solo stock, es dinero detenido. Su salida debe clasificarse siempre por motivo (Venta, Merma, Ajuste) para no contaminar el Food Cost.
- **Dicotomía de Costo:** Separación estricta entre **Costo de Reposición** (decisiones futuras) y **Costo Histórico** (cierre de rentabilidad).

---

## 2. Definición de Fuentes de Verdad (SSOT por Dominio)
Para eliminar la fragmentación actual, el sistema debe reconocer una única fuente de verdad por proceso:

| Dominio | Fuente de Verdad Canónica (TO-BE) | Función |
| :--- | :--- | :--- |
| **Ventas Netas** | `public.transactions` | Única referencia para liquidación monetaria e ingresos reales. |
| **Descuentos** | `public.ticket_discount` (canonizado) | Fuente analítica para marketing, validando el `%` vs `$`. |
| **Efectivo** | `Conciliación Caja vs Caja Chica` | El balance final debe ser la suma neta de ambos flujos. |
| **Inventario** | `Snapshot persistido` | **Evento** derivado del `mov_inv` con el costo WAC capturado en el momento de la salida. |
| **Costos** | **WAC (Costo Promedio Ponderado)** | Valor obtenido de la historia de compras, no del catálogo de precios. |

---

## 3. Modelo Correcto de Food Cost
El Food Cost dejará de ser una métrica "viva" y pasará a ser una métrica "sentenciada":
1. **Valoración por WAC:** El costo de los ingredientes consumidos se calculará basándose en el costo promedio de las unidades que **salieron físicamente** del lote, no en el precio actual del proveedor.
2. **Snapshot de Costo:** Al confirmar un consumo POS, el sistema debe capturar el costo promedio del insumo en ese instante preciso y persistirlo. Esto evita que cambios de precio futuros alteren rentabilidades pasadas.
3. **Fórmula:** `(Consumo Teórico Valorizado al WAC / Ingreso Líquido de Transactions) * 100`.

---

## 4. Modelo Correcto de Conciliación de Caja
El flujo de efectivo debe integrarse mediante un "Puente de Transferencia":
- **Transferencia Caja -> Caja Chica:** El gasto de *CashFund* debe registrarse como un movimiento de salida autorizado en la Caja Operativa que genera una entrada automática en la Caja Chica.
- **Eliminación de Faltantes Fantasma:** El Postcorte debe incluir una línea de "Gastos Operativos Autorizados" extraídos de la gaveta, conciliando el dinero trazado con el dinero físico sin maquillajes manuales.

---

## 5. Modelo Correcto de Pérdidas (Mermas)
Se implementará un flujo de clasificación obligatoria:
- **Captura al Vuelo:** Toda salida de inventario que no sea venta (tipo `MERMA` o `AJUSTE`) debe exigir un motivo de la tabla `perdida_log`.
- **Visibilidad del desperdicio:** El Food Cost se reportará en dos niveles: 
  - **Teórico:** (Receta / Ventas)
  - **Real:** ((Receta + Merma Declarada) / Ventas)
- Esto permitirá identificar si el margen se pierde por mala receta o por mal manejo físico.

---

## 6. Reglas de Integración entre Módulos
1. **POS_SYNC -> Inventario:** La explosión de recetas debe invocar el costo histórico persistido, no recalcularlo en cada ejecución de reporte.
2. **Caja Chica -> Postcorte:** El cierre de caja chica debe alimentar el estado financiero global del día para permitir una visión consolidada del efectivo.
3. **Producción -> WAC:** Las órdenes de producción completadas deben alimentar el Kardex con costos de insumos agregados, refinando el valor de los productos terminados.

---

## 7. Qué se debe DEJAR de hacer (Anti-patrones a erradicar)
- **NO** usar `ticket.total_discount` como cifra de liquidación.
- **NO** usar `item_vendor_prices` para medir rentabilidad de días pasados.
- **NO** hacer ajustes de inventario "en masa" sin asociar un motivo de `perdida_log`.
- **NO** ignorar el flujo de `CashFund` en el algoritmo del Postcorte.

---

## 8. Nivel de Impacto
- **Lógica de Negocio (Medio):** Requiere ajustar las funciones SQL de costeo y los servicios de liquidación en Laravel.
- **Base de Datos (Bajo):** No requiere cambios masivos de esquema, sino el aprovechamiento de tablas existentes (`perdida_log`, `transactions`).
- **Interfaz de Usuario (Bajo):** Requiere añadir campos de "Motivo" en ajustes y un reporte consolidado de cajas.

---

## 9. Estrategia de Transición (Mínimo Viable)
1. **Canonización de Datos:** Establecer por decreto técnico que `transactions` manda sobre `ticket`.
2. **Snapshot de WAC:** Implementar una tabla de históricos de costos para que el Food Cost sea inmutable tras el cierre.
3. **Puente Operativo:** Crear el registro de "Salida a Caja Chica" dentro del flujo de la Caja Operativa para sanear el arqueo físico.
4. **Cultura de Clasificación:** Activar la obligatoriedad de motivos en cada ajuste de inventario para alimentar la taxonomía de pérdidas.

---

## 10. Conclusión
El modelo canónico no busca un ERP nuevo, busca la **integridad del dato** mediante el puenteo de los silos financieros actuales. Al alinear el WAC con el Food Cost y la Caja Operativa con la Caja Chica, el sistema dejará de ser una calculadora de tickets para convertirse en un sistema de gobernanza financiera real.
