<?php

namespace App\Livewire\People;

use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Livewire\Attributes\Layout;
use Livewire\Component;
use Livewire\WithPagination;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

#[Layout('layouts.terrena', ['active' => 'personal'])]
class UsersIndex extends Component
{
    use AuthorizesRequests;
    use WithPagination;

    public string $activeTab = 'users';
    public string $userSearch = '';

    // Estados para formularios modales
    public bool $showUserModal = false;
    public bool $editingUser = false;
    public ?int $editingUserId = null;

    public array $userForm = [];

    public bool $showRoleModal = false;
    public bool $editingRole = false;
    public ?int $editingRoleId = null;
    public array $roleForm = [];

    public bool $showUserRolesModal = false;
    public bool $showUserPermissionsModal = false;

    // Gestión de permisos individuales
    public array $usersListData = [];
    public ?int $selectedUserId = null;
    public bool $selectedUserIsSuperAdmin = false;
    public array $roleList = [];
    public array $selectedUserRoles = [];
    public array $editRoles = [];
    public array $allPermissions = [];
    public array $inheritedPermissions = [];
    public array $directPermissions = [];
    public array $effectivePermissions = [];
    public array $editMatrix = [];
    public array $selectedUserSummary = [];
    public string $statusMessage = '';

    // Gestión de Plantillas (Roles) - Esta parte ya está cubierta con las variables anteriores
    public bool $showRoleForm = false;
    public array $permissionsByModule = [];

    protected $paginationTheme = 'bootstrap';

    protected array $rules = [
        'userForm.nombre_completo' => ['required', 'string', 'max:255'],
        'userForm.email' => ['required', 'email', 'max:255'],
        'userForm.username' => ['nullable', 'string', 'max:60'],
        'userForm.password' => ['nullable', 'string', 'min:8', 'confirmed'],
        'userForm.activo' => ['boolean'],
    ];

    public function mount(): void
    {
        $this->userForm = $this->defaultUserForm();
        $this->roleForm = $this->defaultRoleForm();
        $this->loadUsersList();
        $this->loadRoleList();
        $this->loadPermissionsByModule();
    }

    protected function loadUsersList(): void
    {
        $this->usersListData = User::query()
            ->select('id', 'username', 'nombre_completo', 'email')
            ->with(['roles:id,name'])
            ->orderByRaw("LOWER(COALESCE(nombre_completo, ''))")
            ->get()
            ->map(fn ($user) => [
                'id' => $user->id,
                'username' => $user->username ?? '-',
                'name' => $user->nombre_completo ?? '-',
                'email' => $user->email,
                'roles' => $user->roles->pluck('name')->toArray(),
            ])
            ->toArray();
    }

    protected function loadRoleList(): void
    {
        $this->roleList = Role::query()
            ->withCount(['permissions', 'users'])
            ->orderBy('name')
            ->get()
            ->map(function (Role $role) {
                return [
                    'id' => $role->id,
                    'name' => $role->name,
                    'display_name' => $role->display_name ?? $role->name,
                    'description' => $role->description,
                    'permissions_count' => $role->permissions_count ?? $role->permissions()->count(),
                    'users_count' => $role->users_count ?? $role->users()->count(),
                    'is_super_admin' => $role->name === 'Super Admin',
                ];
            })
            ->toArray();
    }

    public function selectUser(int $userId): void
    {
        $this->authorize('people.users.manage');

        $user = User::query()
            ->with(['roles.permissions', 'permissions'])
            ->findOrFail($userId);

        $this->refreshSelectedUserState($user);
        $this->statusMessage = '';
    }

    public function openUserRolesModal(int $userId): void
    {
        $this->authorize('people.users.manage');

        $this->selectUser($userId);
        $this->loadRoleList(); // Asegura que roleList esté actualizada
        $this->showUserRolesModal = true;
    }

    public function closeUserRolesModal(): void
    {
        $this->showUserRolesModal = false;
        $this->selectedUserId = null;
    }

    public function openUserPermissionsModal(int $userId): void
    {
        $this->authorize('people.permissions.manage');

        $this->selectUser($userId);
        $this->showUserPermissionsModal = true;
    }

    public function closeUserPermissionsModal(): void
    {
        $this->showUserPermissionsModal = false;
        $this->selectedUserId = null;
    }

