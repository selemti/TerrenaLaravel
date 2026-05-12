<?php
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

try {
    $columns = Schema::getColumnListing('ticket');
    
    $sessions = DB::table('selemti.sesion_cajon')
        ->join('selemti.postcorte', 'postcorte.sesion_id', '=', 'sesion_cajon.id')
        ->select('sesion_cajon.id', 'sesion_cajon.terminal_id', 'sesion_cajon.apertura_ts', 'sesion_cajon.cierre_ts', 'postcorte.total_ventas_brutas', 'postcorte.sistema_efectivo_esperado')
        ->where('postcorte.total_ventas_brutas', '<=', 0)
        ->whereNotNull('sesion_cajon.cierre_ts')
        ->orderBy('sesion_cajon.id', 'desc')
        ->limit(3)
        ->get();

    if ($sessions->isEmpty()) {
        // Fallback to any recent sessions if none have 0
        $sessions = DB::table('selemti.sesion_cajon')
            ->select('id', 'terminal_id', 'apertura_ts', 'cierre_ts')
            ->whereNotNull('cierre_ts')
            ->orderBy('id', 'desc')
            ->limit(3)
            ->get();
    }

    $transactionsCols = Schema::getColumnListing('transactions');

    echo "=== TICKET COLUMNS ===\n" . implode(", ", $columns) . "\n\n";
    echo "=== TRANSACTIONS COLUMNS ===\n" . implode(", ", $transactionsCols) . "\n\n";
    echo "=== PROBLEMATIC SESSIONS ===\n";
    foreach ($sessions as $s) {
        echo "Session ID: {$s->id} | Terminal: {$s->terminal_id} | Apertura: {$s->apertura_ts} | Cierre: {$s->cierre_ts}\n";
    }
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage();
}
