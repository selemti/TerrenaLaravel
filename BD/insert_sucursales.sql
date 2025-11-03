-- Insertar sucursales mapeadas desde public.terminal (location)
-- Fecha: 2025-11-01

INSERT INTO selemti.cat_sucursales (clave, nombre, ubicacion, activo, created_at, updated_at)
VALUES
  ('PRINCIPAL', 'Sucursal Principal', 'Ubicacion Principal del Restaurante', true, NOW(), NOW()),
  ('NB', 'Sucursal NB', 'Ubicacion NB', true, NOW(), NOW()),
  ('TORRE', 'Sucursal Torre', 'Ubicacion Torre', true, NOW(), NOW()),
  ('SELEMTI', 'Sucursal SelemTI', 'Ubicacion SelemTI (Desarrollo)', true, NOW(), NOW())
ON CONFLICT (clave) DO NOTHING;

-- Verificar inserciones
SELECT id, clave, nombre, ubicacion, activo FROM selemti.cat_sucursales ORDER BY id;
