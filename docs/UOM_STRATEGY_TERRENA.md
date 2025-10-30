# UOM Strategy - TerrenaLaravel

**Versión:** 1.0
**Fecha:** 2025-10-29
**Esquema:** `selemti`
**PostgreSQL:** 9.5

---

## 📋 Resumen Ejecutivo

Este documento describe la estrategia de normalización del sistema de Unidades de Medida (UOM) en TerrenaLaravel. El objetivo es consolidar múltiples tablas legacy en un sistema canónico robusto con soporte para conversiones exactas y aproximadas, manteniendo compatibilidad hacia atrás mediante vistas.

### Objetivos Cumplidos

✅ **Tablas canónicas consolidadas**: `cat_unidades` y `cat_uom_conversion`
✅ **Semillas base**: 29 UOM (métrica, imperial, culinaria)
✅ **Conversiones bidireccionales**: 26 conversiones (14 exactas, 12 aproximadas)
✅ **Compatibilidad legacy**: 4 vistas de compatibilidad
✅ **UOM base operativas**: KG, L, PZ (kilogramo, litro, pieza)
✅ **Metadata de conversiones**: `is_exact`, `scope`, `notes`

---

## 🎯 Alcance

### Tablas Canónicas (Fuente de Verdad)

#### 1. `selemti.cat_unidades`

**Propósito**: Catálogo maestro de todas las unidades de medida.

**Columnas:**

| Columna      | Tipo           | Descripción                                   |
|--------------|----------------|-----------------------------------------------|
| `id`         | `bigint`       | PK, autoincremental                           |
| `clave`      | `varchar(16)`  | Código único (ej: KG, L, PZ) - UNIQUE         |
| `nombre`     | `varchar(64)`  | Nombre descriptivo (ej: Kilogramo)            |
| `activo`     | `boolean`      | Estado activo/inactivo (default: true)        |
| `created_at` | `timestamp`    | Timestamp de creación                         |
| `updated_at` | `timestamp`    | Timestamp de última actualización             |

**Constraints:**
- `PRIMARY KEY (id)`
- `UNIQUE (clave)`

**Índices:**
- `idx_cat_unidades_clave` en `clave`
- `idx_cat_unidades_activo` en `activo`

#### 2. `selemti.cat_uom_conversion`

**Propósito**: Factores de conversión entre unidades con metadata (exactitud, alcance, notas).

**Columnas:**

| Columna      | Tipo            | Descripción                                      |
|--------------|-----------------|--------------------------------------------------|
| `id`         | `bigint`        | PK, autoincremental                              |
| `origen_id`  | `bigint`        | FK a `cat_unidades(id)` - unidad origen          |
| `destino_id` | `bigint`        | FK a `cat_unidades(id)` - unidad destino         |
| `factor`     | `numeric(18,6)` | Factor de conversión (> 0)                       |
| `is_exact`   | `boolean`       | Conversión exacta (true) o aproximada (false)    |
| `scope`      | `varchar(16)`   | Alcance: 'global' (métrica/imperial) o 'house' (culinaria) |
| `notes`      | `text`          | Notas adicionales (ej: "US customary")           |
| `created_at` | `timestamp`     | Timestamp de creación                            |
| `updated_at` | `timestamp`     | Timestamp de última actualización                |

**Constraints:**
- `PRIMARY KEY (id)`
- `UNIQUE (origen_id, destino_id)` - una sola conversión por par
- `CHECK (origen_id <> destino_id)` - no auto-conversión
- `CHECK (factor > 0)` - factor positivo
- `CHECK (scope IN ('global', 'house'))`
- `FOREIGN KEY (origen_id) REFERENCES cat_unidades(id) ON DELETE CASCADE`
- `FOREIGN KEY (destino_id) REFERENCES cat_unidades(id) ON DELETE CASCADE`

**Índices:**
- `idx_cat_uom_conversion_origen` en `origen_id`
- `idx_cat_uom_conversion_destino` en `destino_id`
- `idx_cat_uom_conversion_scope` en `scope`

---

## 📦 UOM Base Operativas

Las tres unidades base para inventario operacional en TerrenaLaravel son:

