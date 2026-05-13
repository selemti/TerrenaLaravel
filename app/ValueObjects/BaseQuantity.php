<?php

namespace App\ValueObjects;

use InvalidArgumentException;

/**
 * Cantidad ya convertida a UOM base (KG, L, PZ).
 * Previene confundir qty en UOM compra con qty en UOM base en mov_inv.
 */
final readonly class BaseQuantity
{
    public function __construct(
        public readonly float $value,
        public readonly string $uomClave, // 'KG', 'L', 'PZ'
    ) {}

    public static function zero(string $uomClave): self
    {
        return new self(0.0, $uomClave);
    }

    public function add(self $other): self
    {
        $this->assertSameUom($other);

        return new self($this->value + $other->value, $this->uomClave);
    }

    public function subtract(self $other): self
    {
        $this->assertSameUom($other);

        return new self($this->value - $other->value, $this->uomClave);
    }

    public function isZero(): bool
    {
        return abs($this->value) < 0.000001;
    }

    public function isNegative(): bool
    {
        return $this->value < -0.000001;
    }

    public function toVariance(self $theoretical): Variance
    {
        $this->assertSameUom($theoretical);

        return new Variance($this->value - $theoretical->value, $this->uomClave);
    }

    private function assertSameUom(self $other): void
    {
        if ($this->uomClave !== $other->uomClave) {
            throw new InvalidArgumentException(
                "Cannot operate BaseQuantity with different UOMs: {$this->uomClave} vs {$other->uomClave}"
            );
        }
    }
}
