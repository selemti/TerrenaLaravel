<?php

namespace App\ValueObjects;

use InvalidArgumentException;

/**
 * Value Object para cantidades monetarias.
 * Previene valores negativos inesperados y centraliza el redondeo.
 */
final readonly class Money
{
    public float $amount;

    public string $currency;

    public function __construct(float $amount, string $currency = 'MXN')
    {
        $this->amount = round($amount, 2);
        $this->currency = strtoupper($currency);
    }

    public static function of(float $amount, string $currency = 'MXN'): self
    {
        return new self($amount, $currency);
    }

    public static function zero(string $currency = 'MXN'): self
    {
        return new self(0.0, $currency);
    }

    public function add(self $other): self
    {
        $this->assertSameCurrency($other);

        return new self($this->amount + $other->amount, $this->currency);
    }

    public function subtract(self $other): self
    {
        $this->assertSameCurrency($other);

        return new self($this->amount - $other->amount, $this->currency);
    }

    public function multiply(float $factor): self
    {
        return new self($this->amount * $factor, $this->currency);
    }

    public function isPositive(): bool
    {
        return $this->amount > 0;
    }

    public function isZero(): bool
    {
        return abs($this->amount) < 0.001;
    }

    public function isNegative(): bool
    {
        return $this->amount < 0;
    }

    public function equals(self $other): bool
    {
        return $this->currency === $other->currency
            && abs($this->amount - $other->amount) < 0.001;
    }

    public function toFloat(): float
    {
        return $this->amount;
    }

    public function __toString(): string
    {
        return number_format($this->amount, 2).' '.$this->currency;
    }

    private function assertSameCurrency(self $other): void
    {
        if ($this->currency !== $other->currency) {
            throw new InvalidArgumentException(
                "Cannot operate on different currencies: {$this->currency} and {$other->currency}"
            );
        }
    }
}
