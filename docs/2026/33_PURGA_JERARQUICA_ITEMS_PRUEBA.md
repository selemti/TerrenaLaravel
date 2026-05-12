# 33 Purga Jerárquica de Ítems de Prueba (Cold Start Fase 2)

## 1. Objetivo
Ejecutar la eliminación segura de los 6 ítems de prueba (y sus categorías base funcionales) del sistema. Debido a la integridad referencial, la purga debe hacerse en **cascada inversa** (borrando desde las hojas operativas hasta maestros) para no violar restricciones de llaves foráneas (`FOREIGN KEY`) previamente detectadas en nuestra auditoría forense determinista.

## 2. Alcance exacto de la purga
La auditoría aisló los registros dependientes vinculados exclusivamente al ítem `LECHE-MEMBERS-01` y sus hermanos de prueba en las siguientes tablas:
* `selemti.inventory_batch` (2 registros)
* `selemti.recepcion_det` (2 registros)
* `selemti.traspaso_det` (8 registros)
* `selemti.mov_inv` (14 registros)
* `selemti.items` (6 registros)
* `selemti.item_categories` (sólo las categorías atadas a los 6 ítems)

Tablas maestras que resultarán afectadas por orfandad:
* `selemti.recepcion_cab` (Se detectan huérfanos predecibles)
* `selemti.traspaso_cab` (Se detectan huérfanos predecibles)

## 3. Alcance congelado (Scope Lock)
Para proteger el sistema de ejecuciones futuras donde `selemti.items` pudiera tener datos nuevos de producción, encapsularemos explícitamente los IDs definidos por la auditoría. Todas las sentencias posteriores del script utilizarán esta tabla temporal como su universo absoluto.

```sql
CREATE TABLE selemti.tmp_items_objetivo_20260415 AS
SELECT id
FROM selemti.items
WHERE id IN (
  'ACEITE-NUT-01',
  'ACEITE-NUTRIOLI-01',
  'LECHE-MEM-01',
  'LECHE-MEMBERS-01',
  'LECHE-NUT-01',
  'LECHE-NUTRI-01'
);
```

## 4. Respaldo previo
Creación de copias físicas con fecha (sufijo `_20260415`) para salvaguardar todos los registros afectados **exclusivamente vinculados al universo congelado**.

```sql
-- 4.1 Respaldo de dependencias directas
CREATE TABLE selemti.bkp_mov_inv_20260415 AS 
SELECT * FROM selemti.mov_inv WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

CREATE TABLE selemti.bkp_traspaso_det_20260415 AS 
SELECT * FROM selemti.traspaso_det WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

CREATE TABLE selemti.bkp_recepcion_det_20260415 AS 
SELECT * FROM selemti.recepcion_det WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

CREATE TABLE selemti.bkp_inventory_batch_20260415 AS 
SELECT * FROM selemti.inventory_batch WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

-- 4.2 Respaldo de tablas catálogo
CREATE TABLE selemti.bkp_items_20260415 AS 
SELECT * FROM selemti.items WHERE id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

CREATE TABLE selemti.bkp_item_categories_20260415 AS 
SELECT * FROM selemti.item_categories 
WHERE id IN (SELECT categoria_id FROM selemti.bkp_items_20260415);

-- 4.3 Respaldo cautelar de cabeceras operativas (Solo donde hayan figurado los ítems del universo)
CREATE TABLE selemti.bkp_recepcion_cab_20260415 AS 
SELECT rc.* FROM selemti.recepcion_cab rc 
JOIN selemti.recepcion_det rd ON rc.id = rd.recepcion_id 
WHERE rd.item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

CREATE TABLE selemti.bkp_traspaso_cab_20260415 AS 
SELECT tc.* FROM selemti.traspaso_cab tc 
JOIN selemti.traspaso_det td ON tc.id = td.traspaso_id 
WHERE td.item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);
```

## 5. Orden jerárquico de borrado
Debemos ejecutar la purga borrando PRIMERO las dependencias y hojas de la cascada. Todo borrado está estrictamente condicionado a la tabla iteradora pivote `tmp_items_objetivo_20260415`.

```sql
-- 5.1 Purga de dependencias a nivel hijo (solo el universo auditado)
DELETE FROM selemti.inventory_batch WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);
DELETE FROM selemti.recepcion_det WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);
DELETE FROM selemti.traspaso_det WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);
DELETE FROM selemti.mov_inv WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

-- 5.2 Purga protectora de cabeceras huérfanas 
-- (Borra SOLO aquellas de prueba que YA NO tienen más detalles atados a ellas después de la purga 5.1)
DELETE FROM selemti.recepcion_cab rc
WHERE id IN (SELECT id FROM selemti.bkp_recepcion_cab_20260415)
  AND NOT EXISTS (SELECT 1 FROM selemti.recepcion_det rd WHERE rc.id = rd.recepcion_id);

DELETE FROM selemti.traspaso_cab tc
WHERE id IN (SELECT id FROM selemti.bkp_traspaso_cab_20260415)
  AND NOT EXISTS (SELECT 1 FROM selemti.traspaso_det td WHERE tc.id = td.traspaso_id);

-- 5.3 Purga de maestras limitadas al universo congelado (Catálogo Base)
DELETE FROM selemti.items 
WHERE id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

DELETE FROM selemti.item_categories 
WHERE id IN (SELECT categoria_id FROM selemti.bkp_items_20260415);
```

