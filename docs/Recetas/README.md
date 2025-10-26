# 📘 Módulo de Recetas y Subrecetas

## Objetivo
Estandarizar el flujo técnico y operativo para definir, costear y producir recetas dentro del sistema **Terrena**, alineado con los módulos de Compras, Producción e Inventarios.

El módulo **Recetas** es el punto de unión entre lo que se vende en el POS y lo que se mueve en almacén.  
Permite:
- Definir ingredientes base y subrecetas reutilizables.
- Calcular costos y rendimientos por lote.
- Conectar con órdenes de producción y descargas de inventario.
- Integrar modificadores POS (salsas, proteínas, empaques, etc.) con impacto real en inventario y costo.

---

## 1️⃣ Tipos de Recetas

| Tipo | Descripción | Ejemplo |
|------|--------------|----------|
| **Receta Base** | Preparación principal del platillo vendido en el POS. No incluye modificadores. | Enchiladas Base |
| **Subreceta** | Preparación interna usada como ingrediente en otras recetas. | Salsa Roja Base, Frijoles Refritos |
| **Producto Vendible (PLU POS)** | Plato final mostrado en el POS, asociado a una receta base y modificadores. | Enchiladas Rellenas |
| **Receta de Modificador** | Receta asociada a una opción POS (sin o con costo). | Salsa Verde, Pollo Deshebrado |

---

## 2️⃣ Tipos de Ítems (Inventario)

| Tipo | Descripción | Ejemplo |
|------|--------------|----------|
| `MATERIA_PRIMA` | Ingrediente comprado crudo. | Tortilla, Queso, Jitomate |
| `ELABORADO` | Subreceta producida internamente. | Salsa Verde, Pollo Deshebrado |
| `ENVASADO` | Producto comprado listo para venta. | Electrolit, Topo Chico |
| `CONSUMIBLE_OPERATIVO` | Desechables y limpieza no ligados a ventas, pero con control de stock. | Vaso, Servilleta, Desinfectante |

---

## 3️⃣ Flujo Operativo General

1. **Definición de Receta/Subreceta**  
   En el módulo de Recetas se definen los ingredientes (`items`) y su cantidad base.  
   - Recetas Base y Subrecetas se vinculan con `items`.
   - Cada subreceta tiene su propio rendimiento y costo.

2. **Producción (Mise en Place)**  
   El módulo de Producción ejecuta la receta tipo `ELABORADO`, descargando materias primas y generando stock (batch) del producto terminado (ej. 3 kg de Salsa Verde Base).

3. **Venta (POS + Modificadores)**  
   - El POS selecciona el plato base + modificadores (salsa, proteína, empaque).  
   - Cada modificador tiene asociado su propia receta.  
   - El sistema descarga del inventario los ingredientes y subrecetas correspondientes.

4. **Consumo Operativo**  
   - Materiales no vendibles (limpieza, bolsas, guantes) se descuentan mediante movimiento tipo `CONSUMO_OPERATIVO` en `mov_inv`.

---

## 4️⃣ Estados de Receta y Producción

| Estado | Descripción |
|--------|--------------|
| **BORRADOR** | Receta o producción editable. |
| **PLANIFICADA** | Receta lista para aprobación o producción. |
| **EN_PROCESO** | Producción activa; se está elaborando el batch. |
| **TERMINADA** | Producción completada, pendiente de registrar inventario. |
| **POSTEADA_A_INVENTARIO** | Stock actualizado; insumos descargados, producto terminado creado. |

---

## 5️⃣ Integración con Modificadores POS

| Grupo POS | Tipo | Impacto | Ejemplo |
|------------|------|----------|----------|
| **Salsa** | Sin costo | Cambia subreceta consumida | Salsa Roja / Verde |
| **Proteína** | Con costo | Cambia costo y precio | Pollo (+15), Jamón (+18) |
| **Empaque** | Sin costo o con costo fijo | Descuenta desechables | Vaso + Tapa / Charola to-go |

Cada opción de modificador POS tiene un campo `receta_modificador_id` que apunta a la subreceta correspondiente.

---

## 6️⃣ Interacción con Otros Módulos

| Módulo | Relación |
|--------|-----------|
| **Compras** | Los ingredientes (`items`) provienen del catálogo de compras. |
| **Producción** | Ejecuta subrecetas (ELABORADO) para generar stock físico. |
| **Inventario** | Mantiene control de lotes, stock, consumos POS y operativos. |
| **POS** | Desencadena descargas de inventario y aplica modificadores. |

---

📍 *Autor: Equipo SelemTI · Versión 1.0 (Octubre 2025)*
