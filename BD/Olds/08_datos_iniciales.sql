-- =====================================================
-- SCRIPT 08: DATOS INICIALES DEL SISTEMA
-- =====================================================

\set ON_ERROR_STOP on
SET search_path TO selemti, public;

-- 1. CREAR USUARIO ADMINISTRADOR INICIAL
INSERT INTO selemti.users (username, password_hash, email, nombre_completo, sucursal_id, activo) VALUES 
('admin', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'admin@restaurante.com', 'Administrador del Sistema', 'SUR', true);

-- 2. ASIGNAR ROLES AL ADMINISTRADOR
INSERT INTO selemti.user_roles (user_id, role_id, assigned_by) VALUES 
(1, 'GERENTE', 1),
(1, 'CHEF', 1),
(1, 'ALMACEN', 1),
(1, 'CAJERO', 1),
(1, 'AUDITOR', 1);

-- 3. CREAR USUARIOS DE EJEMPLO POR ROL
INSERT INTO selemti.users (username, password_hash, nombre_completo, sucursal_id, activo) VALUES 
('chef.juan', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'Juan Pérez - Chef', 'SUR', true),
('almacen.maria', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'María García - Almacén', 'SUR', true),
('caja.carlos', '$2b$10$ExampleHashOf60CharactersLength123456789012', 'Carlos López - Cajero', 'SUR', true);

INSERT INTO selemti.user_roles (user_id, role_id, assigned_by) VALUES 
(2, 'CHEF', 1),
(3, 'ALMACEN', 1),
(4, 'CAJERO', 1);

-- 4. INSERTAR ÍTEMS DE EJEMPLO (MATERIAS PRIMAS)
INSERT INTO selemti.items (id, nombre, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max) VALUES 
('PROT-POLLO-PECHUGA-1KG', 'Pechuga de Pollo', 'CAT-PROTEINA', 'KG', true, 0, 4),
('PROT-SALMON-FRESCO-1KG', 'Salmón Fresco', 'CAT-PROTEINA', 'KG', true, -2, 2),
('VERD-LECHUGA-ROMA-1KG', 'Lechuga Romana', 'CAT-VERDURA', 'KG', true, 1, 4),
('VERD-TOMATE-ROJO-1KG', 'Tomate Rojo', 'CAT-VERDURA', 'KG', true, 10, 15),
('LACT-QUESO-MOZZARELLA-1KG', 'Queso Mozzarella', 'CAT-LACTEO', 'KG', true, 2, 6),
('BEBID-AGUA-1LT', 'Agua Purificada', 'CAT-BEBIDA', 'LT', false, NULL, NULL);

-- 5. INSERTAR RECETAS DE EJEMPLO
INSERT INTO selemti.receta_cab (id, codigo_plato_pos, nombre_plato, categoria_cocina, tipo_preparacion, tiempo_preparacion_min, rendimiento_porciones, nivel_dificultad, activo, usuario_creador, costo_standard_porcion, precio_venta_sugerido) VALUES 
('REC-CEVICHE-CLASICO', 'CEV-001', 'Ceviche Clásico', 'PLATO_FUERTE', 'FRIA', 20, 4, 'MEDIA', true, 1, 45.00, 180.00),
('REC-ENSALADA-CESAR', 'ENS-001', 'Ensalada César', 'ENTRADA', 'FRIA', 15, 2, 'BAJA', true, 1, 35.00, 120.00);

-- 6. INSERTAR DETALLES DE RECETAS
INSERT INTO selemti.receta_det (receta_id, item_id, tipo_componente, cantidad_bruta, porcentaje_merma, cantidad_neta, orden_mezcla, tipo_medida) VALUES 
('REC-CEVICHE-CLASICO', 'PROT-SALMON-FRESCO-1KG', 'INGREDIENTE', 0.500, 10.00, 0.450, 1, 'PESO'),
('REC-CEVICHE-CLASICO', 'VERD-LECHUGA-ROMA-1KG', 'INGREDIENTE', 0.200, 5.00, 0.190, 2, 'PESO'),
('REC-ENSALADA-CESAR', 'VERD-LECHUGA-ROMA-1KG', 'INGREDIENTE', 0.300, 5.00, 0.285, 1, 'PESO'),
('REC-ENSALADA-CESAR', 'LACT-QUESO-MOZZARELLA-1KG', 'INGREDIENTE', 0.100, 2.00, 0.098, 2, 'PESO');

-- 7. ACTUALIZAR FOREIGN KEYS PENDIENTES
-- Actualizar recepcion_cab con referencia a proveedores
UPDATE selemti.recepcion_cab SET proveedor_id = 'PROV-CARNICOS-LA-PALMA' WHERE proveedor_id IS NOT NULL;

-- 8. CREAR PROVEEDORES DE EJEMPLO
INSERT INTO selemti.proveedores (codigo, nombre, tipo_proveedor, categoria_calidad, activo) VALUES 
('PROV-CARNICOS-LA-PALMA', 'Cárnicos La Palma', 'ALIMENTOS', 'A', true),
('PROV-PESCADOS-FRESCOS', 'Pescados Frescos del Pacífico', 'ALIMENTOS', 'A', true),
('PROV-HORTALIZAS-ORGANICAS', 'Hortalizas Orgánicas', 'ALIMENTOS', 'B', true);

RAISE NOTICE 'Script 08 (Datos iniciales) ejecutado exitosamente';