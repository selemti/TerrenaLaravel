<?php

namespace App\ValueObjects;

use Carbon\Carbon;
use InvalidArgumentException;

final readonly class DateRange
{
    public Carbon $from;

    public Carbon $to;

    public function __construct(Carbon $from, Carbon $to)
    {
        if ($from->greaterThan($to)) {
            throw new InvalidArgumentException(
                "DateRange: 'from' ({$from->toDateString()}) must not be after 'to' ({$to->toDateString()})."
            );
        }

        $this->from = $from->startOfDay();
        $this->to = $to->endOfDay();
    }

    public static function fromStrings(string $from, string $to, string $format = 'Y-m-d'): self
    {
        $parsedFrom = Carbon::createFromFormat($format, $from);
        $parsedTo = Carbon::createFromFormat($format, $to);

        if (! $parsedFrom || ! $parsedTo) {
            throw new InvalidArgumentException(
                "DateRange: invalid date strings. Expected format '{$format}'."
            );
        }

        return new self($parsedFrom, $parsedTo);
    }

    public static function lastDays(int $days): self
    {
        return new self(
            Carbon::today()->subDays($days - 1),
            Carbon::today(),
        );
    }

    public static function currentMonth(): self
    {
        return new self(
            Carbon::now()->startOfMonth(),
            Carbon::now()->endOfMonth(),
        );
    }

    public function containsDate(Carbon $date): bool
    {
        return $date->between($this->from, $this->to);
    }

    public function days(): int
    {
        return (int) $this->from->diffInDays($this->to) + 1;
    }

    public function fromSql(): string
    {
        return $this->from->toDateTimeString();
    }

    public function toSql(): string
    {
        return $this->to->toDateTimeString();
    }

    public function toArray(): array
    {
        return [
            'from' => $this->from->toDateString(),
            'to' => $this->to->toDateString(),
        ];
    }
}
