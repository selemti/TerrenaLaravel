# Terrena Laravel · Guía de Proyecto

Este documento resume la arquitectura, dependencias y flujos principales de la aplicación Terrena construida sobre Laravel 12 y Livewire 3. Sirve como punto de partida para nuevos integrantes del equipo y como referencia para tareas de mantenimiento.

---

## 1. Requisitos del Entorno

- **PHP** 8.2+
- **Composer** 2.6+
- **Node.js** 18+ con `npm`
- **PostgreSQL** 13+ (la aplicación utiliza varios esquemas; ver configuración)
- Extensiones PHP: `pdo_pgsql`, `openssl`, `mbstring`, `intl`, `gd`, `fileinfo`
- Opcional: `psql` para consultas en consola y `make` para automatizaciones

---

## 2. Configuración Inicial

1. Instala dependencias:
   ```bash
   composer install
   npm install
   ```
2. Copia y ajusta variables de entorno:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
3. Configura la conexión a PostgreSQL en `.env`:
   ```ini
   DB_CONNECTION=pgsql
   DB_HOST=127.0.0.1
   DB_PORT=5433
   DB_DATABASE=pos
   DB_USERNAME=postgres
   DB_PASSWORD=***
   DB_SCHEMA=selemti,public
   ```
4. Ejecuta las migraciones (idempotentes):
   ```bash
   php artisan migrate
   ```
5. Verifica que todas las tablas requeridas existan:
   ```bash
   php artisan catalogs:verify-tables --details
   ```
6. Inicia los servicios de desarrollo:
   ```bash
   php artisan serve
   npm run dev
   ```
   También puedes usar el script combinado:
   ```bash
   composer run dev
   ```

---

## 3. Dependencias Destacadas

- **livewire/livewire 3.7**: Interfaces reactivas en los módulos de catálogos, inventario y recetas.
- **spatie/laravel-permission 6.21**: Gestión de roles y permisos. Las migraciones detectan tablas preexistentes para entornos migrados.
- **tymon/jwt-auth**: Autenticación API basada en JWT (pendiente de integración completa).
- **darkaonline/l5-swagger**: Generación de especificaciones OpenAPI para endpoints REST.
- Front-end: TailwindCSS, Bootstrap 5, Alpine.js, Vite.

---

## 4. Rutas Principales

| Ruta                                   | Descripción / Componente                                                                 |
|---------------------------------------|-------------------------------------------------------------------------------------------|
| `/`                                   | Página base con enlace rápido al dashboard                                               |
| `/dashboard`, `/compras`, `/inventario`, `/personal`, `/produccion`, `/recetas` | Vistas Blade estáticas incluidas en el menú principal                   |
| `/catalogos/unidades`                 | `App\Livewire\Catalogs\UnidadesIndex` (gestiona unidades desde `selemti.unidades_medida`) |
| `/catalogos/uom`                      | `App\Livewire\Catalogs\UomConversionIndex` (conversiones entre unidades)                  |
| `/catalogos/almacenes`                | `App\Livewire\Catalogs\AlmacenesIndex` (catálogo de almacenes físicos)                    |
| `/catalogos/proveedores`              | `App\Livewire\Catalogs\ProveedoresIndex`                                                  |
| `/catalogos/sucursales`               | `App\Livewire\Catalogs\SucursalesIndex`                                                   |
| `/catalogos/stock-policy`             | `App\Livewire\Catalogs\StockPolicyIndex` (políticas mín./máx. de inventario)              |
| `/inventory/items`                    | `App\Livewire\Inventory\ItemsIndex`                                                       |
| `/inventory/receptions`, `/inventory/receptions/new` | Recepciones de inventario (índice y alta)                                    |
| `/inventory/lots`                     | Gestión de lotes                                                                          |
| `/recipes`, `/recipes/editor/{id?}`   | Listado y editor interactivo de recetas                                                   |
| `/kds`                                | `App\Livewire\Kds\Board` para monitoreo en cocina                                         |
| `/caja/cortes`                        | Controlador `Api\Caja\CajaController@index` (resumen de cortes)                           |

