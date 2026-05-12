# 📦 MÓDULO: Reportes, Diagnóstico y Dashboards (Analytics)

> **Clasificación:** FRAGMENTADO / INCOMPLETO  
> **Estado:** Operativo (Pero altamente disperso con redundancia de APIs y Jasper)  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** PostgreSQL (Vistas estáticas ad-hoc, funciones de agrupamiento)

---

## 1. Misión Funcional
Digerir, agrupar y visualizar la "verdad contable y operativa" transversal de la empresa cruzando variables de ventas crudas, ticket promedio, costeo promedio ponderado (WAC), fluctuaciones de inventario y mermas teóricas vs reales de caja. Es el módulo auditor y el termómetro general de la salud financiera.

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/reports/sales/*`, `/api/reports/*`, `/api/reports/tickets/*` y conexiones estáticas hacia JasperServer.
- **UI principal:** `App\Livewire\Reports\Dashboard`, `DrillDown`. *(Frontends heterogéneos)*
- **Controller / Service central:** Fragmentación masiva y dedicativa (`SalesSummaryController`, `MenuUsageController`, `SalesDrawerController`, `SalesDiagController`, etc.).
- **Fuente de verdad en PGSQL:** Docenas de vistas dedicadas como `vw_report_sales_detail`, `vw_diag_neto_vs_cobros`, `vw_net_sales`.
- **Dependencia crítica:** **TODA LA BASE DEL ERP** (CAJA, POS_SYNC, RECETAS, PRODUCCIÓN, COMPRAS, INVENTARIO).
- **Pendiente prioritario:** Encapsular la dispersión de Endpoints, unificando bajo Recursos JSON predecibles de Eloquent.

---

## 3. Flujo Funcional
A diferencia de los módulos operativos, Reportes es netamente **Pasivo / Exploratorio**:
`Parámetros (Fecha, Filtros) dictados por Usuario → Endpoints interceptan petición → Invocación cruda a Vistas SQL / Envío a Gateway Jasper → Formateo (Agrupamiento matricial, JSON o PDF) → Render Web.`

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Ventas (Sales Mix & Drawer):** `/api/reports/sales/mix`, `/api/reports/sales/drawer`, `/api/reports/sales/diagnostics`.
- **General KPIs:** `/api/reports/kpis/sucursal`, `/api/reports/ventas/top`.
- **Tickets & Anómalos:** `/api/reports/tickets/open`, `/api/reports/anomalias`.
- **Cruces Analíticos (Inventario/Costos):** `/api/reports/consumo/vr`, `/api/reports/stock/val`.

**Componentes Arquitectónicos Base**
- **Controllers:** Infraestructura atomizada en micro-controladores por reporte (`ReportsController`, `SalesBalanceController`, `SalesJournalController`, etc.).
- **Livewire:** Uso escueto y emergente (`Reports\Dashboard`, `DrillDown`).

## 5. Base de Datos Crítica
- **Mapeo:** La "Inteligencia" radica puramente en `views`.
  - Vistas Analíticas de Ventas: `vw_report_*`.
  - Agrupaciones de Costos Financieros: Consolidaciones de WAC ancladas a `selemti.historial_costos_receta`.

## 6. Contrato de Datos / Reglas Base de Datos
- **Duplicidad de Fuentes Analíticas:** Existen informes paralelos en JasperReports (el sistema legacy de reporteo pesado) y la nueva API JSON de Laravel. Esto provoca ocasionalmente descuadres semánticos (¿Qué reporte tiene la regla "correcta"?).
- **Consultas Raw vs Eloquent:** La mayoría del peso de abstracción se salta a los modelos PHP, invocando directamente `DB::select` o llamadas planas a las vistas, desprendiendo al sistema de los Mutators/Accessors definidos en el código fuente.
- **Agregación de Costos de Variantes (Food Cost):** El reporte de utilidad y Food Cost debe agregar de forma acumulativa el costo de la receta base y el de todos los modificadores aplicados en el ticket para devolver un margen real consolidado. 

## 7. Fuente de Verdad Real
- **Ausencia de un SSOT (Single Source of Truth):** No existe actualmente un pivote canónico consolidado u oficial para métricas clave como ventas netas, descuentos o ingresos reales. Cada vista, sub-query o reporte puede estar utilizando lógicas de agrupación distintas, generando divergencias analíticas letales por diseño.
- **Lógica en PostgreSQL:** Ejerce el monopolio del cálculo. Las agrupaciones matemáticas, cruces lógicos inter-tablas y sumatorias acumulativas (*Rollups*) se definen herméticamente en SQL. La vista es la dueña del reporte.
- **Lógica en Laravel:** Aquí, Laravel actúa fundamentalmente como un simple "mensajero" (Data-passer). Toma los parámetros HTTP y devuelve pasivamente la respuesta masticada por la Base de Datos. No valida, no inyecta reglas duras, solo formatea. 

## 8. Dependencias con Otros Módulos (El Mapeo Transversal)
- **Depende de:**
  - **CAJA:** Requiere `selemti.postcorte` cerrado para amarrar la diferencia del Ticket Promedio y Drawer Final.
  - **INVENTARIO:** Para levantar el valor de merma y el conteo de "Over-tolerance".
  - **RECETAS:** Sin versiones congeladas válidas de recetas, el `SalesMix` asume márgenes financieros ciegos o de utilidad errática (debido a faltas en WAC). El reporte `SalesMix` depende existencialmente de la **Sincronización POS-ERP** (Doc 20) para unir tickets con sus costos teóricos.
  - **PRODUCCIÓN:** Genera fluctuaciones en existencias que desvirtúan el reporte de consumos (Consumos vs Movimientos si las mermas no se declaran).
- **Impacta a:**
  - Estrictamente "Solo Lectura". No altera saldos ni despacha nada que afecte a operaciones subsecuentes. Operativamente inofensivo si falla trágicamente su código, pero letal para las decisiones gerenciales.

## 9. Estado Real Desglosado
- **Nivel de Confianza Documental:** Bajo - La alta atomización dificulta asegurar que una regla fiscal de un reporte no contradiga tácitamente otro similar.
- **Implementado / Operativo:** Creado de forma empírica y reactiva (Reporte por petición), sin núcleo consolidado central.
- **Histórico / Legacy:** Profundamente conectado al Legacy subyacente debido a la fuerte persistencia con el subsistema Jasper.

## 10. Problemas Críticos / Anomalías (BUG-04)
### BUG-04: Origen Fragmentado de Descuentos (Impacto Analítico)
- **Contexto Operativo:** El ecosistema de ventas heredado por Floreant POS *carece de una fuente única confiable para los descuentos.* 
- **La Fractura:** Se pueden registrar descuentos globalmente al ticket (`ticket_discount`), a cada partida (`ticket_item_discount`) o incluso camuflarse en pagos (`transactions`).
- **El Impacto Analítico:** Al no existir un pivote canónico contable, agregar de forma ingenua / acumulativa por SQL las tres tablas dispara los porcentajes de descuento al multiplicar ("doble tear") matemáticamente las sumas. 
- **Consecuencia en Reportes:** El reporte de ingresos difiere inexplicablemente de la auditoría de caja fuerte (Drawer Pull del POS). Este bug detona la desconfianza general en la sección financiera de este módulo contable.
- *(Nota: Revertido exitosamente de la base de datos el "experimento de parche por Vistas" durante FASE 3, pero la divergencia legacy sigue exigiendo diseño estructural)*.

## 11. Riesgos si se Modifica (Vulnerabilidad Analítica)
- **Riesgo de Inconsistencia Simultánea:** El *BUG-04* y todo tipo de falla estructural NUNCA deben intentarse resolver de manera "local" (ej. inyectando un WHERE a un solo endpoint). Hacerlo garantiza que existan dos reportes gerenciales arrojando diferentes cifras monetarias para un mismo periodo, lo cual arruina incuestionablemente el trust (*confianza gerencial*) entre departamentos.
- **Riesgo de Desalineación Temporal:** Pequeñas lagunas no estandarizadas que crucen campos como `create_date`, `closing_date` y el timestamp primario siempre generarán diferencias contables duras al compararse con flujos rígidos (Como Postcorte en CAJA).
- **Parches Puntuales (Falsos Ceros):** Alterar métricas planas o sub-vistas requiere una estrategia holística y general de extracción unificada (ETL o Vista Suprema), so pena de mermar ilusiones de negocio y reportar falsos negativos.

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/CAJA.md` (Referencia forzosa de correlación financiera)
- `docs/2026/05_PENDIENTES_Y_BUGS.md` (Donde BUG-04 vive documentado genéricamente y desprendido de FASE 3)

## 13. Backlog Técnico Prioritario
- [ ] Centralizar la lógica y erradicar la fragmentación de Sub-Controladores para encuadrar un `ReportService` escalable.
- [ ] Definir si Laravel absorberá la lógica `Jasper SQL` legacy para limpiarla, o si permanecerá como Pasador de Datos (Data-passer).

---
## 14. Regla de Intervención Previa
⚠️ **ESTRICTO - ANTES DE MODIFICAR ESTE MÓDULO:**
1. **Entender el Bug de Descuentos:** No realizar enmiendas correctivas matemáticas intentando cuadrar descuadres en las ventas si no se revisa o comprende a profundidad el BUG-04 (Descuento fragmentado de Floreant).
2. **Consultas de Solo Lectura:** A menos que un *snapshot* o *cache* deba refrescarse, ningún reporte debe incurrir jamas en un `UPDATE` pasivo bajo la sabana del framework. Todo aquí pertenece al territorio de los DQL `(SELECT)`.
