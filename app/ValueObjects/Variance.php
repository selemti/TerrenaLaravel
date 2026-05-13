<?php

namespace App\ValueObjects;

/**
 * Varianza de conteo físico vs teórico.
 * value = qty_contada - qty_teorica (puede ser negativo = déficit).
 */
final readonly class Variance
{
    public function __construct(
        public readonly float $value,
        public readonly string $uomClave,
    ) {}

    public static function fromCounted(BaseQuantity $counted, BaseQuantity $theoretical): self
    {
        return $counted->toVariance($theoretical);
    }

    public function isDeficit(): bool
    {
        return $this->value < -0.000001;
    }

    public function isSurplus(): bool
    {
        return $this->value > 0.000001;
    }

    public function isZero(): bool
    {
        return abs($this->value) < 0.000001;
    }

    public function absoluteValue(): float
    {
        return abs($this->value);
    }

    public function asBaseQuantity(): BaseQuantity
    {
        return new BaseQuantity($this->value, $this->uomClave);
    }
}
