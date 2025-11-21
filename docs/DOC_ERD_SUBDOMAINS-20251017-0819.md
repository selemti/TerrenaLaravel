ERD por Subdominio — Caja, POS, Inventario/Recetas

Fecha: 2025-10-17 08:19

Caja (selemti)
```mermaid
erDiagram
  SESION_CAJON ||--o{ PRECORTE : "sesion_id"
  PRECORTE ||--o{ PRECORTE_EFECTIVO : "precorte_id"
  PRECORTE ||--o{ PRECORTE_OTROS : "precorte_id"
  SESION_CAJON ||--|| POSTCORTE : "sesion_id (unique)"
```

POS (public)
```mermaid
erDiagram
  TERMINAL ||--o{ TICKET : "terminal_id"
  USERS ||--o{ TICKET : "owner_id/driver_id/void_by_user"
  GRATUITY ||--o{ TICKET : "gratuity_id"
  SHIFT ||--o{ TICKET : "shift_id"
```

Inventario/Recetas (selemti + public donde aplique)
```mermaid
erDiagram
  RECETA_CAB ||--o{ RECETA_VERSION : "receta_id"
  RECETA_VERSION ||--o{ RECETA_DET : "receta_version_id"
  RECETA_SHADOW ||--o{ RECETA_VERSION : "receta_id (shadow)"
  UNIDADES_MEDIDA ||--o{ RECETA_DET : "unidad"
  STOCK_POLICY ||--o{ ??? : "aplicación (según diseño)"
```

Global (relaciones relevantes entre dominios)
```mermaid
flowchart LR
  subgraph PUBLIC
    PT[public.terminal]
    PU[public.users]
    TK[public.ticket]
  end
  subgraph SELEMTI
    SC[selemti.sesion_cajon]
    PR[selemti.precorte]
    PRe[selemti.precorte_efectivo]
    PRo[selemti.precorte_otros]
    PO[selemti.postcorte]
  end
  PT -- terminal_id --> SC
  PT -- terminal_id --> TK
  SC -- sesion_id --> PR
  PR -- precorte_id --> PRe
  PR -- precorte_id --> PRo
  SC -- sesion_id (unique) --> PO
```