    public function togglePermission(string $permission): void
    {
        if (! $this->selectedUserId) {
            return;
        }

        if ($this->selectedUserIsSuperAdmin) {
            // Super Admin se gestiona fuera de esta UI.
            return;
        }

        if (in_array($permission, $this->inheritedPermissions, true)) {
            return;
        }

        $current = $this->editMatrix[$permission] ?? false;
        $this->editMatrix[$permission] = ! $current;
    }

    public function saveUserRoles(): void
    {
        $this->authorize('people.roles.manage');

        if (! $this->selectedUserId) {
            return;
        }

        $user = User::query()
            ->with(['roles.permissions', 'permissions'])
            ->findOrFail($this->selectedUserId);

        if ($user->hasRole('Super Admin')) {
            // No permitir editar plantillas del Super Admin desde UI.
            $this->statusMessage = 'Super Admin no es editable desde esta pantalla.';
            return;
        }

        $roleIds = collect($this->editRoles)
            ->map(fn ($id) => (int) $id)
            ->filter()
            ->unique()
            ->values()
            ->all();

        $user->syncRoles($roleIds);

        // TODO: invalidar cache de permisos del usuario editado si es el usuario autenticado actualmente (sessionStorage.removeItem('terrena_permissions'))
        $this->statusMessage = 'Plantillas actualizadas.';

        $user->load('roles.permissions', 'permissions');
        $this->refreshSelectedUserState($user);
        $this->loadUsersList();
        $this->loadRoleList();
    }

    public function saveUserOverrides(): void
    {
        $this->authorize('people.permissions.manage');

        if (! $this->selectedUserId) {
            return;
        }

        $user = User::query()
            ->with(['roles.permissions', 'permissions'])
            ->findOrFail($this->selectedUserId);

        if ($user->hasRole('Super Admin')) {
            // No permitir ajustes directos al Super Admin.
            $this->statusMessage = 'Super Admin no es editable desde esta pantalla.';
            return;
        }

        $desired = array_keys(array_filter($this->editMatrix));
        $directOnly = array_values(array_diff($desired, $this->inheritedPermissions));

        $user->syncPermissions($directOnly);

        // TODO: invalidar cache de permisos del usuario editado si es el usuario autenticado actualmente (sessionStorage.removeItem('terrena_permissions'))
        $this->statusMessage = 'Permisos especiales actualizados.';

        $user->load('roles.permissions', 'permissions');
        $this->refreshSelectedUserState($user);
    }

    public function updatingUserSearch(): void
    {
        $this->resetPage();
    }

    public function updatingActiveTab(string $value): void
    {
        $this->activeTab = $value;
        $this->resetValidation();
        $this->resetErrorBag();
        $this->resetPage();
    }

    public function openCreateForm(): void
    {
        $this->authorize('people.users.manage');

        $this->resetValidation();
        $this->resetErrorBag();
        $this->userForm = $this->defaultUserForm();
        $this->editingUser = false;
        $this->editingUserId = null;
        $this->showUserModal = true;
    }

    public function openEditForm(int $userId): void
    {
        $this->authorize('people.users.manage');

        $user = User::query()->findOrFail($userId);

        $this->userForm = [
            'username' => $user->username,
            'nombre_completo' => $user->nombre_completo,
            'email' => $user->email,
            'password' => '',
            'password_confirmation' => '',
            'activo' => (bool) $user->activo,
        ];

        $this->editingUser = true;
        $this->editingUserId = $user->getKey();
        $this->showUserModal = true;
    }

    public function closeUserModal(): void
    {
        $this->showUserModal = false;
        $this->editingUser = false;
        $this->editingUserId = null;
        $this->userForm = $this->defaultUserForm();
        $this->resetValidation();
        $this->resetErrorBag();
    }

