# Definición del Módulo: Transferencias

## Descripción General
El módulo de Transferencias gestiona los movimientos internos de inventario entre almacenes y sucursales. Permite solicitar, aprobar, enviar, recibir y postear transferencias con control completo de existencias y trazabilidad. El sistema implementa un flujo de 3 pasos con validaciones en cada etapa y cumple con los principios de control de inventario.

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

**Características actuales:**
- Estados: BORRADOR → APROBADA → EN_TRANSITO → RECIBIDA → CERRADA
- Validación de estados antes de permitir transiciones
- Bloqueo de ediciones en estados posteriores

**Requerimientos de UI/UX:**
- Visualización clara del estado actual
- Botones de acción contextual según estado
- Historial de cambios de estado
- Bloqueo de acciones no permitidas según estado
- Indicadores visuales de progreso

### 3. Control de Acciones
**Descripción:** Sistema de permisos y acciones específicas para cada etapa del flujo.

**Características actuales:**
- Permisos granulares: `inventory.transfers.approve`, `inventory.transfers.ship`, `inventory.transfers.receive`, `inventory.transfers.post`
- Middleware de autenticación en controladores
- Validación de permisos en cada endpoint

**Requerimientos de UI/UX:**
- Mostrar solo acciones permitidas según permisos del usuario
- Validar permisos antes de ejecutar cualquier acción
- Registrar quién realizó cada acción con timestamps
- Requerir motivo para operaciones críticas
- Adjuntar evidencia para operaciones críticas

### 4. Auditoría y Trazabilidad
**Descripción:** Sistema completo de registro de todas las acciones relacionadas con transferencias.

**Características actuales:**
- Registro automático de todas las acciones en `audit_log`
- Quién hizo qué y cuándo
- Motivo de cada acción crítica
- Evidencia adjunta (cuando aplica)

**Requerimientos de UI/UX:**
- Timeline de eventos en detalle de transferencia
- Visualización de cambios realizados
- Posibilidad de adjuntar evidencia
- Requerir motivo para todas las acciones críticas
- Vista de historial de movimientos

## Requerimientos Técnicos
- Servicio: TransferService con métodos para cada etapa del flujo
- Controlador: TransferController con endpoints RESTful
- Componentes Livewire: Transfers\Index, Transfers\Create
- Modelo: TransferHeader, TransferDetail (pendientes de implementación completa)
- Tablas: transfer_header, transfer_detail, transfer_log
- Integración con mov_inv para generar movimientos negativos/positivos
- Sistema de permisos basado en Spatie Permission
- Validaciones de existencias antes de aprobación/envío
- Manejo de discrepancias en recepción
- Endpoints: 
  - `POST /api/inventory/transfers/create`
  - `POST /api/inventory/transfers/{transfer_id}/approve`
  - `POST /api/inventory/transfers/{transfer_id}/ship`
  - `POST /api/inventory/transfers/{transfer_id}/receive`
  - `POST /api/inventory/transfers/{transfer_id}/post`

## Integración con Otros Módulos
- Inventario: Descuento de existencias en origen, abono en destino
- Almacenes: Relación con orígenes y destinos de transferencias
- Sucursales: Control por ubicaciones
- Reportes: KPIs de transferencias y movimientos entre almacenes
- Auditoría: Registro de todas las acciones en audit_log
- Permisos: Control de acceso basado en Spatie Permission

## KPIs Asociados
- Transferencias por estado
- Tiempo promedio entre estados
- Transferencias con discrepancias
- Transferencias completadas vs pendientes
- Transferencias por almacén origen/destino
- Valor total transferido
- Transferencias fuera de tolerancia
- Incidencias por tipo de discrepancia
- Tasa de éxito en primera recepción
- Tiempo promedio de ciclo (solicitud a cierre)

## Flujos de Trabajo

### Flujo Básico de Transferencia
1. **Creación**: Usuario crea transferencia (origen → destino)
2. **Aprobación**: Usuario autorizado aprueba la transferencia
3. **Envío**: Almacén origen marca como enviada
4. **Recepción**: Almacén destino registra cantidades recibidas
5. **Posteo**: Sistema genera movimientos de inventario y cierra transferencia

