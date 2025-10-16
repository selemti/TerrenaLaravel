@extends('layouts.terrena')

@section('title', 'Personal - TerrenaPOS')
@section('page-title')
  <i class="fa-solid fa-user-group"></i><span class="label"> Personal</span>
@endsection

@section('content')
<div class="dashboard-grid">

  <ul class="nav nave nav-tabs mb-3">
    <li class="nav-item">
      <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tabEmpl">Empleados</button>
    </li>
    <li class="nav-item">
      <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabRoles">Roles</button>
    </li>
    <li class="nav-item">
      <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabPerms">Permisos</button>
    </li>
    <li class="nav-item">
      <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabHor">Horarios</button>
    </li>
    <li class="nav-item">
      <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabAudit">Auditoría</button>
    </li>
  </ul>

  <div class="tab-content">

    {{-- Tab Empleados --}}
    <div class="tab-pane fade show active" id="tabEmpl">
      <div class="d-flex justify-content-between mb-2">
        <div class="small text-muted">Empleados (maqueta)</div>
        @can('people.employees.manage')
          <button class="btn btn-sm btn-primary">Nuevo empleado</button>
        @else
          {{-- Si no tienes sistema de permisos, puedes mostrar el botón siempre --}}
          <button class="btn btn-sm btn-primary">Nuevo empleado</button>
        @endcan
      </div>
      <div class="table-responsive">
        <table class="table table-sm align-middle mb-0">
          <thead>
            <tr>
              <th>Usuario</th>
              <th>Nombre</th>
              <th>Rol</th>
              <th>Sucursal</th>
              <th>Estatus</th>
              <th class="text-end">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>jperez</td>
              <td>Juan Pérez</td>
              <td>Gerente</td>
              <td>PRINCIPAL</td>
              <td><span class="badge bg-success">Activo</span></td>
              <td class="text-end">
                @can('people.employees.manage')
                  <div class="btn-group btn-group-sm">
                    <button class="btn btn-outline-secondary">Editar</button>
                    <button class="btn btn-outline-danger">Desactivar</button>
                  </div>
                @else
                  <div class="btn-group btn-group-sm">
                    <button class="btn btn-outline-secondary">Editar</button>
                    <button class="btn btn-outline-danger">Desactivar</button>
                  </div>
                @endcan
              </td>
            </tr>
            <tr>
              <td>ambarista</td>
              <td>Ana Barista</td>
              <td>Cajero</td>
              <td>PRINCIPAL</td>
              <td><span class="badge bg-success">Activo</span></td>
              <td class="text-end">
                @can('people.employees.manage')
                  <div class="btn-group btn-group-sm">
                    <button class="btn btn-outline-secondary">Editar</button>
                    <button class="btn btn-outline-danger">Desactivar</button>
                  </div>
                @else
                  <div class="btn-group btn-group-sm">
                    <button class="btn btn-outline-secondary">Editar</button>
                    <button class="btn btn-outline-danger">Desactivar</button>
                  </div>
                @endcan
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    {{-- Tab Roles --}}
    <div class="tab-pane fade" id="tabRoles">
      <div class="d-flex justify-content-between mb-2">
        <div class="small text-muted">Roles (conjunto de permisos)</div>
        @can('people.roles.manage')
          <button class="btn btn-sm btn-primary">Nuevo rol</button>
        @else
          <button class="btn btn-sm btn-primary">Nuevo rol</button>
        @endcan
      </div>
      <div class="table-responsive">
        <table class="table table-sm align-middle mb-0">
          <thead>
            <tr>
              <th>Rol</th>
              <th>Descripción</th>
              <th>Permisos</th>
              <th class="text-end">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Gerente</td>
              <td>Acceso total operativo</td>
              <td>
                <span class="badge bg-light text-dark">inventory.*</span>
                <span class="badge bg-light text-dark">purchasing.*</span>
                <span class="badge bg-light text-dark">reports.*</span>
              </td>
              <td class="text-end">
                @can('people.roles.manage')
                  <button class="btn btn-sm btn-outline-secondary">Editar</button>
                @else
                  <button class="btn btn-sm btn-outline-secondary">Editar</button>
                @endcan
              </td>
            </tr>
            <tr>
              <td>Cajero</td>
              <td>Operación de caja</td>
              <td>
                <span class="badge bg-light text-dark">cashcuts.view</span>
              </td>
              <td class="text-end">
                @can('people.roles.manage')
                  <button class="btn btn-sm btn-outline-secondary">Editar</button>
                @else
                  <button class="btn btn-sm btn-outline-secondary">Editar</button>
                @endcan
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    {{-- Tab Permisos (matriz) --}}
    <div class="tab-pane fade" id="tabPerms">
      <div class="alert alert-info small">
        Matriz de permisos por rol. Estos permisos son propios del sistema (no los del POS).
      </div>
      @can('people.permissions.manage')
        <div class="table-responsive">
          <table class="table table-sm align-middle mb-0">
            <thead>
              <tr>
                <th>Permiso</th>
                <th>Gerente</th>
                <th>Supervisor</th>
                <th>Cajero</th>
                <th>Almacén</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>dashboard.view</td>
                <td>✓</td>
                <td>✓</td>
                <td>✓</td>
                <td>✓</td>
              </tr>
              <tr>
                <td>inventory.view</td>
                <td>✓</td>
                <td>✓</td>
                <td>✖</td>
                <td>✓</td>
              </tr>
              <tr>
                <td>inventory.move</td>
                <td>✓</td>
                <td>✓</td>
                <td>✖</td>
                <td>✓</td>
              </tr>
              <tr>
                <td>purchasing.view</td>
                <td>✓</td>
                <td>✓</td>
                <td>✖</td>
                <td>✓</td>
              </tr>
              <tr>
                <td>cashcuts.view</td>
                <td>✓</td>
                <td>✓</td>
                <td>✓</td>
                <td>✖</td>
              </tr>
              <tr>
                <td>people.employees.manage</td>
                <td>✓</td>
                <td>✖</td>
                <td>✖</td>
                <td>✖</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="text-end mt-2">
          <button class="btn btn-sm btn-primary">Guardar matriz</button>
        </div>
      @else
        {{-- Sin sistema de permisos, muestra la tabla siempre --}}
        <div class="table-responsive">
          <table class="table table-sm align-middle mb-0">
            <thead>
              <tr>
                <th>Permiso</th>
                <th>Gerente</th>
                <th>Supervisor</th>
                <th>Cajero</th>
                <th>Almacén</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>dashboard.view</td>
                <td>✓</td>
                <td>✓</td>
                <td>✓</td>
                <td>✓</td>
              </tr>
              <tr>
                <td>inventory.view</td>
                <td>✓</td>
                <td>✓</td>
                <td>✖</td>
                <td>✓</td>
              </tr>
              <tr>
                <td>inventory.move</td>
                <td>✓</td>
                <td>✓</td>
                <td>✖</td>
                <td>✓</td>
              </tr>
              <tr>
                <td>purchasing.view</td>
                <td>✓</td>
                <td>✓</td>
                <td>✖</td>
                <td>✓</td>
              </tr>
              <tr>
                <td>cashcuts.view</td>
                <td>✓</td>
                <td>✓</td>
                <td>✓</td>
                <td>✖</td>
              </tr>
              <tr>
                <td>people.employees.manage</td>
                <td>✓</td>
                <td>✖</td>
                <td>✖</td>
                <td>✖</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="text-end mt-2">
          <button class="btn btn-sm btn-primary">Guardar matriz</button>
        </div>
      @endcan
    </div>

    {{-- Tab Horarios --}}
    <div class="tab-pane fade" id="tabHor">
      <div class="d-flex justify-content-between mb-2">
        <div class="small text-muted">Horarios y asignación de turnos</div>
        @can('people.schedules.manage')
          <button class="btn btn-sm btn-primary">Nuevo turno</button>
        @else
          <button class="btn btn-sm btn-primary">Nuevo turno</button>
        @endcan
      </div>
      <div class="table-responsive">
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Empleado</th>
              <th>Sucursal</th>
              <th>Turno</th>
              <th>Días</th>
              <th class="text-end">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>jperez</td>
              <td>PRINCIPAL</td>
              <td>08:00–16:00</td>
              <td>L-Mi-V</td>
              <td class="text-end">
                @can('people.schedules.manage')
                  <button class="btn btn-sm btn-outline-secondary">Editar</button>
                @else
                  <button class="btn btn-sm btn-outline-secondary">Editar</button>
                @endcan
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    {{-- Tab Auditoría --}}
    <div class="tab-pane fade" id="tabAudit">
      @can('people.audit.view')
        <div class="alert alert-secondary small">
          Bitácora de acciones: altas/bajas, cambios de roles, inicios de sesión, etc.
        </div>
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Fecha/Hora</th>
              <th>Usuario</th>
              <th>Acción</th>
              <th>Detalle</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>2025-08-30 10:15</td>
              <td>jperez</td>
              <td>Actualizó permisos</td>
              <td>Rol Supervisor: +inventory.move</td>
            </tr>
          </tbody>
        </table>
      @else
        {{-- Sin sistema de permisos, muestra la tabla siempre --}}
        <div class="alert alert-secondary small">
          Bitácora de acciones: altas/bajas, cambios de roles, inicios de sesión, etc.
        </div>
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Fecha/Hora</th>
              <th>Usuario</th>
              <th>Acción</th>
              <th>Detalle</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>2025-08-30 10:15</td>
              <td>jperez</td>
              <td>Actualizó permisos</td>
              <td>Rol Supervisor: +inventory.move</td>
            </tr>
          </tbody>
        </table>
      @endcan
    </div>

  </div>
</div>
@endsection