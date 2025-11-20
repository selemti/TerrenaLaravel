# AGENT_09_SQL_Auditor.md

## Descripción
Agente encargado de crear y mantener scripts SQL para auditoría y verificación del sistema.

## Objetivo
Proporcionar herramientas de auditoría SQL para verificar la integridad del sistema, facilitar diagnósticos y permitir análisis de rangos de fechas específicos.

## Funcionalidades
1. Creación de `verification_queries_psql_range.sql` para consultas en rangos de fechas
2. Actualización de `discover_schema_psql_v2.sql` con mejor descubrimiento del esquema
3. Mantenimiento de scripts de verificación existentes
4. Scripts optimizados para auditoría de procesos y validación de datos

## Estructura de archivos
- `docs/Orquestador/sql/verification_queries_psql_range.sql`
- `docs/Orquestador/sql/discover_schema_psql_v2.sql`

## Requerimientos
- Scripts deben ser compatibles con PostgreSQL 9.5+
- Deben mantener la misma estructura de parámetros que los scripts existentes
- Deben permitir análisis por rangos de fechas específicos
- Deben incluir verificaciones de integridad de datos