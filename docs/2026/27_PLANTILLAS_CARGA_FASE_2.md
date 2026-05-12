# ⚠️ DOCUMENTO SUPERSEDIDO
Este documento no define el orden actual de ejecución.
Consultar primero: [00_README_EJECUCION_FASE_2.md](00_README_EJECUCION_FASE_2.md)

# 27 Plantillas de Carga (MAD - Fase 2)

> [!CAUTION]
> **GATE OPERATIVO CRÍTICO:** Estas plantillas no deben utilizarse ni cargarse para poblar tablas maestras de Recetas (`T2`) o Modificadores (`T3`) hasta **haber completado satisfactoriamente el paso de POS Link** (Ver doc 36).

> [!WARNING]
> **REVISION ABRIL 2026:** Las entidades de Receta y Modificador listadas aquí (T2 y T3) **ya no se generan automáticamente** por el comando de POS Sync. Se requiere intervención humana directa (flujo asistido) para crearlas e hidratarlas según `35_PROCEDIMIENTO_VIGENTE_SYNC_POS_RECETAS.md`.

Este documento define la estructura de campos requerida para realizar la carga controlada de datos en TerrenaLaravel.

## T0: Unidades y Catálogos Base (Orden: 1)

### Plantilla UOM & Conversiones
| Tabla | Campo | Tipo | Notas |
| :--- | :--- | :--- | :--- |
| `cat_unidades` | `codigo` | VARCHAR(10) | PZ, KG, G, L, ML (PK) |
| `cat_unidades` | `nombre` | VARCHAR(50) | Nombre descriptivo |
| `uom_conversion` | `u_origen` | VARCHAR(10) | Código de unidad padre |
| `uom_conversion` | `u_destino` | VARCHAR(10) | Código de unidad hijo |
| `uom_conversion` | `factor` | DECIMAL | Ej: 1000 para KG -> G |

---

## T1: Artículos e Inventario Inicial (Orden: 2)

### Plantilla Insumos (Items)
| Campo | Tipo | Obligatorio | Notas |
| :--- | :--- | :--- | :--- |
| `id` | VARCHAR(25) | SÍ | ID Normalizado (Ej: INS-001). **GENÉRICO**. |
| `nombre` | VARCHAR(100) | SÍ | Nombre genérico (v1.0). SIN MARCAS. |
| `uom_id` | VARCHAR(10) | SÍ | Unidad base de inventario (L, KG, PZ). |
| `categoria_id` | VARCHAR(10) | SÍ | ID de Familia (CAT-01 a CAT-17). |

### T1.5: Presentaciones de Compra (Marcas/Formatos)
| Campo | Tipo | Obligatorio | Notas |
| :--- | :--- | :--- | :--- |
| `item_id` | VARCHAR(25) | SÍ | FK hacia Insumo Genérico (Ej: INS-001) |
| `proveedor_id`| VARCHAR(25) | SÍ | ID del Proveedor |
| `uom_compra` | VARCHAR(10) | SÍ | Ej: BOTELLA, CAJA, GARRAFA |
| `factor` | DECIMAL | SÍ | Multiplicador para llegar a UOM base |
| `nombre_comercial`| VARCHAR(100)| NO | Marca/Nombre específico (Ej: Aceite Nutrioli) |

### Plantilla Inventario Inicial
| Campo | Tipo | Notas |
| :--- | :--- | :--- |
| `item_id` | VARCHAR(25) | FK hacia Insumos |
| `almacen_id` | VARCHAR(10) | ALM-SEC, ALM-REF, ALM-COC |
| `cantidad` | DECIMAL | Existencia física al "Punto Cero" |
| `costo_unitario` | DECIMAL | Para primera capa de costo |

---

## T2: Estructura de Recetas (Orden: 3)

### Plantilla Receta Cabecera
| Campo | Tipo | Notas |
| :--- | :--- | :--- |
| `id` | VARCHAR(25) | REC-XXXX (Normalizado) |
| `pos_id` | INTEGER | ID del Floreant POS (Crucial para Sync) |
| `nombre` | VARCHAR(100) | Nombre Comercial |

### Plantilla Receta Detalle (Ingredientes)
| Campo | Tipo | Notas |
| :--- | :--- | :--- |
| `receta_id` | VARCHAR(25) | ID de la cabecera anterior |
| `item_id` | VARCHAR(25) | ID del insumo (o de otra receta si es sub-receta) |
| `cantidad` | DECIMAL | Cantidad bruta de ingrediente |
| `uom_id` | VARCHAR(10) | Unidad de medida en receta |

---

## T3: Modificadores y Variantes (Orden: 4)

### Plantilla Modificadores Realistícas
| Campo | Tipo | Notas |
| :--- | :--- | :--- |
| `mod_pos_id` | INTEGER | ID del modificador en Floreant |
| `tipo_impacto` | ENUM | EXTRA, SUSTITUCION, VARIANTE, INFO |
| `rec_id_asociada`| VARCHAR(25) | ID de la Sub-Receta (BOM) del modificador |

---

## T4: Taxonomía de Mermas (Orden: 5)
| Código | Descripción | Requiere Aprobación |
| :--- | :--- | :--- |
| `M_PROD` | Merma producción | No |
| `M_CAD` | Caducidad | Sí |
| `M_AJU` | Ajuste físico | Sí |
