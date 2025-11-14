<?php

namespace App\Models\Catalogs;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class Sucursal extends Model
{
    protected $connection = 'pgsql';

    protected $table = 'selemti.cat_sucursales';

    protected $fillable = [
        'clave',
        'nombre',
        'ubicacion',
        'pos_location',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function almacenes()
    {
        return $this->hasMany(Almacen::class, 'sucursal_id');
    }

    /**
     * Get terminals assigned to this sucursal's POS location
     */
    public function getTerminalesAttribute()
    {
        if (! $this->pos_location) {
            return collect([]);
        }

        return DB::connection('pgsql')
            ->table('public.terminal')
            ->where('location', $this->pos_location)
            ->get(['id', 'name', 'location']);
    }

    /**
     * Get available POS locations from terminal table
     */
    public static function getAvailablePosLocations()
    {
        return DB::connection('pgsql')
            ->table('public.terminal')
            ->select('location')
            ->distinct()
            ->whereNotNull('location')
            ->orderBy('location')
            ->pluck('location');
    }

    /**
     * Get count of terminals for a given POS location
     */
    public static function getTerminalCountByLocation(string $location): int
    {
        return DB::connection('pgsql')
            ->table('public.terminal')
            ->where('location', $location)
            ->count();
    }

    /**
     * Get POS locations from public.terminal that are NOT linked to any sucursal
     * These are locations that exist in the POS system but don't have a corresponding sucursal
     */
    public static function getUnlinkedPosLocations()
    {
        // Get all distinct locations from public.terminal (excluding empty/null)
        $allPosLocations = DB::connection('pgsql')
            ->table('public.terminal')
            ->select('location')
            ->distinct()
            ->whereNotNull('location')
            ->where('location', '!=', '')
            ->pluck('location')
            ->toArray();

        // Get locations already linked to sucursales
        $linkedLocations = static::whereNotNull('pos_location')
            ->where('pos_location', '!=', '')
            ->pluck('pos_location')
            ->toArray();

        // Return locations that are in POS but not linked to any sucursal
        $unlinked = array_diff($allPosLocations, $linkedLocations);

        // Get terminal count for each unlinked location
        $result = [];
        foreach ($unlinked as $location) {
            $result[] = [
                'location' => $location,
                'terminal_count' => static::getTerminalCountByLocation($location),
            ];
        }

        return collect($result);
    }
}
