# 📝 Sistema de Auditoría para Tickets

**Fecha de Implementación:** 12 de Noviembre 2025
**Implementado por:** Claude Code
**Versión:** 1.0
**Estado:** ✅ Producción

---

## 📋 RESUMEN EJECUTIVO

Sistema completo de auditoría que registra todas las operaciones realizadas sobre tickets en `selemti.audit_log`, proporcionando trazabilidad total y cumplimiento de controles internos.

### Qué Se Registra

- ✅ Usuario que ejecutó la acción
- ✅ Tipo de acción (void, close, reopen)
- ✅ Timestamp exacto
- ✅ Datos completos ANTES de la modificación
- ✅ Datos completos DESPUÉS de la modificación
- ✅ Razón de la operación
- ✅ Metadata adicional (sesión, IP, etc.)

---

## 🏗️ ARQUITECTURA

### Tabla: `selemti.audit_log`

```sql
CREATE TABLE selemti.audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES selemti.users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    reason TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para consultas rápidas
CREATE INDEX idx_audit_log_user_id ON selemti.audit_log(user_id);
CREATE INDEX idx_audit_log_action ON selemti.audit_log(action);
CREATE INDEX idx_audit_log_table_record ON selemti.audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_created_at ON selemti.audit_log(created_at);
```

### Servicio: `AlertasService`

**Archivo:** `app/Services/Caja/AlertasService.php`

```php
public function logAudit(
    string $action,
    string $tableName,
    int $recordId,
    array $oldData,
    array $newData,
    ?string $reason = null
): void
{
    DB::connection('pgsql')->table('selemti.audit_log')->insert([
        'user_id' => Auth::id(),
        'action' => $action,
        'table_name' => $tableName,
        'record_id' => $recordId,
        'old_data' => json_encode($oldData),
        'new_data' => json_encode($newData),
        'reason' => $reason,
        'ip_address' => request()->ip(),
        'user_agent' => request()->userAgent(),
        'created_at' => now(),
    ]);
}
```

---

## 📊 CONSULTAS DE AUDITORÍA

### Ver todas las modificaciones de un ticket

```sql
SELECT
    al.id,
    al.action,
    al.created_at,
    u.email AS usuario,
    al.reason,
    al.old_data,
    al.new_data
FROM selemti.audit_log al
LEFT JOIN selemti.users u ON al.user_id = u.id
WHERE al.table_name = 'ticket'
    AND al.record_id = 12345
ORDER BY al.created_at DESC;
```

### Ver todas las acciones de un usuario

```sql
SELECT
    al.id,
    al.action,
    al.table_name,
    al.record_id,
    al.reason,
    al.created_at
FROM selemti.audit_log al
WHERE al.user_id = 5
ORDER BY al.created_at DESC
LIMIT 100;
```

### Reporte diario de operaciones

```sql
SELECT
    DATE(al.created_at) AS fecha,
    al.action,
    COUNT(*) AS cantidad,
    COUNT(DISTINCT al.user_id) AS usuarios_unicos
FROM selemti.audit_log al
WHERE al.table_name = 'ticket'
    AND al.created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(al.created_at), al.action
ORDER BY fecha DESC, cantidad DESC;
```

---

**Documento Técnico Completo**
**Versión:** 1.0
**Última Actualización:** 12 de Noviembre 2025