| Clave | Nombre     | Tipo    | Uso Principal                |
|-------|------------|---------|------------------------------|
| **KG** | Kilogramo  | Masa    | Ingredientes sólidos, carnes |
| **L**  | Litro      | Volumen | Líquidos, aceites, salsas    |
| **PZ** | Pieza      | Unidad  | Items contables              |

Todas las conversiones se normalizan a estas unidades base antes de registrarse en el kardex (`mov_inv`).

---

## 🔄 Política de Conversiones

### Tipos de Conversiones

#### 1. Conversiones Exactas (`is_exact = true`, `scope = 'global'`)

Conversiones métricas e imperiales con definiciones estándar internacionales.

**Ejemplos:**
- 1 KG = 1000 G (métrica)
- 1 L = 1000 ML (métrica)
- 1 LB = 453.59237 G (imperial, definición exacta)
- 1 OZ = 28.349523125 G (avoirdupois)
- 1 LB = 16 OZ (imperial)

**Características:**
- Factor matemático preciso
- Roundtrip perfecto (ida × vuelta = 1.0)
- Aplicables universalmente

#### 2. Conversiones Culinarias (`is_exact = false`, `scope = 'house'`)

Medidas culinarias con aproximaciones basadas en estándares US customary.

**Ejemplos:**
- 1 CUP ≈ 240 ML (varía 236-250ml según fuente)
- 1 TBSP ≈ 15 ML (cucharada)
- 1 TSP ≈ 5 ML (cucharadita)
- 1 FLOZ ≈ 29.5735 ML (US fluid ounce)
- 1 CUP = 16 TBSP (aproximado)
- 1 TBSP = 3 TSP (aproximado)

**Características:**
- Factor aproximado
- Roundtrip puede variar ligeramente (ej: CUP→ML→CUP ≈ 1.00008)
- Específicas para contexto culinario ("house" scope)

### Bidireccionalidad

**Todas las conversiones se insertan en ambos sentidos:**
- KG → G (factor: 1000.0)
- G → KG (factor: 0.001)

Esto permite consultas eficientes en cualquier dirección sin cálculo dinámico.

---

## 🗃️ Tablas Legacy Deprecadas

Las siguientes tablas se renombraron a `*_legacy` y se reemplazaron con vistas de compatibilidad:

| Tabla Original      | Renombrada a                | Vista de Compatibilidad | Estado      |
|---------------------|-----------------------------|-------------------------|-------------|
| `unidad_medida`     | `unidad_medida_legacy`      | `unidad_medida` (VIEW)  | Deprecada   |
| `unidades_medida`   | `unidades_medida_legacy`    | `unidades_medida` (VIEW)| Deprecada   |
| `uom_conversion`    | `uom_conversion_legacy`     | `uom_conversion` (VIEW) | Deprecada   |
| `conversiones_unidad` | `conversiones_unidad_legacy` | `conversiones_unidad` (VIEW) | Deprecada |

### Vistas de Compatibilidad

#### Vista: `unidad_medida`

```sql
CREATE OR REPLACE VIEW unidad_medida AS
SELECT
    id::integer AS id,
    clave AS codigo,
    nombre,
    CASE
        WHEN clave IN ('KG', 'G', 'MG', 'LB', 'OZ') THEN 'PESO'
        WHEN clave IN ('L', 'ML', 'M3', 'FLOZ', 'CUP', 'TBSP', 'TSP') THEN 'VOLUMEN'
        WHEN clave IN ('PZ') THEN 'UNIDAD'
        ELSE 'UNIDAD'
    END AS tipo,
    CASE
        WHEN clave IN ('KG', 'L', 'PZ') THEN true
        ELSE false
    END AS es_base,
    1.0::numeric(14,6) AS factor_a_base,
    2 AS decimales
FROM cat_unidades
WHERE activo = true;
```

**Propósito**: Mapea `cat_unidades` a la estructura legacy `unidad_medida`.

#### Vista: `unidades_medida`