    public function saveUser(): void
    {
        $this->authorize('people.users.manage');

        $this->validate($this->rulesWithUniqueness());

        $payload = $this->userForm;
        $payload['nombre_completo'] = trim((string) $payload['nombre_completo']);
        $payload['email'] = strtolower(trim((string) $payload['email']));
        $payload['username'] = $payload['username'] !== null
            ? Str::lower(Str::of($payload['username'])->trim()->value())
            : null;

        if ($this->editingUser && $this->editingUserId) {
            $user = User::query()->findOrFail($this->editingUserId);
            $user->nombre_completo = $payload['nombre_completo'];
            $user->email = $payload['email'];
            $user->username = $payload['username'] ?: null;
            $user->activo = (bool) $payload['activo'];

            if ($payload['password']) {
                $user->password_hash = Hash::make($payload['password']);
            }

            $user->save();

            session()->flash('user-notice', 'Usuario actualizado correctamente.');
            $this->loadUsersList();
        } else {
            $data = [
                'nombre_completo' => $payload['nombre_completo'],
                'email' => $payload['email'],
                'username' => $payload['username'] ?: null,
                'password_hash' => Hash::make($payload['password']),
                'activo' => (bool) $payload['activo'],
                'intentos_login' => 0,
            ];

            User::query()->create($data);

            session()->flash('user-notice', 'Usuario creado correctamente.');
            $this->loadUsersList();
        }

        $this->closeUserModal();
        session()->flash('user-notice', $this->editingUser ? 'Usuario actualizado correctamente.' : 'Usuario creado correctamente.');
        // TODO auditoría:
        // AuditLogService->logAction(
        //     auth()->id(),
        //     'USER_PERMISSIONS_UPDATE',
        //     'user',
        //     $this->editingUser ? $this->editingUser->id : $newUserId,
        //     'Actualización de usuario desde panel de administración',
        //     null,
        //     [/* diff de roles/permisos aplicados */]
        // );
    }

    public function toggleActive(int $userId): void
    {
        $this->authorize('people.users.manage');

        $user = User::query()->findOrFail($userId);
        $user->activo = ! $user->activo;
        $user->save();

        session()->flash('user-notice', 'Estatus actualizado.');
        $this->loadUsersList();
    }

    public function openRoleEditor(int $roleId): void
    {
        $this->authorize('people.roles.manage');

        $role = Role::findById($roleId, 'web');

        $this->roleEditorRoleId = $role->id;
        $this->roleEditorUsers = $role->users()->pluck('id')->map(fn ($id) => (string) $id)->toArray();
        $this->showRoleEditor = true;
    }

    public function closeRoleEditor(): void
    {
        $this->showRoleEditor = false;
        $this->roleEditorRoleId = null;
        $this->roleEditorUsers = [];
    }

    public function saveRoleEditor(): void
    {
        $this->authorize('people.roles.manage');

        if (! $this->roleEditorRoleId) {
            return;
        }

        $role = Role::findById($this->roleEditorRoleId, 'web');
        $userIds = collect($this->roleEditorUsers)
            ->filter()
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values();

        $role->users()->sync($userIds->all());

        $this->closeRoleEditor();
        session()->flash('role-notice', 'Miembros del rol actualizados.');
    }

    public function render()
    {
        return view('livewire.people.users-index', [
            'users' => $this->userRecords,
            'roles' => $this->roles, // Propiedad computada que devuelve lista de roles
            'roleList' => $this->roleList, // Lista usada para modales
            'permissionsMap' => $this->permissionsByModule,
            'permissions' => $this->permissions,
            'allUsers' => $this->allUsersForRoles,
            'userList' => $this->usersListData,
        ]);
    }

    public function getUserRecordsProperty()
    {
        $query = User::query()
            ->with('roles')
            ->orderBy('nombre_completo');

        if ($this->userSearch !== '') {
            $search = Str::lower($this->userSearch);
            $query->where(function ($builder) use ($search) {
                $builder
                    ->whereRaw('LOWER(nombre_completo) LIKE ?', ['%'.$search.'%'])
                    ->orWhereRaw('LOWER(username) LIKE ?', ['%'.$search.'%'])
                    ->orWhereRaw('LOWER(email) LIKE ?', ['%'.$search.'%']);
            });
        }

        return $query->paginate(10);
    }

    public function getRolesProperty(): \Illuminate\Support\Collection
    {
        return Role::query()
            ->withCount('users')
            ->orderBy('name')
            ->get()
            ->map(function ($role) {
                return [
                    'id' => $role->id,
                    'name' => $role->name,
                    'display_name' => $role->display_name ?? $role->name,
                    'description' => $role->description,
                    'users_count' => $role->users_count,
                    'permissions_count' => $role->permissions->count(),
                    'is_super_admin' => $role->name === 'Super Admin',
                ];
            });
    }

