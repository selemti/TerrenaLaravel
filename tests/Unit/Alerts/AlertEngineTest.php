<?php

namespace Tests\Unit\Alerts;

use App\Services\Alerts\AlertEngine;
use Illuminate\Support\Facades\DB;
use Mockery;
use Tests\TestCase;

class AlertEngineTest extends TestCase
{
    protected function tearDown(): void
    {
        parent::tearDown();

        Mockery::close();
    }

    public function test_run_returns_when_no_rules(): void
    {
        DB::shouldReceive('connection')->once()->with('pgsql')->andReturnSelf();
        DB::shouldReceive('transaction')->once()->andReturnUsing(function ($callback) {
            $callback();
        });

        DB::shouldReceive('table')->once()->with('selemti.alert_rules')->andReturnSelf();
        DB::shouldReceive('where')->once()->with('enabled', true)->andReturnSelf();
        DB::shouldReceive('get')->once()->andReturn(collect());

        $engine = new AlertEngine();
        $engine->run();

        $this->addToAssertionCount(1);
    }
}
