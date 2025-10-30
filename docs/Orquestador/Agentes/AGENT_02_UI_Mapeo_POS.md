# AGENT_02_UI_Mapeo_POS.md

## Descripción
Agente encargado de la interfaz de usuario para el mantenimiento de mapeos POS (WF-05). Permite listar, crear, editar y eliminar mapeos entre productos del POS y recetas del sistema.

## Objetivo
Mantener actualizada la tabla `selemti.pos_map` con mapeos entre PLU del POS y recetas del sistema, permitiendo la correcta expansión de tickets POS a consumos de materias primas.

## Funcionalidades
1. Listado de mapeos existentes con filtros por sucursal, tipo, y vigencia
2. Formulario CRUD para mapeos POS (MENU/MODIFIER)
3. Integración con servicios existentes de mapeo POS
4. Visualización de mapeos pendientes o faltantes

## Estructura de datos
- Tabla: `selemti.pos_map`
- Campos: `id`, `tipo`, `plu`, `receta_id`, `recipe_version_id`, `valid_from`, `valid_to`, `vigente_desde`, `sucursal_id`, `activo`, `created_at`, `updated_at`

## Requerimientos
- Compatibilidad con vistas existentes
- No modificar el esquema de la base de datos
- Seguir patrones de UI/UX del sistema
- Integración con el sistema de permisos existente