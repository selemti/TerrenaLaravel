# Definición del Módulo: Caja Chica

## Descripción General
El módulo de Caja Chica (Fondo de Caja) gestiona las operaciones financieras diarias, incluyendo apertura y cierre de cajas, movimientos de efectivo, arqueos y conciliaciones. Es fundamental para el control de efectivo en operaciones diarias. El sistema implementa un control exhaustivo sobre fondos diarios asignados para gastos menores y pagos a proveedores en sucursales de restaurantes.

## Componentes del Módulo

### 1. Apertura y Cierre de Caja
**Descripción:** Funcionalidad para abrir y cerrar cajas diarias con control de fondos iniciales.

**Características actuales:**
- Flujo de apertura de cajas
- Panel de cajas con excepciones
- Sistema de fondos diarios asignados a usuarios

**Requerimientos de UI/UX:**
- Wizard de apertura de caja con fondos iniciales
- Control de fondos iniciales por denominaciones
- Seguimiento de movimientos durante el turno
- Pre-cierre con verificación de fondos
- Asignación de responsable del fondo
- Descripción opcional para identificación
- Control por sucursal y fecha

### 2. Movimientos de Caja
**Descripción:** Registro y control de entradas y salidas de efectivo.

**Características actuales:**
- Tipos de movimientos: EGRESO, REINTEGRO, DEPOSITO
- Aprobación para movimientos sin comprobante
- Métodos de pago: Efectivo y Transferencia

**Requerimientos de UI/UX:**
- Formulario para registrar diferentes tipos de movimientos
- Adjunto de comprobantes para movimientos (PDF, imágenes)
- Flujo de aprobación para movimientos sin comprobante
- Categorización de movimientos
- Información de proveedor
- Edición y eliminación con auditoría
- Requerimiento de comprobante con opción de "POR_APROBAR"

### 3. Arqueo de Caja
**Descripción:** Proceso de conteo físico de efectivo y conciliación con sistema.

**Características actuales:**
- Precorte por denominaciones
- Panel de cajas con excepciones
- Sistema de estados (ABIERTO → EN_REVISION → CERRADO)

**Requerimientos de UI/UX:**
- Wizard de arqueo detallado por denominaciones
- Comparación automática con saldo teórico
- Registro de diferencias (faltantes/sobrantes) y justificaciones
- Adjunto de evidencia del conteo físico
- Cálculo automático de diferencias
- Observaciones y justificaciones

### 4. Conciliación y Aprobación
**Descripción:** Proceso de validación, revisión y cierre de operaciones de caja.

**Características actuales:**
- Panel de excepciones
- Conciliación parcial
- Estados: ABIERTO → EN_REVISION → CERRADO

**Requerimientos de UI/UX:**
- Wizard de cierre con checklist de verificación
- Adjunto de evidencia (foto de arqueo)
- Reglas de excepción parametrizables
- Autorizaciones para diferencias
- Estado EN_REVISION después del arqueo
- Revisión por usuarios autorizados
- Aprobación con validaciones
- Posibilidad de rechazar y reabrir
- Cierre definitivo (estado CERRADO)
- Solo lectura en estado CERRADO

### 5. Sistema de Auditoría
**Descripción:** Registro y seguimiento de todos los cambios y movimientos.

**Características actuales:**
- Tabla de auditoría: cash_fund_movement_audit_log
- Registro automático de cambios

**Requerimientos de UI/UX:**
- Registro automático de todos los cambios
- Historial detallado por movimiento
- Trazabilidad completa (quién, cuándo, qué cambió)
- Valores anteriores y nuevos
- Timeline de eventos

### 6. Vista de Detalle Completa
**Descripción:** Información completa del fondo con todos sus movimientos y estados.

**Características actuales:**
- Componente Livewire Detail
- Información general del fondo

**Requerimientos de UI/UX:**
- Información general del fondo
- Resumen financiero
- Tabla de movimientos
- Resultado del arqueo
- Timeline de eventos
- Formato de impresión profesional
- Formato tipo estado de cuenta bancario
- Header con logo y datos del fondo
- Tabla optimizada para papel
- Resumen financiero destacado
- Footer con fecha de generación
- Optimizado para papel tamaño letter

## Requerimientos Técnicos
- Modelos: CashFund, CashFundMovement, CashFundArqueo, CashFundMovementAuditLog
- Tablas: cash_fund, cash_fund_movements, cash_fund_arqueos, cash_fund_movement_audit_log
- Componentes Livewire: Index, Open, Movements, Arqueo, Approvals, Detail
- Sistema de archivos adjuntos en storage/app/public/cash_fund_attachments
- Sistema de validación y autorización con Spatie Permissions
- Transacciones de BD para operaciones críticas
- Sistema de auditoría completo

## Integración con Otros Módulos
- Permisos: Control de acceso según roles con Spatie Permissions
- Reportes: Movimientos de caja, excepciones
- Catálogos: Proveedores, sucursales
- Producción: Posible financiamiento para materiales de producción

## KPIs Asociados
- Diferencia entre teórico y físico
- Número de excepciones por cierre
- Movimientos sin comprobante
- Total de ingresos/egresos por periodo
- Desviación de fondos iniciales
- Tiempo promedio de cierre de caja
- % egresos sin comprobante y tiempos de aprobación
- Diferencias de arqueo por día/usuario
- Tasa de comprobación de movimientos
- Fondos cerrados vs. fondos abiertos