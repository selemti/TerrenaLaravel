# Estado de Implementación - Roadmap Financiero 2026

## Fase actual: Fase 1 - Saneamiento de Ingresos (SSOT)
**Estado:** Etapa B (Switch-over Progresivo) en progreso.

---

### Registro de Bitácora (Abril 2026)

#### [2026-04-13] Ejecución Paso 4.1 y 4.2A - COMPLETADO
Se ha intervenido la capa de lectura y reporting para habilitar el **Modo Canon (SSOT)** de forma reversible.

**Componentes Actualizados:**
1.  **[CORE] `ConfiguresReportConnection.php`**: Implementado flag `isCanonMode`. El método `getTicketNetAmount()` ahora resuelve el neto vía subquery a `public.transactions` cuando el modo está activo.
2.  **[ADMIN] `SalesSummaryController.php`**: El campo `neto` de la consulta principal ahora es dinámico. Si `?mode=canon`, el valor coincide con los pagos liquidados (`pagos_netos`), resolviendo visualmente el BUG-04.
3.  **[AUDIT] `SalesExceptionsReportService.php`**: Las excepciones de discrepancia de pago (`payment_mismatch`) ahora se validan contra el neto canónico, eliminando falsos positivos.
4.  **[KPI] `ProductsReportService.php`**: Se eliminó el parche de exclusión manual de tickets al 100%. Los totales de Jasper ahora se calculan dinámicamente comparando Legacy vs SSOT.

**Mecanismo de Verificación:**
- Se puede alternar entre vistas agregando `?mode=canon` a la URL en los módulos afectados.
- Configuración global disponible en `config/finance.php` (pendiente creación de archivo de config, se usa fallback `false`).

**Siguiente Paso:**
- Etapa C: Validación de paridad masiva y Decomisionamiento de columnas legacy.

#### [2026-04-14] Ejecución Etapa B.3: Operación (4.2B) - COMPLETADO
Se han migrado los controladores operativos para usar el flujo canónico. Ver [16_REPORTE_VALIDACION_OPERATIVA.md](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/16_REPORTE_VALIDACION_OPERATIVA.md) para dictamen técnico.

**Controladores Actualizados:**
1.  **[API] `CajaController.php`**: Las excepciones de caja (anulaciones/descuentos) ahora resuelven su monto real vía SSOT. Se saneó el detalle de tickets para mostrar netos canónicos.
2.  **[ADMIN] `TicketManagementController.php`**: La detección automática de tickets con descuento 100% ahora utiliza `SalesResolutionService`, garantizando cierres precisos incluso con el BUG-04 presente.

**Estado Global:**
### 🟢 FASE 1: Finanzas y Saneamiento
**Estado:** ✅ **CERTIFICADA**
- SSOT Financiero consolidado (`transactions`).
- Saneamiento de Descuentos y Cierres de Caja.
- Modo Canon operativo.

### 🟡 FASE 2: Inventarios y Logística
**Estado:** 🛠️ **NO INICIADA OPERATIVAMENTE**
> [!CAUTION]
> **El ecosistema de Recetas (D3) NO es operable sin el módulo POS Link.** La carga operativa está bloqueada estratégicamente en este punto (Doc 36). Las fases iniciales D0-D2 (UOM, catálogos e inventario base) **sí están liberadas para avanzar independientemente**.

- **Arquitectura:** ❌ **NO CONSOLIDADA** (Detectada fragmentación en Auditoría 360°).
- **Motor Recursivo (Doc 24):** 🟡 Prototipo Avanzado.
- **Sincronización POS:** 🟢 Re-arquitectura aprobada: **Transición a Modelo Asistido** finalizada (Comando ciego deprecado, ver Doc 35).
- **Población de Datos:** 🛠️ **DISEÑO COMPLETADO** (Listo para Secuencia D0-D1-D2-D3).

**Hitos Alcanzados:**
1.  **[CORE] `fn_expandir_consumo_ticket` (v2.5)**: Implementada lógica recursiva. (Prototipo).
2.  **[DATA] MAD (Minimum Auditable Dataset)**: Diseño y plantillas completadas.
3.  **[GOV] Gobierno Fase 2**: Creado el [README de Ejecución](00_README_EJECUCION_FASE_2.md) (Abril 14, 2026).

> [!WARNING]
> No se permite la carga operativa de datos ni el procesamiento de inventarios hasta que se consolide la **Soberanía del Modelo** y se ejecute el **Protocolo de Purga (Doc 29)**.

**Siguiente Paso:**
- **Saneamiento Arquitectónico**: Unificar modelos `Inv\Item` y `Item` raíz.
- **Protocolo de Purga**: Ejecución del Doc 29.
- **Carga Secuencial**: Iniciar con UOMs y Almacenes.
