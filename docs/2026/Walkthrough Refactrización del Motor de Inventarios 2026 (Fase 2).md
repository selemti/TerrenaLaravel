# Walkthrough: Refactrización del Motor de Inventarios 2026 (Fase 2)

Se ha completado con éxito la refactorización técnica de la lógica de consumo de inventario para **TerrenaLaravel**, habilitando el soporte para recetas jerárquicas, modificadores complejos y gestión inteligente de semiterminados.

## 🚀 Logros Principales

### 1. Motor de Consumo Recursivo (v2.5)
Se ha re-diseñado la función `selemti.fn_expandir_consumo_ticket` utilizando **CTEs Recursivas** (`WITH RECURSIVE`).
- **Explosión Profunda**: El sistema navega el árbol de recetas hasta 5 niveles de anidamiento.
- **Soporte de Modificadores**: Se integró el procesamiento de `public.ticket_item_modifier`, vinculándolos a sub-recetas placeholder `REC-MOD-*` dinámicamente.

### 2. Lógica "Stock-Aware" (Semiterminados)
Este es el componente más crítico solicitado por **Gustavo Selem**:
- **Conmutación Inteligente**: Al explotar una receta (ej. Chilaquiles), el motor verifica el stock en tiempo real de sus sub-componentes (ej. Salsa Roja).
- **Decisión**: 
    - Si hay **Salsa Roja** producida (en stock), el sistema descuenta la cantidad directa.
    - Si **No hay stock**, el sistema explota la Salsa Roja hasta sus ingredientes base (tomate, chile, etc.).

### 3. Sincronización POS-ERP Mejorada
El comando `php artisan recipes:sync-pos` ahora **(DEPRECADO COMO GENERADOR AUTOMÁTICO, VER DOC 35)**:
- Diferencia modificadores por **Grupo de Modificador**, permitiendo tener "Cebolla" en diferentes grupos con costos distintos.
- Mapea códigos canónicos para una trazabilidad total entre Floreant y el ERP.

## 🧪 Resultados de Validación (Empíricos)

Se ejecutó una batería de 17 pruebas técnicas ([tmp_validate_recursion_v17.php](file:///C:/xampp3/htdocs/TerrenaLaravel/tmp_validate_recursion_v17.php)) con los siguientes resultados certificados:

| Escenario | Resultado Esperado | Resultado Obtenido | Estado |
|-----------|-------------------|--------------------|--------|
| **Sin Stock de Sub-receta** | Explosión total hasta insumos base | Descarga de Insumo (MP_ID=999) | ✅ OK |
| **Con Stock de Sub-receta** | Consumo de la unidad producida | Descarga de Sub-receta (MP_ID=0) | ✅ OK |
| **Modificadores Anidados** | Explosión de receta base + modificador | Consumo consolidado en Kardex | ✅ OK |

> [!IMPORTANT]
> La función `selemti.fn_expandir_consumo_ticket` ahora es el SSOT (Single Source of Truth) para la descarga de inventario del POS, garantizando que el **Food Cost** sea exacto independientemente de si el plato se preparó desde cero o se utilizó un producto pre-elaborado.

## 🛠️ Archivos Técnicos Generados
- **Función DDL**: [tmp_update_fn_consumo_recursive_v2_5.sql](file:///C:/xampp3/htdocs/TerrenaLaravel/tmp_update_fn_consumo_recursive_v2_5.sql)
- **Script de Validación**: [tmp_validate_recursion_v17.php](file:///C:/xampp3/htdocs/TerrenaLaravel/tmp_validate_recursion_v17.php)

---
**Fase 2: Lógica certificada / pendiente activación operativa mediante POS Link y carga de datos reales**. El motor está listo para recibir la carga masiva de insumos una vez la base se prepare adecuadamente y se resuelvan las exclusiones POS.
