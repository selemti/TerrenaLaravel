# BORRADORES DE MIGRATIONS - SPRINT 1.1 (COMPRAS)

**Fecha:** 2025-10-24
**Estado:** ⚠️ BORRADOR PARA REVISIÓN - NO EJECUTAR AÚN
**Propósito:** Validación técnica contra BD real antes de implementar

---

## 📋 MAPEO DE FOREIGN KEYS A TABLAS EXISTENTES

| FK en Nueva Tabla | Apunta a Tabla Existente | Columna PK | Tipo de Dato | Notas |
|-------------------|--------------------------|------------|--------------|-------|
| `item_id` | `selemti.items` | `id` | **VARCHAR(20)** | ⚠️ NO es bigint |
| `sucursal_id` | `selemti.cat_sucursales` | `id` | **BIGINT** | Catálogo maestro |
| `almacen_id` | `selemti.cat_almacenes` | `id` | **BIGINT** | Catálogo maestro |
| `proveedor_id` | `selemti.cat_proveedores` | `id` | **BIGINT** | Catálogo maestro |
| `*_user_id` (todos) | **`selemti.users`** | **`id`** | **INTEGER** | ✅ Usuarios internos del sistema<br>✅ **Crear FK formal** |
| `convertido_a_request_id` | `selemti.purchase_requests` | `id` | **BIGINT** | Ya existe |
| `purchase_request_id` | `selemti.purchase_requests` | `id` | **BIGINT** | Ya existe |

### ⚠️ PUNTOS CRÍTICOS IDENTIFICADOS:

1. **`selemti.items.id` es VARCHAR(20), NO bigint**
   - Todas las FKs a items deben ser VARCHAR(20)

2. **✅ Usuarios del sistema: `selemti.users`**
   - PK: `id INTEGER`
   - **Tabla operativa interna** (NO confundir con `public.users` que es del POS read-only)
   - **SÍ crear constraints FK formales** (dentro del esquema selemti)
   - Ya en uso en: `cash_funds`, `cash_fund_movements`, `cash_fund_arqueos`

3. **`selemti.purchase_requests.sucursal_id` es VARCHAR(36)**
   - Inconsistencia con `cat_sucursales.id` (bigint)
   - En las nuevas tablas usaremos BIGINT para alinear con catálogos

4. **Sistema de permisos dinámicos**
   - No usar roles fijos ("Gerente", "Almacenista")
   - Todo basado en permisos granulares: `purchase.request.approve`, `inventory.post`, etc.
   - Administrable desde configuración del sistema
   - Futuro: integración con `job_positions`, `user_positions`, `organization_units` para Labor Manager

---

