<?php

namespace App\Http\Controllers\Api;

use App\Adapters\FloreantPos\FloreantPosAdapter;
use App\Http\Controllers\Controller;
use App\Models\Catalogs\Almacen;
use App\Models\Catalogs\Sucursal;
use App\Models\Catalogs\Unidad;
use Illuminate\Http\Request;

class CatalogsController extends Controller
{
    public function __construct(private readonly FloreantPosAdapter $pos) {}

    // GET /api/catalogs/categories
    public function categories(Request $r)
    {
        $categories = $this->pos->getMenuCategories(visibleOnly: ! $r->boolean('show_all'));

        return response()->json([
            'ok' => true,
            'data' => $categories,
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    // GET /api/catalogs/almacenes (warehouses)
    public function almacenes(Request $r)
    {
        $query = Almacen::query();

        // Only active warehouses by default
        if (! $r->boolean('show_all')) {
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
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    // GET /api/catalogs/sucursales (branches)
    public function sucursales(Request $r)
    {
        $query = Sucursal::query();

        // Only active branches by default
        if (! $r->boolean('show_all')) {
            $query->where('activo', true);
        }

        $sucursales = $query->orderBy('nombre')->get();

        return response()->json([
            'ok' => true,
            'data' => $sucursales,
            'timestamp' => now()->toIso8601String(),
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
                'sign' => '+',
            ],
            [
                'value' => 'SALIDA',
                'label' => 'Salida',
                'description' => 'Salida de inventario',
                'affects_stock' => true,
                'sign' => '-',
            ],
            [
                'value' => 'AJUSTE',
                'label' => 'Ajuste',
                'description' => 'Ajuste de inventario',
                'affects_stock' => true,
                'sign' => '±',
            ],
            [
                'value' => 'MERMA',
                'label' => 'Merma',
                'description' => 'Merma o desperdicio',
                'affects_stock' => true,
                'sign' => '-',
            ],
            [
                'value' => 'RECEPCION',
                'label' => 'Recepción',
                'description' => 'Recepción de compra',
                'affects_stock' => true,
                'sign' => '+',
            ],
            [
                'value' => 'TRASPASO_IN',
                'label' => 'Traspaso Entrada',
                'description' => 'Traspaso entre almacenes (entrada)',
                'affects_stock' => true,
                'sign' => '+',
            ],
            [
                'value' => 'TRASPASO_OUT',
                'label' => 'Traspaso Salida',
                'description' => 'Traspaso entre almacenes (salida)',
                'affects_stock' => true,
                'sign' => '-',
            ],
        ];

        return response()->json([
            'ok' => true,
            'data' => $types,
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    // GET /api/catalogs/unidades
    public function unidades(Request $request)
    {
        $query = Unidad::query();

        // Support both 'tipo' (legacy) and 'categoria' as filter params
        if ($request->filled('tipo')) {
            $query->where('categoria', $request->input('tipo'));
        }

        if ($request->filled('categoria')) {
            $query->where('categoria', $request->input('categoria'));
        }

        $total = (clone $query)->count();

        if ($request->boolean('only_count')) {
            return response()->json([
                'ok' => true,
                'count' => $total,
                'data' => [],
                'timestamp' => now()->toIso8601String(),
            ]);
        }

        $limit = (int) $request->input('limit', 250);
        $limit = max(1, min($limit, 500));

        $units = $query
            ->orderBy('clave')
            ->limit($limit)
            ->get(['id', 'clave', 'nombre', 'categoria', 'activo'])
            ->map(fn ($u) => [
                'id' => $u->id,
                'codigo' => $u->clave,
                'nombre' => $u->nombre,
                'tipo' => $u->categoria,
                'categoria' => $u->categoria,
                'activo' => $u->activo,
            ]);

        return response()->json([
            'ok' => true,
            'count' => $total,
            'data' => $units,
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