## 6. Validaciones intermedias
Terminada la fase de ejecución, validamos que el universo haya quedado estructuralmente desvinculado con recuentos a 0.

```sql
SELECT 
  (SELECT COUNT(*) FROM selemti.items WHERE id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415)) AS total_items,
  (SELECT COUNT(*) FROM selemti.item_categories WHERE id IN (SELECT categoria_id FROM selemti.bkp_items_20260415)) AS total_categorias,
  (SELECT COUNT(*) FROM selemti.mov_inv WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415)) AS total_mov_inv_huerfanos,
  (SELECT COUNT(*) FROM selemti.recepcion_det WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415)) AS total_recepciones_huerfanas,
  (SELECT COUNT(*) FROM selemti.traspaso_det WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415)) AS total_traspasos_huerfanos;
```

## 7. Revisión de cabeceras huérfanas
La auditoría determinó de manera determinista lo siguiente:
- Recepciones: `recepcion_cab` (IDs `4` y `5`). Ambos documentos en su estado actual tenían `1` solo registro en su base operativo en "LECHE-MEMBERS-01". Al purgar ese ítem, las cabeceras quedan completamente desglosadas en cero.
- Traspasos: `traspaso_cab`. Los registros operados derivaron exclusivamente de cruces lógicos de inventario con los ítems de prueba.

**Recomendación de cabeceras**: Se recomienda borrar las cabeceras (implementado en el sub-paso `5.2`). Se optó por una query iterada de tipo `WHERE ... NOT EXISTS (...)` para asegurar que el motor de postgres destruya la cabecera operativa **solo** si ésta ha perdido el control del 100% de los renglones operativos intermedios (`det`), haciendo el borrado seguro e invisible ante el POS final de otros productos.

## 8. Rollback completo
Si algo falla, ejecutar este bloque en estricto orden inverso a la purga. Dado que el alcance de impacto es acotado, se garantiza una higiene simétrica rigurosa purgando preventivamente todo rastro cruzado **antes** de lanzar las re-inyecciones.

```sql
-- 8.1 Limpiar entorno simétrico para evitar colisiones lógicas (Hojas y Cabeceras)
DELETE FROM selemti.inventory_batch WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);
DELETE FROM selemti.recepcion_det WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);
DELETE FROM selemti.traspaso_det WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);
DELETE FROM selemti.mov_inv WHERE item_id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);

DELETE FROM selemti.recepcion_cab WHERE id IN (SELECT id FROM selemti.bkp_recepcion_cab_20260415);
DELETE FROM selemti.traspaso_cab WHERE id IN (SELECT id FROM selemti.bkp_traspaso_cab_20260415);

DELETE FROM selemti.items WHERE id IN (SELECT id FROM selemti.tmp_items_objetivo_20260415);
DELETE FROM selemti.item_categories WHERE id IN (SELECT categoria_id FROM selemti.bkp_items_20260415);

-- 8.2 Reinstalar Entidades Maestras
INSERT INTO selemti.item_categories SELECT * FROM selemti.bkp_item_categories_20260415;
INSERT INTO selemti.items SELECT * FROM selemti.bkp_items_20260415;

-- 8.3 Reinstalar Soporte Operacional Cabeceras
INSERT INTO selemti.recepcion_cab SELECT * FROM selemti.bkp_recepcion_cab_20260415;
INSERT INTO selemti.traspaso_cab SELECT * FROM selemti.bkp_traspaso_cab_20260415;

-- 8.4 Reinstalar Entidades Hojas de Transacción
INSERT INTO selemti.recepcion_det SELECT * FROM selemti.bkp_recepcion_det_20260415;
INSERT INTO selemti.traspaso_det SELECT * FROM selemti.bkp_traspaso_det_20260415;
INSERT INTO selemti.inventory_batch SELECT * FROM selemti.bkp_inventory_batch_20260415;
INSERT INTO selemti.mov_inv SELECT * FROM selemti.bkp_mov_inv_20260415;
```

## 9. Dictamen operativo
El protocolo ha sido estructurado mediante SQL relacional estándar y acota su alcance únicamente al universo auditado en la tabla pivote temporal. **Es apto para ejecución manual controlada en entorno de mantenimiento, sujeto a confirmación previa del alcance congelado y validación post-borrado en su matriz operacional.**
