# Plan de Implementación - Sistema de Reportes de Ventas

## 📋 Resumen de la Revisión

He analizado tu base de datos FloreantPOS y encontrado discrepancias importantes entre el prompt original y tu estructura real. He preparado:

1. **Análisis de Discrepancias** - Documento detallado con todas las diferencias encontradas
2. **Script SQL Corregido** - Todas las vistas adaptadas a tu estructura real
3. **Este Plan de Acción** - Guía paso a paso para implementar

## 🎯 Estado Actual

### ✅ Lo que SÍ tienes listo:
- PostgreSQL 9.5 ✓
- Schemas `public` y `selemti` ✓
- Tablas principales: `ticket`, `transactions`, `terminal`, `ticket_item` ✓
- Todas las funciones críticas del prompt existen ✓
- Campos de negocio principales ✓

### ❌ Lo que necesita ajuste:
- Nombres de columnas diferentes (ej: `create_date` vs `created_at`)
- Columnas de auditoría faltantes (`paid_at`, `settled_at`, `tip_amount`)
- Tipos de datos (double precision vs numeric)
- Referencias a tablas inexistentes (`products` vs `menu_item`)

## 🚀 Plan de Implementación Recomendado

### Fase 1: Preparación (1 día)
```bash
# 1. Backup completo
pg_dump -h localhost -U floreant -d pos > backup_$(date +%Y%m%d).sql

# 2. Crear ambiente de pruebas
createdb pos_test
pg_restore -d pos_test backup_$(date +%Y%m%d).sql
```

### Fase 2: Implementación Base (2-3 días)

#### Opción A: Usar Script Corregido (RECOMENDADO)
```sql
-- 1. Conectar a la BD
psql -U floreant -d pos_test

-- 2. Ejecutar script corregido
\i /path/to/script_sql_corregido.sql

-- 3. Verificar vistas creadas
SELECT viewname FROM pg_views 
WHERE schemaname = 'public' AND viewname LIKE 'vw_%';
```

#### Opción B: Agregar Columnas Faltantes (más trabajo)
```sql
-- Solo si necesitas 100% compatibilidad con el prompt original
ALTER TABLE ticket ADD COLUMN IF NOT EXISTS paid_at timestamp;
ALTER TABLE ticket ADD COLUMN IF NOT EXISTS settled_at timestamp;
ALTER TABLE ticket ADD COLUMN IF NOT EXISTS tip_amount numeric(10,2);
ALTER TABLE ticket ADD COLUMN IF NOT EXISTS discount_reason text;
ALTER TABLE ticket ADD COLUMN IF NOT EXISTS authorized_by integer;

-- Migrar datos
UPDATE ticket SET paid_at = create_date WHERE paid = true;
UPDATE ticket SET settled_at = closing_date WHERE settled = true;
```

### Fase 3: Laravel API (3-4 días)

```php
// 1. Crear modelos Eloquent
php artisan make:model Ticket
php artisan make:model Transaction
php artisan make:model Terminal

// 2. Crear controladores
php artisan make:controller Api/Reports/SalesReportController --api
php artisan make:controller Api/Reports/DiscountReportController --api
php artisan make:controller Api/Reports/DiagnosticController --api

// 3. Configurar rutas en api.php
Route::middleware(['auth:sanctum'])->prefix('reports')->group(function () {
    Route::prefix('sales')->group(function () {
        Route::get('daily', [SalesReportController::class, 'daily']);
        Route::get('by-terminal', [SalesReportController::class, 'byTerminal']);
        Route::get('payment-mix', [SalesReportController::class, 'paymentMix']);
        Route::get('by-hour', [SalesReportController::class, 'byHour']);
        Route::get('kpis', [SalesReportController::class, 'kpis']);
    });
    
    Route::prefix('discounts')->group(function () {
        Route::get('daily', [DiscountReportController::class, 'daily']);
        Route::get('detail', [DiscountReportController::class, 'detail']);
        Route::get('exceptions', [DiscountReportController::class, 'exceptions']);
    });
    
    Route::prefix('diagnostics')->group(function () {
        Route::get('summary', [DiagnosticController::class, 'summary']);
        Route::get('payment-mismatch', [DiagnosticController::class, 'paymentMismatch']);
        Route::get('high-discounts', [DiagnosticController::class, 'highDiscounts']);
    });
});
```

### Fase 4: Performance (1-2 días)

```sql
-- 1. Crear índices críticos
CREATE INDEX idx_ticket_folio_date ON ticket(folio_date, branch_key);
CREATE INDEX idx_ticket_paid_voided ON ticket(paid, voided);
CREATE INDEX idx_transactions_ticket_id ON transactions(ticket_id);
CREATE INDEX idx_transactions_voided ON transactions(voided);

-- 2. Crear materialized views
CREATE MATERIALIZED VIEW mv_sales_by_terminal AS
SELECT * FROM vw_sales_by_terminal
WHERE folio_date >= CURRENT_DATE - INTERVAL '7 days';

-- 3. Configurar refresh automático (cron)
0 1 * * * psql -U floreant -d pos -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales_by_terminal;"
```

