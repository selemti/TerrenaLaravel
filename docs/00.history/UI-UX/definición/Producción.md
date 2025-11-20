# Definición del Módulo: Producción

## Descripción General
El módulo de Producción gestiona las órdenes de producción, planificación, ejecución y control de procesos productivos. Incluye funcionalidades para planificar según demanda, stock objetivo o calendario, así como el cálculo de KPIs de eficiencia. El sistema implementa el flujo Produmix para planificación diaria y control de mermas.

## Componentes del Módulo

### 1. API y Endpoints
**Descripción:** Funcionalidades programáticas para planificación, consumo, completar y postear producción.

**Características actuales:**
- Endpoints plan/consume/complete/post disponibles
- UI operativa pendiente

**Requerimientos de UI/UX:**
- UI Operativa de producción: planificar por demanda (ventas POS), por stock objetivo o por calendario
- Vista de KPIs: teorías vs reales, mermas y costo por batch
- Gestión de batches de producción
- Seguimiento de rendimiento y eficiencia

### 2. Planificación de Producción (Produmix)
**Descripción:** Funcionalidad para crear y gestionar órdenes de producción basadas en demanda estimada.

**Características actuales:**
- Algoritmo de planificación Produmix que transforma demanda estimada en órdenes de producción
- Entradas: histórico POS, inventario terminado, par stock/metas
- Implosión de recetas hasta insumo crudo inventariable
- Tablas: selemti.produmix_plan, selemti.produmix_plan_det, selemti.produmix_plan_log

**Requerimientos de UI/UX:**
- Planificación automática basada en demanda de ventas POS
- Planificación por niveles de stock objetivo
- Planificación por calendario o programación
- Asignación de recursos y capacidades
- Vista calendarizada de producción
- Dashboard Produmix con resumen por SKU
- Indicadores por familia (Salsa, Proteínas, Empanadas, etc.)
- Botones: "Generar plan", "Aprobar plan", "Emitir órdenes"
- Detalle por SKU con histórico de consumo POS y inventario terminado
- Log de decisiones con motivo y registro en produmix_plan_log

### 3. Control de Producción
**Descripción:** Seguimiento y control de las órdenes de producción en ejecución.

**Características actuales:**
- Endpoints para consumo y posteo disponibles
- ProductionService con métodos: planBatch, consumeIngredients, completeBatch, postBatchToInventory
- Implosión obligatoria de recetas hasta insumos crudos inventariables

**Requerimientos de UI/UX:**
- Seguimiento en tiempo real de órdenes activas
- Registro de consumos reales vs teóricos
- Cálculo de mermas y rendimientos
- Cierre de órdenes con posteo a inventario
- Cocina líder ejecuta órdenes (plan → consume → complete → post)
- Registro de mermas planificadas o incidentales
- Cada lote producido, merma, reproceso o ajuste debe almacenar user_id, timestamp, motivo y referencias
- Merma se registra como tipo de movimiento en mov_inv (MERMA_PRODUCCION, MERMA_CALIDAD, etc.)

### 4. Merma y Control de Alérgenos
**Descripción:** Gestión de mermas y control de alérgenos en la producción.

**Características actuales:**
- Cada receta debe identificar los puntos de merma esperada (limpieza, cocción, montaje)
- Merma se registra como tipo de movimiento en mov_inv

**Requerimientos de UI/UX:**
- Registrar mermas planificadas o incidentales (pesaje, calidad)
- Para productos congelados/refrigerados, registrar lote y fecha de descongelación
- Ajustes manuales sin motivo quedan prohibidos (Política C)
- Cada receta debe identificar los puntos de merma esperada
- Seguimiento de rendimiento real vs teórico por receta/turno

## Requerimientos Técnicos
- Pantallas Livewire para UI operativa
- Colas de posteo para operaciones asíncronas
- Permisos finos (planificar vs postear)
- Integración con módulos de inventario y recetas
- Tablas para batches de producción y consumos
- Sistema de auditoría para cambios en OP
- ProductionService: planBatch, consumeIngredients, completeBatch, postBatchToInventory
- Tablas: selemti.production_order, production_order_log, production_merma
- Conexión con Produmix → ProductionService automáticamente al aprobar plan
- Implementar bitácora de ejecución (quién posteó, merma, observaciones)

## Integración con Otros Módulos
- Recetas: Base para cálculo de materias primas, implosión de recetas
- Inventario: Consumo de materias primas y producción de terminados
- POS: Fuente de demanda para planificación, integración con consumo POS
- Reportes: KPIs de producción y rendimiento
- Replenishment: Validación de materia prima disponible, generación automática de compras para faltantes
- Caja Chica: Posible financiamiento para materiales de producción

