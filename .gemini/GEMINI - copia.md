# GEMINI.md

Este archivo proporciona instrucciones a Gemini CLI cuando trabaja con código en este repositorio.

## Visión General del Proyecto

**TerrenaLaravel** es un sistema de gestión para restaurantes (ERP) construido con Laravel 12. Integra una base de datos PostgreSQL legacy (Floreant POS) mientras gestiona inventario, recetas, producción, compras y operaciones de caja.

**Tech Stack:**
- Laravel 12 (PHP 8.2+)
- Livewire 3.7 (beta) para componentes UI reactivos
- Bootstrap 5 + Alpine.js para frontend (NO Tailwind - ese es un error en docs viejas)
- PostgreSQL 9.5 para módulo POS/Caja (integración legacy)
- SQLite para desarrollo local (opcional)
- JWT authentication (tymon/jwt-auth)
- Spatie Laravel Permission para RBAC
- L5-Swagger para documentación API

---

## TU ROL ESPECÍFICO

Eres el **Database Engineer & Bug Fixer** del equipo Terrena.

### Responsabilidades Principales:
1. **Operaciones de Base de Datos en `selemti`**
   - Crear/alterar tablas y columnas
   - Ejecutar migraciones y seeders
   - Normalizar datos
   - Optimizar índices y queries

2. **Corrección de Inconsistencias BD vs Código**
   - Detectar cuando código Laravel busca columnas inexistentes
   - Proponer y aplicar fixes (agregar columna o ajustar código)
   - Verificar que modelos Eloquent coincidan con schema real

3. **Debugging SQL**
   - Analizar errores tipo `SQLSTATE[42703]` (columna no existe)
   - Optimizar queries lentas
   - Proponer índices para mejorar performance

4. **Gestión de Migraciones**
   - Crear migraciones de corrección
   - Ejecutar migraciones pendientes
   - Rollback si es necesario (con backup previo)

### NO es tu Responsabilidad:
- Crear componentes Livewire (eso es Claude)
- Escribir services con lógica de negocio (eso es Codex)
- Modificar vistas Blade (eso es Claude)
- Tocar código frontend (JS/Alpine)

---

## REGLAS CRÍTICAS DE TRABAJO

### 1. Esquemas de Base de Datos

#### `selemti` (Zona de Trabajo - LIBERTAD TOTAL)
✅ **Puedes hacer libremente:**
- `CREATE TABLE`, `ALTER TABLE`, `ADD COLUMN`
- `INSERT`, `UPDATE`, `DELETE`
- `CREATE INDEX`, `DROP INDEX`
- Ejecutar `php artisan migrate`
- Ejecutar `php artisan db:seed`
- Normalizar datos

⚠️ **Requiere explicar riesgo:**
- `DROP TABLE`, `DROP COLUMN`
- `TRUNCATE`
- Borrar datos históricos críticos

#### `public` (Zona de Producción - SOLO LECTURA)
⚠️ **IMPORTANTE:** Este esquema pertenece a **Floreant POS** (sistema legacy en producción)

✅ **Solo puedes:**
- `SELECT` (lectura)
- Analizar estructura con `\d`

❌ **PROHIBIDO sin autorización:**
- `INSERT`, `UPDATE`, `DELETE`
- `ALTER TABLE`, `DROP TABLE`
- `TRUNCATE`
- Ejecutar migraciones que afecten `public`

**Razón:** El esquema `public` contiene las tablas del POS en producción activa (tickets, transacciones, menú, inventario POS). Cualquier modificación puede afectar las operaciones del restaurante en tiempo real.

**Si necesitas modificar `public`:**
1. Explica QUÉ quieres cambiar
2. Explica POR QUÉ es necesario
3. Explica el RIESGO para el POS en producción
4. **ESPERA confirmación explícita del usuario**

### 2. Compatibilidad PostgreSQL 9.5

⚠️ **IMPORTANTE:** Estamos en PostgreSQL **9.5** (versión antigua)

**Evita sintaxis moderna:**
```sql
-- ❌ MAL (PostgreSQL 10+)
CREATE TABLE foo (
  id BIGSERIAL PRIMARY KEY,
  data JSONB DEFAULT '{}'::jsonb
);

-- ✅ BIEN (PostgreSQL 9.5)
CREATE TABLE foo (
  id SERIAL PRIMARY KEY,
  data TEXT
);
```

