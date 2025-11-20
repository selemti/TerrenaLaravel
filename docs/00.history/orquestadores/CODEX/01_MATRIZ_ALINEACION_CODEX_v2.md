# MATRIZ DE ALINEACIÓN INICIAL · CODEX

| Módulo | Estado V4.0 (FASE2) | Evidencia principal | Gaps identificados | Acción inmediata |
|--------|---------------------|---------------------|--------------------|------------------|
| Inventario (Items, Recepciones, Disponibilidad, Transferencias, Conteos, Mermas) | 95% completo (6 docs) | FASE2 §“Inventario” | Falta política de reorden y ajustes manuales | Crear specs `Ajustes` + `Reorden` (FASE3 prioridad 🔴) antes de tocar código. |
| Purchasing | 90% completo | `docs/V4.0/Purchasing/README.md` + FASE1 tabla | Fase 2 (comparación cotizaciones) pendiente | Documentar Fase 2 en V4.0 y enlazar recepciones. |
| Caja (Precorte/Postcorte) | 95% completo | `docs/V4.0/Caja/*` | Estados de sesión y rechazo postcorte sin detallar | Añadir doc “EstadosSesion” (FASE3). |
| Finanzas (Caja Chica + cortes) | 85% completo | `docs/V4.0/Finanzas/README.md` + FASE1 | Falta workflow de aprobaciones multi-nivel | Migrar detalles de `/docs/CajaChica/` según FASE3. |
| Reports (Ventas) | 88% completo | `docs/V4.0/Reports/README.md` | Lista completa y scheduling ausentes | Incorporar catálogo v9 y relación Jasper (FASE3). |
| Frontend (Layout/Componentes) | 90% | `docs/V4.0/Frontend/*` | Falta guía Design System | Crear `DesignSystem.md` (FASE3). |
| Recetas | 70% | `docs/V4.0/Recetas/README.md` | Versionado real ausente | Redactar documentos `BOMImplosion` y `IntegracionPOS` (FASE3). |
| Producción | 55% | `docs/V4.0/Produccion/README.md` | Estados OP y mise en place no migrados | Crear `Estados.md` y `MiseEnPlace.md` (FASE3). |
| POS | 60% | `docs/V4.0/POS/README.md` | Endpoints `PosConsumptionController` sin exponer | Documentar sincronización y reproceso (FASE3). |
| Caja Chica | 100% (fuera V4.0) | `docs/CajaChica/FondoCaja/` + FASE1 | Falta referencia explícita en V4.0 | Enlazar desde `Finanzas/README.md`. |
| Replenishment | Solo en legacy | `docs/Replenishment/*` + FASE1 | Motor documentado pero no en V4.0 | Pendiente integrar (no crear módulo nuevo, solo referenciar). |
| Seguridad | Parcial | `docs/V4.0/Guia/Stack.md` + FASE4/FASE6 | Falta doc independiente | Plan FASE3: `Seguridad/Roles.md`, `AuditLog.md`. |
| Ventas (Tickets) | Legacy | `docs/Ventas/*` | No hay carpeta V4.0 | Mantener en history; referenciar desde Reports. |
| BD / Migraciones | 75% | `docs/BD/Normalizacion` + FASE5 | 26 migraciones sin doc | Mapear en historial, no crear archivo nuevo. |
| UX | 6.5/10 | FASE6 | Loading states, notificaciones, confirmaciones | Documentar lineamientos en `Frontend/DesignSystem.md` y backlog UX. |

**Nota:** La matriz usa solo datos explicitados en FASE1–FASE6; no se añaden módulos nuevos.