## 🗂️ MIGRATION 1: create_purchase_suggestions_table.php

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Verificar que el esquema selemti existe
        DB::statement('CREATE SCHEMA IF NOT EXISTS selemti');

        Schema::connection('pgsql')->create('selemti.purchase_suggestions', function (Blueprint $table) {
            // Identificación
            $table->bigIncrements('id');
            $table->string('folio', 20)->unique()->comment('PSC-2025-001234');

            // Contexto
            $table->bigInteger('sucursal_id')->nullable();
            $table->bigInteger('almacen_id')->nullable();

            // Estados
            $table->string('estado', 20)->default('PENDIENTE')
                ->comment('PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA');
            $table->string('prioridad', 20)->default('NORMAL')
                ->comment('URGENTE, ALTA, NORMAL, BAJA');
            $table->string('origen', 20)->default('AUTO')
                ->comment('AUTO, MANUAL, EVENTO_ESPECIAL');

            // Cálculos
            $table->integer('total_items')->default(0);
            $table->decimal('total_estimado', 18, 2)->default(0);

            // Auditoría
            $table->timestamp('sugerido_en')->useCurrent();
            $table->integer('sugerido_por_user_id')->nullable()
                ->comment('FK a selemti.users.id');
            $table->integer('revisado_por_user_id')->nullable()
                ->comment('FK a selemti.users.id');
            $table->timestamp('revisado_en')->nullable();
            $table->bigInteger('convertido_a_request_id')->nullable()
                ->comment('FK a selemti.purchase_requests.id');
            $table->timestamp('convertido_en')->nullable();

            // Metadatos
            $table->integer('dias_analisis')->default(7)
                ->comment('Días usados para calcular consumo promedio');
            $table->boolean('consumo_promedio_calculado')->default(true);
            $table->text('notas')->nullable();
            $table->jsonb('meta')->nullable();

            // Timestamps
            $table->timestamps();

            // Foreign Keys
            $table->foreign('sucursal_id', 'fk_psugg_sucursal')
                ->references('id')
                ->on('selemti.cat_sucursales')
                ->onDelete('set null');

            $table->foreign('almacen_id', 'fk_psugg_almacen')
                ->references('id')
                ->on('selemti.cat_almacenes')
                ->onDelete('set null');

            $table->foreign('sugerido_por_user_id', 'fk_psugg_user_sugerido')
                ->references('id')
                ->on('selemti.users')
                ->onDelete('set null');

            $table->foreign('revisado_por_user_id', 'fk_psugg_user_revisado')
                ->references('id')
                ->on('selemti.users')
                ->onDelete('set null');

            $table->foreign('convertido_a_request_id', 'fk_psugg_request')
                ->references('id')
                ->on('selemti.purchase_requests')
                ->onDelete('set null');

            // Índices
            $table->index('estado', 'idx_psugg_estado');
            $table->index('prioridad', 'idx_psugg_prioridad');
            $table->index('sugerido_en', 'idx_psugg_fecha');
            $table->index(['sucursal_id', 'estado'], 'idx_psugg_sucursal_estado');
        });

        // Comentario en la tabla
        DB::statement("COMMENT ON TABLE selemti.purchase_suggestions IS 'Sugerencias automáticas de compra basadas en stock policies'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.purchase_suggestions');
    }
};
```

---

## 🗂️ MIGRATION 2: create_purchase_suggestion_lines_table.php

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::connection('pgsql')->create('selemti.purchase_suggestion_lines', function (Blueprint $table) {
            // Identificación
            $table->bigIncrements('id');
            $table->bigInteger('suggestion_id')->comment('FK a purchase_suggestions');
            $table->string('item_id', 20)->comment('FK a selemti.items.id (VARCHAR!)');

            // Stock y políticas
            $table->decimal('stock_actual', 18, 6)->default(0);
            $table->decimal('stock_min', 18, 6);
            $table->decimal('stock_max', 18, 6);
            $table->decimal('reorder_point', 18, 6)->nullable();

            // Consumo y demanda
            $table->decimal('consumo_promedio_diario', 18, 6)->default(0);
            $table->integer('dias_cobertura_actual')->default(0)
                ->comment('Días de stock restante al ritmo actual');
            $table->decimal('demanda_proyectada', 18, 6)->default(0)
                ->comment('Consumo esperado en próximos N días');

            // Cantidades
            $table->decimal('qty_sugerida', 18, 6)
                ->comment('Cantidad calculada automáticamente');
            $table->decimal('qty_ajustada', 18, 6)->nullable()
                ->comment('Cantidad modificada manualmente por usuario');
            $table->string('uom', 10)->comment('Unidad de medida');

            // Costos
            $table->decimal('costo_unitario_estimado', 18, 6)->nullable();
            $table->decimal('costo_total_linea', 18, 2)->nullable();

            // Proveedor recomendado
            $table->bigInteger('proveedor_sugerido_id')->nullable()
                ->comment('FK a selemti.cat_proveedores.id');
            $table->decimal('ultimo_precio_compra', 18, 6)->nullable();
            $table->date('fecha_ultima_compra')->nullable();

            // Metadatos
            $table->text('notas')->nullable();

            // Timestamps
            $table->timestamps();

            // Foreign Keys
            $table->foreign('suggestion_id', 'fk_psuggline_suggestion')
                ->references('id')
                ->on('selemti.purchase_suggestions')
                ->onDelete('cascade');

            $table->foreign('item_id', 'fk_psuggline_item')
                ->references('id')
                ->on('selemti.items')
                ->onDelete('restrict');

            $table->foreign('proveedor_sugerido_id', 'fk_psuggline_proveedor')
                ->references('id')
                ->on('selemti.cat_proveedores')
                ->onDelete('set null');

            // Constraint UNIQUE (evitar duplicados del mismo item en la misma sugerencia)
            $table->unique(['suggestion_id', 'item_id'], 'uq_psuggline_suggestion_item');

            // Índices
            $table->index('suggestion_id', 'idx_psuggline_suggestion');
            $table->index('item_id', 'idx_psuggline_item');
        });

        // Comentario en la tabla
        DB::statement("COMMENT ON TABLE selemti.purchase_suggestion_lines IS 'Detalle de items en cada sugerencia de compra'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.purchase_suggestion_lines');
    }
};
```

