# Investigación de Diferencias en Reportes de Ventas
**Fecha:** 8 de diciembre 2025
**Período Analizado:** Últimos 7 días (1-6 diciembre 2025)
**Terminales:** 101 y 102

## Resumen Ejecutivo

Se identificaron **diferencias considerables** entre los datos de tickets y los precortes/reportes en ambas terminales:

- **Terminal 101:** Diferencia total de **$10,589.20** (positiva = declarado más que ventas reales)
- **Terminal 102:** Diferencia total de **$10,200.20** (positiva = declarado más que ventas reales)

**Diferencia combinada:** $20,789.40 en solo 6 días de operación.

## Hallazgos Principales

### 1. Volumen de Operaciones

| Métrica | Terminal 101 | Terminal 102 | Diferencia |
|---------|--------------|--------------|------------|
| Tickets totales | 834 | 1,315 | +57% |
| Ventas brutas | $48,033 | $67,906 | +41% |
| Ticket promedio | ~$58 | ~$52 | -10% |

### 2. Discrepancias por Terminal

#### Terminal 101
- **5 de 6 días con diferencias significativas** (> $1,000)
- **Diferencia máxima:** $3,265 (36.7%) el 1-dic
- **Tendencia:** Consistentemente declara más de lo que vende
- **Anomalía:** 3-dic con diferencia negativa (-$2,422, -30.9%)

#### Terminal 102
- **4 de 5 días con diferencias significativas** (> $1,000)
- **Diferencia máxima:** $3,597 (47.4%) el 5-dic
- **Tendencia:** Similar a 101, declara más de lo que vende
- **Dato faltante:** No hay datos de 3-dic en precortes

### 3. Análisis por Día

#### Días con Mayor Discrepancia

1. **1-dic-2025:**
   - 101: +$3,265 (36.7%)
   - 102: +$2,195 (15.0%)

2. **5-dic-2025:**
   - 101: +$1,554 (19.3%)
   - 102: +$3,597 (47.4%) 🔴

#### Día con Anomalía Negativa
- **3-dic-2025:** Terminal 101 con -$2,422 (-30.9%)
  - Posible problema de cálculo o datos incompletos

### 4. Formas de Pago

| Terminal | Efectivo | Tarjetas | Distribución |
|----------|----------|----------|--------------|
| 101 | $22,553 (47.0%) | $25,480 (53.0%) | Balanceado |
| 102 | $34,382 (50.4%) | $33,872 (49.6%) | Balanceado |

Ambas terminales tienen distribución similar efectivo/tarjetas (~50/50).

### 5. Problemas Detectados

- **Tickets sin transacciones:** 4 tickets identificados
- **Tickets anulados:** 8 tickets en terminal 102
- **Sesiones sin precortes:** Terminal 102 no tiene datos de 3-dic
- **Tickets pagados sin registro:** 4 casos detectados

## Causas Posibles

### 1. Errores en Proceso de Corte
- **Cálculo manual incorrecto** en totales de precorte
- **Inclusión de tickets no válidos** (anulados, pruebas)
- **Omisión de tickets válidos** (offline, sistema caído)

### 2. Problemas de Sincronización
- **Tickets offline** no registrados en tiempo real
- **Fallas de conexión** durante picos de operación
- **Inconsistencia** entre sistema de POS y sistema de cortes

### 3. Errores de Procedimiento
- **Corte parcial** (no todos los turnos)
- **Cierre anticipado** o tardío de sesión
- **Mala configuración** de terminal o caja

### 4. Problemas Técnicos
- **Bugs en sistema** de cálculo de totales
- **Datos corruptos** o perdidos
- **Inconsistencias** entre tablas de transacciones

## Impacto Financiero

### Sobrestimación en Precortes
- **Terminal 101:** $10,589 extras declarados
- **Terminal 102:** $10,200 extras declarados
- **Total:** $20,789 sobrestimados en 6 días

### Proyección Mensual
Si la tendencia continúa:
- **Sobrestimación mensual estimada:** ~$100,000
- **Impacto en conciliación:** Requiere ajustes manuales significativos
- **Riesgo de auditoría:** Diferencias sistemáticas detectables

## Recomendaciones Inmediatas

### 1. Acciones Urgentes (Hoy)
- [ ] **Investigar 3-dic-2025:** Verificar ausencia de precorte en terminal 102
- [ ] **Revisar tickets sin transacciones:** Identificar causa raíz
- [ ] **Validar proceso actual:** Observar ejecución de próximos cortes

### 2. Corto Plazo (Esta semana)
- [ ] **Auditoría física:** Conteo manual vs sistema
- [ ] **Revisión de procedimientos:** Validar metodología de corte
- [ ] **Capacitación:** Reforzar proceso correcto con personal

### 3. Mediano Plazo (2 semanas)
- [ ] **Implementar validaciones:** Sistema debe alertar diferencias >10%
- [ ] **Automatizar conciliación:** Cruce automático tickets vs transacciones
- [ ] **Mejorar reportes:** Dashboard de diferencias en tiempo real

### 4. Largo Plazo (1 mes)
- [ ] **Integración sistemas:** Unificar POS y sistema de cortes
- [ ] **Control de cambios:** Validación antes de procesar corte
- [ ] **Monitoreo continuo:** Alertas automáticas de anomalías

## Pasos Siguientes Específicos

### Para Terminal 101
1. **Investigar 3-dic-2025:** ¿Por qué diferencia negativa?
2. **Validar cálculos:** Revisar fórmulas de totales
3. **Verificar tickets offline:** Posibles tickets perdidos

### Para Terminal 102
1. **Investigar 5-dic-2025:** Diferencia más alta (47.4%)
2. **Recuperar 3-dic-2025:** ¿Por qué no hay precorte?
3. **Analizar patrones:** ¿Por qué más volúmenes pero mismas proporciones?

### Acciones Correctivas
1. **Estandarizar proceso:** Mismo procedimiento en ambas terminales
2. **Validación cruzada:**tickets ↔ transacciones ↔ cortes
3. **Reporte diario:** Validar diferencias antes de cerrar día

## Herramientas de Diagnóstico

Se crearon los siguientes scripts para continuar el monitoreo:

1. **`scripts/analisis_simple_ventas.sql`** - Análisis diario automatizado
2. **`scripts/comparacion_precortes_tickets.php`** - Comparación manual
3. **`scripts/analizar_discrepancias_ventas.php`** - Análisis detallado (con Laravel)

## Conclusión

Las diferencias detectadas son **significativas y sistemáticas**, requiriendo acción inmediata. No parecen ser errores aleatorios sino problemas de proceso o sistema que deben corregirse para garantizar la integridad de la información financiera.

La magnitud de las diferencias ($20,789 en 6 días) representa aproximadamente el 15-20% de las ventas, lo cual es inaceptable desde una perspectiva de control financiero.

---

**Próxima revisión:** Recomendado en 7 días para validar efectividad de acciones correctivas.
**Responsables:** Operación (procesos), TI (sistema), Finanzas (validación).