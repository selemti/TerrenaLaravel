# Arquitectura del Sistema — TerrenaLaravel
> Actualizado: Abril 2026

## Stack Tecnológico

| Capa | Tecnología | Versión |
|------|-----------|---------|
| Framework backend | Laravel | 12.x |
| Frontend reactivo | Livewire | 3.7.0 |
| CSS | Tailwind CSS + Bootstrap | 4.x + 5.3 |
| JS reactivo | Alpine.js | 3.x |
| Base de datos | PostgreSQL | 9.5 (prod) |
| POS | FloreantPOS | 1.5 (Java/Swing) |
| Auth API | Laravel Sanctum + JWT | 4.x + 2.2 |
| Permisos | Spatie Laravel Permission | 6.x |
| PDF | DomPDF | 3.x |
| Excel | Maatwebsite Excel | 3.x |
| Cola de trabajos | Laravel Queue (DB driver) | — |
| Assets | Vite | 7.x |

---

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTES                             │
│   Browser (Livewire)   │   POS Tablet (API REST)            │
└────────────┬───────────┴───────────────┬────────────────────┘
             │                           │
┌────────────▼───────────────────────────▼────────────────────┐
│                    LARAVEL 12 ERP                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Web Routes   │  │  API Routes  │  │   Queue Workers  │  │
│  │ (Livewire)   │  │ (REST/JSON)  │  │  (Consumption,   │  │
│  └──────┬───────┘  └──────┬───────┘  │   Restock, etc.) │  │
│         │                 │          └──────────────────┘  │
│  ┌──────▼─────────────────▼───────┐                        │
│  │         Services Layer          │                        │
│  │  Caja | Inventory | Purchasing  │                        │
│  │  Recetas | Reports | PosSync    │                        │
│  └──────────────┬─────────────────┘                        │
│                 │                                           │
│  ┌──────────────▼─────────────────┐                        │
│  │         Models (Eloquent)       │                        │
│  └──────────────┬─────────────────┘                        │
└─────────────────┼───────────────────────────────────────────┘
                  │
     ┌────────────┴────────────┐
     │                         │
┌────▼────────┐   ┌────────────▼──────────────┐
│ schema:     │   │ schema: selemti             │
│ public      │   │ (ERP propio — R/W)          │
│ (FloreantPOS│   │ Caja, Inventario, Compras,  │
│  read-only) │   │ Recetas, Producción, etc.   │
└─────────────┘   └────────────────────────────┘
       ▲
       │ Lee tickets, ventas, pagos
┌──────┴──────────────────────────────────┐
│           FloreantPOS (Java)             │
│  Tablets / Terminales de venta           │
└──────────────────────────────────────────┘
```

---

## Módulos del Sistema (25 módulos definidos)

### Módulos Operativos Core
1. **Caja / Sesión de Cajón** — Apertura, precorte, corte, postcorte, conciliación
2. **Caja Chica** — Gestión de fondo fijo, movimientos, arqueo, aprobaciones
3. **POS Sync** — Lectura de FloreantPOS, mapeo items → insumos
4. **KDS (Kitchen Display)** — Display de órdenes en cocina (SSE/WebSockets)

### Módulos de Inventario
5. **Catálogos** — Unidades, almacenes, sucursales, proveedores, políticas de stock
6. **Items / Insumos** — Maestro de artículos con categorías, presentaciones, unidades
7. **Stock** — Nivel actual por almacén/lote, valorizado (WAC)
8. **Movimientos** — Entradas, salidas, ajustes, mermas
9. **Conteos Físicos** — Inventario cíclico/completo con aprobación
10. **Lotes** — Trazabilidad FEFO, caducidad, APPCC
11. **Transferencias** — Inter-almacén con aprobación y despacho

### Módulos de Compras
12. **Solicitudes de Compra** — Flujo solicitud → aprobación
13. **Órdenes de Compra** — Generación, aprobación, seguimiento
14. **Recepciones (GRN)** — Recepción contra OC, costeo WAC
15. **Devoluciones** — Devolución a proveedor, nota de crédito
16. **Reposición** — Sugerencias automáticas por punto de reorden

### Módulos de Producción / Recetas
17. **Recetas / BOM** — Estructura de costo, ingredientes, versiones
18. **Costeo de Recetas** — WAC, último costo, snapshots históricos
19. **Órdenes de Producción** — Mise en place, consumo de insumos
20. **Producción** — Ejecución, captura, posteo a inventario

### Módulos de Reportería
21. **Reportes de Ventas** — Sales mix, journal, drawer pull, exceptions
22. **Reportes de Inventario** — Stock valorizado, anomalías, top urgentes
23. **KPIs / Dashboard** — Ventas vs costo teórico, márgenes
24. **Auditoría** — Logs de operaciones, políticas de retención

### Módulo Administrativo
25. **Admin / Tickets** — Gestión, anulación, cierre masivo, permisos

---

## Flujos de Negocio Principales

### Flujo de Corte de Caja
```
SesionCajon (apertura)
  └─► Ventas en FloreantPOS (tickets/transacciones)
        └─► PosConsumptionService (consumo teórico batch)
              └─► Precorte (totales por forma de pago)
                    └─► Postcorte (declarado vs sistema)
                          └─► Conciliación (diferencias, alertas)