---

## 🗂️ MIGRATION 3: alter_purchase_requests_add_fields.php

### **Estructura Actual vs Propuesta**

#### **Columnas EXISTENTES en `selemti.purchase_requests` (NO tocar):**
```sql
id                 BIGINT PK
folio              VARCHAR(40) UNIQUE
sucursal_id        VARCHAR(36)          -- ⚠️ Inconsistencia con cat_sucursales (BIGINT)
created_by         BIGINT NOT NULL
requested_by       BIGINT
requested_at       TIMESTAMP NOT NULL DEFAULT NOW()
estado             VARCHAR(24) NOT NULL DEFAULT 'BORRADOR'
importe_estimado   NUMERIC(18,6) NOT NULL DEFAULT 0
notas              TEXT
meta               JSONB
created_at         TIMESTAMP
updated_at         TIMESTAMP
```

#### **Columnas NUEVAS que agregará esta migration:**
```sql
fecha_requerida        DATE            -- Fecha límite operativa
almacen_destino_id     BIGINT          -- FK a cat_almacenes (dónde se recibirá)
justificacion          TEXT            -- Por qué se solicita
urgente                BOOLEAN         -- Marca de urgencia
origen_suggestion_id   BIGINT          -- FK a purchase_suggestions (si fue auto-generada)
```

#### **Foreign Keys NUEVAS:**
- `almacen_destino_id` → `selemti.cat_almacenes.id`
- `origen_suggestion_id` → `selemti.purchase_suggestions.id`

---

### **Código de Migration:**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::connection('pgsql')->table('selemti.purchase_requests', function (Blueprint $table) {
            // Campos adicionales para integración con sugerencias

            // Contexto operativo
            $table->date('fecha_requerida')->nullable()
                ->comment('Fecha límite en que se necesita el material');

            $table->bigInteger('almacen_destino_id')->nullable()
                ->comment('FK a selemti.cat_almacenes - Dónde se recibirá');

            $table->text('justificacion')->nullable()
                ->comment('Por qué se solicita (ej: stock bajo, evento especial)');

            $table->boolean('urgente')->default(false)
                ->comment('Marca de urgencia operativa');

            // Origen de la solicitud
            $table->bigInteger('origen_suggestion_id')->nullable()
                ->comment('FK a purchase_suggestions - si fue generada automáticamente');

            // Foreign Keys
            $table->foreign('almacen_destino_id', 'fk_preq_almacen_destino')
                ->references('id')
                ->on('selemti.cat_almacenes')
                ->onDelete('set null');

            $table->foreign('origen_suggestion_id', 'fk_preq_suggestion')
                ->references('id')
                ->on('selemti.purchase_suggestions')
                ->onDelete('set null');

            // Índices
            $table->index('fecha_requerida', 'idx_preq_fecha_requerida');
            $table->index('urgente', 'idx_preq_urgente');
        });

        // Comentarios en columnas
        DB::statement("COMMENT ON COLUMN selemti.purchase_requests.fecha_requerida IS 'Fecha límite operativa'");
        DB::statement("COMMENT ON COLUMN selemti.purchase_requests.almacen_destino_id IS 'Almacén que recibirá el material'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->table('selemti.purchase_requests', function (Blueprint $table) {
            // Eliminar FKs primero
            $table->dropForeign('fk_preq_almacen_destino');
            $table->dropForeign('fk_preq_suggestion');

            // Eliminar índices
            $table->dropIndex('idx_preq_fecha_requerida');
            $table->dropIndex('idx_preq_urgente');

            // Eliminar columnas
            $table->dropColumn([
                'fecha_requerida',
                'almacen_destino_id',
                'justificacion',
                'urgente',
                'origen_suggestion_id'
            ]);
        });
    }
};
```

---

## ⚠️ VALIDACIONES REQUERIDAS ANTES DE EJECUTAR

### 1. **Verificar Conexión PostgreSQL en config/database.php**
```php
'pgsql' => [
    'driver' => 'pgsql',
    'host' => env('DB_PGSQL_HOST', 'localhost'),
    'port' => env('DB_PGSQL_PORT', '5433'),
    'database' => env('DB_PGSQL_DATABASE', 'pos'),
    'username' => env('DB_PGSQL_USERNAME', 'postgres'),
    'password' => env('DB_PGSQL_PASSWORD', ''),
    'charset' => 'utf8',
    'prefix' => '',
    'schema' => 'public',
    'sslmode' => 'prefer',
],
```

### 2. **Confirmar que NO existen tablas con estos nombres:**
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'selemti'
  AND table_name IN ('purchase_suggestions', 'purchase_suggestion_lines');
```

