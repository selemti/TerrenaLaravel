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

    public bool $showUserForm = false;
    public bool $editingUser = false;
    public ?int $editingUserId = null;

    public array $userForm = [];

    public bool $showRoleEditor = false;
    public ?int $roleEditorRoleId = null;
    public array $roleEditorUsers = [];

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
        $this->showUserForm = true;
    }

    public function openEditForm(int $userId): void
    {
        $this->authorize('people.users.manage');

        $user = User::query()->findOrFail($userId);

        $this->userForm = [
            'username' => $user->username,
            'nombre_completo' => $user->nombre_completo ?? $user->name,
            'email' => $user->email,
            'password' => '',
            'password_confirmation' => '',
            'activo' => (bool) $user->activo,
        ];

        $this->editingUser = true;
        $this->editingUserId = $user->getKey();
        $this->showUserForm = true;
    }

    public function closeUserForm(): void
    {
        $this->showUserForm = false;
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
        }

        $this->closeUserForm();
    }

    public function toggleActive(int $userId): void
    {
        $this->authorize('people.users.manage');

        $user = User::query()->findOrFail($userId);
        $user->activo = ! $user->activo;
        $user->save();

        session()->flash('user-notice', 'Estatus actualizado.');
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
            'users' => $this->users,
            'roles' => $this->roles,
            'permissions' => $this->permissions,
            'allUsers' => $this->allUsersForRoles,
        ]);
    }

    public function getUsersProperty()
    {
        $query = User::query()->orderBy('nombre_completo');

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

    public function getRolesProperty(): Collection
    {
        return Role::query()->withCount('users')->orderBy('name')->get();
    }

    public function getPermissionsProperty(): Collection
    {
        return Permission::query()->orderBy('name')->get();
    }

    public function getAllUsersForRolesProperty(): Collection
    {
        return User::query()->orderBy('nombre_completo')->get(['id', 'nombre_completo', 'email']);
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
}
