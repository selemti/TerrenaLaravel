# Terrena · Status Integral del Proyecto (V2)

_Actualizado: octubre 2025_

---

## 1. Resumen Ejecutivo

- **Nombre del proyecto:** Terrena (TerrenaLaravel / TerrenaUI)
- **Objetivo:** Plataforma unificada para operaciones de restaurantes Terrena (catálogos maestros, inventarios, recetas, caja/KDS, reportes).
- **Estado general:** Base de datos y catálogos principales funcionales; interfaces Livewire operativas con validaciones; módulos de inventario/recepciones y recetas aún dependen de vistas/tablas externas; autenticación JWT y reportes requieren consolidación. Documentación dispersa entre la carpeta `docs/` y repos externos en D:\.

---

## 2. Stack Tecnológico

| Capa | Detalle |
|------|---------|
| Backend | Laravel 12.x (PHP 8.2.12), Livewire 3.7, Spatie Permission 6.21, Tymon JWT-Auth 2.2 |
| Frontend | Blade + Livewire, TailwindCSS 3.x, Bootstrap 5.3, Alpine.js 3.x, Vite 7 |
| Base de datos | PostgreSQL 9.5 (esquemas `public` y `selemti`), vistas auxiliares requeridas (`selemti.v_stock_resumen`, `selemti.v_kardex_item`, etc.) |
| Infra/otros | Composer 2.8, npm 10+, almacenamiento local `storage/app/public`, endpoints API REST/legacy, documentación en `docs/`, `BD/`, y carpetas externas (`D:\Tavo\2025\UX\...`). |

---

## 3. Convenciones y Patrones

- **Estilo:** PSR-12, clases en PascalCase, archivos Blade en snake-case, controladores bajo `App\Http\Controllers\...`, Livewire en `App\Livewire\...`.
- **Validaciones:** Reglas en componentes Livewire (`$rules`, `validate()`); para HTTP tradicionales se usan Form Requests (ej. `CreatePostcorteRequest`). Mensajería de errores vía `session()->flash()` y respuestas JSON consistentes (`ok`, `error`, `message`).
- **Patrones:** Eloquent como ORM primario, servicios puntuales (`App\Services\Inventory\ReceptionService`), sin patrón Repository formal.
- **Front:** Combina Blade estático (dashboard, inventario, compras, etc.) con componentes Livewire reusando `layouts/terrena.blade.php` y `layouts/app.blade.php`. CSS adicional en `public/assets/css`, scripts vanilla/Alpine en `public/assets/js` y `public/vendor` (assets reempaquetados de Livewire v3).

---

## 4. Estructura Actual del Código

| Ruta | Contenido Relevante |
|------|---------------------|
| `app/Livewire/Catalogs/` | CRUDs de catálogos (unidades, conversiones, proveedores, sucursales, almacenes, políticas de stock). |
| `app/Livewire/Inventory/` | Panel de inventario (`ItemsIndex`), recepciones (`ReceptionsIndex`, `ReceptionCreate`), lotes. Dependencias en vistas SQL `selemti.*`. |
| `app/Livewire/Recipes/` | Listado y editor básicos con datos demo si la tabla `recipes` no existe. |
| `app/Livewire/Kds/` | Tablero KDS placeholder. |
| `app/Http/Controllers/Api/` | Endpoints para caja (precortes/postcortes/sesiones), inventario REST, unidades y reportes. Incluye controladores legacy (`caja/*.php`). |
| `app/Models/` | Modelos Eloquent para catálogos (`Catalogs\*`), inventario (`Inv\Item`, `Inventory\*`), caja (`Caja\*`), recetas (`Rec\*`). Algunos apuntan a esquemas externos (`selemti.unidades_medida`). |
| `app/Services/Inventory/ReceptionService.php` | Servicio transaccional para recepciones (escribe en `recepcion_cab`, `recepcion_det`, `inventory_batch`, `mov_inv`). |
| `database/migrations/` | Migraciones idempotentes (verificación `Schema::hasTable`). Nuevas tablas: `cat_*`, `inv_stock_policy`, ajustes a `cat_unidades`. |
| `routes/web.php` | Menú principal con Blade y Livewire, rutas de catálogos/inventario/recetas/KDS/caja. |
| `routes/api.php` | APIs REST + endpoints legacy (`/legacy/*`), ping/health y módulo de reportes. |
| `public/assets/` | JS y CSS personalizados para caja/terrena. |
| `docs/` | Auditorías y diccionarios (octubre 2025), muchos con inconsistencias. |
| `BD/` | Scripts SQL históricos (deploys, backups). |

