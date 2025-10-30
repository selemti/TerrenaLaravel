<?php

namespace App\Http\Controllers\Audit;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EvidenceController extends Controller
{
    public function upload(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'error' => 'UNAUTHORIZED',
                'message' => 'Usuario no autenticado',
                'timestamp' => now()->toIso8601String(),
            ], 401);
        }

        $request->validate([
            'file' => 'required|image|max:2048',
        ]);

        // TODO: Implementar política de retención y borrado seguro de evidencias.
        // TODO: mover al storage definitivo o S3 según configuración
        $path = $request->file('file')->store('audit_evidence', 'public');

        return response()->json([
            'ok' => true,
            'evidencia_url' => asset('storage/' . $path),
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
