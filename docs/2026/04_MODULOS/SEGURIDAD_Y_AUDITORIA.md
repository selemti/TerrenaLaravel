# 📦 MÓDULO: Gobernanza, Seguridad y Bitácora Activa (Audit & RoleSec)

> **Clasificación:** TRANSVERSAL CRÍTICO (Core Sistema Nervioso)  
> **Estado:** Implementado (Con Inmutabilidad Raw SQL)  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** PostgreSQL (`selemti.audit_log` / `Spatie Permission Tables`).

---

## 1. Misión Funcional
**Identidad y Control (Spatie):** Someter cada Petición HTTP Operacional bajo un escrutinio de Roles y Restricciones Gerenciales.
**Bitácoras Duras (Audit Log):** Vigilar a los vigilantes. Acuñar de manera forense e indeleble un registro en piedra sobre alteraciones transaccionales críticas (ej. Cancelación y borrado de Tickets, Resurrección de Sesiones).

## 2. Resumen Operativo Rápido
- **Componentes Tecnológicos:** `Spatie/laravel-permission`, `Laravel Sanctum`.
- **Controladores Base:** `App\Livewire\Audit\LogViewer`, `AuditLogController`.
- **Base de modelos:** `AuditLog`, `User`, `Core\Auditoria`.
- **Fuente de Inyección Central:** Insertado pasivamente mediante comandos estáticos directos `$db->insert()` ignorando por diseño los Hooks de PHP para garantizar invisibilidad e incorruptibilidad ante el framework.
- **Pendiente prioritario:** Generar un catálogo público interno (`MATRIZ_DE_PERMISOS_SISTEMA`) que formalice jerárquicamente qué *Gates* tocan a qué *End-points*.

---

## 3. Flujo Funcional (Trazabilidad Forense)
`Usuario Físico detona Acción (Ticket Cancellation) → Controlador Valida Permiso vía Spatie → Lógica Comercial Se Ejecuta → Al unísono, se despacha un RAW INSERT incondicional hacia selemti.audit_log con (Old Value / New Value / User_ID).`

## 4. Mapa Tecnológico Canónico
- **Gobernanza:** `app/Http/Middleware/CheckPermission.php`, `AuthServiceProvider.php`.
- **Micro-Logs Ciegos:** `pos_reverse_log_table` y `pos_reprocess_log_table` (Vuelcos crudos del comportamiento del TPV Floreant).
- **Core Database:** `2025_09_26_205955_create_permission_tables.php`.

## 5. Entorno Sub-Módulo de Aprobaciones
El ERP Terrena Laravel es reticente en acciones. El Flujo global detiene ciertas promesas transaccionales en un estatus `En Revisión` las cuales se liberan al validarse el componente abstracto Spatie superior del Usuario Activo, logrando una gobernanza de "Cuatro Ojos". (Evidenciado en flujos de CajaChica y Transferencias).

## 6. Riesgos y Alertas Críticas de Intervención Funcional
- **Auditoría Vulnerable por Sombra:** Al emplear el disparo manual `$db->insert` dentro del código PHP comercial (ej. `TicketManagementController.php`), Eloquent no detecta ni protege la columna audit_log. Un refactor imprudente o re-escritura masiva ignorará que "olvidó" copiar y pegar esa línea de registro en el nuevo script, apagando los monitores anti-fraude del negocio local sin que los Unit Tests estallen.
- **Crecimiento No Asintótico (Log Bloat):** Carece de una política de archivo frío o purga. Mantener perennemente registros estáticos textuales terminará degradando el IOPS general del esquema `selemti`.

## 7. Dependencias con Otros Módulos
- **Depende de:** Todos. Al ser un módulo Transversal Aislado, es dependiente e ingerente sobre los Request Cycles enteros de CAJA, INVENTARIO, CORTES y COMPRAS.
