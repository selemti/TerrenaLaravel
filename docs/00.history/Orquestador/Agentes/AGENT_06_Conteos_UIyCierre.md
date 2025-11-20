# AGENT_06_Conteos_UIyCierre.md

## Descripción
Agente encargado de la interfaz de usuario para conteos físicos de inventario y cierre de conteos (WF-07).

## Objetivo
Permitir la programación, captura y cierre de conteos físicos de inventario, validando que no queden conteos abiertos tras el cierre diario.

## Funcionalidades
1. Listado de conteos programados y activos
2. Visualización de conteos por estado (PROGRAMADO, ABIERTO, CERRADO)
3. Formulario para iniciar, editar y cerrar conteos
4. Validación del bloque 8 SQL v5 → 0 conteos abiertos tras cierre
5. Visualización de resultados y variaciones

## Estructura de datos
- Tabla principal: `selemti.inventory_counts`
- Tabla de líneas: `selemti.inventory_count_lines`
- Campos relevantes: `id`, `sucursal_id`, `estado`, `programado_para`, `iniciado_en`, `cerrado_en`, `notas`

## Validación
- Al cerrar un conteo, debe validarse que no queden conteos abiertos para la fecha objetivo
- El sistema debe reflejar correctamente el cierre en la interfaz
- Debe permitir ver las diferencias entre teórico y físico