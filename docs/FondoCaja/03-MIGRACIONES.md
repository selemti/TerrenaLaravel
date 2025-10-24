# 03 - MIGRACIONES Y BASE DE DATOS

## 📊 Estructura de Base de Datos

**Schema:** `selemti`
**Conexión:** `pgsql`
**Motor:** PostgreSQL 9.5+

---

## 🗃️ Tablas

### 1. selemti.cash_funds

**Migración:** `2025_01_23_100000_create_cash_funds_table.php`

```sql
CREATE TABLE selemti.cash_funds (
    id BIGSERIAL PRIMARY KEY,
    sucursal_id INTEGER NOT NULL,
    fecha DATE NOT NULL,
    monto_inicial DECIMAL(12,2) NOT NULL,
    moneda VARCHAR(3) NOT NULL DEFAULT 'MXN',
    descripcion VARCHAR(255),
    estado VARCHAR(20) NOT NULL DEFAULT 'ABIERTO',
    responsable_user_id INTEGER NOT NULL,
    created_by_user_id INTEGER NOT NULL,
    closed_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT cash_funds_sucursal_id_fk
        FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id),
    CONSTRAINT cash_funds_responsable_user_id_fk
        FOREIGN KEY (responsable_user_id) REFERENCES users(id),
    CONSTRAINT cash_funds_created_by_user_id_fk
        FOREIGN KEY (created_by_user_id) REFERENCES users(id)
);

CREATE INDEX cash_funds_sucursal_id_idx ON selemti.cash_funds(sucursal_id);
CREATE INDEX cash_funds_fecha_idx ON selemti.cash_funds(fecha);
CREATE INDEX cash_funds_estado_idx ON selemti.cash_funds(estado);
```

### 2. selemti.cash_fund_movements

**Migración:** `2025_01_23_101000_create_cash_fund_movements_table.php`

```sql
CREATE TABLE selemti.cash_fund_movements (
    id BIGSERIAL PRIMARY KEY,
    cash_fund_id BIGINT NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    concepto TEXT NOT NULL,
    proveedor_nombre VARCHAR(255),
    monto DECIMAL(12,2) NOT NULL,
    metodo VARCHAR(20) NOT NULL,
    tiene_comprobante BOOLEAN NOT NULL DEFAULT FALSE,
    adjunto_path VARCHAR(500),
    estatus VARCHAR(20) NOT NULL DEFAULT 'POR_APROBAR',
    created_by_user_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT cash_fund_movements_cash_fund_id_fk
        FOREIGN KEY (cash_fund_id) REFERENCES selemti.cash_funds(id) ON DELETE CASCADE,
    CONSTRAINT cash_fund_movements_created_by_user_id_fk
        FOREIGN KEY (created_by_user_id) REFERENCES users(id)
);

CREATE INDEX cash_fund_movements_cash_fund_id_idx ON selemti.cash_fund_movements(cash_fund_id);
CREATE INDEX cash_fund_movements_tipo_idx ON selemti.cash_fund_movements(tipo);
```

### 3. selemti.cash_fund_arqueos

**Migración:** `2025_01_23_102000_create_cash_fund_arqueos_table.php`

```sql
CREATE TABLE selemti.cash_fund_arqueos (
    id BIGSERIAL PRIMARY KEY,
    cash_fund_id BIGINT NOT NULL UNIQUE,
    monto_esperado DECIMAL(12,2) NOT NULL,
    monto_contado DECIMAL(12,2) NOT NULL,
    diferencia DECIMAL(12,2) NOT NULL,
    observaciones TEXT,
    created_by_user_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT cash_fund_arqueos_cash_fund_id_fk
        FOREIGN KEY (cash_fund_id) REFERENCES selemti.cash_funds(id) ON DELETE CASCADE,
    CONSTRAINT cash_fund_arqueos_created_by_user_id_fk
        FOREIGN KEY (created_by_user_id) REFERENCES users(id)
);

CREATE UNIQUE INDEX cash_fund_arqueos_cash_fund_id_unique ON selemti.cash_fund_arqueos(cash_fund_id);
```

### 4. selemti.cash_fund_movement_audit_log

