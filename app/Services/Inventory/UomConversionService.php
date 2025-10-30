<?php

namespace App\Services\Inventory;

use App\Models\Catalogs\Unidad;
use App\Models\Catalogs\UomConversion;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

/**
 * UomConversionService
 *
 * Service for converting quantities between units of measure (UOM).
 *
 * Features:
 * - Direct conversion using cat_uom_conversion table
 * - Resolution by clave (e.g., 'KG', 'G', 'L')
 * - Exact vs approximate conversion detection
 * - Scope preference (global/house)
 * - Caching for performance
 *
 * Usage:
 * ```php
 * $service = new UomConversionService();
 * $result = $service->convert(2.5, 'KG', 'G');
 * // ['success' => true, 'result' => 2500.0, 'is_approx' => false, ...]
 * ```
 *
 * @package App\Services\Inventory
 * @see docs/UOM_STRATEGY_TERRENA.md
 */
class UomConversionService
{
    /**
     * Cache TTL in seconds (1 hour)
     */
    const CACHE_TTL = 3600;

    /**
     * Convert a value from one UOM to another
     *
     * @param float $value Quantity to convert
     * @param string $fromClave Origin UOM clave (e.g., 'KG')
     * @param string $toClave Destination UOM clave (e.g., 'G')
     * @param string $preferScope Preferred scope: 'global', 'house', or 'any'
     * @return array Result array with keys:
     *               - success: bool (true if conversion succeeded)
     *               - result: float (converted value)
     *               - is_approx: bool (true if conversion is approximate)
     *               - factor: float (conversion factor used)
     *               - scope: string ('global' or 'house')
     *               - notes: string|null (additional notes)
     *               - error: string|null (error message if failed)
     */
    public function convert(
        float $value,
        string $fromClave,
        string $toClave,
        string $preferScope = 'any'
    ): array {
        // Normalize claves to uppercase
        $fromClave = strtoupper(trim($fromClave));
        $toClave = strtoupper(trim($toClave));

        // Special case: same UOM (no conversion needed)
        if ($fromClave === $toClave) {
            return [
                'success' => true,
                'result' => $value,
                'is_approx' => false,
                'factor' => 1.0,
                'scope' => 'global',
                'notes' => 'No conversion needed (same UOM)',
                'error' => null,
            ];
        }

        // Validate scope parameter
        if (!in_array($preferScope, ['global', 'house', 'any'])) {
            return $this->error("Invalid scope: {$preferScope}. Must be 'global', 'house', or 'any'.");
        }

        // Find conversion using cache
        $cacheKey = "uom_conversion:{$fromClave}:{$toClave}:{$preferScope}";

        try {
            $conversion = Cache::remember($cacheKey, self::CACHE_TTL, function () use ($fromClave, $toClave, $preferScope) {
                return $this->findConversion($fromClave, $toClave, $preferScope);
            });

            if (!$conversion) {
                return $this->error("No conversion found from {$fromClave} to {$toClave}");
            }

            // Apply conversion
            $result = $value * (float) $conversion->factor;

            return [
                'success' => true,
                'result' => $result,
                'is_approx' => !$conversion->is_exact,
                'factor' => (float) $conversion->factor,
                'scope' => $conversion->scope,
                'notes' => $conversion->notes,
                'error' => null,
            ];
        } catch (\Exception $e) {
            Log::error("UomConversionService: Conversion error", [
                'from' => $fromClave,
                'to' => $toClave,
                'value' => $value,
                'error' => $e->getMessage(),
            ]);

            return $this->error("Conversion error: " . $e->getMessage());
        }
    }

    /**
     * Find conversion record between two UOM claves
     *
     * @param string $fromClave Origin UOM clave
     * @param string $toClave Destination UOM clave
     * @param string $preferScope Preferred scope
     * @return UomConversion|null
     */
    protected function findConversion(string $fromClave, string $toClave, string $preferScope): ?UomConversion
    {
        // Resolve UOM IDs
        $fromUom = Unidad::activas()->porClave($fromClave)->first();
        $toUom = Unidad::activas()->porClave($toClave)->first();

        if (!$fromUom || !$toUom) {
            return null;
        }

        // Build query
        $query = UomConversion::where('origen_id', $fromUom->id)
            ->where('destino_id', $toUom->id);

        // Apply scope preference
        if ($preferScope === 'global') {
            $query->global();
        } elseif ($preferScope === 'house') {
            $query->house();
        } else {
            // 'any': prefer global over house
            $query->orderByRaw("CASE WHEN scope = 'global' THEN 1 ELSE 2 END");
        }

        return $query->first();
    }