## KPIs Asociados
- Eficiencia de producción
- Rendimiento (output/input)
- Merma por batch
- Costo por batch
- Cumplimiento de fechas de entrega
- Utilización de capacidad
- Desviación de costos teóricos vs reales
- Cumplimiento de plan (producción ejecutada / producción sugerida)
- Desviación vs. par stock
- Incidencias de agotados POS por falta de producción
- Tiempo promedio entre aprobación de plan y cierre de órdenes de producción
- Rendimiento real vs teórico por receta/turno
- Variación de costos

## Flujos de Trabajo

### Flujo Básico de Producción
1. **Planificación**: Sistema genera órdenes sugeridas basadas en demanda POS
2. **Aprobación**: Gerente cocina aprueba plan de producción
3. **Ejecución**: Cocina líder ejecuta órdenes (plan → consume → complete → post)
4. **Posteo**: Sistema registra movimientos en inventario y cierra orden
5. **Auditoría**: Registro completo de todas las acciones

### Estados de Órdenes de Producción
```
BORRADOR → PLANIFICADA → EN_PROCESO → COMPLETADA → POSTEADA → CERRADA
```

### Estados Detallados
- **BORRADOR**: Orden creada pero no aprobada
- **PLANIFICADA**: Aprobada y lista para ejecutar
- **EN_PROCESO**: En ejecución por cocina
- **COMPLETADA**: Ejecutada pero no posteada
- **POSTEADA**: Movimientos generados en inventario
- **CERRADA**: Orden finalizada y bloqueada

## Componentes Técnicos

### Servicios
- **ProductionService**: Servicio principal para operaciones de producción
  - `planBatch()`: Planifica un batch de producción
  - `consumeIngredients()`: Registra consumo de insumos
  - `completeBatch()`: Completa batch de producción
  - `postBatchToInventory()`: Postea batch a inventario

### Controladores
- **ProductionController**: Controlador REST para operaciones de producción
  - `POST /api/production/batch/plan`
  - `POST /api/production/batch/{batch_id}/consume`
  - `POST /api/production/batch/{batch_id}/complete`
  - `POST /api/production/batch/{batch_id}/post`

### Modelos
- **ProductionOrder**: Modelo para órdenes de producción
- **ProductionOrderLine**: Modelo para líneas de órdenes
- **ProductionBatch**: Modelo para batches de producción
- **ProductionConsumption**: Modelo para consumos de producción
- **ProductionOutput**: Modelo para salidas de producción

### Tablas
- `selemti.production_order`: Cabecera de órdenes de producción
- `selemti.production_order_line`: Líneas de órdenes
- `selemti.production_batch`: Batches de producción
- `selemti.production_consumption`: Registro de consumos
- `selemti.production_output`: Registro de salidas
- `selemti.production_merma`: Registro de mermas
- `selemti.produmix_plan`: Plan de producción diario
- `selemti.produmix_plan_det`: Detalle del plan
- `selemti.produmix_plan_log`: Bitácora de decisiones

## Permisos y Roles

### Permisos Disponibles
- `can_edit_production_order`: Ejecutar producción y registrar mermas
- `can_manage_produmix`: Ver, editar y aprobar el plan Produmix, emitir órdenes
- `production.orders.view`: Ver órdenes de producción
- `production.orders.close`: Cerrar OP (consume MP)
- `production.batches.plan`: Planificar batches
- `production.batches.consume`: Registrar consumos
- `production.batches.complete`: Completar batches
- `production.batches.post`: Postear batches

### Roles Sugeridos
- **Cocina Líder**: `can_edit_production_order`, `production.orders.close`, `production.batches.*`
- **Chef Ejecutivo**: `can_manage_produmix`, `can_edit_production_order`
- **Gerente de Sucursal**: `can_manage_produmix`, `production.orders.view`, `production.orders.close`
- **Director de Operaciones**: Todos los permisos de producción

## Consideraciones Especiales

### Implosión de Recetas
- Obligatoria para todas las órdenes de producción
- Debe llegar hasta insumos crudos inventariables
- Validación automática de disponibilidad de materias primas
- Generación de alertas si faltan insumos críticos

### Control de Mermas
- Registro obligatorio de todas las mermas
- Clasificación por tipo (preparación, calidad, caducidad)
- Justificación obligatoria para mermas significativas
- Alertas automáticas cuando merma supera umbrales

### Auditoría Completa
- Registro de todas las acciones en producción_order_log
- Trazabilidad completa de cambios (quién, cuándo, qué)
- Evidencia de movimientos en mov_inv
- Bitácora de ejecución en production_batch_log