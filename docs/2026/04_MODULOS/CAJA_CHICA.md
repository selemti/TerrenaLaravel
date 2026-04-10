# Módulo de Caja Chica (Cash Fund)
> Actualizado: Abril 2026

## Flujo

```
Apertura (CashFundOpen) → fondo fijo asignado
        │
        ▼
Movimientos (CashFundMovements) → gastos/ingresos con comprobante
        │
        ▼
Arqueo periódico (CashFundArqueo) → conteo físico vs sistema
        │
        ▼
Aprobación (CashFundApprovals) → gerencia revisa y aprueba
        │
        └── Liquidación / cierre del fondo
```

---

## Componentes Livewire

| Componente | Ruta | Descripción |
|-----------|------|------------|
| CashFundIndex | `/cashfund` | Lista de fondos activos |
| CashFundOpen | `/cashfund/open` | Abrir nuevo fondo |
| CashFundMovements | `/cashfund/{id}/movements` | Registrar movimientos |
| CashFundArqueo | `/cashfund/{id}/arqueo` | Realizar arqueo |
| CashFundDetail | `/cashfund/{id}/detail` | Detalle completo del fondo |
| CashFundApprovals | `/cashfund/approvals` | Aprobaciones pendientes |

> Nota: `/cashfund/approvals` requiere permiso `can:approve-cash-funds`

---

## Servicio

`CashFundService` (173 líneas) — ✅ implementado

Maneja: apertura, movimientos, arqueo, aprobación, cierre.

---

## Modelos / Tablas

| Modelo | Tabla | Descripción |
|--------|-------|------------|
| CashFund | `cash_funds` | Fondo fijo |
| CashFundMovement | `cash_fund_movements` | Movimientos (gasto/ingreso) |
| CashFundArqueo | `cash_fund_arqueos` | Arqueos realizados |
| CashFundMovementAuditLog | `cash_fund_movement_audit_logs` | Auditoría detallada |

---

## Documentación adicional

- `docs/CAJA_CHICA_LIFECYCLE.md` — Ciclo de vida completo
- `docs/MEJORAS_CAJA_CHICA.md` — Mejoras implementadas
- `docs/PERMISOS_CAJA_CHICA.md` — Estructura de permisos
- `docs/FASE2_ARQUEO_DETALLADO.md` — Proceso detallado de arqueo
- `docs/FASE3_APROBACIONES.md` — Flujo de aprobaciones
