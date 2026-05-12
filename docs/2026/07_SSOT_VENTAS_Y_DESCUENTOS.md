# SSOT Ventas y Descuentos (Single Source of Truth)
**Vigencia:** Abril 2026

## 1. Definición del Problema
El sistema TerrenaLaravel carece de una fuente única consolidada (Single Source of Truth) para la extracción y totalización de los descuentos aplicados en tienda. La arquitectura hereda la fragmentación nativa generada por el sistema Floreant POS, el cual distribuye la métrica de deducciones monetarias en distintas tablas desconectadas estructuralmente dentro del esquema `public`.

Esta multiplicidad de orígenes detona una incapacidad crónica para determinar unívocamente el "Total Neto" transaccional del negocio. En el terreno contable, el impacto repercute en:
- **Caja (Postcorte):** Los cierres de turno no logran cuadrar aritméticamente el efectivo recolectado debido a la ambigüedad en el descuento reportado contra el ingresado.
- **Reportes:** La analítica gerencial (Dashboards, Jasper) arroja márgenes distorsionados dependiendo de la tabla desde la cual ejecute el *Query*.
- **Food Cost (Recetas/Kardex):** Dificulta el cálculo de rentabilidad del platillo (*Sales Mix*) al desconocer el precio real de venta final. El nuevo [Motor de Consumo (Doc 24)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md) utiliza esta base financiera para proyectar márgenes precisos sobre el consumo material.

---

## 2. Mapa de Origen de Datos (Evidencia SQL)
Existen tres fuentes fácticas simultáneas y superpuestas en el esquema `public`:

### 2.1 public.ticket
- **Campo relevante:** `total_discount`, `discount_amount` (según sub-esquemas).
- **Representación:** Conserva a nivel cabecera el monto dictaminado como "descuento global" asignado a la cuenta general de una mesa.
- **Limitaciones:** Carece de granularidad. Ignora qué artículos específicos padecieron la rebaja, imposibilitando un análisis de coste por platillo.

### 2.2 public.ticket_item
- **Campo relevante:** `discount_rate`, `discount_amount` u operadores equivalentes de línea.
- **Representación:** Guarda explícitamente el porcentaje o reducción monetaria aplicada ítem por ítem.
- **Limitaciones:** Vulnerabilidad a **doble conteo**. Si un auditor suma los montos de `ticket_item` y luego inspecciona libremente `public.ticket`, podría inflar y falsear el descuento si Floreant arrastró o duplicó valores entre ambas identidades.

### 2.3 public.transactions
- **Campo relevante:** `amount` / Monto final cobrado.
- **Representación:** Es el flujo monetario puro (Gateway/Cash). Determina la verdad de liquidez ("Cuánto dinero en valor físico/digital entró a la caja por esta cuenta").
- **Limitaciones:** No desglosa "qué precio tenía / por qué se rebajó". Solamente escupe el residuo neto liquidado. Si hubo cortesías del 100%, la transacción simplemente no asoma rastro financiero en ingresos, tapando la matemática de los reportes brutos.

### 2.4 public.ticket_discount y public.coupon_and_discount
- **Campo relevante:** `value`
- **Representación:** Conserva el factor numérico del descuento o cupón utilizado vinculado al ticket.
- **Limitaciones (BUG CRÍTICO):** Almacena **porcentajes nominales** (ej. `100` para indicar un descuento del 100% o Cortesía total). Capas superiores o consultas mal formuladas habitualmente leen la columna e interpretan ciegamente que el descuento equivale a `$100.00` líquidos absolutos (moneda), en vez de aplicar el porcentaje al total bruto, lo cual falsea catastróficamente todo reporte monetario.

---

## 3. Flujo Real de Datos (POS → ERP)
La información ingresa a TerrenaLaravel mediante el módulo de integración **POS_SYNC**.
- **Ingreso (Floreant):** Floreant POS retiene la información partida al cerrar una cuenta en el front-end.
- **Sincronización:** `POS_SYNC` importa estos latidos asincrónicamente mediante conectores de *jobs/cron*.
- **Pérdida de Granularidad:** En el tránsito operativo, la justificación causal ("¿Fue promoción programada o cancelación discrecional?") suele evaporarse. El ERP comúnmente absorbe el diferencial bruto pero pierde metadato contextual.
- **Punto de Consolidación Fallido:** El intento urgente por definir estas métricas se pospone resolviéndose al aire durante la consulta en vistas de Reportes o Postcorte, perpetuando el problema. Al no contar con una tabla central (`ETL local`), la verdad sigue fracturada.

---

## 4. Estado Actual del Sistema (AS-IS)
Al ejecutar auditoría cruzada contra `fn_generar_postcorte`, reportes visuales y controladores:
- **Ventas Brutas:** Calculadas mayormente agrupando `ticket.subtotal` o la suma rígida del precio original en `ticket_item`.
- **Ventas Netas:** Frecuentemente recuperadas consolidando la matriz final de `public.transactions` para extraer el total liquidado indudable. Sin embargo, algunos fragmentos de código infieren deduciéndole a `Venta Bruta` las cifras dudosas del BUG-04.
- **Descuentos:** Totalmente incierto. Diferentes scripts legacy y vistas de postcorte asumen criterios discrecionales y opuestos.
- **Lugar de Ejecución:** Persiste una hibridación severa: agregaciones absolutas rigen desde PostgreSQL (`fn_generar_postcorte`), mientras analíticas superficiales realizan el cruce usando *arrays/ForEach* en capa PHP de Laravel, contraviniendo el performance y arriesgándose a fallos lógicos.