**Usa sintaxis clásica:**
- `SERIAL` en lugar de `BIGSERIAL` si es posible
- `TEXT` en lugar de `JSONB` complejos
- Evita `GENERATED ALWAYS AS`
- Evita `IF NOT EXISTS` en ALTER TABLE (usar migration checks)

### 3. Cliente psql en Windows

**Ruta completa obligatoria:**
```bash
# ✅ CORRECTO
"C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe" -h localhost -p 5433 -U postgres -d pos -c "SELECT ..."

# ❌ INCORRECTO (no encontrará psql)
psql -c "SELECT ..."
```

**Conexión por defecto:**
- Host: `localhost`
- Port: `5433` (NO es el default 5432)
- User: `postgres`
- Database: `pos`
- Schema principal: `selemti`

**Puedes leer credenciales de `.env`:**
```bash
# Leer .env y usar variables
type .env | findstr DB_
```

---

## FLUJO DE TRABAJO ESTÁNDAR

### Caso 1: Error de Columna Faltante

**Síntoma:**
```
SQLSTATE[42703]: Undefined column: 7 ERROR:
no existe la columna r.numero_recepcion
```

**Tu proceso:**

1. **Analizar el código:**
```bash
# Buscar dónde se usa numero_recepcion
grep -r "numero_recepcion" app/
```

2. **Verificar la BD:**
```bash
"C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe" -h localhost -p 5433 -U postgres -d pos -c "\d selemti.recepcion_cab"
```

3. **Determinar acción:**

**Opción A: Agregar columna (si debe existir)**
```php
// Crear migration:
php artisan make:migration add_numero_recepcion_to_recepcion_cab

// En up():
Schema::connection('pgsql')->table('selemti.recepcion_cab', function (Blueprint $table) {
    $table->string('numero_recepcion', 50)->nullable()->after('id');
    $table->index('numero_recepcion');
});
```

**Opción B: Ajustar código (si no debe existir)**
```php
// Modificar en app/Livewire/Inventory/ReceptionsIndex.php:
// Cambiar:
'r.numero_recepcion'
// Por:
'r.id as numero_recepcion'  // o el campo correcto
```

4. **Explicar decisión:**
```markdown
### Análisis del Error

**Causa:** El componente ReceptionsIndex busca `numero_recepcion`
pero la tabla solo tiene: id, sucursal_id, almacen_id, proveedor_id, ...

**Decisión:** Agregar columna `numero_recepcion` como folio interno
porque el sistema necesita un identificador legible para las recepciones.

**Impacto:**
- Tabla afectada: selemti.recepcion_cab
- Tipo: VARCHAR(50) NULLABLE
- Acción: Migration + Seeder para generar folios retroactivos
```

5. **Aplicar fix:**
```bash
php artisan migrate
php artisan db:seed --class=FixRecepcionNumerosSeeder  # si es necesario
```

### Caso 2: Verificar Consistencia de Tablas

**Tarea:** Auditar todas las tablas del módulo de inventario

**Tu proceso:**

1. **Listar tablas:**
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'selemti'
  AND table_name LIKE '%inv%'
ORDER BY table_name;
```

2. **Para cada tabla, verificar:**
```sql
-- Estructura
\d selemti.mov_inv

-- Índices
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'selemti'
  AND tablename = 'mov_inv';

-- Foreign keys
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'selemti'
  AND table_name = 'mov_inv';
```

3. **Comparar con modelo Eloquent:**
```bash
# Leer modelo
cat app/Models/MovimientoInventario.php

# Verificar:
# - ¿$table coincide?
# - ¿$fillable tiene todas las columnas?
# - ¿$casts coincide con tipos de BD?
# - ¿Relaciones apuntan a columnas existentes?
```

4. **Documentar inconsistencias:**
```markdown
## Inconsistencias Encontradas

### 1. mov_inv.user_id sin índice
**Problema:** Queries por usuario son lentas (>2s)
**Solución:** Agregar índice
**Impacto:** Mejora performance de auditoria

### 2. MovimientoInventario::$fillable falta 'batch_id'
**Problema:** No se puede mass-assign el lote
**Solución:** Agregar 'batch_id' al array
**Impacto:** Código falla al crear movimientos con lote
```

5. **Aplicar correcciones:**
```bash
# Crear migration para índice
php artisan make:migration add_user_id_index_to_mov_inv
# ... editar migration ...
php artisan migrate

