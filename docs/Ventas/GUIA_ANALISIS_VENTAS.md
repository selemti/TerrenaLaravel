# 🔬 Sistema de Análisis y Corrección de Discrepancias en Ventas

## 📋 Descripción

Este sistema permite **detectar y corregir automáticamente** las discrepancias entre los Drawer Pull Reports y los datos reales en la base de datos.

**Problemas que detecta:**
1. ✅ Tickets con descuento 100% mal registrados (`total_price = $0`)
2. ✅ Descuentos registrados pero NO aplicados en pagos
3. ✅ Tickets abiertos sin pagar con datos inconsistentes
4. ✅ Comparación Drawer Pull Reports vs BD Real

---

## 🚀 Comandos Disponibles

### 1. **Analizar Discrepancias** (Solo Lectura)

```bash
# Analizar mes anterior (por defecto)
php artisan ventas:analizar-discrepancias

# Analizar un mes específico
php artisan ventas:analizar-discrepancias --mes=2025-10

# Analizar un rango de fechas
php artisan ventas:analizar-discrepancias --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31

# Ver detalles de tickets problemáticos
php artisan ventas:analizar-discrepancias --mes=2025-10 --detalle

# Exportar resultados a JSON
php artisan ventas:analizar-discrepancias --mes=2025-10 --exportar --detalle
```

**Salida esperada:**
```
╔═══════════════════════════════════════════════════════════════════╗
║   🔬 ANÁLISIS DE DISCREPANCIAS EN VENTAS - DRAWER PULL vs BD    ║
╚═══════════════════════════════════════════════════════════════════╝

📅 Período de análisis: 2025-10-01 a 2025-10-31

⏳ Analizando tickets con descuento 100%... ✔
⏳ Analizando discrepancias pago vs neto... ✔
⏳ Analizando tickets abiertos... ✔
⏳ Comparando Drawer Pull Reports vs BD... ✔

╔═══════════════════════════════════════════════════════════════════╗
║                        📊 RESULTADOS                              ║
╚═══════════════════════════════════════════════════════════════════╝

🚨 PROBLEMA #1: Tickets con Descuento 100% Mal Registrados
   Total tickets afectados: 34
   Total descuentos fantasma: $2,145.00

⚠️  PROBLEMA #2: Descuentos NO Aplicados en Pagos
   Total tickets afectados: 127
   Total sobrecobros: $2,870.40

📋 PROBLEMA #3: Tickets Abiertos sin Pagar
   Total tickets abiertos: 39
   Total price acumulado: $993.00
   Total descuentos: $1,738.00
   Neto pendiente: -$745.00

💰 IMPACTO FINANCIERO TOTAL:
   Descuentos fantasma (reportados incorrectamente): $2,145.00
   Sobrecobros (descuentos no aplicados): $2,870.40
   Tickets sin cobrar: -$745.00
   ─────────────────────────────────────────────
   TOTAL DISCREPANCIAS: $5,760.40
```

**Archivo exportado:** `storage/app/analisis_ventas/analisis_ventas_2025-10-01_a_2025-10-31_TIMESTAMP.json`

---

### 2. **Ver Preview de Tickets a Corregir** (Sin Modificar BD)

```bash
# Ver qué se va a corregir (octubre)
php artisan ventas:corregir-tickets preview --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31

# Ver solo un ticket específico
php artisan ventas:corregir-tickets preview --ticket-id=15246
```

**Salida esperada:**
```
╔═══════════════════════════════════════════════════════════════════╗
║          🔧 CORRECCIÓN DE TICKETS PROBLEMÁTICOS                   ║
╚═══════════════════════════════════════════════════════════════════╝

📅 Período: 2025-10-01 a 2025-10-31

🚨 TICKETS CON DESCUENTO 100% (total_price = 0):
   Total: 34

┌─────┬────────────┬──────────────┬───────────┬────────┬────────────────────────────────┐
│ ID  │ Fecha      │ Total Price  │ Descuento │ Items  │ Acción Sugerida                │
├─────┼────────────┼──────────────┼───────────┼────────┼────────────────────────────────┤
│ 975 │ 2025-10-15 │ $0           │ $303      │ $303   │ Restaurar total_price = $303   │
│ 712 │ 2025-10-08 │ $0           │ $233      │ $233   │ Restaurar total_price = $233   │
│ 187 │ 2025-10-03 │ $0           │ $73       │ $0     │ Anular (voided = TRUE)         │
└─────┴────────────┴──────────────┴───────────┴────────┴────────────────────────────────┘
   ... y 31 más

📋 TICKETS ABIERTOS SIN PAGAR:
   Total: 39
   
┌─────┬────────────┬────────────┬────────┬────────┬────────┬──────────────┐
│ ID  │ Creación   │ Cierre     │ Total  │ Desc   │ Neto   │ Acción       │
├─────┼────────────┼────────────┼────────┼────────┼────────┼──────────────┤
│ 456 │ 2025-10-10 │ NULL       │ $0     │ $150   │ -$150  │ Anular       │
│ 789 │ 2025-10-20 │ NULL       │ $200   │ $50    │ $150   │ Revisar      │
└─────┴────────────┴────────────┴────────┴────────┴────────┴──────────────┘
   ... y 37 más

💡 Para corregir, ejecuta:
   php artisan ventas:corregir-tickets descuento100 --dry-run
   php artisan ventas:corregir-tickets abiertos --dry-run
```

