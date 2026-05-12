# 📦 MÓDULO: Recetas e Ingeniería de Menú (Recipes / BOM)

> **Clasificación:** SOPORTE / AMBIGUO  
> **Estado:** Operativo (Implementación Parcialmente Fragmentada por Nomenclatura)  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** Mixta (Recursividad matemática en PostgreSQL, Control de Flujo de Versiones en Laravel)

---

## 1. Misión Funcional
Administrar las listas de materiales y sub-componentes (Bill of Materials - BOM) bajo una arquitectura que permite recursividad infinita (receta dentro de receta), asegurando un mapeo exacto al ítem de venta en POS y suministrando implosiones para el costeo en tiempo real (WAC).

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/recipes`, `/recipes/editor/{id}`, `/api/recipes/{id}/cost`
- **UI principal:** `App\Livewire\Recipes\RecipeEditor`, `RecipesIndex`, `VersionComparator`
- **Controller / Service central:** `Api\Inventory\RecipeCostController` / `RecipeCostingService`, `RecipeVersionService`, `RecalcularCostosRecetasService`
- **Fuente de verdad en PGSQL:** Vistas especiales `v_receta`, `v_receta_insumo` y la recursividad profunda en `v_ingenieria_menu_completa`.
- **Dependencia crítica:** UOM Conversions e Inventario (Suministra el costo primo).
- **Pendiente prioritario:** Unificar y estandarizar el Spanglish a nivel arquitectura (`Receta` vs `Recipe`, rutas web dobles).

---

## 3. Flujo Funcional
El flujo operativo define qué y cuánto cuesta el producto vendido:
`Vinculación asistida (POS Link) → Creación de Shell → Ingreso a RecipeEditor (BOM) → Asignación de Insumos/Sub-Recetas + UOM → Versionamiento Activo (VersionActivator) → Cálculo Matemático Recursivo de Costo WAC → Publicación del CostSnapshot.`

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Web:** 
  - `/recipes` (Livewire Web Dashboard)
  - `/recipes/editor/{id}`
  - `/recipes/{id}/versions`
  - *(Legacy Duplicado)*: `/recetas`
- **API:** 
  - `/api/recipes/{id}/cost`
  - `/api/recipes/{id}/bom/implode`
  - `/api/recipes/{id}/cost/snapshot`
  - `/api/orquestador/recalcular-costos` (Hook de recalculo global)

**Componentes Arquitectónicos Base**
- **Controllers:** `Api\Inventory\RecipeCostController`
- **Services:** `Recetas\RecalcularCostosRecetasService`, `Recetas\RecipeCostService`, `Recetas\RecipeVersionService`, `Costing\RecipeCostingService`
- **Livewire:** Componentes bajo `Recipes/*` (`RecipeEditor`, `VersionActivator`, `VersionComparator`, `UnidadesIndex`, `ConversionesIndex`)
- **Models:** `Rec\Receta`, `Rec\RecetaDetalle`, `Rec\RecetaVersion`, `Rec\RecipeCostSnapshot`, `Rec\RecetaShadow`, `Rec\Modificador`

## 5. Base de Datos Crítica
- **Tablas Primarias:** `selemti.recetas`, `selemti.receta_detalle`, `selemti.receta_version`, `selemti.receta_shadow`
- **Registro Histórico:** `selemti.historial_costos_receta`
- **Vistas Específicas Activas:** 
  - `v_receta`
  - `v_receta_insumo`
  - `v_ingenieria_menu_completa` (El núcleo de resolución BOM recursiva)
- **Funciones PL/pgSQL:** `fn_recipe_cost_at` (Calculadora dinámica en base a cierres e históricos).

## 6. Contrato de Datos / Reglas Base de Datos
- **Origen de datos:** Master Data de Artículos de Inventario.
- **Destino de datos:** Impacto en implosión para `ticket_item` (Consumo POS) y para `orden_produccion` (Despacho de componentes físicos).
- **Reglas críticas:** Jerarquía infinita. Para que una receta resuelva su ecuación, todos los sub-nodos y hojas del árbol necesitan coincidencia exacta de factores de conversión (UOM). Un UOM roto provoca costo de receta a cero (error silencioso).
- **Sub-Recetas de Modificadores (`REC-MOD-*`):** Los agregados del POS se tratan como recetas independientes. El costo final del plato vendido es la suma de la receta base + las recetas de modificadores seleccionados.
- **Recursividad Logística (Semiterminados):** El sistema permite anidar recetas dentro de otras (ej. Salsa Roja en Enchiladas). Si el componente es una `SUB_RECETA` y tiene stock físico derivado de una OP, el sistema rebaja la unidad producida; de lo contrario, realiza una "explosión" hacia los insumos primarios. Ver detalle técnico en [Doc 24 - Motor de Consumo Recursivo](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md).
- **Tipos de Costeo:** El costo puede derivarse dinámicamente (WAC) o consultarse mediante capturas congeladas (*snapshots* históricos via `historial_costos_receta`). La fuente invocada depende netamente del flujo exigido.
- **Riesgo Silencioso Adicional:** Las recetas estructuralmente válidas pero con nodos o insumos desactivados/incompletos pueden emitir costos netos de $0.00 al cierre de su evaluación sin detonar un error explícito en consola.

## 7. Fuente de Verdad Real (Mixta)
- **Lógica en Laravel:** Domina el gobierno del ciclo de vida productivo de la receta. Almacena las "versiones", facilita la manipulación visual (Livewire) e instrumenta los *snapshots* de costos aprobados comparándolos contra el costo objetivo.
- **Lógica en PostgreSQL:** Las vistas y en especial `v_ingenieria_menu_completa` ejecutan la recursividad brutal con sentencias `WITH RECURSIVE` para aplanar el árbol jerárquico. La sumatoria de costos es jurisdicción incuestionable del motor BD.

## 8. Dependencias con Otros Módulos
- **Depende de:** Fundamentalmente del Módulo de Inventario y su catálogo de conversiones UOM (Units Of Measurement).
- **Impacta a:**
  - **POS Consumption:** Instruye qué materias primas reales deducir cuando Floreant POS vende un ítem compuesto.
  - **Dependencia Indirecta Crítica (POS_SYNC y POS Link):** Floreant POS no interpreta recetas *per se*; el vaciado físico de inventario depende estrictamente del pipeline POS_SYNC, el vínculo manual de POS Link y sus triggers. Esto introduce un riesgo letal si se sufre desalineación entre la receta teórica del BackOffice vs el consumo real.
  - **Producción:** Provee la lista (BOM) para fabricar semiterminados o procesados en planta.

## 9. Estado Real Desglosado
- **Nivel de Confianza Documental:** Medio/Alto - Los componentes están plenamente validados pero entrelazados por nomenclatura confusa.
- **Implementado:** Operativo con deuda técnica controlada en la arquitectura "2026".
- **Operativo:** Activo y generando implosiones de receta a tiempo real. Costing activo.
- **Pendiente:** Unificación técnica radical de namespace (Desarraigar el modelo `Rec\Receta` o adaptarlo firmemente al contexto de `Recipe`).

## 10. Problemas Conocidos / Bugs
- **Bug:** Diccionario de Dominios Cruzado (Spanglish).
- **Causa:** Desarrollo iterativo. Se inyectaron vistas web anglosajonas (`/recipes`) mezclando namespaces nativos (`app/Models/Rec/` y base de datos `recetas`). Resulta en controladores como `RecipeCostController` consumiendo tablas `receta_detalle`.
- **Impacto:** Fricción cognitiva severa al desarrollar y mantener dependencias, con dobletas ocasionales en `routes/web.php`.
- **Estado:** Parcialmente documentado, marcado como Deuda Técnica Crítica.

## 11. Riesgos si se Modifica
La recursividad `WITH RECURSIVE` en `v_ingenieria_menu_completa` es de una fragilidad alta. Intervenir la base para crear atajos puede causar "ciclos infinitos" (circular loops donde la Receta A requiere Receta B que requiere Receta A) lo que derrumbaría el servidor PostgreSQL. No tocar validaciones de guardado estructural en Livewire.

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
- `docs/2026/20_PROTOCOLO_ALINEACION_POS_ERP.md`
- `AI_COORDINATION/STATUS.md`
- `docs/2026/05_PENDIENTES_Y_BUGS.md`

**Externa / Histórica (Referencia Obsoleta):**
- `D:\Tavo\2025\UX\00. Recetas\*` 

## 13. Backlog Técnico Prioritario
- [ ] Refactorización Lingüística: Deprecar de una vez `routes/web.php` con las redirecciones heredadas (`/legacy/recetas` y `/recetas`).
- [ ] Confirmar la orquestación del endpoint de cron `recalcular-costos` (`RecalcularCostosRecetasService`).
- [ ] Robustecer protección algorítmica contra Loops Circulares de Materia Prima al anidar sub-recetas en Componentes Livewire.

---
## 14. Regla de Intervención Previa
⚠️ **ESTRICTO - ANTES DE MODIFICAR ESTE MÓDULO:**
1. **Verificar PostgreSQL Primero:** Aislar e inspeccionar la Función, Trigger o Vista canónica de la BD antes de diseñar soluciones vía Controladores en Laravel (`v_ingenieria_menu_completa`).
2. **Pre-Validación en Staging:** Evaluar integraciones y dependencias obligatoriamente en un entorno Local/Staging, vigilando el CostSnapshot final producido.
3. **Restricción de Producción:** Si es imperativo consultar directamente en Producción para depurar, la intervención debe de ceñirse a perfiles de *Solo Lectura (`SELECT`)*.
