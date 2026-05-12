# 📦 MÓDULO: Caja Chica y Fondos Operativos (CashFunds)

> **Clasificación:** CONTROL FINANCIERO (Transversal cruzado con Caja Principal)  
> **Estado:** Implementado (Y activo en Workflow de Livewire)  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** PostgreSQL (`caja_fondo`, `caja_fondo_mov`) gobernado por Livewire UI.

---

## 1. Misión Funcional
Dotar de liquidez inmediata a las sucursales para erogaciones menudas o gastos de emergencia (Caja Chica) sin comprometer las utilidades de venta directa del POS, manteniendo una trazabilidad del usuario autorizante, el cajero responsable y el arqueo/viabilidad final del fondo.

## 2. Resumen Operativo Rápido
- **UI principal:** `App\Livewire\CashFund\Approvals.php` y Componentes Front.
- **Controller / Service central:** `App\Services\Cash\CashFundService.php`.
- **Base de modelos:** `CashFund`, `CashFundMovement`, `CashFundArqueo`.
- **Fuente de verdad en PGSQL:** Tablas base `caja_fondo`, `caja_fondo_mov`, `caja_fondo_usuario`.
- **Dependencia crítica:** Usuarios (Roles de Aprobación) y CAJA MAESTRA.
- **Pendiente prioritario:** Conciliación explícita (Deductiva) entre el Arqueo de un fondo exhausto contra la liquidación final del Postcorte de un Supervisor.

---

## 3. Flujo Funcional
El Workflow difiere dramáticamente del flujo comercial POS:
`Fondo Solicitado → Estado (EN_REVISION) → Supervisor Aprueba (Livewire Approvals) → Fondo Activo/Depositado → Registros de Movimientos (Retiros / Aportes / Gastos) → Corte/Arqueo de Fondo Parcial → Cierre Definitivo (CERRADO).`

## 4. Mapa Tecnológico Canónico
- **Servicios:** Contiene el `CashFundService` orquestando las inyecciones de ID y los cierres de tabla relacional.
- **Micro-Logs:** Cuenta con una pista de auditoría pasiva única: `CashFundMovementAuditLog` para retener intervenciones indebidas en los gastos aplicados.

## 5. Contrato de Datos / Reglas Base de Datos
- **Asignación Nominal:** Los fondos no pertenecen a una "Caja Genérica". Se vinculan nominalmente mediante `caja_fondo_usuario` al cajero / gerente asignado, rindiendo cuentas exclusivas por ID.
- **Integridad Referencial:** Un `CashFundArqueo` sella definitivamente los saldos de los `caja_fondo_mov` hijos asociados a su parent ID (`caja_fondo_id`).

## 6. Fuente de Verdad Real
**PostgreSQL Centralizado:** La inserción directa a nivel Service ejecuta sentencias crudas/builders en Postgres para salvaguardar el performance, pero el peso del _State-Machine_ (estados EnRevisión → Activo) recae directamente en el controlador visual de Livewire.

## 7. Dependencias con Otros Módulos
- **Depende de:**
  - **SEGURIDAD_Y_AUDITORIA (Identidad):** Verifica los Spatie Roles para desbloquear el Componente `Approvals.php`.
- **Impacta a:**
  - **CAJA (Virtualmente):** Un gasto autorizado en el mundo de Caja Chica, si fue extraído del Drawer original del turno, significa un "Faltante Fiscal Acordado". Si CAJA no lo sabe asimilar, detona diferencias netas.

## 8. Estado Real Desglosado
- **Nivel de Confianza Documental:** Medio. Documentado arduamente en Histórico (`docs/00.history/CajaChica`) pero extraviado en el censo operativo actual 2026.
- **Implementado:** Sí. A nivel código sólido en Backend y Livewire.
- **Módulo Legacy:** Se rescataron archivos paralelos (`FIX_SESION_CAJON_ESTATUS_CHECK.sql`) probando iteraciones previas intensas.

## 9. Problemas Conocidos / Bugs / Alertas Críticas
- **Aislamiento Contable (Silo):** El fondo corre su propio riel por Livewire, desconectado temporalmente del *Termómetro Central* (Módulo Reportes).

## 10. Riesgos si se Modifica
Intervenir el `CashFundService` sin cautela compromete el enrutado a su sub-tabla de auditoría (`CashFundMovementAuditLog`). Perderemos el rastro de la corrupción interna (ej. si cambian el valor de un Gasto Operativo ya aprobado).
