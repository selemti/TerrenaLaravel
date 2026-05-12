# 📦 MÓDULO: Automatizaciones y Procesos en Lote (Batch Jobs)

> **Clasificación:** INFRAESTRUCTURA INVISIBLE (Background)  
> **Estado:** Implementado (Operativo Pasivo)  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** Tareas Programadas de Laravel (Cron / Scheduler).

---

## 1. Misión Funcional
Garantizar la salud técnica y la sanidad contable del negocio estructurando *rutinas de mantenimiento invisibles*. Evitar cuellos de botella calculando variables pesadas durante la madrugada, tales como la consolidación de inventario tardío, la generación estática de reportes y la purgación de estados huérfanos.

## 2. Resumen Operativo Rápido
- **Componentes base:** Cronjobs, Cola de Trabajos (`Queues` Redis/Database).
- **Controlador Base:** Código inyectado bajo contexto CLI (Comandos de consola locales).
- **Modelos Asignados:** `App\Models\Core\JobRecalculo.php`, `App\Models\Core\PerdidaLog.php`.
- **Dependencia Crítica:** Supervisor (Linux) o Task Scheduler (Windows) para detonar `php artisan schedule:run`.
- **Pendiente prioritario:** Levantar un Dashboard Visual en el Administrativo para monitorear Jobs Fallidos.

---

## 3. Flujo Funcional
`Reloj del SO detona Scheduler Laravel → Verifica si hay Tarea Asignada a la hora actual → Invoca la Clase Job → Ejecuta el DML pesado a PostgreSQL (Postcorte, Recálculos WAC, PerdidaLogs) → Cierra el Job y marca Success/Fail en tabla loguera.`

## 4. Mapa Tecnológico Canónico
Este módulo se rige fuera del canal HTTP, existiendo puramente bajo el amparo de los Handlers de Consola de Laravel:
- **Scripts Nativos:** Múltiples comandos agendados ocultos (`php artisan ...`).
- **Bitácoras Especializadas:** Emplea las entidades `PerdidaLog` para asentar cuando un lote de transferencia fue descartado por timeout de viaje o caducidad.

## 5. Contrato de Datos / Reglas Base de Datos
- **Asincronicidad:** Ninguna vista o controlador web debe depender empíricamente de la latencia de un Job. Operan desacoplados. Las vistas de reportes gerenciales (Ventas del día de ayer, Costos Mensuales) suelen apoyarse de Tablas Pre-calculadas que estos *Batch Jobs* rellenan cada madrugada.

## 6. Riesgos y Alertas Críticas de Intervención Funcional
- **El Monstruo Silencioso (Silent Fails):** A diferencia de Error 500 en web donde un usuario gritará, si un Cron Job falla por un Bug SQL en la actualización del ERP, puede estar una semana entera sin actualizar los WAC y nadie lo notará hasta que envíen el reporte de Fin de Mes a los contadores.
- **Saturación en Ventana Activa:** Si el `JobRecalculo` toma más horas de lo proyectado y se solapa con el turno operativo de los Cajeros, puede producir un *Deadlock* infernal contra la base de datos (PostgreSQL), trabando a todas las cajas y al piso del restaurante simultáneamente.

## 7. Dependencias con Otros Módulos
- **Depende de:** No requiere permisos humanos; exige los privilegios absolutos del demonio de servicio.
- **Impacta a:**
  - **REPORTES:** Lo retroalimenta generando agregaciones pre-digeridas aligerando su vista.
  - **INVENTARIO:** Castiga mermas tardías.
