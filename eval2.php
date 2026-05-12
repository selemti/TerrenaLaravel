<?php
use Illuminate\Support\Facades\DB;

try {
    $cols = DB::select("SELECT column_name FROM information_schema.columns WHERE table_name = 'ticket' AND table_schema = 'public'");
    $ticket_columns = array_map(function($c) { return $c->column_name; }, $cols);
    
    $create_col = 'creation_date';
    if (!in_array('creation_date', $ticket_columns)) {
        if (in_array('create_date', $ticket_columns)) $create_col = 'create_date';
        elseif (in_array('active_date', $ticket_columns)) $create_col = 'active_date';
        elseif (in_array('folio_date', $ticket_columns)) $create_col = 'folio_date';
        else $create_col = null;
    }

    $sessions_to_test = [605, 598, 596];

    foreach ($sessions_to_test as $s_id) {
        $s = DB::table('selemti.sesion_cajon')->where('id', $s_id)->first();
        
        $apertura = $s->apertura_ts;
        $cierre = $s->cierre_ts ?? date('Y-m-d H:i:s');
        $terminal = $s->terminal_id;

        $drawer = DB::select("
            SELECT COALESCE(totaldiscountamount, 0) as val
            FROM public.drawer_pull_report dpr
            WHERE dpr.terminal_id = ?
              AND dpr.report_time >= ?
              AND dpr.report_time < (?::timestamp + INTERVAL '1 day')
            ORDER BY dpr.report_time DESC LIMIT 1
        ", [$terminal, $apertura, $cierre])[0]->val ?? 0;

        $resA = DB::select("
            SELECT COUNT(*) as tickets, COALESCE(SUM(total_price), 0) as brutas, COALESCE(SUM(total_discount), 0) as netas
            FROM public.ticket
            WHERE terminal_id = ? AND voided = false
              AND closing_date >= ? AND closing_date < ?
        ", [$terminal, $apertura, $cierre])[0];

        $resB = DB::select("
            SELECT COUNT(*) as tickets, COALESCE(SUM(total_price), 0) as brutas, COALESCE(SUM(total_discount), 0) as netas
            FROM public.ticket
            WHERE terminal_id = ? AND voided = false
              AND closing_date >= ? AND closing_date <= (?::timestamp + interval '2 hours')
        ", [$terminal, $apertura, $cierre])[0];

        $resC = null;
        if ($create_col) {
            $resC = DB::select("
                SELECT COUNT(*) as tickets, COALESCE(SUM(total_price), 0) as brutas, COALESCE(SUM(total_discount), 0) as netas
                FROM public.ticket
                WHERE terminal_id = ? AND voided = false
                  AND {$create_col} >= ? AND {$create_col} <= ?
            ", [$terminal, $apertura, $cierre])[0];
        }

        echo "\n=== SESION $s_id | Terminal $terminal ===\n";
        echo "$create_col column used\n";
        echo "Apertura: $apertura | Cierre: $cierre\n";
        echo "Desc. Drawer: $drawer\n\n";

        echo "A. ESTRICTA (closing_date)\n";
        echo "   Tickets: {$resA->tickets} | Brutas: {$resA->brutas} | DescReal: {$resA->netas}\n";
        
        echo "B. TOLERANCIA +2H (closing_date)\n";
        echo "   Tickets: {$resB->tickets} | Brutas: {$resB->brutas} | DescReal: {$resB->netas}\n";
        
        if ($resC) {
            echo "C. CREACION ({$create_col})\n";
            echo "   Tickets: {$resC->tickets} | Brutas: {$resC->brutas} | DescReal: {$resC->netas}\n";
        }

        $overlap = DB::select("
            SELECT COUNT(*) as solapados
            FROM public.ticket t
            JOIN selemti.sesion_cajon s2 ON t.terminal_id = s2.terminal_id
            WHERE t.terminal_id = ? AND t.voided = false
              AND t.closing_date >= ? AND t.closing_date <= (?::timestamp + interval '2 hours')
              AND s2.id > ? AND s2.apertura_ts <= t.closing_date
        ", [$terminal, $apertura, $cierre, $s_id])[0]->solapados;

        echo "Riesgo Solapamiento B (+2H): $overlap tickets pertecencen a sesion posterior.\n";
    }
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage();
}
