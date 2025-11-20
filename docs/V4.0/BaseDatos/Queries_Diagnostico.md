# QUERIES DE DIAGNÓSTICO PARA TERRENA

## 1. Diagnóstico de Tickets

### 1.1 Tickets Abiertos y Potenciales Problemas
```sql
-- Tickets abiertos por más de 24 horas
SELECT t.id, t.folio, t.total_price, t.created_date, t.closed
FROM public.ticket t
WHERE t.closed = false
AND t.created_date < current_date - 1
ORDER BY t.created_date;

-- Tickets con descuentos del 100%
SELECT t.id, t.folio, t.total_price, t.total_discount,
       (t.total_discount / NULLIF(t.total_price, 0) * 100) as porcentaje_descuento
FROM public.ticket t
WHERE t.total_discount > 0
AND t.total_price > 0
AND (t.total_discount / NULLIF(t.total_price, 0) * 100) >= 99.99;

-- Tickets anulados recientemente
SELECT t.id, t.folio, t.total_price, t.status, t.void_date
FROM public.ticket t
WHERE t.status = 'voided'
ORDER BY t.void_date DESC
LIMIT 50;

-- Tickets con pagos inconsistentes
SELECT t.id, t.folio, t.total_price, 
       (SELECT SUM(tp.amount) FROM public.ticket_payment tp WHERE tp.ticket_id = t.id) as total_pagado
FROM public.ticket t
WHERE t.total_price != (SELECT COALESCE(SUM(tp.amount), 0) FROM public.ticket_payment tp WHERE tp.ticket_id = t.id);
```

### 1.2 Tickets Duplicados
```sql
-- Tickets con el mismo folio en la misma fecha
SELECT folio, folio_date, COUNT(*) as conteo
FROM public.ticket
GROUP BY folio, folio_date
HAVING COUNT(*) > 1
ORDER BY conteo DESC;

-- Tickets con items duplicados
SELECT ti.ticket_id, mi.item_name, COUNT(*) as conteo
FROM public.ticket_item ti
JOIN public.menu_item mi ON ti.menu_item_id = mi.id
GROUP BY ti.ticket_id, mi.item_name
HAVING COUNT(*) > 1;
```

## 2. Diagnóstico de Recepciones

### 2.1 Recepciones Inconsistentes
```sql
-- Recepciones sin detalle
SELECT rc.id, rc.numero_recepcion, rc.fecha_recepcion
FROM selemti.recepcion_cab rc
WHERE NOT EXISTS (SELECT 1 FROM selemti.recepcion_det rd WHERE rd.recepcion_id = rc.id);

-- Lotes sin movimientos de inventario
SELECT ib.id, ib.item_id, ib.lote_proveedor, ib.cantidad_original
FROM selemti.inventory_batch ib
WHERE NOT EXISTS (
    SELECT 1 FROM selemti.mov_inv mi 
    WHERE mi.lote_id = ib.id 
    AND mi.tipo = 'RECEPCION'
);
```

## 3. Diagnóstico de Transferencias

### 3.1 Transferencias Incompletas
```sql
-- Transferencias despachadas pero no recibidas
SELECT tc.id, tc.numero_traspaso, tc.fecha_salida, tc.estado
FROM selemti.traspaso_cab tc
WHERE tc.estado = 'DESPACHADA'
AND NOT EXISTS (
    SELECT 1 FROM selemti.mov_inv mi 
    WHERE mi.ref_tipo = 'traspaso' 
    AND mi.ref_id = tc.id
    AND mi.tipo = 'TRASPASO_RECIBIDO'
);

-- Transferencias con discrepancias
SELECT tc.id, tc.numero_traspaso, 
       SUM(td.qty_presentacion) as enviado,
       COALESCE(SUM(mi.qty), 0) as recibido
FROM selemti.traspaso_cab tc
JOIN selemti.traspaso_det td ON tc.id = td.traspaso_id
LEFT JOIN selemti.mov_inv mi ON mi.ref_tipo = 'traspaso' AND mi.ref_id = tc.id AND mi.item_id = td.item_id
GROUP BY tc.id, tc.numero_traspaso
HAVING SUM(td.qty_presentacion) != COALESCE(SUM(mi.qty), 0);
```

## 4. Diagnóstico de Movimientos de Inventario

### 4.1 Movimientos Huérfanos
```sql
-- Movimientos sin referencia a recepción u otro origen
SELECT mi.id, mi.item_id, mi.tipo, mi.qty, mi.ts, mi.ref_tipo, mi.ref_id
FROM selemti.mov_inv mi
WHERE mi.ref_tipo IS NULL OR mi.ref_id IS NULL
AND mi.tipo NOT IN ('AJUSTE_MANUAL', 'INICIAL');

-- Movimientos de ítems no existentes
SELECT mi.id, mi.item_id, mi.tipo, mi.qty
FROM selemti.mov_inv mi
LEFT JOIN selemti.items i ON mi.item_id = i.id
WHERE i.id IS NULL;
```

