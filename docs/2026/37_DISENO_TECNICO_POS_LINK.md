# 37 Diseño Técnico de "POS Link"

El módulo "POS Link" es la barrera arquitectónica (Gate Operativo) que regula el ingreso de ítems del Punto de Venta (Floreant) hacia el motor de inventarios y recetas (TerrenaLaravel), reemplazando el proceso de sincronización ciega mediante un modelo de "Vinculación Asistida".

## 1. Objetivo del Módulo
Otorgar una interfaz centralizada al Chef o Analista de Costos para evaluar, clasificar y decidir el destino contable de todos los productos y modificadores creados en el POS, garantizando que el catálogo de recetas (`selemti.receta_cab`) se mantenga higiénico, intencional y 100% vinculado a operaciones reales.

## 2. Alcance Funcional
**Qué SÍ hace:**
- Mostrar ítems y modificadores del POS que carecen de vínculo operativo (Bandeja de Pendientes).
- Permitir la vinculación a recetas ya existentes en el ERP.
- Solicitar sistemáticamente la creación de recetas nuevas (Shell) para ítems aprobados.
- Permitir clasificar ítems como "No Inventariables" (Retail/Servicio) ocultándolos de la bandeja.

**Qué NO hace:**
- NO crea recetas, versiones ni ingredientes automáticamente al abrir la pantalla.
- NO altera el nombre o receta del ERP si el ítem ya está satisfactoriamente vinculado.
- NO define listas de materiales o cantidades (Costeo/BOM); esa tarea recae en RecipeEditor.

## 3. Flujo Operativo (UX/UI en 3 Vistas)
La interfaz se basará en un sistema de **3 Pestañas (Tabs)**:

### Tab 1: Pendientes POS
Lista plana de `public.menu_item` donde la llave no exista todavía en el mapa ERP.
**Acciones por fila:**
- **[Vincular]**: Abre un buscador/dropdown de `receta_cab` libre (ID y Nombre) -> Graba la llave.
- **[Crear Shell]**: Genera el registro explícito en `receta_cab` (estado borrador) y amarra la llave al POS. **Regla de Creación:** Genera cabecera Y también inserta `receta_version` (versión 1, `version_publicada = false`) para evitar errores en interfaces anidadas.
- **[Ignorar]**: Marca el `menu_item` como retail/servicio registrándolo en la tabla `selemti.pos_exclusion` (dejando trazabilidad total).

### Tab 2: Modificadores Pendientes
Aparece EXCLUSIVAMENTE para grupos de modificadores cuyos Items principales **ya hayan sido vinculados** en el Tab 1.
**Acciones por fila:**
- **[Clasificar como Extra]**: Crea/vincula sub-receta. (Suma al costeo).
- **[Clasificar como Sustitución]**: Crea/vincula. (Resta base, suma variante).
- **[Clasificar como Información]**: Marca como "Sin Costo" (Ej. "Servir Frío"). Se descarta de inventario.

### Tab 3: Mapa POS ↔ ERP (Auditoría)
Vista resolutiva (SSOT Mode).
- Muestra el Catálogo de POS cruzado con `receta_cab`/estado.

## 4. Estados del Vínculo (Tipos de Entidad)
Cada ítem en el módulo residirá en uno de estos estados lógicos:
- `PENDIENTE`: Reside en Floreant POS pero el ERP no sabe qué hacer con él.
- `VINCULADO_RECETA`: Atado a una `receta_cab` real (Mapeo 1:1).
- `OCULTO_IGNORADO`: Atado como *Servicio/Retail*. No aparecerá como pendiente ni se le buscará inventario.
- `PENDIENTE_MOD`: Ítem vinculado, pero sus modificadores base no hand sido clasificados.
- `CONFLICTO`: El código POS de este ítem antes existía pero desapareció de Floreant (Falsa dependencia).

## 5. Arquitectura Técnica Propuesta
- **Front-end**: Componentes Alpine.js y Livewire.
- **SSOT Persistente (Autoridad del Vínculo)**: La llave `codigo_plato_pos` en `selemti.receta_cab` se erige como la FUENTE ÚNICA DE VERDAD estructural (para ítems). La tabla `selemti.pos_map` se preserva **solo** como bitácora transaccional para cruces históricos, pero la decisión de despache nace orgánicamente del catálogo maestro.
- **Soberanía Base**: La lectura original sigue yendo a la conexión PostgreSQL `pos` (`public.menu_item`, `public.menu_group`).
- **Control de Exclusiones**: Se creará la tabla física `selemti.pos_exclusion` con el siguiente esquema mínimo: `id, pos_id, tipo_entidad (menu_item / modifier), motivo, created_at, user_id`. La reactivación es un simple delete físico de este registro.

## 6. Componentes Livewire Propuestos
1. `App\Livewire\PosLink\Dashboard` (Layout principal y contador de pestañas).
2. `App\Livewire\PosLink\PendingItemsTable` (Grilla paginada del Tab 1).
3. `App\Livewire\PosLink\PendingModifiersTable` (Grilla paginada del Tab 2).
4. `App\Livewire\PosLink\AuditMap` (Vista de auditoría continua).

## 7. Servicios y Queries Requeridas
La lógica se abstrae del componente visual hacia un repositorio dedicado para asegurar mantenibilidad.

- **Servicio Base (`PosBindingService`)**: Encargado de traer los pendientes, registrar ignorados y ejecutar vinculación.
- **Cálculo Optimo de Pendientes (`NOT EXISTS`):** En lugar de grandes exclusiones espigadas, se favorece el uso de sub-bloques robustos:
  ```sql
  SELECT mi.id, mi.name 
  FROM public.menu_item mi 
  WHERE NOT EXISTS (
      SELECT 1 FROM selemti.receta_cab WHERE codigo_plato_pos = CAST(mi.id AS VARCHAR)
  ) 
  AND NOT EXISTS (
      SELECT 1 FROM selemti.pos_exclusion WHERE pos_id = mi.id AND tipo_entidad = 'menu_item'
  )
  ```
- **Repositorio Visual**: El componente Livewire solo interacciona usando los resultados de `PosBindingService`.

## 8. Reglas de Validación (Inquebrantables)
- **Bloqueo Duplicados**: Imposible que dos recetas del ERP apunten al mismo `codigo_plato_pos`.
- **Bloqueo de Auto-Gestión**: La acción "Crear Shell explícito" requiere Forzosamente que el operario escriba o confirme la "Categoría de Contabilidad" para evitar creaciones al aire.
- **Blindaje D3 BOM**: RecipeEditor arrojará excepción si un usuario intenta generar BOM (`receta_det`) para una receta sin estado "Publicado" (Versión 1 explícitamente firmada pos-vinculación).

## 9. Riesgos y Decisiones Abiertas
- **Decisión de Ignorados (Ratificada)**: Se ha optado por implementar formalmente `selemti.pos_exclusion`. Esto empodera métricas y permite consultas limpias `NOT EXISTS`, facilitando devolver ítems a la bandeja de pendientes en el futuro.
- **Decisión sobre SSOT (Ratificada)**: `selemti.receta_cab` conserva la autoridad definitiva de vínculo en su campo `codigo_plato_pos`.
- **Rendimiento**: La conexión cruzada es capaz de procesar `<1000` registros directamente, sin generar colisiones ni bloqueos.

## 10. Dictamen Final
El diseño de Pos Link cierra formalmente la brecha operativa permitiendo el control soberano. Este documento técnico está aprobado para iniciar su desarrollo en Livewire tan pronto como concluyan las ejecuciones obligatorias de preparación de catálogos e inventario genérico Fases D0-D2.
