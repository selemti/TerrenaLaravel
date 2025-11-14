<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class DbSelectCommand extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'db:select 
        {query : SELECT/WITH statement to execute}
        {--bindings= : JSON array of positional bindings}
        {--schema= : Optional schema search_path override (comma-separated)}
        {--first : Return first row only}';

    /**
     * The console command description.
     */
    protected $description = 'Execute a read-only SELECT (or WITH) SQL against the configured database and output JSON results';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $sql = trim((string) $this->argument('query'));
        $lower = ltrim(strtolower($sql));

        // Guard: only allow read-only statements (SELECT or WITH ... SELECT)
        if (! (str_starts_with($lower, 'select') || str_starts_with($lower, 'with'))) {
            $this->error('Only SELECT or WITH queries are allowed.');

            return self::INVALID;
        }

        // Optional: very basic destructive keyword guard
        $blocked = [' insert ', ' update ', ' delete ', ' drop ', ' alter ', ' truncate ', ' grant ', ' revoke '];
        $lowerPadded = ' '.preg_replace('/\s+/', ' ', $lower).' ';
        foreach ($blocked as $kw) {
            if (str_contains($lowerPadded, $kw)) {
                $this->error('Detected potentially destructive keyword: '.trim($kw));

                return self::INVALID;
            }
        }

        // Apply search_path if provided or via env(DB_SCHEMA)
        $schema = $this->option('schema');
        if (! $schema) {
            $schema = env('DB_SCHEMA');
        }

        try {
            if ($schema) {
                DB::statement('set search_path to '.$schema);
            }

            $bindings = [];
            if ($b = $this->option('bindings')) {
                $decoded = json_decode($b, true);
                if (! is_array($decoded)) {
                    $this->error('Bindings must be a JSON array.');

                    return self::INVALID;
                }
                $bindings = array_values($decoded);
            }

            if ($this->option('first')) {
                // Run and print only first row
                $row = DB::selectOne($sql, $bindings);
                $this->line(json_encode($row, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
            } else {
                $rows = DB::select($sql, $bindings);
                $this->line(json_encode($rows, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
            }
        } catch (\Throwable $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }

        return self::SUCCESS;
    }
}
