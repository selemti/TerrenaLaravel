# 🚀 DEPLOYMENT GUIDE - TRANSFERENCIAS

**Módulo**: Transferencias entre Almacenes
**Versión**: 1.0
**Fecha**: Noviembre 2025
**Ambientes**: Staging → Production

---

## 📋 PRE-REQUISITOS

### Validaciones Pre-Deployment

- [ ] Backend completado (Semana 1)
- [ ] Frontend completado (Semana 2)
- [ ] Tests passing 100% (8/8 backend + UI tests)
- [ ] Code review aprobado
- [ ] Migrations testeadas en local
- [ ] Backup de BD producción realizado

### Base de Datos Normalizada

**IMPORTANTE**: Este módulo usa la BD normalizada ubicada en:
- `BD/00.SelemTI_Normalizada_29_10_25_10_40_v0.sql`

Estructura clave:
```sql
-- ENUM mov_tipo incluye:
'RECEPCION', 'COMPRA', 'VENTA', 'CONSUMO_OP',
'AJUSTE', 'TRASPASO_IN', 'TRASPASO_OUT', 'ANULACION'

-- Tablas transfer_cab y transfer_det ya existen
-- Se agregan columnas faltantes vía migration
```

---

## 🗓️ TIMELINE DEPLOYMENT

### Viernes (Pre-deployment)
**18:00-20:00** - Preparación
- [ ] Merge a `develop`
- [ ] Tag version: `v1.1-transfers`
- [ ] Notificar stakeholders
- [ ] Preparar rollback plan

### Sábado (Staging)
**10:00-14:00** - Deploy a Staging
- [ ] Pull código a staging server
- [ ] Run migrations
- [ ] Smoke tests (30 min)
- [ ] QA completo (2h)

**14:00-15:00** - Go/No-Go Decision

### Domingo (Production)
**14:00-18:00** - Deploy a Production
- [ ] Maintenance mode ON
- [ ] Backup BD
- [ ] Deploy código
- [ ] Run migrations
- [ ] Smoke tests
- [ ] Maintenance mode OFF
- [ ] Monitoring activo (4h)

---

## 📦 DEPLOYMENT STEPS

### 1. STAGING DEPLOYMENT

#### 1.1 Preparar Código (10 min)

```bash
# En servidor staging
cd /var/www/TerrenaLaravel
git fetch origin
git checkout develop
git pull origin develop

# Verificar branch
git log --oneline -5
```

#### 1.2 Install Dependencies (5 min)

```bash
composer install --optimize-autoloader --no-dev
npm install
npm run build
```

#### 1.3 Run Migrations (5 min)

```bash
# Verificar migrations pendientes
php artisan migrate:status

# Ejecutar migration de transfers
php artisan migrate --path=database/migrations/2025_11_01_090000_complete_transfer_tables.php

# Verificar estructura
psql -h localhost -U postgres -d pos -c "\d selemti.transfer_cab"
psql -h localhost -U postgres -d pos -c "\d selemti.transfer_det"
```

**Validar columnas agregadas**:
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'transfer_cab'
ORDER BY ordinal_position;

-- Debe incluir:
-- aprobada_por, posteada_por
-- fecha_solicitada, fecha_aprobada, fecha_despachada, fecha_recibida, fecha_posteada
-- observaciones, observaciones_recepcion
```

#### 1.4 Cache & Optimize (5 min)

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize
```

#### 1.5 Verificar Permisos (5 min)

```bash
# Verificar que exista el permiso
psql -h localhost -U postgres -d pos -c "
SELECT name FROM selemti.permissions WHERE name = 'can_manage_transfers';
"

# Si no existe, crear:
psql -h localhost -U postgres -d pos -c "
INSERT INTO selemti.permissions (name, guard_name, created_at, updated_at)
VALUES ('can_manage_transfers', 'web', NOW(), NOW())
ON CONFLICT (name, guard_name) DO NOTHING;
"
```

---

### 2. SMOKE TESTS (30 min)

#### Test 1: API Health Check (2 min)

```bash
# Verificar API disponible
curl -f https://staging.terrena.com/api/health

# Verificar autenticación
TOKEN="your-test-token"
curl -H "Authorization: Bearer $TOKEN" \
  https://staging.terrena.com/api/inventory/transfers
```

#### Test 2: Crear Transferencia (5 min)

```bash
curl -X POST https://staging.terrena.com/api/inventory/transfers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "origen_almacen_id": 57,
    "destino_almacen_id": 58,
    "lineas": [
      {
        "item_id": "ITEM-TEST-001",
        "cantidad": 10,
        "uom_id": 1
      }
    ]
  }'

# Respuesta esperada:
# {
#   "ok": true,
#   "data": {
#     "transfer_id": 1,
#     "status": "SOLICITADA"
#   },
#   "message": "Transferencia creada exitosamente",
#   "timestamp": "2025-11-01T10:30:00Z"
# }
```

