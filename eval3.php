<?php
use Illuminate\Support\Facades\DB;

try {
    $sessions = DB::table('selemti.sesion_cajon')
        ->select('id', 'terminal_id', 'apertura_ts', 'cierre_ts')
        ->whereNotNull('cierre_ts')
        ->orderBy('id', 'desc')
        ->limit(300) // check many sessions
        ->get();

    $found_gaps = [];
    foreach ($sessions as $s) {
        $apertura = $s->apertura_ts;
        $cierre = $s->cierre_ts;
        $terminal = $s->terminal_id;

        $resA = DB::select("
            SELECT COUNT(*) as tickets, COALESCE(SUM(total_price), 0) as brutas
            FROM public.ticket
            WHERE terminal_id = ? AND voided = false
              AND closing_date >= ? AND closing_date < ?
        ", [$terminal, $apertura, $cierre])[0];

        $resB = DB::select("
            SELECT COUNT(*) as tickets, COALESCE(SUM(total_price), 0) as brutas
            FROM public.ticket
            WHERE terminal_id = ? AND voided = false
              AND closing_date >= ? AND closing_date <= (?::timestamp + interval '2 hours')
        ", [$terminal, $apertura, $cierre])[0];

        if ($resA->tickets != $resB->tickets) {
            $found_gaps[] = [
                'sesion' => $s->id,
                'a_tickets' => $resA->tickets,
                'a_brutas' => $resA->brutas,
                'b_tickets' => $resB->tickets,
                'b_brutas' => $resB->brutas,
                'gap' => $resB->tickets - $resA->tickets,
                'apertura' => $apertura,
                'cierre' => $cierre
            ];
            // Only output up to 5 gaps to avoid massive output
            if (count($found_gaps) >= 5) break; 
        }
    }

    echo "Found " . count($found_gaps) . " sessions where B > A.\n\n";
    foreach ($found_gaps as $g) {
        echo "=== Sesion {$g['sesion']} ===\n";
        echo "Apertura: {$g['apertura']} | Cierre: {$g['cierre']}\n";
        echo "A (Estricta): {$g['a_tickets']} tks | \${$g['a_brutas']}\n";
        echo "B (2 Hrs)   : {$g['b_tickets']} tks | \${$g['b_brutas']}\n";
        echo "Gap de {$g['gap']} tickets generados DESPUES del cierre formal.\n\n";
    }

} catch (\Exception $e) {
    echo "Error: " . $e->getMessage();
}
