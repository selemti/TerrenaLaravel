# 📦 MÓDULO: [Nombre del Módulo]

> **Clasificación:** CORE / SOPORTE / AMBIGUO / LEGACY  
> **Estado:** Planeado / Implementado / Operativo / Pendiente  
> **Última revisión:** [Mes Año]  
> **Fuente principal de verdad:** [Laravel / PostgreSQL / Mixta]

---

## 1. Misión Funcional
[Dos o tres líneas sobre el valor real del módulo para el negocio]

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/ruta/*`
- **UI principal:** `App\Livewire\...`
- **Controller / Service central:** `...`
- **Fuente de verdad en PGSQL:** `tabla / vista / función / trigger`
- **Dependencia crítica:** `[Módulo del que depende o al que alimenta]`
- **Pendiente prioritario:** `...`

---

## 3. Flujo Funcional
[Describir el flujo principal del módulo, paso a paso]
`Entrada → validación → procesamiento → persistencia → salida`

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Web:** 
- **API:** 
- **Legacy (si aplica):** 

**Componentes Arquitectónicos Base**
- **Controllers:**
- **Services:**
- **Livewire:**
- **Models:**

## 5. Base de Datos Crítica
- **Tablas:**
- **Vistas Específicas Activas:**
- **Vistas Híbridas (Pendientes de Indexar/Purgar):**
- **Funciones PL/pgSQL:**
- **Triggers:**

## 6. Contrato de Datos / Reglas Base de Datos
- **Origen de datos:** 
- **Destino de datos:** 
- **Reglas críticas:** 
- **Restricciones importantes:** 

## 7. Fuente de Verdad Real
- **Lógica en Laravel:** [Explicar qué manda y procesa realmente de este lado]
- **Lógica en PostgreSQL:** [Explicar qué componente SQL manda, suma o restringe]
*(Ejemplo: “La UI y orquestación viven en Laravel, pero la sumatoria oficial vive en selemti.fn_generar_postcorte”)*

## 8. Dependencias con Otros Módulos
- **Depende de:** 
- **Impacta a:** 
- **Bloqueos conocidos:** 

## 9. Estado Real Desglosado
- **Nivel de Confianza Documental:** [Alto/Medio/Bajo - Describir el ratio de pureza vs obsolescencia]
- **Implementado:** [Estado físico en el sistema]
- **Operativo:** [Si está en funcionamiento o falla]
- **Pendiente:** [Breve estatus de lo faltante]
- **Histórico / Legacy:** [Vínculos obsoletos que se mantienen vivos]

## 10. Problemas Conocidos / Bugs
- **Bug:** 
- **Causa:** 
- **Impacto:** 
- **Estado:** 

## 11. Riesgos si se Modifica
[Indicar qué engranaje específico (rutas, servicios o DB) rompería el negocio si se toca sin cuidado]

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
- `AI_COORDINATION/STATUS.md`

**Externa / Histórica (Referencia Obsoleta):**
- `D:\Tavo\2025\UX\...` 

## 13. Backlog Técnico Prioritario
- [ ] Pendiente 1
- [ ] Pendiente 2
- [ ] Pendiente 3

---
## 14. Regla de Intervención Previa
⚠️ **ESTRICTO - ANTES DE MODIFICAR ESTE MÓDULO:**
1. **Verificar PostgreSQL Primero:** Aislar e inspeccionar la Función, Trigger o Vista canónica de la BD antes de diseñar soluciones vía Controladores en Laravel.
2. **Pre-Validación en Staging:** Evaluar integraciones y dependencias obligatoriamente en un entorno Local/Staging.
3. **Restricción de Producción:** Si es imperativo consultar directamente en Producción para depurar, la intervención debe de ceñirse a perfiles de *Solo Lectura (`SELECT`)*.