### Recursos Externos (D:\Tavo\2025\UX\*)

- **Inventarios:** Plantillas CSV/XLSX, data dictionary, scripts `selemti_deploy_inventarios_*.sql` (v2/v3). Falta integrar con migraciones oficiales.
- **Cortes:** Documentos de definición, PHP legacy (`precorte_*`), SQL optimizados (`precorte_conciliacion*.sql`), dashboards. Sirven como referencia para reimplementar en Laravel.
- **00. Recetas:** Análisis funcional, actas técnicas, SRS, UML, queries SQL (`03_modulo_recetas.sql`), documentación V1. Pendiente adaptar a nuevas entidades `recipes`, `recipe_items`, etc.

---

## 5. Estado de Módulos

| Módulo | Alcance | Implementado | Pendiente / Riesgos |
|--------|---------|--------------|----------------------|
| **Catálogos** (`cat_unidades`, `cat_uom_conversion`, `cat_proveedores`, `cat_sucursales`, `cat_almacenes`, `inv_stock_policy`) | CRUD Livewire con validaciones y paginación. | ✔ Migraciones y UI listas. | Poblar datos iniciales, pruebas de integridad, sincronizar con sistemas externos. |
| **Unidades (selemti)** | Gestión directa sobre `selemti.unidades_medida`. | ✔ Componentes operativos. | Asegurar permisos cross-schema, documentar impacto en POS legado. |
| **Inventario – Dashboard** | KPIs, filtros y movimientos rápidos basados en vistas `selemti.v_stock_resumen` y `selemti.v_kardex_item`. | ⚠ UI montada; depende de vistas externas. | Crear/validar vistas en BD, asegurar seguridad al insertar en `mov_inv`. |
| **Inventario – Recepciones** | Carga de recepciones con archivos adjuntos. | ⚠ Formularios prototipo; usa datos mock. | Definir catálogos reales (proveedores/items), crear migraciones para `recepcion_*` y `inventory_batch`, manejar storage y permisos. |
| **Inventario – Lotes** | Seguimiento de lotes y caducidades. | ⚠ Componente Livewire base. | Dependencia total de tablas/vistas; falta integración. |
| **Recetas** | Listado y editor. | ⚠ Demo data si `recipes` no existe. | Diseñar schema (`recipes`, `recipe_items`, `recipe_steps`), migraciones, reglas de costo. |
| **Caja / Precortes & Postcortes** | APIs REST y compatibilidad legacy (`/legacy/precorte_*`). | ⚠ Controladores implementados pero dependen de tablas/funciones preexistentes. | Validador de esquemas, autenticación JWT, cobertura de pruebas. |
| **KDS** | Tablero en tiempo real. | ⚠ Placeholder. | Diseñar integración con órdenes y eventos. |
| **Reportes** | Endpoints `/api/reports/*` (KPIs, ventas, stock). | ⚠ Métodos stub con consultas pendientes. | Integrar con vistas/reportes reales, agregar caching. |
| **Autenticación / Roles** | Laravel Breeze + Spatie Permission. | ⚠ Base creada; tablas detectan duplicados. | Configurar guardas reales, sincronizar seeds de roles/permisos, JWT para apps móviles. |
| **Testing / QA** | PHPUnit 11, tests demo. | ✖ Solo tests básicos (`ExampleTest`). | Diseñar suite funcional (APIs, Livewire), integrar en CI. |

---

## 6. API y Endpoints

