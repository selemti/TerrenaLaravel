# Guía de Desarrollo — TerrenaLaravel
> Actualizado: Abril 2026

## Requisitos

| Herramienta | Versión | Notas |
|-------------|---------|-------|
| PHP | 8.2+ | |
| Node.js | 18+ | Para Vite |
| PostgreSQL | 9.5 | Producción — no usar features de PG12+ |
| Composer | 2.x | |
| npm | 9+ | |

---

## Instalación Inicial

```bash
# 1. Clonar repositorio
git clone https://github.com/selemti/floreantpos-selemti.git
cd TerrenaLaravel

# 2. Instalar dependencias PHP
composer install

# 3. Instalar dependencias JS
npm install

# 4. Configurar ambiente
cp .env.example .env
php artisan key:generate

# 5. Configurar BD en .env
DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5433
DB_DATABASE=pos
DB_USERNAME=postgres
DB_PASSWORD=T3rr3n4#p0s
DB_SCHEMA=selemti

# 6. Ejecutar migraciones
php artisan migrate

# 7. Poblar datos de prueba (si aplica)
php artisan db:seed
```

---

## Levantar el Ambiente de Desarrollo

### Opción A: Todo en uno (recomendado)
```bash
composer dev
```
Levanta en paralelo:
- Laravel server (puerto 8000)
- Vite/Assets (puerto 5173)  
- Queue worker
- Pail (log viewer)

### Opción B: Servidores individuales
```bash
# Terminal 1: Laravel
php artisan serve

# Terminal 2: Assets (Vite)
npm run dev

# Terminal 3: Queue
php artisan queue:listen --tries=1

# Terminal 4: Logs (opcional)
php artisan pail --timeout=0
```

### Configuración en .claude/launch.json
El archivo `.claude/launch.json` contiene las 4 configuraciones para iniciar con Claude Code.

---

## Estructura de Git

| Rama | Propósito |
|------|----------|
| `main` | Producción estable |
| `work/inicio-limpio-abril-2026` | Punto de partida oficial (abril 2026) |
| `codex/refactor-sales-exceptions` | Rama de Codex para refactors |
| `feature/*` | Nuevas funcionalidades |

**Regla:** Nunca hacer push directo a `main`. Siempre PR desde feature branch.

---

## Convenciones de Código

### Naming
- Controladores: `NombreController.php` en `App\Http\Controllers\Api\Modulo\`
- Servicios: `NombreService.php` en `App\Services\Modulo\`
- Livewire: `NombreComponent.php` en `App\Livewire\Modulo\`
- Modelos: `Nombre.php` en `App\Models\Modulo\`
- Vistas Blade: `resources/views/livewire/modulo/nombre.blade.php`

### API Response Format
```json
{
  "data": { ... },
  "meta": { "total": 0, "page": 1 },
  "message": "OK"
}
```

---

## Bases de Datos

### Local (desarrollo)
```
Host: localhost:5433
BD: pos
Usuario: postgres
Password: T3rr3n4#p0s
Schema principal: selemti
Schema Floreant: public (read-only)
```

### Producción
```
Host: 100.126.124.101:5432
BD: pos
Usuario: floreant
Password: Floreant123!
```

**NUNCA** escribir en producción directamente. Solo lectura para debugging.

---

## Comandos Útiles

```bash
# Limpiar caché
php artisan config:clear && php artisan cache:clear && php artisan view:clear

# Ver rutas
php artisan route:list --path=api

# Ejecutar tests
php artisan test

# Build assets para producción
npm run build

# Tinker (REPL)
php artisan tinker

# Recalcular costos de inventario
php artisan inventory:recalculate-costs

# Sincronizar consumo POS manualmente
php artisan pos:sync-consumption
```

---

## Multi-Agente Development

Este proyecto es desarrollado por múltiples IAs coordinadas:
- **Claude** — UI/Livewire, documentación, análisis
- **Codex** — Backend/servicios, refactors
- **Gemini** — Base de datos, SQL, optimizaciones

**Regla:** Comunicar cambios significativos antes de que otro agente modifique los mismos archivos. Los archivos en `docs/AI_COORDINATION/` sirven como canal de coordinación.

---

## Troubleshooting Común

| Problema | Solución |
|----------|---------|
| Error "no existe la relación selemti.*" | `SET search_path = selemti;` o usar `selemti.tabla` explícito |
| Vite no carga assets | Verificar que `npm run dev` está corriendo y `VITE_DEV_SERVER_URL` en .env |
| Queue jobs no se procesan | Verificar que `queue:listen` está corriendo |
| Error de permisos RBAC | `php artisan permission:cache-reset` |
| PG 9.5 no soporta función | Buscar alternativa compatible (no usar JSONB avanzado, CTEs recursivos tienen limitaciones) |

---

## Documentación de Referencia

| Documento | Ubicación | Cuándo consultar |
|-----------|----------|-----------------|
| Estado actual | `docs/2026/00_ESTADO_ACTUAL.md` | Siempre al iniciar sesión |
| Arquitectura | `docs/2026/01_ARQUITECTURA.md` | Antes de agregar nuevo módulo |
| Base de datos | `docs/2026/02_BASE_DE_DATOS.md` | Al trabajar con modelos/SQL |
| Rutas y API | `docs/2026/03_RUTAS_Y_API.md` | Al agregar endpoints o vistas |
| Módulos | `docs/2026/04_MODULOS/` | Al trabajar en módulo específico |
| Pendientes | `docs/2026/05_PENDIENTES_Y_BUGS.md` | Al iniciar nueva tarea |
| Seguridad | `docs/2026/06_SEGURIDAD_Y_ROLES.md` | Al trabajar con auth/permisos |
