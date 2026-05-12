# ⚠️ DOCUMENTO SUPERSEDIDO
Este documento no define el orden actual de ejecución.
Consultar primero: [00_README_EJECUCION_FASE_2.md](00_README_EJECUCION_FASE_2.md)

# 28 Carga Inicial Operativa: UOM, Almacenes e Insumos (Fase 2)

Este documento define el set de datos real y normalizado para el arranque de la Fase 2 en TerrenaLaravel. Su objetivo es evitar duplicidades y garantizar la integridad del motor de consumo.

## 1. Auditoría de Estado de Tablas (Pre-Carga)
Tras la auditoría técnica del 14-Abr-2026, se detectó:
- **`cat_unidades`**: 6 registros activos (KG, L, PZ, G, ML, CAJA). **Estado: OK**.
- **`cat_uom_conversion`**: Identificada como tabla de relación. **Estado: Vacía**.
- **`almacen`**: **Estado: Vacía**.
- **`items`**: 6 registros con duplicidades lógicas (Aceites/Leches). **Estado: Requiere Purga**.
- **`item_categories`**: Registros redundantes detectados. **Estado: Requiere Purga y Normalización**.

---

## 2. Definición del Dataset MAD (Minimum Auditable Dataset)

### 2.1 Catálogo de Unidades (UOM)
Se utilizarán estas 5 unidades como base soberana:
| Clave | Nombre | Acción |
| :--- | :--- | :--- |
| `KG` | Kilogramo | Mantener existente |
| `G` | Gramo | Mantener existente |
| `L` | Litro | Mantener existente |
| `ML` | Mililitro | Mantener existente |
| `PZ` | Pieza | Mantener existente |

### 2.2 Conversiones Iniciales
| Unidad Origen | Unidad Destino | Factor |
| :--- | :--- | :--- |
| `KG` | `G` | 1000 |
| `L` | `ML` | 1000 |

### 2.3 Estructura de Almacenes
| ID / Clave | Nombre | Descripción |
| :--- | :--- | :--- |
| `ALM-SEC` | Almacén Seco | Granos, abarrotes, latas. |
| `ALM-REF` | Refrigeración | Carnes, lácteos, verduras. |
| `ALM-COC` | Producción / Cocina | Punto de despacho y semiterminados. |

### 2.4 Familias de Ítems (Taxonomía v1.0)
Se han integrado las 17 familias oficiales (Lácteos, Proteínas, Verduras, Frutas, Abarrotes, etc.) para mantener consistencia con el catálogo maestro previo.

---

## 3. Catálogo de 26 Insumos Base (Armonizados v1.0)
Estos insumos utilizan la nomenclatura oficial del catálogo maestro histórico.

| ID Normalizado | Nombre (v1.0) | Categoría | UOM Base |
| :--- | :--- | :--- | :--- |
| `INS-TOR-01` | Tortilla de maíz | CAT-08 (Masas) | KG |
| `INS-TOT-01` | Totopo frito base | CAT-08 (Masas) | KG |
| `INS-POL-01` | Pechuga de pollo cruda | CAT-02 (Proteína) | KG |
| `INS-QUE-01` | Queso de hebra | CAT-01 (Lácteos) | KG |
| `INS-CRE-01` | Crema ácida | CAT-01 (Lácteos) | LT |
| `INS-CEB-01` | Cebolla blanca | CAT-03 (Verduras) | KG |
| `INS-JIT-01` | Jitomate rojo | CAT-03 (Verduras) | KG |
| `INS-CHI-01` | Chile serrano | CAT-03 (Verduras) | KG |
| `INS-ACE-01` | Aceite vegetal | CAT-05 (Abarrotes) | LT |
| `INS-FRI-01` | Frijol negro seco | CAT-05 (Abarrotes) | KG |
| `INS-SRO-01` | Salsa Roja Base | CAT-12 (Subrecetas)| KG |
| `INS-SVE-01` | Salsa Verde Base | CAT-12 (Subrecetas)| KG |
| (Ver lista completa en `fase2_insumos_base.csv`) | | | |

---

## 4. Plantillas de Importación (Layouts Finales)

### 4.1 Plantilla A: Almacenes e Insumos
| Columna | Obligatorio | Validación |
| :--- | :--- | :--- |
| `id` | SÍ | Único, Alfanumérico (Normalizado) |
| `nombre` | SÍ | Texto descriptivo |
| `unidad_medida_id` | SÍ | Debe existir en `cat_unidades` |
| `categoria_id` | SÍ | Catálogo definido (PROTEINA, VERDURA, etc) |
| `costo_inicial` | SÍ | Decimal (2 decimales) |

### 4.2 Plantilla B: Inventario Inicial (Punto Cero)
| Columna | Obligatorio | Dependencia |
| :--- | :--- | :--- |
| `item_id` | SÍ | Plantilla A |
| `almacen_id` | SÍ | ALM-SEC / ALM-REF / ALM-COC |
| `cantidad` | SÍ | Positivo |

---

## 5. Reglas de Higiene
1. **No Duplicidad**: Antes de la carga masiva, se recomienda ejecutar `DELETE FROM selemti.items` para limpiar los registros de prueba previos.
2. **Normalización de IDs**: NUNCA usar IDs autoincrementales para la lógica de negocio; usar prefijos descriptivos (INS-XXX).
3. **Persistencia**: Esta carga inicial será el "Snapshot" para el primer cálculo de WAC en Fase 3.