```sql
CREATE OR REPLACE VIEW unidades_medida AS
SELECT
    id::integer AS id,
    clave AS codigo,
    nombre,
    CASE
        WHEN clave IN ('KG', 'G', 'MG', 'LB', 'OZ') THEN 'PESO'
        WHEN clave IN ('L', 'ML', 'M3', 'FLOZ', 'CUP', 'TBSP', 'TSP') THEN 'VOLUMEN'
        WHEN clave IN ('PZ') THEN 'UNIDAD'
        ELSE 'UNIDAD'
    END::character varying(10) AS tipo,
    CASE
        WHEN clave IN ('KG', 'G', 'MG', 'L', 'ML', 'M3') THEN 'METRICO'
        WHEN clave IN ('LB', 'OZ', 'FLOZ') THEN 'IMPERIAL'
        WHEN clave IN ('CUP', 'TBSP', 'TSP') THEN 'CULINARIO'
        ELSE 'METRICO'
    END::character varying(20) AS categoria,
    CASE
        WHEN clave IN ('KG', 'L', 'PZ') THEN true
        ELSE false
    END AS es_base,
    1.0::numeric(12,6) AS factor_conversion_base,
    2 AS decimales,
    created_at
FROM cat_unidades
WHERE activo = true;
```

**Propósito**: Mapea `cat_unidades` con columna adicional `categoria` (METRICO/IMPERIAL/CULINARIO).

#### Vista: `uom_conversion`

```sql
CREATE OR REPLACE VIEW uom_conversion AS
SELECT
    id::integer AS id,
    origen_id::integer AS origen_id,
    destino_id::integer AS destino_id,
    factor::numeric(14,6) AS factor
FROM cat_uom_conversion;
```

**Propósito**: Mapea `cat_uom_conversion` sin columnas de metadata.

#### Vista: `conversiones_unidad`

```sql
CREATE OR REPLACE VIEW conversiones_unidad AS
SELECT
    id::integer AS id,
    origen_id::integer AS unidad_origen_id,
    destino_id::integer AS unidad_destino_id,
    factor AS factor_conversion,
    notes AS formula_directa,
    CASE
        WHEN is_exact THEN 1.0
        ELSE 0.95
    END::numeric(5,4) AS precision_estimada,
    true AS activo,
    created_at
FROM cat_uom_conversion;
```

**Propósito**: Mapea `cat_uom_conversion` con alias de columnas legacy.

### Estrategia de Migración Gradual

**Fase Actual**: Compatibilidad total mediante vistas
**Fase Siguiente** (futuro): Migrar queries y FKs a tablas canónicas
**Fase Final** (futuro): Eliminar vistas y tablas `*_legacy`

**No rompe código existente** porque:
1. Las vistas mantienen los mismos nombres de tabla
2. Las vistas exponen las mismas columnas esperadas
3. Los FKs existentes siguen funcionando (apuntan a vistas que son consultables)

---

## 📊 Catálogo de UOM Actual

### Resumen

| Métrica                  | Cantidad |
|--------------------------|----------|
| **Total UOM activas**    | 29       |
| **Conversiones totales** | 26       |
| **Conversiones exactas** | 14       |
| **Conversiones aprox.**  | 12       |
| **Scope global**         | 14       |
| **Scope house**          | 12       |

### UOM por Categoría

#### Masa (Peso)

| Clave | Nombre     | Categoría | Notas                |
|-------|------------|-----------|----------------------|
| KG    | Kilogramo  | Métrica   | **Base operativa**   |
| G     | Gramo      | Métrica   |                      |
| GR    | Gramo      | Métrica   | Duplicado de G       |
| MG    | Miligramo  | Métrica   |                      |
| LB    | Libra      | Imperial  |                      |
| OZ    | Onza       | Imperial  |                      |
| TON   | Tonelada   | Métrica   |                      |

#### Volumen

| Clave | Nombre         | Categoría  | Notas                |
|-------|----------------|------------|----------------------|
| L     | Litro          | Métrica    | **Base operativa**   |
| LT    | Litro          | Métrica    | Duplicado de L       |
| ML    | Mililitro      | Métrica    |                      |
| M3    | Metro cúbico   | Métrica    |                      |
| MC    | Metro Cúbico   | Métrica    | Duplicado de M3      |
| FLOZ  | Onza fluida    | Imperial   | US customary         |
| CUP   | Taza           | Culinaria  |                      |
| TAZA  | Taza           | Culinaria  | Duplicado de CUP     |
| TBSP  | Cucharada      | Culinaria  |                      |
| CDSP  | Cucharada Sopera | Culinaria | Variante de TBSP     |
| TSP   | Cucharadita    | Culinaria  |                      |
| CDTA  | Cucharadita    | Culinaria  | Duplicado de TSP     |
| GAL   | Galón          | Imperial   |                      |

