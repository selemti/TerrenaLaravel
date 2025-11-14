# Auditoría y Limpieza de Base de Datos PostgreSQL

**Proyecto**: TerrenaLaravel
**Base de datos**: pos @ localhost:5433
**Fecha**: 2 Noviembre 2025

---

## Resumen Ejecutivo

Se realizó una auditoría exhaustiva de la base de datos PostgreSQL que reveló **26 grupos de tablas duplicadas** y **4 tablas legacy explícitas** (con sufijo `_legacy`). El análisis detectó aproximadamente **50 tablas legacy vacías** que pueden eliminarse de forma segura después de validación de código.

### Hallazgos Principales

- **Total tablas**: 249 (142 en `selemti`, 107 en `public`)
- **Tablas duplicadas**: 26 grupos identificados
- **Tablas legacy vacías**: ~50 candidatas para eliminación
- **Tablas con datos**: 4 requieren migración o revisión
  - `selemti.auditoria` (72 registros)
  - `selemti.users` (1 registro)
  - `selemti.roles` (7 registros - Spatie RBAC actual)
  - `selemti.model_has_roles` (1 registro - Spatie RBAC actual)

---

## Archivos de la Auditoría

### 1. Reportes Generados

| Archivo | Descripción |
|---------|-------------|
| `REPORTE_AUDITORIA_DUPLICADOS.md` | Reporte inicial automático (9 grupos) |
| `REPORTE_AUDITORIA_DUPLICADOS_COMPLETO.md` | **Reporte exhaustivo manual (26 grupos)** ⭐ |
| `PLAN_LIMPIEZA_SAFE.md` | Plan de limpieza con análisis de riesgos |
| `legacy_code_refs.txt` | Salida completa de grep (referencias en código) |

### 2. Scripts SQL

| Archivo | Descripción |
|---------|-------------|
| `drop_legacy_safe.sql` | Script para eliminar tablas legacy (con dry-run) |
| `validate_cleanup.sql` | Validación post-limpieza |

### 3. Scripts Bash

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| `audit_legacy_references.sh` | `scripts/` | Busca referencias a tablas legacy en código |

### 4. Comando Artisan

```bash
php artisan db:audit-duplicates
```

Genera reporte automático de duplicados en `docs/BD/REPORTE_AUDITORIA_DUPLICADOS.md`.

---

## Categorías de Tablas Duplicadas

### 1. Autenticación (3 grupos)
- **Usuarios**: `public.users`, `selemti.users`, `selemti.usuario`
- **Roles**: `selemti.roles`, `selemti.rol`
- **Asignación roles**: `selemti.model_has_roles`, `selemti.user_roles`

### 2. Catálogos Maestros (5 grupos)
- **Sucursales**: `cat_sucursales`, `sucursal`
- **Almacenes**: `cat_almacenes`, `almacen`, `bodega`
- **Proveedores**: `cat_proveedores`, `proveedor`
- **Unidades**: `cat_unidades`, `unidad_medida_legacy`, `unidades_medida_legacy`
- **Conversiones**: `cat_uom_conversion`, `conversiones_unidad_legacy`, `uom_conversion_legacy`

### 3. Inventario (4 grupos)
- **Items**: `items`, `insumo`
- **Lotes**: `inventory_batch`, `lote`
- **Mermas**: `inventory_wastes`, `merma`
- **Políticas**: `inv_stock_policy`, `stock_policy`

### 4. Transferencias (2 grupos)
- **Cabecera**: `transfer_cab`, `traspaso_cab`
- **Detalle**: `transfer_det`, `traspaso_det`

### 5. Producción (3 grupos)
- **Órdenes cabecera**: `production_orders`, `op_cab`, `op_produccion_cab`, `prod_cab`, `sol_prod_cab` (5 tablas!)
- **Órdenes detalle**: `production_order_inputs`, `production_order_outputs`, `op_insumo`, `prod_det`, `sol_prod_det`
- **Yield**: `op_yield`

### 6. Recetas (3 grupos)
- **Cabecera**: `receta`, `receta_cab`
- **Detalle**: `receta_det`, `receta_insumo`
- **Versiones**: `recipe_versions`, `receta_version`, `receta_shadow`

### 7. Caja Chica (4 grupos)
- **Fondos**: `cash_funds`, `caja_fondo`
- **Movimientos**: `cash_fund_movements`, `caja_fondo_mov`
- **Arqueos**: `cash_fund_arqueos`, `caja_fondo_arqueo`
- **Ajustes**: `caja_fondo_adj`

### 8. Auditoría (1 grupo)
- **Logs**: `audit_log_global`, `auditoria`, `audit_log`

---

## Pasos para Ejecutar la Limpieza

### PASO 1: Backup Completo

```bash
# Crear backup antes de cualquier operación
pg_dump -h localhost -p 5433 -U postgres -d pos -F c \
  -f "pos_backup_$(date +%Y%m%d_%H%M%S).dump"
```

### PASO 2: Validar Referencias en Código

```bash
cd /c/xampp3/htdocs/TerrenaLaravel

# Ejecutar script de auditoría
bash scripts/audit_legacy_references.sh > docs/BD/legacy_code_refs.txt

# Revisar output
cat docs/BD/legacy_code_refs.txt
```

**IMPORTANTE**: El script encontró que la mayoría de "referencias" son a **campos FK** (como `sucursal_id`), NO a las tablas legacy. Requiere validación manual para confirmar.

