<?php

namespace App\Services\Recetas;

use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Rec\RecetaVersion;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * Servicio para gestión de versionado de recetas
 * 
 * Implementa:
 * - Creación de nuevas versiones (clonado de versión activa)
 * - Publicación de versiones
 * - Comparación entre versiones
 * 
 * @see RecetaVersion
 * @see RecetaDetalle
 */
class RecipeVersionService
{
    /**
     * Crea una nueva versión de una receta clonando la versión activa actual
     * 
     * Flujo:
     * 1. Obtiene la versión publicada actual (si existe)
     * 2. Crea nueva fila en receta_version con version++
     * 3. Clona todos los ingredientes (receta_det) a la nueva versión
     * 4. Retorna la nueva versión creada
     * 
     * @param string $recetaId ID de la receta (VARCHAR)
     * @param int $userId ID del usuario que crea la versión
     * @param string|null $descripcionCambios Descripción opcional de los cambios
     * @return RecetaVersion Nueva versión creada (en estado draft)
     * @throws InvalidArgumentException Si la receta no existe
     */
    public function createNewVersion(
        string $recetaId, 
        int $userId, 
        ?string $descripcionCambios = null
    ): RecetaVersion 
    {
        return DB::transaction(function () use ($recetaId, $userId, $descripcionCambios) {
            // Verificar que la receta existe
            $receta = Receta::find($recetaId);
            if (!$receta) {
                throw new InvalidArgumentException("Receta {$recetaId} no encontrada");
            }

            // Obtener la versión publicada actual (fuente de clonado)
            $versionActual = RecetaVersion::where('receta_id', $recetaId)
                ->where('version_publicada', true)
                ->orderByDesc('version')
                ->first();

            // Si no hay versión publicada, buscar la última versión disponible
            if (!$versionActual) {
                $versionActual = RecetaVersion::where('receta_id', $recetaId)
                    ->orderByDesc('version')
                    ->first();
            }

            // Calcular número de versión
            $ultimaVersion = RecetaVersion::where('receta_id', $recetaId)
                ->max('version') ?? 0;
            $nuevaVersionNumero = $ultimaVersion + 1;

            // Crear nueva versión (draft)
            $nuevaVersion = RecetaVersion::create([
                'receta_id' => $recetaId,
                'version' => $nuevaVersionNumero,
                'descripcion_cambios' => $descripcionCambios ?? "Versión {$nuevaVersionNumero} creada",
                'fecha_efectiva' => now()->toDateString(),
                'version_publicada' => false,
                'usuario_publicador' => null,
                'fecha_publicacion' => null,
                'created_at' => now(),
            ]);

            // Clonar ingredientes de la versión actual (si existe)
            if ($versionActual) {
                $ingredientes = RecetaDetalle::where('receta_version_id', $versionActual->id)
                    ->orderBy('orden')
                    ->get();

                foreach ($ingredientes as $ingrediente) {
                    RecetaDetalle::create([
                        'receta_version_id' => $nuevaVersion->id,
                        'item_id' => $ingrediente->item_id,
                        'cantidad' => $ingrediente->cantidad,
                        'unidad_medida' => $ingrediente->unidad_medida,
                        'merma_porcentaje' => $ingrediente->merma_porcentaje,
                        'instrucciones_especificas' => $ingrediente->instrucciones_especificas,
                        'orden' => $ingrediente->orden,
                        'created_at' => now(),
                    ]);
                }
            }

            return $nuevaVersion->fresh('detalles');
        });
    }

    /**
     * Publica una versión de receta (la marca como activa)
     * 
     * Flujo:
     * 1. Marca la versión como publicada
     * 2. Desmarca cualquier otra versión publicada de la misma receta
     * 3. Actualiza fecha_publicacion y usuario_publicador
     * 4. TODO: Actualizar pos_map si aplica (INV-001 integración)
     * 
     * @param int $versionId ID de la versión a publicar
     * @param int $userId ID del usuario que publica
     * @return RecetaVersion Versión publicada
     * @throws InvalidArgumentException Si la versión no existe o ya está publicada
     */
    public function publishVersion(int $versionId, int $userId): RecetaVersion
    {
        return DB::transaction(function () use ($versionId, $userId) {
            $version = RecetaVersion::find($versionId);
            
            if (!$version) {
                throw new InvalidArgumentException("Versión {$versionId} no encontrada");
            }

            if ($version->version_publicada) {
                throw new InvalidArgumentException("La versión ya está publicada");
            }

            // Desmarcar cualquier versión publicada anterior de la misma receta
            RecetaVersion::where('receta_id', $version->receta_id)
                ->where('version_publicada', true)
                ->update([
                    'version_publicada' => false,
                ]);

            // Publicar la nueva versión
            $version->update([
                'version_publicada' => true,
                'usuario_publicador' => $userId,
                'fecha_publicacion' => now(),
            ]);

            // TODO: Actualizar pos_map con la nueva version
            // Esto requiere integración con PosConsumptionService (Sprint 2)
            // DB::table('selemti.pos_map')
            //     ->where('receta_id', $version->receta_id)
            //     ->update(['receta_version_id' => $version->id]);

            return $version->fresh();
        });
    }