    public function getPermissionsProperty(): Collection
    {
        return Permission::query()->orderBy('name')->get();
    }

    public function getAllUsersForRolesProperty(): Collection
    {
        return User::query()->orderBy('nombre_completo')->get(['id', 'nombre_completo', 'email']);
    }

    public function getPermissionsMapProperty(): array
    {
        return config('permissions_map', []);
    }

    protected function rulesWithUniqueness(): array
    {
        $rules = $this->rules;

        $uniqueUsername = Rule::unique('users', 'username');
        $uniqueEmail = Rule::unique('users', 'email');

        if ($this->editingUser && $this->editingUserId) {
            $uniqueUsername = $uniqueUsername->ignore($this->editingUserId, 'id');
            $uniqueEmail = $uniqueEmail->ignore($this->editingUserId, 'id');
            $rules['userForm.password'][0] = 'nullable';
        } else {
            $rules['userForm.password'][0] = 'required';
        }

        $rules['userForm.username'][] = $uniqueUsername;
        $rules['userForm.email'][] = $uniqueEmail;

        return $rules;
    }

    protected function defaultUserForm(): array
    {
        return [
            'username' => '',
            'nombre_completo' => '',
            'email' => '',
            'password' => '',
            'password_confirmation' => '',
            'activo' => true,
        ];
    }

    protected function defaultRoleForm(): array
    {
        return [
            'name' => '',
            'display_name' => '',
            'description' => '',
            'permissions' => [],
            'is_super_admin' => false,
        ];
    }

    protected function loadPermissionsByModule(): void
    {
        $this->permissionsByModule = config('permissions_map', []);
    }

    protected function refreshSelectedUserState(User $user): void
    {
        $user->loadMissing('roles.permissions', 'permissions');

        $this->selectedUserId = $user->id;
        $this->selectedUserRoles = $user->roles->pluck('id')->map(fn ($id) => (int) $id)->toArray();
        $this->editRoles = $this->selectedUserRoles;

        $this->selectedUserSummary = [
            'name' => $user->nombre_completo ?? '—',
            'username' => $user->username ?? '—',
            'email' => $user->email ?? '—',
            'roles' => $user->roles->map(function (Role $role) {
                return [
                    'id' => $role->id,
                    'name' => $role->name,
                    'display_name' => $role->display_name ?? $role->name,
                    'is_super_admin' => $role->name === 'Super Admin',
                ];
            })->toArray(),
        ];

        $this->rebuildPermissionState($user);
    }

    protected function rebuildPermissionState(User $user): void
    {
        $this->selectedUserIsSuperAdmin = $user->hasRole('Super Admin');
        $this->directPermissions = $user->permissions->pluck('name')->unique()->values()->toArray();

        $rolePermissions = $user->roles
            ->loadMissing('permissions')
            ->flatMap(fn ($role) => $role->permissions->pluck('name'))
            ->unique()
            ->values()
            ->toArray();

        $this->inheritedPermissions = $rolePermissions;

        $effective = array_values(array_unique(array_merge($this->directPermissions, $this->inheritedPermissions)));

        if ($this->selectedUserIsSuperAdmin) {
            $effective = Permission::orderBy('name')->pluck('name')->toArray();
        }

        $this->effectivePermissions = $effective;

        $this->allPermissions = Permission::orderBy('name')->pluck('name')->toArray();
        $this->editMatrix = array_fill_keys($this->allPermissions, false);

        foreach ($this->effectivePermissions as $perm) {
            $this->editMatrix[$perm] = true;
        }
    }

    public function loadRoleForEdit(int $roleId): void
    {
        $this->authorize('people.roles.manage');

        $role = Role::findById($roleId, 'web');

        $this->roleForm = [
            'name' => $role->name,
            'display_name' => $role->display_name ?? '',
            'description' => $role->description ?? '',
            'permissions' => $role->permissions->pluck('name')->toArray(),
            'is_super_admin' => $role->name === 'Super Admin',
        ];

        $this->editingRole = true;
        $this->editingRoleId = $role->id;
        $this->showRoleModal = true;
    }