### PASO 3: Dry-Run del Script SQL

```bash
# Ejecutar con ROLLBACK para ver qué haría sin hacer cambios
psql -h localhost -p 5433 -U postgres -d pos \
  -f docs/BD/drop_legacy_safe.sql
```

El script está configurado con `ROLLBACK` por defecto, por lo que NO hará cambios reales. Solo mostrará mensajes `NOTICE` de lo que haría.

### PASO 4: Revisar Output del Dry-Run

Buscar:
- ✅ NOTICE de eliminaciones exitosas
- ⚠️ WARNING de FKs o datos encontrados
- ❌ ERROR que detendría la ejecución

### PASO 5: Ejecutar Limpieza Real

Solo después de dry-run exitoso:

1. Editar `docs/BD/drop_legacy_safe.sql`
2. Cambiar `ROLLBACK;` por `COMMIT;`
3. Ejecutar de nuevo:

```bash
psql -h localhost -p 5433 -U postgres -d pos \
  -f docs/BD/drop_legacy_safe.sql
```

### PASO 6: Validar Limpieza

```bash
# Ejecutar validación post-limpieza
psql -h localhost -p 5433 -U postgres -d pos \
  -f docs/BD/validate_cleanup.sql
```

Debe mostrar:
- ✅ 0 tablas legacy restantes
- ✅ 5 tablas `cat_*` existentes
- ✅ 0 foreign keys rotas
- ✅ Tablas de operaciones actuales presentes

### PASO 7: Tests de Aplicación

```bash
cd /c/xampp3/htdocs/TerrenaLaravel

# Ejecutar tests
php artisan test

# Verificar Livewire
php artisan serve
# Probar componentes en navegador

# Monitorear logs
php artisan pail
```

---

## Tablas a Mantener Post-Limpieza

### Catálogos (cat_*)
```
cat_sucursales
cat_almacenes
cat_proveedores
cat_unidades
cat_uom_conversion
```

### Operaciones Actuales
```
items, inventory_batch, mov_inv
production_orders, production_order_inputs, production_order_outputs
recipe_versions, recipe_version_items
cash_funds, cash_fund_movements
purchase_orders, purchase_order_lines
recepcion_cab, recepcion_det
```

### Spatie Laravel Permission
```
roles, permissions
model_has_roles, model_has_permissions, role_has_permissions
```

### POS Floreant (READ-ONLY)
```
public.* (107 tablas - NO TOCAR)
```

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| FKs CASCADE eliminan datos | BAJA | CRÍTICO | Backup + dry-run + validación |
| Código roto por refs no detectadas | MEDIA | ALTO | Grep exhaustivo + tests |
| Confusión campos vs tablas | ALTA | MEDIO | Análisis manual detallado |
| Pérdida de auditoría | BAJA | ALTO | NO eliminar `auditoria` (72 regs) |

---

## Tareas Pendientes

### Antes de Limpieza
- [ ] Backup completo ejecutado y verificado
- [ ] Validación de código completada manualmente
- [ ] Dry-run exitoso sin errores
- [ ] Coordinación con Gemini y Codex

### Durante Limpieza
- [ ] Ejecutar script con COMMIT
- [ ] Monitorear output en tiempo real
- [ ] Detener si aparecen errores

### Después de Limpieza
- [ ] Validación post-limpieza exitosa
- [ ] Tests de Laravel pasados
- [ ] Livewire components funcionando
- [ ] Logs sin errores críticos
- [ ] Migrar `selemti.auditoria` (72 registros)
- [ ] Documentación actualizada

---

## Coordinación Multi-Agente

Este proyecto usa múltiples agentes AI:

- **Claude Code**: UI/UX, Livewire, esta auditoría
- **Codex**: Backend services, business logic
- **Gemini CLI**: Operaciones de BD directas

**IMPORTANTE**: Actualizar `.gemini/WORK_ASSIGNMENTS.md` con resultado de limpieza.

---

## Comandos Útiles

### Consultas Directas

```sql
-- Contar tablas por schema
SELECT schemaname, COUNT(*) FROM pg_tables
WHERE schemaname IN ('selemti', 'public')
GROUP BY schemaname;

-- Listar tablas cat_*
SELECT tablename FROM pg_tables
WHERE schemaname = 'selemti' AND tablename LIKE 'cat_%'
ORDER BY tablename;

-- Verificar FKs a tabla específica
SELECT tc.table_name, tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
WHERE ccu.table_name = 'sucursal' -- cambiar nombre
  AND tc.constraint_type = 'FOREIGN KEY';

-- Contar registros en tabla
SELECT COUNT(*) FROM selemti.auditoria;
```

### Laravel Artisan

```bash
# Re-ejecutar auditoría
php artisan db:audit-duplicates

# Migrations
php artisan migrate:status

# Tinker para queries
php artisan tinker
>>> DB::connection('pgsql')->table('selemti.auditoria')->count();
```

---

## Contacto y Soporte

Para dudas sobre esta auditoría:
1. Revisar `REPORTE_AUDITORIA_DUPLICADOS_COMPLETO.md` (exhaustivo)
2. Consultar `PLAN_LIMPIEZA_SAFE.md` (riesgos y pasos)
3. Ejecutar `php artisan db:audit-duplicates` (reporte actualizado)

---

**Última actualización**: 2 Noviembre 2025
**Versión**: 1.0
**Estado**: Auditoría completa, limpieza pendiente de ejecución