#### Test 3: Aprobar Transferencia (5 min)

```bash
TRANSFER_ID=1

curl -X POST https://staging.terrena.com/api/inventory/transfers/$TRANSFER_ID/approve \
  -H "Authorization: Bearer $TOKEN"

# Verificar estado
curl https://staging.terrena.com/api/inventory/transfers/$TRANSFER_ID \
  -H "Authorization: Bearer $TOKEN"

# Respuesta esperada: estado = "APROBADA"
```

#### Test 4: Workflow Completo (15 min)

```bash
# 1. Crear transferencia
# 2. Aprobar (verify stock check)
# 3. Despachar (marcar en tránsito)
# 4. Recibir (registrar cantidades)
# 5. Postear (verify mov_inv entries)

# Verificar movimientos en kardex
psql -h localhost -U postgres -d pos -c "
SELECT * FROM selemti.mov_inv
WHERE ref_tipo = 'TRANSFER' AND ref_id = $TRANSFER_ID
ORDER BY ts;
"

# Debe haber 2 registros:
# - TRANSFER_OUT (qty negativo, almacen_origen)
# - TRANSFER_IN (qty positivo, almacen_destino)
```

#### Test 5: UI Access (3 min)

```bash
# Browser tests
# 1. Navegar a https://staging.terrena.com/transfers
# 2. Verificar tabla de transferencias carga
# 3. Click "Nueva Transferencia"
# 4. Verificar wizard de 3 pasos funciona
# 5. Crear transferencia de prueba
# 6. Verificar badges de estado correctos
```

---

### 3. PRODUCTION DEPLOYMENT

#### 3.1 Pre-Deployment Checklist (15 min antes)

- [ ] Staging QA aprobado (todos los tests pasan)
- [ ] No hay bugs P0 o P1 sin resolver
- [ ] Backup de BD producción completado
- [ ] Team notificado vía Slack
- [ ] Rollback plan revisado

#### 3.2 Maintenance Mode (2 min)

```bash
php artisan down --message="Actualizando sistema - 15 minutos aprox" \
  --retry=60
```

#### 3.3 Backup Database (5 min)

```bash
# Backup completo
pg_dump -h localhost -U postgres -d pos -F c \
  -f /backups/pos_pre_transfers_$(date +%Y%m%d_%H%M%S).backup

# Verificar backup
ls -lh /backups/pos_pre_transfers_*.backup

# Test restore (dry run en staging)
# pg_restore -l /backups/pos_pre_transfers_*.backup | head -20
```

#### 3.4 Deploy Code (10 min)

```bash
cd /var/www/TerrenaLaravel

# Stash local changes (si hay)
git stash

# Pull nuevo código
git fetch origin
git checkout v1.1-transfers
git pull origin v1.1-transfers

# Install dependencies
composer install --optimize-autoloader --no-dev
npm install
npm run build

# Restore stashed config (si aplica)
# git stash pop
```

#### 3.5 Run Migrations (5 min)

```bash
# Dry run primero (en staging, ya hecho)
# php artisan migrate --pretend

# Ejecutar en producción
php artisan migrate --force

# Verificar
php artisan migrate:status
```

#### 3.6 Optimize & Clear Cache (5 min)

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize

# Verificar cache
php artisan route:list | grep transfers
```

#### 3.7 Maintenance Mode OFF (1 min)

```bash
php artisan up
```

#### 3.8 Smoke Tests Production (15 min)

Ejecutar mismos smoke tests que en staging pero contra producción:

```bash
# Health check
curl -f https://app.terrena.com/api/health

# Crear transferencia de prueba
# (usar datos de prueba reales pero obvios como "TEST-DEPLOYMENT")

# Verificar UI
# Browser: https://app.terrena.com/transfers
```

---

## 🚨 ROLLBACK PLAN

### Cuándo hacer Rollback

Ejecutar rollback SI:
- ❌ Migration falla
- ❌ Smoke test falla (API no responde, errores 500)
- ❌ UI completamente rota
- ❌ Bug P0 descubierto (bloquea funcionalidad crítica)

### Rollback Steps (10-15 min)

```bash
# 1. Maintenance mode ON
php artisan down

# 2. Restore código anterior
cd /var/www/TerrenaLaravel
git checkout v1.0-previous-stable
composer install --optimize-autoloader --no-dev
npm install
npm run build

# 3. Rollback migration SI es necesario
# SOLO si la migration causó el problema
php artisan migrate:rollback --step=1