**Migración:** `2025_01_23_110000_create_cash_fund_movement_audit_log_table.php`

```sql
CREATE TABLE selemti.cash_fund_movement_audit_log (
    id BIGSERIAL PRIMARY KEY,
    movement_id BIGINT NOT NULL,
    action VARCHAR(50) NOT NULL,
    field_changed VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    observaciones TEXT,
    changed_by_user_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT audit_log_movement_id_fk
        FOREIGN KEY (movement_id) REFERENCES selemti.cash_fund_movements(id) ON DELETE CASCADE,
    CONSTRAINT audit_log_changed_by_user_id_fk
        FOREIGN KEY (changed_by_user_id) REFERENCES users(id)
);

CREATE INDEX audit_log_movement_id_idx ON selemti.cash_fund_movement_audit_log(movement_id);
CREATE INDEX audit_log_action_idx ON selemti.cash_fund_movement_audit_log(action);
```

---

## 🔄 Ejecutar Migraciones

```bash
# Ejecutar todas las migraciones pendientes
php artisan migrate

# Revertir última migración
php artisan migrate:rollback

# Revertir todas las migraciones
php artisan migrate:reset

# Refrescar BD (rollback + migrate)
php artisan migrate:refresh

# Ver estado de migraciones
php artisan migrate:status
```

---

## 📝 Datos de Prueba (Seeders)

No hay seeders implementados actualmente. Los datos deben ingresarse a través de la UI.

**Requisitos previos:**
- Usuarios en tabla `users`
- Sucursales en `selemti.cat_sucursales`

---

## 🔍 Consultas Útiles

### Fondos abiertos hoy
```sql
SELECT * FROM selemti.cash_funds
WHERE fecha = CURRENT_DATE
AND estado = 'ABIERTO';
```

### Movimientos con faltantes de comprobante
```sql
SELECT cf.id as fondo_id, cfm.*
FROM selemti.cash_fund_movements cfm
JOIN selemti.cash_funds cf ON cf.id = cfm.cash_fund_id
WHERE cf.estado = 'ABIERTO'
AND cfm.tiene_comprobante = FALSE;
```

### Fondos con diferencias en arqueo
```sql
SELECT cf.id, cf.fecha, cfa.diferencia
FROM selemti.cash_funds cf
JOIN selemti.cash_fund_arqueos cfa ON cfa.cash_fund_id = cf.id
WHERE ABS(cfa.diferencia) > 0.01
ORDER BY cf.fecha DESC;
```

### Historial de auditoría de un movimiento
```sql
SELECT
    cfmal.created_at,
    u.nombre_completo,
    cfmal.action,
    cfmal.field_changed,
    cfmal.old_value,
    cfmal.new_value
FROM selemti.cash_fund_movement_audit_log cfmal
JOIN users u ON u.id = cfmal.changed_by_user_id
WHERE cfmal.movement_id = 123
ORDER BY cfmal.created_at DESC;
```

---

## 🛠️ Mantenimiento

### Limpiar fondos de prueba
```sql
DELETE FROM selemti.cash_funds WHERE id IN (1,2,3);
-- CASCADE eliminará movimientos, arqueos y auditoría automáticamente
```

### Verificar integridad referencial
```sql
-- Movimientos huérfanos (no deberían existir)
SELECT * FROM selemti.cash_fund_movements
WHERE cash_fund_id NOT IN (SELECT id FROM selemti.cash_funds);

-- Arqueos huérfanos
SELECT * FROM selemti.cash_fund_arqueos
WHERE cash_fund_id NOT IN (SELECT id FROM selemti.cash_funds);
```

---

## 📦 Respaldo y Restauración

### Respaldar solo módulo de caja chica
```bash
pg_dump -h localhost -p 5433 -U postgres -d pos \
  -t selemti.cash_funds \
  -t selemti.cash_fund_movements \
  -t selemti.cash_fund_arqueos \
  -t selemti.cash_fund_movement_audit_log \
  > backup_caja_chica_$(date +%Y%m%d).sql
```

### Restaurar
```bash
psql -h localhost -p 5433 -U postgres -d pos < backup_caja_chica_20251023.sql
```
