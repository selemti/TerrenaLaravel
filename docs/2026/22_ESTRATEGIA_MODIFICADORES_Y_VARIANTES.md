> [!WARNING]
> **REVISION ABRIL 2026:** La creación automática y obligatoria de "Sub-recetas Placeholder" por comando ha sido deprecada (ver `35_PROCEDIMIENTO_VIGENTE_SYNC_POS_RECETAS.md`). Las asunciones sobre el comando `--modifiers` en la sección 5 aplican solo a la "vinculación asistida" desde la interfaz operativa.

# 22 Estrategia de Gestión de Modificadores y Variantes
Para que el modelo de Food Cost sea exacto, el sistema debe ser capaz de procesar no solo el platillo base, sino también las elecciones específicas del comensal que impactan el inventario.

## 1. Clasificación de Modificadores

| Tipo | Definición | Impacto Inventario | Ejemplo |
| :--- | :--- | :--- | :--- |
| **Agregado (Extra)** | Insumo que se suma a la receta base. | **Suma** al consumo total. | + Pollo, + Extra Queso. |
| **Sustitución** | Cambia un insumo base por otro. | **Resta** base, **Suma** sustituto. | Cambiar papas por ensalada. |
| **Variante (Shadow)** | El modificador define la identidad del producto. | El consumo depende del **Sabor/Tipo**. | Electrolit Coco vs Fresa. |
| **Opcional (Sin Costo)**| Instrucciones de servicio sin impacto material. | **Cero**. | Sin cebolla, con servilletas. |

---

## 2. El Modelo de "Sub-Recetas"
Cada modificador en TerrenaLaravel se tratará como una **Sub-Receta** (`selemti.modificadores_pos.receta_modificador_id`), siempre y cuando sea ratificado operativamente (excluyendo modificadores genéricos no inventariables).

1. **Enchiladas Base**: Receta `REC-01` (Tortilla, salsa base, aceite) [Vinculada asistida].
2. **Modificador Pollo**: Si es vinculado, genera Receta `REC-MOD-CHICKEN` (120g de pechuga).
3. **Explosión en Venta**: El sistema suma `REC-01` + `REC-MOD-CHICKEN` para obtener el costo total y el rebaje total.

---

## 3. El Caso Especial: Variantes (Electrolit)
Para productos como el Electrolit, donde el item principal es genérico pero el sabor define el SKU físico:
- Se recomienda usar **Shadow Recipes**.
- El Item POS "Electrolit" se vincula a una receta "Shell" (vacía).
- Los Modificadores "Fresa", "Coco", etc., contienen el insumo físico final al 100%.

---

## 4. Estado de Implementación (Certificado)
Las brechas técnicas de explosión han sido resueltas en la Fase 2:
1. **Persistencia**: `PosSyncService` y los controladores de tickets guardan el detalle de modificadores.
2. **Explosión**: El [Motor de Consumo Recursivo (Doc 24)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md) recorre atomizadamente cada modificador y rebaja sus insumos.

---

## 5. Protocolo de Documentación
Cada nuevo modificador creado en el POS debe ser:
1. **Analizado** operativamente desde el bloque asistido (POS Link) para dictaminar si requiere impactar estructura (Ignorar o Vincular).
2. Si amerita inventario, editado en el **RecipeEditor** para asignar su insumo (ej. 1 Bottle of Chocolate Milk).
~3. El uso ciego de `--modifiers` en la terminal sin justificación es contraproducente y está deprecado.~