### 3. **Verificar integridad referencial:**
- ✅ `selemti.cat_sucursales` existe y tiene registros activos
- ✅ `selemti.cat_almacenes` existe y tiene registros activos
- ✅ `selemti.cat_proveedores` existe y tiene registros activos
- ✅ `selemti.items` existe y tiene registros activos
- ✅ **`selemti.users` existe y tiene usuarios activos** (tabla operativa interna)
- ✅ `selemti.purchase_requests` existe

### 4. **Tipos de datos alineados:**
| Campo | Tipo en Migration | Tipo en BD Real | Tabla Destino | ✅/❌ |
|-------|-------------------|-----------------|---------------|-------|
| item_id | VARCHAR(20) | VARCHAR(20) | `selemti.items.id` | ✅ |
| sucursal_id | BIGINT | BIGINT | `selemti.cat_sucursales.id` | ✅ |
| almacen_id | BIGINT | BIGINT | `selemti.cat_almacenes.id` | ✅ |
| proveedor_id | BIGINT | BIGINT | `selemti.cat_proveedores.id` | ✅ |
| *_user_id | INTEGER | INTEGER | **`selemti.users.id`** | ✅ |
| request_id | BIGINT | BIGINT | `selemti.purchase_requests.id` | ✅ |

---

## 🎯 PRÓXIMAS ACCIONES (DESPUÉS DE APROBACIÓN)

1. **Crear archivos de migration en:**
   - `database/migrations/2025_10_24_120000_create_purchase_suggestions_table.php`
   - `database/migrations/2025_10_24_120001_create_purchase_suggestion_lines_table.php`
   - `database/migrations/2025_10_24_120002_alter_purchase_requests_add_fields.php`

2. **Ejecutar migrations:**
   ```bash
   php artisan migrate --database=pgsql --path=database/migrations/2025_10_24_120000_create_purchase_suggestions_table.php
   php artisan migrate --database=pgsql --path=database/migrations/2025_10_24_120001_create_purchase_suggestion_lines_table.php
   php artisan migrate --database=pgsql --path=database/migrations/2025_10_24_120002_alter_purchase_requests_add_fields.php
   ```

3. **Validar creación:**
   ```sql
   \dt selemti.purchase_sug*
   \d selemti.purchase_suggestions
   \d selemti.purchase_suggestion_lines
   \d selemti.purchase_requests
   ```

---

**FIN DEL BORRADOR**

**⚠️ ESPERANDO APROBACIÓN TÉCNICA ANTES DE PROCEDER**
