@extends('layouts.terrena')

@section('title', 'Aprobación de Cortes Irregulares')

@section('page-title')
    <div class="d-flex align-items-center justify-content-between mb-2">
        <div class="d-flex align-items-center gap-2">
            <h2 class="mb-0"><i class="fa-solid fa-user-check me-2"></i> Aprobación de Cortes Irregulares</h2>
        </div>
    </div>
@endsection

@section('content')

<div class="dashboard-grid">
  <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
    <div>
      <p class="text-muted mb-0">Postcortes que requieren validación de supervisor</p>
    </div>
    <div>
      <button type="button" class="btn btn-outline-primary btn-sm" onclick="refreshTable()">
        <i class="fa-solid fa-sync me-1"></i> Refrescar
      </button>
    </div>
  </div>

  <!-- Alert placeholder -->
  <div id="alertContainer"></div>

  <!-- Pending postcortes table -->
  <div class="card">
    <div class="card-header py-2 d-flex justify-content-between align-items-center">
      <strong>Cortes Pendientes de Aprobación</strong>
      <span id="pendingCount" class="badge bg-warning">-</span>
    </div>
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" id="postcortesTable">
          <thead class="table-light">
            <tr>
              <th>ID</th>
              <th>Sesión ID</th>
              <th>Terminal</th>
              <th>Cajero</th>
              <th>Total Declarado</th>
              <th>Diferencia</th>
              <th>Motivo Irregular</th>
              <th>Fecha</th>
              <th class="text-end">Acciones</th>
            </tr>
          </thead>
          <tbody id="postcortesTableBody">
            <tr>
              <td colspan="9" class="text-center py-4 text-muted">
                <i class="fa-solid fa-spinner fa-spin me-2"></i>
                Cargando postcortes pendientes...
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<!-- Modal: Ver Detalle -->
<div class="modal fade" id="modalDetalle" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Detalle del Postcorte</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body" id="modalDetalleBody">
        <div class="text-center py-4">
          <i class="fa-solid fa-spinner fa-spin fa-2x"></i>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
      </div>
    </div>
  </div>
</div>

<!-- Modal: Aprobar Postcorte -->
<div class="modal fade" id="modalAprobar" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Aprobar Postcorte</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-info mb-3">
          <i class="fa-solid fa-info-circle me-2"></i>
          ¿Confirmas que deseas aprobar este postcorte irregular?
        </div>
        <p><strong>Postcorte ID:</strong> <span id="aprobarPostcorteId">-</span></p>
        <p><strong>Terminal:</strong> <span id="aprobarTerminalId">-</span></p>
        <p><strong>Diferencia:</strong> <span id="aprobarDiferencia">-</span></p>

        <div class="mb-3">
          <label for="aprobarNotas" class="form-label">Notas de aprobación (opcional)</label>
          <textarea id="aprobarNotas" class="form-control" rows="3" placeholder="Comentarios sobre la aprobación..."></textarea>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
        <button type="button" class="btn btn-success" onclick="confirmarAprobar()">
          <i class="fa-solid fa-check me-1"></i> Aprobar
        </button>
      </div>
    </div>
  </div>
</div>

<!-- Modal: Rechazar Postcorte -->
<div class="modal fade" id="modalRechazar" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Rechazar Postcorte</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-warning mb-3">
          <i class="fa-solid fa-exclamation-triangle me-2"></i>
          El postcorte será rechazado y la sesión será reabierta para que el cajero pueda corregir.
        </div>
        <p><strong>Postcorte ID:</strong> <span id="rechazarPostcorteId">-</span></p>
        <p><strong>Terminal:</strong> <span id="rechazarTerminalId">-</span></p>

        <div class="mb-3">
          <label for="rechazarMotivo" class="form-label">Motivo del rechazo <span class="text-danger">*</span></label>
          <textarea id="rechazarMotivo" class="form-control" rows="3" placeholder="Explica por qué rechazas este postcorte..." required></textarea>
          <small class="text-muted">Este campo es obligatorio</small>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
        <button type="button" class="btn btn-danger" onclick="confirmarRechazar()">
          <i class="fa-solid fa-times me-1"></i> Rechazar
        </button>
      </div>
    </div>
  </div>
</div>

</div>

@endsection

