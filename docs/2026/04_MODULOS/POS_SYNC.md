# 📦 MÓDULO: POS_SYNC (Orquestador y Sincronizaciones)

> **Clasificación:** CORE  
> **Estado:** Operativo  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** Mixta (Sincronía en Laravel, Eventos Asíncronos en PostgreSQL)

---

## 1. Misión Funcional
Actuar como el "pegamento" arquitectónico del ERP, orquestando y sincronizando el flujo de tiempo entre la emisión legada de operaciones del POS (Floreant) y el impacto logístico / contable en TerrenaLaravel (Cierres, Transferencias, Rebajes).

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/orquestador/daily-close`, `/orquestador/generar-snapshot`
- **UI principal:** (No aplica, procesos ejecutados en Background o disparados por CI/Mantenimiento)
- **Controller / Service central:** `App\Services\Operations\DailyCloseService`, `App\Console\Commands\SyncPosRecipes`
- **Fuente de verdad en PGSQL:** Relación implícita de integridad temporal con timestamps en `public.ticket` y `public.transactions`.
- **Dependencia crítica:** Conecta a **Caja y Postcorte** (validación temporal de cierres), **Inventario** (consolidación periódica) y **Recetas** (Sincronización Estructural / Lectura POS).
- **Pendiente prioritario:** Implementar módulo asistido POS Link y derogar cualquier auto-creación.

---

## 3. Flujo Funcional (Ejemplo Orquestador Cierre)
Petición Orquestador Cierre Diario → Recolección Timestamps del lapso → Verificación de Traspasos sin cerrar → Invocación de cierres pendientes → Empaquetado o Snapshot de Kardex.

`Evento Orquestador (Laravel) → Scan BD → Validación Dependencias Cruzadas → Confirmación de Daily Close`

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Web:** N/A (Consumido vía Jobs CLI).
- **API:** Rutas directas en closures bajo prefijo `/orquestador/*`.
- **Legacy (si aplica):** Antiguos scripts PHP crudos llamando cronjobs en el OS.

**Componentes Arquitectónicos Base**
- **Controllers:** (Ausentes por mala práctica en `api.php`).
- **Services:** `DailyCloseService`, Jobs batch de sincronización pos.
- **Livewire:** Interfaz visual del Panel Orquestador (si fue migrada recientemente de dashboard a Livewire).
- **Models:** Modelos híbridos que interceptan base de datos antigua.

## 5. Base de Datos Crítica
- **Tablas:** `public.ticket`, `public.transactions`.
- **Vistas Específicas Activas:** N/A directa, las vistas pertenecen a los submódulos. 
- **Vistas Híbridas (Pendientes de Indexar/Purgar):** N/A.
- **Funciones PL/pgSQL:** (La delegación de la lógica de negocio real a CAJA: `fn_generar_postcorte`).
- **Triggers:** Escucha y reacción pasiva hacia `selemti.trg_postcorte_after_insert` y `trg_ticket_inventory_consumption`.

## 6. Contrato de Datos / Reglas Base de Datos
- **Origen de datos:** Operaciones de terminal registradas crudas en el schema `public.*`.
- **Destino de datos:** Múltiples (Consolidaciones de Kardex, Postcortes, Historiales).
- **Reglas críticas (Síncrono vs Asíncrono):**
  - **Asíncrono:** El rebaje de inventario reacciona inmediatamente, sin esperar al motor Laravel (Trigger en BD).
  - **Síncrono:** El corte diario contable de flujo (Cierre de día) obedece estrictamente al disparo programado del *Orchestrator* de Laravel asumiendo que los cajeros terminaron su labor.
- **Restricciones importantes:** Si el log temporal de `public.ticket` defasa (reloj de PC distinto en restaurante), la orquestación síncrona fracturará los totales de validación cruzada.

## 7. Fuente de Verdad Real
- **Lógica en Laravel:** Domina cuándo ocurren las consolidaciones macro, validando la lógica cruzada en PHP (ej: "No cerrar el día sin confirmar que los Traspasos están aprobados").
- **Lógica en PostgreSQL:** Dicta qué valores matemáticos existen. La sincronía de orquestación ciegamente empaquetará lo que PostgreSQL afirme en la ventana temporal solicitada por Laravel.

## 8. Dependencias con Otros Módulos
- **Depende de:** Integridad de los Timestamps de Cajas y Empleo constante del POS (sin tickets manuales insertados tardíamente).
- **Impacta a:** FASE 3 (El empaquetado del postcorte), Módulo de Compras (cierre del ciclo de mermas).
- **Bloqueos conocidos:** Tareas duplicadas de `Orquestador` pueden colisionar bloqueando sumatorias (Race conditions).

## 9. Estado Real Desglosado
- **Nivel de Confianza Documental:** Medio (La traza existe mayoritariamente en los logs de los 'GPTs', poca definición en manuales operacionales).
- **Implementado:** Vivo y operando parcialmente en closures de rutas.
- **Operativo:** Funcional pero rústico y fuera de convenciones MVC.
- **Pendiente:** Saneamiento de las APIs de Orquestación y purgado de Jobs no usados.
- **Histórico / Legacy:** Varios scripts de "Sincronización POS v3" de Yunisoft que se abandonaron.

## 10. Problemas Conocidos / Bugs
- **Bug:** Lógica de orquestación acoplada directamente al enrutamiento de Laravel.
- **Causa:** En la reescritura rápida (FASE 1), se asignaron *Closures* de funciones anónimas a las rutas (ej. `/orquestador/generar-snapshot`).
- **Impacto:** Dificulta el testing unitario y rompe compatibilidad con el caché de rutas del servidor, creando carga computacional innecesaria.
- **Estado:** Identificado y listado para la Fase de Limpieza.

## 11. Riesgos si se Modifica
Cambiar la secuencia síncrona en el `DailyCloseService` (ej. permitir realizar un Postcorte sin verificar traspasos pendientes) quebrará temporalmente todo el Inventario físico vs valorizado, generando un gap logístico.

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
- `AI_COORDINATION/STATUS.md`
- Ficha de Módulo CAJA.md y INVENTARIO.md

**Externa / Histórica (Referencia Obsoleta):**
- Carpetas con análisis CLI `D:\Tavo\2025\UX\GPTS\...` (solo validez histórica para comprender el por qué de ciertos Closures).

## 13. Backlog Técnico Prioritario
- [ ] Mudar lógicas *Closure* de `routes/api.php` a Controladores Canónicos dedicados (`OrchestratorController`).
- [ ] Mapear exhaustivamente en código las funciones exactas llamadas dentro de `DailyCloseService`.
- [ ] Validar explícitamente el uso de tokens y permisos para evitar que un orquestador dispare cierres sin privilegios adecuados `auth:sanctum`.

---
## 14. Regla de Intervención Previa
⚠️ **ESTRICTO - ANTES DE MODIFICAR ESTE MÓDULO:**
1. **Verificar PostgreSQL Primero:** Revisar que no haya triggers desincronizados en `selemti.trg_*` que interfieran o asuman el trabajo que se planifica hacer en Laravel.
2. **Pre-Validación en Staging:** Cualquier migración de closures a Controladores requiere probar un "Cierre Diario Ficticio" completo en local (Staging).
3. **Restricción de Producción:** Jamás disparar de forma manual orquestadores transaccionales vía cURL/Postman sin aislar el ecosistema.