### Fase 5: Testing y Validación (2 días)

```sql
-- 1. Verificar integridad de datos
SELECT * FROM vw_daily_diagnostics_summary;

-- 2. Comparar totales
WITH ticket_totals AS (
  SELECT 
    folio_date,
    COUNT(*) as tickets,
    SUM(total_price - total_discount) as neto
  FROM ticket
  WHERE paid=true AND voided=false
    AND folio_date = CURRENT_DATE
  GROUP BY folio_date
),
tx_totals AS (
  SELECT 
    t.folio_date,
    SUM(tx.amount) as cobrado
  FROM ticket t
  JOIN transactions tx ON tx.ticket_id = t.id
  WHERE t.paid=true AND t.voided=false
    AND tx.voided=false
    AND t.folio_date = CURRENT_DATE
  GROUP BY t.folio_date
)
SELECT 
  tt.*,
  tx.cobrado,
  tt.neto - tx.cobrado as diferencia
FROM ticket_totals tt
JOIN tx_totals tx ON tx.folio_date = tt.folio_date;

-- 3. Test de performance
EXPLAIN ANALYZE SELECT * FROM vw_sales_by_terminal 
WHERE folio_date = CURRENT_DATE;
```

## 📊 Dashboard de Monitoreo

```php
// app/Console/Commands/MonitorReports.php
class MonitorReports extends Command
{
    protected $signature = 'reports:monitor';
    
    public function handle()
    {
        // Verificar discrepancias
        $issues = DB::select('SELECT * FROM vw_daily_diagnostics_summary');
        
        if (count($issues) > 0) {
            // Enviar alerta
            Mail::to('admin@example.com')->send(new ReportIssuesAlert($issues));
        }
        
        // Log métricas
        Log::info('Report Monitor', [
            'date' => now(),
            'critical_issues' => collect($issues)->where('severity', 'CRITICAL')->count(),
            'warnings' => collect($issues)->where('severity', 'WARN')->count()
        ]);
    }
}
```

## 🔧 Configuración Laravel (.env)

```env
# Base de datos principal
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=pos
DB_USERNAME=floreant
DB_PASSWORD=your_password

# Cache para reportes
CACHE_DRIVER=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# Configuración de reportes
REPORTS_CACHE_TTL=300
REPORTS_MV_REFRESH_DAYS=7
REPORTS_EXPORT_PATH=storage/app/reports
REPORTS_CLEANUP_DAYS=7
```

## 📝 Checklist de Validación Final

### Base de Datos
- [ ] Todas las vistas compilan sin errores
- [ ] Funciones existentes verificadas
- [ ] Índices creados en columnas críticas
- [ ] Materialized views creadas y con datos
- [ ] Permisos de usuario configurados

### Laravel API
- [ ] Endpoints responden < 2 segundos
- [ ] Autenticación Sanctum funcionando
- [ ] Filtros por fecha/sucursal/terminal operativos
- [ ] Exportación Excel/PDF funcionando
- [ ] Cache Redis configurado

### Diagnósticos
- [ ] Sin discrepancias CRITICAL en producción
- [ ] Monitoreo automático configurado
- [ ] Alertas por email funcionando
- [ ] Logs de auditoría activos

### Performance
- [ ] Query execution < 500ms promedio
- [ ] Materialized views con refresh automático
- [ ] Cache hit ratio > 80%
- [ ] No deadlocks detectados

## 🚨 Problemas Comunes y Soluciones

### Error: "column does not exist"
```sql
-- Verificar nombres reales de columnas
\d ticket
\d ticket_item
\d transactions
```

### Error: "type mismatch"
```sql
-- Convertir double precision a numeric
CAST(column_name AS numeric)
```

### Performance lento
```sql
-- Analizar plan de ejecución
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM vw_sales_by_terminal;

-- Actualizar estadísticas
ANALYZE ticket;
ANALYZE transactions;
ANALYZE ticket_item;
```

## 📚 Documentación Recomendada

1. **ERD_Actual.md** - Diagrama real de tu BD
2. **API_Endpoints.md** - Documentación de endpoints
3. **Troubleshooting.md** - Guía de solución de problemas
4. **Performance_Tuning.md** - Optimizaciones

## 🎯 Siguientes Pasos Inmediatos

1. **HOY**: Hacer backup y crear BD de pruebas
2. **MAÑANA**: Ejecutar script SQL corregido en pruebas
3. **DÍA 3**: Validar datos y ajustar si necesario
4. **DÍA 4-5**: Implementar API Laravel
5. **DÍA 6**: Testing completo
6. **DÍA 7**: Deploy a producción

## 💡 Recomendación Final

**USA EL SCRIPT CORREGIDO** que preparé. Está 100% adaptado a tu estructura real y te ahorrará días de trabajo. El prompt original tiene buenos conceptos pero asume una estructura diferente a la tuya.

Si tienes dudas específicas sobre alguna vista o diagnóstico, puedo ayudarte a ajustarla.

¡Éxito con la implementación!
