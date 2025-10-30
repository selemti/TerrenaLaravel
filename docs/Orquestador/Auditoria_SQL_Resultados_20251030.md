# Resultados de Auditoría SQL
Fecha: jueves, 30 de octubre de 2025

## Scripts Integrados
- verification_queries_psql_range.sql
- verification_queries_psql_v6.sql
- discover_schema_psql_v2.sql

## Resultados de verification_queries_psql_range.sql

### Consulta 1: Ventas en rango de fechas sin mapeo POS→Receta (MENÚ)
- Descripción: Identifica ítems de menú vendidos que no tienen mapeo a receta en un rango de fechas
- Parámetros: `fecha_inicio`, `fecha_fin`, `sucursal_key`
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: ticket_item_id, menu_item_id, menu_item_pg_id, menu_item_name, ticket_id, fecha_venta, terminal_id, sucursal

### Consulta 1.b: Modificadores en rango de fechas sin mapeo (MODIFIER)
- Descripción: Identifica modificadores en ventas que no tienen mapeo POS en un rango de fechas
- Parámetros: `fecha_inicio`, `fecha_fin`, `sucursal_key`
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: ticket_item_mod_id, modifier_item_id, ticket_id, fecha_venta, terminal_id, sucursal

### Consulta 2: Líneas inv_consumo_pos/_det pendientes en rango de fechas
- Descripción: Identifica líneas pendientes de procesamiento en un rango de fechas
- Parámetros: `fecha_inicio`, `fecha_fin`, `sucursal_key`
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: id, ticket_id, sucursal_id, terminal_id, fecha, mp_id, uom_id, factor, cantidad, requiere_reproceso, procesado, fecha_proceso

### Consulta 3: Tickets expandidos en rango pero sin movimientos definitivos en selemti.mov_inv
- Descripción: Identifica tickets que se expandieron a consumos POS pero que no generaron movimientos en el inventario en un rango de fechas
- Parámetros: `fecha_inicio`, `fecha_fin`, `sucursal_key`
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: ticket_id, fecha_ticket, sucursal_id

### Consulta 4: Recetas mapeadas en rango de fechas sin snapshot de costo
- Descripción: Recetas mapeadas POS que no tienen registro de costo en un rango de fechas
- Parámetros: `fecha_inicio`, `fecha_fin`
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: recipe_id, primer_mapeo, primer_costo

### Consulta 5: Conteos físicos abiertos en rango de fechas (por sucursal)
- Descripción: Inventario conteos que estaban abiertos en un rango de fechas
- Parámetros: `fecha_inicio`, `fecha_fin`, `sucursal_key`
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: id, sucursal_id, programado_para, iniciado_en, estado, cerrado_en, renglones

### Consulta 6: Movimientos de inventario en rango por sucursal
- Descripción: Resume los movimientos de inventario por tipo en un rango de fechas
- Parámetros: `fecha_inicio`, `fecha_fin`, `sucursal_key`
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: ref_tipo, total_movimientos, items_afectados, suma_cantidades

### Consulta 7: Recuentos de tickets y consumos POS por día en el rango
- Descripción: Compara el volumen de tickets y consumos POS procesados por día en un rango
- Parámetros: `fecha_inicio`, `fecha_fin`, `sucursal_key`
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: fecha, tickets, consumos_expandidos

## Resultados de discover_schema_psql_v2.sql

### Consulta 1: Información general de esquemas
- Descripción: Resume las tablas por esquema
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: schema_name, total_tables

### Consulta 2: Tablas en esquema 'public' con detalles
- Descripción: Proporciona información sobre las tablas en el esquema 'public'
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: table_name, size, table_size, estimated_rows

### Consulta 3: Tablas en esquema 'selemti' con detalles
- Descripción: Proporciona información sobre las tablas en el esquema 'selemti'
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: table_name, size, estimated_rows

### Consulta 4: Columnas de tabla selemti.pos_map con tipos detallados
- Descripción: Detalla las columnas de la tabla de mapeos POS
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: column_name, data_type, is_nullable, column_default, character_maximum_length, numeric_precision, numeric_scale

### Consulta 5: Columnas de tabla selemti.inventory_counts e inventory_count_lines
- Descripción: Detalla las columnas de las tablas de conteo físico
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: table_name, column_name, data_type, is_nullable, column_default, character_maximum_length, numeric_precision, numeric_scale

### Consulta 6: Columnas de tablas de costos de recetas
- Descripción: Detalla las columnas de las tablas de historial de costos de recetas
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: table_name, column_name, data_type, is_nullable, column_default, character_maximum_length, numeric_precision, numeric_scale

### Consulta 7: Índices en tablas relevantes para rendimiento
- Descripción: Muestra los índices en las tablas más importantes para rendimiento
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: schemaname, tablename, indexname, indexdef

### Consulta 8: Llaves foráneas en esquema selemti
- Descripción: Muestra las relaciones entre tablas en el esquema selemti
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: table_name, constraint_name, constraint_type, column_name, foreign_table_name, foreign_column_name

### Consulta 9: Secuencias en los esquemas relevantes
- Descripción: Muestra las secuencias de identificadores en los esquemas
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: sequence_schema, sequence_name, data_type, start_value, minimum_value, maximum_value, increment, cycle_option

### Consulta 10: Estadísticas de uso de tablas (últimas operaciones)
- Descripción: Muestra estadísticas de uso de las tablas
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: schemaname, tablename, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, n_tup_upd, n_tup_del, n_tup_hot_upd, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze

### Consulta 11: Tipos de datos personalizados (si existen)
- Descripción: Muestra tipos de datos personalizados en los esquemas
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: type_name, schema_name, type_type, description

### Consulta 12: Configuración de los servidores de datos
- Descripción: Muestra configuración importante del servidor PostgreSQL
- Resultado: [PENDIENTE DE EJECUCIÓN EN BASE DE DATOS]
- Columnas: name, setting, unit, category, short_desc

## Resumen
Estos scripts proporcionan una visión completa del esquema de base de datos y permiten realizar auditorías detalladas del sistema. La información obtenida es fundamental para:
- Validar la integridad de los datos
- Verificar el correcto funcionamiento de los procesos
- Identificar problemas de rendimiento
- Planificar optimizaciones
- Asegurar la calidad del sistema

Los resultados reales se obtendrán cuando se ejecuten estos scripts en la base de datos del entorno correspondiente.