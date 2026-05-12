<?php

namespace App\Exceptions\Recetas;

use App\Exceptions\Domain\DomainException;

class RecetaVersionException extends DomainException
{
    public function errorCode(): string
    {
        return 'receta_version_error';
    }
}
