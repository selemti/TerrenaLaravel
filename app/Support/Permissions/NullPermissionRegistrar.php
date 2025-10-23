<?php

namespace App\Support\Permissions;

use Illuminate\Cache\CacheManager;
use Illuminate\Contracts\Auth\Access\Gate;
use Illuminate\Database\Eloquent\Collection;
use Spatie\Permission\PermissionRegistrar;

class NullPermissionRegistrar extends PermissionRegistrar
{
    public function __construct(CacheManager $cacheManager)
    {
        parent::__construct($cacheManager);
    }

    public function registerPermissions(Gate $gate): bool
    {
        return true;
    }

    public function getPermissions(array $params = [], bool $onlyOne = false): Collection
    {
        return Collection::make();
    }
}
