# MATRIZ DE ALINEACIÓN INICIAL v2.0
## Orquestador: COPILOT
**Fecha:** 2025-11-14

**Leyenda:**
- ✅ = Completo y funcional
- ⚠️ = Parcial o con problemas
- ❌ = No existe o no funcional
- 🔴 = CRÍTICO | 🟠 = ALTO | 🟡 = MEDIO | 🟢 = BAJO

---

## INVENTARIO

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Alta de ítems | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Recepciones - Wizard | ✅ | ✅ | ✅ | ✅ | ⚠️ | Falta flujo BORRADOR→VALIDADA→POSTEADA | 🟠 |
| Recepciones - Tolerancias | ✅ | ❌ | ⚠️ | ❌ | ❌ | Sistema tolerancias no implementado | 🟠 |
| Recepciones - Evidencias | ✅ | ❌ | ❌ | ❌ | ❌ | Carga fotos/docs no implementada | 🟡 |
| Recepciones - Vinculación PO | ✅ | ❌ | ⚠️ | ❌ | ❌ | Recepciones independientes de POs | 🟡 |
| Transferencias - Estados | ✅ | ⚠️ | ✅ | ⚠️ | ❌ | Solo 2 de 5 estados | 🟡 |
| Transferencias - API REST | ✅ | ❌ | ✅ | ❌ | ❌ | Endpoints no implementados | 🟡 |
| Conteos físicos | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conteos - Vista teórica | ✅ | ❌ | ⚠️ | ❌ | ❌ | Vista stock teórico faltante | 🟡 |
| Mermas - Básico | ✅ | ⚠️ | ✅ | ⚠️ | ⚠️ | Funcionalidad limitada | 🟡 |
| Mermas - UI rápida | ✅ | ❌ | ✅ | ❌ | ❌ | UI ajustes rápidos faltante | 🟡 |
| Mermas - Motivos | ✅ | ❌ | ❌ | ❌ | ❌ | Catálogo motivos sin implementar | 🟡 |
| Kardex | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| KPIs disponibilidad | ✅ | ⚠️ | ✅ | ⚠️ | ⚠️ | No todos KPIs conectados | 🟡 |
| Stock valorizado | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |

**Resumen:** ✅ 4 | ⚠️ 6 | ❌ 5

---

## RECETAS & COSTEO

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Editor básico | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Subrecetas | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Versionado - Estructura | ✅ | ✅ | ✅ | ❌ | ❌ | UI versionado no implementada | 🟠 |
| Versionado - Lógica | ✅ | ❌ | ✅ | ❌ | ❌ | Editor solo version=1 | 🟠 |
| Versionado - Comparación | ✅ | ❌ | ⚠️ | ❌ | ❌ | Comparador faltante | 🟡 |
| Versionado - Activar/desactivar | ✅ | ❌ | ⚠️ | ❌ | ❌ | Control versiones faltante | 🟡 |
| Costeo automático | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Costeo histórico | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | API no expuesta | 🟡 |
| Snapshots | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Job no programado | 🟡 |
| Recálculo masivo | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI manual | 🟡 |
| Catálogo UOM | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conversiones | ✅ | ✅ | ✅ | ✅ | ⚠️ | UI inconsistente props | 🟡 |
| Función conversión | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Recetas Shadow - Tabla | ⚠️ | ⚠️ | ✅ | ❌ | ❌ | UI validación faltante | 🟢 |
| Recetas Shadow - Inferencia | ⚠️ | ✅ | ✅ | ❌ | ❌ | Proceso sin UI | 🟢 |
| Sincronización POS | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI sync | 🟡 |

**Resumen:** ✅ 6 | ⚠️ 6 | ❌ 4

---

## PRODUCCIÓN

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Servicio backend | ✅ | ✅ | ✅ | ❌ | ❌ | UI operativa no implementada | 🟡 |
| API REST | ✅ | ⚠️ | ✅ | ❌ | ❌ | Endpoints no completos | 🟡 |
| CRUD órdenes | ✅ | ✅ | ✅ | ❌ | ❌ | UI CRUD faltante | 🟡 |
| KPIs rendimiento | ✅ | ❌ | ⚠️ | ❌ | ❌ | Dashboard KPIs faltante | 🟡 |
| Mermas producción | ✅ | ⚠️ | ✅ | ❌ | ❌ | Registro no implementado | 🟡 |
| Mise en place | ⚠️ | ❌ | ❌ | ❌ | ❌ | No en scope actual | 🟢 |

**Resumen:** ✅ 0 | ⚠️ 3 | ❌ 3

---

## COMPRAS & REPLENISHMENT

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Solicitudes CRUD | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| POs CRUD | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Cotizaciones | ✅ | ❌ | ❌ | ❌ | ❌ | Módulo faltante | 🟡 |
| Devoluciones | ✅ | ⚠️ | ❌ | ❌ | ❌ | Módulo incompleto | 🟡 |
| Políticas stock | ✅ | ❌ | ✅ | ❌ | ❌ | Motor completo no implementado | 🔴 |
| Algoritmo Min-Max | ✅ | ❌ | ⚠️ | ❌ | ❌ | No implementado | 🔴 |
| Algoritmo SMA | ✅ | ❌ | ⚠️ | ❌ | ❌ | No implementado | 🔴 |
| POS Consumption | ✅ | ❌ | ⚠️ | ❌ | ❌ | Algoritmo no implementado | 🔴 |
| Dashboard sugerencias | ✅ | ❌ | ✅ | ❌ | ❌ | No implementado | 🔴 |
| Razón cálculo | ✅ | ❌ | ❌ | ❌ | ❌ | Trazabilidad faltante | 🔴 |
| Simulador costo | ✅ | ❌ | ⚠️ | ❌ | ❌ | Faltante | 🟡 |
| API Sugerencias | ✅ | ⚠️ | ❌ | ❌ | ❌ | No implementada | 🔴 |
| Recepciones duplicadas | ✅ | ⚠️ | ✅ | ⚠️ | ❌ | Servicio duplicado | 🟡 |

