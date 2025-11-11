# Auditoría Operacional

## Propósito

El módulo de Auditoría Operacional ("Caja Negra Operativa") registra todas las acciones sensibles del sistema para garantizar trazabilidad completa y facilitar auditorías internas y externas.

## Acceso

- **Permiso requerido**: `audit.view`
- **Acceso automático**: Usuarios con rol `Super Admin`
- **Usuario especial**: El usuario `soporte` siempre tiene acceso

## Qué se audita

### Inventario
- Recepciones posteadas
- Ajustes de stock
- Conteos físicos
- Movimientos manuales

### Transferencias
- Envío entre almacenes (ship)
- Recepción en destino (receive)
- Cierre definitivo (post)

### Producción
- Batches procesados
- Merma reportada
- Ajustes de producción

### Recetas y Costos
- Cambios en fórmulas
- Actualizaciones de costos
- Modificaciones de ingredientes

### POS (Punto de Venta)
- Reprocesamiento de tickets
- Reversas de ventas
- Correcciones de consumos

### Caja Chica
- Aperturas de fondos
- Movimientos aprobados
- Cierres de cajas
- Ajustes de saldos

## Estructura de registros

Cada acción auditada contiene:

### Datos obligatorios
- **Usuario**: Quién realizó la acción
- **Timestamp**: Fecha y hora exacta
- **Módulo**: Sistema donde ocurrió (inventario, transferencia, etc.)
- **Acción**: Tipo específico de operación
- **Entidad**: Objeto afectado (ID de recepción, ticket, etc.)

### Datos opcionales
- **Motivo**: Justificación proporcionada por el usuario
- **Evidencia**: URL a documento o imagen adjunta
- **Payload**: Datos estructurados del cambio (antes/después)

## Vista del módulo

### Listado principal
- Tabla paginada con últimos 50 registros
- Filtros por fecha, usuario, módulo y texto libre
- Columnas clave: fecha, usuario, acción, entidad, motivo

### Detalle de registro
- Vista ampliada con todos los datos del evento
- Diferencias en payload (antes/después) en formato JSON
- Enlaces a evidencia adjunta si existe
- Información completa del usuario y contexto

## Seguridad y privacidad

### Acceso restringido
- Solo personal autorizado puede ver la auditoría
- Todos los accesos quedan registrados en el log
- Super Admin tiene acceso total por diseño

### Información sensible
- No se registran contraseñas ni hashes
- Datos personales se manejan según políticas de privacidad
- Solo se auditan acciones operativas, no datos privados

## Consideraciones importantes

- Este módulo es **solo lectura**
- No permite modificar ni eliminar registros de auditoría
- Sirve exclusivamente para supervisión y trazabilidad
- Está destinado a gerencia, dirección y auditores internos

## Uso típico

1. **Investigación de irregularidades**
   - Seguimiento de movimientos sospechosos
   - Identificación de patrones anormales

2. **Cumplimiento normativo**
   - Demostración de controles internos
   - Preparación para auditorías externas

3. **Capacitación y mejora continua**
   - Análisis de errores frecuentes
   - Reforzamiento de buenas prácticas

4. **Resolución de conflictos**
   - Aclaración de dudas sobre movimientos
   - Respaldos para decisiones administrativas