    public function openCreateRoleForm(): void
    {
        $this->authorize('people.roles.manage');

        $this->roleForm = $this->defaultRoleForm();
        $this->editingRole = false;
        $this->editingRoleId = null;
        $this->showRoleModal = true;
    }

    public function closeRoleModal(): void
    {
        $this->showRoleModal = false;
        $this->editingRole = false;
        $this->editingRoleId = null;
        $this->roleForm = $this->defaultRoleForm();
    }

    public function saveRole(): void
    {
        $this->authorize('people.roles.manage');

        if (($this->roleForm['is_super_admin'] ?? false) === true) {
            session()->flash('role-notice', 'La plantilla Super Admin no se puede editar.');
            return;
        }

        $this->validate([
            'roleForm.name' => 'required|string|max:255|unique:roles,name,' . ($this->editingRole ? $this->editingRoleId : ''),
            'roleForm.display_name' => 'nullable|string|max:255',
            'roleForm.description' => 'nullable|string|max:1000',
        ]);

        $wasEditing = $this->editingRole && $this->editingRoleId;

        if ($wasEditing) {
            $role = Role::findById($this->editingRoleId, 'web');
            $role->name = $this->roleForm['name'];
            $role->display_name = $this->roleForm['display_name'];
            $role->description = $this->roleForm['description'];
            $role->save();

            // Sync permissions
            $role->syncPermissions($this->roleForm['permissions']);
        } else {
            $role = Role::create([
                'name' => $this->roleForm['name'],
                'display_name' => $this->roleForm['display_name'],
                'description' => $this->roleForm['description'],
            ]);

            $role->syncPermissions($this->roleForm['permissions']);
        }

        $this->closeRoleModal();
        $this->loadRoleList();
        session()->flash('role-notice', $wasEditing ? 'Plantilla actualizada correctamente.' : 'Plantilla creada correctamente.');
    }

    public function deleteRole(int $roleId): void
    {
        $this->authorize('people.roles.manage');

        $role = Role::findById($roleId, 'web');

        if ($role->name === 'Super Admin') {
            session()->flash('role-notice', 'No se puede eliminar el rol Super Admin.');
            return;
        }

        // Check if role is assigned to users
        if ($role->users()->count() > 0) {
            session()->flash('role-notice', 'No se puede eliminar la plantilla porque está asignada a usuarios.');
            return;
        }

        $role->delete();
        $this->loadRoleList();
        session()->flash('role-notice', 'Plantilla eliminada correctamente.');
    }

    public function duplicateRole(int $roleId): void
    {
        $this->authorize('people.roles.manage');

        $role = Role::findById($roleId, 'web');

        if ($role->name === 'Super Admin') {
            session()->flash('role-notice', 'La plantilla Super Admin no se puede duplicar.');
            return;
        }

        // Generar nuevo nombre para evitar duplicados
        $counter = 1;
        $newName = $role->name . '_copy';
        $newDisplayName = ($role->display_name ?? $role->name) . ' (copia)';
        
        while (Role::where('name', $newName)->exists()) {
            $counter++;
            $newName = $role->name . '_copy_' . $counter;
            $newDisplayName = ($role->display_name ?? $role->name) . ' (copia ' . $counter . ')';
        }

        // Crear nuevo rol con los mismos permisos
        $newRole = Role::create([
            'name' => $newName,
            'display_name' => $newDisplayName,
            'description' => $role->description ? $role->description . ' (copia)' : null,
        ]);

        // Copiar permisos
        $newRole->syncPermissions($role->permissions);

        session()->flash('role-notice', 'Plantilla duplicada correctamente: ' . $newDisplayName);
        $this->loadRoleList(); // Actualizar lista
    }

    public function togglePermissionInRole(string $module, string $permissionName): void
    {
        if (($this->roleForm['is_super_admin'] ?? false) === true) {
            return;
        }

        $index = array_search($permissionName, $this->roleForm['permissions']);
        
        if ($index !== false) {
            // Remove permission
            unset($this->roleForm['permissions'][$index]);
            $this->roleForm['permissions'] = array_values($this->roleForm['permissions']);
        } else {
            // Add permission
            $this->roleForm['permissions'][] = $permissionName;
        }
    }

}