```

### Flujo de Inventario
```
OC (PurchaseOrder)
  └─► GRN / Recepción (ReceptionService → costeo WAC)
        └─► Stock (InventoryMovement → lotes)
              ├─► Transferencia (TransferService)
              ├─► Producción (ProductionService → consume insumos)
              │     └─► Consumo POS (PosConsumptionService)
              └─► Conteo Físico (InventoryCountService → ajustes)
```

### Flujo de Reposición
```
AlertEngine (nivel < punto de reorden)
  └─► ReplenishmentService (sugerencias)
        └─► DemandCalculationService (demanda histórica)
              └─► PurchaseSuggestion → PurchaseRequest → PurchaseOrder
```

---

## Decisiones de Diseño Clave

| Decisión | Elección | Motivo |
|----------|---------|--------|
| Costeo de inventario | WAC (Costo Promedio Ponderado) | Estándar en restaurantes MX |
| Lotes/caducidad | FEFO recomendado, PEPS configurable | APPCC compliance |
| Consumo POS | Batch cada 60s (job) | Sin latencia en POS |
| Schema dual | public (Floreant) + selemti (ERP) | Evitar modificar Floreant |
| Auth | Sanctum para web, JWT para API móvil | Multi-cliente |
| Unidades | Canónica única por ítem + conversiones | Evitar inconsistencias |
| Motor de alertas | AlertEngine genérico con reglas | Extensible a cualquier módulo |

---

## Estructura de Carpetas (app/)

```
app/
├── Http/
│   ├── Controllers/
│   │   ├── Api/
│   │   │   ├── Caja/          (10 controladores)
│   │   │   ├── Inventory/     (7 controladores)
│   │   │   ├── Purchasing/    (1 controlador)
│   │   │   └── Unidades/      (2 controladores)
│   │   └── (web controllers)
├── Livewire/
│   ├── CashFund/    Caja Chica (6)
│   ├── Catalogs/    Catálogos (6)
│   ├── Inventory/   Inventario (10)
│   ├── InventoryCount/ Conteos (5)
│   ├── Recipes/     Recetas (7)
│   ├── Purchasing/  Compras (5)
│   ├── Replenishment/ Reposición (1)
│   ├── Reports/     Reportes (2)
│   ├── Transfers/   Transferencias (5)
│   ├── Pos/         POS Sync (4)
│   ├── Audit/       Auditoría (2)
│   └── Kds/         KDS (1)
├── Models/
│   ├── Caja/        Modelos de caja
│   ├── Inv/         Modelos de inventario (legacy)
│   ├── Inventory/   Modelos de inventario (nuevo)
│   ├── Pos/         Modelos POS (lectura Floreant)
│   ├── Rec/         Modelos de recetas
│   ├── Catalogs/    Catálogos
│   ├── Purchasing/  Compras
│   └── Core/        Modelos legacy
└── Services/
    ├── Caja/        Servicios de caja
    ├── Cash/        Caja chica
    ├── Inventory/   Inventario
    ├── Pos/         POS sync
    ├── Purchasing/  Compras
    ├── Recetas/     Recetas
    ├── Reports/     Reportes
    ├── Replenishment/ Reposición
    ├── Operations/  Operaciones diarias
    ├── Alerts/      Motor de alertas
    ├── Audit/       Auditoría
    └── Costing/     Costeo
```
