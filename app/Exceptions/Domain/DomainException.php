<?php

namespace App\Exceptions\Domain;

abstract class DomainException extends \RuntimeException
{
    protected array $context = [];

    public function getContext(): array
    {
        return $this->context;
    }

    public function withContext(array $context): static
    {
        $this->context = array_merge($this->context, $context);
        return $this;
    }

    public function errorCode(): string
    {
        return 'domain_error';
    }
}