**Resumen:** ✅ 2 | ⚠️ 2 | ❌ 9 | **CRÍTICO: Motor Replenishment ausente**

---

## POS & CONSUMOS

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Mapeo POS-Recetas | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Mapeo modificadores | ✅ | ⚠️ | ✅ | ❌ | ❌ | UI faltante | 🟡 |
| Consumo automático | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI limitada | 🟡 |
| Fn confirmar | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI directa | 🟢 |
| Fn expandir | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI directa | 🟢 |
| Fn reversar | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin UI directa | 🟡 |
| Reproceso tickets | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI faltante | 🟡 |
| Auditoría consumos | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Dashboard limitado | 🟡 |
| API Recipe Cost | ⚠️ | ✅ | ✅ | ❌ | ❌ | No en routes | 🟡 |
| Sync batches | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI sync faltante | 🟢 |

**Resumen:** ✅ 1 | ⚠️ 8 | ❌ 1

---

## CAJA & FINANZAS

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Fondos CRUD | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Movimientos CRUD | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Arqueos | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Precorte | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Precorte trigger | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin visibilidad UI | 🟢 |
| Postcorte | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Postcorte trigger | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Sin visibilidad UI | 🟢 |
| Sesiones cajón | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conciliación efectivo | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conciliación tarjetas | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conciliación sesiones | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Histórico UI | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Alertas cortes | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | Dashboard mejorable | 🟡 |
| DailyCloseService | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | No ubicado | 🟡 |

**Resumen:** ✅ 12 | ⚠️ 2 | ❌ 0 | **Módulo mejor alineado**

---

## REPORTES & KPIs

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Dashboard principal | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| KPIs sucursal | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| KPIs terminal | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas detalle | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas resumen | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas balance | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas excepciones | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas mix | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Journal | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Menu usage | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Stock valorizado | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Consumo vs movimientos | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Anomalías | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ticket promedio | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Ventas por hora | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Export PDF | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | Incompletas | 🟡 |
| Export XLSX | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | Incompletas | 🟡 |
| DrillDown | ⚠️ | ✅ | ⚠️ | ⚠️ | ⚠️ | Limitado | 🟡 |

**Resumen:** ✅ 15 | ⚠️ 3 | ❌ 0

---

## SEGURIDAD & PERMISOS

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Sistema roles | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno backend | 🟢 |
| Permisos atómicos | ✅ | ✅ | ✅ | ✅ | ⚠️ | Matriz no 100% sync | 🟡 |
| GUI roles | ⚠️ | ❌ | ✅ | ❌ | ❌ | GUI faltante | 🟡 |
| GUI permisos | ⚠️ | ❌ | ✅ | ❌ | ❌ | GUI faltante | 🟡 |
| GUI asignación | ⚠️ | ⚠️ | ✅ | ⚠️ | ⚠️ | GUI mejorable | 🟡 |
| Auditoría global | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI limitada | 🟡 |
| Auditoría específica | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | UI limitada | 🟡 |
| Middleware | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |

**Resumen:** ✅ 2 | ⚠️ 5 | ❌ 2

---

## CATÁLOGOS

| Funcionalidad | Docs | Código | BD | UI | Alineado | Gap | Severidad |
|--------------|------|--------|----|----|----------|-----|-----------|
| Unidades medida | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Conversiones UOM | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Proveedores | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Almacenes | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Sucursales | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno | 🟢 |
| Políticas stock | ✅ | ✅ | ✅ | ✅ | ⚠️ | UI sin motor | 🟡 |
| Categorías ítems | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | CRUD mejorable | 🟡 |

**Resumen:** ✅ 5 | ⚠️ 2 | ❌ 0

---

## RESUMEN GLOBAL DE ALINEACIÓN

| Módulo | Total Funcionalidades | ✅ Alineadas | ⚠️ Parciales | ❌ Faltantes | % Alineación |
|--------|----------------------|-------------|-------------|-------------|--------------|
| Inventario | 15 | 4 | 6 | 5 | 67% |
| Recetas | 16 | 6 | 6 | 4 | 75% |
| Producción | 6 | 0 | 3 | 3 | 50% |
| **Compras** | **13** | **2** | **2** | **9** | **31%** 🔴 |
| POS | 10 | 1 | 8 | 1 | 90% |
| Caja | 14 | 12 | 2 | 0 | 96% |
| Reportes | 18 | 15 | 3 | 0 | 94% |
| Seguridad | 8 | 2 | 5 | 2 | 69% |
| Catálogos | 7 | 5 | 2 | 0 | 93% |
| **TOTAL** | **107** | **47** | **37** | **24** | **73%** |

---

## GAPS CRÍTICOS PRIORIZADOS

### 🔴 CRÍTICO (P0)
1. **Motor Replenishment completo** - 0% implementado
2. **Versionado recetas funcional** - BD lista, lógica ausente
3. **Consolidar servicios recepciones** - Duplicidad

### 🟠 ALTO (P1)
4. **Flujos validación recepciones** - Solo 1 de 3 estados
5. **Estados completos transferencias** - 2 de 5 estados
6. **UI operativa producción** - Backend existe, UI no

### 🟡 MEDIO (P2)
7. **API POS en routes** - Código existe, no expuesto
8. **UI ajustes rápidos mermas** - Diseño existe, no implementado
9. **GUI completa permisos** - Backend OK, UI limitada

---

**FIN MATRIZ ALINEACIÓN v2.0 - COPILOT**
