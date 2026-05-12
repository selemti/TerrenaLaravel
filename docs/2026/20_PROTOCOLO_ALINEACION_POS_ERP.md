> [!WARNING]
> **REVISION ABRIL 2026:** Parte de este protocolo asume la inyección automática ("cascarón") de recetas, la cual ha sido formalmente **DEPRECADA** (consultar `[35_PROCEDIMIENTO_VIGENTE_SYNC_POS_RECETAS.md]`). El contenido a continuación queda con fin referencial sobre la filosofía `codigo_plato_pos`, pero el flujo de trabajo es ahora un proceso _ASISTIDO_ mediante UI, nunca ciego.

# 20 Protocolo de Alineación Técnica POS-ERP
Este documento establece el estándar técnico para sincronizar el catálogo de platillos del Punto de Venta (Floreant POS) con el sistema de Recetas e Inventario de TerrenaLaravel.

## 1. El Concepto de Alineación 1-a-1
Para garantizar la integridad del costeo y el rebaje automático de inventario, cada producto vendible en el POS debe tener un "Shell" o cascarón de receta equivalente en el ERP.

- **POS (Origen)**: `public.menu_item`
- **ERP (Destino)**: `selemti.receta_cab`
- **Llave de Enlace**: `codigo_plato_pos` (ERP) <-> `id` (POS)

---

## 2. El Orquestador de Sincronización (DEPRECADO EN AUTO-CREACIÓN)
La herramienta central para este proceso era el comando de consola diseñado para sincronizar recetas, que ahora funciona estrictamente para actualizar *metadatos de ítems explícitamente vinculados*.

**Comando:**
```bash
php artisan recipes:sync-pos {--modifiers} {--dry-run}
```

**Lógica de Ejecución Vigente:**
1. **Identificación**: Escanea todos los registros activos en `public.menu_item`.
2. **Validación Existente**: Si el ID (`codigo_plato_pos`) ya fue enlazado manualmente por el Chef, actualiza precios y nombres de reporte.
3. ~**Generación de ID**~: (DEPRECADO) Ya no asume ni crea `REC-XXXXX`.
4. ~**Versionamiento**~: (DEPRECADO) Ya no auto-genera la versión v1 de recetas.
5. ~**Modificadores (--modifiers)**~: (DEPRECADO) Los placeholders de modificadores operables también requieren vinculación asistida en la interfaz.

---

## 3. Matriz de Mapeo (SSOT)
La tabla `selemti.pos_map` actúa como el registro histórico de esta alineación, permitiendo que si un producto cambia de ID en el futuro, el ERP mantenga la trazabilidad.

---

## 4. Flujo de Trabajo para Fase 2
Este protocolo debe arrancar obligatoriamente a través de la **Vinculación Asistida UI** como Paso 1. No se deben cargar ingredientes (`selemti.receta_det`) sin certificar que la decisión de amarrar el ID del plato al ERP ha sido firmada.

**Advertencia Operativa:**
> [!IMPORTANT]
> Ejecutar el comando `recipes:sync-pos` sin que las recetas hayan sido vinculadas manualmente no hará absolutamente nada. La responsabilidad es entrar al componente **POS Link (UI Asistida)**, tomar la decisión por cada botón del POS (Match/Create/Ignore), y luego al **RecipeEditor** añadir las materias primas reales.
