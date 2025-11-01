<?php

namespace Tests\Support;

use Illuminate\Support\Facades\DB;

trait RequiresPostgresConnection
{
    protected function requirePostgresConnection(): void
    {
        try {
            DB::connection('pgsql')->getPdo();
        } catch (\Throwable $e) {
            $this->markTestSkipped('PostgreSQL connection unavailable: ' . $e->getMessage());
        }
    }
}
