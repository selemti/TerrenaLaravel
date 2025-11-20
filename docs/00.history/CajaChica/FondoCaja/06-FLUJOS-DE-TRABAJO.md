# 06 - FLUJOS DE TRABAJO Y CASOS DE USO

## 📋 Flujo Completo del Día

### **Día Normal (Sin Problemas)**

```
08:00 - APERTURA
   └─→ Gerente abre fondo con $5,000 MXN

09:00-17:00 - OPERACIÓN
   ├─→ Egreso #1: Compra verduras $250
   ├─→ Egreso #2: Pago proveedor pan $450
   ├─→ Egreso #3: Taxi emergencia $120
   ├─→ Reintegro #1: Devolución cambio $50
   └─→ Total: $5,000 - $820 + $50 = $4,230

18:00 - ARQUEO
   ├─→ Saldo teórico: $4,230
   ├─→ Efectivo contado: $4,230
   └─→ Diferencia: $0 ✅ CUADRA

18:30 - REVISIÓN
   ├─→ Supervisor revisa movimientos
   ├─→ Verifica comprobantes
   └─→ Estado: EN_REVISION

19:00 - CIERRE
   ├─→ Supervisor aprueba
   └─→ Estado: CERRADO ✅
```

---

## 🔄 Casos de Uso Detallados

### **CU-01: Apertura de Fondo**

**Actor:** Gerente/Cajero Principal
**Precondiciones:** Usuario autenticado
**Flujo Principal:**

1. Usuario navega a "Caja → Caja Chica"
2. Click en "Abrir fondo"
3. Selecciona sucursal
4. Ingresa fecha (default: hoy)
5. Selecciona responsable
6. [Opcional] Ingresa descripción
7. Ingresa monto inicial
8. Selecciona moneda (MXN/USD)
9. Click "Abrir fondo"
10. Sistema valida datos
11. Sistema crea registro en BD
12. Sistema redirige a pantalla de movimientos
13. Estado: ABIERTO

**Postcondiciones:**
- Fondo creado en estado ABIERTO
- Responsable asignado
- Listo para registrar movimientos

**Excepciones:**
- E1: Fecha futura → Error "La fecha no puede ser futura"
- E2: Monto <= 0 → Error "El monto debe ser mayor a cero"
- E3: Sin responsable → Error "Selecciona un responsable"

---

### **CU-02: Registrar Egreso**

**Actor:** Responsable del fondo
**Precondiciones:** Fondo en estado ABIERTO
**Flujo Principal:**

1. Usuario en pantalla de movimientos
2. Click "Registrar egreso"
3. Selecciona tipo: EGRESO
4. Ingresa concepto: "Compra de verduras"
5. Ingresa nombre proveedor: "Verdulería El Huerto"
6. Ingresa monto: $250.50
7. Selecciona método: EFECTIVO
8. [Opcional] Adjunta comprobante (PDF/imagen)
9. Click "Guardar"
10. Sistema valida datos
11. Sistema crea movimiento
12. Sistema registra en auditoría
13. Sistema guarda archivo (si hay)
14. Sistema actualiza saldo disponible
15. Sistema muestra toast de éxito

**Postcondiciones:**
- Movimiento registrado
- Saldo disponible actualizado
- Auditoría registrada
- Archivo guardado (si aplica)

**Excepciones:**
- E1: Monto > saldo disponible → Advertencia (permite continuar)
- E2: Sin concepto → Error "El concepto es obligatorio"
- E3: Archivo > 10MB → Error "El archivo es muy grande"

---

### **CU-03: Editar Movimiento**

**Actor:** Responsable del fondo
**Precondiciones:**
- Fondo en estado ABIERTO
- Movimiento existe

**Flujo Principal:**

1. Usuario click ícono "editar" en movimiento
2. Sistema abre modal con datos actuales
3. Usuario modifica campo(s)
4. Click "Guardar cambios"
5. Sistema valida cambios
6. Para cada campo modificado:
   a. Sistema registra en auditoría (old_value, new_value)
7. Sistema actualiza movimiento
8. Sistema cierra modal
9. Sistema actualiza lista
10. Sistema muestra toast de éxito

**Postcondiciones:**
- Movimiento actualizado
- Cada cambio registrado en auditoría
- Saldo recalculado si cambió monto

**Excepciones:**
- E1: Fondo ya no está ABIERTO → Error "No se puede editar"
- E2: Validación falla → Mostrar errores específicos

---

### **CU-04: Eliminar Movimiento**

**Actor:** Responsable del fondo
**Precondiciones:**
- Fondo en estado ABIERTO
- Movimiento existe

**Flujo Principal:**

