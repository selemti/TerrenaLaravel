-- SEED_PLANTILLAS_V6.sql
-- Idempotente para PostgreSQL 9.5+. No crea tablas. Inserta permisos y plantillas si no existen.
-- Ajusta los nombres de tabla si difieren: selemti.permissions, selemti.plantillas, selemti.plantilla_permission

BEGIN;

-- === Permisos atómicos (subset clave; completa si deseas todos) ===
WITH perms(key) AS (
  VALUES
    ('inventory.items.view'),
    ('inventory.items.manage'),
    ('inventory.uoms.view'),
    ('inventory.uoms.manage'),
    ('inventory.uoms.convert.manage'),
    ('inventory.receptions.view'),
    ('inventory.receptions.post'),
    ('inventory.counts.view'),
    ('inventory.counts.open'),
    ('inventory.counts.close'),
    ('inventory.moves.view'),
    ('inventory.moves.adjust'),
    ('inventory.snapshot.generate'),
    ('inventory.snapshot.view'),
    ('purchasing.suggested.view'),
    ('purchasing.orders.manage'),
    ('purchasing.orders.approve'),
    ('recipes.view'),
    ('recipes.manage'),
    ('recipes.costs.recalc.schedule'),
    ('recipes.costs.snapshot'),
    ('pos.map.view'),
    ('pos.map.manage'),
    ('pos.audit.run'),
    ('pos.reprocess.run'),
    ('production.orders.view'),
    ('production.orders.close'),
    ('cashier.preclose.run'),
    ('cashier.close.run'),
    ('reports.kpis.view'),
    ('reports.audit.view'),
    ('system.users.view'),
    ('system.templates.manage'),
    ('system.permissions.direct.manage')
)
INSERT INTO selemti.permissions (clave)
SELECT key FROM perms p
WHERE NOT EXISTS (SELECT 1 FROM selemti.permissions x WHERE x.clave = p.key);

-- === Plantillas ===
WITH tpl(name) AS (
  VALUES
    ('Almacenista'),
    ('Jefe de Almacén'),
    ('Compras'),
    ('Costos / Recetas'),
    ('Producción'),
    ('Auditoría / Reportes'),
    ('Administrador del Sistema')
)
INSERT INTO selemti.plantillas (nombre)
SELECT name FROM tpl t
WHERE NOT EXISTS (SELECT 1 FROM selemti.plantillas x WHERE x.nombre = t.name);

-- === Helper para insertar relaciones plantilla-permiso ===

-- Almacenista
INSERT INTO selemti.plantilla_permission (plantilla_id, permiso_id)
SELECT p.id, r.id
FROM selemti.plantillas p
JOIN selemti.permissions r ON r.clave IN (
  'inventory.items.view',
  'inventory.counts.view',
  'inventory.counts.open',
  'inventory.counts.close',
  'inventory.moves.view',
  'inventory.snapshot.view'
)
WHERE p.nombre = 'Almacenista'
AND NOT EXISTS (
  SELECT 1 FROM selemti.plantilla_permission pp WHERE pp.plantilla_id = p.id AND pp.permiso_id = r.id
);

-- Jefe de Almacén
INSERT INTO selemti.plantilla_permission (plantilla_id, permiso_id)
SELECT p.id, r.id
FROM selemti.plantillas p
JOIN selemti.permissions r ON r.clave IN (
  'inventory.items.view',
  'inventory.counts.view',
  'inventory.counts.open',
  'inventory.counts.close',
  'inventory.moves.view',
  'inventory.moves.adjust',
  'inventory.receptions.view',
  'inventory.receptions.post',
  'pos.map.view'
)
WHERE p.nombre = 'Jefe de Almacén'
AND NOT EXISTS (
  SELECT 1 FROM selemti.plantilla_permission pp WHERE pp.plantilla_id = p.id AND pp.permiso_id = r.id
);

-- Compras
INSERT INTO selemti.plantilla_permission (plantilla_id, permiso_id)
SELECT p.id, r.id
FROM selemti.plantillas p
JOIN selemti.permissions r ON r.clave IN (
  'purchasing.suggested.view',
  'purchasing.orders.manage',
  'purchasing.orders.approve',
  'inventory.receptions.view'
)
WHERE p.nombre = 'Compras'
AND NOT EXISTS (
  SELECT 1 FROM selemti.plantilla_permission pp WHERE pp.plantilla_id = p.id AND pp.permiso_id = r.id
);

-- Costos / Recetas
INSERT INTO selemti.plantilla_permission (plantilla_id, permiso_id)
SELECT p.id, r.id
FROM selemti.plantillas p
JOIN selemti.permissions r ON r.clave IN (
  'recipes.view',
  'recipes.manage',
  'recipes.costs.recalc.schedule',
  'recipes.costs.snapshot',
  'pos.map.manage'
)
WHERE p.nombre = 'Costos / Recetas'
AND NOT EXISTS (
  SELECT 1 FROM selemti.plantilla_permission pp WHERE pp.plantilla_id = p.id AND pp.permiso_id = r.id
);

-- Producción
INSERT INTO selemti.plantilla_permission (plantilla_id, permiso_id)
SELECT p.id, r.id
FROM selemti.plantillas p
JOIN selemti.permissions r ON r.clave IN (
  'production.orders.view',
  'production.orders.close',
  'inventory.items.view'
)
WHERE p.nombre = 'Producción'
AND NOT EXISTS (
  SELECT 1 FROM selemti.plantilla_permission pp WHERE pp.plantilla_id = p.id AND pp.permiso_id = r.id
);

-- Auditoría / Reportes
INSERT INTO selemti.plantilla_permission (plantilla_id, permiso_id)
SELECT p.id, r.id
FROM selemti.plantillas p
JOIN selemti.permissions r ON r.clave IN (
  'reports.kpis.view',
  'reports.audit.view',
  'pos.audit.run',
  'inventory.snapshot.view'
)
WHERE p.nombre = 'Auditoría / Reportes'
AND NOT EXISTS (
  SELECT 1 FROM selemti.plantilla_permission pp WHERE pp.plantilla_id = p.id AND pp.permiso_id = r.id
);

-- Administrador del Sistema (todos)
INSERT INTO selemti.plantilla_permission (plantilla_id, permiso_id)
SELECT p.id, r.id
FROM selemti.plantillas p
JOIN selemti.permissions r ON true
WHERE p.nombre = 'Administrador del Sistema'
AND NOT EXISTS (
  SELECT 1 FROM selemti.plantilla_permission pp WHERE pp.plantilla_id = p.id AND pp.permiso_id = r.id
);

COMMIT;
