<?php

namespace Tests\Unit\ValueObjects;

use App\ValueObjects\DateRange;
use Carbon\Carbon;
use InvalidArgumentException;
use Tests\TestCase;

class DateRangeTest extends TestCase
{
    public function test_constructs_from_carbon_instances(): void
    {
        $from = Carbon::parse('2026-01-01');
        $to = Carbon::parse('2026-01-31');
        $range = new DateRange($from, $to);

        $this->assertEquals('2026-01-01', $range->from->toDateString());
        $this->assertEquals('2026-01-31', $range->to->toDateString());
    }

    public function test_from_strings_parses_correctly(): void
    {
        $range = DateRange::fromStrings('2026-03-01', '2026-03-31');

        $this->assertEquals('2026-03-01', $range->from->toDateString());
        $this->assertEquals('2026-03-31', $range->to->toDateString());
    }

    public function test_throws_when_from_after_to(): void
    {
        $this->expectException(InvalidArgumentException::class);

        new DateRange(Carbon::parse('2026-05-15'), Carbon::parse('2026-05-01'));
    }

    public function test_same_day_is_valid(): void
    {
        $range = DateRange::fromStrings('2026-04-10', '2026-04-10');

        $this->assertEquals(1, $range->days());
    }

    public function test_days_counts_inclusive(): void
    {
        $range = DateRange::fromStrings('2026-01-01', '2026-01-07');

        $this->assertEquals(7, $range->days());
    }

    public function test_last_days_factory(): void
    {
        $range = DateRange::lastDays(7);

        $this->assertEquals(7, $range->days());
        $this->assertEquals(Carbon::today()->toDateString(), $range->to->toDateString());
    }

    public function test_current_month_factory(): void
    {
        $range = DateRange::currentMonth();

        $this->assertEquals(Carbon::now()->startOfMonth()->toDateString(), $range->from->toDateString());
        $this->assertEquals(Carbon::now()->endOfMonth()->toDateString(), $range->to->toDateString());
    }

    public function test_contains_date_true(): void
    {
        $range = DateRange::fromStrings('2026-01-01', '2026-01-31');

        $this->assertTrue($range->containsDate(Carbon::parse('2026-01-15')));
    }

    public function test_contains_date_false(): void
    {
        $range = DateRange::fromStrings('2026-01-01', '2026-01-31');

        $this->assertFalse($range->containsDate(Carbon::parse('2026-02-01')));
    }

    public function test_to_array_returns_date_strings(): void
    {
        $range = DateRange::fromStrings('2026-06-01', '2026-06-30');
        $arr = $range->toArray();

        $this->assertEquals('2026-06-01', $arr['from']);
        $this->assertEquals('2026-06-30', $arr['to']);
    }

    public function test_from_sql_includes_start_of_day(): void
    {
        $range = DateRange::fromStrings('2026-05-01', '2026-05-31');

        $this->assertStringStartsWith('2026-05-01 00:00:00', $range->fromSql());
    }

    public function test_to_sql_includes_end_of_day(): void
    {
        $range = DateRange::fromStrings('2026-05-01', '2026-05-31');

        $this->assertStringStartsWith('2026-05-31 23:59:59', $range->toSql());
    }
}