#### Unidad (Contable)

| Clave | Nombre   | Categoría | Notas                |
|-------|----------|-----------|----------------------|
| PZ    | Pieza    | Unidad    | **Base operativa**   |
| PZA   | Pieza    | Unidad    | Duplicado de PZ      |
| CAJA  | Caja     | Unidad    |                      |
| COST  | Costal   | Unidad    |                      |
| PAQ   | Paquete  | Unidad    |                      |
| PLAT  | Plato    | Unidad    |                      |
| PORC  | Porción  | Unidad    |                      |

#### Tiempo (Opcional)

| Clave | Nombre  | Categoría | Notas                     |
|-------|---------|-----------|---------------------------|
| HR    | Hora    | Tiempo    | Para recetas/producción   |
| MIN   | Minuto  | Tiempo    | Para recetas/producción   |

---

## 🔗 Foreign Keys Afectadas

### FKs que Apuntan a Tablas Canónicas

| Tabla Origen                     | Columna FK        | Tabla Destino      |
|----------------------------------|-------------------|--------------------|
| `cat_uom_conversion`             | `origen_id`       | `cat_unidades`     |
| `cat_uom_conversion`             | `destino_id`      | `cat_unidades`     |
| `insumo_proveedor_presentacion`  | `uom_base_id`     | `cat_unidades`     |
| `insumo_proveedor_presentacion`  | `uom_compra_id`   | `cat_unidades`     |

### FKs que Apuntan a Vistas Legacy (Compatibilidad)

Estos FKs continúan funcionando porque las vistas exponen las mismas interfaces:

| Tabla Origen            | Columna FK              | Vista Destino       |
|-------------------------|-------------------------|---------------------|
| `insumo_presentacion`   | `um_compra_id`          | `unidad_medida`     |
| `insumo`                | `um_id`                 | `unidad_medida`     |
| `items`                 | `unidad_medida_id`      | `unidades_medida`   |
| `items`                 | `unidad_compra_id`      | `unidades_medida`   |
| `items`                 | `unidad_salida_id`      | `unidades_medida`   |
| `recepcion_det`         | `um_id`                 | `unidad_medida`     |
| `ticket_det_consumo`    | `uom_original_id`       | `unidades_medida`   |
| `perdida_log`           | `uom_original_id`       | `unidades_medida`   |
| (otros 10+ FKs)         | ...                     | vistas legacy       |

**Nota**: En futuras migraciones, estos FKs se actualizarán para apuntar a `cat_unidades` directamente.

---

## ✅ Verificaciones Ejecutadas

### 1. Conteo de Registros

```sql
-- Total UOM activas: 29
SELECT COUNT(*) FROM selemti.cat_unidades WHERE activo = true;

-- Total conversiones: 26 (14 exactas, 12 aproximadas)
SELECT COUNT(*) FROM selemti.cat_uom_conversion;
```

### 2. Rutas de Conversión (Roundtrip Tests)

#### KG → G → KG (Exacta)

```sql
-- Resultado: 1.000000000000 (perfecto)
SELECT
    (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'KG') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'G'))
    *
    (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'G') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'KG'))
    AS roundtrip_factor;
```

**Resultado**: `1.000000000000` ✅

#### L → ML → L (Exacta)

```sql
-- Resultado: 1.000000000000 (perfecto)
```

**Resultado**: `1.000000000000` ✅

#### CUP → ML → CUP (Aproximada)

```sql
-- Resultado: 1.000080000000 (aproximado, aceptable)
```

**Resultado**: `1.000080000000` ✅ (variación < 0.01%, esperada para scope 'house')

### 3. Vistas de Compatibilidad

```sql
-- Verificar que las 4 vistas existen
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'selemti'
AND table_name IN ('unidad_medida', 'unidades_medida', 'uom_conversion', 'conversiones_unidad')
ORDER BY table_name;
```

**Resultado**:
```
     table_name      | table_type
---------------------+------------
 conversiones_unidad | VIEW
 unidad_medida       | VIEW
 unidades_medida     | VIEW
 uom_conversion      | VIEW
```

