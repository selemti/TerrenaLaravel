<?php

namespace Tests\Feature\Reports;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Gate;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Tests para el reporte de Ítems + Modificadores
 *
 * Valida:
 * - Las 3 vistas (summary_items, summary_item_mods, detail)
 * - Filtrado por sucursal
 * - Filtrado por terminal
 * - Agrupación por día
 * - Validación de totales
 */
class ItemModsReportTest extends TestCase
{
    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::firstOrCreate(
            ['email' => 'test@terrena.test'],
            ['name' => 'Test User', 'password' => bcrypt('password')]
        );

        app(PermissionRegistrar::class)->forgetCachedPermissions();
        $permission = Permission::query()->firstOrCreate([
            'name' => 'reports.view',
            'guard_name' => 'web',
        ]);
        app(PermissionRegistrar::class)->forgetCachedPermissions();
        $this->user->givePermissionTo($permission);

        Gate::define('reports.view', fn ($user) => true);
    }

    /**
     * Test que la vista summary_item_mods devuelve datos correctos
     */
    public function test_summary_item_mods_returns_correct_structure(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_item_mods',
        ]));

        $response->assertStatus(200);
        $response->assertViewHas('rows');
        $response->assertViewHas('summary');
        $response->assertViewHas('view', 'summary_item_mods');
    }

    /**
     * Test que la vista summary_items devuelve datos correctos
     */
    public function test_summary_items_returns_correct_structure(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_items',
        ]));

        $response->assertStatus(200);
        $response->assertViewHas('rows');
        $response->assertViewHas('summary');
        $response->assertViewHas('view', 'summary_items');

        // Verificar que summary tiene las claves correctas para esta vista
        $summary = $response->viewData('summary');
        $this->assertArrayHasKey('total_items', $summary);
        $this->assertArrayHasKey('total_categories', $summary);
        $this->assertArrayHasKey('total_groups', $summary);
        $this->assertArrayHasKey('total_gross', $summary);
        $this->assertArrayHasKey('total_net', $summary);
    }

    /**
     * Test que la vista detail devuelve datos correctos
     */
    public function test_detail_view_returns_correct_structure(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'detail',
        ]));

        $response->assertStatus(200);
        $response->assertViewHas('rows');
        $response->assertViewHas('summary');
        $response->assertViewHas('view', 'detail');

        // Verificar que summary tiene las claves correctas para esta vista
        $summary = $response->viewData('summary');
        $this->assertArrayHasKey('total_records', $summary);
        $this->assertArrayHasKey('total_tickets', $summary);
        $this->assertArrayHasKey('total_items', $summary);
    }

    /**
     * Test que la vista legacy sigue funcionando
     */
    public function test_legacy_view_still_works(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'legacy',
        ]));

        $response->assertStatus(200);
        $response->assertViewHas('rows');
        $response->assertViewHas('summary');
    }

    /**
     * Test que el filtro de sucursal funciona
     */
    public function test_branch_filter_works(): void
    {
        // Obtener datos sin filtro
        $responseAll = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_item_mods',
        ]));

        $allRows = $responseAll->viewData('rows');

        if ($allRows->isEmpty()) {
            $this->markTestSkipped('No hay datos para probar el filtro de sucursal');
        }

        // Obtener primera sucursal de los datos
        $firstBranch = $allRows->first()->sucursal ?? null;

        if (! $firstBranch) {
            $this->markTestSkipped('Los datos no tienen información de sucursal');
        }

        // Filtrar por esa sucursal
        $responseFiltered = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_item_mods',
            'branch' => [$firstBranch],
        ]));

        $filteredRows = $responseFiltered->viewData('rows');

        // Verificar que todas las filas tienen la sucursal correcta
        foreach ($filteredRows as $row) {
            $this->assertEquals($firstBranch, $row->sucursal ?? null);
        }
    }

    /**
     * Test que el filtro de terminal funciona
     */
    public function test_terminal_filter_works(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_item_mods',
            'terminal' => [1],
        ]));

        $response->assertStatus(200);

        $rows = $response->viewData('rows');

        if ($rows->isEmpty()) {
            $this->markTestSkipped('No hay datos para terminal 1');
        }

        // Verificar que todas las filas tienen terminal 1
        foreach ($rows as $row) {
            $this->assertEquals(1, $row->terminal ?? null);
        }
    }

    /**
     * Test que group_by_day agrega la columna fecha
     */
    public function test_group_by_day_adds_date_column(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_item_mods',
            'group_by_day' => '1',
        ]));

        $response->assertStatus(200);

        $rows = $response->viewData('rows');

        if ($rows->isEmpty()) {
            $this->markTestSkipped('No hay datos para probar agrupación por día');
        }

        // Verificar que las filas tienen la columna fecha
        $firstRow = $rows->first();
        $this->assertObjectHasProperty('fecha', $firstRow);
    }

    /**
     * Test del endpoint JSON (API)
     * NOTA: API requiere autenticación Sanctum, se omite por ahora
     */
    public function test_json_endpoint_returns_valid_response(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->getJson(route('api.reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_item_mods',
        ]));

        $response->assertStatus(200);
        $response->assertJsonStructure(['success', 'data', 'summary', 'filters']);
        $response->assertJsonPath('filters.view', 'summary_item_mods');
    }

    /**
     * Test de exportación a Excel
     */
    public function test_excel_export_works(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods.export.xlsx', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_item_mods',
        ]));

        $response->assertStatus(200);
        $response->assertHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    }

    /**
     * Test de validación de totales (coherencia interna)
     */
    public function test_summary_totals_are_consistent(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->subDays(7)->format('Y-m-d'),
            'end_date' => Carbon::now()->format('Y-m-d'),
            'view' => 'summary_item_mods',
        ]));

        $rows = $response->viewData('rows');
        $summary = $response->viewData('summary');

        if ($rows->isEmpty()) {
            $this->markTestSkipped('No hay datos para validar totales');
        }

        // Calcular total manualmente
        $manualTotal = $rows->sum(fn ($row) => (float) ($row->monto_extra_modificador ?? 0));
        $summaryTotal = (float) ($summary['total_amount'] ?? 0);

        // Verificar que coinciden (con tolerancia de 0.01 por redondeos)
        $this->assertEqualsWithDelta($manualTotal, $summaryTotal, 0.01, 'El total del summary debe coincidir con la suma de las filas');

        // Verificar que total_combinations coincide con el número de filas
        $this->assertEquals($rows->count(), $summary['total_combinations']);
    }

    /**
     * Test de validación de fechas inválidas
     */
    public function test_invalid_date_range_is_handled(): void
    {
        $response = $this->actingAs($this->user)->get(route('reports.sales.mods', [
            'start_date' => Carbon::now()->format('Y-m-d'),
            'end_date' => Carbon::now()->subDays(7)->format('Y-m-d'), // Fecha final antes que inicial
            'view' => 'summary_item_mods',
        ]));

        // El sistema debe manejar esto de alguna manera (puede ser 200 con datos vacíos o un redirect)
        $this->assertTrue(in_array($response->status(), [200, 302]));
    }

    /**
     * Test de validación contra datos conocidos
     *
     * NOTA: Este test requiere datos específicos en la base de datos de prueba.
     * Ajustar los valores esperados según los datos reales de JasperReport.
     */
    public function test_totals_match_jasper_report_baseline(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->getJson(route('api.reports.sales.mods', [
            'start_date' => '2026-05-13',
            'end_date' => '2026-05-13',
            'view' => 'summary_items',
            'sales_mode' => 'floreant_conciliation',
        ]));

        $response->assertStatus(200);

        // Baseline real de FloreantPOS/Jasper:
        // SUM(public.ticket_item.sub_total_without_modifiers) para tickets paid=true del 2026-05-13.
        $expectedGrandTotal = 19464.00;

        $this->assertEqualsWithDelta(
            $expectedGrandTotal,
            (float) $response->json('summary.total_gross'),
            0.01,
            'El total base sin modificadores debe coincidir con el baseline Jasper'
        );

        $this->assertGreaterThanOrEqual(1, count($response->json('data', [])));
    }
}