1. Usuario click ícono "eliminar" en movimiento
2. Sistema muestra modal de confirmación
3. Usuario confirma eliminación
4. Sistema registra en auditoría acción DELETED
5. Sistema elimina archivo adjunto (si existe)
6. Sistema elimina movimiento
7. Sistema actualiza saldo
8. Sistema muestra toast de éxito

**Postcondiciones:**
- Movimiento eliminado
- Archivo eliminado
- Auditoría registrada
- Saldo recalculado

---

### **CU-05: Gestionar Comprobante**

**Actor:** Responsable del fondo
**Precondiciones:**
- Fondo en estado ABIERTO
- Movimiento existe

**Flujo Añadir:**

1. Usuario click ícono "adjuntar"
2. Sistema abre modal
3. Usuario selecciona archivo
4. Click "Subir"
5. Sistema valida archivo (tipo, tamaño)
6. Sistema guarda en `/storage/app/public/cash_fund_attachments/{fondo_id}/{movement_id}/`
7. Sistema actualiza `adjunto_path` y `tiene_comprobante = true`
8. Sistema registra en auditoría ATTACHMENT_ADDED
9. Sistema muestra toast de éxito

**Flujo Reemplazar:**

1. Usuario click "Cambiar comprobante"
2. Sistema muestra advertencia
3. Usuario confirma
4. Usuario selecciona nuevo archivo
5. Sistema elimina archivo anterior
6. Sistema guarda nuevo archivo
7. Sistema actualiza `adjunto_path`
8. Sistema registra en auditoría ATTACHMENT_REPLACED
9. Sistema muestra toast de éxito

**Flujo Eliminar:**

1. Usuario click "Eliminar comprobante"
2. Sistema muestra confirmación
3. Usuario confirma
4. Sistema elimina archivo físico
5. Sistema actualiza `adjunto_path = null`, `tiene_comprobante = false`
6. Sistema registra en auditoría ATTACHMENT_REMOVED
7. Sistema muestra toast de éxito

---

### **CU-06: Realizar Arqueo**

**Actor:** Responsable del fondo
**Precondiciones:**
- Fondo en estado ABIERTO
- Fin del día/turno

**Flujo Principal:**

1. Usuario click "Realizar Arqueo"
2. Sistema muestra pantalla de arqueo
3. Sistema calcula saldo teórico:
   - Saldo = monto_inicial - total_egresos + total_reintegros
4. Sistema muestra resumen de movimientos
5. Usuario cuenta efectivo físico
6. Usuario ingresa "Efectivo contado": $4,228.50
7. Sistema calcula diferencia en tiempo real: -$1.50
8. [Opcional] Usuario ingresa observaciones: "Falta moneda de 50¢ y billete de $1"
9. Sistema muestra advertencia si hay diferencia
10. Usuario click "Confirmar y cerrar"
11. Sistema muestra modal de confirmación
12. Usuario confirma
13. Sistema crea/actualiza registro en `cash_fund_arqueos`
14. Sistema cambia estado del fondo a EN_REVISION
15. Sistema redirige a movimientos
16. Sistema muestra mensaje de éxito

**Postcondiciones:**
- Arqueo registrado
- Estado: EN_REVISION
- Fondo bloqueado para edición

**Excepciones:**
- E1: Diferencia muy grande (>$500) → Advertencia adicional
- E2: No hay movimientos → Advertencia "¿Estás seguro?"

---

### **CU-07: Rechazar Fondo (Reabrir)**

**Actor:** Supervisor/Gerente (con permiso)
**Precondiciones:**
- Usuario tiene permiso `approve-cash-funds`
- Fondo en estado EN_REVISION

**Flujo Principal:**

1. Usuario navega a "Aprobaciones"
2. Sistema muestra fondos EN_REVISION
3. Usuario selecciona fondo
4. Sistema muestra detalle completo
5. Usuario identifica error/faltante
6. Click "Rechazar y reabrir"
7. Sistema abre modal
8. Usuario ingresa motivo: "Falta comprobante del egreso #3"
9. Click "Confirmar rechazo"
10. Sistema cambia estado a ABIERTO
11. Sistema cierra modal
12. Sistema actualiza lista
13. Sistema muestra toast "Fondo reabierto"

**Postcondiciones:**
- Estado: ABIERTO
- Responsable puede editar nuevamente

**Flujo Alternativo:**
- Responsable recibe notificación (futuro)
- Responsable corrige errores
- Vuelve a realizar arqueo

---

### **CU-08: Aprobar y Cerrar Fondo**

**Actor:** Supervisor/Gerente (con permiso)
**Precondiciones:**
- Usuario tiene permisos `approve-cash-funds` y `close-cash-funds`
- Fondo en estado EN_REVISION
- Todos los movimientos tienen comprobante O están justificados

**Flujo Principal:**

1. Usuario navega a "Aprobaciones"
2. Sistema muestra fondos EN_REVISION
3. Usuario selecciona fondo
4. Sistema muestra detalle completo:
   - Movimientos
   - Comprobantes
   - Resultado de arqueo
