# 🚀 DEPLOYMENT GUIDE - WEEKEND (NOV 1-2, 2025)

**Proyecto**: TerrenaLaravel ERP
**Fecha de Despliegue**: 1-2 de Noviembre 2025
**Alcance**: Catálogos + Recetas
**Objetivo**: Despliegue parcial para captura de datos base

---

## 📋 ÍNDICE

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Pre-requisitos](#pre-requisitos)
3. [Plan de Despliegue](#plan-de-despliegue)
4. [Sábado - Desarrollo](#sábado---desarrollo)
5. [Domingo - Deployment](#domingo---deployment)
6. [Rollback Plan](#rollback-plan)
7. [Post-Deployment](#post-deployment)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 RESUMEN EJECUTIVO

### Estrategia de Despliegue

Este fin de semana NO es un despliegue completo del sistema. Es un **despliegue estratégico parcial** con los siguientes objetivos:

**Meta Principal**:
Desplegar módulos de Catálogos y Recetas para que el personal comience a capturar datos base (sucursales, almacenes, unidades, proveedores, items, recetas) durante la semana siguiente (3-7 días de ventaja).

**Meta Secundaria**:
Validar flujo completo de deployment en producción antes del despliegue total del siguiente fin de semana (Nov 8-9).

### Módulos Incluidos

✅ **Catálogos**:
- Sucursales
- Almacenes
- Unidades de Medida
- Categorías
- Proveedores

✅ **Recetas**:
- Catálogo de Recetas
- Ingredientes de Recetas
- Cálculo de Costos (histórico con snapshots)
- BOM Implosion

❌ **NO Incluidos** (próximo fin de semana):
- Inventario completo (solo views read-only)
- Compras
- Producción
- Integración POS completa
- Reportes avanzados

### Timeline

```
VIERNES 31 OCT
└─ 18:00-24:00: Documentación final (Claude + ChatGPT)

SÁBADO 1 NOV
├─ 09:00-15:00: Desarrollo Backend (Codex)
├─ 09:00-15:00: Desarrollo Frontend (Qwen)
├─ 15:00-18:00: Code Review + Testing
└─ 18:00-20:00: Deployment a Staging

DOMINGO 2 NOV
├─ 09:00-12:00: QA en Staging
├─ 12:00-14:00: Fix bugs críticos
├─ 14:00-16:00: Deployment a Production
├─ 16:00-18:00: Smoke tests
└─ 18:00-20:00: Capacitación inicial al personal
```

---

## ✅ PRE-REQUISITOS

### Infraestructura

- [ ] Servidor de producción listo (Linux/Ubuntu 22.04)
- [ ] PostgreSQL 9.5+ instalado y corriendo
- [ ] PHP 8.2+ instalado (php-fpm + php-pgsql + php-mbstring + php-xml)
- [ ] Nginx configurado
- [ ] SSL certificate configurado (HTTPS obligatorio)
- [ ] Dominio apuntando al servidor: `app.terrena.com`

### Base de Datos

- [ ] PostgreSQL accesible desde servidor app
- [ ] Schema `selemti` creado
- [ ] Schema `public` con datos de FloreantPOS (read-only)
- [ ] Usuario con permisos adecuados:
  ```sql
  -- Crear usuario app
  CREATE USER terrena_app WITH PASSWORD 'STRONG_PASSWORD_HERE';

  -- Permisos en selemti (full access)
  GRANT ALL PRIVILEGES ON SCHEMA selemti TO terrena_app;
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA selemti TO terrena_app;
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA selemti TO terrena_app;

  -- Permisos en public (read-only)
  GRANT USAGE ON SCHEMA public TO terrena_app;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO terrena_app;
  ```

### Backups

- [ ] Backup de BD producción (pre-deployment)
  ```bash
  pg_dump -h localhost -U postgres -d pos -F c -b -v \
    -f "backup_pre_deployment_$(date +%Y%m%d_%H%M%S).backup"
  ```

- [ ] Backup de aplicación actual (si existe)
  ```bash
  tar -czf app_backup_$(date +%Y%m%d_%H%M%S).tar.gz /var/www/terrena
  ```

### Accesos

- [ ] SSH al servidor producción
- [ ] Credenciales BD producción
- [ ] Credenciales GitHub (deploy key configurado)
- [ ] Slack webhook configurado para notificaciones

---

## 📅 PLAN DE DESPLIEGUE

### Fase 1: Desarrollo (Sábado 09:00-15:00)

**Agentes en Paralelo**:

| Agente | Tareas | Output |
|--------|--------|--------|
| **Codex** | Backend (6h) | RecipeCostSnapshot, BOM Implosion, Seeders, Tests |
| **Qwen** | Frontend (6h) | Validaciones inline, Loading states, Responsive design |
| **Claude** | Coordinación | Deployment guide, Integration tests |

**Deliverables 15:00**:
- ✅ Code committed to `develop` branch
- ✅ Tests passing (100%)
- ✅ Migrations ready
- ✅ Seeders ready
- ✅ Docs updated

### Fase 2: QA (Sábado 15:00-18:00)

**Responsable**: Tech Lead + QA

- [ ] Code review de PRs de Codex y Qwen
- [ ] Merge to `develop` branch
- [ ] Ejecutar test suite completo:
  ```bash
  php artisan test --parallel
  ```
- [ ] Ejecutar Laravel Pint:
  ```bash
  ./vendor/bin/pint
  ```
- [ ] Verificar no hay console.log() o dd() olvidados
- [ ] Revisar queries N+1 con Debugbar (local)

### Fase 3: Staging Deployment (Sábado 18:00-20:00)

**Responsable**: DevOps + Tech Lead

#### 3.1 Preparar Staging

```bash
# SSH al servidor staging
ssh user@staging.terrena.com

# Navegar a directorio app
cd /var/www/terrena

# Pull latest code
git fetch origin
git checkout develop
git pull origin develop

# Install dependencies
composer install --no-dev --optimize-autoloader
npm ci
npm run build
```

#### 3.2 Ejecutar Migrations

```bash
# Backup BD staging
php artisan db:backup

# Ejecutar migrations
php artisan migrate --force

# Verificar tablas creadas
php artisan tinker
>>> \DB::connection('pgsql')->select("SELECT table_name FROM information_schema.tables WHERE table_schema = 'selemti' ORDER BY table_name;");
```

#### 3.3 Ejecutar Seeders

```bash
# Seeders de producción
php artisan db:seed --class=CatalogosProductionSeeder --force
php artisan db:seed --class=RecipesProductionSeeder --force
```

#### 3.4 Verificar Deployment

```bash
# Clear cache
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Queue restart
php artisan queue:restart

# Verificar logs
tail -f storage/logs/laravel.log
```

#### 3.5 Smoke Tests (Manual)

**Catálogos**:
- [ ] Acceder a `/catalogs/sucursales` - Debe mostrar lista
- [ ] Crear nueva sucursal - Debe guardar correctamente
- [ ] Editar sucursal - Debe actualizar
- [ ] Validaciones funcionan (RFC inválido debe rechazarse)

**Recetas**:
- [ ] Acceder a `/recipes` - Debe mostrar lista
- [ ] Crear nueva receta - Debe guardar
- [ ] Agregar ingredientes - Debe guardar detalles
- [ ] Calcular costo - Endpoint `/api/recipes/{id}/cost` debe responder

**API**:
```bash
# Test API Catálogos
curl -X GET "https://staging.terrena.com/api/catalogs/sucursales" \
  -H "Authorization: Bearer TOKEN" \
  -H "Accept: application/json"

# Test API Recetas
curl -X GET "https://staging.terrena.com/api/recipes" \
  -H "Authorization: Bearer TOKEN" \
  -H "Accept: application/json"
```

### Fase 4: QA en Staging (Domingo 09:00-12:00)

**Responsable**: QA Team + Users

**Test Cases**:

| ID | Módulo | Caso de Prueba | Resultado Esperado |
|----|--------|----------------|-------------------|
| TC-001 | Sucursales | Crear sucursal válida | ✅ Guarda correctamente |
| TC-002 | Sucursales | RFC duplicado | ❌ Muestra error "RFC ya existe" |
| TC-003 | Almacenes | Crear almacén sin sucursal | ❌ Muestra error "Sucursal requerida" |
| TC-004 | Unidades | Listar unidades base | ✅ Muestra KG, LT, PZ |
| TC-005 | Proveedores | RFC inválido | ❌ Muestra error "RFC inválido" |
| TC-006 | Recetas | Crear receta sin ingredientes | ⚠️ Permite pero muestra warning |
| TC-007 | Recetas | Calcular costo en fecha pasada | ✅ Usa snapshot si existe |
| TC-008 | Recetas | Implodir BOM receta compuesta | ✅ Retorna solo items base |
| TC-009 | API | Rate limiting (61 req/min) | ❌ Retorna 429 Too Many Requests |
| TC-010 | Auth | Login con credenciales inválidas | ❌ Retorna 401 Unauthorized |

**Reportar Bugs**:
- Crear issues en GitHub con label `bug` + `weekend-deployment`
- Prioridad: `P0` (blocker), `P1` (critical), `P2` (minor)
- Solo bugs P0 y P1 se fixean antes de deployment

### Fase 5: Bug Fixing (Domingo 12:00-14:00)

**Responsable**: Codex + Qwen

**Workflow**:
```bash
# Crear branch para fix
git checkout develop
git pull origin develop
git checkout -b hotfix/bug-description

# Fix bug
# ... code changes ...

# Test
php artisan test tests/Feature/BugTest.php

# Commit
git add .
git commit -m "fix(module): Description of fix"

# Push y crear PR
git push origin hotfix/bug-description

# Fast-track review
# Merge to develop
# Deploy to staging
```

**Criterio de Go/No-Go**:
- ✅ **GO**: Cero bugs P0, máximo 2 bugs P1 (con workaround documentado)
- ❌ **NO-GO**: Algún bug P0 sin resolver, >2 bugs P1, funcionalidad crítica rota

### Fase 6: Production Deployment (Domingo 14:00-16:00)

**Responsable**: DevOps + Tech Lead

#### 6.1 Pre-Deployment Checklist

- [ ] Staging QA completado (✅ GO decision)
- [ ] Backup de BD producción creado
- [ ] Backup de aplicación actual creado
- [ ] Notificación en Slack: "🚀 Deployment iniciando en 5 minutos"
- [ ] Usuario admin creado en BD producción
- [ ] Credenciales `.env` listas

#### 6.2 Ejecutar Deployment

```bash
# SSH al servidor producción
ssh user@app.terrena.com

# Poner aplicación en mantenimiento
cd /var/www/terrena
php artisan down --message="Actualizando sistema. Volvemos en 15 minutos." --retry=60

# Pull código
git fetch origin
git checkout main
git pull origin main

# Install dependencies
composer install --no-dev --optimize-autoloader
npm ci
npm run build

# Ejecutar migrations
php artisan migrate --force

# Ejecutar seeders (solo si BD está vacía)
php artisan db:seed --class=CatalogosProductionSeeder --force

# Clear + cache
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache

# Queue restart
php artisan queue:restart

# Verificar permisos
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Levantar aplicación
php artisan up
```

#### 6.3 Post-Deployment Verification

**Smoke Tests (Automatizados)**:
```bash
# Script: tests/smoke_tests.sh
#!/bin/bash

BASE_URL="https://app.terrena.com"
TOKEN="your-token-here"

# Test 1: Health check
curl -f "$BASE_URL/api/health" || exit 1

# Test 2: API Catálogos
curl -f -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/catalogs/sucursales" || exit 1

# Test 3: API Recetas
curl -f -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/recipes" || exit 1

echo "✅ Smoke tests passed"
```

**Manual Verification**:
- [ ] Login con usuario admin funciona
- [ ] Dashboard carga sin errores
- [ ] Módulo Catálogos accesible
- [ ] Módulo Recetas accesible
- [ ] Crear catálogo funciona
- [ ] Crear receta funciona
- [ ] Logs no muestran errores críticos

#### 6.4 Notificaciones

```bash
# Slack notification
curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "🎉 Deployment completado exitosamente!",
    "attachments": [
      {
        "color": "good",
        "fields": [
          {"title": "Ambiente", "value": "Producción", "short": true},
          {"title": "Versión", "value": "v1.0-weekend", "short": true},
          {"title": "Módulos", "value": "Catálogos, Recetas", "short": false}
        ]
      }
    ]
  }'
```

### Fase 7: Capacitación (Domingo 18:00-20:00)

**Responsable**: Tech Lead + Key Users

**Agenda**:

| Tiempo | Tema | Responsable |
|--------|------|-------------|
| 18:00-18:15 | Introducción al sistema | Tech Lead |
| 18:15-18:45 | Catálogos (demo + hands-on) | Key User 1 |
| 18:45-19:15 | Recetas (demo + hands-on) | Key User 2 |
| 19:15-19:45 | Sesión práctica (captura real) | Todos |
| 19:45-20:00 | Q&A + cierre | Tech Lead |

**Materiales**:
- [ ] Manual de usuario (PDF)
- [ ] Video tutorial (5 min)
- [ ] Guía rápida (1 página)
- [ ] FAQ documento

**Usuarios a Capacitar**:
- Gerente de Operaciones (admin)
- Chef Ejecutivo (recetas)
- Encargado de Compras (catálogos)
- Staff de soporte (1-2 personas)

---

## 🔄 ROLLBACK PLAN

### Escenarios de Rollback

**ROLLBACK si**:
- Sistema completamente inaccesible (500 errors persistentes)
- Pérdida de datos críticos
- Vulnerabilidad de seguridad descubierta
- Performance degradation >50%

### Procedimiento de Rollback

```bash
# 1. Poner app en mantenimiento
php artisan down

# 2. Restaurar código anterior
git checkout main
git reset --hard COMMIT_HASH_PREVIOUS  # Ver con git log

# 3. Restaurar BD (si es necesario)
pg_restore -h localhost -U terrena_app -d pos \
  backup_pre_deployment_20251101_140000.backup

# 4. Reinstalar dependencies
composer install --no-dev --optimize-autoloader

# 5. Clear cache
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# 6. Levantar app
php artisan up

# 7. Notificar
# Slack: "⚠️ Rollback ejecutado. Investigando issue."
```

**Tiempo estimado de rollback**: 10-15 minutos

**Post-Rollback**:
- Analizar logs para identificar causa raíz
- Documentar issue en GitHub
- Planificar fix para siguiente deployment
- Comunicar a stakeholders

---

## 📊 POST-DEPLOYMENT

### Monitoring (Primera Semana)

**Diario** (Lunes-Viernes):
- [ ] Revisar logs de errores: `tail -n 100 storage/logs/laravel.log`
- [ ] Verificar uso de BD: `SELECT count(*) FROM selemti.cat_sucursales;`
- [ ] Verificar usuarios activos: `SELECT count(*) FROM users WHERE last_login > NOW() - INTERVAL '24 hours';`
- [ ] Revisar performance: Response time promedio <500ms

**Métricas Clave**:
```sql
-- Catálogos creados
SELECT
  (SELECT COUNT(*) FROM selemti.cat_sucursales) as sucursales,
  (SELECT COUNT(*) FROM selemti.cat_almacenes) as almacenes,
  (SELECT COUNT(*) FROM selemti.cat_proveedores) as proveedores,
  (SELECT COUNT(*) FROM selemti.items) as items;

-- Recetas creadas
SELECT
  COUNT(*) as total_recetas,
  COUNT(*) FILTER (WHERE activo = true) as activas,
  AVG(ARRAY_LENGTH(detalles, 1)) as avg_ingredientes_per_recipe
FROM selemti.recipes;

-- Snapshots creados
SELECT
  COUNT(*) as total_snapshots,
  COUNT(DISTINCT recipe_id) as unique_recipes,
  COUNT(*) FILTER (WHERE reason = 'MANUAL') as manual,
  COUNT(*) FILTER (WHERE reason = 'AUTO_THRESHOLD') as auto
FROM selemti.recipe_cost_snapshots;
```

### Feedback Loop

**Canal de Soporte**:
- Slack: `#terrena-support`
- Email: `soporte@terrena.com`
- WhatsApp: (solo emergencias)

**Categorización de Issues**:
- 🔴 **P0 (Blocker)**: Sistema inaccesible, pérdida de datos
  - SLA: 1 hora
- 🟠 **P1 (Critical)**: Funcionalidad importante no funciona
  - SLA: 4 horas
- 🟡 **P2 (Minor)**: Bug menor, workaround disponible
  - SLA: 1 día
- 🟢 **P3 (Enhancement)**: Mejora, no bloqueante
  - SLA: 1 semana

### Optimizaciones (Durante la Semana)

**Performance**:
- [ ] Agregar índices si queries lentas detectadas
- [ ] Configurar Redis cache si necesario
- [ ] Optimizar queries N+1 identificadas

**UX**:
- [ ] Ajustar validaciones según feedback
- [ ] Mejorar mensajes de error si confusos
- [ ] Agregar tooltips donde usuarios pidan ayuda

**Data**:
- [ ] Limpiar datos de prueba si existen
- [ ] Validar integridad de catálogos capturados
- [ ] Corregir duplicados si se detectan

---

## 🐛 TROUBLESHOOTING

### Error 500 - Internal Server Error

**Diagnóstico**:
```bash
# Ver últimos 50 errores
tail -n 50 storage/logs/laravel.log | grep ERROR

# Ver errores Nginx
tail -n 50 /var/log/nginx/error.log
```

**Causas comunes**:
1. **Permisos incorrectos**:
   ```bash
   chmod -R 775 storage bootstrap/cache
   chown -R www-data:www-data storage bootstrap/cache
   ```

2. **Cache corrupto**:
   ```bash
   php artisan cache:clear
   php artisan config:clear
   ```

3. **DB connection failed**:
   ```bash
   # Verificar .env
   cat .env | grep DB_

   # Test connection
   php artisan tinker
   >>> \DB::connection('pgsql')->getPdo();
   ```

### Error 419 - CSRF Token Mismatch

**Diagnóstico**:
```bash
# Verificar session driver
cat .env | grep SESSION_DRIVER

# Verificar permisos storage/framework/sessions
ls -la storage/framework/sessions/
```

**Fix**:
```bash
# Clear sessions
rm -rf storage/framework/sessions/*

# Regenerate app key (solo si es nuevo deployment)
php artisan key:generate

# Clear config
php artisan config:clear
```

### Error 429 - Too Many Requests

**Diagnóstico**:
Usuario excedió rate limit (60 req/min).

**Fix**:
```php
// Ajustar en app/Http/Kernel.php
'throttle:120,1'  // 120 req/min (temporal)
```

### Migrations Fail

**Diagnóstico**:
```bash
php artisan migrate --pretend  # Ver SQL sin ejecutar
```

**Causas comunes**:
1. **Tabla ya existe**:
   ```sql
   DROP TABLE IF EXISTS selemti.recipe_cost_snapshots;
   ```

2. **FK constraint falla**:
   ```sql
   -- Verificar datos huérfanos
   SELECT * FROM selemti.recipe_cost_snapshots
   WHERE recipe_id NOT IN (SELECT id FROM selemti.recipes);
   ```

### Performance Degradation

**Diagnóstico**:
```bash
# Queries lentas
php artisan telescope:install  # Si usas Telescope

# Manualmente con Debugbar (local)
composer require barryvdh/laravel-debugbar --dev
```

**Queries comunes lentas**:
1. **N+1 en listados**:
   ```php
   // Mal
   $recipes = Receta::all();
   foreach ($recipes as $r) {
       echo $r->categoria->nombre;  // N+1
   }

   // Bien
   $recipes = Receta::with('categoria')->get();
   ```

2. **Sin índices**:
   ```sql
   -- Agregar índice
   CREATE INDEX idx_recipes_activo ON selemti.recipes(activo);
   ```

---

## 📝 CHECKLIST FINAL PRE-GO-LIVE

### Código

- [ ] Todas las PRs merged a `main`
- [ ] Tests passing (100%)
- [ ] Code review completado
- [ ] Laravel Pint ejecutado
- [ ] No console.log() ni dd() en código
- [ ] `.env.example` actualizado

### Base de Datos

- [ ] Backup pre-deployment creado
- [ ] Migrations ejecutadas sin errores
- [ ] Seeders ejecutados correctamente
- [ ] Índices creados
- [ ] Foreign keys verificadas

### Infraestructura

- [ ] SSL certificate válido
- [ ] Nginx configurado
- [ ] PHP-FPM corriendo
- [ ] PostgreSQL accesible
- [ ] Queue worker corriendo
- [ ] Cron jobs configurados (si aplica)

### Seguridad

- [ ] `.env` con credenciales seguras (no default)
- [ ] `APP_DEBUG=false` en producción
- [ ] `APP_ENV=production`
- [ ] CORS configurado correctamente
- [ ] Rate limiting activo

### Documentación

- [ ] API docs actualizados
- [ ] Manual de usuario listo
- [ ] Deployment guide (este doc) revisado
- [ ] Rollback plan documentado
- [ ] Troubleshooting guide disponible

### Comunicación

- [ ] Stakeholders notificados del deployment
- [ ] Usuarios capacitados
- [ ] Soporte disponible (Slack/WhatsApp)
- [ ] Slack webhook configurado

### Monitoreo

- [ ] Logs accesibles
- [ ] Métricas definidas
- [ ] Alertas configuradas (opcional)
- [ ] Dashboard de salud (opcional)

---

## 🎉 SUCCESS CRITERIA

El deployment se considera **exitoso** si:

✅ Sistema accesible en `https://app.terrena.com`
✅ Login funciona correctamente
✅ Módulo Catálogos completamente funcional
✅ Módulo Recetas completamente funcional
✅ API responde correctamente (5 endpoints Catálogos + 7 Recetas)
✅ Performance aceptable (<500ms response time promedio)
✅ Cero errores críticos en logs (primeras 2 horas)
✅ Personal puede capturar datos sin bloqueos
✅ Backup y rollback plan probados

---

## 📞 CONTACTOS

| Rol | Nombre | Contacto | Disponibilidad |
|-----|--------|----------|----------------|
| Tech Lead | [NOMBRE] | +52 XXX XXX XXXX | 24/7 |
| DevOps | [NOMBRE] | +52 XXX XXX XXXX | Sáb-Dom 8am-10pm |
| QA Lead | [NOMBRE] | +52 XXX XXX XXXX | Sáb-Dom 9am-6pm |
| Product Owner | [NOMBRE] | +52 XXX XXX XXXX | On-demand |

---

## 📚 REFERENCIAS

- **CLAUDE.md**: Arquitectura del proyecto
- **API_CATALOGOS.md**: Specs API Catálogos
- **API_RECETAS.md**: Specs API Recetas
- **VALIDACIONES_EXISTENTES.md**: Matriz de validaciones
- **PROMPT_QWEN_FRONTEND_SABADO.md**: Plan Frontend Saturday
- **PROMPT_CODEX_BACKEND_SABADO.md**: Plan Backend Saturday

---

**Última Actualización**: 31 de octubre de 2025
**Versión**: 1.0
**Mantenido por**: Tech Team TerrenaLaravel
