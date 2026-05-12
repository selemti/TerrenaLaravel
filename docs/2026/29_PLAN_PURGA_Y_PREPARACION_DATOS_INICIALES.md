# 29 Protocolo de Purga Operativa (Punto Cero Fase 2)

> [!IMPORTANT]
> Este documento no es descriptivo, es **OPERATIVO**. Los pasos deben ejecutarse en el orden indicado, validando los resultados de cada query antes de proceder al siguiente.

## 0. Fase 0: Dry Run Humano (Simulación de impacto)
*Objetivo: Verificar dependencias críticas antes de iniciar el proceso.*

```sql
-- Simulación de impacto
SELECT COUNT(*) AS items_a_borrar FROM selemti.items;
SELECT COUNT(*) AS total_receta_cab FROM selemti.receta_cab;
SELECT COUNT(*) AS total_receta_det FROM selemti.receta_det;
SELECT COUNT(*) AS total_mov_inv FROM selemti.mov_inv;
SELECT COUNT(*) AS total_recepcion_det FROM selemti.recepcion_det;
```

> [!WARNING]
> Si `receta_det > 0`, `mov_inv > 0` o `recepcion_det > 0` → **STOP**. No puedes borrar ítems porque ya hay historia ligada.

---

## 1. Preparación del Entorno (Reglas de Oro)
Antes de tocar la base de datos, el sistema debe estar en estado de mantenimiento:
1.  **Mantenimiento**: `php artisan down`
2.  **Workers**: Detener cualquier proceso de `queue:work` o cron jobs.
3.  **Frontend**: Asegurar que no hay usuarios logueados operando el módulo de inventarios.
4.  **Confirmar conexión a BD correcta**: Ejecutar `SELECT current_database();` para evitar errores fatales.

---

## 2. Fase de Pre-Check (Auditoría Blanca)
*Objetivo: Documentar el estado previo sin alterar datos.*

```sql
-- 2.1 Conteo actual de items
SELECT COUNT(*) AS total_items FROM selemti.items;

-- 2.2 Detectar duplicados lógicos por nombre (para referencia forense)
SELECT nombre, COUNT(*) 
FROM selemti.items 
GROUP BY nombre 
HAVING COUNT(*) > 1;

-- 2.3 Verificar categorías actuales
SELECT COUNT(*) AS total_categorias FROM selemti.item_categories;

-- 2.4 Validar relaciones antes de borrar (¿Quién depende de items?)
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name
FROM
    information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND ccu.table_name = 'items';
```

---

## 3. Fase de Seguridad (Respaldo Garantizado)
*Objetivo: Crear un punto de restauración inmediato.*

```sql
-- 3.1 Crear backup físico en una tabla temporal de seguridad
CREATE TABLE selemti.bkp_items_pre_fase2_20260415 AS 
SELECT * FROM selemti.items;

CREATE TABLE selemti.bkp_categories_pre_fase2_20260415 AS 
SELECT * FROM selemti.item_categories;

-- 3.2 Validar que el respaldo es íntegro
SELECT COUNT(*) AS total_backup FROM selemti.bkp_items_pre_fase2_20260415;
```

---

## 4. Fase de Ejecución (Purga Controlada)
*Objetivo: Limpiar el catálogo maestro sin romper la integridad referencial.*

```sql
-- 4.0 Validación de dependencias crítica
SELECT COUNT(*) AS count_receta_det FROM selemti.receta_det;
SELECT COUNT(*) AS count_mov_inv FROM selemti.mov_inv;
SELECT COUNT(*) AS count_recepcion_det FROM selemti.recepcion_det;
-- Si alguno de los 3 arroja > 0, STOP.

-- 4.1 Purga de Items (Usamos DELETE, NO TRUNCATE para detectar FKs activas)
DELETE FROM selemti.items;

-- 4.2 Purga de Categorías
DELETE FROM selemti.item_categories;
```

> [!NOTE]
> Si el comando `DELETE` falla por una `Foreign Key Violation`, **DETENER EL PROCESO**. Significa que hay transacciones (ventas, compras o recetas) ligadas a estos ítems de prueba que deben ser analizadas.

---

## 5. Fase de Verificación (Certificación)
*Objetivo: Confirmar el estado "Cold Start".*

```sql
-- 5.1 Validar estado global
SELECT
    (SELECT COUNT(*) FROM selemti.items) AS items,
    (SELECT COUNT(*) FROM selemti.item_categories) AS categorias;
-- Debe dar: 0 | 0

-- 5.2 Validación Estructural (Verificar integridad de constraints)
SELECT * 
FROM information_schema.constraint_column_usage 
WHERE table_name = 'items' AND table_schema = 'selemti';
```

---

## 6. Plan de Rollback (En caso de emergencia)
*Objetivo: Restaurar el estado previo en menos de 10 segundos.*

```sql
-- 6.1 Restaurar Datos (Limpiar antes para evitar duplicados)
DELETE FROM selemti.items;
DELETE FROM selemti.item_categories;

INSERT INTO selemti.items SELECT * FROM selemti.bkp_items_pre_fase2_20260415;
INSERT INTO selemti.item_categories SELECT * FROM selemti.bkp_categories_pre_fase2_20260415;

-- 6.2 Validar restauración
SELECT COUNT(*) FROM selemti.items;
```

---
**Protocolo Certificado por**: Antigravity AI
**Aprobación Operativa**: [A espera de confirmación de Gustavo]
