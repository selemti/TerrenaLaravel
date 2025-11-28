# TAREA PARA CODEX - Implementación de Consolidación Diaria de Ventas
**Fecha**: 28 de noviembre de 2025
**Prioridad**: 🔴 ALTA (después de refactorización de reportes)
**Tiempo estimado**: 8-10 horas
**Tipo**: BACKEND - Service Layer + ETL + Scheduler

---

## 🎯 OBJETIVO

Implementar el **Data Mart de Consolidación Diaria de Ventas** que permite reportes 95% más rápidos al pre-agregar datos transaccionales del POS.

**Meta de implementación**:
- ✅ Crear 4 tablas consolidadas en schema `selemti`
- ✅ Implementar `DailySalesConsolidationService` con lógica ETL
- ✅ Crear comando Laravel para consolidación manual
- ✅ Configurar scheduler para ejecución diaria (3:00 AM)
- ✅ Backfill de 90 días históricos
- ✅ Validar con datos reales

---

## ⚠️ PRERREQUISITOS CRÍTICOS

**ANTES DE EMPEZAR, debes haber completado**:

1. ✅ **Refactorización de reportes** (3 PRs):
   - SalesExceptionsController → Service
   - SalesDetailController → Service
   - SalesSummaryController → Service

2. ✅ **Análisis de QWEN**:
   - `docs/ARCHITECTURE/CONSOLIDATION_TECHNICAL_ANALYSIS.md` debe existir
   - Lee completamente las recomendaciones de QWEN
   - Valida que queries ETL estén aprobados

**NO COMENZAR sin confirmar estos prerequisitos.**

---

## 📚 DOCUMENTOS A LEER PRIMERO

### 1. Estrategia Original
**Archivo**: `docs/ARCHITECTURE/DAILY_SALES_CONSOLIDATION_STRATEGY.md`

**Qué contiene**:
- Arquitectura de 4 tablas consolidadas
- Beneficios: 95% mejora performance
- Plan de 6 fases
- Estructura del servicio

### 2. Análisis Técnico de QWEN
**Archivo**: `docs/ARCHITECTURE/CONSOLIDATION_TECHNICAL_ANALYSIS.md`

**CRÍTICO**: Este archivo contiene:
- ✅ Validación de esquemas de tablas
- ✅ Queries ETL optimizados y probados
- ⚠️ Casos especiales a manejar
- 🔧 Modificaciones sugeridas a la estrategia original
- 📊 Índices necesarios

**SIGUE LAS RECOMENDACIONES DE QWEN**, no la estrategia original si hay conflictos.

### 3. Patrón de Referencia
**Archivo**: `app/Services/Reports/ItemModsReportService.php`

**Por qué leerlo**: Patrón de Service layer que debes seguir.

---

## 🏗️ ARQUITECTURA DE IMPLEMENTACIÓN

### Fase 1: Infraestructura (Migración de Tablas)

#### Archivo: `database/migrations/YYYY_MM_DD_create_daily_sales_consolidation_tables.php`

**Tarea**:
1. Crear migración para las 4 tablas en schema `selemti`
2. Usar las definiciones de QWEN (CONSOLIDATION_TECHNICAL_ANALYSIS.md)
3. Incluir todos los índices recomendados

