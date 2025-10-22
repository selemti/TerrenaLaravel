<div>
    @section('page-title')
        <i class="fa-solid fa-user-group"></i> <span class="label">Personal</span>
    @endsection

    <div class="mb-3">
        <h2 class="h4 fw-semibold mb-1">Gestión de personal</h2>
        <p class="text-muted small mb-0">Administra usuarios, roles y permisos del sistema Terrena.</p>
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
                    <i class="fa-solid fa-user-shield me-1"></i>Roles
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
        <div class="tab-pane fade @if($activeTab === 'users') show active @endif" id="tab-users">
            <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-2 mb-3">
                <div class="input-group input-group-sm" style="max-width: 320px;">
                    <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
                    <input type="search" class="form-control" placeholder="Buscar por nombre, usuario o correo"
                           wire:model.debounce.500ms="userSearch">
                </div>
                @can('people.users.manage')
                    <div class="d-flex gap-2">
                        <button class="btn btn-sm btn-outline-secondary" wire:click="closeUserForm" @disabled(!$showUserForm)>
                            <i class="fa-solid fa-xmark me-1"></i>Cerrar
                        </button>
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
                                <td>{{ $user->nombre_completo ?? $user->name }}</td>
                                <td>{{ $user->email ?? '—' }}</td>
                                <td>
                                    @if ($user->getRoleNames()->count())
                                        @foreach ($user->getRoleNames() as $roleName)
                                            <span class="badge bg-light text-dark">{{ $roleName }}</span>
                                        @endforeach
                                    @else
                                        <span class="text-muted">Sin rol</span>
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
                                        @else
                                            <span class="text-muted small">Sin permisos</span>
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

            @if ($showUserForm)
                <div class="card shadow-sm mt-4">
                    <div class="card-body">
                        <h5 class="card-title mb-3">
                            @if ($editingUser)
                                <i class="fa-solid fa-user-pen me-1"></i>Editar usuario
                            @else
                                <i class="fa-solid fa-user-plus me-1"></i>Registrar usuario
                            @endif
                        </h5>

                        <form wire:submit.prevent="saveUser" class="row g-3">
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

                            <div class="col-12 d-flex justify-content-end gap-2 mt-3">
                                <button type="button" class="btn btn-outline-secondary" wire:click="closeUserForm">
                                    Cancelar
                                </button>
                                <button type="submit" class="btn btn-success">
                                    <i class="fa-solid fa-floppy-disk me-1"></i>Guardar
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            @endif
        </div>

        <div class="tab-pane fade @if($activeTab === 'roles') show active @endif" id="tab-roles">
            <div class="card shadow-sm">
                <div class="card-body">
                    @include('partials.under-construction')
                </div>
            </div>
        </div>

        <div class="tab-pane fade @if($activeTab === 'permissions') show active @endif" id="tab-permissions">
            <div class="row">
                <div class="col-lg-7">
                    <div class="card shadow-sm mb-3">
                        <div class="card-body">
                            <h5 class="card-title mb-3">Listado de permisos disponibles</h5>
                            <div class="d-flex flex-wrap gap-2">
                                @foreach ($permissions as $permission)
                                    <span class="badge bg-light text-dark">{{ $permission->name }}</span>
                                @endforeach
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-5">
                    @include('partials.under-construction')
                </div>
            </div>
        </div>
    </div>
</div>
