<?php

namespace App\Http\Controllers\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Audit\AuditLogService;
use App\Services\Inventory\InsumoCodeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InsumoController extends Controller
{
    public function __construct(
        private readonly InsumoCodeService $codeService,
        private AuditLogService $auditLogService
    )
    {
        $this->middleware(['auth', 'permission:inventory.items.manage']);
    }

    public function create()
    {
        return view('inventory.insumos.create');
    }

    public function store(Request $request): JsonResponse
    {
        // TODO: evaluar autorización granular adicional si se requiere endurecer más adelante.

        $validated = $request->validate([
            'categoria_codigo'    => ['required', 'string', 'max:4'],
            'subcategoria_codigo' => ['required', 'string', 'max:6'],
            'nombre'              => ['required', 'string', 'max:255'],
            'um_id'               => ['required', 'integer'],
            'sku'                 => ['nullable', 'string', 'max:120'],
            'perecible'           => ['sometimes', 'boolean'],
            'merma_pct'           => ['sometimes', 'numeric', 'between:0,100'],
            'meta'                => ['sometimes', 'array'],
        ]);

        $codes = $this->codeService->generateCode(
            $validated['categoria_codigo'],
            $validated['subcategoria_codigo']
        );

        $meta = $validated['meta'] ?? null;
        if ($meta !== null) {
            $meta = json_encode($meta);
        }

        // TODO: Esta tabla vive realmente en el esquema selemti. Ajustar conexión/schema en prod si es necesario.
        $id = DB::table('insumo')->insertGetId([
            'codigo'              => $codes['codigo'],
            'categoria_codigo'    => $codes['categoria'],
            'subcategoria_codigo' => $codes['subcategoria'],
            'consecutivo'         => $codes['consecutivo'],
            'nombre'              => $validated['nombre'],
            'um_id'               => $validated['um_id'],
            'sku'                 => $validated['sku'] ?? null,
            'perecible'           => $validated['perecible'] ?? false,
            'merma_pct'           => $validated['merma_pct'] ?? 0,
            'activo'              => true,
            'meta'                => $meta,
        ]);

        // Registrar auditoría de creación de insumo
        $this->auditLogService->logAction(
            (int) auth()->id(),
            'INSUMO_CREATE',
            'insumo',
            (int) $id,
            (string) $request->input('motivo', ''),
            $request->input('evidencia_url'),
            $request->all()
        );

        return response()->json([
            'ok'     => true,
            'id'     => $id,
            'codigo' => $codes['codigo'],
        ], 201);
    }

    public function bulkImport(Request $request): JsonResponse
    {
        // TODO: implementar carga masiva (CSV/Excel) reutilizando InsumoCodeService para cada fila.
        return response()->json([
            'ok'      => false,
            'message' => 'bulkImport pendiente de implementación.',
        ], 501);
    }
}