## 5. Diagnóstico de Recetas

### 5.1 Recetas Inconsistentes
```sql
-- Recetas sin versión publicada
SELECT rc.id, rc.nombre_plato, rc.categoria_plato
FROM selemti.receta_cab rc
WHERE NOT EXISTS (
    SELECT 1 FROM selemti.receta_version rv 
    WHERE rv.receta_id = rc.id 
    AND rv.version_publicada = true
);

-- Recetas con ingredientes inexistentes
SELECT rc.id as receta_id, rc.nombre_plato, rd.item_id as item_no_existente
FROM selemti.receta_cab rc
JOIN selemti.receta_version rv ON rc.id = rv.receta_id
JOIN selemti.receta_det rd ON rv.id = rd.receta_version_id
LEFT JOIN selemti.items i ON rd.item_id = i.id
WHERE i.id IS NULL;
```

## 6. Diagnóstico de Producción

### 6.1 Producción Inconsistente
```sql
-- Órdenes de producción sin movimientos
SELECT po.id, po.folio, po.recipe_id, po.estado
FROM selemti.production_orders po
WHERE po.estado = 'COMPLETADO'
AND NOT EXISTS (
    SELECT 1 FROM selemti.mov_inv mi 
    WHERE mi.ref_tipo = 'production_order' 
    AND mi.ref_id = po.id
);
```

## 7. Diagnóstico de Cierre y Cortes

### 7.1 Sesiones Inconsistentes
```sql
-- Sesiones sin cierre
SELECT sc.id, sc.sucursal, sc.terminal_id, sc.apertura_ts, sc.cierre_ts
FROM selemti.sesion_cajon sc
WHERE sc.cierre_ts IS NULL
AND sc.apertura_ts < current_date - 1;

-- Precortes sin postcorte
SELECT p.id, p.sesion_id, p.creado_en
FROM selemti.precorte p
WHERE NOT EXISTS (
    SELECT 1 FROM selemti.postcorte pc 
    WHERE pc.sesion_id = p.sesion_id
);
```

## 8. Diagnóstico de Vistas y Consultas

### 8.1 Vistas Sin Uso
```sql
-- Vistas que no están referenciadas en código o consultas frecuentes
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'selemti'
AND table_name LIKE 'vw_%'
ORDER BY table_name;
```

## 9. Diagnóstico de Datos Maestros

### 9.1 Datos Inconsistentes
```sql
-- Ítems sin categoría definida
SELECT id, nombre
FROM selemti.items
WHERE categoria_id IS NULL OR categoria_id = '';

-- Ítems con costos negativos
SELECT id, nombre, costo_promedio
FROM selemti.items
WHERE costo_promedio < 0;

-- Ítems con unidad de medida inválida
SELECT i.id, i.nombre, i.unidad_medida
FROM selemti.items i
LEFT JOIN selemti.cat_unidades cu ON i.unidad_medida = cu.clave
WHERE cu.clave IS NULL;
```

## 10. Diagnóstico de Seguridad

### 10.1 Usuarios Inactivos con Acceso
```sql
-- Usuarios inactivos pero con permisos activos
SELECT u.id, u.username, u.nombre_completo, u.activo
FROM selemti.users u
WHERE u.activo = false
AND EXISTS (
    SELECT 1 FROM selemti.model_has_permissions mhp 
    WHERE mhp.model_id = u.id
    AND mhp.model_type = 'App\\Models\\User'
);
```

## 11. Diagnóstico de Performance

### 11.1 Tablas con Gran Cantidad de Registros
```sql
-- Tablas con más de 10,000 registros
SELECT schemaname, tablename, n_tup_ins - n_tup_del as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'selemti'
AND (n_tup_ins - n_tup_del) > 10000
ORDER BY (n_tup_ins - n_tup_del) DESC;
```

## 12. Diagnóstico de Integración POS

### 12.1 Tickets POS sin Confirmar Consumo
```sql
-- Tickets en POS sin registro en inv_consumo_pos
SELECT t.id, t.folio, t.total_price, t.created_date
FROM public.ticket t
WHERE NOT EXISTS (
    SELECT 1 FROM selemti.inv_consumo_pos icp 
    WHERE icp.ticket_id = t.id
)
AND t.created_date >= current_date - 7
ORDER BY t.created_date DESC;
```

Estos queries permiten diagnosticar rápidamente el estado de la base de datos y detectar posibles inconsistencias o problemas en el sistema.