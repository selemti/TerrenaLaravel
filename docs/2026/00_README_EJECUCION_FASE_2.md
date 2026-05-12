# ⚠️ LECTURA OBLIGATORIA: Protocolo de Ejecución Fase 2 (Inventarios 2026)

Este documento es la **Soberanía de Decisión** para la Fase 2 del proyecto TerrenaLaravel. Cualquier ejecución fuera de este orden o ignorando estas advertencias resultará en corrupción de integridad de datos e inconsistencias financieras.

## 1. Orden Real de Ejecución (Secuencia Crítica)

Para evitar duplicidad de IDs, desalineación con el POS o errores en el Food Cost, se DEBE seguir este orden estrictamente:

1.  **PURGA (Doc 29)**: Limpieza total de tablas `items`, `item_categories` y maestros relacionados. El sistema debe estar en *Cold Start*.
2.  **CARGA DE MAESTROS (Doc 28)**: 
    - D0: UOM, Conversiones y Almacenes.
    - D1: Insumos Genéricos (Items) y Categorías oficiales.
    - D2: Presentaciones de Compra y Proveedores (Desacoplamiento).
3.  **VALIDACIÓN (Doc 30)**: Auditoría post-carga para certificar que el catálogo maestro es íntegro.
4.  **CONSOLIDACIÓN ARQUITECTÓNICA**: Refactorización de Modelos y Servicios para eliminar la "Arquitectura de Sombra" (según Informe de Auditoría).
5.  **VINCULACIÓN POS LINK**: Vinculación asistida (manual) de recetas y modificadores desde el POS hacia el ERP (basado en el catálogo ya cargado).
6.  **ACTIVACIÓN DEL MOTOR (Doc 24)**: Inicio del rebaje de inventario y cálculo de Food Cost recursivo.

---

## 2. Jerarquía de Documentación

### Nivel 1: Gobierno y Estado (Decisión)
*   **[STATUS.md](../STATUS.md)**: El termómetro del proyecto. Si un módulo no está en "Verificado", no se usa.
*   **[Este README](00_README_EJECUCION_FASE_2.md)**: El mapa de navegación obligatorio.

### Nivel 2: Operación y Carga (Ejecución)
*   **[Doc 26: Dataset Mínimo](26_DATASET_MINIMO_FASE_2.md)**: El "Qué" vamos a cargar.
*   **[Doc 27: Plantillas de Carga](27_PLANTILLAS_CARGA_FASE_2.md)**: El format operativo.
*   **[Doc 28: Carga Inicial](28_CARGA_INICIAL_UOM_Y_ALMACENES.md)**: El proceso de inyección.
*   **[Doc 29: Protocolo de Purga](29_PROTOCOLO_PURGA_DATOS_PRUEBA.md)**: El botón de reset previo.
*   **[Doc 30: Checklist de Validación](30_CHECKLIST_VALIDACION_POST_CARGA.md)**: El certificado de calidad.

### Nivel 3: Referencias e Histórico
*   Planes de implementación anteriores, auditorías sistémicas y minutas.

---

## 3. Lo que NO se debe hacer (Restricciones)

*   **❌ NO cargar insumos** sin antes haber limpiado las tablas (ver Doc 29).
*   **❌ NO procesar tickets** (Motor de Consumo) hasta que la Carga Inicial y la vinculación POS Link estén certificados.
*   **❌ NO crear nuevos insumos** directamente en la BD sin pasar por el flujo de "Insumo Genérico" vs "Presentación".
*   **❌ NO ignorar el STATUS.md**: Si la Fase 2 no está marcada como "Iniciada Operativamente", cualquier dato en el sistema se considera "de prueba".

## 4. Relación con STATUS.md
Este README define la **estrategia**, mientras que `STATUS.md` refleja la **táctica** (el avance porcentual real). Antes de cualquier paso de Nivel 2, se debe verificar en `STATUS.md` que la pre-condición necesaria esté cumplida.

---
**Director de Proyecto**: Gustavo Selem
**Arquitecto de Datos**: Antigravity AI