---

### 3. **Corregir Tickets con Descuento 100%**

```bash
# Modo DRY-RUN (simular sin aplicar cambios)
php artisan ventas:corregir-tickets descuento100 --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31 --dry-run

# Aplicar correcciones REALES
php artisan ventas:corregir-tickets descuento100 --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31
```

**¿Qué hace?**
- Si el ticket tiene items (`suma_items > 0`): Restaura `total_price = suma_items`
- Si NO tiene items pero tiene descuento: Anula el ticket (`voided = TRUE`)

**Salida esperada:**
```
Procesando ticket #975...
  ✓ Restaurado: total_price = $303 (era $0)
Procesando ticket #712...
  ✓ Restaurado: total_price = $233 (era $0)
Procesando ticket #187...
  ⚠ Anulado: Sin items pero descuento de $73

✅ Cambios guardados en la base de datos

📊 RESUMEN:
   Tickets corregidos (total_price restaurado): 30
   Tickets anulados: 4
   Tickets omitidos: 0
```

---

### 4. **Corregir Tickets Abiertos**

```bash
# Modo DRY-RUN
php artisan ventas:corregir-tickets abiertos --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31 --dry-run

# Aplicar correcciones REALES
php artisan ventas:corregir-tickets abiertos --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31
```

**¿Qué hace?**
- Si `neto <= 0`: Anula el ticket automáticamente
- Si `neto > 0`: **Requiere revisión manual** (no se modifica)

**Salida esperada:**
```
Procesando ticket #456 (neto: $-150)...
  ⚠ Anulado: Neto = $-150
Procesando ticket #789 (neto: $150)...
  - Omitido: Requiere revisión manual (neto = $150)

✅ Cambios guardados en la base de datos

📊 RESUMEN:
   Tickets anulados (neto <= 0): 20
   Tickets omitidos (requieren revisión): 19

⚠️  HAY 19 TICKETS QUE REQUIEREN REVISIÓN MANUAL
```

---

## 📂 Archivos Generados

### Exportaciones JSON

```
storage/app/analisis_ventas/
├── analisis_ventas_2025-10-01_a_2025-10-31_2025-11-05_101530.json
├── analisis_ventas_2025-09-01_a_2025-09-30_2025-11-05_102145.json
└── analisis_ventas_2025-08-01_a_2025-08-31_2025-11-05_103210.json
```

**Estructura del JSON:**
```json
{
    "periodo": {
        "fecha_inicio": "2025-10-01",
        "fecha_fin": "2025-10-31"
    },
    "fecha_analisis": "2025-11-05 10:15:30",
    "resultados": {
        "descuento_100": {
            "total_tickets": 34,
            "total_descuentos": 2145.00,
            "tickets": [...]
        },
        "pago_vs_neto": {
            "total_tickets": 127,
            "total_diferencia": 2870.40,
            "tickets": [...]
        },
        "tickets_abiertos": {
            "total_tickets": 39,
            "total_price": 993.00,
            "total_discount": 1738.00,
            "neto": -745.00,
            "tickets": [...]
        }
    },
    "resumen": {
        "descuentos_fantasma": 2145.00,
        "sobrecobros": 2870.40,
        "tickets_sin_cobrar": -745.00,
        "total_discrepancias": 5760.40
    }
}
```

---

## 🎯 Flujo de Trabajo Recomendado

### **PASO 1: Análisis Inicial**

