# MATRIZ MAESTRA DE MÓDULOS - TERRENALARAVEL

**Ubicación:** `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
**Fecha de Generación:** Abril 2026
**Propósito:** Definir de manera absoluta e irrevocable el perímetro funcional, arquitectónico y operativo del sistema, limitándose EXCLUSIVAMENTE a la evidencia encontrada en código (Laravel y REST API), base de datos (PostgreSQL), e integraciones documentales comprobadas. Esta es la **única** fuente de verdad validada para análisis de módulos.

---

### 1. Caja y Postcorte
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Caja y Postcorte |
| **Clasificación** | 🟣 CORE / 🟡 AMBIGUO |
| **Objetivo de negocio** | Conciliar efectivo de cajeros vs operaciones (tickets) del sistema, calculando faltantes/sobrantes (drawer). |
| **Flujo funcional resumido** | Apertura Sesión ➔ Precorte ➔ Declarado Físico ➔ Postcorte (Comparativo de valores reales) ➔ Alertas de Conciliación. |
| **Endpoints principales** | `/caja/cortes/historico` (Web). `/caja/sesiones/*`, `/caja/precortes/*`, `/caja/postcortes/*` (API). |
| **Componentes clave** | `Models\Caja\Postcorte`, `PostcorteController`, Componentes Livewire `CashFund\*`. |
| **Elementos BD** | Tablas: `selemti.postcorte`, `selemti.precorte`. Función PL/pgSQL: `selemti.fn_generar_postcorte`. Trigger: `trg_postcorte_after_insert`. |
| **Lógica en Laravel** | CRUD, validación de API, orquestación UI (Livewire). |
| **Lógica en PostgreSQL** | Las agregaciones formales de totales de venta y descuentos entre `public.transactions` y `public.ticket` se realizan en PL/pgSQL. |
| **Estado** | Implementado parcialmente operativo (Error por exclusión temporal en queries). |
| **Fuente de verdad** | Código BD (`fn_generar_postcorte`) + [Doc 07 (SSOT Ventas)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/07_SSOT_VENTAS_Y_DESCUENTOS.md) + [Doc 17 (Cierre F1)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/17_CIERRE_FORMAL_FASE_1.md) |
| **Riesgo si se modifica** | **Alto/Crítico**. Rompe la paridad financiera real y los cierres de turno de cajeros. |
| **Pendiente principal** | Modificar regla temporal estricta en `fn_generar_postcorte` para admitir tickets cerrados fuera de ventana estricta (FASE 3). |

---

### 2. Inventario Pos Consumption
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Inventario Pos / Consumo de Ventas |
| **Clasificación** | 🟣 CORE |
| **Objetivo de negocio** | Rebajar teóricamente en tiempo real las existencias en Kardex de los **Insumos Genéricos** al procesar ventas. |
| **Flujo funcional resumido** | Venta POS ➔ Implosión BOM ➔ Insumo Genérico (SSOT Stock) ➔ Conversión UOM ➔ Descuento Kardex automático. |
| **Endpoints principales** | `/inventory/items/{id}/kardex` (API/Web). |
| **Componentes clave** | `Inventory\PosConsumptionService`, `DailyCloseService`, Comando `PosReprocess` (Roto en dependencias). |
| **Elementos BD** | Tabla: `selemti.inv_consumo_pos`. Trigger: `trg_ticket_inventory_consumption`. |
| **Lógica en Laravel** | Tareas repetitivas programadas y reprocesamientos de orquestador bajo demanda (`DailyCloseService`). |
| **Lógica en PostgreSQL** | El trigger sobre `public.ticket` intercepta asíncronamente y rebaja el inventario "al vuelo". |
| **Estado** | 🟡 Prototipo Avanzado (Lógica Core) |
| **Fuente de verdad** | `selemti.fn_expandir_consumo_ticket` (v2.5) + [Doc 24 (Motor)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md). Pendiente Población de Datos Maestros. |
| **Riesgo si se modifica** | **Alto**. Descuadra drásticamente saldos de kardex físico vs teórico. |
| **Pendiente principal** | Población de datos reales de insumos y UOMs (Fase 2.3). Ver estrategia en **[Doc 26 (Dataset)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/26_DATASET_MINIMO_FASE_2.md)** y **[Doc 27 (Plantillas)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/27_PLANTILLAS_CARGA_FASE_2.md)**. |

---

### 3. Compras, Sugerido y Recepciones (Replenishment)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Compras / Replenishment |
| **Clasificación** | 🔵 SOPORTE |
| **Objetivo de negocio** | Gestionar **Presentaciones Comerciales** por proveedor, transformarlas en UOM base y alimentar el WAC del **Insumo Genérico**. |
| **Flujo funcional resumido** | Orden de Compra (Marca/Presentación) ➔ Recepción ➔ Conversión a UOM Base ➔ Update WAC Insumo Genérico ➔ Kardex. |
| **Endpoints principales** | `/purchasing/replenishment` (Web). `/purchasing/suggestions/*`, `/purchasing/receptions/*` (API). |
| **Componentes clave** | `Livewire/Purchasing/*`, `ReplenishmentController`, `ReceivingController`. |
| **Elementos BD** | `vw_replenishment_dashboard`, `vw_replenishment`. Tablas compra: `recepcion_cab`, `recepcion_det`. |
| **Lógica en Laravel** | Conversión sugerido-a-orden, control Livewire y consolidación de vista al usuario. |
| **Lógica en PostgreSQL** | La evaluación matemática de qué sugerir comprar está empaquetada enteramente en `vw_replenishment`. |
| **Estado** | Operativo. |
| **Fuente de verdad** | Código `ReplenishmentDashboard` e interfaz `Purchasing`. |
| **Riesgo si se modifica** | **Medio**. Fricción en algoritmos predictivos o encarecer tiempos de carga de Dashboard. |
| **Pendiente principal** | Purgar duplicidad de servicios: `ReceivingService` vs `ReceptionService`. |

---

### 4. Producción Interna
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Producción Interna |
| **Clasificación** | 🔵 SOPORTE |
| **Objetivo de negocio** | Generar productos sub-receta o finales a partir de insumos base o intermedios en lotes. |
| **Flujo funcional resumido** | OP (Orden de Producción) ➔ Receta Formulación ➔ Captura en Planta ➔ Inserción Inventarios. |
| **Endpoints principales** | `/production/*` (Web). `/production/batch/*` (API). |
| **Componentes clave** | `Livewire\Production\OrdersIndex`, `ProductionController`. |
| **Elementos BD** | `selemti.op_cab`, `selemti.op_insumo`. |
| **Lógica en Laravel** | Toda la reactividad de estados (Planear, Consumido, Hecho), captura UOM vía Livewire. |
| **Lógica en PostgreSQL** | Almacenamiento directo. |
| **Estado** | 🟡 En Desarrollo / Sin Data |
| **Fuente de verdad** | `docs/2026/04_MODULOS/PRODUCCION.md` + [Doc 24](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md). |
| **Riesgo si se modifica** | **Medio**. Posibilidad de generar UOMs recursivos que ciclen infinitamente. |
| **Pendiente principal** | Auditoría de balanceo en Kardex Real vs Teórico tras carga masiva. |

---

### 5. Recetas e Ingeniería de Menú
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Recetas e Ingeniería de Menú |
| **Clasificación** | 🔵 SOPORTE / 🟡 AMBIGUO |
| **Objetivo de negocio** | Mantener listas de componentes (BOM), costeo estándar real y mapeo directo al botón de venta POS. |
| **Flujo funcional resumido** | Ítem Menú ➔ Mapeo Lista Insumos BOM ➔ Conversión de unidad volumétrica a financiera ➔ Precio Costo Promedio. |
| **Endpoints principales** | `/recipes/*` (Web). `/recipes/{id}/cost`, `/recipes/{id}/bom/implode` (API). |
| **Componentes clave** | `Livewire\Recipes\RecipeEditor`, `RecipeCostController`. |
| **Elementos BD** | Vistas complejas `v_receta`, `v_receta_insumo`, `v_ingenieria_menu_completa`. Funciones factor `fn_recipe_cost_at`. |
| **Lógica en Laravel** | Render visual de árboles implosionados del costo. |
| **Lógica en PostgreSQL** | Recursividad SQL pesada para encontrar el fondo del árbol BOM usando `v_ingenieria_menu_completa`. |
| **Estado** | Operativo parcial (Arquitectura Livewire en Spanglish, disparidad de rutas /recetas vs /recipes). |
| **Fuente de verdad** | Documentos `D:\Tavo\2025\UX\00. Recetas` y Vistas BD `v_ingenieria_*`. |
| **Riesgo si se modifica** | **Alto**. Si se rompe el cálculo de una receta raíz, todas las sub-recetas arrastran utilidades negativas. |
| **Pendiente principal** | Definir obligatoriedad de nombre dominial (`Recipe` vs `Receta`) entre Frontend Web y Rutas API. |

---

### 6. Transferencias (Traspasos)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Traspasos (Transfers) |
| **Clasificación** | 🔵 SOPORTE |
| **Objetivo de negocio** | Documentar salidas logísticas entre almacenes internos y confirmar ingreso. |
| **Flujo funcional resumido** | Borrador Envío ➔ Ship (Salida de kardex) ➔ Receive (Inspección y alta) ➔ Post Confirmado. |
| **Endpoints principales** | `/inventory/transfers/*` (API). |
| **Componentes clave** | `Livewire\Transfers\*`, `App\Http\Controllers\Inventory\TransferController`, `App\Http\Controllers\Api\Inventory\TransferApiController`. |
| **Elementos BD** | `selemti.traspaso_cab`, `selemti.traspaso_det`. |
| **Lógica en Laravel** | Duplicidad cruda de controladores MVC interceptando la misma petición. |
| **Lógica en PostgreSQL** | Entidad relacional bruta. |
| **Estado** | Planeado / Implementado con Duplicidad. |
| **Fuente de verdad** | No documentado como prioridad, se deduce de implementaciones legacy. |
| **Riesgo si se modifica** | **Bajo**. Se puede desacoplar de manera limpia. |
| **Pendiente principal** | Destruir `TransferApiController` o `TransferController` a favor de un Service único en el repo. |

---

### 7. Reportes, Diagnóstico y Dashboards (Jasper / Nativo)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Reportes (BI / Financieros) |
| **Clasificación** | 🟡 INCOMPLETO / FRAGMENTADO |
| **Objetivo de negocio** | Imprimir vistas contables operacionales (Mix ventas diarios, tickets vs efectivo, kardex valorizado Jasper). |
| **Flujo funcional resumido** | Seleccionar Fecha ➔ Invocar SQL Agrupado / Endpoint Jasper ➔ Volcado a JSON o PDF. |
| **Endpoints principales** | `/reports/sales/*`, `/reports/dashboard` (Web), Jasper Drilldowns. |
| **Componentes clave** | `Reports\SalesSummaryController`, `Reports\SalesDetailController`, `Livewire\ReportsDashboard`. |
| **Elementos BD** | Multiplicidad asombrosa de vistas ad-hoc: `vw_report_sales_detail`, `vw_diag_neto_vs_cobros`, `vw_net_sales`. |
| **Lógica en Laravel** | Conectividad REST delegando casi 100% el esfuerzo, o interfaces minimalistas Livewire. |
| **Lógica en PostgreSQL** | Todas las agregaciones cruces de sumatoria SQL y lógicas de diagnóstico residen estáticamente aquí. |
| **Estado** | Parcial / Funcional pero ambiguo en mantenimiento. |
| **Fuente de verdad** | Los txt `Analisis costos` de `D:\Tavo\2025\UX\GPTS\` y código crudo PostgreSQL. |
| **Riesgo si se modifica** | **Medio**. Perder visualización métrica, pero no invalida operación directa. |
| **Pendiente principal** | Definir arquitectura estricta si Laravel debe absorber la lógica Jasper SQL legacy hacia Eloquent Resources limpios. |

---

### 8. Catálogos Maestros (Master Data)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Catálogos (UOM y Locaciones) |
| **Clasificación** | 🔵 SOPORTE (Fundamental) |
| **Objetivo de negocio** | Mantenimiento jerárquico de Unidades de Medida, factores de conversión, bodegas y terminales. |
| **Flujo funcional resumido** | Alta UOM Base ➔ Factor de Conversión `uom_conversion` a nivel de Ítem. |
| **Endpoints principales** | N/A (Consumido directamente). |
| **Componentes clave** | `UnitController`, `Livewire\Catalogs\*`. |
| **Elementos BD** | `selemti.unidades_medida`, `selemti.uom_conversion`, `v_bodega`. |
| **Lógica en Laravel** | Operaciones CRUD y listados dependientes asíncronos. |
| **Lógica en PostgreSQL** | - |
| **Estado** | Operativo total. |
| **Fuente de verdad** | Plantilla `D:\Tavo\2025\UX\Inventarios\MasterData...xlsx`. |
| **Riesgo si se modifica** | **Crítico**. Alterar factores de conversión derrumba compras y descuentos POS. |
| **Pendiente principal** | Integrar `ux/interface` definitiva robusta. |

---

### 9. Ruteo Global API y Legacy (Infraestructura)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Ruteo y Orquestación Backend |
| **Clasificación** | 🔴 LEGACY / HISTÓRICO |
| **Objetivo de negocio** | Transición entre la red legacy PHP plana (Slim) hacia el framework Laravel moderno (rutas API JSON). |
| **Flujo funcional resumido** | Requests URL `caja/precorte_create.php` ➔ Enrutador intercepta ➔ Inyecta clase Controladora Legacy. |
| **Endpoints principales** | Bloques `Route::prefix('legacy')` y `Closure` en `routes/api.php`. |
| **Componentes clave** | `routes/api.php`, `routes/web.php`. Controladores que exponen funciones duales (ej `createLegacy()`). |
| **Elementos BD** | N/A. |
| **Lógica en Laravel** | Intercepción de requests y parches `Closure` donde inyectan Servicios Complejos (`DailyCloseService`) directo en el route file. |
| **Lógica en PostgreSQL** | N/A. |
| **Estado** | Operativo, pero endeudado. |
| **Fuente de verdad** | Logs del `Octubre/Migracion_a_Laravel.txt`. |
| **Riesgo si se modifica** | **Medio-Alto**. Quiebra interconexión en hardware POS o clientes que no actualicen su API URIs. |
| **Pendiente principal** | Mudar lógica pesada inyectada en `<Closure>` hacia sus constructores `Controller` correspondientes. |

---

### 10. Caja Chica y Fondos (CashFund)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Caja Chica y Fondos |
| **Clasificación** | 🔵 SOPORTE FINANCIERO |
| **Objetivo de negocio** | Administrar retiros líquidos y gastos de forma paralela al Cajón de POS. |
| **Flujo funcional resumido** | Apertura de Fondo ➔ Aprobación ➔ Gasto/Retiro ➔ Arqueo. |
| **Endpoints principales** | UI Livewire `CashFund\Approvals`. |
| **Componentes clave** | `CashFundService`, `Models\CashFund`. |
| **Elementos BD** | `caja_fondo`, `caja_fondo_mov`, `caja_fondo_arqueo`. |
| **Lógica en Laravel** | Workflow duro de Máquina de Estados (En Revisión -> Cerrado). |
| **Lógica en PostgreSQL** | Persistencia estricta y logs raw (`cash_fund_movement_audit_log`). |
| **Estado** | Implementado. |
| **Fuente de verdad** | `docs/2026/04_MODULOS/CAJA_CHICA.md` |
| **Riesgo si se modifica** | **Alto**. Desajusta el balance líquido y fuga fondos del arqueo maestro. |
| **Pendiente principal** | Conciliación Deductiva contra el Postcorte de CAJA principal. |

---

### 11. Auditorías Físicas (Inventory Counts)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Auditorías Físicas |
| **Clasificación** | 🔵 CONTABLE / KARDEX |
| **Objetivo de negocio** | Asentar la realidad física en piso de almacén contra el teórico mermado. |
| **Flujo funcional resumido** | Sorteo de Ajuste ➔ Conteo Real ➔ Diferencial Sintético ➔ Inserción Movimiento. |
| **Endpoints principales** | Ocultos en CRUD Livewire / Inventory. |
| **Componentes clave** | `InventoryCount`, `InventoryCountLine`. |
| **Elementos BD** | `movimientos_inventario`. |
| **Lógica en Laravel** | Reglas de conciliación y validación de tolerancias de ajuste. |
| **Lógica en PostgreSQL** | Triggers y actualización de WAC / Existencia física final. |
| **Estado** | Implementado. |
| **Fuente de verdad** | `docs/2026/04_MODULOS/INVENTORY_COUNTS.md` |
| **Riesgo si se modifica** | **Crítico**. Encubre robos disfrazándolos de ajustes autorizados perdiendo el Food Cost. |
| **Pendiente principal** | Configurar obligatoriedad en jerarquías de Spatie (Permisos) al aprobar saldos grandes. |

---

### 12. Gobernanza, Seguridad y Bitácoras (Audit & Roles)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Gobernanza, Seguridad y Bitácoras |
| **Clasificación** | 🟣 NÚCLEO TRANSVERSAL |
| **Objetivo de negocio** | Someter y auditar rigurosamente las transacciones de API/Web bajo el esquema de Identidad empresarial. |
| **Flujo funcional resumido** | Validación Auth ➔ Permiso Spatie ➔ Ejecución ➔ RAW Insert inmutable (Auditoría). |
| **Endpoints principales** | Middlewares de Auth y Traits modelados. |
| **Componentes clave** | `CheckPermission`, `AuthServiceProvider`, `Models\AuditLog`. |
| **Elementos BD** | `selemti.audit_log`, esquema `Spatie` (permissions, roles). |
| **Lógica en Laravel** | Abstracción paramétrica web (`Spatie`), Tokens para API (`Sanctum`). |
| **Lógica en PostgreSQL** | Ejecutor ciego para salvaguardar el `audit_log` sin pasar por el ORM. |
| **Estado** | Implementado (Ejecución Silenciosa). |
| **Fuente de verdad** | `docs/2026/04_MODULOS/SEGURIDAD_Y_AUDITORIA.md` |
| **Riesgo si se modifica** | **Crítico**. Desactiva inadvertidamente la matriz de ciber-crimen contable y borrados sin custodia. |
| **Pendiente principal** | Diseñar una Guía y Matriz Visual Pública de los accesos reales por Cargo. |

---

### 13. Automatizaciones y Lotes (Batch Jobs)
| Columna / Atributo | Evidencia Técnica / Lógica Validada |
| :--- | :--- |
| **Módulo** | Automatizaciones y Lotes |
| **Clasificación** | 🔵 SOPORTE ASÍNCRONO |
| **Objetivo de negocio** | Calcular y sanear datos contables pesados fuera del horario operativo. |
| **Flujo funcional resumido** | Detonador SO Cron ➔ Console Schedule ➔ Query Background ➔ Log Ejecución. |
| **Endpoints principales** | N/A (Scripts CLI). |
| **Componentes clave** | `App\Models\Core\JobRecalculo`, `App\Models\Core\PerdidaLog`. |
| **Elementos BD** | Rutinas pasivas y agrupaciones asincrónicas en PostgreSQL. |
| **Lógica en Laravel** | Command Schedulers. |
| **Lógica en PostgreSQL** | Target final del barrido asíncrono. |
| **Estado** | Implementado. |
| **Fuente de verdad** | `docs/2026/04_MODULOS/AUTOMATIZACIONES_BATCH.md` |
| **Riesgo si se modifica** | **Medio**. Consecuencias asintomáticas (Pérdidas no logueadas oportunamente, Reportes sin caché de noche). |
| **Pendiente principal** | Levantar Interface View (Panel de Control) para visibilidad activa gerencial. |
