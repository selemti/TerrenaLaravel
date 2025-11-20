# Reporte Diagnóstico: PHPUnit Tests Failures

**Fecha:** 2025-11-18
**Tests Ejecutados:** 226
**Resultado:** 138 Errors, 6 Failures, 76 Deprecations

---

## Resumen Ejecutivo

Los tests están configurados para usar la BD PostgreSQL real (`pos`) pero faltan las tablas necesarias para los módulos de Purchasing, Receiving y Transfer.

### Problemas Identificados

1. **138 Errors (61% de los tests):** `Illuminate\Database\QueryException` - Tablas inexistentes en PostgreSQL
2. **6 Failures (2.6%):** Problemas de aserciones (tipos de datos)
3. **76 Deprecations (33.6%):** Warnings de PHPUnit sobre funcionalidad deprecated

---

## Problema Principal: Tablas Faltantes en PostgreSQL

### Configuración Actual de Tests

**phpunit.xml (líneas 20-31):**
```xml
<env name="DB_CONNECTION" value="pgsql"/>
<env name="DB_HOST" value="127.0.0.1"/>
<env name="DB_PORT" value="5433"/>
<env name="DB_DATABASE" value="pos"/>
<env name="DB_USERNAME" value="postgres"/>
<env name="DB_PASSWORD" value="T3rr3n4#p0s"/>
<env name="DB_SCHEMA" value="selemti,public"/>
```

**PROBLEMA:** Tests usan BD PostgreSQL real de producción/desarrollo, NO una BD de testing.

### Tablas Faltantes Detectadas

#### 1. Módulo Purchasing
```
ERROR: no existe la relación «selemti.purchase_requests»
```

**Tests afectados:**
- `test_create_request_persists_header_and_lines`
- `test_submit_approve_and_issue_order_flow`

**Tablas requeridas:**
- `selemti.purchase_requests`
- `selemti.purchase_request_lines`
- `selemti.vendor_quotes`
- `selemti.vendor_quote_lines`
- `selemti.purchase_orders`
- `selemti.purchase_order_lines`

#### 2. Módulo Receiving/Reception
```
ERROR: Queries a tablas inexistentes en selemti
```

**Tests afectados (16 tests):**
- `ReceivingServiceTest::test_create_draft_reception_successfully`
- `ReceivingServiceTest::test_update_reception_lines_successfully`
- `ReceivingServiceTest::test_validate_reception_successfully`
- `ReceivingServiceTest::test_approve_reception_successfully`
- `ReceivingServiceTest::test_post_to_inventory_successfully`
- Y más...

**Tablas requeridas:**
- `selemti.recepcion_cab` (existe según BD_SCHEMA_SELEMTI.sql)
- `selemti.recepcion_det` (existe según BD_SCHEMA_SELEMTI.sql)
- Pero posiblemente falten en la BD real

#### 3. Módulo Transfers
```
ERROR: Queries a transfer_cab/transfer_det
```

**Tests afectados (10+ tests):**
- `TransferServiceTest::test_create_transfer_successfully`
- `TransferServiceTest::test_approve_transfer_successfully`
- `TransferServiceTest::test_mark_in_transit_successfully`
- `TransferServiceTest::test_receive_transfer_successfully`
- Y más...

**Tablas requeridas:**
- `selemti.transfer_cab` (existe según BD_SCHEMA_SELEMTI.sql)
- `selemti.transfer_det` (existe según BD_SCHEMA_SELEMTI.sql)

---

## Verificación de Tablas en BD Real

```bash
psql -h localhost -p 5433 -U postgres -d pos -c "
SELECT tablename FROM pg_tables
WHERE schemaname = 'selemti'
AND tablename LIKE '%purchase%';"
```

**Resultado:** 0 filas (tablas NO existen)

```bash
psql -h localhost -p 5433 -U postgres -d pos -c "
SELECT tablename FROM pg_tables
WHERE schemaname = 'selemti'
AND tablename IN ('recepcion_cab', 'recepcion_det', 'transfer_cab', 'transfer_det');"
```

**Esperado:** 4 tablas
**Real:** Pendiente verificar

---

## Problemas de Aserciones (Failures)

### 1. RecipeCostingServiceTest::test_calculate_handles_zero_yield

**Error:**
```
Failed asserting that 0 is identical to 0.0.
```

**Ubicación:** `tests/Unit/Costing/RecipeCostingServiceTest.php:93`

**Línea problemática:**
```php
$this->assertSame(0.0, $result['portion_cost']); // Espera float, recibe int
```

**Causa:** `RecipeCostingService` está retornando `0` (integer) en vez de `0.0` (float) cuando yield_portions es 0.

**Solución:** Cambiar `assertSame` por `assertEquals` O forzar cast a float en el servicio.

### 2. InventoryCountServiceTest::test_normalize_line_maps_expected_fields

**Error similar:** Problema de tipos en aserciones.

---

## Deprecations (76 warnings)

PHPUnit 11.5 está marcando como deprecated ciertas funcionalidades. Esto NO causa fallo de tests pero requiere atención futura.

