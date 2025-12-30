-- SQL para corregir el problema de items sin modificadores mostrados en cero
-- El problema está en que solo se muestran items que tienen modificadores

-- Vista corregida que muestra TODOS los items (con y sin modificadores)
CREATE OR REPLACE VIEW vw_item_mods_corregidos AS
WITH base_data AS (
    -- Items con modificadores (lógica original simplificada)
    SELECT
        ti.category_name AS categoria,
        ti.group_name AS grupo_menu,
        ti.item_name AS menu_item,
        ti.item_price AS precio_item,
        ti.total_price_without_modifiers AS total_sin_mods,
        SUM(COALESCE(tim.item_count, 0)) AS selecciones_modificador,
        SUM(COALESCE(tim.modifier_price, 0) * COALESCE(tim.item_count, 0)) AS monto_extra_modificador,
        COUNT(DISTINCT tim.id) as num_modificadores_distintos,
        COUNT(*) as lineas_con_mods,
        t.branch_key AS sucursal,
        t.terminal_id AS terminal,
        t.closing_date::date AS fecha
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
    WHERE t.closing_date >= '2025-08-01'
      AND t.closing_date <= '2025-12-09 23:59:59'
      AND t.paid = true
      AND t.voided = false
    GROUP BY ti.category_name, ti.group_name, ti.item_name, ti.item_price, ti.total_price_without_modifiers, t.branch_key, t.terminal_id, t.closing_date::date

    UNION ALL

    -- Items SIN modificadores (el problema principal)
    SELECT
        ti.category_name AS categoria,
        ti.group_name AS grupo_menu,
        ti.item_name AS menu_item,
        ti.item_price AS precio_item,
        ti.total_price_without_modifiers AS total_sin_mods,
        0 AS selecciones_modificador,
        0 AS monto_extra_modificador,
        0 AS num_modificadores_distintos,
        0 AS lineas_con_mods,
        t.branch_key AS sucursal,
        t.terminal_id AS terminal,
        t.closing_date::date AS fecha
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
    WHERE t.closing_date >= '2025-08-01'
      AND t.closing_date <= '2025-12-09 23:59:59'
      AND t.paid = true
      AND t.voided = false
      AND tim.id IS NULL
),

    -- Agregar totales del día por ítem
    totales_dia AS (
        SELECT
            ti.category_name AS categoria,
            ti.group_name AS grupo_menu,
            ti.item_name AS menu_item,
            AVG(CASE WHEN ti.item_price > 0 THEN ti.item_price ELSE ti.total_price_without_mods / NULLIF(ti.total_price_without_mods, 0) END) AS precio_item,
            SUM(ti.total_price_without_modifiers) AS total_sin_mods,
            0 AS selecciones_modificador,
            0 AS monto_extra_modificador,
            0 AS num_modificadores_distintos,
            0 AS lineas_con_mods,
            'TODAS' as sucursal,
            0 as terminal,
            t.closing_date::date AS fecha
        FROM public.ticket t
        JOIN public.ticket_item ti ON ti.ticket_id = t.id
        WHERE t.closing_date >= '2025-08-01'
          AND t.closing_date <= '2025-12-09 23:59:59'
          AND t.paid = true
          AND t.voided = false
        GROUP BY ti.category_name, ti.group_name, ti.item_name, t.closing_date::date
    )
)
SELECT
    categoria,
    grupo_menu,
    menu_item,
    precio_item,
    total_sin_mods,
    selecciones_modificador,
    monto_extra_modificador,
    num_modificadores_distintos,
    lineas_con_mods,
    sucursal,
    terminal,
    fecha,
    CASE
        WHEN lineas_con_mods > 0 THEN 'CON_MODS'
        ELSE 'SIN_MODS'
    END as tiene_mods,
    (total_sin_mods + monto_extra_modificador) as ingreso_total,
    -- Datos consolidados por fecha y sucursal para evitar duplicados
    ROW_NUMBER() OVER (
        PARTITION BY fecha, sucursal, menu_item, grupo_menu, categoria, precio_item,
        CASE WHEN lineas_con_mods > 0 THEN 'CON_MODS' ELSE 'SIN_MODS' END
        ORDER BY total_sin_mods + monto_extra_modificador DESC
    ) as consolidacion_id
FROM base_data;

-- Verificación de datos corregidos
SELECT 'DATOS CORREGIDOS - Items sin modificadores con ventas reales:' as validacion;

SELECT
    item_name,
    total_unidades,
    total_ventas,
    tiene_mods,
    ingresos_total
FROM (
    SELECT
        menu_item,
        SUM(total_unidades) as total_unidades,
        SUM(ingreso_total) as total_ventas,
        tiene_mods,
        SUM(ingreso_total) as ingresos_total
    FROM vw_item_mods_corregidos
    GROUP BY menu_item, tiene_mods
) ventas
WHERE total_unidades > 0
ORDER BY total_ventas DESC
LIMIT 20;

SELECT 'TOP 20 ITEMS (con y sin modificadores):' as titulo;

-- Comparación: items que antes podrían aparecer como cero
SELECT
    'ITEMS_IMPORTANTES_SIN_MODS' as categoria,
    menu_item,
    total_unidades,
    ROUND(total_ventas, 2) as total_ventas,
    tiene_mods
FROM (
    SELECT
        menu_item,
        SUM(total_unidades) as total_unidades,
        SUM(ingreso_total) as total_ventas,
        tiene_mods
    FROM vw_item_mods_corregidos
    WHERE ingresos_total > 0
    GROUP BY menu_item, tiene_mods
) ventas
WHERE tiene_mods = 'SIN_MODS'
  AND total_ventas > 5000
ORDER BY total_ventas DESC
LIMIT 20;