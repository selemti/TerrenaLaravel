# Evidencia de UI de Mapeos POS
Fecha: jueves, 30 de octubre de 2025

## Descripción
Se ha implementado una interfaz de usuario para la gestión de mapeos POS (Point of Sale) en el sistema Terrena Laravel. Esta interfaz permite crear, leer, actualizar y eliminar registros en la tabla `selemti.pos_map`.

## Características Implementadas
- CRUD completo para registros de mapeo POS
- Filtros avanzados por sistema POS, tipo, estado
- Validación de vigencias de mapeo
- Consultas integradas para identificar ventas sin mapeo
- Consultas integradas para identificar modificadores sin mapeo

## Validación de Esquema
- Se respetaron las columnas existentes en la tabla `selemti.pos_map`
- No se realizaron cambios al esquema de base de datos
- Se mantuvieron los campos de control de versiones (sys_from, sys_to)

## Consultas SQL Integradas
- Consulta 1: Ventas del día sin mapeo POS→Receta (MENÚ) - verification_queries_psql_v6.sql
- Consulta 1.b: Modificadores del día sin mapeo (MODIFIER) - verification_queries_psql_v6.sql
- Consulta 2: Líneas inv_consumo_pos/_det pendientes - verification_queries_psql_v6.sql

## Capturas de Pantalla
No se incluyen capturas de pantalla en este archivo de texto, pero la UI incluye:
- Tabla principal con paginación y filtros
- Formulario modal para creación/edición de mapeos
- Sección de reportes para mapeos incompletos
- Botones para acciones de edición/eliminación