# Log del Scheduler de Costos
Fecha: jueves, 30 de octubre de 2025

## Descripción
Registro de ejecución del servicio de recálculo de costos de recetas programado en el sistema Terrena Laravel.

## Configuración del Scheduler
- Comando: `recetas:recalcular-costos`
- Frecuencia: Diaria a las 01:10
- Descripción: Recalcular el costo unitario de recetas publicadas y subrecetas cuyo insumo cambió de precio el día anterior, y propagar costo a padres

## Servicio Ejecutado
- Clase: `App\Services\Recetas\RecalcularCostosRecetasService`
- Método principal: `recalcularCostos()`
- Lógica implementada:
  - Detectar insumos con cambio de costo (WAC/último) con valid_from = date
  - Recalcular subrecetas afectadas (versión publicada vigente a la fecha)
  - Recalcular recetas que referencian esas subrecetas/insumos
  - Propagar los cambios de costo hacia arriba en la jerarquía de recetas
  - Persistir en históricos existentes
  - Generar alertas para recetas con margen negativo (opcional)

## Resultados de Ejecución
- Fecha procesada: [FECHA_ACTUAL]
- Items con cambio de costo: [PENDIENTE DE EJECUCIÓN]
- Subrecetas recalculadas: [PENDIENTE DE EJECUCIÓN]
- Recetas recalculadas: [PENDIENTE DE EJECUCIÓN]
- Alertas generadas: [PENDIENTE DE EJECUCIÓN]

## Validación
- El servicio implementa idempotencia mediante un lock en Redis
- Cálculo de márgenes y generación de alertas para recetas con márgen negativo o muy bajo
- Registro en histórico de costos si existen las tablas correspondientes

## Seguimiento
- Se mantiene la integridad de la línea de tiempo de costos
- Solo se procesan versiones con `version_publicada = true` y `fecha_efectiva <= date`
- No se reescriben costos de días anteriores