**Categorías comunes:**
- Uso de métodos deprecated de PHPUnit
- Sintaxis antigua de attributes/annotations
- Cambios en API de mocking

**Impacto:** BAJO (warnings solamente)

---

## Soluciones Propuestas

### Opción 1: Usar SQLite in-memory para Tests (RECOMENDADO)

**Ventajas:**
- Tests aislados de BD de producción/desarrollo
- Más rápidos
- No requiere datos pre-existentes
- Limpieza automática entre tests

**Cambios necesarios:**

**1. phpunit.xml:**
```xml
<env name="DB_CONNECTION" value="sqlite"/>
<env name="DB_DATABASE" value=":memory:"/>
```

**2. TestCase.php:**
```php
use Illuminate\Foundation\Testing\RefreshDatabase;

abstract class TestCase extends BaseTestCase
{
    use RefreshDatabase;
}
```

**3. Crear migraciones para todas las tablas:**
- Purchasing tables
- Reception tables (validar existencia)
- Transfer tables (validar existencia)

**Limitaciones:**
- SQLite no soporta todos los tipos de PostgreSQL
- Algunas queries específicas de PostgreSQL pueden fallar

---

### Opción 2: Crear BD de Testing en PostgreSQL

**Ventajas:**
- Tests con BD real tipo producción
- Soporta queries específicas de PostgreSQL

**Desventajas:**
- Más lento
- Requiere setup adicional
- Necesita datos seed

**Cambios necesarios:**

**1. Crear BD de testing:**
```bash
createdb -h localhost -p 5433 -U postgres pos_test
```

**2. phpunit.xml:**
```xml
<env name="DB_DATABASE" value="pos_test"/>
```

**3. Ejecutar migraciones en pos_test:**
```bash
php artisan migrate --database=pgsql --env=testing
```

**4. Seeders para datos mínimos**

---

### Opción 3: Mockear Servicios en Tests Unitarios

**Para tests UNIT solamente:**
- Mockear conexiones de BD
- Usar stubs para repositorios
- Tests verdaderamente unitarios (sin BD)

**Ejemplo:**
```php
public function test_create_request()
{
    $mock = $this->createMock(PurchaseRequestRepository::class);
    $mock->expects($this->once())
         ->method('create')
         ->willReturn(1);

    $service = new PurchasingService($mock);
    $result = $service->createRequest([...]);

    $this->assertSame(1, $result);
}
```

---

## Acciones Inmediatas Recomendadas

### Prioridad ALTA

1. **Verificar existencia de tablas en BD real:**
   ```bash
   psql -h localhost -p 5433 -U postgres -d pos -c "
   SELECT tablename FROM pg_tables
   WHERE schemaname = 'selemti'
   ORDER BY tablename;"
   ```

2. **Ejecutar migraciones faltantes:**
   - Si existen migraciones pero no se ejecutaron: `php artisan migrate --database=pgsql`
   - Si NO existen migraciones: crearlas basándose en BD_SCHEMA_SELEMTI.sql

3. **Decidir estrategia de testing:**
   - ¿SQLite para Unit tests?
   - ¿PostgreSQL para Feature tests?
   - ¿Mocks para tests unitarios puros?

### Prioridad MEDIA

4. **Corregir failures de aserciones:**
   - `RecipeCostingServiceTest.php:93` - cambiar a `assertEquals`
   - `InventoryCountServiceTest` - revisar tipos

5. **Revisar deprecations:**
   - Ejecutar: `./vendor/bin/phpunit 2>&1 | grep "Deprecation"`
   - Actualizar sintaxis a PHPUnit 11.5

---

## Comandos de Diagnóstico

### Ver todos los errores agrupados:
```bash
./vendor/bin/phpunit --log-junit storage/logs/phpunit-report.xml
cat storage/logs/phpunit-report.xml | grep -E "<error|<failure" | sort | uniq -c
```

### Ver deprecations:
```bash
./vendor/bin/phpunit 2>&1 | grep -A 3 "Deprecation"
```

### Ejecutar solo tests que pasan:
```bash
./vendor/bin/phpunit --exclude-group=requires-database
```

### Ver lista de tablas en selemti:
```bash
psql -h localhost -p 5433 -U postgres -d pos -c "
SELECT schemaname, tablename, tableowner
FROM pg_tables
WHERE schemaname = 'selemti'
ORDER BY tablename;"
```

---

## Conclusión

**CAUSA RAÍZ:** Tests configurados para usar BD PostgreSQL real pero tablas críticas (Purchasing) no existen.

**IMPACTO:** 61% de tests fallan (138/226)

**SOLUCIÓN RÁPIDA:** Cambiar a SQLite in-memory para tests Unit

**SOLUCIÓN COMPLETA:**
1. Ejecutar migraciones faltantes en PostgreSQL
2. Configurar BD de testing separada
3. Implementar seeds mínimos para tests

**SIGUIENTE PASO:** Decidir estrategia de testing con el equipo.

---

**Generado:** 2025-11-18
**Autor:** Claude Code (Especialista BD + Backend Laravel)
