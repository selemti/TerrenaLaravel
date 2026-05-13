<?php

namespace Tests\Unit;

use Tests\TestCase;

/**
 * Critical guardrails — these tests protect invariants that, if broken,
 * cause catastrophic data loss or security regressions. They run in < 1ms
 * and must never be skipped or removed.
 *
 * IF ANY OF THESE FAIL: stop, read the message, and fix the root cause.
 * Do NOT work around them by adding markTestSkipped().
 */
class GuardRailsTest extends TestCase
{
    /**
     * DB_SCHEMA must NEVER include "public" in the test environment.
     *
     * WHY: Laravel's RefreshDatabase calls migrate:fresh which calls
     * Schema::dropAllTables(). PostgresBuilder::getAllTables() uses the
     * connection's search_path (derived from DB_SCHEMA) to decide which
     * tables to drop. If "public" is included, all 108 FloreantPOS tables
     * (ticket, terminal, cash_drawer, etc.) are wiped on every test run.
     * This happened on 2026-05-13 and required a full restore from production.
     *
     * CORRECT value in phpunit.xml: <env name="DB_SCHEMA" value="selemti"/>
     * NEVER:                        <env name="DB_SCHEMA" value="selemti,public"/>
     */
    public function test_db_schema_does_not_include_public(): void
    {
        $schema = config('database.connections.pgsql.schema');
        $schemas = is_array($schema) ? $schema : array_map('trim', explode(',', (string) $schema));

        $this->assertNotContains(
            'public',
            $schemas,
            "CRITICAL: DB_SCHEMA includes 'public'. This will wipe all FloreantPOS tables " .
            "(ticket, terminal, cash_drawer, etc.) every time RefreshDatabase runs migrate:fresh. " .
            "Fix phpunit.xml: set DB_SCHEMA to 'selemti' only. See incident 2026-05-13."
        );
    }

    /**
     * phpunit.xml must declare DB_SCHEMA explicitly.
     *
     * WHY: If DB_SCHEMA is removed from phpunit.xml, the value falls back to
     * the .env file. If .env ever sets selemti,public (or worse, has no value
     * and PostgreSQL defaults to "$user,public"), the protection above is
     * silently bypassed during test runs.
     */
    public function test_phpunit_xml_declares_db_schema(): void
    {
        $phpunitXml = base_path('phpunit.xml');
        $this->assertFileExists($phpunitXml);

        $content = file_get_contents($phpunitXml);
        $this->assertStringContainsString(
            'DB_SCHEMA',
            $content,
            "CRITICAL: phpunit.xml must explicitly declare DB_SCHEMA to prevent " .
            "falling back to .env values that might include 'public'."
        );
    }

    /**
     * The public schema migration must use IF NOT EXISTS guard.
     *
     * WHY: The migration 2025_09_01_000007_create_public_menu_category_table.php
     * creates a table in the public (FloreantPOS) schema. It must check for
     * existence first so it never overwrites production POS data.
     */
    public function test_public_schema_migration_has_existence_guard(): void
    {
        $migrationFile = database_path('migrations/2025_09_01_000007_create_public_menu_category_table.php');
        $this->assertFileExists($migrationFile, 'Migration for public.menu_category not found.');

        $content = file_get_contents($migrationFile);
        $this->assertTrue(
            str_contains($content, 'IF NOT EXISTS') || str_contains($content, 'information_schema'),
            "CRITICAL: The public.menu_category migration must guard against overwriting " .
            "existing FloreantPOS data. Use IF NOT EXISTS or check information_schema first."
        );
    }
}
