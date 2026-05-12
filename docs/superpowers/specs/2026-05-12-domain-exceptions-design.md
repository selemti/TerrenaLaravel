# Domain Exceptions — Design Spec
**Date:** 2026-05-12  
**Status:** Approved  
**Branch:** work/inicio-limpio-abril-2026

## Goal

Replace generic `InvalidArgumentException` / `RuntimeException` throws in service layer with typed domain exceptions that:
1. Carry semantic meaning (what went wrong, in which domain)
2. Map automatically to correct HTTP codes via Laravel's exception handler
3. Include debugging context (IDs, states) for logging

## File Structure

```
app/Exceptions/
├── Domain/
│   └── DomainException.php
├── Inventory/
│   ├── InventoryException.php
│   ├── InventoryValidationException.php
│   ├── InvalidInventoryStateException.php
│   ├── ItemNotFoundException.php
│   └── InsufficientStockException.php
├── Transfer/
│   ├── TransferException.php
│   ├── InvalidTransferStateException.php
│   └── TransferNotFoundException.php
├── Caja/
│   ├── CajaException.php
│   └── InvalidCajaStateException.php
└── CashFund/
    ├── CashFundException.php
    └── CashFundValidationException.php
```

## Class Hierarchy

```
\RuntimeException
  └── DomainException (abstract, carries $context[])
        ├── InventoryException
        │     ├── InventoryValidationException        → HTTP 422
        │     ├── InvalidInventoryStateException      → HTTP 409 ($currentState, $expectedState)
        │     ├── ItemNotFoundException               → HTTP 404 ($itemId)
        │     └── InsufficientStockException          → HTTP 422 ($itemId, $requested, $available)
        ├── TransferException
        │     ├── InvalidTransferStateException       → HTTP 409 ($transferId, $currentState, $expectedState)
        │     └── TransferNotFoundException           → HTTP 404 ($transferId)
        ├── CajaException
        │     └── InvalidCajaStateException           → HTTP 409
        └── CashFundException
              └── CashFundValidationException         → HTTP 422
```

## HTTP Mapping (bootstrap/app.php)

| Exception class | HTTP code | Rationale |
|----------------|-----------|-----------|
| `*NotFoundException` | 404 | Entity does not exist |
| `InventoryValidationException`, `InsufficientStockException`, `CashFundValidationException` | 422 | Bad input / constraint violation |
| `Invalid*StateException` | 409 | Conflict — operation not valid in current state |
| Any other `DomainException` | 400 | Generic bad request |

Response body (JSON, enforced by existing `ApiResponseMiddleware`):
```json
{ "ok": false, "error": "invalid_inventory_state", "message": "...", "timestamp": "..." }
```

## Named Constructors (API ergonomics)

```php
ItemNotFoundException::forId(string $itemId): static
InvalidInventoryStateException::transition(int $receptionId, string $current, string $expected): static
InvalidTransferStateException::transition(int $transferId, string $current, string $expected): static
InsufficientStockException::forItem(string $itemId, float $requested, float $available): static
```

## Services to Migrate

| Service | Current throws | New exception |
|---------|---------------|---------------|
| `ReceptionService` | `InvalidArgumentException` (not found, wrong state) | `ItemNotFoundException`, `InvalidInventoryStateException` |
| `TransferService` | `InvalidArgumentException` + `RuntimeException` (state, not found, validation) | `InvalidTransferStateException`, `TransferNotFoundException`, `InventoryValidationException` |
| `ProductionService` | `InvalidArgumentException` (missing fields, qty) | `InventoryValidationException` |
| `InventoryCountService` | `RuntimeException` (not found), `InvalidArgumentException` (missing item_id) | `ItemNotFoundException`, `InventoryValidationException` |
| `ReceivingService` | `InvalidArgumentException` (empty lines, invalid ids) | `InventoryValidationException` |
| `CashFundService` | `InvalidArgumentException` (missing fields, qty) | `CashFundValidationException` |
| `UomConversionService` | `InvalidArgumentException` (invalid tipo) | `InventoryValidationException` |
| `AuditLogService` | `InvalidArgumentException` | `InventoryValidationException` (or leave — minor) |

## Non-Goals

- Do NOT create exceptions for Purchasing domain yet (tables not migrated, no active service layer)
- Do NOT wrap Eloquent `ModelNotFoundException` — Laravel handles that natively
- Do NOT change controller try/catch blocks — HTTP mapping is centralized in handler