# O restaurar backup completo (más seguro pero más lento - 15 min)
pg_restore -h localhost -U postgres -d pos -c \
  /backups/pos_pre_transfers_YYYYMMDD_HHMMSS.backup

# 4. Clear cache
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# 5. Maintenance mode OFF
php artisan up

# 6. Smoke test
curl -f https://app.terrena.com/api/health

# 7. Notificar equipo
echo "Rollback completado. Sistema restaurado a v1.0" | \
  slack-cli send -c #terrena-deployment
```

---

## 📊 MONITORING POST-DEPLOYMENT

### Primeras 4 Horas

Monitorear activamente:

#### Metrics Dashboard

```bash
# Errors en logs (cada 15 min)
tail -f storage/logs/laravel.log | grep ERROR

# Performance API (cada 30 min)
curl -w "@curl-format.txt" https://app.terrena.com/api/inventory/transfers

# DB Connections
psql -h localhost -U postgres -d pos -c "
SELECT count(*) as active_connections
FROM pg_stat_activity
WHERE datname = 'pos';
"
```

#### Queries Lentas

```bash
# Habilitar query logging temporal (solo primeras 2h)
psql -h localhost -U postgres -d pos -c "
ALTER SYSTEM SET log_min_duration_statement = 500; -- 500ms
SELECT pg_reload_conf();
"

# Revisar slow queries
tail -f /var/log/postgresql/postgresql-9.5-main.log | grep "duration:"

# Deshabilitar después de 2h
psql -h localhost -U postgres -d pos -c "
ALTER SYSTEM RESET log_min_duration_statement;
SELECT pg_reload_conf();
"
```

### Métricas de Éxito

| Métrica | Target | Cómo Medir |
|---------|--------|------------|
| **Uptime** | 100% | `curl -f https://app.terrena.com/api/health` |
| **API Response Time** | <500ms | Monitoring dashboard |
| **Error Rate** | <1% | `grep ERROR storage/logs/laravel.log | wc -l` |
| **Transferencias Creadas** | ≥1 | Query BD (primera semana) |
| **Bugs P0** | 0 | GitHub issues |

---

## ✅ SUCCESS CRITERIA

Deployment es exitoso SI:

- ✅ Todos los smoke tests pasan
- ✅ API responde <500ms
- ✅ UI funciona en desktop y mobile
- ✅ No errores 500 en logs (primeras 2h)
- ✅ Workflow completo funciona: Crear → Aprobar → Despachar → Recibir → Postear
- ✅ Movimientos en `mov_inv` se generan correctamente
- ✅ Performance no degradada vs. baseline
- ✅ No bugs P0 o P1 en primeras 4h

---

## 📞 ESCALATION

### Niveles de Soporte

**P3 (Enhancement)**
- SLA: 1 semana
- Action: Crear issue GitHub

**P2 (Minor Bug)**
- SLA: 1 día
- Action: Notificar Slack + crear issue

**P1 (Critical Bug)**
- SLA: 4 horas
- Action: Llamar Tech Lead + hotfix inmediato

**P0 (Blocker)**
- SLA: 1 hora
- Action: Llamar Tech Lead + DevOps + considerar rollback

### Contactos

- **Tech Lead**: [NOMBRE] - [TELÉFONO]
- **DevOps**: [NOMBRE] - [TELÉFONO]
- **DBA**: [NOMBRE] - [TELÉFONO]
- **Slack**: `#terrena-deployment`, `#terrena-support`

---

## 📝 POST-MORTEM

Después de deployment (Lunes siguiente):

### Checklist Post-Mortem

- [ ] Documentar issues encontrados
- [ ] Actualizar runbook con learnings
- [ ] Revisar métricas de performance
- [ ] Recopilar feedback de usuarios
- [ ] Identificar mejoras para próximo deployment
- [ ] Actualizar estimaciones si hubo retrasos

### Template Reporte

```markdown
# Post-Mortem: Deployment Transferencias v1.1

**Fecha**: YYYY-MM-DD
**Duración**: Xh Ym
**Status**: ✅ Éxito / ⚠️ Parcial / ❌ Rollback

## Métricas
- Downtime: X minutos
- Issues encontrados: X (P0: 0, P1: 0, P2: X)
- Performance: OK / Degraded

## Qué funcionó bien
- [Item 1]
- [Item 2]

## Qué mejorar
- [Item 1]
- [Item 2]

## Acciones
- [ ] [Acción 1] - Owner: [NOMBRE] - Due: [FECHA]
- [ ] [Acción 2] - Owner: [NOMBRE] - Due: [FECHA]
```

---

**Versión**: 1.0
**Última Actualización**: 31 de Octubre 2025
**Mantenido por**: DevOps Team

🚀 **¡Deployment exitoso!**
