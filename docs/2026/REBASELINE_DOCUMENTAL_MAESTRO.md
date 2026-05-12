# ⚠️ DOCUMENTO SUPERSEDIDO
Este documento no define el orden actual de ejecución.
Consultar primero: [00_README_EJECUCION_FASE_2.md](00_README_EJECUCION_FASE_2.md)

# INFORME MAESTRO DE REBASELINE DOCUMENTAL E INTEGRAL
**Fecha**: Abril 13, 2026
**Objetivo**: Reestablecer la fuente de verdad estructural y operativa del sistema TerrenaLaravel tras descartar documentación histórica contaminada.

---

## A. Inventario Maestro de Módulos Operativos

### 1. Caja y Postcorte (Core Transaccional)
- **Propósito**: Cuadre de efectivo de cajeros vs sistema Floreant POS, arqueos, caja chica.
- **Estado Real**: VIGENTE (con anomalía de ventana temporal a corregir en F-03).
- **Código Principal**: `App\Models\Caja\Postcorte`, `App\Http\Controllers\Api\Caja\*`, `App\Livewire\CashFund\*`
- **DB (Fuente de Verdad)**: `selemti.fn_generar_postcorte` (crea el corte sumando POS), `public.transactions`, `public.ticket`.
- **Docs**: `docs/2026/04_MODULOS/CAJA.md` (Única fuente válida).

### 2. Inventario y Consumo POS
- **Propósito**: Mapeo y rebaje del stock (kardex) consumido teóricamente de **Insumos Genéricos** a partir de ventas del POS.
- **Estado Real**: VIGENTE y CERTIFICADO (v2.5). Soporta explosión recursiva y desacoplamiento de marcas.
- **Código Principal**: `selemti.fn_expandir_consumo_ticket` (v2.5), `Inventory\PosConsumptionService`.
- **DB (Fuente de Verdad)**: `selemti.inv_consumo_pos_det` (Auditoría granular).
- **Docs**: `docs/2026/04_MODULOS/INVENTARIO.md`, `docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md`, `docs/2026/31_MODELO_DESACOPLAMIENTO_INSUMO_PRESENTACION.md`.

### 3. Compras y Sugerido (Replenishment)
- **Propósito**: Abastecimiento predictivo y recepción de mercancía.
- **Estado Real**: VIGENTE.
- **Código Principal**: `ReplenishmentDashboard`, `ReplenishmentController`, `App\Models\Purchasing\*`.

### 4. Producción (Transformación Interna)
- **Propósito**: Transformación de insumos base en sub-recetas y productos finales con BOM.
- **Estado Real**: VIGENTE y Operativo. Integrado con Recursividad Logística.
- **Código Principal**: `App\Services\Production\ProductionService`, `App\Livewire\Production\*`.

### 5. Transferencias (Sucursales)
- **Propósito**: Mover stock entre `selemti.v_bodega`.
- **Estado Real**: VIGENTE (Corregido recientemente el check en `DailyCloseService`).
- **Código Principal**: `App\Models\Inventory\TransferHeader` (`traspaso_cab`).

### 6. Reportes (Nativos vs Legacy)
- **Propósito**: Dashboards de ventas, mermas e inventario.
- **Estado Real**: TRANSICIONAL. Coexisten rutas exclusivas Jasper (`/reports/sales/detail`) con vistas nativas (`/reports/dashboard`).

---

## B. Inventario Maestro Documental

Tras escanear recursivamente la carpeta `docs/`, se mapeó el infierno documental.

### 1. Documentación Vigente y Confiable
- **`AI_COORDINATION/STATUS.md`**: El orquestador sagrado de agentes (Claude/Gemini/Codex).
- **`docs/2026/04_MODULOS/CAJA.md`**: Recientemente purgado de mentiras (abril 2026).
- **Hito 1: Saneamiento Financiero (Abr 2026)**: Implementación del [SSOT de Ventas (Doc 07)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/07_SSOT_VENTAS_Y_DESCUENTOS.md) y [Cierre de Fase 1 (Doc 17)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/17_CIERRE_FORMAL_FASE_1.md).
- **Hito 2: Motor de Consumo Recursivo (Abr 2026)**: Finalización de la arquitectura lógica y motor v2.5. Estado: **Prototipo Avanzado**. Pendiente: Población de datos reales e higiene de IDs (ver [Doc 24](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md)).
- **`.gemini/GEMINI.md`**: Excelente para reglas operativas y convenciones de trabajo (pero no para reglas de negocio).

