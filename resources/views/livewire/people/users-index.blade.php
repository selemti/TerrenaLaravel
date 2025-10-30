<div>
    @section('page-title')
        <i class="fa-solid fa-user-group"></i> <span class="label">Personal</span>
    @endsection

    <div class="mb-3">
        <h2 class="h4 fw-semibold mb-1">Gestión de personal</h2>
        <p class="text-muted small mb-0">Administra usuarios, plantillas y permisos del sistema Terrena.</p>
    </div>

    <div class="mb-3">
        <ul class="nav nav-pills gap-2">
            <li class="nav-item">
                <button class="nav-link @if($activeTab === 'users') active @endif" wire:click="$set('activeTab','users')">
                    <i class="fa-solid fa-id-badge me-1"></i>Usuarios
                </button>
            </li>
            <li class="nav-item">
                <button class="nav-link @if($activeTab === 'roles') active @endif" wire:click="$set('activeTab','roles')">
                    <i class="fa-solid fa-user-shield me-1"></i>Plantillas
                </button>
            </li>
            <li class="nav-item">
                <button class="nav-link @if($activeTab === 'permissions') active @endif" wire:click="$set('activeTab','permissions')">
                    <i class="fa-solid fa-lock me-1"></i>Permisos
                </button>
            </li>
        </ul>
    </div>

    @if (session()->has('user-notice'))
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fa-solid fa-circle-check me-1"></i>{{ session('user-notice') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
        </div>
    @endif

    @if (session()->has('role-notice'))
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fa-solid fa-circle-check me-1"></i>{{ session('role-notice') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
        </div>
    @endif

    <div class="tab-content">
        <!-- Tab de Usuarios -->
        <div class="tab-pane fade @if($activeTab === 'users') show active @endif" id="tab-users">
            <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-2 mb-3">
                <div class="input-group input-group-sm" style="max-width: 320px;">
                    <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
                    <input type="search" class="form-control" placeholder="Buscar por nombre, usuario o correo"
                           wire:model.debounce.500ms="userSearch">
                </div>
                @can('people.users.manage')
                    <div class="d-flex gap-2">
                        <button class="btn btn-sm btn-success" wire:click="openCreateForm">
                            <i class="fa-solid fa-user-plus me-1"></i>Nuevo usuario
                        </button>
                    </div>
                @endcan
            </div>

            <div class="table-responsive mb-3">
                <table class="table table-sm align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Usuario</th>
                            <th>Nombre</th>
                            <th>Correo</th>
                            <th>Roles</th>
                            <th class="text-center">Estatus</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($users as $user)
                            <tr>
                                <td>{{ $user->username ?? '—' }}</td>
                                <td>{{ $user->nombre_completo ?? '—' }}</td>
                                <td>{{ $user->email ?? '—' }}</td>
                                <td>
                                    @if (isset($user->roles) && $user->roles->count() > 0)
                                        @foreach ($user->roles->take(3) as $role)
                                            <span class="badge bg-light text-dark">{{ $role->name }}</span>
                                        @endforeach
                                        @if ($user->roles->count() > 3)
                                            <span class="badge bg-secondary">+{{ $user->roles->count() - 3 }}</span>
                                        @endif
                                    @else
                                        <span class="text-muted">Sin roles</span>
                                    @endif
                                </td>
                                <td class="text-center">
                                    @if ($user->activo)
                                        <span class="badge bg-success">Activo</span>
                                    @else
                                        <span class="badge bg-secondary">Inactivo</span>
                                    @endif
                                </td>
                                <td class="text-end">
                                    <div class="btn-group btn-group-sm" role="group">
                                        @can('people.users.manage')
                                            <button class="btn btn-outline-secondary" wire:click="openEditForm({{ $user->id }})">
                                                <i class="fa-solid fa-pen"></i>
                                            </button>
                                            <button class="btn btn-outline-{{ $user->activo ? 'warning' : 'success' }}"
                                                    wire:click="toggleActive({{ $user->id }})">
                                                <i class="fa-solid fa-power-off"></i>
                                            </button>
                                        @endcan
                                        @can('people.roles.manage')
                                            <button class="btn btn-outline-primary" title="Asignar plantillas"
                                                    wire:click="openUserRolesModal({{ $user->id }})">
                                                <i class="fa-solid fa-user-tag"></i>
                                            </button>
                                        @endcan
                                        @can('people.permissions.manage')
                                            <button class="btn btn-outline-info" title="Permisos especiales"
                                                    wire:click="openUserPermissionsModal({{ $user->id }})">
                                                <i class="fa-solid fa-key"></i>
                                            </button>
                                        @endcan
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="text-center text-muted py-4">
                                    <i class="fa-regular fa-circle-question me-1"></i>No se encontraron usuarios con los filtros actuales.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <div class="d-flex justify-content-end">
                {{ $users->links() }}
            </div>
        </div>

        <!-- Tab de Plantillas -->
        <div class="tab-pane fade @if($activeTab === 'roles') show active @endif" id="tab-roles">
            <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-2 mb-3">
                @can('people.roles.manage')
                    <div>
                        <button class="btn btn-sm btn-success" wire:click="openCreateRoleForm">
                            <i class="fa-solid fa-plus me-1"></i>Nueva plantilla
                        </button>
                    </div>
                @endcan
            </div>

            <div class="table-responsive mb-3">
                <table class="table table-sm align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Nombre</th>
                            <th>Descripción</th>
                            <th class="text-center">Permisos</th>
                            <th class="text-center">Usuarios</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($roles as $role)
                            <tr>
                                <td>
                                    <div class="fw-bold">{{ $role['display_name'] }}</div>
                                    <div class="small text-muted">{{ $role['name'] }}</div>
                                </td>
                                <td>{{ $role['description'] ?? '—' }}</td>
                                <td class="text-center">
                                    <span class="badge bg-primary">{{ $role['permissions_count'] }}</span>
                                </td>
                                <td class="text-center">
                                    <span class="badge bg-info">{{ $role['users_count'] }}</span>
                                </td>
                                <td class="text-end">
                                    <div class="btn-group btn-group-sm" role="group">
                                        @can('people.roles.manage')
                                            <button class="btn btn-outline-secondary" 
                                                    wire:click="loadRoleForEdit({{ $role['id'] }})">
                                                <i class="fa-solid fa-pen"></i>
                                            </button>
                                            @if ($role['is_super_admin'])
                                                <button class="btn btn-outline-secondary" disabled title="Sistema">
                                                    <i class="fa-solid fa-lock"></i>
                                                </button>
                                            @else
                                                <button class="btn btn-outline-warning"
                                                        wire:click="duplicateRole({{ $role['id'] }})"
                                                        title="Duplicar plantilla">
                                                    <i class="fa-solid fa-copy"></i>
                                                </button>
                                                <button class="btn btn-outline-danger"
                                                        wire:click="deleteRole({{ $role['id'] }})"
                                                        @disabled($role['users_count'] > 0)
                                                        title="Eliminar plantilla">
                                                    <i class="fa-solid fa-trash"></i>
                                                </button>
                                            @endif
                                        @endcan
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="text-center text-muted py-4">
                                    <i class="fa-regular fa-circle-question me-1"></i>No se encontraron plantillas.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <!--
            SEGURIDAD / CONTROL DE ACCESO:
            Esta pestaña expone el catálogo completo de permisos del sistema
            (toda la matriz de control interno).
            SOLO se debe mostrar a usuarios con rol de administrador de acceso.
            TODO: proteger esta pestaña con gate/policy antes de ir a producción.
        -->
        <!-- Tab de Permisos -->
        <div class="tab-pane fade @if($activeTab === 'permissions') show active @endif" id="tab-permissions">
            <div class="row">
                <div class="col-12">
                    <div class="card shadow-sm mb-3">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-center mb-3">
                                <h5 class="card-title mb-0">Catálogo de permisos por módulo</h5>
                                <div class="d-flex gap-2">
                                    <button class="btn btn-sm btn-outline-secondary" disabled>
                                        <i class="fa-solid fa-download me-1"></i>
                                        Exportar
                                    </button>
                                    <!-- TODO: exportar catálogo de permisos a CSV para auditoría externa -->
                                </div>
                            </div>
                            
                            <!-- Pestañas para módulos de permisos -->
                            <ul class="nav nav-tabs mb-3" id="permModulesTab" role="tablist">
                                @foreach($permissionsMap as $module => $modulePerms)
                                    <li class="nav-item" role="presentation">
                                        <button class="nav-link {{ $loop->first ? 'active' : '' }}" 
                                                id="{{ \Illuminate\Support\Str::slug($module) }}-perm-tab" 
                                                data-bs-toggle="tab" 
                                                data-bs-target="#{{ \Illuminate\Support\Str::slug($module) }}-perm" 
                                                type="button" 
                                                role="tab">
                                            {{ $module }} 
                                            <span class="badge bg-secondary ms-1">{{ count($modulePerms) }}</span>
                                        </button>
                                    </li>
                                @endforeach
                            </ul>

                            <div class="tab-content" id="permModulesTabContent">
                                @foreach($permissionsMap as $module => $modulePerms)
                                    <div class="tab-pane fade {{ $loop->first ? 'show active' : '' }}" 
                                         id="{{ \Illuminate\Support\Str::slug($module) }}-perm" 
                                         role="tabpanel">
                                        <div class="row">
                                            @forelse($modulePerms as $permMeta)
                                                @php
                                                    $permName = $permMeta['perm'];
                                                    $label = $permMeta['label'];
                                                    $desc = $permMeta['desc'];
                                                @endphp
                                                <div class="col-md-6 mb-2">
                                                    <div class="card h-100">
                                                        <div class="card-body p-3">
                                                            <h6 class="card-title mb-1">{{ $label }}</h6>
                                                            <p class="card-text small text-muted mb-1">{{ $permName }}</p>
                                                            <p class="card-text small mb-0">{{ $desc }}</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            @empty
                                                <div class="col-12">
                                                    <p class="text-muted small mb-0">No hay permisos definidos en este módulo.</p>
                                                </div>
                                            @endforelse
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        </div>
                    </div>
                    
                    <!-- Estadísticas de permisos -->
                    <div class="row">
                        <div class="col-md-4">
                            <div class="card text-bg-light">
                                <div class="card-body p-3">
                                    <h6 class="card-title">Total de Permisos</h6>
                                    <h3 class="card-text">{{ count($permissions->toArray()) }}</h3>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="card text-bg-primary">
                                <div class="card-body p-3">
                                    <h6 class="card-title">Módulos</h6>
                                    <h3 class="card-text">{{ count($permissionsMap) }}</h3>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="card text-bg-success">
                                <div class="card-body p-3">
                                    <h6 class="card-title">Roles</h6>
                                    <h3 class="card-text">{{ count($roles) }}</h3>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal de edición/creación de usuario -->
    @if($showUserModal)
    <div class="modal fade show d-block" tabindex="-1" style="background-color: rgba(0,0,0,0.5);">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        @if ($editingUser)
                            <i class="fa-solid fa-user-pen me-1"></i>Editar usuario
                        @else
                            <i class="fa-solid fa-user-plus me-1"></i>Nuevo usuario
                        @endif
                    </h5>
                    <button type="button" class="btn-close" wire:click="closeUserModal"></button>
                </div>
                <form wire:submit.prevent="saveUser">
                    <div class="modal-body">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Nombre completo <span class="text-danger">*</span></label>
                                <input type="text" class="form-control @error('userForm.nombre_completo') is-invalid @enderror"
                                       wire:model.defer="userForm.nombre_completo" required>
                                @error('userForm.nombre_completo')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Usuario</label>
                                <input type="text" class="form-control @error('userForm.username') is-invalid @enderror"
                                       wire:model.defer="userForm.username" autocomplete="username" @disabled($editingUser)>
                                @error('userForm.username')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Correo electrónico <span class="text-danger">*</span></label>
                                <input type="email" class="form-control @error('userForm.email') is-invalid @enderror"
                                       wire:model.defer="userForm.email" autocomplete="email" required @disabled($editingUser && ! empty($userForm['email']))>
                                @error('userForm.email')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Estatus</label>
                                <select class="form-select" wire:model.defer="userForm.activo">
                                    <option value="1">Activo</option>
                                    <option value="0">Inactivo</option>
                                </select>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">
                                    {{ $editingUser ? 'Nueva contraseña' : 'Contraseña' }} @unless($editingUser)<span class="text-danger">*</span>@endunless
                                </label>
                                <input type="password" class="form-control @error('userForm.password') is-invalid @enderror"
                                       wire:model.defer="userForm.password" autocomplete="new-password">
                                @error('userForm.password')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Confirmar contraseña</label>
                                <input type="password" class="form-control" wire:model.defer="userForm.password_confirmation" autocomplete="new-password">
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" wire:click="closeUserModal">
                            Cancelar
                        </button>
                        <button type="submit" class="btn btn-success">
                            <i class="fa-solid fa-floppy-disk me-1"></i>Guardar
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    @endif

    <!-- Modal de edición/creación de plantilla -->
    @if($showRoleModal)
    <div class="modal fade show d-block" tabindex="-1" style="background-color: rgba(0,0,0,0.5);">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        @if ($editingRole)
                            <i class="fa-solid fa-user-shield me-1"></i>Editar plantilla
                        @else
                            <i class="fa-solid fa-user-shield me-1"></i>Nueva plantilla
                        @endif
                    </h5>
                    <button type="button" class="btn-close" wire:click="closeRoleModal"></button>
                </div>
                <form wire:submit.prevent="saveRole">
                    <div class="modal-body">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Nombre interno <span class="text-danger">*</span></label>
                                <input type="text" class="form-control @error('roleForm.name') is-invalid @enderror"
                                       wire:model.defer="roleForm.name" 
                                       @disabled($editingRole && $roleForm['is_super_admin'] ?? false)
                                       required>
                                @error('roleForm.name')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                                <div class="form-text">Nombre único para identificar la plantilla en el sistema</div>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">Nombre para mostrar</label>
                                <input type="text" class="form-control @error('roleForm.display_name') is-invalid @enderror"
                                       wire:model.defer="roleForm.display_name"
                                       @disabled($editingRole && $roleForm['is_super_admin'] ?? false)>
                                @error('roleForm.display_name')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                                <div class="form-text">Nombre legible para mostrar en la interfaz</div>
                            </div>

                            <div class="col-12">
                                <label class="form-label">Descripción</label>
                                <textarea class="form-control @error('roleForm.description') is-invalid @enderror"
                                          wire:model.defer="roleForm.description" 
                                          @disabled($editingRole && $roleForm['is_super_admin'] ?? false)
                                          rows="2"></textarea>
                                @error('roleForm.description')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                                <div class="form-text">Descripción opcional de la función o responsabilidades de la plantilla</div>
                            </div>

                            <div class="col-12">
                                <label class="form-label">Permisos de la plantilla</label>
                                <div class="border rounded p-3" style="max-height:40vh; overflow:auto;">
                                    @foreach($permissionsByModule as $moduleName => $modulePermissions)
                                        <div class="mb-3">
                                            <h6 class="mb-2">{{ $moduleName }}</h6>
                                            <div class="row">
                                                @foreach($modulePermissions as $permData)
                                                    @php
                                                        $permissionName = $permData['perm'];
                                                        $isChecked = in_array($permissionName, $roleForm['permissions'], true);
                                                    @endphp
                                                    <div class="col-md-6 col-lg-4">
                                                        <div class="form-check mb-1">
                                                            <input class="form-check-input"
                                                                   type="checkbox"
                                                                   id="perm_{{ md5($permissionName) }}"
                                                                   @checked($isChecked)
                                                                   @disabled($editingRole && $roleForm['is_super_admin'] ?? false)
                                                                   wire:click="togglePermissionInRole('{{ $moduleName }}', '{{ $permissionName }}')">
                                                            <label class="form-check-label small" for="perm_{{ md5($permissionName) }}">
                                                                {{ $permData['label'] ?? $permissionName }}
                                                                <br>
                                                                <small class="text-muted">{{ $permData['desc'] ?? $permissionName }}</small>
                                                            </label>
                                                        </div>
                                                    </div>
                                                @endforeach
                                            </div>
                                        </div>
                                    @endforeach
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" wire:click="closeRoleModal">
                            Cancelar
                        </button>
                        <button type="submit" class="btn btn-success" 
                                @disabled($editingRole && $roleForm['is_super_admin'] ?? false)>
                            <i class="fa-solid fa-floppy-disk me-1"></i>Guardar
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    @endif

    <!-- Modal de asignación de roles a usuario -->
    @if($showUserRolesModal)
    <div class="modal fade show d-block" tabindex="-1" style="background-color: rgba(0,0,0,0.5);">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fa-solid fa-user-tag me-1"></i>Asignar plantillas a {{ $selectedUserSummary['name'] ?? 'usuario' }}
                    </h5>
                    <button type="button" class="btn-close" wire:click="closeUserRolesModal"></button>
                </div>
                <div class="modal-body">
                    @if($selectedUserIsSuperAdmin)
                        <div class="alert alert-warning">
                            <i class="fa-solid fa-triangle-exclamation me-1"></i>Este usuario es <strong>Super Admin</strong>. Tiene acceso total al sistema y no se puede editar desde aquí.
                        </div>
                    @else
                        @if(session('user-notice'))
                            <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
                                <i class="fa-solid fa-circle-check me-1"></i>{{ session('user-notice') }}
                                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
                            </div>
                        @endif

                        <div class="mb-3">
                            <p class="mb-0 small text-muted">
                                Un usuario puede combinar varias plantillas (ej. Cajero + Encargado de Tienda).
                            </p>
                        </div>

                        <div class="row">
                            @foreach($roleList as $role)
                                <div class="col-md-6 col-lg-4">
                                    <div class="card mb-2 border-{{ in_array($role['id'], array_column($selectedUserSummary['roles'] ?? [], 'id')) ? 'primary' : 'light' }}">
                                        <div class="card-body p-3">
                                            <div class="form-check mb-0">
                                                <input class="form-check-input"
                                                       type="checkbox"
                                                       value="{{ $role['id'] }}"
                                                       id="role-checkbox-{{ $role['id'] }}"
                                                       wire:model.defer="editRoles"
                                                       @disabled($role['is_super_admin'])
                                                >
                                                <label class="form-check-label" for="role-checkbox-{{ $role['id'] }}">
                                                    <strong>{{ $role['display_name'] }}</strong>
                                                    <small class="d-block text-muted">{{ $role['description'] ?? 'Sin descripción' }}</small>
                                                    <small class="text-muted">
                                                        {{ $role['permissions_count'] }} permisos • 
                                                        {{ $role['users_count'] }} usuarios
                                                    </small>
                                                    @if($role['is_super_admin'])
                                                        <span class="badge bg-danger ms-1">Sistema</span>
                                                    @endif
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            @endforeach
                        </div>
                    @endif
                </div>
                @if(!$selectedUserIsSuperAdmin)
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary" wire:click="closeUserRolesModal">
                        Cancelar
                    </button>
                    <button class="btn btn-primary" wire:click="saveUserRoles">
                        <i class="fa-solid fa-floppy-disk me-1"></i>Guardar plantillas
                    </button>
                </div>
                @endif
            </div>
        </div>
    </div>
    @endif

    <!-- Modal de permisos especiales de usuario -->
    @if($showUserPermissionsModal)
    <div class="modal fade show d-block" tabindex="-1" style="background-color: rgba(0,0,0,0.5);">
        <div class="modal-dialog modal-xl">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fa-solid fa-key me-1"></i>Permisos especiales para {{ $selectedUserSummary['name'] ?? 'usuario' }}
                    </h5>
                    <button type="button" class="btn-close" wire:click="closeUserPermissionsModal"></button>
                </div>
                <div class="modal-body">
                    @if($selectedUserIsSuperAdmin)
                        <div class="alert alert-warning">
                            <i class="fa-solid fa-triangle-exclamation me-1"></i>Este usuario es <strong>Super Admin</strong>. Tiene acceso total al sistema y no se puede editar desde aquí.
                        </div>
                    @else
                        @if(session('user-notice'))
                            <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
                                <i class="fa-solid fa-circle-check me-1"></i>{{ session('user-notice') }}
                                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
                            </div>
                        @endif

                        <div class="mb-3">
                            <p class="small text-muted mb-0">Estos permisos individuales se usan para excepciones sin modificar las plantillas base.</p>
                        </div>

                        <!-- Pestañas para módulos de permisos -->
                        <ul class="nav nav-tabs mb-3" id="permissionsTab" role="tablist">
                            @foreach($permissionsMap as $module => $modulePerms)
                                <li class="nav-item" role="presentation">
                                    <button class="nav-link {{ $loop->first ? 'active' : '' }}" 
                                            id="{{ \Illuminate\Support\Str::slug($module) }}-tab" 
                                            data-bs-toggle="tab" 
                                            data-bs-target="#{{ \Illuminate\Support\Str::slug($module) }}" 
                                            type="button" 
                                            role="tab">
                                        {{ $module }} 
                                        <span class="badge bg-secondary ms-1">{{ count($modulePerms) }}</span>
                                    </button>
                                </li>
                            @endforeach
                        </ul>

                        <div class="tab-content" id="permissionsTabContent">
                            @foreach($permissionsMap as $module => $modulePerms)
                                <div class="tab-pane fade {{ $loop->first ? 'show active' : '' }}" 
                                     id="{{ \Illuminate\Support\Str::slug($module) }}" 
                                     role="tabpanel">
                                    <div class="row">
                                        @forelse($modulePerms as $permMeta)
                                            @php
                                                $permName = $permMeta['perm'];
                                                $label = $permMeta['label'];
                                                $desc = $permMeta['desc'];
                                                $inherited = in_array($permName, $inheritedPermissions, true);
                                                $checked = $editMatrix[$permName] ?? in_array($permName, $effectivePermissions, true);
                                            @endphp
                                            <div class="col-md-6">
                                                <div class="form-check mb-2">
                                                    <input class="form-check-input"
                                                           type="checkbox"
                                                           id="perm-{{ md5($permName) }}"
                                                           @checked($checked)
                                                           @disabled($inherited)
                                                           wire:click="togglePermission('{{ $permName }}')"
                                                    >
                                                    <label class="form-check-label" for="perm-{{ md5($permName) }}">
                                                        <span class="fw-semibold">{{ $label }}</span>
                                                        <span class="d-block small text-muted">{{ $desc }}</span>
                                                    </label>
                                                    @if($inherited)
                                                        <span class="badge bg-secondary ms-2">vía plantilla</span>
                                                    @endif
                                                </div>
                                            </div>
                                        @empty
                                            <div class="col-12">
                                                <p class="text-muted small mb-0">Sin permisos configurados en este módulo.</p>
                                            </div>
                                        @endforelse
                                    </div>
                                </div>
                            @endforeach
                        </div>
                    @endif
                </div>
                @if(!$selectedUserIsSuperAdmin)
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary" wire:click="closeUserPermissionsModal">
                        Cancelar
                    </button>
                    <button class="btn btn-primary" wire:click="saveUserOverrides">
                        <i class="fa-solid fa-floppy-disk me-1"></i>Guardar permisos
                    </button>
                </div>
                @endif
            </div>
        </div>
    </div>
    @endif
</div>