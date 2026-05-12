# 14 Auditoría Técnica: Saneamiento de Ventas y SSOT

Este documento detalla los hallazgos de la auditoría técnica realizada en la Fase 1 del roadmap financiero. El objetivo es identificar todos los puntos donde el sistema utiliza cálculos aritméticos manuales sobre columnas legacy (`total_discount`) en lugar de utilizar `public.transactions` como Fuente de Verdad (SSOT).

## 1. Hallazgos Críticos: El "Smoking Gun"

### 1.1 `ConfiguresReportConnection.php` - El Punto Ciego Global
Se identificó que el Trait central de reportes (`app/Traits/Reports/ConfiguresReportConnection.php`) propaga un error estructural de cálculo:

```php
// app/Traits/Reports/ConfiguresReportConnection.php:L59
protected function getTicketNetAmount(): string
{
    return '(t.total_price - COALESCE(t.total_discount, 0))';
}
```

> [!WARNING]
> **Impacto del BUG-04:** Esta función es la responsable de que múltiples reportes resten el "monto" de descuento incluso cuando este representa un porcentaje mal interpretado. Si un ticket de $100 tiene "100%" de descuento, el reporte resta $100 del precio bruto, lo cual es correcto operativamente pero analíticamente ciego si el dato de entrada está corrupto.

---

### 1.2 `ProductsReportService.php` - Metodología JasperReports
Se encontró que el sistema ya detecta la discrepancia pero la resuelve mediante **omisión** en lugar de corrección:

```php
// app/Services/Reports/ProductsReportService.php:L248
->where('t.total_price', '>', 0)  // Excluir tickets con descuento 100%
```

*   **Evidencia:** El servicio tiene una métrica llamada `JasperReports methodology` que excluye explícitamente los tickets con descuento del 100% para que los totales cuadren con los PDFs manuales.
*   **Riesgo:** Esto "embellece" el reporte pero oculta la realidad financiera de las cortesías y mermas en el flujo principal.

---

### 1.3 `SalesSummaryController.php` - Divergencia de Neto
El controlador de resumen de ventas utiliza una lógica híbrida:

```sql
-- Query en fetchRows()
ROUND(
    COALESCE(vs.bruto, 0) + COALESCE(vd.void_amount, 0)
    - COALESCE(vs.descuento, 0) -- Dependencia en ticket.total_discount
    - (COALESCE(r.refund_amount, 0) + COALESCE(vd.void_amount, 0)),
    2
) AS neto
```

*   **Problema:** Aunque el controlador ya lee `public.transactions` para obtener `pagos_netos`, el valor de `neto` que se muestra en la columna principal se calcula restando el descuento (posiblemente corrupto).
*   **Consecuencia:** El usuario ve un "Neto" que no coincide con los "Pagos" en tickets afectados por el BUG-04.

---

## 2. Inventario de Riesgo (High Attack Surface)

| Componente | Archivo | Riesgo | Acción Requerida |
| :--- | :--- | :--- | :--- |
| **Global Report Trait** | `ConfiguresReportConnection.php` | Crítico (Propagación) | Inyectar `SalesResolutionService` |
| **Sales Summary** | `SalesSummaryController.php` | Alto (Inconsistencia UI) | Sustituir cálculo manual por SSOT de transacciones |
| **Exceptions Report** | `SalesExceptionsReportService.php` | Alto (Falso Positivo) | Validar excepciones contra SSOT |
| **Dashboard KPIs** | `ProductsReportService.php` | Medio (Data Incompleta) | Eliminar exclusión manual de 100% |

---

## 3. Conclusión de Auditoría

La arquitectura actual sufre de **"Sesgo Aritmético Legacy"**: el sistema confía más en la resta manual de una columna denormalizada (`total_discount`) que en la suma de los eventos de flujo de caja (`transactions`).

**Dictamen:** Se debe proceder con la **Etapa B (Inyección de Modo Canon)**, sustituyendo el método `getTicketNetAmount()` por una llamada o cálculo derivado estrictamente de las transacciones liquidadas.