- `GET /api/ping` y `/api/health`: monitoreo básico.
- `POST /api/auth/login`: login (JWT pendiente de reforzar).
- `api/caja/*`: precortes/postcortes/sesiones/conciliación, con rutas legacy (`/legacy/*`) para compatibilidad Slim PHP.
- `api/unidades/*`: CRUD de unidades y conversiones.
- `api/inventory/*`: Items, stock, vendors; requiere definir políticas de autenticación.
- `api/reports/*`: KPI ventas/stock (consultas por implementar).
- Errores JSON estandarizados (`error`, `message`, `timestamp`). Falta versionado y rate limiting.

---

## 7. Base de Datos y Migraciones

- Migraciones idempotentes (uso de `Schema::hasTable/hasColumn`). Incluye `2025_10_19_000001_update_cat_unidades_structure` para normalizar estructuras existentes.
- Tablas nuevas esperadas: `cat_*`, `inv_stock_policy`, `inventory_batch`, `recepcion_cab`, `recepcion_det`, `mov_inv`, `recipes`, etc. Varias aún no cuentan con migración oficial.
- Dependencia en esquemas externos (`selemti`) con vistas y funciones SQL almacenadas en `BD/*` y `D:\Tavo\2025\UX\*.sql`. Se requiere sanear y centralizar para despliegues consistentes.
- Comando `php artisan catalogs:verify-tables --details` confirma presencia de tablas críticas y columnas básicas.
- Scripts históricos en `BD/DEPLOY_*`, `BD/fix_*` deben revisarse para convertirlos en migraciones o seeds reproducibles.

---

## 8. Documentación Existente

- `docs/` (en repo): Auditorías, diccionarios de datos, análisis de gaps, plan de ataque, ERD, wizard de caja. Muchos se generaron en fechas cercanas (17 oct 2025) y pueden contener duplicados/inconsistencias.
- `docs/DATA_DICTIONARY-2025-10-17.md`: referencia principal de entidades `public` y `selemti`.
- `docs/DOC_ERD-FULL-20251017-081101.md`: diagrama entidad-relación consolidado.
- `D:\Tavo\2025\UX\Inventarios` / `Cortes` / `00. Recetas`: Reúnen especificaciones funcionales, archivos Excel, plantillas CSV, scripts SQL y documentación contractual. Deben clasificarse y versionarse (Git o SharePoint) para evitar divergencias.
- Repos zip (`Documentación_full.zip`, `Inventarios_Old.zip`, etc.) requieren curaduría o migración a esta carpeta `docs/V2/` una vez validados.

Recomendación: migrar los documentos vigentes a la carpeta `docs/V2/` y registrar enlaces a archivos binarios alojados externamente (SharePoint/Drive) para no sobrecargar el repositorio.

---

## 9. Backlog y Objetivos Inmediatos

1. **Base de datos productiva**  
   - Normalizar migraciones faltantes (`recepcion_*`, `inventory_batch`, `recipes*`, vistas inventario/KPIs).  
   - Consolidar scripts SQL (carpeta `BD/` y `D:\Tavo\2025\UX\*`) → migraciones/seeds versionadas.

2. **Módulos en producción**  
   - Inventario: crear vistas `v_stock_resumen`, `v_kardex_item`, revisar permisos.  
   - Recepciones: reemplazar datos mock por catálogos reales, integrar `ReceptionService`.  
   - Recetas: diseñar modelo final y conectar con costos reales.

3. **Caja/KDS**  
   - Validar endpoints `/api/caja` contra BD real, complementar conciliación.  
   - Diseñar UI Livewire/Blade para KDS y dashboard de cortes.

4. **Seguridad/Autenticación**  
   - Definir flujo JWT (guard `api`), refresco de tokens, logout.  
   - Publicar seeds de roles/permisos (Spatie).

5. **Frontend y UX**  
   - Unificar estilos (Tailwind vs Bootstrap), revisar assets en `public/assets`.  
   - Incorporar diseños entregados en `D:\Tavo\2025\UX\Cortes\V5` y `UX\00. Recetas\ia / v2`.

6. **QA y Deploy**  
   - Crear suite de pruebas (APIs, Livewire) y pipeline CI/CD.  
   - Documentar checklist de despliegue (migraciones, assets, caches).

