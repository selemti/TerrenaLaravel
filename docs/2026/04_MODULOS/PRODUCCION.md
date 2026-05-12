# 📦 MÓDULO: Producción Interna (Production / OP)

> **Clasificación:** SOPORTE  
> **Estado:** Operativo / Implementado  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** Mixta (Laravel orquesta el flujo, PostgreSQL ejecuta la partida doble del kardex)

---

## 1. Misión Funcional
Fabricar productos semiterminados o elaborados dentro de la planta a partir de la transformación de insumos crudos mediante Órdenes de Producción (OP), rebajando el inventario de materias primas y aumentando equitativamente las existencias del producto resultante procesado.

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/production/*` (Web UI), `/api/production/batch/*` (Lógica CORE)
- **UI principal:** `App\Livewire\Production\OrdersIndex`, `OrderCreate`, `OrderDetail`, `OrderCapture`
- **Controller / Service central:** `ProductionController` / `ProductionService`
- **Fuente de verdad en PGSQL:** Tablas `selemti.op_cab` y `selemti.op_insumo`
- **Dependencia crítica:** RECETAS (Extrae el árbol BOM) e INVENTARIOS (Afecta el Kardex)
- **Pendiente prioritario:** Pruebas unitarias para `ProductionService`.

---

## 3. Flujo Funcional
El diseño actual abarca un **doble flujo** de operaciones, con un modelo ideal (teórico) y un modelo ajustado (captura real operativa):
`BOM Consultado (RECETAS) → Order Planned (Planificación) → Consumo Físico → OrderCapture (Ajuste Teórico vs Realizado) → Completed → Post a Kardex (Entradas/Salidas)`

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Web:** 
  - `/production`
  - `/production/create`
  - `/production/{orderId}`
  - `/production/{orderId}/capture`
- **API (Bloque Batch):** 
  - `/api/production/batch/plan`
  - `/api/production/batch/{batch_id}/consume`
  - `/api/production/batch/{batch_id}/complete`
  - `/api/production/batch/{batch_id}/post`
- **Legacy:** Hay presencia mínima de redirecciones (`/produccion`).

**Componentes Arquitectónicos Base**
- **Controllers:** `App\Http\Controllers\Production\ProductionController`
- **Services:** `App\Services\Production\ProductionService`
- **Livewire:** Interfaz fluida en `Livewire\Production\*`
- **Models:** `ProductionOrder` (y vestigios en `Rec\OrdenProduccion`)

## 5. Base de Datos Crítica
- **Tablas:** `selemti.op_cab` (Órdenes), `selemti.op_insumo` (Líneas de insumos a ingerir).
- **Triggers derivados:** Las operaciones posteadas disparan o simulan transacciones puras bajo el tag o type `produccion` en el Diario de Kardex.

## 6. Contrato de Datos / Reglas Base de Datos
- **Origen de datos:** Depende existencialmente de `v_ingenieria_menu_completa` o sus equivalentes en el módulo de RECETAS para obtener la receta base de qué y cuánto pedir.
- **Destino de datos:** Tabla de Movimientos del Inventario (Afectación física final).
- **Reglas críticas:** 
  - **Doble Impacto de Kardex:** Una misma Orden de Producción crea transacciones ambidiestras: Salidas (OUT) para los insumos base y Entradas (IN) para el sub-terminado resultante.
  - El sistema detecta y asimila Mermas a partir de la varianza entre Consumo Teórico y Consumo Real capturado.
  - **Consumo en Negativo:** Dependiendo de la política configurada, el sistema puede bloquear operaciones por falta de stock u operar temporalmente consumos en negativo (riesgo silencioso controlado) para no detener la planta.
  - **Explosión Jerárquica:** Al producir o vender ítems con modificadores, el sistema explota tanto la receta base como las sub-recetas de modificadores (`REC-MOD-*`) de forma acumulativa.
  - **Generación de Stock de Terminadores:** Las Órdenes de Producción pueden generar ítems con stock propio (ej. Tortas, Salsas en Lote) que son aptos para ser transferidos entre sucursales (`TRANSFERENCIAS`) como una unidad terminada, no como insumos. Esto habilita el consumo directo omitiendo la explosión de recetas (ver [Doc 24](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md)).

## 7. Fuente de Verdad Real (Mixta)
- **Lógica en Laravel:** Domina de forma autoritaria la orquestación. Laravel mapea las fases intermitentes de la Orden (Draft, Planned, Consumed, Completed, Posted) y aloja el motor de "Order Capture" donde el humano dicta el gramaje real utilizado saltándose el ideal de la receta.
- **Lógica en PostgreSQL:** La base de datos es la ejecutora soberana de la partida doble y la persistencia del impacto en Kardex. El valor contable resultante vive estricta y verdaderamente aquí.

## 8. Dependencias con Otros Módulos
- **Depende de:**
  - **RECETAS:** Sin recetas válidas no hay Bill of Materials (BOM) base para detonar la OP. Requiere **Sincronización POS-RECIPE** previa para asegurar que el producto terminado coincida con el ítem de venta.
  - **UOM (Master Data):** Indispensable para transmutar kilogramos solicitados por la receta vs sacos o galones almacenados.
  - **INVENTARIO:** Valida la disponibilidad empírica/teórica antes de un consumo real.
- **Impacta a:**
  - **INVENTARIO:** Directa e incondicionalmente al afectar las existencias en partida doble.
  - **COSTEO (WAC):** Alimenta indirectamente el costo del inventario re-valorizándolo al inyectar existencias ajustadas con mermas operativas.
  - **POS (Floreant):** Impacta indirectamente el consumo en terminales, ya que la producción habilita o niega la disponibilidad de productos de venta final.

## 9. Estado Real Desglosado
- **Nivel de Confianza Documental:** Alto - El escrutinio de los Controladores Livewire confirman su arquitectura unificada.
- **Implementado:** Sí. Funcionalidad reciente de Livewire (Fase 2).
- **Operativo:** Totalmente activo bajo el esquema API/Livewire.
- **Histórico / Legacy:** El viejo modelo `Rec\OrdenProduccion` coexiste como deuda técnica secundaria frente a implementaciones directas de `ProductionOrder`.

## 10. Problemas Conocidos / Bugs
- **Bug:** Desdoblamiento de Modelo Base.
- **Causa:** `app\Models\Rec\OrdenProduccion.php` convive arquitectónicamente con `app\Models\ProductionOrder.php` en la carpeta raíz.
- **Impacto:** Bajo. Fragmentación semántica que dificulta extensiones orgánicas.
- **Estado:** Identificado, pendiente de erradicación mediante deuda técnica.

## 11. Riesgos si se Modifica
**Partida Doble Inestable:** La inyección dual en el módulo de Inventario es matemáticamente frágil si se mutan los servicios API (`ProductionService->post()`). Una falla al "Postear" podría rebajar insumos pero NO sumar el producto terminado (o viceversa), licuando y evaporando costo contable del sistema.

**Desviaciones de Costos Financieros (WAC):** El costo real de producción puede diferir ampliamente del costo dictado teóricamente en RECETAS debido a las mermas o ajustes crudos introducidos en el OrderCapture. Esto genera variaciones permanentes en el cálculo WAC (Costo Promedio Ponderado) de los productos almacenados. Un error de código aquí pudre la base de costeo de casi todas las futuras recetas y procesos de venta asociados, enmascarando pérdidas masivas en el módulo de Reportes.

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
- `docs/2026/04_MODULOS/RECETAS.md`
- `docs/2026/04_MODULOS/INVENTARIO.md` (Referencia central vigente)
- `AI_COORDINATION/STATUS.md`

## 13. Backlog Técnico Prioritario
- [ ] Dotar de Tests Unitarios urgentes a `ProductionService` (Módulo completamente ciego a testing según previas auditorías).
- [ ] Eliminar `app\Models\Rec\OrdenProduccion.php` favoreciendo a un único `app\Models\Production\Order.php` (namespaces unificados).

---
## 14. Regla de Intervención Previa
⚠️ **ESTRICTO - ANTES DE MODIFICAR ESTE MÓDULO:**
1. **Pre-Validación en Staging:** La captura teórica vs la captura real debe ensayarse hasta el final del flujo (`POST`), certificando a nivel Base de Datos (Kardex) que el valor inyectado concilia su partida doble equivalente al costeo mermado.
2. **Dependencia UOM/Recipes:** Cualquier reestructura de Producción debe someterse a ensayo con recetas que incluyan conversiones UOM asimétricas extremas para revelar quiebres de factor matemático.