```bash
# Analizar agosto, septiembre y octubre
php artisan ventas:analizar-discrepancias --mes=2025-08 --exportar --detalle
php artisan ventas:analizar-discrepancias --mes=2025-09 --exportar --detalle
php artisan ventas:analizar-discrepancias --mes=2025-10 --exportar --detalle
```

### **PASO 2: Preview de Correcciones**

```bash
# Ver qué se va a corregir
php artisan ventas:corregir-tickets preview --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31
```

### **PASO 3: Backup de BD**

```bash
# SIEMPRE hacer backup antes de corregir
pg_dump -h 127.0.0.1 -p 5433 -U postgres -d pos > backup_antes_correccion_2025-11-05.sql
```

### **PASO 4: Corrección en DRY-RUN**

```bash
# Simular correcciones (NO modifica BD)
php artisan ventas:corregir-tickets descuento100 --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31 --dry-run
php artisan ventas:corregir-tickets abiertos --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31 --dry-run
```

### **PASO 5: Aplicar Correcciones REALES**

```bash
# ⚠️ ESTO MODIFICA LA BD
php artisan ventas:corregir-tickets descuento100 --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31
php artisan ventas:corregir-tickets abiertos --fecha-inicio=2025-10-01 --fecha-fin=2025-10-31
```

### **PASO 6: Validar Correcciones**

```bash
# Re-analizar para verificar que se corrigieron
php artisan ventas:analizar-discrepancias --mes=2025-10 --detalle
```

---

## 🛡️ Seguridad y Validaciones

### ✅ **Protecciones Implementadas:**

1. **Modo Dry-Run:** Todos los comandos de corrección soportan `--dry-run`
2. **Confirmación Manual:** Se pide confirmación antes de modificar la BD
3. **Transacciones:** Todas las correcciones se ejecutan en transacciones (rollback en caso de error)
4. **Solo Lectura por Defecto:** El comando de análisis NUNCA modifica datos
5. **Logs Automáticos:** Laravel registra todas las operaciones en `storage/logs/laravel.log`

### ⚠️ **IMPORTANTE:**

- **SIEMPRE** hacer backup de la BD antes de corregir
- **SIEMPRE** probar primero con `--dry-run`
- **NUNCA** ejecutar en producción sin validar en desarrollo
- Los tickets con `neto > 0` requieren **revisión manual**

---

## 📊 Casos de Uso

### **Caso 1: Auditoría Mensual**

```bash
# Analizar el mes que acaba de cerrar
php artisan ventas:analizar-discrepancias --mes=$(date -d "last month" +%Y-%m) --exportar --detalle
```

### **Caso 2: Investigar un Día Específico**

```bash
# Analizar solo el 1 de octubre
php artisan ventas:analizar-discrepancias --fecha-inicio=2025-10-01 --fecha-fin=2025-10-01 --detalle
```

### **Caso 3: Corregir un Ticket Específico**

```bash
# Ver detalles del ticket #15246
php artisan ventas:corregir-tickets preview --ticket-id=15246

# Corregirlo (si es del tipo descuento 100%)
php artisan ventas:corregir-tickets descuento100 --ticket-id=15246 --dry-run
php artisan ventas:corregir-tickets descuento100 --ticket-id=15246
```

### **Caso 4: Análisis Histórico (Ago-Oct)**

```bash
# Analizar 3 meses completos
php artisan ventas:analizar-discrepancias --fecha-inicio=2025-08-01 --fecha-fin=2025-10-31 --exportar
```

---

## 🔧 Solución a Problemas Comunes

### **Error: "Connection refused" o "Access denied"**

Verifica las credenciales en `.env`:
```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5433
DB_DATABASE=pos
DB_USERNAME=postgres
DB_PASSWORD="T3rr3n4#p0s"
DB_SCHEMA=selemti,public
```

### **Error: "Command not found"**

Regenera el autoload:
```bash
composer dump-autoload
php artisan cache:clear
php artisan config:clear
```

### **No se exportan resultados**

Verifica permisos del directorio:
```bash
mkdir -p storage/app/analisis_ventas
chmod -R 775 storage/app/analisis_ventas
```

---

## 📞 Soporte

Para más información, consulta:
- `ANALISIS_DEFINITIVO_OCTUBRE_01_2025.md` - Análisis detallado del 1 de octubre
- `ANALISIS_PATRONES_OCTUBRE_2025.md` - Patrones del mes completo
- `analisis_forense_agosto_octubre.txt` - Datos forenses de 3 meses

---

**Última actualización:** 2025-11-05  
**Versión:** 1.0  
**Autor:** Sistema de Análisis Terrena

