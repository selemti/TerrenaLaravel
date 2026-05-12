# 📦 MÓDULO: INVENTARIO Y POS CONSUMPTION

> **Clasificación:** CORE  
> **Estado:** Operativo  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** PostgreSQL

---

## 1. Misión Funcional
Controlar, rebajar y valorizar las existencias físicas y teóricas (Kardex) en tiempo real mediante la intercepción asíncrona de operaciones de venta (POS) y movimientos directos (compras, ajustes, producción).

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/inventory/kardex`, `/inventory/items`
- **UI principal:** `App\Livewire\Inventory\*`, `App\Livewire\InventoryCount\*`
- **Controller / Service central:** `App\Services\Inventory\PosConsumptionService`, `DailyCloseService`
- **Fuente de verdad en PGSQL:** Trigger `trg_ticket_inventory_consumption` y vistas de costeo WAC.
- **Dependencia crítica:** Módulo de Recetas (BOM implosion) y Módulo de Catálogos (UOMs).
- **Pendiente prioritario:** Estabilizar y purgar la lógica legacy del comando de reprocesamiento `PosReprocess`.

---

## 3. Flujo Funcional (Ejemplo Pos Consumption)
Venta confirmada en POS (Floreant) → Intercepción asíncrona (Trigger) → Implosión BOM (Receta) → Conversión de Porción a UOM local → Inserción a kardex (`inv_consumo_pos` / `inv_mov`) → Depreciación de Costos (WAC/Capas). 

`Venta POS → selemti.trg_ticket_inventory_consumption → Extracción de Insumo → inserción Kardex`

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Web:** `/inventory/*`
- **API:** Rest API en `/api/inventory/*`
- **Legacy (API):** Componentes aislados bajo el folder legacy extinto.

**Componentes Arquitectónicos Base**
- **Controllers:** `InventoryController`, `StockController`
- **Services:** `PosConsumptionService`, orquestado a veces por `App\Services\Operations\DailyCloseService`.
- **Livewire:** `App\Livewire\Inventory\*`, `App\Livewire\InventoryCount\*`
- **Models:** `App\Models\Inventory\*`, `App\Models\Inv\*`

## 5. Base de Datos Crítica
- **Tablas:** `public.items` (Legacy items), `selemti.inv_mov`, `selemti.inv_consumo_pos`, `inventory_batch`, `cost_layer`, `historial_costos_item`.
- **Vistas Específicas Activas:** Pendientes de aislar del pool general de vistas híbridas `vw_*`.
- **Vistas Híbridas (Pendientes de Purgar):** Múltiples cruces de reporteo mixto de inventario sobre facturación.
- **Funciones PL/pgSQL:** Evaluaciones de costos como `fn_item_unit_cost_at` o `fn_generar_kardex` (si aplican).
- **Triggers:** El más importante es `selemti.trg_ticket_inventory_consumption` interactuando contra `public.ticket`.

## 6. Contrato de Datos / Reglas Base de Datos
- **Origen de datos:** Operaciones crudas generadas desde `public.ticket` (POS), Recepciones de compra o Ajustes de inventario (Conteos Físicos).
- **Destino de datos:** Tablas de historial de inventario `inv_mov` o `inv_consumo_pos`.
- **Reglas críticas:** El descuento DEBE respetar matemáticamente la unidad de medida originaria (UOM) vs la configurada en receta, aplicando el factor de conversión estricto.
- **Consumo Granular (Explosión de Modificadores):** El rebaje de inventario no se limita al ítem principal; el sistema debe iterar sobre cada modificador seleccionado del POS y descontar los insumos de su sub-receta correspondiente (`REC-MOD-*`).
- **Consumo por Unidad vs. Explosión:** Para semiterminados (ej. Salsa Roja) o productos elaborados (ej. Tortas), el sistema verifica si existe stock del ítem producido. Si hay stock disponible, rebaja la unidad; de lo contrario, procede a la explosión teórica de sus ingredientes en tiempo real. Ver especificación en [Doc 24 - Motor de Consumo](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md).
- **Restricciones importantes:** El Costeo Promedio Ponderado (WAC) o capas solo es válido si la cronología de movimientos respeta estricto orden (imposibilidad de modificar recepciones históricas sin en cascada recalcular).

## 7. Fuente de Verdad Real
- **Lógica en Laravel:** Interfaces Livewire de reporteo temporal, listado de catálogos y comando de Cierre Diario (`DailyCloseService`) ordenando las verificaciones de cuadraturas y orquestación de batching.
- **Lógica en PostgreSQL:** Todo lo relacionado a intercepción, deducción material volumétrica (UOM), y evaluación de consumo vive nativamente en el Motor DB (Triggers). No debe depender del código PHP para subsistir transaccionalmente.

## 8. Dependencias con Otros Módulos
- **Depende de:** Catálogos (Equivalencias UOM) y Recetas (Lógica BOM). Requiere **Alineación POS-ERP** previa (ver [Doc 20](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/20_PROTOCOLO_ALINEACION_POS_ERP.md)).
- **Impacta a:** FASE 3 (Postcorte) indirectamente al validar fechas idénticas; Reportes Financieros y Dashboards. Depende de la exactitud de los ingresos liquidados (ver [Doc 07 - SSOT Ventas](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/07_SSOT_VENTAS_Y_DESCUENTOS.md)) para el cálculo preciso de márgenes y Food Cost real vs teórico.
- **Bloqueos conocidos:** Reprocesamientos de históricos pueden bloquear por scripts rotos (`PosReprocess`).

## 9. Estado Real Desglosado
- **Nivel de Confianza Documental:** Alto (Purgadas dependencias imaginarias de módulos externos). Documentación Externa `D:\Tavo\2025\UX\Inventarios\*` tratada estrictamente como referencia formativa.
- **Implementado:** Activo con integración viva hacia bases legacy.
- **Operativo:** Totalmente orgánico en consumo. Fricciones únicamente en refactorizaciones de costos.
- **Pendiente:** Saneamiento de orquestadores de consumo obsoletos.
- **Histórico / Legacy:** El historial documentado se mantiene, pero ningún documento de diseño 2025 funge como verdad.

## 10. Problemas Conocidos / Bugs
- **Bug:** Fallo en el comando de reprocesamiento histórico.
- **Causa:** El código original acopló repositorios como `App\Services\Pos\` que fueron borrados o fusionados en `Inventory\PosConsumptionService`, corrompiendo la inyección.
- **Impacto:** Si hay que regenerar movimientos del mes anterior, el script revienta en CLI.
- **Estado:** Identificado y aislado.

## 11. Riesgos si se Modifica
Entorpecer o mutar el trigger `trg_ticket_inventory_consumption` corrompe invisiblemente todo el Kardex, ya que el sistema POS continuará facturando pero la base de Laravel pasará a ceguera logística (generando costos cero, mermas falsas y compras innecesarias).

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
- `docs/2026/20_PROTOCOLO_ALINEACION_POS_ERP.md`
- `AI_COORDINATION/STATUS.md`

**Externa / Histórica (Referencia Obsoleta):**
- Carpetas `D:\Tavo\2025\UX\Inventarios\*` (Excel Dictionaries y actas). 

## 13. Backlog Técnico Prioritario
- [ ] Rehabilitar o extirpar permanentemente el código muerto relacionado a Reprocesos de Inventario POS huérfanos.
- [ ] Mapear íntegramente las Vistas Específicas Activas (WAC/Capas).
- [ ] Validar integridad algorítmica y aislar el módulo transversal de recetas, ya que si estalla UOM, también lo hará éste componente.

---
## 14. Regla de Intervención Previa
⚠️ **ESTRICTO - ANTES DE MODIFICAR ESTE MÓDULO:**
1. **Verificar PostgreSQL Primero:** Revisar profundamente el trigger base `trg_ticket_inventory_consumption` y la estructura de `inv_consumo_pos` antes de alterar lógicas del Service en Laravel.
2. **Pre-Validación en Staging:** Alteraciones con cruce UOM obligatoriamente requieren simulación local en BD clónica (no asumir conversiones de UI).
3. **Restricción de Producción:** Cualquier visualización de Kardex fallido debe realizarse por medio de query plana e inofensiva (`SELECT * FROM selemti...`) antes de proponer código o manipular Livewire en PRD.
