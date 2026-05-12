# 19 Matriz de Población Mínima: Fase 2 (Inventarios)

Este documento define el dataset mínimo viable necesario para que la Fase 2 del Modelo Financiero Canónico sea ejecutable y auditable.

## 1. Clasificación por Prioridad

### 🟥 A. Nivel CRÍTICO (Bloqueo Total)
*Sin estos datos, la lógica canónica fallará por falta de integridad referencial.*

| Concepto | Detalle | Justificación |
| :--- | :--- | :--- |
| **Insumos Genéricos**| Catálogo Maestro v1.0 (sin marcas). | Evita duplicidad en recetas y estabiliza el stock. |
| **UOM & Conversiones** | Matriz de conversión (Kg -> g, L -> ml). | Base de toda la aritmética de WAC y recetas. |
| **Carga de Almacenes** | Estructura de Bodegas y Cocinas. | Define la segregación del stock. |

### 🟨 B. Nivel NECESARIO (Funcionalidad)
*Sin estos datos, el sistema funciona pero no entrega KPIs financieros (Food Cost).*

| Concepto | Detalle | Justificación |
| :--- | :--- | :--- |
| **Presentaciones** | Marcas y formatos por proveedor. | Permite la compra real y traduce a UOM base. |
| **Recetas (Top 50)** | Insumos por producto vendible. | Permite calcular el Food Cost Teórico. |
| **Enlace POS-Recipe** | Mapeo `menu_items` -> `recipe_id`. | Vincula la venta real con el consumo de inventario. |

### 🟦 C. Nivel DESEABLE (Optimización)
*Mejoran el control pero no bloquean el modelo SSOT.*

| Concepto | Detalle | Justificación |
| :--- | :--- | :--- |
| **Taxonomía Mermas** | Catálogo de motivos de pérdida. | Análisis detallado de rentabilidad (Causa-Raíz). |
| **Stocks de Seguridad** | Min/Max por item. | Habilita alertas de resurtido automático. |

---

## 2. Secuencia Mínima de Carga (Roadmap de Datos)

Para evitar errores de "llave foránea" o inconsistencias de unidad, se debe seguir estrictamente este orden:

1.  **Sincronización Maestra POS-RECIPE**: Ejecutar `php artisan recipes:sync-pos`. Crea la base 1-a-1 de platillos conforme al [Doc 20](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/20_PROTOCOLO_ALINEACION_POS_ERP.md).
2.  **UOM (Unidades de Medida)**: Kg, L, Pz, Mililitro, Gramo.
2.  **Conversiones**: Estandarizar que 1 Kg = 1000g globalmente.
3.  **Proveedores**: Alta de entidades fiscales de suministro.
4.  **Insumos (Master)**: Catálogo genérico vinculado a UOMs (v1.0).
5.  **Presentaciones**: Relación Insumo-Proveedor-Marca-Factor.
6.  **Locaciones (Almacenes)**: Definir dónde vive el inventario físico.
7.  **Inventario Inicial**: "Snapshot" de arranque (Cisterna, Almacén Seco).
8.  **Recetas**: Definición de la composición de productos.
9.  **Vínculo POS**: Asociar productos de venta con sus recetas.
10. **Taxonomía de Mermas**: Clasificación de pérdidas permitidas.

---

## 3. Conclusión de Estrategia
La Fase 2 debe iniciar con una **Sesión de Población** (Data Entry / Importación CSV) antes de activar cualquier lógica de cálculo de WAC. 

> [!IMPORTANT]
> El éxito de la Fase 2 depende más de la calidad del dato cargado que de la sofisticación del código PHP/SQL.
