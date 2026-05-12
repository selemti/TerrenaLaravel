# 21 Catálogo de Unidades de Medida (UOM) y Conversiones

El sistema de Unidades de Medida (UOM) es el eje matemático que permite al ERP transmutar unidades de compra (ej. Bulto), unidades de almacenamiento (ej. Kg) y unidades de consumo de receta (ej. Gramos).

## 1. Estructura de Datos (SSOT)
- **Tabla Maestra**: `selemti.cat_unidades` (o `selemti.unidades_medida` según la versión del DDL).
- **Atributos**: `id`, `nombre`, `abreviatura`, `tipo` (Masa, Volumen, Unidad).

---

## 2. Tipos de Unidades Canónicas
Para evitar errores de redondeo o "Ceros en Inventario", se deben usar exclusivamente estas abreviaturas:

| Tipo | Unidad Base | Sub-unidades Comunes |
| :--- | :--- | :--- |
| **Masa** | `KG` | `G` (Gramo), `MG` (Miligramo) |
| **Volumen** | `L` (Litro) | `ML` (Mililitro), `OZ` (Onzas - Referencia) |
| **Unidad** | `PZ` (Pieza) | `CAJA` (Paquete), `BULTO`, `LAT` (Lata) |

---

## 3. Lógica de Conversión (BOM Implosion)
Cuando el modulo de **RECETAS** (Doc 04) o **INVENTARIOS** (Doc 01) procesa un movimiento, aplica el factor de conversión:

**Fórmula**: `Cantidad_Base * Factor = Cantidad_Resultante`

> [!NOTE]
> El sistema distingue entre **UOM de Inventario** (base para stock/recetas) y **UOM de Compra** (presentaciones comerciales). La tabla `insumo_proveedor_presentacion` gestiona la conversión entre ambas para normalizar el ingreso a stock genérico.

> Si se registra un insumo en `KG` pero la receta usa `G` sin una conversión definida en `selemti.uom_conversion`, el rebaje de inventario fallará o asumirá una paridad 1:1. El [Motor de Consumo (Doc 24)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md) audita estas discrepancias y las registra en el log de auditoría.

---

## 4. Alineación POS-ERP (Impacto Sincronización)
Al vincular un platillo del POS (Doc 35), el sistema asume inicialmente una unidad de venta `PZ` o `PORCION`. El Chef debe mapear esta porción a los ingredientes correspondientes usando las UOMs de este catálogo.

## 5. Mantenimiento
La actualización de este catálogo debe ser restringida a perfiles administrativos senior, ya que un cambio en un factor de conversión altera retroactivamente el valor del inventario valorizado (WAC) de todos los items que lo utilicen.
