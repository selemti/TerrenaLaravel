# Definición del Módulo: Producción

## Descripción General
El módulo de Producción gestiona las órdenes de producción, planificación, ejecución y control de procesos productivos. Incluye funcionalidades para planificar según demanda, stock objetivo o calendario, así como el cálculo de KPIs de eficiencia.

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

### 2. Planificación de Producción
**Descripción:** Funcionalidad para crear y gestionar órdenes de producción.

**Características actuales:**
- Estructura básica en endpoints

**Requerimientos de UI/UX:**
- Planificación automática basada en demanda de ventas POS
- Planificación por niveles de stock objetivo
- Planificación por calendario o programación
- Asignación de recursos y capacidades
- Vista calendarizada de producción

### 3. Control de Producción
**Descripción:** Seguimiento y control de las órdenes de producción en ejecución.

**Características actuales:**
- Endpoints para consumo y posteo disponibles

**Requerimientos de UI/UX:**
- Seguimiento en tiempo real de órdenes activas
- Registro de consumos reales vs teóricos
- Cálculo de mermas y rendimientos
- Cierre de órdenes con posteo a inventario

## Requerimientos Técnicos
- Pantallas Livewire para UI operativa
- Colas de posteo para operaciones asíncronas
- Permisos finos (planificar vs postear)
- Integración con módulos de inventario y recetas
- Tablas para batches de producción y consumos
- Sistema de auditoría para cambios en OP

## Integración con Otros Módulos
- Recetas: Base para cálculo de materias primas
- Inventario: Consumo de materias primas y producción de terminados
- POS: Fuente de demanda para planificación
- Reportes: KPIs de producción y rendimiento

## KPIs Asociados
- Eficiencia de producción
- Rendimiento (output/input)
- Merma por batch
- Costo por batch
- Cumplimiento de fechas de entrega
- Utilización de capacidad
- Desviación de costos teóricos vs reales

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