`routes/api.php` expone endpoints REST adicionales para caja, reportes y operaciones móviles (ver documentación específica en `docs/`).

---

## 5. Módulos Clave

### 5.1 Catálogos

- **Unidades (`selemti.unidades_medida`)**: CRU mediante Livewire, respetando estructura del esquema externo.
- **Conversión de Unidades (`cat_uom_conversion`)**: Usa relaciones con `cat_unidades` y validaciones de unicidad.
- **Sucursales / Almacenes / Proveedores**: CRUD completos con filtros y paginación.
- **Políticas de Stock (`inv_stock_policy`)**: Define mínimos/máximos por ítem y sucursal; incluye validaciones combinadas.

### 5.2 Inventario

- Ítems (`items`), recepciones y lotes gestionados vía componentes Livewire. Integra reglas de negocio sobre unidades canónicas.

### 5.3 Recetas

- Editor interactivo (`RecipeEditor`) y visor (`RecipesIndex`) con soporte para componentes, pasos y costos.

### 5.4 Caja y KDS

- Controladores bajo `App\Http\Controllers\Api\Caja\` alimentan la vista de cortes y cálculos de cuadratura.
- `App\Livewire\Kds\Board` muestra el tablero de cocina en tiempo real.

---

## 6. Base de Datos

- Esquema principal: `public`. Algunas tablas leen de `selemti` (por ejemplo `selemti.unidades_medida`).
- Las migraciones de catálogos crean:
  - `cat_unidades`, `cat_uom_conversion`
  - `cat_sucursales`, `cat_almacenes`
  - `cat_proveedores`
  - `inv_stock_policy`
- Migración incremental `2025_10_19_000001_update_cat_unidades_structure` normaliza `cat_unidades` en entornos existentes.
- Comando de verificación: `php artisan catalogs:verify-tables --details`

Consulta el diccionario de datos ampliado en `docs/DATA_DICTIONARY-2025-10-17.md` y el ERD en `docs/DOC_ERD-FULL-20251017-081101.md`.

---

## 7. Scripts y Tareas Útiles

- `composer run dev`: inicia servidor HTTP, escucha de colas, visor de logs y Vite en paralelo.
- `npm run dev` / `npm run build`: compilación de activos con Vite + Tailwind.
- `php artisan migrate --graceful`: incluido en scripts de Composer para instalaciones frescas.
- `php artisan test`: ejecuta suite de pruebas (usa PHPUnit 11).
- `php artisan inspire`: comando de ejemplo.

---

## 8. Estándares y Buenas Prácticas

- Seguir PSR-12 y convenciones de Laravel para controladores, modelos y Livewire.
- Las validaciones se centralizan en Livewire o Form Requests (por ejemplo `CreatePostcorteRequest`).
- Mantener sincronizados los catálogos SQL de la carpeta `BD/` con las migraciones cuando se despliegan cambios productivos.
- Antes de desplegar, ejecutar:
  ```bash
  php artisan migrate --force
  php artisan catalogs:verify-tables
  npm run build
  ```

---

## 9. Documentación Complementaria

La carpeta `docs/` contiene auditorías, diccionarios de datos, flujos de caja y reportes de gap analysis generados en octubre 2025. Algunos archivos relevantes:

- `DOC_GENERAL-20251017-0146.md`: visión general del proyecto.
- `DOC_RUTAS_Y_CASOS_DE_USO-*.md`: mapeo detallado de endpoints.
- `WIZARD_CORTE_CAJA-*.md`: guía específica del flujo de corte de caja.

Revisa también `Documentación_full.zip` para paquetes completos por dominio.

---

## 10. Contacto y Soporte

- Para incidencias de infraestructura (DB offline, credenciales), coordinar con el área de DevOps.
- Para errores funcionales en catálogos o módulos Livewire, levantar ticket en Jira **TERR-CORE** indicando ruta, captura y pasos de reproducción.
- Mantén actualizado este documento cuando se agreguen módulos o cambien procesos críticos.

---

_Última actualización: octubre 2025._

