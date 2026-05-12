\o 'C:/xampp3/htdocs/TerrenaLaravel/tmp_caja_data.txt'
\echo '==== POSTCORTE TABLE ===='
SELECT * FROM selemti.postcorte ORDER BY id DESC LIMIT 5;

\echo '==== PRECORTE TABLE ===='
SELECT * FROM selemti.precorte ORDER BY id DESC LIMIT 5;

\echo '==== PRECORTE EFECTIVO TABLE ===='
SELECT * FROM selemti.precorte_efectivo ORDER BY id DESC LIMIT 5;

\echo '==== TICKET MODIFIERS TABLE ===='
SELECT * FROM selemti.ticket_item_modifiers ORDER BY id DESC LIMIT 5;
\o
