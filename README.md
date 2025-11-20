# Terrena POS/ERP v4.0

Sistema ERP/POS para restaurantes desarrollado con Laravel 10 + Livewire 3.

## 📋 Características Principales

- **Gestión de Inventario:** Items, recepciones, transferencias, conteos físicos, mermas
- **Recetas & Costeo:** Editor de recetas, costeo automático, versionado
- **Producción:** Órdenes de producción, planificación mise en place
- **Compras:** Solicitudes, POs, motor de replenishment (en desarrollo)
- **POS & Consumos:** Mapeo POS-Recetas, consumo automático
- **Caja Chica:** Fondos, movimientos, arqueos
- **Cortes:** Precorte, postcorte, conciliación
- **Reportes & KPIs:** Dashboards en tiempo real, ventas, stock valorizado

## 🚀 Inicio Rápido

### Requisitos

- PHP 8.3+
- PostgreSQL 14+
- Composer 2
- Node.js 20+
- Redis (para colas)

### Instalación Local

```bash
# Clonar repositorio
git clone [repo-url]
cd TerrenaLaravel

# Instalar dependencias
composer install
npm install

# Configurar ambiente
cp .env.example .env
php artisan key:generate

# Migrar y poblar BD
php artisan migrate --seed

# Compilar assets
npm run build

# Ejecutar servidor
php artisan serve
npm run dev
```

**URL Local:** http://localhost/TerrenaLaravel

## 📚 Documentación

### Documentación Principal

Toda la documentación oficial está en `docs/V4.0/`:

- **[Índice General](docs/V4.0/README.md)** - Punto de partida
- **[Stack & Convenciones](docs/V4.0/Guia/Stack.md)** - Tecnologías y estándares
- **[🚀 Deployment](docs/V4.0/Guia/Deployment.md)** - **Proceso completo Local→Producción**
- **[Arquitectura](docs/V4.0/Arquitectura/README.md)** - Stack técnico
- **[Frontend](docs/V4.0/Frontend/)** - Layout y componentes UI

### Documentación por Módulo

- **[Inventario](docs/V4.0/Inventario/)** - Items, recepciones, transferencias, conteos, mermas
- **[Recetas](docs/V4.0/Recetas/README.md)** - Editor, costeo, UOM
- **[Producción](docs/V4.0/Produccion/README.md)** - Órdenes, mise en place
- **[Compras](docs/V4.0/Purchasing/README.md)** - Solicitudes, POs, replenishment
- **[POS](docs/V4.0/POS/README.md)** - Mapeo, consumos
- **[Finanzas](docs/V4.0/Finanzas/README.md)** - Caja chica
- **[Caja](docs/V4.0/Caja/HistoricoCortes.md)** - Cortes y conciliación
- **[Reportes](docs/V4.0/Reports/README.md)** - KPIs y dashboards

### Referencias Rápidas

- **[DEPLOYMENT_CHEATSHEET.md](DEPLOYMENT_CHEATSHEET.md)** - Referencia rápida de deployment
- **[AGENTS.md](AGENTS.md)** - Lineamientos para el equipo

## 🌐 Ambientes

### Desarrollo (Local)
```
URL: http://localhost/TerrenaLaravel
Ruta: C:\xampp3\htdocs\TerrenaLaravel\
BD: PostgreSQL localhost:5433, esquema selemti
```

### Producción (Ubuntu Server)
```
URLs:
  - Red Local: http://192.168.1.235/terrena2/
  - Tailscale: http://100.126.124.101/terrena2/
Ruta: /var/www/kds/terrenaPos/
BD: PostgreSQL localhost:5432, esquema selemti
Usuario SSH: terrena@100.126.124.101
```

**⚠️ IMPORTANTE:** Antes de actualizar producción, leer **[docs/V4.0/Guia/Deployment.md](docs/V4.0/Guia/Deployment.md)**

## 🛠️ Stack Tecnológico

- **Backend:** Laravel 10, PHP 8.3, PostgreSQL 14+
- **Frontend:** Livewire 3, Alpine.js, Tailwind CSS
- **Build:** Vite, Composer, npm
- **Seguridad:** Sanctum, Spatie Permissions
- **Colas:** Redis
- **Servidor:** Apache 2.4 (Ubuntu 22.04)

## 📦 Comandos Útiles

```bash
# Desarrollo
composer run dev          # Servidor + Vite + Queue workers
php artisan serve         # Solo servidor
npm run dev              # Solo Vite (assets)

# Build producción
npm run build
composer install --no-dev --optimize-autoloader

# Cache
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Optimizar producción
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Tests
php artisan test
./vendor/bin/pint        # Code style (PSR-12)

# Migraciones
php artisan migrate
php artisan migrate:status
php artisan migrate:rollback
```

## 🔐 Seguridad

- `.env` **NO** se versiona
- Permisos manejados con Spatie Laravel Permission
- API protegida con Sanctum tokens
- Auditoría de cambios en `audit_log`

## 🤝 Contribuir

1. Leer `docs/V4.0/Guia/Stack.md` para convenciones
2. Seguir formato de commits: `<type>(<scope>): summary`
3. Actualizar documentación en `docs/V4.0/` con cada cambio
4. Ejecutar `./vendor/bin/pint` antes de PR
5. Incluir tests cuando aplique

## 📞 Soporte

**Documentación completa:** `docs/V4.0/`  
**Deployment:** `docs/V4.0/Guia/Deployment.md`  
**Troubleshooting:** Ver sección 7 de Deployment.md

---

## About Laravel

Laravel is a web application framework with expressive, elegant syntax. We believe development must be an enjoyable and creative experience to be truly fulfilling. Laravel takes the pain out of development by easing common tasks used in many web projects.

**License:** The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