✅ Todas las vistas creadas correctamente.

### 4. Funcionalidad de Vistas

```sql
-- Verificar que la vista retorna datos
SELECT COUNT(*) FROM selemti.unidades_medida;
```

**Resultado**: `29` ✅

---

## 🛠️ Uso en Código Laravel

### Modelos Eloquent

#### Modelo `Unidad` (Canónico)

**Archivo**: `app/Models/Catalogs/Unidad.php`

```php
<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

class Unidad extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.cat_unidades';
    protected $primaryKey = 'id';
    public $incrementing = true;
    protected $keyType = 'int';

    protected $fillable = [
        'clave',
        'nombre',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relationships
    public function conversionesOrigen()
    {
        return $this->hasMany(UomConversion::class, 'origen_id');
    }

    public function conversionesDestino()
    {
        return $this->hasMany(UomConversion::class, 'destino_id');
    }

    // Scopes
    public function scopeActivas($query)
    {
        return $query->where('activo', true);
    }

    public function scopePorClave($query, string $clave)
    {
        return $query->where('clave', strtoupper($clave));
    }
}
```

#### Modelo `UomConversion` (Canónico)

**Archivo**: `app/Models/Catalogs/UomConversion.php`

```php
<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;

class UomConversion extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.cat_uom_conversion';
    protected $primaryKey = 'id';

    protected $fillable = [
        'origen_id',
        'destino_id',
        'factor',
        'is_exact',
        'scope',
        'notes',
    ];

    protected $casts = [
        'factor' => 'decimal:6',
        'is_exact' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relationships
    public function origen()
    {
        return $this->belongsTo(Unidad::class, 'origen_id');
    }

    public function destino()
    {
        return $this->belongsTo(Unidad::class, 'destino_id');
    }

    // Scopes
    public function scopeExactas($query)
    {
        return $query->where('is_exact', true);
    }

    public function scopeAproximadas($query)
    {
        return $query->where('is_exact', false);
    }

    public function scopeGlobal($query)
    {
        return $query->where('scope', 'global');
    }

    public function scopeHouse($query)
    {
        return $query->where('scope', 'house');
    }
}
```

### Servicio de Conversión

Ver sección "Servicio `UomConversionService`" más abajo.

---

## 📚 Servicio `UomConversionService`

**Archivo**: `app/Services/Inventory/UomConversionService.php`

**Funcionalidades**:
1. **Conversión directa**: Convertir cantidad de UOM origen a UOM destino
2. **Resolución por clave**: Buscar conversión usando claves (ej: 'KG' → 'G')
3. **Detección de aproximación**: Flag `is_approx` en resultado
4. **Scope preference**: Preferir conversiones 'global' sobre 'house'
5. **Validaciones**: Verificar que UOM existen y conversión está disponible

### Métodos Principales

#### `convert(float $value, string $fromClave, string $toClave, string $preferScope = 'any'): array`

**Parámetros**:
- `$value`: Cantidad a convertir
- `$fromClave`: Clave UOM origen (ej: 'KG')
- `$toClave`: Clave UOM destino (ej: 'G')
- `$preferScope`: Scope preferido ('global', 'house', 'any')

**Retorna**:
```php
[
    'success' => true|false,
    'result' => float,           // Cantidad convertida
    'is_approx' => bool,         // true si conversión es aproximada
    'factor' => float,           // Factor aplicado
    'scope' => 'global'|'house', // Scope usado
    'notes' => string|null,      // Notas de la conversión
    'error' => string|null       // Mensaje de error si falló
]
```

**Ejemplo de uso**:

```php
use App\Services\Inventory\UomConversionService;

$service = new UomConversionService();

// Convertir 2.5 KG a G
$result = $service->convert(2.5, 'KG', 'G');

if ($result['success']) {
    echo "Resultado: {$result['result']} G\n";  // 2500.0 G
    echo "Exacta: " . ($result['is_approx'] ? 'No' : 'Sí') . "\n";  // Sí
}

// Convertir 1 CUP a ML (culinaria, aproximada)
$result = $service->convert(1, 'CUP', 'ML', 'house');

if ($result['success']) {
    echo "Resultado: {$result['result']} ML\n";  // 240.0 ML
    echo "Exacta: " . ($result['is_approx'] ? 'No' : 'Sí') . "\n";  // No
    echo "Notas: {$result['notes']}\n";  // Taza US estándar (aproximado, varía 236-250ml)
}
```

