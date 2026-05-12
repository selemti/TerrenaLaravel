<?php

namespace App\Exceptions\Recetas;

use App\Exceptions\Domain\DomainException;

class RecetaNotFoundException extends DomainException
{
    public function errorCode(): string
    {
        return 'receta_not_found';
    }
}