### 2. Documentación Vigente pero Incompleta
- El modelo exacto de sincronización UOM (Unit of Measure) para recetas anidadas.

### 3. Histórica, Obsoleta y Engañosa (ZONA ROJA)
Existen **más de 80 archivos** en la ruta `docs/00.history/` (y `V2/`, `V3/`, `V4.0/`, `BD/NoviembreDocs/`). 
Ejemplos críticos que provocan alucinación en AIs:
- `DOC_WIZARD_CORTE_CAJA-20251017-0126.md`
- `MODIFICACIONES_POSTCORTE_CONTROLLER.md`
- Todo el bloque de `.history/BD/Normalizacion/` 

**Veredicto**: Toda carpeta que contenga nombres con fechas 2025 debe evitarse para resolver bugs en 2026.

---

## C. Mapa de Verdad del Sistema (Contrato 2026)

| Dominio | Documento / Archivo Canónico a Consultar ANTES de programar |
|---------|-----------------------------------------------------------|
| **Orquestación/Ruteo AI**| `AI_COORDINATION/STATUS.md` |
| **Apego/Reglas de Agente**| `.gemini/GEMINI.md` o `CLAUDE.md` |
| **Caja / Cortes** | `docs/2026/04_MODULOS/CAJA.md` (*Nunca* usar historia de 2025) |
| **Motor PostgreSQL** | Directamente query a `pg_proc` y vistas `vw_*`. **El código DB manda sobre cualquier markdown.** |
| **Endpoints y API** | Exclusivamente `routes/web.php` y `routes/api.php` |

---

## D. Pendientes Reales del Proyecto (Evidencia)

- ⏳ **FASE 3 (Corte Real)**: Refactorizar `selemti.fn_generar_postcorte` para agrupar tickets usando `folio_date` vs `v_apertura_ts`, solucionando el falso bug de los NULLs convertido en totales 0.00.
- ⏳ **Seguridad**: Existen bloques enteros en `api.php` listos pero con middleware `auth:sanctum` suspendido explícitamente para desarrollo. Ej: `/postcortes/pendientes-aprobacion`.
- ⏳ **Legado**: Cientos de líneas comentadas con `legacy/` redirecciones en `web.php` que ensucian la tabla de enrutamiento.

---

## E. Riesgos de Gobierno del Cambio

1. **Riesgo Crítico - Alteración de Bases de Datos ciegamente:**
   Modificar un trigger (`trg_*`) o función (`fn_*`) basándose en documentación externa y no en la lectura directa del DDL de PostgreSQL. (*Caso de vida real: G-01 en Abril 2026*).
2. **Duplicidad de Servicios:**
   Al haber archivos en `Operations/` vs `Inventory/` (ej. `PosConsumptionService`). 
3. **Mapeo de Rutas Silencioso:**
   Muchas rutas de postcorte son interceptadas en bloques regex en `api.php` (`/postcortes[/{id}]`). Insertar métodos arriba o abajo altera masivamente el comportamiento REST.

---

## F. Propuesta de Estructura Documental Final

1. **Mantener** la jerarquía de `docs/2026/04_MODULOS/` como la única Biblia del comportamiento lógico por dominio.
2. **Renombrar** radicalmente `00.history` a `.deprecated_history` para evitar que los vectores de búsqueda de Claude / Gemini los incluyan al buscar "¿Cómo funciona el postcorte?".
3. **Crear** `docs/2026/02_BASE_DE_DATOS.md` pero **no para transcribir SQL**, sino únicamente para indexar responsabilidades: "La tabla X es poblada mediante la función Y".

**Fin de Informe Rebaseline.**
