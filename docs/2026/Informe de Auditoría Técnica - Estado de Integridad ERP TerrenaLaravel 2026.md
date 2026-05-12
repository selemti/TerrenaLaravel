# Informe de Auditoría Técnica: Estado de Integridad ERP TerrenaLaravel 2026

## Resumen Ejecutivo
Tras una auditoría cruzada entre la Base de Datos, el Backend (Modelos/Servicios) y el Frontend (Livewire), se ha detectado una **fragmentación crítica de la arquitectura**. El sistema actualmente opera bajo tres estándares técnicos distintos que no comparten lógica de negocio, lo que representa el principal bloqueador para la integridad de la Fase 2 (Inventarios).

---

## 1. Hallazgos en Base de Datos (selemti)
El esquema `selemti` es un "cementerio de prototipos" donde coexisten múltiples versiones de la misma entidad.

| Entidad | Tablas en Conflicto | Riesgo |
| :--- | :--- | :--- |
| **Insumos** | `items` (Moderno), `insumo` (Legacy) | Duplicidad de catálogo maestro. |
| **Proveedores** | `insumo_proveedor_presentacion`, `item_vendor`, `item_vendor_prices` | 3 formas distintas de guardar precios/marcas. |
| **Producción** | `production_orders`, `op_cab`, `op_produccion_cab` | 3 sistemas de órdenes de producción paralelos. |
| **Traspasos** | `transfer_cab`, `traspaso_cab` | Incertidumbre sobre qué tabla descuenta stock real. |
| **UOM** | `cat_unidades`, `unidad_medida_legacy`, `unidades_medida_legacy` | Fallos en conversiones de recetas. |

**Hallazgo Crítico:** Coexistencia de IDs tipo `BIGINT` (Secuencias) y `VARCHAR` (Strings de FloreantPOS).

---

## 2. Hallazgos en Backend (Modelos y Servicios)
Se detectó una "Arquitectura de Sombra" donde el código ignora activamente los modelos de datos.

- **Fragmentación de Modelos**: Existen 4 versiones de [Item](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Models/Inv/Item.php#8-63) (`Inv\Item`, `Inventory\Item`, [Item](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Models/Inv/Item.php#8-63) raíz e [Insumo](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Models/Insumo.php#8-40)).
- **Bypass de Eloquent**: El [PurchasingService](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Services/Purchasing/PurchasingService.php#12-686) utiliza Query Builder directo (`DB::table`), ignorando relaciones y validaciones definidas en los modelos.
- **División de Inteligencia**: El modelo `Inv\Item` tiene las relaciones de UOM, pero el modelo [Item](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Models/Inv/Item.php#8-63) raíz tiene las políticas de stock. Ningún modelo es "dueño" del objeto completo.

---

## 3. Hallazgos en Frontend (Livewire)
La capa de presentación es **totalmente agnóstica de la arquitectura**.

- Componenes como [ItemsIndex.php](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Livewire/Inventory/ItemsIndex.php) ignoran modelos y servicios.
- Realizan `INSERT`, `UPDATE` y `SELECT` manuales vía `DB::table`.
- **Impacto**: Cualquier lógica centralizada que se implemente en un Modelo (como el desacoplamiento de marcas) **será invisible para la interfaz de usuario**.

---

## 4. Diagnóstico de Fase 2: Insumo-Presentación
El modelo propuesto de separar el Insumo Genérico de la Presentación de Compra **no es viable en el estado actual** porque:
1. El módulo de Compras no lee las presentaciones de `insumo_proveedor_presentacion`.
2. El módulo de Inventarios (Livewire) busca la marca directamente en la descripción del ítem genérico.
3. El motor de consumo (`fn_expandir_consumo_ticket`) es la única pieza consistente (PL/pgSQL), pero los datos que recibe del ERP están corruptos por la fragmentación anterior.

---

## 5. Recomendaciones de Remediación (Pre-Carga)
1. **Soberanía del Modelo**: Unificar todas las versiones de [Item](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Models/Inv/Item.php#8-63) en `App\Models\Inventory\Item` y eliminar las redundantes.
2. **Refactorización de Servicios**: Migrar [PurchasingService](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Services/Purchasing/PurchasingService.php#12-686) y [ItemsIndex](file:///C:/xampp3/htdocs/TerrenaLaravel/app/Livewire/Inventory/ItemsIndex.php#10-295) para que utilicen el Modelo Soberano en lugar de Query Builder crudo.
3. **Limpieza Quirúrgica**: Ejecutar el protocolo de purga (Doc 29) inmediatamente para eliminar las tablas legacy que confunden al equipo de desarrollo.
4. **Validación de ID**: Estandarizar que el ID de `items` es el `floreant_id` (String) para asegurar la sincronía con el POS.

---
**Auditor:** Antigravity AI
**Fecha:** 14 de Abril, 2026
