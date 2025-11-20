# COMPENDIO SUPREMO FUSION - QWEN

## HISTORIA DEL PROYECTO

Terrena comenzó como un sistema POS/ERP para restaurantes con el objetivo de integrar operaciones de inventario, producción, compras y reportes. A lo largo del desarrollo, se identificaron múltiples gaps entre la documentación y la implementación real del sistema.

El proyecto ha pasado por 6 fases críticas de análisis:
- FASE 1: Análisis de documentación existente
- FASE 2: Revisión de V4.0 comparando con compendio de FASE 1
- FASE 3: Integración documental proponiendo estructura ordenada
- FASE 4: Análisis de código y funcionalidades del proyecto
- FASE 5: Análisis de base de datos (esquema selemti)
- FASE 6: Evaluación UI/UX del sistema

## LO APRENDIDO EN LAS FASES

### FASE 1 - Análisis de documentación
- Mucha documentación estaba dispersa en diferentes ubicaciones
- Existían contradicciones entre documentación histórica y actual
- Se identificaron funciones planeadas pero no implementadas
- Había una brecha entre lo documentado y lo implementado

### FASE 2 - Revisión V4.0
- La versión V4.0 contenía información actualizada pero incompleta
- Se encontraron funcionalidades mencionadas pero no implementadas
- La documentación sugería eliminar features futuros, pero se optó por mantenerlos como pendientes

### FASE 3 - Estructura integrada
- Se propuso una estructura documental ordenada por módulos
- Se identificaron fuentes documentales para cada componente
- Se detectaron áreas de mejora en la organización

### FASE 4 - Análisis de código
- El código mostró una implementación más avanzada de lo que sugería la documentación inicial
- Existen servicios más completos de lo que se documentaba
- Se encontraron duplicados o servicios paralelos (ReceivingService vs ReceptionService)

### FASE 5 - Análisis BD
- La base de datos está bien estructurada con 141 tablas normalizadas
- Las vistas y funciones están implementadas pero no completamente integradas con la UI
- Hay coherencia entre la estructura de BD y la documentación técnica

### FASE 6 - Evaluación UI/UX
- La UI tiene componentes reutilizables pero con inconsistencias visuales
- Existen flujos operativos completos pero con UX mejorable
- Faltan interfaces para funcionalidades ya implementadas en backend

## ESTADO TÉCNICO ACTUAL

### Código
- La base de código está bien estructurada con servicios, modelos y componentes Livewire
- Se implementó el patrón de arquitectura de capas (presentación, aplicación, negocio, datos)
- Existe un buen uso de servicios y buenas prácticas de Laravel

### Base de Datos
- Esquema selemti con 141 tablas bien normalizadas
- Funciones y vistas SQL para cálculos complejos
- Estructura enterprise-grade con triggers de auditoría

### UI
- Componentes reutilizables con Blade y Livewire
- Layout consistente con Bootstrap y Tailwind
- Falta completar interfaces para funcionalidades completas en backend

## MÓDULOS DEL SISTEMA Y CONEXIONES

### 1. Inventario
- Conectado con: Recetas, Producción, POS, Compras
- Componentes: Items, Recepciones, Conteos, Transferencias, Kardex
- APIs: /api/inventory/*, /api/inventory/transfers/*

### 2. Recetas
- Conectado con: Inventario, Producción, POS
- Componentes: Editor, Versionado, Costeo, Mapeo
- APIs: /api/recipes/*, /api/recipes/cost/*

### 3. Producción
- Conectado con: Recetas, Inventario, Ventas
- Componentes: Órdenes de producción, consumos, mermas
- APIs: /api/production/*

### 4. Compras/Purchasing
- Conectado con: Inventario, Proveedores, Recepciones
- Componentes: Solicitudes, órdenes, motor de replenishment
- APIs: /api/purchasing/*

### 5. POS
- Conectado con: Recetas, Ventas, Consumos
- Componentes: Mapeo, reprocesamiento, auditoría
- APIs: /api/pos/* (muchos no expuestos aún)

### 6. Caja Chica
- Conectado con: Movimientos financieros, cortes
- Componentes: Fondos, movimientos, arqueos
- APIs: /api/caja/*

### 7. Reportes
- Conectado con: Todos los módulos para métricas
- Componentes: KPIs, dashboards, exportaciones
- APIs: /api/reports/*

## DEPENDENCIAS ENTRE MÓDULOS

```
Ventas → POS → Recetas → Inventario
Inventario → Producción → Recetas
Compras → Inventario → Recetas
Caja ← Cortes → Ventas
Reportes ← Todos los módulos
```

## MAPA DOC-V4.0 vs CÓDIGO vs BD

### docs/V4.0/Arquitectura/
- Documenta: Stack, wiring, convenciones
- Código: Configurado en routes/, config/, app/
- BD: No aplica

### docs/V4.0/Inventario/
- Documenta: Items, Recepciones, Transferencias, Conteos
- Código: app/Livewire/Inventory/, app/Services/Inventory/
- BD: tablas selemti.items, recepcion_*, inventory_batch, mov_inv

### docs/V4.0/Recetas/
- Documenta: Catálogo, versionado, costeo
- Código: app/Livewire/Recipes/, app/Services/Costing/
- BD: tablas selemti.receta_*, recipe_cost_*

### docs/V4.0/Produccion/
- Documenta: Órdenes, planificación
- Código: app/Services/Inventory/ProductionService.php
- BD: tablas selemti.production_*, inventory_wastes

### docs/V4.0/Purchasing/
- Documenta: Solicitudes, órdenes, replenishment
- Código: app/Livewire/Purchasing/, app/Services/Purchasing/
- BD: tablas selemti.purchase_*, stock_policy

## ÍNDICE DE RUTAS Y PUNTOS CRÍTICOS

### Rutas API más importantes:
- /api/inventory/* - Gestión de inventario
- /api/recipes/* - Gestión de recetas y costos
- /api/production/* - Operaciones de producción
- /api/purchasing/* - Compras y reposición
- /api/caja/* - Operaciones financieras
- /api/reports/* - Reportes y KPIs

### Puntos críticos identificados:
1. Motor de Replenishment: Documentado pero no implementado
2. Versionado de Recetas: Parcialmente implementado
3. UI de Producción: Servicio completo pero UI pendiente
4. Endpoints POS: Código completo pero rutas no expuestas
5. Reportes: Funcionalidades completas pero UI básica

## REGLAS PARA AGENTES IA

### Antes de comenzar trabajo:
1. Leer 00_CONTRATO_SISTEMA_QWEN_v2.md
2. Revisar 01_MATRIZ_ALINEACION_QWEN_v2.md
3. Consultar 02_BACKLOG_SPRINTS_QWEN_v2.md
4. Estudiar docs/V4.0/<modulo>/ donde vaya a trabajar

### Durante el desarrollo:
1. Mantener consistencia entre docs/código/BD
2. No modificar módulos ajenos al asignado
3. Actualizar documentación V4.0 al completar tareas
4. Validar con estructura de BD antes de cambios

### Al finalizar tareas:
1. Verificar coherencia con otros módulos
2. Actualizar matriz de alineación si se resuelve un gap
3. Registrar cambios en el backlog si aplica
4. Notificar dependencias a otros módulos si aplica