<!--
    NOTA DE SEGURIDAD:
    Este dashboard interno consulta /api/audit/logs usando un token Bearer.
    Se asume que window.TerrenaApiToken sólo se inyecta en usuarios con permiso alerts.view.
    Ese token NO debe existir para usuarios sin ese permiso.
    TODO: mover a consumo backend-side (sin exponer token al browser).
    TODO: migrar markup a Tailwind para alinear el estilo con el panel interno.
-->
<div class="audit-log-dashboard">
    <div class="card">
        <div class="card-header">
            <h3>Dashboard de Auditoría Operativa</h3>
        </div>
        <div class="card-body">
            <!-- Filtros -->
            <div class="row mb-3">
                <div class="col-md-2">
                    <label for="user_id" class="form-label">Usuario ID</label>
                    <input type="number" id="user_id" class="form-control" wire:model="user_id" placeholder="ID usuario">
                </div>
                <div class="col-md-2">
                    <label for="accion" class="form-label">Acción</label>
                    <input type="text" id="accion" class="form-control" wire:model="accion" placeholder="Ej: TRANSFER_POST">
                </div>
                <div class="col-md-2">
                    <label for="entidad" class="form-label">Entidad</label>
                    <input type="text" id="entidad" class="form-control" wire:model="entidad" placeholder="Ej: transfer">
                </div>
                <div class="col-md-2">
                    <label for="entidad_id" class="form-label">ID Entidad</label>
                    <input type="number" id="entidad_id" class="form-control" wire:model="entidad_id" placeholder="ID entidad">
                </div>
                <div class="col-md-2">
                    <label for="date_from" class="form-label">Desde</label>
                    <input type="date" id="date_from" class="form-control" wire:model="date_from">
                </div>
                <div class="col-md-2">
                    <label for="date_to" class="form-label">Hasta</label>
                    <input type="date" id="date_to" class="form-control" wire:model="date_to">
                </div>
            </div>

            <div class="mb-3">
                <button class="btn btn-primary" wire:click="search">Buscar</button>
            </div>

            <!-- Tabla de resultados -->
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Fecha/Hora</th>
                            <th>Usuario</th>
                            <th>Acción</th>
                            <th>Entidad</th>
                            <th>ID Entidad</th>
                            <th>Motivo</th>
                            <th>Evidencia</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td colspan="7" class="text-center text-muted" id="audit-results-placeholder">
                                Haga clic en "Buscar" para cargar los resultados de auditoría.<br>
                                <small>La búsqueda se realizará a través del endpoint API /api/audit/logs</small>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <div id="audit-results-container" style="display: none;">
                <!-- Los resultados se cargarán aquí dinámicamente vía JavaScript -->
            </div>
        </div>
    </div>

    <!-- Script para hacer la llamada al API y mostrar los resultados -->
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            if (window.Livewire && Livewire.on) {
                Livewire.on('audit-filters-updated', (event) => {
                    fetchAuditLogs(event.filters);
                });
            }
        });

        async function fetchAuditLogs(filters) {
            try {
                const tableBody = document.querySelector('.audit-log-dashboard table tbody');
                if (!tableBody) {
                    return;
                }

                tableBody.innerHTML = `<tr><td colspan="7" class="text-center">
                    <i class="fas fa-spinner fa-spin"></i> Cargando...
                </td></tr>`;
                
                // Obtener token de autorización (esto debe obtenerse de forma segura en producción)
                // En un entorno real, probablemente se obtenga del contexto de sesión
                const token = window.TerrenaApiToken; // Asumiendo que está disponible desde layouts/terrena.blade.php
                
                if (!token) {
                    console.error('No se encontró token de autorización para la API de auditoría');
                    tableBody.innerHTML = `<tr><td colspan="7" class="text-center text-danger">
                        Error: No se encontró token de autorización
                    </td></tr>`;
                    return;
                }
                
                // Hacer la solicitud al endpoint API
                const response = await fetch(`/api/audit/logs?${new URLSearchParams(filters)}`, {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    credentials: 'same-origin'
                });
                
                if (!response.ok) {
                    const error = await response.json();
                    throw new Error(error.message || `HTTP ${response.status}`);
                }
                
                const data = await response.json();
                
                if (data.ok && Array.isArray(data.data)) {
                    renderAuditResults(data.data);
                } else {
                    throw new Error('Formato de respuesta inesperado');
                }
            } catch (error) {
                console.error('Error al cargar logs de auditoría:', error);
                const tableBody = document.querySelector('.audit-log-dashboard table tbody');
                if (tableBody) {
                    tableBody.innerHTML = `<tr><td colspan="7" class="text-center text-danger">
                        Error: ${escapeHtml(error.message || 'Desconocido')}
                    </td></tr>`;
                }
            }
        }
        
        function renderAuditResults(results) {
            const tableBody = document.querySelector('.audit-log-dashboard table tbody');
            if (!tableBody) {
                return;
            }
            
            if (results.length === 0) {
                tableBody.innerHTML = `<tr><td colspan="7" class="text-center text-muted">
                    No se encontraron registros coincidentes
                </td></tr>`;
                return;
            }
            
            const rowsHtml = results.map(row => {
                const requiresInvestigation = Boolean(row.requires_investigation);
                const toleranciaFuera = Boolean(row.tolerancia_fuera);
                const isUserAccessEvent = ['USER_DISABLE', 'USER_ENABLE'].includes(row.accion);

                let rowClass = '';
                if (toleranciaFuera) {
                    rowClass = 'table-danger';
                } else if (requiresInvestigation) {
                    rowClass = 'table-warning';
                } else if (isUserAccessEvent) {
                    rowClass = 'table-info';
                }

                const badges = [];
                if (toleranciaFuera) {
                    badges.push('<span class="badge bg-danger text-white">Fuera de tolerancia</span>');
                }
                if (requiresInvestigation) {
                    badges.push('<span class="badge bg-warning text-dark">Requiere revisión</span>');
                }

                if (Array.isArray(row.payload?.differences) && row.payload.differences.length > 0) {
                    badges.push(`<span class="badge bg-secondary text-white">Dif: ${row.payload.differences.length}</span>`);
                }

                const badgeHtml = badges.length ? `<div class="small mt-1">${badges.join(' ')}</div>` : '';

                const evidencia = row.evidencia_url
                    ? `<a href="${escapeAttribute(row.evidencia_url)}" target="_blank" class="btn btn-sm btn-outline-primary">Ver</a>`
                    : 'N/A';

                return `
                    <tr class="${rowClass}">
                        <td>${formatDateTime(row.timestamp)}</td>
                        <td>${escapeHtml(String(row.user_id))}</td>
                        <td>${escapeHtml(row.accion || '')}</td>
                        <td>${escapeHtml(row.entidad || '')}</td>
                        <td>${escapeHtml(String(row.entidad_id))}</td>
                        <td>${escapeHtml(row.motivo || '')}${badgeHtml}</td>
                        <td>${evidencia}</td>
                    </tr>
                `;
            }).join('');

            tableBody.innerHTML = rowsHtml;
        }
        
        function formatDateTime(timestamp) {
            // Formatear fecha y hora para presentación
            const date = new Date(timestamp);
            return date.toLocaleString('es-MX', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        function escapeHtml(value) {
            return String(value ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        function escapeAttribute(value) {
            return escapeHtml(value).replace(/`/g, '&#96;');
        }
    </script>
</div>
