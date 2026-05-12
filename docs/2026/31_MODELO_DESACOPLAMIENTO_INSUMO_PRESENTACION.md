# 31 Modelo de Desacoplamiento Insumo-Presentación

Este documento detalla la arquitectura técnica de TerrenaLaravel para separar los **Insumos Genéricos** de las **Presentaciones de Compra**, siguiendo las mejores prácticas de abastecimiento y costeo.

## 1. El Concepto: Genérico vs. Específico

| Nivel | Entidad | Ejemplo | Propósito |
| :--- | :--- | :--- | :--- |
| **Maestro** | `selemti.items` | Aceite Vegetal | Controlar existencias totales, recetas y WAC. |
| **Operativo**| `insumo_proveedor_presentacion` | Aceite Nutrioli 900ml | Gestionar compras, proveedores y precios. |

## 2. Estructura de Datos (Arquitectura Soberana)

La tabla `selemti.insumo_proveedor_presentacion` actúa como el puente de normalización:

- **`item_id`**: Vincula al ítem genérico en el catálogo maestro.
- **`proveedor_id`**: Identifica quién nos vende esta presentación.
- **`uom_compra_id`**: La unidad en la que se compra (ej. BOTELLA, CAJA-12, GALON).
- **`factor_a_base`**: La constante matemática que convierte la compra en inventario.
  - *Ejemplo*: Si compramos una botella de 900ml y nuestra unidad base es Litro (L), el factor es **0.90**.

---

## 3. Beneficios del Desacoplamiento

1.  **Cálculo de WAC Real**: El sistema puede promediar el costo de un "Litro de Aceite" sin importar si se compró Nutrioli, 1-2-3 o Kirkland, siempre que se registre el precio y el factor de conversión correcto.
2.  **Sustitución de Proveedores**: Podemos cambiar de proveedor sin necesidad de crear un nuevo ítem en el catálogo de recetas. Solo se añade una nueva relación en la tabla de presentaciones.
3.  **Higiene de Recetas**: Las recetas (BOM) se mantienen limpias utilizando nombres genéricos, lo que facilita la actualización de precios de menú.

---

## 4. Ejemplo Práctico de Carga (Phase 2.3)

Al cargar el catálogo maestro con el MAD, los registros deben lucir así:

**Tabla `items` (Genérico):**
- ID: `INS-ACE-01`
- Nombre: Aceite Vegetal
- UOM Base: L (Litro)

**Tabla `insumo_proveedor_presentacion` (Específico):**
- Item: `INS-ACE-01`
- Proveedor: PROV-ABARR-01 (Sam's Club)
- UOM Compra: GARRAFA (20 L)
- **Factor a Base: 20.0**
- Precio: $650.00

---

## 5. Dictamen de Diseño
**El sistema está técnicamente preparado para operar sin marcas en el catálogo maestro.**  
Se recomienda que la carga inicial de la Fase 2 únicamente pueble la tabla `items` con nombres genéricos (v1.0), dejando la especificidad de marcas para el módulo de Compras y Recepción de Mercancía.
