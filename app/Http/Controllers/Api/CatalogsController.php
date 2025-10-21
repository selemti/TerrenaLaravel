<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Catalogs\Almacen;
use App\Models\Catalogs\Sucursal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CatalogsController extends Controller
{
    // GET /api/catalogs/categories
    public function categories(Request $r)
    {
        $query = DB::connection('pgsql')
            ->table('public.menu_category')
            ->select([
                DB::raw("'CAT-' || id::text as id"),
                'name',
                'translated_name',
                'visible',
                'beverage',
                'sort_order'
            ])
            ->orderBy('sort_order')
            ->orderBy('name');

        // Only visible categories by default
        if (!$r->boolean('show_all')) {
            $query->where('visible', true);
        }

        $categories = $query->get();

        return response()->json([
            'ok' => true,
            'data' => $categories,
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // GET /api/catalogs/almacenes (warehouses)
    public function almacenes(Request $r)
    {
        $query = Almacen::query();

        // Only active warehouses by default
        if (!$r->boolean('show_all')) {
            $query->where('activo', true);
        }

        if ($r->filled('sucursal_id')) {
            $query->where('sucursal_id', $r->get('sucursal_id'));
        }

        $almacenes = $query->with('sucursal')
            ->orderBy('nombre')
            ->get();

        return response()->json([
            'ok' => true,
            'data' => $almacenes,
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // GET /api/catalogs/sucursales (branches)
    public function sucursales(Request $r)
    {
        $query = Sucursal::query();

        // Only active branches by default
        if (!$r->boolean('show_all')) {
            $query->where('activo', true);
        }

        $sucursales = $query->orderBy('nombre')->get();

        return response()->json([
            'ok' => true,
            'data' => $sucursales,
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // GET /api/catalogs/movement-types
    public function movementTypes()
    {
        $types = [
            [
                'value' => 'ENTRADA',
                'label' => 'Entrada',
                'description' => 'Entrada de inventario',
                'affects_stock' => true,
                'sign' => '+'
            ],
            [
                'value' => 'SALIDA',
                'label' => 'Salida',
                'description' => 'Salida de inventario',
                'affects_stock' => true,
                'sign' => '-'
            ],
            [
                'value' => 'AJUSTE',
                'label' => 'Ajuste',
                'description' => 'Ajuste de inventario',
                'affects_stock' => true,
                'sign' => '±'
            ],
            [
                'value' => 'MERMA',
                'label' => 'Merma',
                'description' => 'Merma o desperdicio',
                'affects_stock' => true,
                'sign' => '-'
            ],
            [
                'value' => 'RECEPCION',
                'label' => 'Recepción',
                'description' => 'Recepción de compra',
                'affects_stock' => true,
                'sign' => '+'
            ],
            [
                'value' => 'TRASPASO_IN',
                'label' => 'Traspaso Entrada',
                'description' => 'Traspaso entre almacenes (entrada)',
                'affects_stock' => true,
                'sign' => '+'
            ],
            [
                'value' => 'TRASPASO_OUT',
                'label' => 'Traspaso Salida',
                'description' => 'Traspaso entre almacenes (salida)',
                'affects_stock' => true,
                'sign' => '-'
            ],
        ];

        return response()->json([
            'ok' => true,
            'data' => $types,
            'timestamp' => now()->toIso8601String()
        ]);
    }
}
