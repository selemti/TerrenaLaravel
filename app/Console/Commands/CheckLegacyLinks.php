<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Filesystem\Filesystem;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;

class CheckLegacyLinks extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'legacy:scan {--pattern=* : Patrones adicionales a buscar en las vistas}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Escanea resources/views en busca de enlaces legacy (/api/v1, /legacy/*, etc.)';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $filesystem = new Filesystem();
        $viewsPath = resource_path('views');

        if (! $filesystem->exists($viewsPath)) {
            $this->error('No se encontró el directorio de vistas.');
            return self::FAILURE;
        }

        $defaultPatterns = [
            '/api/v1',
            '/legacy/recetas',
            '/legacy/reportes',
            '/legacy/admin',
            '/reportes',
            '/admin',
        ];

        $extraPatterns = Arr::wrap($this->option('pattern'));
        $patterns = array_values(array_unique(array_filter(array_merge($defaultPatterns, $extraPatterns))));

        $matches = [];
        foreach ($filesystem->allFiles($viewsPath) as $file) {
            $relativePath = Str::after($file->getPathname(), base_path() . DIRECTORY_SEPARATOR);
            $lines = preg_split('/\R/', $filesystem->get($file->getPathname()));

            foreach ($lines as $index => $line) {
                foreach ($patterns as $pattern) {
                    if ($pattern === '') {
                        continue;
                    }

                    if (Str::contains($line, $pattern)) {
                        $matches[] = [
                            'file' => $relativePath,
                            'line' => $index + 1,
                            'pattern' => $pattern,
                            'snippet' => Str::limit(trim($line), 120),
                        ];
                    }
                }
            }
        }

        if (empty($matches)) {
            $this->info('Sin coincidencias legacy en resources/views.');
            return self::SUCCESS;
        }

        $this->line('Coincidencias encontradas:');
        $this->table(
            ['Archivo', 'Línea', 'Patrón', 'Fragmento'],
            array_map(static function (array $match) {
                return [
                    $match['file'],
                    $match['line'],
                    $match['pattern'],
                    $match['snippet'],
                ];
            }, $matches)
        );

        $this->warn('Revisa los enlaces legacy y actualiza la UI según corresponda.');

        return self::SUCCESS;
    }
}
