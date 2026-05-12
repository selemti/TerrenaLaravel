# 📦 MÓDULO: Compras y Abastecimiento (Purchasing / Replenishment)

> **Clasificación:** SOPORTE  
> **Estado:** Operativo / Implementado  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** Mixta (Lógica de Replenishment en PostgreSQL, Flujo de Órdenes en Laravel)

---

## 1. Misión Funcional
Garantizar la disponibilidad del inventario analizando el histórico de consumos frente a máximos y mínimos (Replenishment), derivando dichas sugerencias en Órdenes de Compra formales (Purchasing) que finalmente se materializan como entradas físicas al inventario (Recepciones).

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/purchasing/replenishment`, `/purchasing/orders`, `/api/purchasing/receptions/*`
- **UI principal:** `App\Livewire\Replenishment\Dashboard`, `App\Livewire\Purchasing\Orders\*`
- **Controller / Service central:** `ReplenishmentController`, `ReceivingController` / `ReplenishmentService`, `PurchasingService`
- **Fuente de verdad en PGSQL:** Vistas algorítmicas `vw_replenishment`, `vw_replenishment_dashboard` y tablas `recepcion_cab`, `purchase_orders`
- **Dependencia crítica:** Inventario (Kardex de consumo) y Master Data (Catálogo de Artículos y UOM)
- **Pendiente prioritario:** Purgar duplicidad técnica entre `ReceivingService` vs `ReceptionService`.

---

## 3. Flujo Funcional
El flujo abarca desde la gestación de la necesidad hasta el alta en el almacén:
`Dashboard de Sugeridos (vw_replenishment) → Evaluación de Demanda → Conversión a Purchase Order (PO) / Purchase Request → Recepción Física de Mercancía → Post a Kardex en Firme (Afectación de Inventario)`

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Web:** 
  - `/purchasing/replenishment`
  - `/purchasing/requests/*`
  - `/purchasing/orders/*`
- **API:** 
  - `/api/purchasing/replenishment/suggestions/*`
  - `/api/purchasing/suggestions/*`
  - `/api/purchasing/receptions/create-from-po/*`
- **Legacy:** N/A explícito en compras modernas, aunque la recepción inyecta a tablas legacy (`recepcion_cab`, `recepcion_det`).

**Componentes Arquitectónicos Base**
- **Controllers:** `PurchaseSuggestionController`, `ReceivingController`, `ReturnController`, `Api\Purchasing\ReplenishmentController`
- **Services:** `ReplenishmentService`, `DemandCalculationService`, `PurchasingService`, `ReturnService`
- **Livewire:** `Purchasing\Orders\Index|Detail`, `Purchasing\Requests\Create|Index|Detail`, `Replenishment\Dashboard`
- **Models:** `PurchaseRequest`, `PurchaseRequestLine`, `PurchaseOrder`, `PurchaseOrderLine`, `PurchaseSuggestion`, `PurchaseSuggestionLine`

## 5. Base de Datos Crítica
- **Tablas de Orquestación:** `selemti.purchase_requests`, `selemti.purchase_request_lines`, `selemti.purchase_orders`, `selemti.purchase_order_lines`, `selemti.purchase_suggestions`, `selemti.purchase_suggestion_lines`
- **Tablas de Afectación Final:** `selemti.recepcion_cab`, `selemti.recepcion_det`
- **Vistas Específicas Activas:** `vw_replenishment`, `vw_replenishment_dashboard`
- **Funciones PL/pgSQL:** Rutinas dependientes integradas en triggers de kardex a inyección de recepciones.

## 6. Contrato de Datos / Reglas Base de Datos
- **Origen de datos:** Histórico de salidas en PosConsumption, mermas registradas, y umbrales definidos en catálogo de maestro de artículos (min/max).
- **Destino de datos:** Tablas de `recepcion_cab/det` que disparan el ingreso final al `selemti.kardex_diario`.
- **Reglas críticas:** Unidad de Medida (UOM) al pedir vs UOM de factor de conversión al ingreso; si el factor falla, el costo inventariado se distorsiona dramáticamente.

## 7. Fuente de Verdad Real (Mixta)
- **Lógica en Laravel:** La conversión del "sugerido" a una "orden", el gobierno del flujo UI, los ciclos de aprobación (Approve/Reject) y las validaciones del proceso. Laravel asume la autoridad orquestadora del módulo.
- **Lógica en PostgreSQL:** La evaluación matemática pesada que deduce "qué y cuánto" comprar se encuentra empaquetada primordialmente en `vw_replenishment`. PostgreSQL calcula la sugerencia, pero no manda de forma absoluta en el ciclo de vida del módulo.

## 8. Dependencias con Otros Módulos
- **Depende de:** Inventario Pos Consumption (origen del vacío a rellenar) y el Catálogo UOM Base y sus conversiones de receta. La previsión de demanda se basa en los platillos sincronizados desde el POS conforme al Doc 20.
- **Impacta a:** El nivel físico del almacén (aumentando existencia al Postear Recepción) y proyecta deuda en un futuro módulo de Cuentas por Pagar financieramente.
- **Bloqueos conocidos:** UOMs mal configurados cortan el flujo en la recepción.

## 9. Estado Real Desglosado
- **Nivel de Confianza Documental:** Alto - Estructura levantada explícitamente desde inspecciones crudas del repositorio de rutas web/api y endpoints vivos.
- **Implementado:** Completamente en el repositorio de 2026.
- **Operativo:** Activo y orquestado (Flujo Suggestions -> Livewire PO -> API Receptions).
- **Pendiente:** Resoluciones de deuda técnica por duplicidad.
- **Histórico / Legacy:** El ingreso físico impacta directamente a tablas `recepcion_cab` heredadas para salvaguardar compatibilidades de bases terceras.

## 10. Problemas Conocidos / Bugs
- **Bug:** Colisión y Duplicidad en Responsabilidad Lógica de Servicios.
- **Causa:** Desarrollo paralelo o refactorización incompleta resultó en la co-existencia estática de `ReceivingService` vs `ReceptionService` bajo la carpeta `Services/Inventory`.
- **Impacto:** Posible ambigüedad para futuros mantenedores al rastrear lógica de inyección de compra a almacén.
- **Estado:** Identificado y documentado como Deuda Técnica (Tech Debt).

## 11. Riesgos si se Modifica
La capa de **Catálogo UOM y Factores** funge como el gozne entre "Compras" e "Inventarios". Alterar la lógica algorítmica de la vista `vw_replenishment` asumiendo que es una proyección tonta derrumbará los sugeridos al usuario en el Dashboard limitando las compras futuras y generando desabasto.

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
- `AI_COORDINATION/STATUS.md`
- `docs/2026/05_PENDIENTES_Y_BUGS.md`

**Externa / Histórica (Referencia Obsoleta):**
- `D:\Tavo\2025\UX\Inventarios\*` (Prototipos conceptuales de Abastecimiento)

## 13. Backlog Técnico Prioritario
- [ ] Analizar diferencias para fusionar y purgar la duplicidad entre `ReceivingService` y `ReceptionService`.
- [ ] Validar cobertura de unit tests (Actual: ❌ sin tests en ReceivingService).
- [ ] Confirmar desprendimiento total de invocación de Controladores a `Closure` de `routes/api.php` al módulo de compras propio, si las hubiera heredadas.
- [ ] Confirmar de manera exhaustiva si el flujo de recepción está ya completamente desacoplado de cualquier dependencia legacy indirecta o triggers obsoletos.

---
## 14. Regla de Intervención Previa
⚠️ **ESTRICTO - ANTES DE MODIFICAR ESTE MÓDULO:**
1. **Verificar PostgreSQL Primero:** Aislar e inspeccionar la Función, Trigger o Vista canónica de la BD antes de diseñar soluciones vía Controladores en Laravel. Específicamente examinar el interior de `vw_replenishment`.
2. **Pre-Validación en Staging:** Evaluar integraciones y dependencias obligatoriamente en un entorno Local/Staging.
3. **Restricción de Producción:** Si es imperativo consultar directamente en Producción para depurar, la intervención debe de ceñirse a perfiles de *Solo Lectura (`SELECT`)*.
