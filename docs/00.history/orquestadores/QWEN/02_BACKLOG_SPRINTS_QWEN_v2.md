# BACKLOG SPRINTS v2 - QWEN

## Criterios de Aceptación Generales

- Todo código debe tener tests asociados
- Documentación debe actualizarse antes de merge
- Validar consistencia con BD antes de implementación
- Seguir convenciones de nombres y estructura
- Cada módulo debe mantener independencia funcional
- Actualizar documentación en docs/V4.0/<modulo>/ al completar tareas

## Sprint 1 – CRÍTICOS

**REC-001 - Recetas (reescritura completa)**  
- Completar UI de versiones múltiples  
- Implementar publicación de versiones  
- Crear historial de cambios  
- Resultado esperado: Sistema de versionado funcional completo  
- Prioridad: Crítica  
- Dependencias: Items  
- Documentos a actualizar: docs/V4.0/Recetas/README.md  

**PROD-001 - Producción (reescritura completa)**  
- Implementar UI operativa de producción  
- Crear panel de control  
- Integrar con movimientos de inventario  
- Resultado esperado: UI operativa de producción funcional  
- Prioridad: Crítica  
- Dependencias: Recetas, Items  
- Documentos a actualizar: docs/V4.0/Produccion/README.md  

**VEN-001 - Ventas (crear módulo)**  
- Crear dashboard de análisis de ventas  
- Implementar UI de tickets  
- Crear reportes de productos vendidos  
- Resultado esperado: Módulo de ventas funcional  
- Prioridad: Crítica  
- Dependencias: POS, Tickets  
- Documentos a actualizar: docs/V4.0/Reports/README.md  

**SEG-001 - Seguridad (crear módulo)**  
- Crear UI de gestión de permisos  
- Crear UI de gestión de roles  
- Implementar auditoría de acciones  
- Resultado esperado: Sistema de seguridad completo  
- Prioridad: Crítica  
- Dependencias: Usuarios  
- Documentos a actualizar: docs/V4.0/Seguridad/README.md  

**BD-001 - BaseDatos (crear módulo)**  
- Completar documentación de vistas  
- Completar documentación de funciones  
- Crear guía de consultas comunes  
- Resultado esperado: Documentación completa de BD  
- Prioridad: Crítica  
- Dependencias: -  
- Documentos a actualizar: docs/V4.0/BD/README.md  

**POS-001 - POS (sincronización + reprocesamiento)**  
- Registrar rutas API POS  
- Implementar UI de reprocesamiento  
- Crear funcionalidad de validación  
- Resultado esperado: Funcionalidad POS completa  
- Prioridad: Crítica  
- Dependencias: Recetas, Tickets  
- Documentos a actualizar: docs/V4.0/POS/README.md  

## Sprint 2 – ALTA PRIORIDAD

**INV-001 - Inventory (flujos completos)**  
- Completar flujo de recepciones: BORRADOR → VALIDADA → POSTEADA  
- Completar flujo de transferencias: SOLICITADA → DESPACHADA → RECIBIDA  
- Implementar validaciones y tolerancias  
- Resultado esperado: Flujos completos de inventario  
- Prioridad: Alta  
- Dependencias: Items, Proveedores  
- Documentos a actualizar: docs/V4.0/Inventario/Recepciones.md, docs/V4.0/Inventario/Transferencias.md  

**INV-002 - Inventory (FEFO, ajustes)**  
- Implementar FEFO en conteos  
- Crear UI de ajustes  
- Documentar proceso de mermas  
- Resultado esperado: Control preciso de inventario  
- Prioridad: Alta  
- Dependencias: Lotes, Movimientos  
- Documentos a actualizar: docs/V4.0/Inventario/Mermas.md  

**COM-001 - Purchasing (fase 2)**  
- Desarrollar dashboard de sugerencias  
- Implementar motor de replenishment  
- Crear UI de cotizaciones  
- Resultado esperado: Módulo de compras completo  
- Prioridad: Alta  
- Dependencias: Inventario, Recetas  
- Documentos a actualizar: docs/V4.0/Purchasing/README.md  

## Sprint 3 – MEDIA PRIORIDAD

**GUI-001 - GUI (mejoras de interfaz)**  
- Mejorar consistencia visual  
- Implementar validación en línea  
- Crear componentes reutilizables  
- Resultado esperado: UI más consistente y usable  
- Prioridad: Media  
- Dependencias: Frontend  
- Documentos a actualizar: docs/V4.0/Frontend/Componentes.md  

**UX-001 - UX (mejoras de experiencia)**  
- Mejorar flujo de conteos físicos  
- Optimizar formularios principales  
- Implementar feedback visual  
- Resultado esperado: UX más intuitiva  
- Prioridad: Media  
- Dependencias: UI  
- Documentos a actualizar: docs/V4.0/Frontend/Layout.md  

**REP-001 - Reports (dashboards)**  
- Completar UI de KPIs  
- Implementar exportaciones CSV/PDF  
- Crear dashboards personalizables  
- Resultado esperado: Sistema de reportes completo  
- Prioridad: Media  
- Dependencias: Datos, KPIs  
- Documentos a actualizar: docs/V4.0/Reports/README.md  

**MOB-001 - Mobile (funcionalidades)**  
- Adaptar UI para dispositivos móviles  
- Implementar escaneo de códigos  
- Optimizar para operaciones rápidas  
- Resultado esperado: Versión móvil funcional  
- Prioridad: Media  
- Dependencias: UI, Conteos  
- Documentos a actualizar: docs/V4.0/Frontend/Componentes.md  

## Sprint 4 – MEJORAS

**NOT-001 - Notificaciones**  
- Implementar sistema de alertas  
- Crear notificaciones por email  
- Configurar umbrales  
- Resultado esperado: Sistema de notificaciones funcional  
- Prioridad: Baja  
- Dependencias: Permisos  
- Documentos a actualizar: docs/V4.0/Seguridad/README.md  

**REC-002 - Recetas Shadow → Validación UI**  
- Crear UI para validar recetas inferidas  
- Implementar proceso de validación  
- Documentar workflow  
- Resultado esperado: Validación de recetas POS  
- Prioridad: Baja  
- Dependencias: Recetas, POS  
- Documentos a actualizar: docs/V4.0/Recetas/README.md  

**MER-001 - Mermas/Ajustes UI**  
- Crear funcionalidad de ajustes ágiles  
- Implementar UI de mermas  
- Documentar proceso  
- Resultado esperado: Control de mermas eficiente  
- Prioridad: Baja  
- Dependencias: Producción  
- Documentos a actualizar: docs/V4.0/Inventario/Mermas.md