# Operaciones · Monitoreo y Observabilidad

## 1. Health Checks

- `GET /api/ping` → respuesta rápida para monitor básico.
- `GET /api/health` → delega en `Api\Caja\HealthController`. Pendiente:
  - Verificar conexión a DB (`pg_connect`).
  - Verificar cache/queue.
  - Incluir versión de la app (`config('app.version')`).
- `GET /__probe` (web) → información extendida del entorno. Restringir acceso en producción.

## 2. Logs

- Laravel Log: `storage/logs/laravel.log` (daily).  
- JS/CSS específicos de caja escriben en consola; revisar `public/assets/js/caja/*.js`.  
- Recomendado integrar:
  - Rotación via `logrotate` o servicio similar.
  - Alertas (Slack/Teams) en caso de errores críticos.

## 3. Métricas & KPIs

- Reportes: endpoints en `/api/reports/*` (pendientes).  
- Inventario: Livewire `ItemsIndex` calcula KPIs (bajo stock, por vencer). Llevar a API para monitoreo automático.
- Caja: scripts en `D:\Tavo\2025\UX\Cortes\` contienen consultas para dashboards (migrar a vistas materializadas).

## 4. Alertas

- Definir umbrales (e.g., inventario bajo stock, conciliación fallida).  
- Utilizar jobs programados (cron) para generar alertas por correo/Notificaciones.

## 5. Herramientas Recomendadas

- **Supervisord** para colas (`queue:listen`).  
- **PgHero / pganalyze** para observar base de datos Postgres 9.5.  
- **Sentry / Bugsnag** para errores de PHP/JS.  
- **Grafana/Prometheus** si se exponen métricas (custom).  
- **UptimeRobot** o similar para monitorear endpoints `/api/ping`.

## 6. Próximos Pasos

- [ ] Implementar chequeo profundo en `/api/health`.  
- [ ] Configurar canal de alertas (email, Slack).  
- [ ] Documentar dashboard de monitoreo (qué se vigila y cómo).  
- [ ] Agregar logging estructurado para módulos críticos (caja, inventario).  
- [ ] Plan de respuesta a incidentes (contactos, escalamiento).

Actualiza este archivo conforme se implementen herramientas de monitoreo.
