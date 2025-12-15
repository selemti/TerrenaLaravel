# Validación rápida Ítems + Modificadores (rango específico)

Uso: verificar que las combinaciones del reporte coinciden con la BD en un rango (ej. 2025-12-02 a 2025-12-08).

## 1) Preparar conexión psql (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install -y postgresql-client
```

## 2) Probar conexión (sustituye host/puerto si aplica)
```bash
psql -h 172.24.240.1 -p 5433 -U postgres -d pos -c "SELECT 1;"
```
Password: `T3rr3n4#p0s`

## 3) Totales por ítem (ticket_item) en el rango
```bash
psql -h 172.24.240.1 -p 5433 -U postgres -d pos -c "
  SELECT
    ti.category_name,
    ti.group_name,
    ti.item_name,
    SUM(COALESCE(ti.item_quantity, ti.item_count, 0)) AS units,
    SUM(ti.total_price) AS ingreso,
    SUM(ti.total_price_without_modifiers) AS ingreso_sin_mods
  FROM public.ticket t
  JOIN public.ticket_item ti ON ti.ticket_id = t.id
  WHERE t.closing_date BETWEEN '2025-12-02 00:00:00' AND '2025-12-08 23:59:59'
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY ti.category_name, ti.group_name, ti.item_name
  ORDER BY units DESC
  LIMIT 50;
"
```

## 4) Combinaciones con modificadores (ticket_item_modifier) en el rango
```bash
psql -h 172.24.240.1 -p 5433 -U postgres -d pos -c "
  SELECT
    ti.category_name,
    ti.group_name,
    ti.item_name,
    COALESCE(mg.name, 'Sin grupo') AS grupo_mod,
    tim.modifier_name,
    SUM(COALESCE(tim.item_count, 0)) AS selecciones,
    SUM(COALESCE(tim.item_count,0) * COALESCE(tim.modifier_price,0)) AS monto_extra
  FROM public.ticket t
  JOIN public.ticket_item ti ON ti.ticket_id = t.id
  JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
  LEFT JOIN public.menu_modifier mm ON mm.id = tim.item_id
  LEFT JOIN public.menu_modifier_group mg ON mg.id = COALESCE(tim.group_id, mm.group_id)
  WHERE t.closing_date BETWEEN '2025-12-02 00:00:00' AND '2025-12-08 23:59:59'
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY ti.category_name, ti.group_name, ti.item_name, mg.name, tim.modifier_name
  ORDER BY selecciones DESC
  LIMIT 100;
"
```

## 5) Qué comparar
- Ítems sin modificadores en el reporte deben coincidir con `units/ingreso` del query #3.
- Combinaciones con modificadores deben aparecer en el query #4 (grupo_mod + modifier_name).
- Si un ítem tiene ventas en #3 pero no aparece en la vista: revisar normalización de nombre (espacios/acentos).

## 6) Si psql no conecta
- Verifica host/puerto en `.env` (DB_HOST, DB_PORT).
- Limpia caché de config en Laravel:
  ```bash
  php artisan config:clear
  php artisan cache:clear
  ```
- Confirma que el puerto 5433 está abierto desde tu host.

---

Nota: Rango usado en los ejemplos: 2025-12-02 a 2025-12-08 (ajusta fechas si necesitas otro rango).
