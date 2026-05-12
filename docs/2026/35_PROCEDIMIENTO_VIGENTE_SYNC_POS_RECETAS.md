# 35 Procedimiento Vigente de Sincronización POS-Recetas (Asistido)

Este documento funciona como la fuente única de verdad para el proceso de sincronización entre Floreant POS y el sistema de Recetas (Fase 2), depreciando formalmente cualquier modelo de automatización ciega previamente documentado.

## 1. Qué se hacía antes (Modelo Deprecado)
Bajo el modelo inicial (ahora derogado):
- **Sync ciego**: El comando inyectaba cascarones (`receta_cab`) en la base de datos para *todo* registro que existiera en el botón de ventas de Floreant.
- **Creación masiva de shells**: Creaba la "Versión 1" vacía en `receta_version` de forma sistémica e indiscriminada.
- **Creación automática de modificadores**: Asumía que todos los modificadores (ej. "Con hielo", "Para llevar") requerían sub-recetas inventariables, insertándolos también.

## 2. Por qué ya no se debe hacer
La auditoría funcional determinó que ese esquema es altamente peligroso para la Fase 2 debido a:
- **Contaminación de BD (Ruido Operativo)**: Multiplicaba las recetas generando falsos catálogos de platos por botones de ventas que son puramente servicios o textos adicionales en tickets (misceláneos).
- **Ruido en `receta_version`**: Rompía el historial cronológico y control de soberanía, forzando la Versión 1 sin validación humana.
- **Pérdida de Soberanía Culinaria**: Obligaba al modelo de ERP a adaptarse a una grilla de meseros, perdiendo la estructura de sub-recetas (BOM) organizadas por producción en cocina central.

## 3. Qué se hace ahora (Modelo Estructural Asistido)
El nuevo paradigma le devuelve el control al Chef Ejecutivo o encargado de Alimentos y Bebidas:
- **Sync estructural de sólo lectura**: La base de datos ERP asume que existe la data del POS, pero solo la observa para mantener un catálogo referencial temporal si la requiere.
- **Vínculo humano asistido**: La inserción en el costeo es estrictamente intencional. El usuario elige qué ítem del POS amerita de verdad conectarse al despache y descargo de inventarios.
- **Creación explícita de receta**: Ninguna receta (ni versión, ni sub-receta) se crea en el ERP sin decisión humana y validación operativa. 

## 4. Nuevo flujo operativo
Si deseas estructurar correctamente la alineación POS -> ERP, sigue estos pasos:
1. **Leer el POS**: El sistema carga la estructura de ítems y modificadores en memoria al abrir el panel o de forma temporal.
2. **Identificar pendientes**: Una vista UI listará los productos que residen en Floreant POS y que "aún no han sido catalogados en el ERP".
3. **Decidir el destino (Vincular / Crear / Ignorar)**:
   - *Vincular*: Ligar el ítem del POS a una receta que el Chef ya formuló en el editor.
   - *Crear*: Solicitar que a partir del ítem del POS sí se emita un cascarón nuevo de forma voluntaria.
   - *Ignorar*: Botón de "Servicio" que desaparece de los pendientes sin interactuar jamás con la despensa.
4. **Carga de Modificadores**: Una vez ligada la receta principal, se procesarán los modificadores bajo la misma óptica.

## 5. Qué comandos/procedimientos quedan vigentes
El arsenal de comandos del sistema se vio alterado:
- **`php artisan recipes:sync-pos` sigue existiendo**.
- **Nuevo Propósito**: Opera exclusivamente para *Actualizar Metadatos (Precios o Categorías)* de los ítems o modificadores que el Chef YA unió manualmente. Sirve para que si Floreant sube un platillo de $50 a $60, el ERP lo sepa para medir Food Cost.
- **Parámetros Deprecados**: La bandera `--modifiers` ya no dispara inserción de subrecetas ("placeholders"). Apenas sirve para diagnosticar/re-calcular precios de modificadores operables.
- **Procedimientos Derogados**: La ejecución ciega descrita en el *Paso 1* del Doc 20 queda terminantemente erradicada de TerrenaLaravel. Todo manual que exija dicho paso como requisito asume carga asistida desde la UI.
