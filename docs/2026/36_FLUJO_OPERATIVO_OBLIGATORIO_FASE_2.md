# 36 Flujo Operativo Obligatorio (Fase 2)

## DECLARACIÓN JURADA OPERATIVA
**Queda ESTRICTAMENTE PROHIBIDO:**
- 🚫 Crear recetas manuales sin un vínculo previo al POS.
- 🚫 Cargar Estructuras BOM (Ingredientes) a recetas no vinculadas.
- 🚫 Ejecutar pruebas de consumo recursivo o rebaje de inventario sin vínculo exacto al POS.
- 🚫 Registrar modificadores base y placeholders operativos desde cualquier entorno ajeno a la interfaz asistida de POS.

---

## 1. El Porqué del Gate Operativo
La arquitectura de TerrenaLaravel carece de integridad si las operaciones generadas en el sistema de ventas (POS) no aterrizan en una identidad formal (Receta/Sub-Receta/Item) de inventario. 

**Excepción Estratégica:**
> [!NOTE]
> POS Link es un gate obligatorio EXCLUSIVAMENTE para la Fase **D3** (Recetas, modificadores y explosión BOM). Las fases preparatorias **D0, D1 y D2** (UOM, almacenes, insumos genéricos, presentaciones de compra e inventario maestro) NO dependen de POS Link y **deben avanzar** para preparar el entorno a las recetas.

**Para que la explosión y costeo funcionen, TODO platillo a venderse debe pasar por el "Módulo de POS Link".**

---

## 2. ORDEN OBLIGATORIO DE EJECUCIÓN (Cold Start a Producción)

1. **Fase D0: Configuraciones Base**
   - Establecer UOM (Unidades), conversiones y catálogo de Almacenes.
2. **Fase D1: Insumos Maestro**
   - Puesta en marcha de insumos genéricos (sin marcas comerciales).
3. **Fase D1.5: Presentaciones**
   - Definir presentaciones de compra asociadas al proveedor.
4. **Fase D2: Inventario Inicial**
   - Entrada física al sistema (Punto Cero).
5. **Fase D3: POS Link y Recetas**
   - **Paso A (Vinculación)**: Entrada al módulo asistido para Atar el botón POS con el Motor de Recetas.
   - **Paso B (Cuerpo de Receta)**: Definición del BOM desde el RecipeEditor o UI manual.
   - **Paso C (Modificadores)**: Aprobación posterior de modificadores inventariables.
   - **Paso D (Validación)**: Pruebas de consumo recursivo atestiguando costo D2 vs Venta POS.

---

## 3. Estado de la Herramienta
**BLOQUEANTE PARA D3:**
A la fecha (Abril 2026), el módulo estructurado **POS Link** es inexistente en Livewire. Por estatuto técnico-operativo, ningún motor de recetas, inyección de BOM o simulación de Food Cost puede activarse masivamente hasta que el POS Link esté habilitado en producción. Todo avance debe enfocarse en cargar catálogos crudos (D0-D2).
