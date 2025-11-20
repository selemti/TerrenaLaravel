# 📦 Catálogo Inicial de Ítems y Familias (Recetas)

## 1️⃣ Estructura de Clasificación

| Campo | Descripción |
|--------|--------------|
| **Familia** | Agrupación operativa (Lácteos, Verduras, Desechables, etc.) |
| **Categoría** | Subgrupo funcional (Quesos, Jarabes, Bolsas, Limpieza) |
| **Tipo** | MATERIA_PRIMA / ELABORADO / ENVASADO / CONSUMIBLE_OPERATIVO |
| **Unidad Base (UOM)** | KG / LT / PZ / ML / PAQ |
| **Producible** | Si el ítem se fabrica internamente |
| **Consumible Operativo** | Si es material no vendido (limpieza/empaque) |

---

## 2️⃣ Familias Principales

| Familia | Categorías |
|----------|-------------|
| **Lácteos y Huevo** | Leche, Yogurt, Quesos, Crema, Huevo |
| **Proteínas y Cárnicos** | Pollo, Cecina, Arrachera, Jamón, Salchicha |
| **Verduras Frescas** | Tomate, Cebolla, Chiles, Cilantro, Lechuga |
| **Frutas Frescas** | Fresa, Plátano, Papaya, Piña, Frutos rojos |
| **Abarrotes Secos** | Harina, Azúcar, Arroz, Frijol, Pasta, Especias |
| **Jarabes y Café** | Jarabes, Bases frappé, Café molido, Matcha |
| **Panadería y Postres** | Pan dulce, Pan salado, Postres listos |
| **Salsas y Aderezos** | Subrecetas y salsas base |
| **Bebidas Embotelladas** | Agua, Electrolit, Topo Chico, Refrescos |
| **Desechables / Empaques** | Vasos, Tapas, Charolas, Cubiertos, Servilletas |
| **Limpieza y Operación** | Desinfectantes, Bolsas, Guantes, Trapos |

---

## 3️⃣ Ejemplo de Ítems Clave

| Nombre | Tipo | UOM | Producible | Consumible Operativo |
|---------|------|------|-------------|------------------------|
| Leche deslactosada | MATERIA_PRIMA | LT | ❌ | ❌ |
| Queso fresco | MATERIA_PRIMA | KG | ❌ | ❌ |
| Pollo deshebrado | ELABORADO | KG | ✅ | ❌ |
| Salsa Roja Base | ELABORADO | LT | ✅ | ❌ |
| Empaque Platillo Caliente | ELABORADO | PZ | ✅ | ✅ |
| Vaso frappé 16oz | MATERIA_PRIMA | PZ | ❌ | ✅ |
| Servilleta desechable | MATERIA_PRIMA | PZ | ❌ | ✅ |
| Desinfectante cocina | MATERIA_PRIMA | LT | ❌ | ✅ |

---

## 4️⃣ Próximos Pasos

1. Poblar `items` con este catálogo.
2. Asociar recetas tipo `ELABORADO` a subrecetas base.
3. Configurar `stock_policy` min/max para reposición.