@push('scripts')
<script type="module">
  let currentPostcorteId = null;
  let postcortesPendientes = [];

  // Get base path
  const basePath = window.__BASE__ || '';

  // Initialize on page load
  document.addEventListener('DOMContentLoaded', () => {
    loadPostcortes();
  });

  /**
   * Load pending postcortes from API
   */
  async function loadPostcortes() {
    const tbody = document.getElementById('postcortesTableBody');
    const countBadge = document.getElementById('pendingCount');

    tbody.innerHTML = '<tr><td colspan="9" class="text-center py-4 text-muted"><i class="fa-solid fa-spinner fa-spin me-2"></i>Cargando...</td></tr>';

    try {
      const response = await fetch(basePath + '/api/caja/postcortes/pendientes-aprobacion', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      });

      const data = await response.json();

      if (!data.ok) {
        throw new Error(data.detail || data.error || 'Error al cargar postcortes');
      }

      postcortesPendientes = data.data || [];
      renderTable(postcortesPendientes);
      countBadge.textContent = postcortesPendientes.length;

    } catch (error) {
      console.error('Error loading postcortes:', error);
      tbody.innerHTML = `<tr><td colspan="9" class="text-center py-4 text-danger"><i class="fa-solid fa-exclamation-circle me-2"></i>Error: ${error.message}</td></tr>`;
      countBadge.textContent = '!';
    }
  }

  /**
   * Render postcortes table
   */
  function renderTable(postcortes) {
    const tbody = document.getElementById('postcortesTableBody');

    if (!postcortes || postcortes.length === 0) {
      tbody.innerHTML = '<tr><td colspan="9" class="text-center py-4 text-muted">No hay postcortes pendientes de aprobación</td></tr>';
      return;
    }

    tbody.innerHTML = postcortes.map(pc => `
      <tr>
        <td>${pc.id}</td>
        <td>${pc.sesion_id}</td>
        <td>${pc.terminal_id || '-'}</td>
        <td>${pc.cajero_nombre || 'N/A'}</td>
        <td class="text-end">$${parseFloat(pc.total_declarado_efectivo || 0).toFixed(2)}</td>
        <td class="text-end ${getDiferenciaClass(pc.diferencia_efectivo)}">
          $${parseFloat(pc.diferencia_efectivo || 0).toFixed(2)}
        </td>
        <td><small>${pc.motivo_irregular || '-'}</small></td>
        <td><small>${formatDate(pc.creado_en)}</small></td>
        <td class="text-end">
          <button class="btn btn-sm btn-outline-primary me-1" onclick="verDetalle(${pc.id})" title="Ver detalle">
            <i class="fa-solid fa-eye"></i>
          </button>
          <button class="btn btn-sm btn-success me-1" onclick="showAprobarModal(${pc.id})" title="Aprobar">
            <i class="fa-solid fa-check"></i>
          </button>
          <button class="btn btn-sm btn-danger" onclick="showRechazarModal(${pc.id})" title="Rechazar">
            <i class="fa-solid fa-times"></i>
          </button>
        </td>
      </tr>
    `).join('');
  }

  /**
   * Get CSS class for diferencia value
   */
  function getDiferenciaClass(diff) {
    const d = parseFloat(diff || 0);
    if (Math.abs(d) < 0.01) return 'text-success';
    if (d > 0) return 'text-primary';
    return 'text-danger';
  }

  /**
   * Format date string
   */
  function formatDate(dateStr) {
    if (!dateStr) return '-';
    const d = new Date(dateStr);
    return d.toLocaleString('es-MX', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  /**
   * View postcorte detail
   */
  window.verDetalle = async function(postcorteId) {
    const modal = new bootstrap.Modal(document.getElementById('modalDetalle'));
    const body = document.getElementById('modalDetalleBody');

    body.innerHTML = '<div class="text-center py-4"><i class="fa-solid fa-spinner fa-spin fa-2x"></i></div>';
    modal.show();

    try {
      const response = await fetch(`${basePath}/api/caja/postcortes/${postcorteId}`, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      });

      const data = await response.json();

      if (!data.ok) {
        throw new Error(data.detail || 'Error al cargar detalle');
      }

      const pc = data.data;
      body.innerHTML = renderDetalle(pc);

    } catch (error) {
      body.innerHTML = `<div class="alert alert-danger">Error: ${error.message}</div>`;
    }
  };

  /**
   * Render postcorte detail HTML
   */
  function renderDetalle(pc) {
    return `
      <div class="row g-3">
        <div class="col-md-6">
          <p class="mb-2"><strong>Postcorte ID:</strong> ${pc.id}</p>
          <p class="mb-2"><strong>Sesión ID:</strong> ${pc.sesion_id}</p>
          <p class="mb-2"><strong>Terminal:</strong> ${pc.terminal_id || '-'}</p>
          <p class="mb-2"><strong>Cajero:</strong> ${pc.cajero_nombre || 'N/A'}</p>
        </div>
        <div class="col-md-6">
          <p class="mb-2"><strong>Fecha Creación:</strong> ${formatDate(pc.creado_en)}</p>
          <p class="mb-2"><strong>Total Declarado:</strong> $${parseFloat(pc.total_declarado_efectivo || 0).toFixed(2)}</p>
          <p class="mb-2"><strong>Diferencia:</strong> <span class="${getDiferenciaClass(pc.diferencia_efectivo)}">$${parseFloat(pc.diferencia_efectivo || 0).toFixed(2)}</span></p>
        </div>
        <div class="col-12">
          <p class="mb-2"><strong>Motivo Irregular:</strong></p>
          <div class="alert alert-warning">${pc.motivo_irregular || 'No especificado'}</div>
        </div>
        <div class="col-12">
          <p class="mb-2"><strong>Notas:</strong></p>
          <p class="text-muted">${pc.notas || 'Sin notas'}</p>
        </div>
      </div>
    `;
  }

  /**
   * Show aprobar modal
   */
  window.showAprobarModal = function(postcorteId) {
    const pc = postcortesPendientes.find(p => p.id === postcorteId);
    if (!pc) return;

    currentPostcorteId = postcorteId;
    document.getElementById('aprobarPostcorteId').textContent = pc.id;
    document.getElementById('aprobarTerminalId').textContent = pc.terminal_id || '-';
    document.getElementById('aprobarDiferencia').textContent = '$' + parseFloat(pc.diferencia_efectivo || 0).toFixed(2);
    document.getElementById('aprobarNotas').value = '';

    const modal = new bootstrap.Modal(document.getElementById('modalAprobar'));
    modal.show();
  };

  /**
   * Show rechazar modal
   */
  window.showRechazarModal = function(postcorteId) {
    const pc = postcortesPendientes.find(p => p.id === postcorteId);
    if (!pc) return;

    currentPostcorteId = postcorteId;
    document.getElementById('rechazarPostcorteId').textContent = pc.id;
    document.getElementById('rechazarTerminalId').textContent = pc.terminal_id || '-';
    document.getElementById('rechazarMotivo').value = '';

    const modal = new bootstrap.Modal(document.getElementById('modalRechazar'));
    modal.show();
  };

  /**
   * Confirm approval
   */
  window.confirmarAprobar = async function() {
    const notas = document.getElementById('aprobarNotas').value.trim();

    try {
      const response = await fetch(`${basePath}/api/caja/postcortes/${currentPostcorteId}/aprobar`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ notas })
      });

      const data = await response.json();

      if (!data.ok) {
        throw new Error(data.detail || data.error || 'Error al aprobar');
      }

      showAlert('success', 'Postcorte aprobado exitosamente');
      bootstrap.Modal.getInstance(document.getElementById('modalAprobar')).hide();
      loadPostcortes();

    } catch (error) {
      showAlert('danger', 'Error: ' + error.message);
    }
  };

  /**
   * Confirm rejection
   */
  window.confirmarRechazar = async function() {
    const motivo = document.getElementById('rechazarMotivo').value.trim();

    if (!motivo) {
      alert('Por favor, proporciona el motivo del rechazo');
      return;
    }

    try {
      const response = await fetch(`${basePath}/api/caja/postcortes/${currentPostcorteId}/rechazar`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ motivo_rechazo: motivo })
      });

      const data = await response.json();

      if (!data.ok) {
        throw new Error(data.detail || data.error || 'Error al rechazar');
      }

      showAlert('warning', 'Postcorte rechazado. La sesión ha sido reabierta.');
      bootstrap.Modal.getInstance(document.getElementById('modalRechazar')).hide();
      loadPostcortes();

    } catch (error) {
      showAlert('danger', 'Error: ' + error.message);
    }
  };

  /**
   * Refresh table
   */
  window.refreshTable = function() {
    loadPostcortes();
  };

  /**
   * Show alert message
   */
  function showAlert(type, message) {
    const container = document.getElementById('alertContainer');
    const alert = `
      <div class="alert alert-${type} alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    `;
    container.innerHTML = alert;

    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      const alertElement = container.querySelector('.alert');
      if (alertElement) {
        const bsAlert = new bootstrap.Alert(alertElement);
        bsAlert.close();
      }
    }, 5000);
  }
</script>

<style>
  .table tbody tr:hover {
    background-color: #f8f9fa;
    cursor: pointer;
  }
</style>
@endpush
