# Definición del Módulo: Transferencias

## Descripción General
El módulo de Transferencias gestiona los movimientos internos de inventario entre almacenes y sucursales. Permite solicitar, aprobar, enviar, recibir y postear transferencias con control completo de existencias y trazabilidad. El sistema implementa un flujo de 3 pasos con validaciones en cada etapa.

## Componentes del Módulo

### 1. Gestión de Transferencias
**Descripción:** Funcionalidad para crear, aprobar y gestionar transferencias entre almacenes.

**Características actuales:**
- Flujo 3 pasos: Borrador → Despachada (descuenta origen / prepara recibo) → Recibida (abona destino por lote)
- Confirmaciones parciales y discrepancias (corto/exceso)
- Botón "Recibir" en destino
- UI de "reconciliación" simple
- Integración con módulo de inventario para descuentos y abonos

**Requerimientos de UI/UX:**
- Crear transferencias entre almacenes/sucursales
- Aprobar transferencias con validación de existencias
- Marcar como enviada desde el almacén origen
- Registrar cantidades recibidas en destino
- Generar movimientos de inventario negativos/positivos
- Manejo de discrepancias (corto/exceso)
- Sistema de auditoría completo con registro de acciones

### 2. Estados del Flujo de Transferencias
**Descripción:** Sistema de estados que controla el flujo completo de una transferencia.

**Estados Implementados:**
- `SOLICITADA`: Transferencia creada pero pendiente de aprobación
- `APROBADA`: Aprobada y lista para ser enviada
- `EN_TRANSITO`: Marcada como enviada desde origen
- `RECIBIDA`: Recibida en destino con cantidades confirmadas
- `CERRADA`: Posteada a inventario con movimientos generados

**Requerimientos de UI/UX:**
- Visualización clara del estado actual
- Botones de acción contextual según estado
- Historial de cambios de estado
- Bloqueo de acciones no permitidas según estado

### 3. Control de Acciones
**Descripción:** Sistema de permisos y acciones específicas para cada etapa del flujo.

**Permisos Implementados:**
- `inventory.transfers.approve`: Aprobar transferencias
- `inventory.transfers.ship`: Marcar como enviada
- `inventory.transfers.receive`: Registrar recepción
- `inventory.transfers.post`: Postear a inventario

**Requerimientos de UI/UX:**
- Mostrar solo acciones permitidas según permisos del usuario
- Validar permisos antes de ejecutar cualquier acción
- Registrar quién realizó cada acción con timestamps
- Requerir motivo para operaciones críticas

### 4. Auditoría y Trazabilidad
**Descripción:** Sistema completo de registro de todas las acciones relacionadas con transferencias.

**Características actuales:**
- Registro automático de todas las acciones
- Quién hizo qué y cuándo
- Motivo de cada acción crítica
- Evidencia adjunta (cuando aplica)

**Requerimientos de UI/UX:**
- Timeline de eventos en detalle de transferencia
- Visualización de cambios realizados
- Posibilidad de adjuntar evidencia
- Requerir motivo para todas las acciones críticas

## Requerimientos Técnicos
- Servicio: TransferService con métodos para cada etapa del flujo
- Controlador: TransferController con endpoints RESTful
- Componentes Livewire: Transfers\Index, Transfers\Create
- Modelo: (pendiente de implementación completa)
- Tablas: (pendiente de creación) transfer_header, transfer_detail
- Integración con mov_inv para generar movimientos negativos/positivos
- Sistema de permisos basado en Spatie Permission
- Validaciones de existencias antes de aprobación/envío
- Manejo de discrepancias en recepción

## Integración con Otros Módulos
- Inventario: Descuento de existencias en origen, abono en destino
- Almacenes: Relación con orígenes y destinos de transferencias
- Sucursales: Control por ubicaciones
- Reportes: KPIs de transferencias y movimientos entre almacenes
- Auditoría: Registro de todas las acciones en audit_log

## KPIs Asociados
- Transferencias por estado
- Tiempo promedio entre estados
- Transferencias con discrepancias
- Transferencias completadas vs pendientes
- Transferencias por almacén origen/destino
- Valor total transferido
- Transferencias fuera de tolerancia

## Flujos de Trabajo

### Flujo Básico de Transferencia
1. **Creación**: Usuario crea transferencia (origen → destino)
2. **Aprobación**: Usuario autorizado aprueba la transferencia
3. **Envío**: Almacén origen marca como enviada
4. **Recepción**: Almacén destino registra cantidades recibidas
5. **Posteo**: Sistema genera movimientos de inventario y cierra transferencia

### Estados y Transiciones
```
SOLICITADA
   ↓ (aprobar)
APROBADA
   ↓ (enviar)
EN_TRANSITO
   ↓ (recibir)
RECIBIDA
   ↓ (postear)
CERRADA
```

## Componentes Técnicos

### Servicios
- **TransferService**: Lógica de negocio para transferencias
  - `createTransfer()`: Crea transferencia solicitada
  - `approveTransfer()`: Aprueba transferencia
  - `markInTransit()`: Marca como enviada
  - `receiveTransfer()`: Registra recepción
  - `postTransferToInventory()`: Postea a inventario

### Controladores
- **TransferController**: Endpoints REST para operaciones
  - `POST /api/inventory/transfers/create`
  - `POST /api/inventory/transfers/{transfer_id}/approve`
  - `POST /api/inventory/transfers/{transfer_id}/ship`
  - `POST /api/inventory/transfers/{transfer_id}/receive`
  - `POST /api/inventory/transfers/{transfer_id}/post`

### Componentes Livewire
- **Transfers\Index**: Listado de transferencias
- **Transfers\Create**: Creación de nuevas transferencias

### Vistas
- **resources/views/livewire/transfers/index.blade.php**: Listado de transferencias
- **resources/views/livewire/transfers/create.blade.php**: Creación de transferencias

## Pendientes de Implementación

### Backend
- [ ] Modelo completo de Transferencias
- [ ] Tablas en base de datos (transfer_header, transfer_detail)
- [ ] Validaciones de existencias
- [ ] Manejo de discrepancias
- [ ] Generación de movimientos en mov_inv

### Frontend
- [ ] Vista de detalle de transferencia
- [ ] Componentes de edición/actualización
- [ ] Sistema de notificaciones
- [ ] Validaciones en formularios
- [ ] Responsive design completo

### Integración
- [ ] Conexión con servicios de inventario
- [ ] Pruebas de flujo completo
- [ ] Manejo de errores
- [ ] Logging y auditoría