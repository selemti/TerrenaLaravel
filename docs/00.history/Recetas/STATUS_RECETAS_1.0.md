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
  - Posteo de orden de producción → `mov_inv` salida insumos + entrada producto elaborado.
- POS y Modificadores ya soportan `receta_modificador_id`:
  - No requiere cambios de estructura, sólo configuración.
- **Consumibles operativos** (limpieza/empaques) no se incluyen en recetas:
  - Se controlan por `mov_inv` tipo `CONSUMO_OPERATIVO`.

---

📍 *Versión inicial 25/10/2025 — Coordinado con módulos Compras / Producción / Inventario*
