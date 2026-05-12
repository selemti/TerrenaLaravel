# 📦 MÓDULO: CAJA y POSTCORTE

> **Clasificación:** CORE
> **Estado:** Operativo (Parcial)
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** PostgreSQL

---

## 1. Misión Funcional
Garantizar la conciliación financiera correcta de las operaciones del restaurante mediante la comparación (cuadre) del efectivo declarado físicamente por los cajeros contra las operaciones consolidadas y registradas automáticamente en el sistema de ventas (POS Floreant).

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/caja/postcortes/*`, `/caja/sesiones/*`, `/caja/cortes/historico`
- **UI principal:** Dividida funcionalmente en `App\Livewire\CashFund\*` (Manejo exclusivo de Caja Chica) e interfaces de orquestación central.
- **Controller / Service central:** Ecosistema orquestado por `Api\CajaController`, `Api\PostcorteController` y `Api\PrecorteController`.
- **Fuente de verdad en PGSQL:** Función `selemti.fn_generar_postcorte`
- **Pendiente prioritario:** Corregir desfase de tickets en la cláusula de ventana temporal del `fn_generar_postcorte`.

---

## 3. Flujo Funcional
Apertura de Turno (Sesión) → Emisión de Ventas POS → Preparación Cierre (Precorte) → Declarado de Valores Físico (Drawer/Z) → Ejecución de Postcorte → Validación y Conciliación Final (Descuadre).

`Apertura → Venta POS → Declaración de Caja (Drawer) → selemti.fn_generar_postcorte → Auditoría/Conciliación`

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Web:** `/caja/cortes/historico`, `/cashfund/*`
- **API:** Rest endpoints en `routes/api.php` sobre prefijo `/caja/postcortes`
- **Legacy (API):** Interceptores en `routes/api.php` simulando llamadas planas `/legacy/caja/precorte_create.php`

**Componentes genéticos**
- **Controllers:** `Api\CajaController`, `Api\PostcorteController`, `Api\PrecorteController`
- **Services:** `PrecorteService`, `PostcorteService`
- **Livewire:** Interfaz modular bajo `App\Livewire\CashFund\*`
- **Models:** `Postcorte`, `Precorte`, `SesionCajon`

## 5. Base de Datos Crítica
- **Tablas:** `selemti.postcorte`, `selemti.precorte`, `selemti.sesion_cajon`
- **Vistas:** Pendientes de indexar y consolidar (existen múltiples vistas `vw_*` híbridas para diagnósticos de caja/reportes que requieren aislarse del transactional core).
- **Funciones PL/pgSQL:** `selemti.fn_generar_postcorte` (El motor central que elabora la contabilidad).
- **Triggers:** `selemti.fn_postcorte_after_insert` (Encargado ÚNICAMENTE de alterar el estado visual de la sesión a "CERRADA", jamás debe cargar lógica matemática).

## 6. Contrato de Datos / Reglas Base de Datos
- **Origen de datos:** Tabla de producción legada `public.ticket`, `public.transactions`, contra montos físicos de `public.drawer_pull_report`. El total neto es dictaminado por el [SSOT de Ventas (Doc 07)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/07_SSOT_VENTAS_Y_DESCUENTOS.md).
- **Destino de datos:** Persistencia en `selemti.postcorte`.
- **Reglas críticas:** Para sumar correctamente un ticket de un cajero a un postcorte, el ticket de origen DEBE haber cerrado lógicamente bajo la ventana de asignación de esa sesión.
- **Restricciones importantes:** Evitar la reestructuración de la tabla core de Floreant `ticket`.

## 7. Fuente de Verdad Real
- **Lógica en Laravel:** La UI (CashFund), visualización y la orquestación de la captura del Precorte, más la interfaz del orquestador, están a cargo de Laravel de manera superficial.
- **Lógica en PostgreSQL:** Toda la matemática financiera, cruce de propinas, descuentos, y agregaciones formales de totales está herméticamente codificada en la función base **`selemti.fn_generar_postcorte`**.

## 8. Dependencias con Otros Módulos
- **Depende de:** Integridad operativa en el Módulo POS (inserción lícita natural).
- **Impacta a:** Reportes Financieros, Cuadre Corporativo y consolidación del kardex al cierre diario.
- **Bloqueos conocidos:** Ninguno ajeno al bug de exclusión de tickets por timestamp estricto (FASE 3).

## 9. Estado Real Desglosado
- **Documentado:** Nivel Alto. Integrado formalmente al estándar Ficha Documental 2026; la documentación histórica contradictoria fue reclasificada y aislada exitosamente.
- **Implementado:** Completamente codificado sobre la base de PGSQL y Laravel 12.
- **Operativo:** Parcial. Se encuentra vivo en ejecución pero adolece de precisión asimétrica por exclusiones cronológicas injustas en BD.
- **Pendiente:** Abordaje crítico de FASE 3 para reparar el cálculo final de postcorte.
- **Histórico / Legacy:** Ruteos `.php` embebidos en el router y manuales de requerimientos del sistema intermedio "Slim".

## 10. Problemas Conocidos / Bugs
- **Bug Histórico:** Aparecieron falsos ceros en cierres contables (`0.00`).
- **Causa Exacta:** Una divergencia de esquema. Se inyectó código en staging que pretendía registrar ventas brutas/descuentos matemáticos sin respaldar DDL.
- **Estado:** ✅ RESUELTO. Se revirtió toda experimentación, empatando el origen de `fn_generar_postcorte` exactamente a lo codificado en Producción 100.126.124.101.

## 11. Riesgos si se Modifica
Alterar triggers como `trg_postcorte_after_insert` asumiendo que controlan los totales quebrará la integridad operativa de la sesión (bug reproducido y revertido en Abril 2026). Así mismo, desactivar las directivas REST `prefix('legacy')` afectará en cascada clientes de escritorio no convertidos. 

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
- [Doc 07 - SSOT Ventas y Descuentos](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/07_SSOT_VENTAS_Y_DESCUENTOS.md)
- [Doc 17 - Cierre Formal Fase 1](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/17_CIERRE_FORMAL_FASE_1.md)
- `AI_COORDINATION/STATUS.md`

**Externa / Histórica (Referencia / No modificar código en base a esto):**
- Todo documento previo al 2026 localizado en `D:\Tavo\2025\UX\Cortes\*`.
- Documentos desastrosos que indujeron a modificar el trigger del postcorte encontrados en `docs/00.history/`.

## 13. Backlog Técnico Prioritario
- [ ] Ejecutar reingeniería de sub-consultas en `selemti.fn_generar_postcorte` para admitir una ventana extendida de captura.
- [ ] Incorporar la activación de tokens `auth:sanctum` a las rutas del API suspendidas en `api.php`.
- [ ] Destruir progresivamente los controladores y wrappers obsoletos legacy cuando los clientes se migren al v3.

---

## 14. Regla de Intervención Previa
⚠️ **ANTES DE MODIFICAR ESTE MÓDULO, REVISAR OBLIGATORIAMENTE:**
1. Validar la estructura y dependencias paramétricas de `selemti.fn_generar_postcorte` trabajando obligatoriamente en un entorno de pruebas o local (staging) controlado. Toda intervención de evaluación sobre la base de Producción deberá ser de estricta 'solo lectura' (`SELECT`).
2. **Nunca asumir que Local representa Producción sin auditoría de esquema previa**. La divergencia experimentada en Abril 2026 demuestra que el DDL en crudo debe respaldarse. Validar BD real productiva antes de tocar lógica financiera.
3. `AI_COORDINATION/STATUS.md` debe revisarse para reconfirmar dependencias.
4. Nunca añadir lógica matemática al Trigger de Cierre.
