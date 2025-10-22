-- Prefijos de categorías (ejemplos)
UPDATE selemti.item_categories SET prefijo='INS' WHERE nombre ILIKE '%insumo%';
UPDATE selemti.item_categories SET prefijo='BEB' WHERE nombre ILIKE '%bebida%';

-- Conversiones UOM mínimas
INSERT INTO selemti.cat_uom_conversion(from_uom,to_uom,factor) VALUES
('KG','G',1000),('G','KG',0.001)
ON CONFLICT DO NOTHING;

INSERT INTO selemti.cat_uom_conversion(from_uom,to_uom,factor) VALUES
('LT','ML',1000),('ML','LT',0.001)
ON CONFLICT DO NOTHING;

INSERT INTO selemti.cat_uom_conversion(from_uom,to_uom,factor) VALUES
('PZA','PZA',1)
ON CONFLICT DO NOTHING;

-- Ejemplos de precios iniciales (ajusta IDs según tu catálogo)
INSERT INTO selemti.item_vendor_prices (item_id, vendor_id, price, pack_qty, pack_uom, source, notes, effective_from)
VALUES (1, 1, 215.50, 1, 'KG', 'BOOTSTRAP', 'Precio referencia inicial', now())
ON CONFLICT DO NOTHING;

INSERT INTO selemti.item_vendor_prices (item_id, vendor_id, price, pack_qty, pack_uom, source, notes, effective_from)
VALUES (2, 1, 120.00, 12, 'PZA', 'BOOTSTRAP', 'Caja por 12 piezas', now())
ON CONFLICT DO NOTHING;

-- Consultas rápidas para verificar vistas de último precio
SELECT item_id, vendor_id, price, effective_from
FROM selemti.vw_item_last_price
ORDER BY item_id, vendor_id
LIMIT 15;

SELECT item_id, vendor_id, price, pack_qty, pack_uom, effective_from
FROM selemti.vw_item_last_price_pref
ORDER BY item_id
LIMIT 15;