    /**
     * Compara dos versiones de una receta
     * 
     * Retorna un array con:
     * - version1: Datos de la primera versión
     * - version2: Datos de la segunda versión
     * - diff: Array con diferencias en ingredientes
     *   - added: Ingredientes agregados en v2
     *   - removed: Ingredientes removidos de v1
     *   - modified: Ingredientes con cantidades/unidades modificadas
     * 
     * @param int $versionId1 ID de la primera versión
     * @param int $versionId2 ID de la segunda versión
     * @return array Comparación estructurada
     * @throws InvalidArgumentException Si alguna versión no existe o no son de la misma receta
     */
    public function compareVersions(int $versionId1, int $versionId2): array
    {
        $v1 = RecetaVersion::with('detalles.item')->find($versionId1);
        $v2 = RecetaVersion::with('detalles.item')->find($versionId2);

        if (!$v1 || !$v2) {
            throw new InvalidArgumentException("Una o ambas versiones no existen");
        }

        if ($v1->receta_id !== $v2->receta_id) {
            throw new InvalidArgumentException("Las versiones no pertenecen a la misma receta");
        }

        // Obtener ingredientes indexados por item_id
        $ingredientes1 = $v1->detalles->keyBy('item_id');
        $ingredientes2 = $v2->detalles->keyBy('item_id');

        $diff = [
            'added' => [],
            'removed' => [],
            'modified' => [],
        ];

        // Ingredientes agregados (están en v2 pero no en v1)
        foreach ($ingredientes2 as $itemId => $ingrediente) {
            if (!isset($ingredientes1[$itemId])) {
                $diff['added'][] = [
                    'item_id' => $itemId,
                    'item_nombre' => $ingrediente->item->nombre ?? $itemId,
                    'cantidad' => $ingrediente->cantidad,
                    'unidad_medida' => $ingrediente->unidad_medida,
                ];
            }
        }

        // Ingredientes removidos (están en v1 pero no en v2)
        foreach ($ingredientes1 as $itemId => $ingrediente) {
            if (!isset($ingredientes2[$itemId])) {
                $diff['removed'][] = [
                    'item_id' => $itemId,
                    'item_nombre' => $ingrediente->item->nombre ?? $itemId,
                    'cantidad' => $ingrediente->cantidad,
                    'unidad_medida' => $ingrediente->unidad_medida,
                ];
            }
        }

        // Ingredientes modificados (están en ambos pero con diferencias)
        foreach ($ingredientes1 as $itemId => $ing1) {
            if (isset($ingredientes2[$itemId])) {
                $ing2 = $ingredientes2[$itemId];
                
                if ($ing1->cantidad != $ing2->cantidad || 
                    $ing1->unidad_medida != $ing2->unidad_medida ||
                    $ing1->merma_porcentaje != $ing2->merma_porcentaje) {
                    
                    $diff['modified'][] = [
                        'item_id' => $itemId,
                        'item_nombre' => $ing1->item->nombre ?? $itemId,
                        'v1' => [
                            'cantidad' => $ing1->cantidad,
                            'unidad_medida' => $ing1->unidad_medida,
                            'merma' => $ing1->merma_porcentaje,
                        ],
                        'v2' => [
                            'cantidad' => $ing2->cantidad,
                            'unidad_medida' => $ing2->unidad_medida,
                            'merma' => $ing2->merma_porcentaje,
                        ],
                    ];
                }
            }
        }

        return [
            'version1' => [
                'id' => $v1->id,
                'version' => $v1->version,
                'descripcion_cambios' => $v1->descripcion_cambios,
                'fecha_efectiva' => $v1->fecha_efectiva,
                'publicada' => $v1->version_publicada,
                'total_ingredientes' => $ingredientes1->count(),
            ],
            'version2' => [
                'id' => $v2->id,
                'version' => $v2->version,
                'descripcion_cambios' => $v2->descripcion_cambios,
                'fecha_efectiva' => $v2->fecha_efectiva,
                'publicada' => $v2->version_publicada,
                'total_ingredientes' => $ingredientes2->count(),
            ],
            'diff' => $diff,
        ];
    }

    /**
     * Obtiene el historial de versiones de una receta
     * 
     * @param string $recetaId ID de la receta
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public function getVersionHistory(string $recetaId)
    {
        return RecetaVersion::where('receta_id', $recetaId)
            ->orderByDesc('version')
            ->with('detalles')
            ->get();
    }

    /**
     * Obtiene la versión publicada actual de una receta
     * 
     * @param string $recetaId ID de la receta
     * @return RecetaVersion|null
     */
    public function getPublishedVersion(string $recetaId): ?RecetaVersion
    {
        return RecetaVersion::where('receta_id', $recetaId)
            ->where('version_publicada', true)
            ->orderByDesc('version')
            ->with('detalles.item')
            ->first();
    }
}
