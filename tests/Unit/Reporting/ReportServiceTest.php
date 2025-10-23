<?php

namespace Tests\Unit\Reporting;

use App\Services\Reporting\ReportService;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use Mockery;
use Tests\TestCase;

class ReportServiceTest extends TestCase
{
    protected function tearDown(): void
    {
        parent::tearDown();

        Mockery::close();
    }

    public function test_run_throws_when_definition_missing(): void
    {
        DB::shouldReceive('table')->once()->with('selemti.report_definitions')->andReturnSelf();
        DB::shouldReceive('where')->once()->with('slug', 'inexistent')->andReturnSelf();
        DB::shouldReceive('first')->once()->andReturn(null);

        $service = new ReportService();

        $this->expectException(InvalidArgumentException::class);
        $service->run('inexistent');
    }
}
