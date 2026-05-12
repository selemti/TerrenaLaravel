# 17 Cierre Formal: Fase 1 - Saneamiento de Ingresos (SSOT)

Este documento clausura la Fase 1 del Roadmap Financiero 2026, certificando la implementación de la Fuente Única de Verdad (SSOT) para el dominio de ingresos en TerrenaLaravel.

## 1. Objetivos Alcanzados
- **SSOT Consolidado**: `public.transactions` es ahora la autoridad contable para la liquidación neta.
- **Saneamiento BUG-04**: Se implementó una lógica de normalización que elimina el truncamiento de descuentos analíticos.
- **Switch-over Controlado**: Capa de lectura (Reportes) y Operación (Caja/Admin) migradas exitosamente al Modo Canon.
- **Reversibilidad**: Se mantiene un toggle activo vía `config/finance.php` y `?mode=canon`.

---

## 2. Componentes Intervenidos
- **Core Strategy**: `SalesResolutionService.php`.
- **Trait Base**: `ConfiguresReportConnection.php`.
- **Reporting**: `SalesSummaryController`, `SalesExceptionsReportService`, `ProductsReportService`.
- **Operación**: `CajaController`, `TicketManagementController`.

---

## 3. Riesgos Mitigados
- **Integridad Monetaria**: Se eliminó la dependencia de la aritmética PHP/SQL ad-hoc (`total_price - total_discount`).
- **Falsos Positivos**: Las excepciones de discrepancia de pago ahora coinciden con la realidad de caja.
- **Continuidad**: No se alteraron flujos del POS ni el esquema de la base de datos (Inmutabilidad del dato histórico).

---

## 4. Pendientes y Restricciones (Fase 1)
- **NO DECOMISIONAR**: Las columnas legacy (`total_discount`, etc.) deben permanecer hasta el fin del periodo de monitoreo.
- **MONITOREO**: Vigilancia activa de tickets de cortesía 100% y cierres de caja (24-48h).
- **CONEXIÓN POSTCORTE**: `fn_generar_postcorte` permanece intacta; su intervención queda reservada para fases futuras.

---

## 5. Dictamen Final
La Fase 1 se declara **CERRADA PARA EJECUCIÓN**. El sistema es ahora financieramente confiable respecto a los ingresos liquidados. 

**Hito Siguiente (Finalizado):** [Fase 2 - Modelo de Inventarios y Mermas](file:///C:/Users/Tavo/.gemini/antigravity/brain/36d06524-f153-40a9-93bb-501a88e8e324/walkthrough.md). Ver motor específico en [Doc 24](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md).