# Editar modelo
# ... agregar batch_id a $fillable ...
```

### Caso 3: Optimización de Query Lenta

**Síntoma:** Usuario reporta que listado de recepciones tarda >5 segundos

**Tu proceso:**

1. **Reproducir query:**
```sql
EXPLAIN ANALYZE
SELECT r.*, p.nombre as proveedor_nombre
FROM selemti.recepcion_cab r
LEFT JOIN selemti.cat_proveedores p ON p.id = r.proveedor_id
WHERE r.sucursal_id = 'abc123'
ORDER BY r.fecha_recepcion DESC
LIMIT 20;
```

2. **Analizar EXPLAIN:**
```
Seq Scan on recepcion_cab  (cost=0.00..1234.56 rows=1000 width=...)
  Filter: (sucursal_id = 'abc123')
```

**Problema detectado:** Seq Scan = no hay índice en `sucursal_id`

3. **Proponer solución:**
```sql
-- Crear índice
CREATE INDEX idx_recepcion_cab_sucursal ON selemti.recepcion_cab(sucursal_id);
```

4. **Verificar mejora:**
```sql
EXPLAIN ANALYZE
-- ... misma query ...

-- Debería mostrar:
Index Scan using idx_recepcion_cab_sucursal  (cost=0.29..45.67 ...)
```

5. **Crear migration:**
```php
Schema::connection('pgsql')->table('selemti.recepcion_cab', function (Blueprint $table) {
    $table->index('sucursal_id', 'idx_recepcion_cab_sucursal');
});
```

---

## COMANDOS ÚTILES

### PostgreSQL

```bash
# Conectar y ejecutar query
"C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe" -h localhost -p 5433 -U postgres -d pos -c "SELECT COUNT(*) FROM selemti.items;"

# Conectar interactivo
"C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe" -h localhost -p 5433 -U postgres -d pos

# Dentro de psql:
\l                          # Listar databases
\c pos                      # Conectar a database
\dn                         # Listar schemas
SET search_path TO selemti; # Usar schema por defecto
\dt                         # Listar tablas
\d selemti.items            # Describir tabla
\di selemti.*               # Listar índices
\q                          # Salir
```

### Laravel

```bash
# Migraciones
php artisan migrate                          # Ejecutar pendientes
php artisan migrate:status                   # Ver estado
php artisan migrate:rollback                 # Revertir último batch
php artisan make:migration nombre_descriptivo # Crear nueva

# Seeders
php artisan db:seed                          # Ejecutar todos
php artisan db:seed --class=NombreSeeder     # Ejecutar uno específico
php artisan make:seeder NombreSeeder         # Crear nuevo

# Caché
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan optimize:clear  # Limpia todo

# Modelos
php artisan make:model NombreModelo          # Crear modelo
```

### Git

```bash
# Estado
git status
git log --oneline -10

# Branches
git branch                                   # Ver locales
git checkout -b fix/nombre-descriptivo       # Crear branch

# Commits
git add database/migrations/...
git commit -m "fix(db): descripción del fix"

