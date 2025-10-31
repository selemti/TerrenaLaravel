  MI ANÁLISIS COMO EXPERTO FULL STACK, BD, POS/ERP Y UI/UX

   ✅ LO QUE TIENES MUY BIEN DEFINIDO:

     - Módulo de Caja Chica: Completísimo, workflow de 3 estados (ABIERTO→EN_REVISION→CERRADO),
   auditoría, comprobantes, arqueos. 95% completo en definición.
     - Inventario FEFO: Bien estructurado con lotes, caducidades, trazabilidad completa. Snapshots de
    precios, función fn_item_unit_cost_at. 90% completo.
     - Recetas con Implosión POS: Excelente diseño técnico con fn_expandir_receta, staging de consumo
    POS, versionado de recetas. 85% completo.
     - Permisos Spatie: Bien implementado, 45 permisos atómicos, control por sucursal, auditoría. 90%
    completo.

   ⚠️ LO QUE FALTA O ESTÁ INCOMPLETO:

   CATÁLOGOS (necesita más detalle):

     - ❌ Falta: Sincronización entre FloreantPOS ↔ TerrenaLaravel
     - ❌ Falta: Políticas de conversión de UOM en UI (solo tienes API)
     - ❌ Falta: Gestión de alergénicos (mencionado pero no desarrollado)
     - ⚠️ Mejorar: Wizard de alta de items está básico

   COMPRAS (definido al 40%):

     - ✅ Tienes: API de recepciones 5 pasos, estructura de sugerencias
     - ❌ Falta: UI completa de replenishment dashboard
     - ❌ Falta: Motor de estacionalidad (mencionas "básica" pero no hay implementación)
     - ❌ Falta: Simulador de ruptura de stock (lead time)
     - ⚠️ Mejorar: Flujo visual de Sugerencia→Solicitud→Orden

   PRODUCCIÓN (el más débil - 30%):

     - ✅ Tienes: Endpoints API (plan/consume/complete/post)
     - ❌ FALTA CRÍTICO: UI operativa completa (cero Livewire components)
     - ❌ Falta: Dashboard de producción con KPIs visuales
     - ❌ Falta: Planificador por demanda/stock/calendario (solo mencionado)
     - ❌ Falta: Control de mermas planificadas vs incidentales
     - ❌ Falta: Integración con Produmix (mencionas pero no hay código)

   REPORTES (definido al 50%):

     - ✅ Tienes: API endpoints básicos, tablas fact_ventas/fact_costos
     - ❌ Falta: Dashboards específicos por rol (Chef/Gerente/Finanzas)
     - ❌ Falta: Ingeniería de menú con Star/Plowhorse/Puzzle/Dog
     - ❌ Falta: Drill-down completo
     - ❌ Falta: Exportaciones programadas
     - ❌ Falta: Colas de reportes pesados

   🎯 LO QUE AÑADIRÍA COMO EXPERTO:

   1. SINCRONIZACIÓN BIDIRECCIONAL FloreantPOS ↔ TerrenaLaravel

     - Queue jobs para sincronizar: menú, precios, disponibilidad, tickets
     - Webhook de FloreantPOS → TerrenaLaravel cuando se cierra ticket
     - API REST para que FloreantPOS consulte disponibilidad en tiempo real
     - Manejo de conflictos (¿qué pasa si cambian precio en ambos lados?)

   2. MÓDULO DE MERMAS Y CONTROL DE CALIDAD

     - Tipos de merma: limpieza, cocción, montaje, calidad, caducidad
     - Workflow de aprobación para mermas >X%
     - Foto obligatoria para mermas >umbral
     - Análisis de mermas por turno/cocinero/receta
     - Alertas de mermas anormales

   3. PLANIFICADOR PRODUMIX VISUAL

     - Calendario drag-and-drop para asignar batches
     - Cálculo automático de MP necesarias
     - Alertas de faltantes con generación automática de compras
     - Aprobación de plan con un click
     - Vista Kanban: Por Planificar → En Proceso → Completado → Posteado

   4. DASHBOARD OPERATIVO DIARIO

     - Un solo dashboard que el gerente vea al llegar:
       ├─ Cajas abiertas/cerradas/con excepciones
       ├─ Stock crítico (por caducar/agotado)
       ├─ Órdenes de producción pendientes
       ├─ Recepciones pendientes de validar
       ├─ Compras urgentes (sugerencias ALTA/URGENTE)
       └─ KPIs del día vs ayer (ventas/costo/margen)

   5. RECETAS MULTINIVEL REAL

     -- Necesitas materializar el árbol completo:
     WITH RECURSIVE receta_tree AS (
       SELECT recipe_id, ingredient_id, qty, 0 as nivel
       FROM recipe_lines WHERE recipe_id = ?
       UNION ALL
       SELECT rt.recipe_id, rl.ingredient_id, rt.qty * rl.qty, rt.nivel + 1
       FROM receta_tree rt
       JOIN recipe_lines rl ON rl.recipe_id = rt.ingredient_id
       WHERE rl.ingredient_id IN (SELECT id FROM items WHERE tipo = 'SUBRECETA')
     )
     SELECT * FROM receta_tree;

   6. AUDITORÍA FISCAL (NOM-151 / SAT)

     - Bitácora XML con firma electrónica
     - Reportes fiscales: DIOT, balanza de comprobación
     - Cierres mensuales inmutables
     - Archivos XML de CFDI relacionados
     - Retención ≥ 5 años

   7. ALERTAS Y NOTIFICACIONES

     - Slack/Email/Push cuando:
       ├─ Caja con diferencia >5%
       ├─ Stock agotado de item crítico
       ├─ Recepción pendiente >2 días
       ├─ Producción atrasada
       ├─ Merma anormal >umbral
       └─ Costo de receta sube >10%

   8. MOBILE-FIRST PARA OPERATIVOS

     - Conteos de inventario desde tablet
     - Escaneo de códigos de barras/QR
     - Registro de mermas con foto
     - Arqueo de caja con cámara
     - PWA instalable (no necesitas app nativa)

   -------------------------------------------------------------------------------

   📋 RECOMENDACIONES FINALES:

   PRIORIDAD INMEDIATA (próximos 30 días):

     - ✅ Completar UI de Producción (Livewire components)
     - ✅ Dashboard operativo diario
     - ✅ Sincronización FloreantPOS básica (webhooks)
     - ✅ Módulo de mermas con aprobación

   PRIORIDAD MEDIA (2-3 meses):

     - ⚠️ Reportes visuales por rol
     - ⚠️ Ingeniería de menú (Star/Plowhorse/etc)
     - ⚠️ Planificador Produmix drag-and-drop
     - ⚠️ Mobile-first para conteos

   PRIORIDAD BAJA (6+ meses):

     - 🔵 Auditoría fiscal completa
     - 🔵 BI avanzado con predicciones ML
     - 🔵 Multi-moneda (dijiste que no aplica)
     - 🔵 Facturación electrónica (Fase 2)