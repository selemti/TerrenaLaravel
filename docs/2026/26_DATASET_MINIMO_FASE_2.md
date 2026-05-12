# ⚠️ DOCUMENTO SUPERSEDIDO
Este documento no define el orden actual de ejecución.
Consultar primero: [00_README_EJECUCION_FASE_2.md](00_README_EJECUCION_FASE_2.md)

# 26 Especificación del Dataset Mínimo Realista (MAD - Fase 2)

> [!CAUTION]
> **GATE OPERATIVO CRÍTICO:** La **Fase D3** de este dataset **NO puede ejecutarse** ni utilizarse en ambiente de pruebas o producción sin antes haber completado POS Link. Las Fases D0, D1 y D2 (Catálogos base) están exentas de este bloqueo y se permite su carga inmediata.

Este documento define el ecosistema de datos mínimo necesario para realizar la transición de "Arquitectura Lógica" a "Validación Real" del motor de inventarios de TerrenaLaravel.

## 1. Alcance Técnico
El objetivo es poblar el sistema con un volumen controlado de datos que permita estresar el motor de consumo recursivo (Doc 24) bajo escenarios reales de producción.

## 2. Definición del Ecosistema Base (D0)

### 2.1 Unidades de Medida (UOM)
| Código | Nombre | Tipo |
| :--- | :--- | :--- |
| `PZ` | Pieza | Unidad |
| `KG` | Kilogramo | Masa |
| `G` | Gramo | Masa |
| `L` | Litro | Volumen |
| `ML` | Mililitro | Volumen |

### 2.2 Conversiones Críticas
- 1 `KG` = 1000 `G`
- 1 `L` = 1000 `ML`

### 2.3 Almacenes Operativos
1. **ALM-SEC**: Almacén Seco (Abarrotes y granos).
2. **ALM-REF**: Refrigeración (Proteínas y lácteos).
3. **ALM-COC**: Producción / Cocina (Punto de consumo y semiterminados).

---

## 3. Catálogo de Insumos Críticos Genéricos (v1.0)
Estos ítems representan el maestro de inventario y **NO deben contener marcas**.

| Categoría | Items Genéricos |
| :--- | :--- |
| **Proteínas** | Pechuga de pollo cruda, Jamón de pavo, Chorizo fresco, Tocino, Huevo fresco. |
| **Lácteos** | Queso de hebra, Crema ácida, Leche deslactosada. |
| **Abarrotes** | Aceite vegetal, Frijol negro seco, Arroz blanco, Telera (pan torta), Mayonesa, Catsup, Mostaza, Café molido espresso, Azúcar estándar, Sal fina. |
| **Verduras** | Cebolla blanca, Jitomate rojo, Chile serrano, Limón verde. |
| **Bases** | Tortilla de maíz, Totopo frito base. |
| **Producción** | Salsa Roja Base, Salsa Verde Base. |

---

## 3.5 Presentaciones de Compra (D1.5)
La especificidad comercial (marcas como Nutrioli, Member's Mark, etc.) se gestionará exclusivamente a través de la relación Proveedor-Presentación, liberando al inventario de nombres comerciales.

---

## 4. Selección de 20 Recetas para Validación Real

| Tipo de Prueba | Recetas Sugeridas (POS ID) | Objetivo Técnico |
| :--- | :--- | :--- |
| **Simples** | Espresso (45), Jugo Naranja (54), Agua 500ml (61), Omelette J&T (36), Quesadilla Jam (97). | Validar explosión de nivel 1. |
| **Compuestas** | Club Sándwich (25), Sopa Azteca (14), Puchero Pollo (13), Super Hot Dog (104). | Validar BOM multinivel. |
| **Con Modificadores** | Huevos al Gusto (29), Picada (2), Chilaquiles (33), Ice Latte Sabor (106). | Validar persistencia de modificadores. |
| **Con Semiterminados** | Salsa Roja (Mod 15), Salsa Verde (Mod 14), Frijol Refrito (Mod 17). | Validar conmutación Stock-Aware. |
| **Variantes/Sabores** | Electrolit (65), Agua de Sabor (66), Naj Frappe Sabor (110). | Validar selección de item_id. |

### 4.1 Escenario de Prueba Crítico (Sub-recetas)
Para validar la recursividad mencionada por Gustavo Selem, se utilizará:
- **Platillos**: Picada (2) o Chilaquiles (33).
- **Modificador**: Salsa Roja (ID 15) o Salsa Verde (ID 14).
- **Lógica**: La Picada consume la **Sub-receta de Salsa Roja**. Si hay stock de Salsa Roja (producida en cocina central), se rebaja la unidad; de lo contrario, se explosionan los tomates/chiles.

---

## 5. Taxonomía Mínima de Mermas
Para validar el impacto en Kardex sin ventas, se habilitarán estos motivos:
- `MERMA_PROD`: Merma en proceso de producción.
- `DESPERDICIO`: Plato devuelto o error en cocina.
- `CADUCIDAD`: Producto vencido en almacén.
- `AJUSTE_CONTEO`: Diferencia detectada en inventario físico.
- `CONSUMO_INT`: Cortesías o consumo de personal.

---

## 6. Orden Lógico de Carga
1. **Fase D0**: Carga de UOM, Conversiones y Almacenes.
2. **Fase D1**: Carga de Insumos Genéricos (v1.0).
3. **Fase D1.5**: Carga de Presentaciones Comerciales (Opcional por Cliente).
4. **Fase D2**: Inventario Inicial (Punto Cero).
5. **Fase D3**: **Vinculación Asistida POS** (Decisión humana de qué platillos/modificadores tendrán receta) y posterior Población BOM.
