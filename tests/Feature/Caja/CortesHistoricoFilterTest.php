<?php

namespace Tests\Feature\Caja;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class CortesHistoricoFilterTest extends TestCase
{
    use RefreshDatabase;

    public function test_custom_date_range_is_respected_even_when_default_filter_is_present(): void
    {
        $user = User::factory()->create();

        DB::connection('pgsql')->table('selemti.sesion_cajon')->insert([
            'id' => 9001,
            'sucursal' => 'Principal',
            'terminal_id' => 7,
            'terminal_nombre' => 'Terminal 7',
            'cajero_usuario_id' => 13,
            'apertura_ts' => '2026-04-20 08:00:00',
            'cierre_ts' => '2026-04-20 18:00:00',
            'estatus' => 'CERRADA',
            'opening_float' => 100.00,
            'closing_float' => 120.00,
            'dah_evento_id' => null,
            'skipped_precorte' => false,
        ]);

        $this->actingAs($user, 'web');

        $response = $this->get('/caja/cortes/historico?per_page=20&sort=apertura_ts&order=desc&date_filter=current_month&date_filter_radio=custom&fecha_inicio=2026-04-01&fecha_fin=2026-04-30');

        $response->assertOk();
        $response->assertSee('#9001');
        $response->assertSee('20/04/2026');
    }
}
