# BACKLOG DE SPRINTS · ORQUESTADOR V2 (CODEX)

## Sprint 1 – “Consolidar Documentación Crítica” (Prioridad 🔴, 2 semanas)
1. **Inventario/Ajustes.md** – describir workflow completo, aprobaciones y tipos (gap FASE3).
2. **Inventario/Reorden.md** – política min/max y alertas (FASE2 y FASE3).
3. **Recetas/BOMImplosion.md** + **Recetas/IntegracionPOS.md** – portar UML v1 (FASE3).
4. **Produccion/Estados.md** – estados SOLICITADA→EN_PROCESO→POSTEADA (FASE3).
5. **POS/Sincronizacion.md** – detallar catálogos ↔ Floreant (FASE3).
6. **Finanzas/CajaChica_Resumen.md** – enlazar docs 98% score (FASE1).

## Sprint 2 – “Correcciones técnicas prioritarias” (Prioridad 🔴/🟡, 2 semanas)
1. **Documentar consolidación de servicios duplicados** (FASE4): PosConsumptionService, ProductionService, modelos Caja, PurchaseRequest.
2. **Catálogo de tablas legacy en `_reference`** (FASE5: 8 tablas legacy + 3 backup).
3. **Reporte de funciones críticas sin doc** (25 funciones según FASE5) → anexar a `Arquitectura/DevOps.md`.
4. **Actualizar `Reports/README.md`** con catálogo v9 + equivalencias Jasper (FASE3).
5. **Seguridad/Roles.md** y **Seguridad/AuditLog.md** (FASE3 + FASE4 hallazgo audit_log sin doc).

## Sprint 3 – “UX Remediation” (Prioridad 🔴 UX, 1 semana)
1. Definir patrón único de **loading states Livewire** (FASE6 §1.1).
2. Crear componente **notify/toast** reutilizable + migración masiva (FASE6 §1.2).
3. Implementar **confirmaciones de delete** (FASE6 §1.3) y documentar en `Frontend/DesignSystem.md`.
4. Añadir guía de mensajes y estados en `Frontend/DesignSystem.md`.

## Sprint 4 – “Alianza Código/BD” (Prioridad 🟡, 2 semanas)
1. Documentar 26 migraciones faltantes en historial (FASE4 + FASE5).
2. Agregar sección `Arquitectura/Diagramas.md` (ERD + deployment).
3. Registrar triggers y vistas críticas (`mov_inv`, `inventory_wastes`, `pos_map`) con referencias cruzadas (FASE5).
4. Preparar informe de reducción de código huérfano (<10%) con evidencias antes/después.

Todos los sprints dependen de actualizar `docs/V4.0/README.md` para reflejar cada nueva ficha (sin crear módulos nuevos).
