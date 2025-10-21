<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class UpdateVwSesionVentas extends Migration
{
    public function up()
    {
        DB::statement(<<<'SQL'
            DROP VIEW IF EXISTS selemti.vw_sesion_ventas CASCADE;

            CREATE OR REPLACE VIEW selemti.vw_sesion_ventas AS
            WITH base AS (
                SELECT
                    s.id AS sesion_id,
                    t.amount::numeric(12,2) AS monto,
                    COALESCE(
                        fp.codigo,
                        selemti.fn_normalizar_forma_pago(
                            t.payment_type::text,
                            t.transaction_type::text,
                            t.payment_sub_type::text,
                            t.custom_payment_name::text
                        )
                    ) AS codigo_fp,
                    t.transaction_time::date AS fecha
                FROM selemti.sesion_cajon s
                JOIN public.transactions t
                    ON t.transaction_time >= s.apertura_ts
                    AND t.transaction_time < COALESCE(s.cierre_ts, now())
                    AND t.terminal_id = s.terminal_id
                    AND t.user_id = s.cajero_usuario_id
                LEFT JOIN selemti.formas_pago fp
                    ON fp.payment_type = t.payment_type::text
                    AND COALESCE(fp.transaction_type, '') = COALESCE(t.transaction_type, '')::text
                    AND COALESCE(fp.payment_sub_type, '') = COALESCE(t.payment_sub_type, '')::text
                    AND COALESCE(fp.custom_name, '') = COALESCE(t.custom_payment_name, '')::text
                    AND COALESCE(fp.custom_ref, '') = COALESCE(t.custom_payment_ref, '')::text
                WHERE COALESCE(t.voided, false) = false
                    AND t.transaction_type = 'CREDIT'
            )
            SELECT
                sesion_id,
                codigo_fp,
                SUM(monto)::numeric(12,2) AS monto,
                fecha
            FROM base
            GROUP BY sesion_id, codigo_fp, fecha;
        SQL);
    }

    public function down()
    {
        DB::statement('DROP VIEW IF EXISTS selemti.vw_sesion_ventas CASCADE');
    }
}