    /**
     * Get all conversions for a given UOM clave
     *
     * @param string $clave UOM clave (e.g., 'KG')
     * @param string $direction 'from' (as origen) or 'to' (as destino) or 'both'
     * @return array Array of conversions with formatted data
     */
    public function getConversionsFor(string $clave, string $direction = 'both'): array
    {
        $clave = strtoupper(trim($clave));
        $uom = Unidad::activas()->porClave($clave)->first();

        if (!$uom) {
            return [];
        }

        $conversions = [];

        // From (origen)
        if ($direction === 'from' || $direction === 'both') {
            $fromConversions = $uom->conversionesOrigen()
                ->with('destino')
                ->get()
                ->map(function ($conv) use ($clave) {
                    return [
                        'from' => $clave,
                        'to' => $conv->destino->clave,
                        'factor' => (float) $conv->factor,
                        'is_exact' => $conv->is_exact,
                        'scope' => $conv->scope,
                        'notes' => $conv->notes,
                        'formula' => "1 {$clave} = {$conv->factor} {$conv->destino->clave}",
                    ];
                });

            $conversions = array_merge($conversions, $fromConversions->toArray());
        }

        // To (destino)
        if ($direction === 'to' || $direction === 'both') {
            $toConversions = $uom->conversionesDestino()
                ->with('origen')
                ->get()
                ->map(function ($conv) use ($clave) {
                    $inverseFactor = 1.0 / (float) $conv->factor;
                    return [
                        'from' => $conv->origen->clave,
                        'to' => $clave,
                        'factor' => $inverseFactor,
                        'is_exact' => $conv->is_exact,
                        'scope' => $conv->scope,
                        'notes' => $conv->notes,
                        'formula' => "1 {$conv->origen->clave} = {$conv->factor} {$clave}",
                    ];
                });

            $conversions = array_merge($conversions, $toConversions->toArray());
        }

        return $conversions;
    }

    /**
     * Validate if a conversion exists between two UOM claves
     *
     * @param string $fromClave Origin UOM clave
     * @param string $toClave Destination UOM clave
     * @param string $preferScope Preferred scope
     * @return bool
     */
    public function canConvert(string $fromClave, string $toClave, string $preferScope = 'any'): bool
    {
        $fromClave = strtoupper(trim($fromClave));
        $toClave = strtoupper(trim($toClave));

        if ($fromClave === $toClave) {
            return true; // Same UOM, always convertible
        }

        $conversion = $this->findConversion($fromClave, $toClave, $preferScope);

        return $conversion !== null;
    }

    /**
     * Normalize quantity to base UOM (KG, L, PZ)
     *
     * This is used for kardex entries where all quantities must be in base units.
     *
     * @param float $value Quantity to normalize
     * @param string $fromClave Origin UOM clave
     * @param string $tipo Type: 'PESO' (→ KG), 'VOLUMEN' (→ L), 'UNIDAD' (→ PZ)
     * @return array Result with normalized value and base UOM
     */
    public function normalizeToBase(float $value, string $fromClave, string $tipo): array
    {
        // Determine base UOM by tipo
        $baseUom = match (strtoupper($tipo)) {
            'PESO' => 'KG',
            'VOLUMEN' => 'L',
            'UNIDAD' => 'PZ',
            default => throw new \InvalidArgumentException("Invalid tipo: {$tipo}. Must be PESO, VOLUMEN, or UNIDAD."),
        };

        // Convert to base UOM
        $result = $this->convert($value, $fromClave, $baseUom, 'global');

        if (!$result['success']) {
            // If direct conversion fails, try to identify if the UOM is already base
            if (strtoupper($fromClave) === $baseUom) {
                return [
                    'success' => true,
                    'normalized_value' => $value,
                    'base_uom' => $baseUom,
                    'original_uom' => $fromClave,
                    'is_approx' => false,
                ];
            }

            return [
                'success' => false,
                'error' => $result['error'],
            ];
        }

        return [
            'success' => true,
            'normalized_value' => $result['result'],
            'base_uom' => $baseUom,
            'original_uom' => $fromClave,
            'factor' => $result['factor'],
            'is_approx' => $result['is_approx'],
        ];
    }

    /**
     * Clear conversion cache
     *
     * Call this after updating conversion factors.
     *
     * @return void
     */
    public function clearCache(): void
    {
        Cache::flush(); // or more specific cache key pattern
        Log::info("UomConversionService: Cache cleared");
    }

    /**
     * Build error response array
     *
     * @param string $message Error message
     * @return array
     */
    protected function error(string $message): array
    {
        return [
            'success' => false,
            'result' => null,
            'is_approx' => null,
            'factor' => null,
            'scope' => null,
            'notes' => null,
            'error' => $message,
        ];
    }
}