---

## 🧪 Tests Unitarios

**Archivo**: `tests/Unit/Services/UomConversionServiceTest.php`

**Casos de prueba**:
1. ✅ Conversión KG → G (exacta, métrica)
2. ✅ Conversión G → KG (exacta, métrica inversa)
3. ✅ Conversión L → ML (exacta, volumen)
4. ✅ Conversión LB → G (exacta, imperial)
5. ✅ Conversión CUP → ML (aproximada, culinaria)
6. ✅ Conversión con UOM inexistente (debe fallar)
7. ✅ Conversión sin ruta directa (debe fallar)
8. ✅ Roundtrip KG → G → KG (debe retornar valor original)
9. ✅ Prefer scope 'global' sobre 'house'

---

## 🚀 Próximos Pasos (Roadmap)

### Fase 1: Operación Actual ✅ COMPLETADO
- [x] Normalizar tablas canónicas
- [x] Insertar semillas de UOM y conversiones
- [x] Crear vistas de compatibilidad
- [x] Documentar estrategia
- [x] Crear servicio `UomConversionService`
- [x] Tests unitarios

### Fase 2: Transición (Q1 2026)
- [ ] Auditoría de queries que usan tablas legacy
- [ ] Migrar queries críticos a tablas canónicas
- [ ] Actualizar modelos Eloquent para usar `cat_unidades`
- [ ] Migrar FKs de tablas legacy a canónicas (con ALTER TABLE)
- [ ] Deprecar vistas con warnings en logs

### Fase 3: Limpieza Final (Q2 2026)
- [ ] Eliminar vistas de compatibilidad
- [ ] Eliminar tablas `*_legacy`
- [ ] Actualizar documentación de modelos
- [ ] Cleanup de código legacy

---

## 📖 Referencias

### Scripts SQL

- **Normalización completa**: `BD/UOM_Normalization_PG95.sql`
- **Dump original**: `BD/SelemTI_Estrucutra_Pedido_29_10_25_10_40_v2.sql`

### Documentación Relacionada

- `CLAUDE.md` - Guía general del proyecto
- `docs/inventory/` - Documentación de módulo de inventario
- `.gemini/WORK_ASSIGNMENTS.md` - Coordinación multi-agente

### Estándares de Conversión

- **Métrica**: Sistema Internacional de Unidades (SI)
- **Imperial**: US Customary Units (NIST Handbook 44)
- **Culinaria**: US Culinary Measurements (FDA Food Labeling Guide)

---

## 🔐 Política de Seguridad

### Modificaciones a Tablas Canónicas

**Requieren aprobación**:
- Agregar nuevas UOM
- Modificar factores de conversión existentes
- Eliminar UOM en uso

**Proceso**:
1. Verificar que la UOM no está en uso (consultar kardex)
2. Crear migration con rollback
3. Actualizar semillas si es necesario
4. Re-ejecutar tests de roundtrip

### Esquema `selemti` vs `public`

- **`selemti`**: Esquema de trabajo, modificable libremente ✅
- **`public`**: Floreant POS legacy, SOLO LECTURA ⚠️

---

## 👥 Coordinación Multi-Agente

Este módulo fue desarrollado con coordinación entre:

- **Claude Code**: UI/UX, documentación, normalización SQL, servicio Laravel
- **Codex**: (Futuro) Integración con servicios backend existentes
- **Gemini CLI**: (Futuro) Optimización de queries, índices adicionales

Ver `.gemini/WORK_ASSIGNMENTS.md` para asignaciones actuales.

---

## 📝 Changelog

### v1.0 - 2025-10-29

- ✅ Normalización inicial de UOM
- ✅ 29 UOM base sembradas
- ✅ 26 conversiones bidireccionales (14 exactas, 12 aproximadas)
- ✅ Vistas de compatibilidad para 4 tablas legacy
- ✅ Documentación completa
- ✅ Servicio `UomConversionService`
- ✅ Tests unitarios básicos

---

**Autor**: Claude Code
**Aprobado por**: Equipo TerrenaLaravel
**Última actualización**: 2025-10-29