**Estructura esperada**:
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    protected $connection = 'pgsql';

    public function up(): void
    {
        // Tabla 1: daily_sales_header
        DB::connection('pgsql')->statement("
            CREATE TABLE selemti.daily_sales_header (
                id SERIAL PRIMARY KEY,
                business_date DATE NOT NULL,
                branch_key VARCHAR(20) NOT NULL,
                terminal_id INT,

                -- Métricas de tickets
                total_tickets INT DEFAULT 0,
                total_voided_tickets INT DEFAULT 0,
                total_refunded_tickets INT DEFAULT 0,

                -- Métricas monetarias
                total_gross_sales DECIMAL(12,2) DEFAULT 0,
                total_discounts DECIMAL(12,2) DEFAULT 0,
                total_net_sales DECIMAL(12,2) DEFAULT 0,
                total_tax DECIMAL(12,2) DEFAULT 0,
                total_tips DECIMAL(12,2) DEFAULT 0,

                -- Métodos de pago
                total_cash DECIMAL(12,2) DEFAULT 0,
                total_card DECIMAL(12,2) DEFAULT 0,
                total_other_payments DECIMAL(12,2) DEFAULT 0,

                -- Metadata
                consolidation_status VARCHAR(20) DEFAULT 'completed',
                consolidation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                -- Constraint único
                UNIQUE(business_date, branch_key, terminal_id)
            );
        ");

        // Índices para daily_sales_header
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dsh_date_branch ON selemti.daily_sales_header(business_date, branch_key);
        ");
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dsh_date ON selemti.daily_sales_header(business_date);
        ");
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dsh_branch ON selemti.daily_sales_header(branch_key);
        ");

        // Tabla 2: daily_item_sales
        DB::connection('pgsql')->statement("
            CREATE TABLE selemti.daily_item_sales (
                id SERIAL PRIMARY KEY,
                business_date DATE NOT NULL,
                branch_key VARCHAR(20) NOT NULL,
                terminal_id INT,

                -- Item info
                menu_item_id INT NOT NULL,
                item_name VARCHAR(255),
                category_name VARCHAR(100),

                -- Métricas
                quantity_sold DECIMAL(10,2) DEFAULT 0,
                ticket_count INT DEFAULT 0,
                total_amount DECIMAL(12,2) DEFAULT 0,
                avg_unit_price DECIMAL(10,2) DEFAULT 0,

                -- Descuentos
                total_discounts DECIMAL(12,2) DEFAULT 0,
                discounted_quantity DECIMAL(10,2) DEFAULT 0,

                -- Metadata
                consolidation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                UNIQUE(business_date, branch_key, terminal_id, menu_item_id)
            );
        ");

        // Índices para daily_item_sales
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dis_date_branch_item ON selemti.daily_item_sales(business_date, branch_key, menu_item_id);
        ");
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dis_date_item ON selemti.daily_item_sales(business_date, menu_item_id);
        ");
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dis_item ON selemti.daily_item_sales(menu_item_id);
        ");

        // Tabla 3: daily_modifier_sales
        DB::connection('pgsql')->statement("
            CREATE TABLE selemti.daily_modifier_sales (
                id SERIAL PRIMARY KEY,
                business_date DATE NOT NULL,
                branch_key VARCHAR(20) NOT NULL,
                terminal_id INT,

                -- Modifier info
                modifier_id INT NOT NULL,
                modifier_name VARCHAR(255),
                modifier_group_name VARCHAR(100),

                -- Relación con item padre
                menu_item_id INT,
                item_name VARCHAR(255),

                -- Métricas
                quantity_sold INT DEFAULT 0,
                ticket_count INT DEFAULT 0,
                total_amount DECIMAL(12,2) DEFAULT 0,

                -- Metadata
                consolidation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                UNIQUE(business_date, branch_key, terminal_id, modifier_id, menu_item_id)
            );
        ");

        // Índices para daily_modifier_sales
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dms_date_branch_mod ON selemti.daily_modifier_sales(business_date, branch_key, modifier_id);
        ");
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dms_modifier ON selemti.daily_modifier_sales(modifier_id);
        ");

        // Tabla 4: daily_misc_sales (CRÍTICA - misceláneos)
        DB::connection('pgsql')->statement("
            CREATE TABLE selemti.daily_misc_sales (
                id SERIAL PRIMARY KEY,
                business_date DATE NOT NULL,
                branch_key VARCHAR(20) NOT NULL,
                terminal_id INT,

                -- Misc item info (sin menu_item_id)
                misc_item_name VARCHAR(255) NOT NULL,
                misc_item_name_normalized VARCHAR(255),

                -- Métricas
                quantity_sold DECIMAL(10,2) DEFAULT 0,
                ticket_count INT DEFAULT 0,
                total_amount DECIMAL(12,2) DEFAULT 0,
                avg_unit_price DECIMAL(10,2) DEFAULT 0,

                -- Metadata
                consolidation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                UNIQUE(business_date, branch_key, terminal_id, misc_item_name_normalized)
            );
        ");

        // Índices para daily_misc_sales
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dmisc_date_branch ON selemti.daily_misc_sales(business_date, branch_key);
        ");
        DB::connection('pgsql')->statement("
            CREATE INDEX idx_dmisc_name_norm ON selemti.daily_misc_sales(misc_item_name_normalized);
        ");
    }

    public function down(): void
    {
        DB::connection('pgsql')->statement("DROP TABLE IF EXISTS selemti.daily_misc_sales CASCADE");
        DB::connection('pgsql')->statement("DROP TABLE IF EXISTS selemti.daily_modifier_sales CASCADE");
        DB::connection('pgsql')->statement("DROP TABLE IF EXISTS selemti.daily_item_sales CASCADE");
        DB::connection('pgsql')->statement("DROP TABLE IF EXISTS selemti.daily_sales_header CASCADE");
    }
};
```

**IMPORTANTE**:
- ⚠️ Ajusta campos según recomendaciones de QWEN
- ⚠️ Si QWEN sugirió cambios, úsalos en lugar de esta estructura base
- ✅ Ejecuta `php artisan migrate` para crear tablas

---

### Fase 2: Service Layer

#### Archivo: `app/Services/Reports/DailySalesConsolidationService.php`

**Estructura completa**:

```php
<?php

namespace App\Services\Reports;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DailySalesConsolidationService
{
    /**
     * Consolida un día específico
     */
    public function consolidateDate(Carbon $businessDate): ConsolidationResult
    {
        Log::info("Consolidando ventas para: {$businessDate->format('Y-m-d')}");

        DB::connection('pgsql')->beginTransaction();

        try {
            $result = new ConsolidationResult($businessDate);

            // Paso 1: Consolidar header (resumen diario)
            $headerRecords = $this->consolidateHeader($businessDate);
            $result->headerRecords = $headerRecords;
            Log::info("Header consolidado: {$headerRecords} registros");

            // Paso 2: Consolidar items vendidos
            $itemRecords = $this->consolidateItems($businessDate);
            $result->itemRecords = $itemRecords;
            Log::info("Items consolidados: {$itemRecords} registros");

            // Paso 3: Consolidar modificadores
            $modifierRecords = $this->consolidateModifiers($businessDate);
            $result->modifierRecords = $modifierRecords;
            Log::info("Modificadores consolidados: {$modifierRecords} registros");

            // Paso 4: Consolidar misceláneos
            $miscRecords = $this->consolidateMisc($businessDate);
            $result->miscRecords = $miscRecords;
            Log::info("Misceláneos consolidados: {$miscRecords} registros");

            DB::connection('pgsql')->commit();

            $result->status = 'completed';
            $result->message = "Consolidación exitosa";
            Log::info("Consolidación completada exitosamente");

            return $result;

        } catch (\Exception $e) {
            DB::connection('pgsql')->rollBack();
            Log::error("Error en consolidación: {$e->getMessage()}");

            $result->status = 'failed';
            $result->message = $e->getMessage();
            return $result;
        }
    }

    /**
     * Consolida rango de fechas
     */
    public function consolidateDateRange(Carbon $startDate, Carbon $endDate): array
    {
        $results = [];
        $current = $startDate->copy();

        while ($current->lte($endDate)) {
            $results[] = $this->consolidateDate($current->copy());
            $current->addDay();
        }

        return $results;
    }

    /**
     * Re-procesa un día (elimina y vuelve a consolidar)
     */
    public function reprocessDate(Carbon $businessDate): ConsolidationResult
    {
        Log::info("Re-procesando: {$businessDate->format('Y-m-d')}");

        // Eliminar registros existentes
        $this->deleteConsolidationForDate($businessDate);

        // Volver a consolidar
        return $this->consolidateDate($businessDate);
    }

    /**
     * Valida que consolidación esté completa y correcta
     */
    public function validateConsolidation(Carbon $businessDate): ValidationResult
    {
        // Comparar totales de consolidado vs transaccional
        $validation = new ValidationResult($businessDate);

        // Total tickets
        $transactionalTickets = $this->getTransactionalTicketCount($businessDate);
        $consolidatedTickets = $this->getConsolidatedTicketCount($businessDate);

        $validation->transactionalTickets = $transactionalTickets;
        $validation->consolidatedTickets = $consolidatedTickets;
        $validation->ticketsMatch = ($transactionalTickets === $consolidatedTickets);

        // Total ventas
        $transactionalSales = $this->getTransactionalSales($businessDate);
        $consolidatedSales = $this->getConsolidatedSales($businessDate);

        $validation->transactionalSales = $transactionalSales;
        $validation->consolidatedSales = $consolidatedSales;
        $validation->salesMatch = (abs($transactionalSales - $consolidatedSales) < 0.01);

        $validation->isValid = $validation->ticketsMatch && $validation->salesMatch;

        return $validation;
    }

    // ===== MÉTODOS PROTECTED (ETL) =====

    /**
     * Consolida daily_sales_header
     */
    protected function consolidateHeader(Carbon $businessDate): int
    {
        $dateStr = $businessDate->format('Y-m-d');

        // Eliminar registros existentes de este día
        DB::connection('pgsql')
            ->table('selemti.daily_sales_header')
            ->whereDate('business_date', $dateStr)
            ->delete();

        // Query ETL (usar el de QWEN)
        $query = "
            INSERT INTO selemti.daily_sales_header (
                business_date, branch_key, terminal_id,
                total_tickets, total_voided_tickets, total_refunded_tickets,
                total_gross_sales, total_discounts, total_net_sales,
                total_tax, total_tips,
                total_cash, total_card, total_other_payments,
                consolidation_status, consolidation_date
            )
            SELECT
                DATE(t.closing_date) as business_date,
                t.branch_key,
                t.terminal_id,

                COUNT(*) FILTER (WHERE t.voided = false) as total_tickets,
                COUNT(*) FILTER (WHERE t.voided = true) as total_voided_tickets,
                COUNT(*) FILTER (WHERE t.refunded = true) as total_refunded_tickets,

                SUM(t.subtotal_amount) FILTER (WHERE t.voided = false) as total_gross_sales,
                SUM(t.discount_amount) FILTER (WHERE t.voided = false) as total_discounts,
                SUM(t.total_amount) FILTER (WHERE t.voided = false) as total_net_sales,
                SUM(t.tax_amount) FILTER (WHERE t.voided = false) as total_tax,
                SUM(t.gratuity) FILTER (WHERE t.voided = false) as total_tips,

                -- Totales por método de pago (requiere JOIN con transactions)
                SUM(tx.amount) FILTER (WHERE tx.payment_type = 'CASH' AND t.voided = false) as total_cash,
                SUM(tx.amount) FILTER (WHERE tx.payment_type IN ('CREDIT_CARD', 'DEBIT_CARD') AND t.voided = false) as total_card,
                SUM(tx.amount) FILTER (WHERE tx.payment_type NOT IN ('CASH', 'CREDIT_CARD', 'DEBIT_CARD') AND t.voided = false) as total_other_payments,

                'completed' as consolidation_status,
                CURRENT_TIMESTAMP as consolidation_date

            FROM public.ticket t
            LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
            WHERE DATE(t.closing_date) = :businessDate
                AND t.paid = true
            GROUP BY DATE(t.closing_date), t.branch_key, t.terminal_id
        ";

        // ⚠️ IMPORTANTE: Usa el query de QWEN si es diferente

        return DB::connection('pgsql')->insert($query, ['businessDate' => $dateStr]);
    }

    /**
     * Consolida daily_item_sales
     */
    protected function consolidateItems(Carbon $businessDate): int
    {
        $dateStr = $businessDate->format('Y-m-d');

        DB::connection('pgsql')
            ->table('selemti.daily_item_sales')
            ->whereDate('business_date', $dateStr)
            ->delete();

        $query = "
            INSERT INTO selemti.daily_item_sales (
                business_date, branch_key, terminal_id,
                menu_item_id, item_name, category_name,
                quantity_sold, ticket_count, total_amount, avg_unit_price,
                total_discounts, discounted_quantity,
                consolidation_date
            )
            SELECT
                DATE(t.closing_date) as business_date,
                t.branch_key,
                t.terminal_id,

                ti.menu_item_id,
                mi.name as item_name,
                mc.name as category_name,

                SUM(ti.quantity) as quantity_sold,
                COUNT(DISTINCT t.id) as ticket_count,
                SUM(ti.unit_price * ti.quantity) as total_amount,
                AVG(ti.unit_price) as avg_unit_price,

                COALESCE(SUM(tid.discount_amount), 0) as total_discounts,
                COALESCE(SUM(ti.quantity) FILTER (WHERE tid.discount_amount > 0), 0) as discounted_quantity,

                CURRENT_TIMESTAMP as consolidation_date

            FROM public.ticket_item ti
            JOIN public.ticket t ON t.id = ti.ticket_id
            LEFT JOIN public.menu_item mi ON mi.id = ti.menu_item_id
            LEFT JOIN public.menu_category mc ON mc.id = mi.category_id
            LEFT JOIN public.ticket_item_discount tid ON tid.ticket_item_id = ti.id
            WHERE DATE(t.closing_date) = :businessDate
                AND t.paid = true
                AND t.voided = false
                AND ti.menu_item_id IS NOT NULL
            GROUP BY DATE(t.closing_date), t.branch_key, t.terminal_id, ti.menu_item_id, mi.name, mc.name
        ";

        return DB::connection('pgsql')->insert($query, ['businessDate' => $dateStr]);
    }

    /**
     * Consolida daily_modifier_sales
     */
    protected function consolidateModifiers(Carbon $businessDate): int
    {
        $dateStr = $businessDate->format('Y-m-d');

        DB::connection('pgsql')
            ->table('selemti.daily_modifier_sales')
            ->whereDate('business_date', $dateStr)
            ->delete();

        $query = "
            INSERT INTO selemti.daily_modifier_sales (
                business_date, branch_key, terminal_id,
                modifier_id, modifier_name, modifier_group_name,
                menu_item_id, item_name,
                quantity_sold, ticket_count, total_amount,
                consolidation_date
            )
            SELECT
                DATE(t.closing_date) as business_date,
                t.branch_key,
                t.terminal_id,

                tim.menu_modifier_id as modifier_id,
                mm.name as modifier_name,
                mmg.name as modifier_group_name,

                ti.menu_item_id,
                mi.name as item_name,

                COUNT(*) as quantity_sold,
                COUNT(DISTINCT t.id) as ticket_count,
                SUM(tim.extra_price) as total_amount,

                CURRENT_TIMESTAMP as consolidation_date

            FROM public.ticket_item_modifier tim
            JOIN public.ticket_item ti ON ti.id = tim.ticket_item_id
            JOIN public.ticket t ON t.id = ti.ticket_id
            LEFT JOIN public.menu_modifier mm ON mm.id = tim.menu_modifier_id
            LEFT JOIN public.modifier_group mmg ON mmg.id = mm.modifier_group_id
            LEFT JOIN public.menu_item mi ON mi.id = ti.menu_item_id
            WHERE DATE(t.closing_date) = :businessDate
                AND t.paid = true
                AND t.voided = false
            GROUP BY DATE(t.closing_date), t.branch_key, t.terminal_id, tim.menu_modifier_id, mm.name, mmg.name, ti.menu_item_id, mi.name
        ";

        return DB::connection('pgsql')->insert($query, ['businessDate' => $dateStr]);
    }

    /**
     * Consolida daily_misc_sales (CRÍTICO - misceláneos)
     */
    protected function consolidateMisc(Carbon $businessDate): int
    {
        $dateStr = $businessDate->format('Y-m-d');

        DB::connection('pgsql')
            ->table('selemti.daily_misc_sales')
            ->whereDate('business_date', $dateStr)
            ->delete();

        $query = "
            INSERT INTO selemti.daily_misc_sales (
                business_date, branch_key, terminal_id,
                misc_item_name, misc_item_name_normalized,
                quantity_sold, ticket_count, total_amount, avg_unit_price,
                consolidation_date
            )
            SELECT
                DATE(t.closing_date) as business_date,
                t.branch_key,
                t.terminal_id,

                ti.name as misc_item_name,
                LOWER(TRIM(ti.name)) as misc_item_name_normalized,

                SUM(ti.quantity) as quantity_sold,
                COUNT(DISTINCT t.id) as ticket_count,
                SUM(ti.unit_price * ti.quantity) as total_amount,
                AVG(ti.unit_price) as avg_unit_price,

                CURRENT_TIMESTAMP as consolidation_date

            FROM public.ticket_item ti
            JOIN public.ticket t ON t.id = ti.ticket_id
            WHERE DATE(t.closing_date) = :businessDate
                AND t.paid = true
                AND t.voided = false
                AND ti.menu_item_id IS NULL
            GROUP BY DATE(t.closing_date), t.branch_key, t.terminal_id, ti.name, LOWER(TRIM(ti.name))
        ";

        return DB::connection('pgsql')->insert($query, ['businessDate' => $dateStr]);
    }

    // ===== MÉTODOS AUXILIARES =====

    protected function deleteConsolidationForDate(Carbon $businessDate): void
    {
        $dateStr = $businessDate->format('Y-m-d');

        DB::connection('pgsql')->table('selemti.daily_sales_header')->whereDate('business_date', $dateStr)->delete();
        DB::connection('pgsql')->table('selemti.daily_item_sales')->whereDate('business_date', $dateStr)->delete();
        DB::connection('pgsql')->table('selemti.daily_modifier_sales')->whereDate('business_date', $dateStr)->delete();
        DB::connection('pgsql')->table('selemti.daily_misc_sales')->whereDate('business_date', $dateStr)->delete();
    }

    protected function getTransactionalTicketCount(Carbon $businessDate): int
    {
        return DB::connection('pgsql')
            ->table('public.ticket')
            ->whereDate('closing_date', $businessDate->format('Y-m-d'))
            ->where('paid', true)
            ->where('voided', false)
            ->count();
    }

    protected function getConsolidatedTicketCount(Carbon $businessDate): int
    {
        return DB::connection('pgsql')
            ->table('selemti.daily_sales_header')
            ->whereDate('business_date', $businessDate->format('Y-m-d'))
            ->sum('total_tickets');
    }

    protected function getTransactionalSales(Carbon $businessDate): float
    {
        return DB::connection('pgsql')
            ->table('public.ticket')
            ->whereDate('closing_date', $businessDate->format('Y-m-d'))
            ->where('paid', true)
            ->where('voided', false)
            ->sum('total_amount') ?? 0.0;
    }

    protected function getConsolidatedSales(Carbon $businessDate): float
    {
        return DB::connection('pgsql')
            ->table('selemti.daily_sales_header')
            ->whereDate('business_date', $businessDate->format('Y-m-d'))
            ->sum('total_net_sales') ?? 0.0;
    }
}

// ===== CLASES DE RESULTADO =====

class ConsolidationResult
{
    public Carbon $businessDate;
    public string $status = 'pending';
    public string $message = '';
    public int $headerRecords = 0;
    public int $itemRecords = 0;
    public int $modifierRecords = 0;
    public int $miscRecords = 0;

    public function __construct(Carbon $businessDate)
    {
        $this->businessDate = $businessDate;
    }
}

class ValidationResult
{
    public Carbon $businessDate;
    public int $transactionalTickets = 0;
    public int $consolidatedTickets = 0;
    public bool $ticketsMatch = false;
    public float $transactionalSales = 0.0;
    public float $consolidatedSales = 0.0;
    public bool $salesMatch = false;
    public bool $isValid = false;

    public function __construct(Carbon $businessDate)
    {
        $this->businessDate = $businessDate;
    }
}
```

**IMPORTANTE**:
- ⚠️ **USA LOS QUERIES DE QWEN**, no estos de ejemplo
- ⚠️ Si QWEN identificó que `ticket_item.name` no existe, ajusta el query de misceláneos
- ✅ Los queries deben usar filtros: `paid = true` y `voided = false`

---

### Fase 3: Comando Laravel

#### Archivo: `app/Console/Commands/ConsolidateDailySales.php`

```php
<?php

namespace App\Console\Commands;

use App\Services\Reports\DailySalesConsolidationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class ConsolidateDailySales extends Command
{
    protected $signature = 'sales:consolidate
                            {date? : Fecha a consolidar (YYYY-MM-DD), por defecto ayer}
                            {--from= : Fecha inicial para rango (YYYY-MM-DD)}
                            {--to= : Fecha final para rango (YYYY-MM-DD)}
                            {--reprocess : Re-procesar día (eliminar y volver a consolidar)}
                            {--validate : Solo validar sin consolidar}';

    protected $description = 'Consolida ventas diarias en tablas agregadas';

    public function __construct(
        protected DailySalesConsolidationService $service
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        try {
            // Modo validación
            if ($this->option('validate')) {
                return $this->validateConsolidation();
            }

            // Modo rango de fechas
            if ($this->option('from') && $this->option('to')) {
                return $this->consolidateRange();
            }

            // Modo día único
            return $this->consolidateSingleDay();

        } catch (\Exception $e) {
            $this->error("Error: {$e->getMessage()}");
            return self::FAILURE;
        }
    }

    protected function consolidateSingleDay(): int
    {
        $dateStr = $this->argument('date') ?? Carbon::yesterday()->format('Y-m-d');
        $date = Carbon::parse($dateStr);

        $this->info("Consolidando ventas para: {$date->format('Y-m-d')}");

        if ($this->option('reprocess')) {
            $this->warn("Re-procesando (eliminar existente)...");
            $result = $this->service->reprocessDate($date);
        } else {
            $result = $this->service->consolidateDate($date);
        }

        if ($result->status === 'completed') {
            $this->info("✅ Consolidación exitosa");
            $this->table(
                ['Tabla', 'Registros'],
                [
                    ['Header', $result->headerRecords],
                    ['Items', $result->itemRecords],
                    ['Modifiers', $result->modifierRecords],
                    ['Misc', $result->miscRecords],
                ]
            );
            return self::SUCCESS;
        } else {
            $this->error("❌ Consolidación falló: {$result->message}");
            return self::FAILURE;
        }
    }

    protected function consolidateRange(): int
    {
        $start = Carbon::parse($this->option('from'));
        $end = Carbon::parse($this->option('to'));

        $this->info("Consolidando rango: {$start->format('Y-m-d')} a {$end->format('Y-m-d')}");
        $this->info("Total días: {$start->diffInDays($end) + 1}");

        $bar = $this->output->createProgressBar($start->diffInDays($end) + 1);
        $bar->start();

        $results = $this->service->consolidateDateRange($start, $end);

        $bar->finish();
        $this->newLine();

        $successful = collect($results)->where('status', 'completed')->count();
        $failed = collect($results)->where('status', 'failed')->count();

        $this->info("✅ Exitosos: {$successful}");
        if ($failed > 0) {
            $this->warn("⚠️ Fallidos: {$failed}");
        }

        return $failed > 0 ? self::FAILURE : self::SUCCESS;
    }

    protected function validateConsolidation(): int
    {
        $dateStr = $this->argument('date') ?? Carbon::yesterday()->format('Y-m-d');
        $date = Carbon::parse($dateStr);

        $this->info("Validando consolidación para: {$date->format('Y-m-d')}");

        $validation = $this->service->validateConsolidation($date);

        $this->table(
            ['Métrica', 'Transaccional', 'Consolidado', 'Match'],
            [
                ['Tickets', $validation->transactionalTickets, $validation->consolidatedTickets, $validation->ticketsMatch ? '✅' : '❌'],
                ['Ventas', number_format($validation->transactionalSales, 2), number_format($validation->consolidatedSales, 2), $validation->salesMatch ? '✅' : '❌'],
            ]
        );

        if ($validation->isValid) {
            $this->info("✅ Validación exitosa - datos coinciden");
            return self::SUCCESS;
        } else {
            $this->error("❌ Validación falló - discrepancias encontradas");
            return self::FAILURE;
        }
    }
}
```

**Uso del comando**:
```bash
# Consolidar ayer (por defecto)
php artisan sales:consolidate

# Consolidar día específico
php artisan sales:consolidate 2025-11-15

# Consolidar rango (backfill)
php artisan sales:consolidate --from=2025-09-01 --to=2025-11-27

# Re-procesar día
php artisan sales:consolidate 2025-11-15 --reprocess

# Validar sin consolidar
php artisan sales:consolidate 2025-11-15 --validate
```

---

### Fase 4: Scheduler (Ejecución Automática)

#### Archivo: `app/Console/Kernel.php`

Agregar en el método `schedule()`:

```php
protected function schedule(Schedule $schedule): void
{
    // Consolidación diaria a las 3:00 AM
    $schedule->command('sales:consolidate')
        ->dailyAt('03:00')
        ->onOneServer()
        ->withoutOverlapping()
        ->sendOutputTo(storage_path('logs/consolidation.log'))
        ->emailOutputOnFailure('admin@terrena.com');
}
```

**Verificar que cron esté configurado**:
```bash
* * * * * cd /path-to-your-project && php artisan schedule:run >> /dev/null 2>&1
```

---

### Fase 5: Backfill Histórico

**Comando para cargar 90 días**:
```bash
php artisan sales:consolidate --from=2025-08-28 --to=2025-11-27
```

**Monitorear progreso**:
```bash
tail -f storage/logs/consolidation.log
```

**Validar después del backfill**:
```bash
# Validar día aleatorio
php artisan sales:consolidate 2025-10-15 --validate

# Query directo
psql -h localhost -p 5433 -U postgres -d pos -c "
SELECT business_date, branch_key, total_tickets, total_net_sales
FROM selemti.daily_sales_header
WHERE business_date >= '2025-08-28'
ORDER BY business_date DESC
LIMIT 10;
"
```

---

## 🧪 VALIDACIÓN

### Validación 1: Tablas creadas

```bash
psql -h localhost -p 5433 -U postgres -d pos -c "\dt selemti.daily*"
```

Debe mostrar:
```
 Schema  |         Name          | Type  |  Owner
---------+-----------------------+-------+----------
 selemti | daily_sales_header    | table | postgres
 selemti | daily_item_sales      | table | postgres
 selemti | daily_modifier_sales  | table | postgres
 selemti | daily_misc_sales      | table | postgres
```

---

### Validación 2: Consolidación funciona

```bash
php artisan sales:consolidate 2025-11-15
```

Debe mostrar:
```
✅ Consolidación exitosa
+-----------+-----------+
| Tabla     | Registros |
+-----------+-----------+
| Header    | 5         |
| Items     | 147       |
| Modifiers | 89        |
| Misc      | 12        |
+-----------+-----------+
```

---

### Validación 3: Datos son correctos

```bash
php artisan sales:consolidate 2025-11-15 --validate
```

Debe mostrar:
```
✅ Validación exitosa - datos coinciden
+---------+----------------+--------------+-------+
| Métrica | Transaccional  | Consolidado  | Match |
+---------+----------------+--------------+-------+
| Tickets | 156            | 156          | ✅    |
| Ventas  | 194,905.50     | 194,905.50   | ✅    |
+---------+----------------+--------------+-------+
```

---

### Validación 4: Performance

Comparar query directo vs consolidado:

**Query directo** (lento):
```sql
-- 15-30 segundos para 30 días
SELECT DATE(t.closing_date), COUNT(*)
FROM public.ticket t
WHERE t.closing_date >= '2025-10-15' AND t.closing_date < '2025-11-15'
GROUP BY DATE(t.closing_date);
```

**Query consolidado** (rápido):
```sql
-- < 1 segundo para 30 días
SELECT business_date, SUM(total_tickets)
FROM selemti.daily_sales_header
WHERE business_date >= '2025-10-15' AND business_date < '2025-11-15'
GROUP BY business_date;
```

---

## 📝 DOCUMENTACIÓN REQUERIDA

Crear archivo: **`docs/REPORTS/CONSOLIDATION_IMPLEMENTATION.md`**

```markdown
# Implementación: Consolidación Diaria de Ventas
**Fecha**: 28-Nov-2025
**Desarrollador**: CODEX
**Basado en análisis**: QWEN (CONSOLIDATION_TECHNICAL_ANALYSIS.md)

---

## Archivos Creados

### Migración
- `database/migrations/YYYY_MM_DD_create_daily_sales_consolidation_tables.php`
- Tablas: 4 (header, items, modifiers, misc)
- Índices: 9 totales

### Service
- `app/Services/Reports/DailySalesConsolidationService.php`
- Métodos: consolidateDate(), consolidateDateRange(), reprocessDate(), validateConsolidation()
- Queries ETL: 4 (uno por tabla)

### Comando
- `app/Console/Commands/ConsolidateDailySales.php`
- Opciones: single day, range, reprocess, validate
- Scheduler: 3:00 AM diario

---

## Validación Realizada

### Datos de Prueba
- Día consolidado: 2025-11-15
- Registros header: 5
- Registros items: 147
- Registros modifiers: 89
- Registros misc: 12

### Validación de Totales
| Métrica | Transaccional | Consolidado | Match |
|---------|---------------|-------------|-------|
| Tickets | 156 | 156 | ✅ |
| Ventas | $194,905.50 | $194,905.50 | ✅ |

### Backfill Histórico
- Rango: 2025-08-28 a 2025-11-27 (90 días)
- Tiempo total: X minutos
- Registros totales: X

---

## Performance

| Métrica | Antes (directo) | Después (consolidado) | Mejora |
|---------|-----------------|----------------------|--------|
| Query 30 días | 15-30 seg | < 1 seg | 95%+ |
| Query 90 días | 45-90 seg | < 1 seg | 98%+ |
| Query 1 año | Inviable | < 2 seg | ∞ |

---

## Mantenimiento

### Ejecución Manual
```bash
# Consolidar ayer
php artisan sales:consolidate

# Consolidar día específico
php artisan sales:consolidate 2025-11-15

# Backfill rango
php artisan sales:consolidate --from=2025-09-01 --to=2025-11-27
```

### Re-proceso
```bash
# Si hay error en consolidación
php artisan sales:consolidate 2025-11-15 --reprocess
```

### Validación
```bash
# Verificar integridad
php artisan sales:consolidate 2025-11-15 --validate
```

---

## Próximos Pasos

1. Actualizar reportes existentes para usar tablas consolidadas
2. Crear vistas SQL para queries complejos
3. Implementar monitoreo de consolidación diaria
```

---

## 📦 ENTREGA

### Pull Request: `codex/feature-daily-sales-consolidation`

**Archivos**:
- ✅ Migración de tablas
- ✅ Service layer completo
- ✅ Comando Laravel
- ✅ Scheduler configurado
- ✅ Documentación de implementación
- ✅ Evidencia de validación

**Checklist antes de PR**:
- [ ] Tablas creadas en PostgreSQL
- [ ] Migración ejecutada exitosamente
- [ ] Service compila sin errores
- [ ] Comando funciona para día único
- [ ] Comando funciona para rango
- [ ] Validación muestra 100% match
- [ ] Backfill de 90 días completo
- [ ] Performance > 90% mejora demostrada
- [ ] Scheduler configurado
- [ ] Documentación completa

---

## ⏱️ TIEMPO ESTIMADO

| Fase | Descripción | Tiempo |
|------|-------------|--------|
| 1 | Crear migración de tablas | 1 hora |
| 2 | Implementar Service (4 queries ETL) | 3 horas |
| 3 | Crear comando Laravel | 1 hora |
| 4 | Configurar scheduler | 30 min |
| 5 | Backfill 90 días | 1 hora |
| 6 | Validación exhaustiva | 1.5 horas |
| 7 | Documentación | 1 hora |
| **TOTAL** | | **9 horas** |

---

## 🚨 REGLAS CRÍTICAS

### ✅ DEBES:
- ✅ Usar queries de QWEN (análisis técnico)
- ✅ Usar transacciones para atomicidad
- ✅ Validar datos antes de commit
- ✅ Manejar errores con rollback
- ✅ Loggear todo el proceso
- ✅ Incluir progress bars en comandos
- ✅ Filtrar solo `paid = true` y `voided = false`

### ❌ NO DEBES:
- ❌ Modificar schema `public` (solo lectura)
- ❌ Usar SQL crudo sin prepared statements
- ❌ Consolidar sin validar primero
- ❌ Olvidar índices (crítico para performance)
- ❌ Hardcodear fechas o valores
- ❌ Dejar queries sin optimizar

---

## 🎯 CRITERIOS DE ÉXITO

Tu implementación será exitosa si:

✅ Las 4 tablas consolidadas están creadas con índices
✅ Service consolidateDate() funciona sin errores
✅ Validación muestra 100% match (tickets + ventas)
✅ Backfill de 90 días completo
✅ Performance > 90% mejora vs queries directos
✅ Scheduler configurado para 3:00 AM
✅ Comando permite: single day, range, reprocess, validate
✅ Documentación completa con evidencia
✅ PR listo para merge

---

**Última actualización**: 28-Nov-2025
**Creado por**: Claude Code
**Para**: CODEX (agente de backend)
**Depende de**: QWEN (análisis técnico completado)
