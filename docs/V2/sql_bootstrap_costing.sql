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
