# AGENT_07_Costos_Recetas_Scheduler.md

## Descripción
Agente encargado de asegurar que la tarea agendada de recálculo de costos de recetas se ejecute correctamente a las 01:10 hora de México.

## Objetivo
Mantener actualizados los costos de recetas basados en cambios de precios de materias primas, y asegurar que la tarea agendada se ejecute diariamente en el horario especificado.

## Funcionalidades
1. Verificación del scheduler configurado en Laravel para ejecutar `recetas:recalcular-costos` a las 01:10
2. Validación de generación de snapshots en `recipe_cost_history` o `recipe_extended_cost_history`
3. Documentación del resultado del proceso
4. Verificación de que `recipe_cost_history.snapshot_at = date`

## Estructura de datos
- Tablas de destino: `selemti.recipe_cost_history`, `selemti.recipe_extended_cost_history`
- Campo de fecha: `snapshot_at` o equivalente
- Campos: `recipe_id`, `costo_unitario`, `fecha_registro`, `tipo_cambio`

## Configuración
- Tarea programada: diaria a las 01:10 (timezone: America/Mexico_City)
- Comando: `recetas:recalcular-costos`
- Parámetros: `--date=ayer` (por defecto)