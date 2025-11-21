# 🚀 Sprint Recetas 1.0 - Implementación Inicial

## 🎯 Objetivo
Crear la infraestructura funcional mínima para capturar, versionar y relacionar recetas con ítems de inventario.

---

## 🧩 Alcance  

1. Crear nuevas tablas `recetas` y `recetas_detalle` (si no existen) o extender las actuales:
   - **recetas**: cabecera general.
   - **recetas_detalle**: ingredientes, cantidades, unidad, flags.

2. Actualizar modelo `Item` para agregar banderas:
   - `es_producible` (bool)
   - `es_consumible_operativo` (bool)

3. Desarrollar componente Livewire `/recetas/create`:
   - Formulario dinámico para capturar ingredientes.
   - Selector de tipo (BASE / SUBRECETA / MODIFICADOR).
   - Calcular costo estimado según precios vigentes (`fn_item_unit_cost_at`).

4. Integrar vista `/produccion/create`:
   - Selección de receta tipo `ELABORADO`.
   - Ingreso de cantidad producida.
   - Estado inicial: BORRADOR.
   - Registrar consumo esperado (sin postear inventario aún).

5. Sincronizar modificadores POS:
   - Vincular cada opción POS (`modificadores_pos`) con `receta_modificador_id`.

---

## 📅 Entregables Sprint 1.0

| Entregable | Descripción |
|-------------|--------------|
| `docs/Recetas/CATALOGOS_INICIALES.md` | Catálogo base de ítems y familias |
| `docs/Recetas/SUBRECETAS_BASE.md` | Subrecetas operativas principales |
| `app/Livewire/Recetas/Create.php` | Formulario de creación de recetas |
| `app/Models/Production/Recipe.php` | Modelo Eloquent para recetas |
| `database/migrations/YYYYMMDD_create_recipes_tables.php` | Migraciones correspondientes |

---

## 🧠 Notas de Integración

- El módulo **Producción** se activa en Sprint 1.1:
  - Posteo de orden de producción �?`mov_inv` salida insumos + entrada producto elaborado.
- POS y Modificadores ya soportan `receta_modificador_id`:
  - No requiere cambios de estructura, sólo configuración.
- **Consumibles operativos** (limpieza/empaques) no se incluyen en recetas:
  - Se controlan por `mov_inv` tipo `CONSUMO_OPERATIVO`.

---

---

## 4.0 Costeo Dinámico y Control Dual

A partir de la versión 2.0, el sistema introduce un control dual de costos para mejorar la precisión del análisis financiero y la valoración de inventarios.

### 4.1 Costo por Lote (Costo Real)

-   **Definición:** Cada lote de producción (`inventory_batch`) almacena su propio costo unitario (`unit_cost`) en el momento de su fabricación. Este costo se calcula a partir del costo promedio ponderado de las materias primas utilizadas.
-   **Tabla:** `inventory_batch`.
-   **Uso:** Valoración de inventario en libros (contabilidad), costeo de ventas (CMV) real.
-   **Movimiento de Ajuste:** `AJUSTE_COSTO_BATCH`. Se utiliza para corregir o revaluar el costo de un lote si se detecta un error en el costo de sus insumos.

### 4.2 Costo Estándar (Snapshot)

-   **Definición:** Es un costo teórico o de referencia que se calcula diariamente para cada receta. Representa el costo "ideal" de una receta si se produjera con los costos más recientes de las materias primas.
-   **Proceso:** Un job nocturno, `RecipeCostSnapshotJob`, se ejecuta y calcula el costo de cada receta activa.
-   **Tabla:** `recipe_cost_history`. Almacena un registro diario del costo estándar de cada receta, permitiendo analizar la evolución de costos a lo largo del tiempo.
    -   `recipe_id`
    -   `fecha_snapshot`
    -   `costo_estandar`
    -   `costo_insumos_json` (detalle de costos por insumo)
-   **Uso:** Análisis de rentabilidad (Menu Engineering), fijación de precios de venta, presupuestos y detección de variaciones de costos.

### 4.3 Comparativa: Costo Real vs. Costo Estándar

El sistema permite comparar ambos costos para obtener insights valiosos:

-   **Análisis de Eficiencia:** Si el **Costo Real** de un lote es consistentemente más alto que el **Costo Estándar**, puede indicar problemas de merma, rendimiento o eficiencia en la producción.
-   **Impacto de Compras:** Si el **Costo Estándar** sube, refleja un aumento en el precio de las materias primas, alertando al equipo de Compras.
-   **Estabilidad de Precios:** El Costo Estándar proporciona una base estable para la toma de decisiones, mientras que el Costo Real refleja la volatilidad del día a día.

📍 *Versión 2.0 — Octubre 2025 — Coordinado con módulos Compras / Producción / Inventario*
