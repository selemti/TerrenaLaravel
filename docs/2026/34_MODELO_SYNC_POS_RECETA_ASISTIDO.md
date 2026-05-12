# 34_MODELO_SYNC_POS_RECETA_ASISTIDO

Este documento redefine la estrategia de integración operativa entre Floreant POS y el módulo de recetas del ERP para la Fase 2, migrando de un entorno de acoplamiento "ciego" (100% automático) hacia un enfoque de **Vinculación Asistida y Modular**, otorgando al Chef o gerente de alimentos el control sobre qué y cómo se sincroniza.

## 1. Estado Actual del Sync
Actualmente, el comando `php artisan recipes:sync-pos` basa su filosofía en un modelo de **Sincronización Total y Automática** (reflejado en el Doc 20 y 22):
- **Creación Ciega de Cascarones**: Por cada `menu_item` en el POS, el script crea instintivamente un registro físico en `selemti.receta_cab` con un ID canónico y genera la "Versión 1" vacía en `selemti.receta_version`.
- **Modificadores Implícitos**: Si se corre con `--modifiers`, asume que *todo* modificador (`menu_modifier`) necesita ser inventariable y crea recetas sub-placeholder atándolas en `selemti.modificadores_pos`.
- **UI Desvinculada**: `Livewire\Recipes\RecipeEditor` asume que el usuario entrará a editar campos sobre recetas que *ya fueron inyectadas* por el sistema en segundo plano.

## 2. Riesgos del Automatismo Total
Esta arquitectura introducía deudas estructurales antes del paso a producción:
1. **Contaminación de Cascarones (Dirty DB)**: No todos los botones de venta del POS necesitan una receta (ej. "Envase extra", "Servicio a Domicilio", "Retail/Abarrotes"). La BD de recetas se llenaría de basura.
2. **Historial Basura**: Crear automáticamente la v1 vacía ensucia la traza de versiones. Una receta no debería versionarse hasta que el Chef defina sus ingredientes.
3. **Plosión Falsa de Modificadores**: Muchos modificadores son instrucciones de servicio (ej. "Sin Sal", "En dos platos") y no requieren una sub-receta.
4. **Pérdida de Soberanía Culinaria**: Obliga al ERP a moldear su estructura de despache (BOM) rígidamente igual a la grilla de venta y clics del mesero en Floreant.

## 3. Modelo Propuesto: Sync Estructural + Vinculación Asistida
Se establece un puente bi-fase separando la *disponibilidad de datos* de la *operación*:

**Fase A: Sync Estructural Automático (Lectura y Cache)**
- El comando de sync o las consultas asumen solo **lectura**. Tráe a memoria (o a tablas temporales/vistas) el catálogo del POS (`menu_item`, `menu_modifier`, `menu_group`) para que el ERP sepa qué se vende, pero **SIN** alterar `receta_cab` ni `receta_version`.
- El comando se usaría exclusivamente para alinear nombres y actualizar precios de los ítems que *ya fueron vinculados*.

**Fase B: Vinculación Operativa Asistida (Humana)**
- Existirá un "Buzón de Sincronización" o "Asistente de Recetario" en la interfaz de usuario.
- El usuario verá los ítems del POS sueltos y decidirá la táctica para cada uno:
  - **Match (Vincular)**: Ligar este ítem del POS a una receta que ya existe en el ERP.
  - **Create (Generar receta)**: Pedirle al sistema crear el "Shell" explícitamente para este ítem.
  - **Ignore (Retail/Servicio)**: Marcar el ítem para que no consuma inventario ni requiera receta.

## 4. Impacto en Documentación Vigente
- **Doc 20 (Protocolo Alineación)**: Se deroga la sección de generación automática ciega de cascarones.
- **Doc 22 (Estrategia de Modificadores)**: Se deroga el punto 5 que ordena ejecutar `sync-pos --modifiers`. Los modificadores ya no se crean como recipes implícitamente, se requiere la acción "Agrupar o vincular modificador" desde la UI.

## 5. Impacto en Comando `SyncPosRecipes`
El comando actual debe ser depreciado o re-arquitecturado radicalmente:
- **No debe ejecutar `DB::table('selemti.receta_cab')->insert()`** masivamente bajo ningún motivo.
- Si se rediseña, su alcance será:
  - Leer el POS.
  - Identificar qué ítems del POS ya tienen un `codigo_plato_pos` mapeado en `receta_cab`.
  - Actualizar únicamente metadatos auxiliares (precio de venta `precio_venta_sugerido`, nombre en el POS para tracking) sobre esos vínculos preexistentes.

## 6. Impacto en UI / Flujo Operativo
Se requiere expandir el ecosistema híbrido actual (Livewire):
1. **Nuevo Módulo "POS Link"**: Un panel tipo lista/bandeja donde recaiga la tabla de ítems de Floreant (`public.menu_item`).
2. **Acciones en RecipeEditor**: Al crear una receta nueva manual, debería existir un selector autocompletado *"Vincular a botón del POS..."* que tome los IDs sueltos que aún no tengan match.
3. El Chef es ahora el verdadero guardián de qué afecta a almacén.

## 7. Dictamen Final
El modelo "Asistido" protege de forma crítica el "Cold Start" evadiendo que la base de datos se inunde de ruido antes de empezar. Técnicamente significa poner en pausa temporal el comando `recipes:sync-pos` actual y priorizar un componente Livewire intermedio de emparejamiento. Este desacoplamiento asíncrono es la respuesta correcta para la escala de la Fase 2 y preserva la soberanía del motor recursivo.