5. Usuario revisa cada movimiento
6. Usuario verifica comprobantes
7. Click "Aprobar y cerrar definitivamente"
8. Sistema valida movimientos pendientes
9. Sistema muestra modal de confirmación
10. Usuario confirma
11. Sistema actualiza en transacción:
    a. Estado del fondo → CERRADO
    b. closed_at → now()
    c. Estatus de movimientos → APROBADO
12. Sistema cierra modal
13. Sistema muestra toast "Fondo cerrado exitosamente"

**Postcondiciones:**
- Estado: CERRADO
- closed_at registrado
- Todos los movimientos APROBADO
- Solo lectura permanente

**Excepciones:**
- E1: Hay movimientos sin comprobante → Error detallado
- E2: Usuario no tiene permiso `close-cash-funds` → Error 403

---

### **CU-09: Ver Historial de Auditoría**

**Actor:** Cualquier usuario con acceso
**Precondiciones:** Movimiento existe

**Flujo Principal:**

1. Usuario click ícono "historial" en movimiento
2. Sistema abre modal de auditoría
3. Sistema carga registros de `cash_fund_movement_audit_log`
4. Sistema muestra tabla cronológica inversa:
   - Fecha/hora
   - Usuario que hizo el cambio
   - Acción (CREATED, UPDATED, DELETED, etc.)
   - Campo modificado
   - Valor anterior
   - Valor nuevo
   - Observaciones
5. Usuario revisa cambios
6. Usuario cierra modal

**Ejemplo de Visualización:**
```
23/10/2025 14:35 - Juan Pérez
  UPDATED: monto
  $100.00 → $150.00
  "Corrección de monto según nueva factura"

23/10/2025 09:15 - Juan Pérez
  CREATED
  "Movimiento creado exitosamente"
```

---

## 🔄 Diagrama de Estados del Fondo

```
    [INICIO]
       │
       ↓
  ┌─────────┐
  │ ABIERTO │◄────────────┐
  └─────────┘             │
       │                  │
       │ Realizar Arqueo  │
       ↓                  │
  ┌──────────────┐        │
  │ EN_REVISION  │        │
  └──────────────┘        │
       │     │            │
       │     └── Rechazar ┘
       │
       │ Aprobar
       ↓
  ┌─────────┐
  │ CERRADO │ (Final)
  └─────────┘
```

---

## 📊 Métricas y Reportes (Futuro)

### Reportes Sugeridos

1. **Reporte Diario:**
   - Fondos abiertos hoy
   - Total egresos
   - Total reintegros
   - Saldos disponibles

2. **Reporte Semanal:**
   - Fondos por sucursal
   - Promedio de egresos
   - Diferencias en arqueos
   - Movimientos sin comprobante

3. **Reporte Mensual:**
   - Total movido en el mes
   - Proveedores más frecuentes
   - Usuarios responsables
   - Tendencias

---

## ⚠️ Escenarios de Excepción

### **Escenario 1: Fondo con Saldo Negativo**

**Situación:** Total de egresos > monto inicial + reintegros

**Acciones:**
1. Sistema permite continuar (no bloquea)
2. Sistema muestra advertencia visual (saldo en rojo)
3. Usuario puede registrar reintegro para cubrir
4. Al arquear, la diferencia será negativa (faltante)
5. Supervisor debe justificar al aprobar

**Recomendación:** Siempre realizar reintegros cuando el saldo se acerque a cero.

---

### **Escenario 2: Pérdida de Comprobante Físico**

**Situación:** Movimiento sin comprobante digital

**Acciones:**
1. Registrar movimiento normalmente
2. Marcar `tiene_comprobante = false`
3. En arqueo, sistema advierte sobre movimientos sin comprobante
4. Al enviar a revisión, supervisor ve alerta
5. Supervisor puede:
   a. Rechazar y solicitar comprobante
   b. Aprobar con justificación escrita

---

### **Escenario 3: Diferencia en Arqueo**

**Diferencia Pequeña (<$10):**
- Anotar en observaciones
- Continuar normalmente
- Supervisor evaluará

**Diferencia Media ($10-$100):**
- Revisar cuidadosamente movimientos
- Verificar cálculos
- Justificar diferencia
- Supervisor puede solicitar recuento

**Diferencia Grande (>$100):**
- STOP: No continuar
- Revisar exhaustivamente
- Verificar no haya movimientos faltantes
- Contactar supervisor antes de arquear
- Documentar detalladamente

---

## 📱 Flujo Mobile (PWA Futuro)

```
1. Abrir app PWA
2. Escanear QR del fondo actual
3. Registrar egreso rápido
4. Tomar foto de factura
5. Auto-upload
6. Confirmación instantánea
```
