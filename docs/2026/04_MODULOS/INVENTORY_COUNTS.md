# 📦 MÓDULO: Auditorías Físicas (Inventory Counts)

> **Clasificación:** CONTROL DE ACTIVO (Kardex Adjustments)  
> **Estado:** Implementado (A nivel de Modelado Subyacente)  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** Laravel interviene como Gestor/Comparador, PostgreSQL como Persistencia en Movimientos (`movimientos_inventario`).

---

## 1. Misión Funcional
Otorgar un mecanismo ciego o restrictivo para forzar auditorías cíclicas (conteos físicos en piso / anaquel) y comparar la pureza del inventario físico frente al inventario *Contable Teórico* asimilado desde las mermas algorítmicas, ajustando el nuevo saldo y absorbiendo las desviaciones.

## 2. Resumen Operativo Rápido
- **UI principal:** Procesos pasivos referenciados históricamente en `InventoryCounts`.
- **Controller / Service central:** `App\Models\InventoryCount` e `InventoryCountLine`.
- **Fuente de verdad en PGSQL:** Inyecta en el maestro `MovimientoInventario`.
- **Dependencia crítica:** INVENTARIO.
- **Pendiente prioritario:** Acotar el poder de intervención, evitando que "cuadres cosméticos" destruyan el margen WAC.

---

## 3. Flujo Funcional
`Sorteo / Apertura de Conteo de Bodega → Captura Ciega Operativa (Conteos en Físico) → Análisis del Diferencial (Físico vs Sistema) → Aprobación Gerencial → Ajuste Formal Inyectado al Kardex (IN o OUT).`

## 4. Mapa Tecnológico Canónico
- **Soporte Lógico:** Archivos modelados activamente en `InventoryCount.php`.
- **Aislamiento Backend:** Es el módulo "antídoto" de los submódulos *Replenishment* y *POS_SYNC*.

## 5. Contrato de Datos / Reglas Base de Datos
- **Tipificación Restrictiva:** Toda inyección originada aquí requiere estampar un Type o Razón explícita en el Kardex (`motivo: Ajuste por Conteo`), es un movimiento "anómalo" por naturaleza en contraposición al viaje normal de recetas.
- **Valuación Contable:** Alterar la cantidad base obliga a la matemática en BD a reconfigurar la valoración neta del almacén, recalculando la masa inyectada acorde al precio o forzando una asunción del WAC congelado.

## 6. Dependencias con Otros Módulos
- **Depende de:**
  - **INVENTARIO:** Para extraer la base comparativa "Conteo Sistema".
- **Impacta a:**
  - **RECETAS:** Inyecciones de Ajuste distorsionan marginalmente los costos históricos reales (Food Cost).
  - **REPORTES:** Explicará las disyuntivas del "Consumo VS Movimientos Reales".

## 7. Estado Real Desglosado
- **Nivel de Confianza Documental:** Bajo contemporáneamente (2026), dependiente mayoritariamente de `docs/00.history/InventoryCounts`.
- **Implementado:** Soportado lógicamente por Eloquent Activo.
- **Operatividad Actual:** Se subestima erróneamente tratándolo como una pestaña interna más de `INVENTARIO.md`, ignorando su rol restrictivo de Auditor.

## 8. Alertas Críticas (El Agujero Negro del WAC)
Este módulo posee el poder técnico de blanquear cualquier robo, merma encubierta o falla operativa bajo el disfraz de "Ajuste Validado". El abuso en la frecuencia o tolerancia porcentual de este módulo **arruinará irrecuperablemente el Costo Promedio Ponderado del ERP**, aislando a la gerencia de saber la verdad de sus pérdidas productivas.
