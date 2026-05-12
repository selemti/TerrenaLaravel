# Modelo de Food Cost y Conciliación (AS-IS)
**Vigencia:** Abril 2026

## 1. Definición del Food Cost en el sistema
En TerrenaLaravel, el **Food Cost** (Costo de Alimentos) es el indicador de convergencia final donde se encuentran los ingresos declarados en el POS y el consumo de insumos en cocina. El sistema lo define como la relación porcentual entre el costo los ingredientes teóricamente utilizados y los ingresos netos percibidos. 

---

## 2. Componentes que lo construyen
El cálculo descansa en tres pilares de datos que operan de forma asíncrona:
- **Ventas Netas (Denominador):** El total de dinero ingresado tras aplicar descuentos, proveniente de `public.transactions` o `vw_dashboard_ventas_productos`.
- **Consumo Teórico (Numerador):** La explosión de la receta (BOM) multiplicada por el volumen vendido, resuelta mediante la vista `selemti.v_ingenieria_menu_completa`.
- **Costo de Insumos:** El valor monetario de cada gramo o mililitro, determinado por la función `selemti.fn_item_unit_cost_at`.

---

## 3. Flujo real de cálculo
1. **Sincronización:** `POS_SYNC` importa los tickets cerrados.
2. **Explosión de Receta:** El sistema toma cada ítem vendido y busca su equivalencia en ingredientes (`recipe_version_items`).
3. **Valoración Financiera:** El sistema asigna un costo a cada ingrediente. **Hallazgo Crítico:** La función rectora `fn_item_unit_cost_at` consulta directamente la tabla `selemti.item_vendor_prices`.
4. **Acumulación:** Se suma el costo total de todos los ingredientes vendidos en el periodo y se divide entre la venta neta acumulada.

---

## 4. Puntos de Contaminación (Por qué no es confiable)
El Food Cost actual es altamente volátil debido a cuatro "fugas" de precisión:
1. **Confusión entre Reposición y Realidad (Vendor vs WAC):** El sistema comete un error de concepto al mezclar dos tipos de costo:
   - **Costo de Reposición (Vendor Price):** Es el precio futuro/actual del proveedor. Sirve para **Pricing**, negociación y forecast.
   - **Costo Histórico Real (WAC):** Es el costo promedio ponderado de lo que realmente se compró y está en el almacén. Sirve para medir **Rentabilidad real**.
   - **Falla Actual:** El sistema usa el *Costo de Reposición* para medir la rentabilidad histórica. Si el precio de la carne sube hoy, el reporte de ayer podría recalcularse falsamente al alza, contaminando los KPIs de cierre.
2. **Contaminación por Descuentos (BUG-04):** Si el reporte utiliza `ticket.total_discount` o lógicas PHP para netear la venta en lugar de la liquidación real de `transactions`, el denominador (Ventas) es falso, disparando erróneamente el porcentaje de costo.
3. **La Malla de Recetas Outdated:** Las recetas en `selemti.recipe_versions` no siempre reflejan las porciones reales servidas o los cambios de insumos hechos en cocina por falta de stock.
4. **Ajustes de Inventario:** Las pérdidas físicas (robos, desperdicio, caducidad) no entran en este cálculo. El reporte solo cuenta lo que "debió haberse gastado", no lo que "realmente se gastó".

---

## 5. Qué sí es confiable hoy
- **La Estructura de Explosión (BOM):** La jerarquía de ingredientes y sub-recetas es matemáticamente robusta a nivel de base de datos.
- **La Trazabilidad Transaccional:** El sistema sabe exactamente cuántos platillos se vendieron y en qué momento.
- **El Cálculo de Mano de Obra y Overhead:** Aunque a menudo se excluyen del Food Cost "puro", `RecipeCostingService` ya tiene la capacidad analítica para incluirlos.

---

## 6. Qué NO es confiable
- **El Porcentaje Final:** Es una métrica "teórica optimista". No representa la rentabilidad real del negocio porque ignora la merma operativa y los ajustes por conteo.
- **El Costeo Histórico:** Al depender de `item_vendor_prices` sin un snapshot de costo al momento del movimiento, el Food Cost es un dato vivo y mudable, no una foto contable estática.

---

## 7. Riesgos financieros
- **Margen de Utilidad Ficticio:** Reportar un Food Cost del 30% cuando en realidad (por mermas y ajustes) es del 38%, ocultando una pérdida neta de rentabilidad que puede llevar a la quiebra silenciosa.
- **Toma de decisiones con data sucia:** Ajustar precios de carta basándose en el costo de proveedor sin considerar que el verdadero problema es la ineficiencia en producción o el desgobierno de porciones.

---

## 8. Relación con Reportes actuales
- **Dashboards:** Algunos Dashboards en Laravel muestran un "Margen de Contribución" que puede diferir de los reportes PDF de Jasper si aplican criterios de descarte de mermas distintos.
- **Jasper Reports:** Tradicionalmente se han basado en las funciones nativas SQL, heredando el sesgo de "Costo de Proveedor" por sobre "Costo Real de Inventario".

---

## 9. Reglas de gobierno actuales
- **Prohibición de Sobreescritura:** No se deben alterar los costos de proveedor para "ajustar" el reporte a mano.
- **Centralidad de SQL:** El cálculo del Food Cost pertenece a la capa de PostgreSQL. Cualquier intento de calcularlo en Blade o Controllers mediante `Iteradores` queda proscrito por las reglas de arquitectura actuales.

---

## 10. Delimitación del problema
Esta ficha documenta el "Estado de Ilusión" del Food Cost actual:
- El sistema es excelente para decirnos cuánto **debería costarnos** operar si todo el mundo siguiera la receta y los proveedores no variaran precios.
- El sistema es incapaz hoy mismo de decirnos cuánto **nos costó realmente** el plato servido ayer debido al desacoplamiento entre las compras reales, el WAC del inventario y el neteo líquido de las ventas.