### Estados y Transiciones
```
BORRADOR
   ↓ (aprobar)
APROBADA
   ↓ (enviar)
EN_TRANSITO
   ↓ (recibir)
RECIBIDA
   ↓ (postear)
CERRADA
```

### Validaciones por Estado
- **BORRADOR**: Solo puede ser aprobada o eliminada
- **APROBADA**: Solo puede ser enviada o rechazada
- **EN_TRANSITO**: Solo puede ser recibida
- **RECIBIDA**: Solo puede ser posteada o rechazada
- **CERRADA**: Solo lectura, no se permiten modificaciones

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

### Modelos (Pendientes de Implementación Completa)
- **TransferHeader**: Cabecera de transferencias
- **TransferDetail**: Detalle de líneas de transferencia
- **TransferLog**: Registro de auditoría de transferencias

### Componentes Livewire
- **Transfers\Index**: Listado de transferencias
- **Transfers\Create**: Creación de nuevas transferencias

### Vistas
- **resources/views/livewire/transfers/index.blade.php**: Listado de transferencias
- **resources/views/livewire/transfers/create.blade.php**: Creación de transferencias
- **resources/views/transfers/**: Vistas estáticas relacionadas

## Permisos y Roles

### Permisos Específicos
- `inventory.transfers.approve`: Aprobar transferencias
- `inventory.transfers.ship`: Marcar como enviada
- `inventory.transfers.receive`: Registrar recepción
- `inventory.transfers.post`: Postear a inventario
- `inventory.transfers.view`: Ver transferencias
- `inventory.transfers.create`: Crear transferencias
- `inventory.transfers.manage`: Gestionar transferencias (crear/editar)

### Roles Sugeridos
- **Almacenista Origen**: `inventory.transfers.ship`, `inventory.transfers.view`
- **Almacenista Destino**: `inventory.transfers.receive`, `inventory.transfers.view`
- **Supervisor de Almacén**: `inventory.transfers.approve`, `inventory.transfers.post`, `inventory.transfers.manage`
- **Gerente de Operaciones**: `inventory.transfers.*`
- **Auditor**: `inventory.transfers.view`

## Consideraciones Especiales

### Manejo de Discrepancias
- Registrar corto/exceso en recepción
- Justificación obligatoria para discrepancias > 5%
- Generación automática de ajustes para diferencias
- Alertas para discrepancias recurrentes

### Trazabilidad Completa
- Registro de quién realizó cada acción
- Timestamp preciso de cada operación
- Motivo obligatorio para acciones críticas
- Evidencia digital adjunta (fotos, documentos)
- Historial completo de cambios en líneas

### Validaciones Críticas
- Verificación de existencias antes de aprobación
- Bloqueo de ediciones en estados avanzados
- Validación de permisos en cada acción
- Control de concurrencia (bloqueo de registros en edición)
- Prevención de transferencias circulares

### Integración con Inventario
- Generación automática de movimientos en `mov_inv`
- Movimiento negativo en origen (TRANSFER_OUT)
- Movimiento positivo en destino (TRANSFER_IN)
- Actualización de existencias en tiempo real
- Validación de lotes y caducidades

## Próximos Pasos

### Implementaciones Pendientes
1. Completar modelos TransferHeader y TransferDetail
2. Crear tablas transfer_header, transfer_detail, transfer_log
3. Implementar validaciones de existencias
4. Completar UI de detalle de transferencia
5. Agregar funcionalidad de búsqueda y filtros avanzados
6. Implementar sistema de notificaciones
7. Agregar reportes específicos de transferencias
8. Completar pruebas de integración

### Mejoras Sugeridas
1. Transferencias parciales
2. Transferencias programadas
3. Transferencias masivas
4. Integración con dispositivos móviles
5. Escaneo de códigos de barras
6. Notificaciones push
7. Dashboard de KPIs en tiempo real
8. Exportación de reportes