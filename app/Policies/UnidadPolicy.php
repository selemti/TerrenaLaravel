<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Catalogs\Unidad;

class UnidadPolicy
{
    public function viewAny(?User $user): bool { return (bool)$user; }
    public function view(?User $user, Unidad $model): bool { return (bool)$user; }
    public function create(User $user): bool { return true; }
    public function update(User $user, Unidad $model): bool { return true; }
    public function delete(User $user, Unidad $model): bool { return true; }
}