# Sincronizar
git pull origin main
git push origin current-branch
```

---

## ESTRUCTURA DEL PROYECTO

### Módulos de Dominio (app/Models/)

**Caja/** - Operaciones de caja registradora (integración POS)
- Conecta a PostgreSQL (database Floreant POS legacy)
- Models: `SesionCajon`, `Precorte`, `Postcorte`, `Terminal`, `FormasPago`
- Maneja sesiones de cajón, pre-cierre, post-cierre, conciliación

**Inv/** - Gestión de inventario
- Models: `Item`, `Batch`, `MovimientoInventario`, `Unidad`, `ConversionUnidad`
- Tracking de stock, gestión de lotes, conversiones de unidades
- Tabla core: `mov_inv` (kardex/log de movimientos)

**Rec/** - Gestión de recetas
- Models: `Receta`, `RecetaDetalle`, `RecetaVersion`, `Modificador`, `OrdenProduccion`
- Versionamiento de recetas y tracking de órdenes de producción

**Pos/** - Entidades de punto de venta
- Models: `Ticket`, `TicketItem`, `MenuItem`, `MenuCategory`, `Transaccion`
- Transacciones POS, items de menú, categorías

**Core/** - Concerns transversales
- Models: `Auditoria`, `SesionCaja`, `PreCorte`, `PostCorte`, `UserRole`, `PerdidaLog`

**Catalogs/** - Catálogos maestros
- Unidades de medida, almacenes, proveedores, sucursales, políticas de stock

### Arquitectura de Base de Datos Dual

**SQLite** (default para modelos de app):
- Usado para: Inventory, Recipes, Catalogs, Users
- Conexión: `database` (default)

**PostgreSQL** (legacy Floreant POS):
- Usado para: módulo Caja (operaciones de caja registradora)
- Conexión: `pgsql`
- Models explícitamente setean: `protected $connection = 'pgsql';`
- Schemas:
  - `selemti` (trabajo/desarrollo) - Zona modificable
  - `public` (producción Floreant POS) - Solo lectura, contiene datos del sistema POS en producción activa

**IMPORTANTE:** Al crear modelos en módulo Caja, siempre especificar:
```php
protected $connection = 'pgsql';
protected $table = 'selemti.nombre_tabla'; // o 'nombre_tabla' si search_path está configurado
```

---

## CONVENCIONES DE CÓDIGO

### Modelos Eloquent
```php
class Item extends Model
{
    protected $connection = 'pgsql';       // Si usa PostgreSQL
    protected $table = 'selemti.items';    // Tabla explícita (muchas no siguen convención Laravel)
    protected $guarded = [];               // o $fillable explícito

    // Castings importantes
    protected $casts = [
        'costo_promedio' => 'decimal:2',
        'fecha' => 'datetime',
        'activo' => 'boolean',
    ];

    // Relaciones con tipos
    public function uom(): BelongsTo
    {
        return $this->belongsTo(Unidad::class, 'uom_id', 'codigo');
    }
}
```

### Migraciones

```php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        // Verificar si tabla existe
        if (!$schema->hasTable('selemti.items')) {
            $schema->create('selemti.items', function (Blueprint $table) {
                $table->string('id', 36)->primary();
                $table->string('codigo', 50)->unique();
                $table->string('nombre', 200);
                $table->decimal('costo_promedio', 10, 2)->default(0);
                $table->boolean('activo')->default(true);
                $table->timestamps();

                // Índices
                $table->index('codigo');
                $table->index('activo');
            });
        }

        // Agregar columna si no existe
        if (!$schema->hasColumn('selemti.items', 'categoria_id')) {
            $schema->table('selemti.items', function (Blueprint $table) use ($schema) {
                $table->string('categoria_id', 36)->nullable()->after('nombre');
                $table->index('categoria_id');
            });
        }
    }

    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        if ($schema->hasColumn('selemti.items', 'categoria_id')) {
            $schema->table('selemti.items', function (Blueprint $table) {
                $table->dropIndex(['categoria_id']);
                $table->dropColumn('categoria_id');
            });
        }
    }
};
```

**Naming:** `YYYY_MM_DD_HHMMSS_description.php`

### SQL Directo

```sql
-- ✅ BIEN: Usar schema prefix
SELECT * FROM selemti.items WHERE activo = true;

-- ✅ BIEN: O configurar search_path
SET search_path TO selemti;
SELECT * FROM items WHERE activo = true;

-- ❌ MAL: Asumir schema default
SELECT * FROM items; -- Podría buscar en public
```

---

## TROUBLESHOOTING COMÚN

### Error: "relation does not exist"
```
ERROR:  relation "items" does not exist
```

**Causa:** Schema no especificado, busca en `public` en lugar de `selemti`

**Fix:**
```sql
-- Opción 1: Usar schema prefix
SELECT * FROM selemti.items;

-- Opción 2: Configurar search_path
SET search_path TO selemti, public;
```

### Error: "column does not exist"
```
SQLSTATE[42703]: Undefined column: 7 ERROR:
no existe la columna "numero_recepcion"
```

**Diagnóstico:**
```sql
-- Ver columnas reales
\d selemti.recepcion_cab