7. **Documentación**  
   - Actualizar README con resumen del proyecto y enlace a `docs/V2`.  
   - Clasificar documentación heredada, eliminar duplicados, asegurar versión única.

---

## 10. Riesgos Identificados

- **Dependencia de estructuras heredadas:** Muchas consultas dependen de vistas y tablas externas (`selemti.*`) que no están bajo control de migraciones → riesgo de inconsistencias entre ambientes.
- **Documentación dispersa:** Multiples versiones de documentos (repo + D:\) provocan dudas sobre la fuente de verdad.
- **Autenticación incompleta:** Falta endurecer login JWT y protección de APIs; rutas de caja siguen expuestas sin guard.
- **Pruebas insuficientes:** Sin cobertura automatizada; regresiones probables.
- **Legacy vigente:** Endpoints `/legacy/*.php` mantienen compatibilidad con Slim/Floreant; se debe planear su retiro y migración de clientes.

---

## 11. Procedimiento de Setup / Desarrollo

1. Clonar repo y ejecutar `composer install`, `npm install`.
2. Configurar `.env` (ver `DB_SCHEMA=selemti,public` y credenciales Postgres 9.5).
3. Generar key (`php artisan key:generate`) y migrar (`php artisan migrate`).
4. Verificar tablas: `php artisan catalogs:verify-tables --details`.
5. Levantar servicios: `composer run dev` (artisan serve + queue + logs + vite) o `php artisan serve` y `npm run dev` por separado.
6. Revisar rutas: `/dashboard`, `/catalogos/*`, `/inventory/*`, `/recipes`, `/caja/cortes`.
7. Para API: usar `php artisan route:list --path=api` y probar endpoints (Postman). Actualmente sin auth estricta.

---

## 12. Recomendaciones Operativas

- Registrar en `CHANGELOG.md` (pendiente) los avances por sprint.  
- Definir owner de BD/schemas para sincronizar cambios con POS legacy.  
- Colocar configuraciones sensibles (contraseñas, tokens) en `.env` y no comitearlas.  
- Añadir política de ramas (por ej. `develop`, `release/*`, `hotfix/*`) y PR reviews obligatorios.  
- Evaluar despliegue automatizado (scripts en `BD/` → pipelines).  
- Documentar endpoints en Swagger (`darkaonline/l5-swagger` está instalado pero no configurado).

---

## 13. Referencias Clave

- **Documentación Local**: `docs/PROJECT_OVERVIEW.md`, `docs/DATA_DICTIONARY-2025-10-17.md`, `docs/DOC_ERD-FULL-20251017-081101.md`, `docs/WIZARD_CORTE_CAJA-20251017-0258.md`.  
- **Scripts SQL**: `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v4-FIXED.sql`, `BD/post_deploy_verify_v4.sql`, `BD/patch_*`.  
- **Material UX / Funcional**: `D:\Tavo\2025\UX\Inventarios\*.xlsx`, `...Cortes\*.php/.sql`, `...00. Recetas\Documentación V1\*`.  
- **Servicios**: `App\Services\Inventory\ReceptionService`, `App\Http\Controllers\Api\Caja\*`.  
- **Validaciones**: Control en Livewire (`app/Livewire/*`), Form Requests en `app/Http/Requests`.  
- **Comando utilidad**: `php artisan catalogs:verify-tables`.

---

### Próximos Pasos Sugeridos

1. **Centralizar documentación** en `docs/V2` (migrar lo vigente desde D:\, limpiar duplicados).  
2. **Priorizar entregables**: Inventario (vistas SQL), Recepciones (migraciones reales), Recetas (schema final).  
3. **Habilitar seguridad** (JWT, roles) antes de exponer APIs a producción.  
4. **Crear hoja de ruta** con hitos mensuales y responsables para cada módulo.  
5. **Implementar monitoreo** (logs, health checks robustos) y scripts de respaldo para Postgres 9.5.

---

> Este documento busca servir como brújula del proyecto: identifica la situación actual, dependencias críticas y tareas inmediatas. Debe mantenerse actualizado al cierre de cada sprint o release.
