-- kardex-integrity-check.sql
-- Calcula saldos basados en movimientos y compara con stock de inventory_batch
-- Sólo lectura, sin modificar datos.

WITH calculo_movs AS (
    SELECT
        mi.item_id,
        SUM(mi.qty * ct.signo) AS saldo_calculado
    FROM
        selemti.mov_inv mi
        JOIN selemti.cat_tipo_mov_inv ct ON mi.tipo = ct.clave
    GROUP BY
        mi.item_id
),
calculo_batches AS (
    SELECT
        item_id,
        SUM(cantidad_actual) AS saldo_batch
    FROM
        selemti.inventory_batch
    GROUP BY
        item_id
)
SELECT
    COALESCE(m.item_id, b.item_id) AS item_id,
    COALESCE(m.saldo_calculado, 0) AS saldo_calculado,
    COALESCE(b.saldo_batch, 0) AS saldo_batch,
    (COALESCE(m.saldo_calculado, 0) - COALESCE(b.saldo_batch, 0)) AS diferencia
FROM
    calculo_movs m
    FULL OUTER JOIN calculo_batches b ON m.item_id = b.item_id
WHERE
    (COALESCE(m.saldo_calculado, 0) - COALESCE(b.saldo_batch, 0)) <> 0;