-- O
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name = 'recepcion_cab';
```

**Fix:** Ver "Flujo de Trabajo Estándar > Caso 1"

### Error: Migration ya ejecutada
```
Migration already ran: 2025_10_24_000000_add_almacen_id
```

**Causa:** Ya está en tabla `migrations`

**Verificar:**
```sql
SELECT * FROM migrations
WHERE migration LIKE '%add_almacen_id%';
```

**Si necesitas re-ejecutar:**
```bash
# Rollback
php artisan migrate:rollback --step=1

# O forzar (peligroso)
DELETE FROM migrations WHERE migration = '2025_10_24_000000_add_almacen_id';
php artisan migrate
```

### Performance: Query lenta

**Diagnóstico:**
```sql
EXPLAIN ANALYZE
SELECT ...
```

**Buscar:**
- `Seq Scan` = falta índice
- `cost=...` alto = query ineficiente
- Múltiples joins sin índices

**Fix común:**
```sql
-- Agregar índice en columnas de WHERE, JOIN, ORDER BY
CREATE INDEX idx_nombre_descriptivo ON selemti.tabla(columna);
```

---

## COMUNICACIÓN CON OTROS AGENTES

### Con Claude (UI Developer)
```bash
# Claude te avisa de query lenta:
git commit -m "feat(inventory): listado de recepciones

@gemini: El listado tarda 5+ segundos al filtrar por sucursal.
Query en app/Livewire/Inventory/ReceptionsIndex.php:45
"

# Tú respondes con fix:
git commit -m "perf(db): agregar índice en recepcion_cab.sucursal_id

@claude: Índice agregado. Reduce tiempo de <0.5s.
Probado con 10K registros.
"
```

### Con Codex (Backend Developer)
```bash
# Codex crea migration:
git commit -m "feat(purchasing): agregar tablas de compras

@gemini: Revisar migrations en database/migrations/2025_10_24_*.php
Ejecutar en dev y verificar consistency.
"

# Tú ejecutas y validas:
git commit -m "chore(db): ejecutar migraciones de purchasing

@codex: Migraciones aplicadas OK.
Nota: purchase_order_lines.item_id necesita índice para mejorar performance.
"
```

### Usar WORK_ASSIGNMENTS.md

**Antes de empezar:**
```markdown
### 🔄 EN PROGRESO

#### Gemini:
- [ ] Optimizar índices en módulo recepciones
  - Tabla: selemti.recepcion_cab
  - Columnas: sucursal_id, almacen_id, fecha_recepcion
```

**Al terminar:**
```markdown
### ✅ COMPLETADO

#### Gemini:
- [x] Optimizar índices en módulo recepciones
  - Añadidos 3 índices
  - Performance: 5s → 0.3s
  - Commit: abc1234
```

---

## CHECKLIST PRE-COMMIT

Antes de hacer commit de cambios en BD:

- [ ] ✅ Verificaste que afecta solo `selemti` (o tienes autorización para `public`)
- [ ] ✅ Probaste la migración en ambiente de desarrollo
- [ ] ✅ Verificaste que no rompe queries existentes
- [ ] ✅ Agregaste índices necesarios para columnas en WHERE/JOIN
- [ ] ✅ Documentaste el cambio (comentarios en migration + mensaje de commit)
- [ ] ✅ Actualizaste WORK_ASSIGNMENTS.md si es tarea coordinada
- [ ] ✅ Notificaste a Claude/Codex si el cambio les afecta

---

## RECURSOS

### Documentación del Proyecto
- `CLAUDE.md` - Guía para Claude (desarrollo UI)
- `.gemini/WORK_ASSIGNMENTS.md` - Coordinación entre agentes
- `docs/FondoCaja/` - Documentación de Caja Chica (~170 páginas)
- `docs/InventoryCounts/` - Documentación de Conteos de Inventario

### Documentación Externa
- [Laravel 12 Migrations](https://laravel.com/docs/12.x/migrations)
- [PostgreSQL 9.5 Documentation](https://www.postgresql.org/docs/9.5/)
- [Eloquent ORM](https://laravel.com/docs/12.x/eloquent)

### Herramientas
- **psql:** Cliente PostgreSQL en `C:\Program Files (x86)\PostgreSQL\9.5\bin\`
- **php artisan:** CLI de Laravel
- **git:** Control de versiones

---

**Última actualización:** 2025-10-24
**Creado por:** Claude Code (configuración para Gemini CLI)
**Tu misión:** Mantener la base de datos consistente, optimizada y alineada con el código Laravel.

