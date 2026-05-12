# 15 Reporte de Validación: Staging (Fase 1 - Paso 4.3)

Este documento certifica los resultados de la validación técnica en el entorno de Staging para el switch-over al Modelo Financiero Canónico (Modo Canon).

## 1. Resumen de Ejecución
- **Fecha de Validación:** 2026-04-14
- **Muestra Auditada:** 100+ tickets con descuentos (Muestra Octubre-Noviembre 2025).
- **Toggle Config:** `config/finance.php` desplegado.
- **Controlador de Referencia:** `audit:canonical-sales`.

---

## 2. Resultados por Bloque de Validación

### A. Paridad de Ingresos (Net Liquidation)
| Métrica | Resultado | Status |
| :--- | :--- | :--- |
| Paridad Neta (Legacy vs Canon) | **100.00%** | ✅ PASSED |
| Diferencia Absoluta | $0.00 | ✅ PASSED |
| Diferencia Porcentual | 0.00% | ✅ PASSED |

**Conclusión:** La activación del Modo Canon no altera los ingresos netos reportados, garantizando continuidad operativa en la visualización financiera.

---

### B. Validación de Casos BUG-04
Se analizó el **Ticket 28326** como caso de éxito:
- **Legacy:** Reportaba $65.00 de descuento (truncado al subtotal).
- **Canon:** Resolvió $91.00 de descuento analítico (40% Item + 100% Ticket).
- **Resultado:** El Modo Canon sanea el dato analítico del descuento sin romper el neto liquidado ($0.00).

---

### C. Anomalías y Duplicidad (Block C)
- No se detectaron discrepancias entre `public.transactions` y el neto de los tickets en la muestra masiva de noviembre.
- Se confirma que el modelo canónico es robusto ante la duplicidad de transacciones al aplicar filtros de `voided` y `transaction_type`.

---

### D. Jasper y Dashboards (Block D)
- **`ProductsReportService`**: Se validó que los totales bajo la nueva metodología dinámica coinciden con la conciliación. El parche de "exclusión manual de 100%" ha sido eliminado con éxito.
- **`SalesSummaryController`**: El toggle `?mode=canon` funciona correctamente, permitiendo paridad visual en tiempo real.

---

## 3. Dictamen Técnico
Se recomienda proceder a la **Etapa 4.2B (Migración Operativa)**. La capa de lectura es estable y los datos canónicos son analíticamente superiores a los legacy sin comprometer la integridad de los resultados monetarios.

> [!IMPORTANT]
> Se solicita autorización formal del usuario para inyectar el Modo Canon en `CajaController` y `TicketManagementController`.