---

## 5. Riesgos Operativos Detectados
1. **Doble Conteo de Descuentos:** Sumatorias analíticas que combinan torpemente `ticket.total_discount` junto con los montos de `ticket_item`, hundiendo falsamente la percepción de ingresos de la jornada.
2. **Subestimación Financiera y Fiscal (Sobreprecio falso):** Ignorar descuentos a nivel sub-item repercute en reportar ventas brutas engañosas mucho más altas de las cobradas.
3. **Inconsistencia Inter-Módulos:** Un Dashboard Livewire de Inteligencia de Negocio mostrará cifras disonantes contra lo que imprime matemáticamente la hoja tabular de cierres y postcortes.
4. **Dependencia de Timestamps:** `POS_SYNC` somete la integración; sincronizaciones que arrastran tickets al filo de las 23:59 hr hacia el turno operativo o Postcorte de la madrugada siguiente disuelven el cierre limpio.
5. **Opacidad de Trazabilidad:** Sin certidumbre documentada de descuentos, es imposible fiscalizar en firme mermas excesivas causadas por abusos promocionales de supervisores en áreas específicas del restaurante.
6. **El Falso Monto en Cortesías (Descuentos al 100%):** Al leer tablas satélite como `ticket_discount`, el valor porcentual `100` es interpretado erróneamente por Laravel como moneda. Un ticket de $5,000 condonado al 100%, termina impactando los reportes como un falso descuento de apenas $100.00 MXN, destruyendo totalmente la matemática de la conciliación del Postcorte.

---

## 6. Definición de Fuente de Verdad ACTUAL (No Ideal)
Revisado minuciosamente el proceder de la operación transaccional:
- **Referencia Operativa de Liquidación:** La tabla relacional `public.transactions` es la **fuente de verdad operativa actual para la liquidación monetaria neta**. Cualquier divagación en tickets, cortesías de ítem o descuentos vacíos debe ceder ante el monto económico de liquidación para efectos de arqueo.
- **Limitación Analítica Crítica:** `public.transactions` **NO es la fuente de verdad completa para descuentos analíticos**. Al desglosar únicamente el valor liquidado final, no resuelve por sí sola las métricas de marketing, promociones, mix de descuentos o margen cedido por ítem.
- **Solución Real Operativa:** Sirve estrictamente para Caja y Postcorte como regente del dinero que ingresa a bóveda. Para análisis comerciales detallados, se requiere la coexistencia (aún fragmentada) de las tablas satélite, asumiendo el riesgo de inconsistencia documentado.

---

## 7. Anti-Patrones Detectados
1. **Conjeturas Deductivas en Modelo PHP:** Existencia de operaciones controladoras inyectando resta lineal de descuentos (`$subtotal - $descuento`) en arreglos temporales aislando a PostgreSQL.
2. **Consultas a Columnas Fantasma:** Esfuerzos heredados desde Sprints IA de re-factorización pasados de v4.1 que intentaban cuadrar y apuntar lógicas de cálculo a pseudo-columnas que habitan inconclusas dentro de las colecciones operativas.
3. **Producto Cartesiano Irregular (Multiplicidad de JOIN):** Queries en vistas antiguas que aplican uniones llanas entre `public.ticket` y `public.ticket_item`, generando sumatorias monstruosas en los grupos de descuentos (`SUM()`) a causa de la repetición incontrolada de datos sobre filas agrupadas. 

---

## 8. Reglas de Gobierno (Modeladas y Alineadas al 2026)
De conformidad y respeto a las Reglas dictaminadas del ERP (Sección 5):
- **Centralidad Matemática Postgres:** Toda métrica consolidatoria para definir Cifra Bruta, Merma Neta o Efectivo Final, pertenece nativamente a *Vistas, Procedimientos y Funciones Materializadas del DB Engine*. 
- **Orquestación Limpia en Capa Superior:** Queda estrictamente negado hacer proyecciones en rutinas complejas locales dentro de Controllers, limitando a Laravel a modelar los resultados emanados del SQL.
- **Conjeturas Proscritas:** Prohibición terminante de inventar lógicas compensatorias asuncionales intentando reconstruir descuentos que Floreant olvidó sellar. Ante la carencia documentada, la realidad del monto recabado determina el fin financiero.

---

## 9. Delimitación del Problema (Limitantes Fuera de Alcance)
Esta ficha sella formalmente el escenario de fragmentación transaccional, advirtiendo explícitamente barreras técnicas inquebrantables.
- **Qué Sí Sabemos Fáctica y Técnicamente:** Comprendemos con fiabilidad estricta los volúmenes transaccionales depositados y la causa subyacente que distorsiona métricamente las capas administrativas dentro del ERP.
- **Lo que NO puede resolverse ni determinarse desde acá:** No podemos inferir ni dictar desde Laravel qué perfil administrativo de piso (ej. Mesero) o bajo qué marco comercial preciso decidió en primera instancia asignar el descuento dentro del Front End del POS y si este impactó cruzadamente ítems particulares, perdiéndose el matiz antes de inyectarse.
- **Frontera Táctica de Floreant:** Las rutinas de *commit* de *Java/C* arraigadas dentro del TPV Floreant son soberanas sobre el esquema `public`. Alterar caprichosamente sus inyecciones DML y rutinas destructivas arriesgaría corromper el motor de piso del restaurante en caliente, por ende ese *software-core* se asume temporalmente como un monolito inmodificable, debiendo resolver el problema estrictamente dentro de los flujos receptores de TerrenaLaravel.
