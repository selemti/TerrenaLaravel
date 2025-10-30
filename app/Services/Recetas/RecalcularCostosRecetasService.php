<?php

namespace App\Services\Recetas;

use App\Models\Inv\Item;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaDetalle;
use App\Models\Rec\RecetaVersion;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class RecalcularCostosRecetasService
{
    /**
     * Recalcula el costo unitario de recetas publicadas y subrecetas cuyo insumo 
     * cambió de precio el día anterior, y propaga el costo a padres.
     * 
     * @param int|null $branchId ID de la sucursal
     * @param string|null $date Fecha objetivo (por defecto ayer)
     * @return array Resultado de la operación
     */
    public function recalcularCostos(?int $branchId = null, ?string $date = null): array
    {
        // Si no se proporciona fecha, usar ayer
        if (!$date) {
            $date = now()->subDay()->format('Y-m-d');
        }

        // Crear lock para idempotencia
        $lockKey = "cost:lock:{$date}";
        if (Redis::exists($lockKey)) {
            return [
                'success' => false,
                'message' => "Proceso ya en ejecución para la fecha {$date}",
                'date' => $date
            ];
        }
        
        // Establecer lock con TTL de 6 horas
        Redis::setex($lockKey, 6 * 60 * 60, 1);

        try {
            // 1. Detectar insumos con cambio de costo (WAC/último) con valid_from = date
            $insumosConCambioCosto = $this->detectarInsumosConCambioCosto($date, $branchId);

            if (empty($insumosConCambioCosto)) {
                return [
                    'success' => true,
                    'message' => "No se encontraron insumos con cambio de costo para la fecha {$date}",
                    'date' => $date,
                    'affected_items' => 0
                ];
            }

            // 2. Recalcular subrecetas afectadas (versión publicada vigente a la fecha)
            $subrecetasAfectadas = $this->recalcularSubrecetasAfectadas($insumosConCambioCosto, $date);

            // 3. Recalcular recetas que referencian esas subrecetas/insumos
            $recetasAfectadas = $this->recalcularRecetasAfectadas($insumosConCambioCosto, $subrecetasAfectadas, $date);

            // 4. Opcional: generar alertas para recetas con margen negativo
            $alertas = $this->generarAlertasMargenNegativo($recetasAfectadas, $date);

            return [
                'success' => true,
                'date' => $date,
                'affected_items' => count($insumosConCambioCosto),
                'affected_subrecetas' => count($subrecetasAfectadas),
                'affected_recetas' => count($recetasAfectadas),
                'alerts_generated' => count($alertas),
                'message' => "Recálculo de costos completado para {$date}"
            ];
        } finally {
            // Eliminar el lock al finalizar
            Redis::del($lockKey);
        }
    }

    /**
     * Detecta insumos con cambio de costo (WAC/último) con valid_from = date
     */
    private function detectarInsumosConCambioCosto(string $date, ?int $branchId = null): array
    {
        // Primero verificar si existe la tabla item_cost_history
        $schema = DB::connection('pgsql')->getSchemaBuilder();
        $hasItemCostHistory = $schema->hasTable('selemti.item_cost_history');
        
        if ($hasItemCostHistory) {
            // Usar la tabla item_cost_history si existe
            $itemsConCambio = DB::connection('pgsql')
                ->table('selemti.item_cost_history')
                ->whereDate('fecha_efectiva', $date)
                ->select('item_id', 'costo', 'tipo_cambio')
                ->get()
                ->pluck('costo', 'item_id')
                ->toArray();
        } else {
            // Si no existe item_cost_history, calcular WAC con recepciones del día
            $itemsConCambio = $this->calcularWACDesdeRecepciones($date, $branchId);
        }

        // Obtener los items que tuvieron cambios en la fecha objetivo
        $itemIds = array_keys($itemsConCambio);
        if (empty($itemIds)) {
            return [];
        }
        
        $items = Item::whereIn('id', $itemIds)->get();

        // Actualizar el costo promedio de los items que cambiaron
        foreach ($items as $item) {
            if (isset($itemsConCambio[$item->id])) {
                $item->costo_promedio = $itemsConCambio[$item->id];
            }
        }

        return $items->values()->toArray();
    }
    
    /**
     * Calcula el costo WAC (Weighted Average Cost) desde recepciones del día
     */
    private function calcularWACDesdeRecepciones(string $date, ?int $branchId = null): array
    {
        // Este método calcularía el costo promedio ponderado basado en las recepciones del día
        // Suponiendo que hay tablas como inv_recepcion_det o similar que contienen
        // información de costos de recepciones
        
        $wacCosts = [];
        
        // Consulta hipotética para obtener datos de recepciones del día
        // que actualizarían el costo promedio de los items
        $recepciones = DB::connection('pgsql')
            ->table('selemti.inv_recepcion_det as rd')
            ->join('selemti.inv_recepcion_cab as rc', 'rd.recepcion_id', '=', 'rc.id')
            ->whereDate('rc.fecha_recepcion', $date)
            ->select(
                'rd.item_id',
                DB::raw('SUM(rd.cantidad * rd.costo_unitario) / SUM(rd.cantidad) as wac_costo')
            )
            ->groupBy('rd.item_id')
            ->get();
        
        foreach ($recepciones as $recepcion) {
            $wacCosts[$recepcion->item_id] = (float) $recepcion->wac_costo;
        }
        
        return $wacCosts;
    }

    /**
     * Recalcula subrecetas afectadas (versión publicada vigente a la fecha)
     */
    private function recalcularSubrecetasAfectadas(array $insumosConCambioCosto, string $date): array
    {
        $idsInsumos = collect($insumosConCambioCosto)->pluck('id')->toArray();
        
        // Encontrar versiones publicadas de recetas que usan los insumos afectados
        // y que estén vigentes a la fecha objetivo
        $recetasVersiones = RecetaVersion::whereHas('detalles', function ($query) use ($idsInsumos) {
                $query->whereIn('item_id', $idsInsumos);
            })
            ->where('version_publicada', true)
            ->where('fecha_efectiva', '<=', $date) // Vigente a la fecha
            ->with(['detalles.item'])
            ->get();

        $subrecetasAfectadas = [];

        foreach ($recetasVersiones as $version) {
            // Recalcular el costo de la receta basado en los nuevos costos de insumos
            $costoRecalculado = $this->calcularCostoReceta($version);

            // Solo actualizar si el costo ha cambiado
            if ($version->receta->costo_standard_porcion != $costoRecalculado) {
                // Guardar el valor anterior para el registro de cambios
                $costoAnterior = $version->receta->costo_standard_porcion;

                // Actualizar el costo de la receta
                $version->receta->costo_standard_porcion = $costoRecalculado;
                $version->receta->save();

                $subrecetasAfectadas[] = [
                    'receta_id' => $version->receta->id,
                    'version_id' => $version->id,
                    'costo_anterior' => $costoAnterior,
                    'nuevo_costo' => $costoRecalculado
                ];

                // Registrar el historial de costos
                $this->registrarHistorialCosto($version->receta->id, $costoRecalculado, $date, $costoAnterior);
            }
        }

        return $subrecetasAfectadas;
    }

    /**
     * Recalcula recetas que referencian subrecetas/insumos afectados
     */
    private function recalcularRecetasAfectadas(array $insumosConCambioCosto, array $subrecetasAfectadas, string $date): array
    {
        // Extraer IDs de subrecetas afectadas
        $idsSubrecetasAfectadas = collect($subrecetasAfectadas)->pluck('receta_id')->toArray();
        $idsInsumosAfectados = collect($insumosConCambioCosto)->pluck('id')->toArray();
        
        // Combinar IDs de insumos y subrecetas afectadas
        $idsElementosAfectados = array_merge($idsInsumosAfectados, $idsSubrecetasAfectadas);
        
        // Encontrar recetas que usan los elementos afectados
        $recetasAfectadas = [];

        // Este es un proceso recursivo, necesitamos propagar los cambios hacia arriba
        $recetasParaRecalcular = $this->encontrarRecetasQueUsanElementos($idsElementosAfectados, $date);
        
        $procesados = [];
        $iteracion = 0;
        $maxIteraciones = 10; // Prevenir bucles infinitos en jerarquías complejas
        
        while (!empty($recetasParaRecalcular) && $iteracion < $maxIteraciones) {
            $nuevasRecetas = [];
            
            foreach ($recetasParaRecalcular as $recetaId) {
                if (in_array($recetaId, $procesados)) continue;
                
                $receta = Receta::find($recetaId);
                if (!$receta) continue;
                
                $versionPublicada = $receta->publishedVersion()->where('fecha_efectiva', '<=', $date)->first();
                if (!$versionPublicada) continue;
                
                $costoRecalculado = $this->calcularCostoReceta($versionPublicada);
                
                // Solo actualizar si el costo ha cambiado
                if ($receta->costo_standard_porcion != $costoRecalculado) {
                    $costoAnterior = $receta->costo_standard_porcion;
                    
                    $receta->costo_standard_porcion = $costoRecalculado;
                    $receta->save();
                    
                    $recetasAfectadas[] = [
                        'receta_id' => $receta->id,
                        'costo_anterior' => $costoAnterior,
                        'nuevo_costo' => $costoRecalculado
                    ];

                    // Registrar el historial de costos
                    $this->registrarHistorialCosto($receta->id, $costoRecalculado, $date, $costoAnterior);
                    
                    // Verificar si esta receta actualizada afecta a otras recetas superiores
                    $recetasPadre = $this->encontrarRecetasQueUsanReceta($receta->id, $date);
                    $nuevasRecetas = array_merge($nuevasRecetas, $recetasPadre);
                }
                
                $procesados[] = $recetaId;
            }
            
            $recetasParaRecalcular = $nuevasRecetas;
            $iteracion++;
        }

        return $recetasAfectadas;
    }

    /**
     * Calcula el costo de una receta basado en sus detalles
     */
    private function calcularCostoReceta(RecetaVersion $version): float
    {
        $costoTotal = 0;

        foreach ($version->detalles as $detalle) {
            $item = $detalle->item;
            if (!$item) continue;

            // Calcular costo del item considerando merma
            $costoUnitario = $item->costo_promedio ?? 0;
            $factorMerma = 1 + ($detalle->merma_porcentaje / 100);
            $costoConMerma = $costoUnitario * $factorMerma;
            
            $costoTotal += $detalle->cantidad * $costoConMerma;
        }

        // Dividir por el número de porciones para obtener costo por porción
        $receta = $version->receta;
        $porciones = $receta->porciones_standard ?? 1;
        
        return $porciones > 0 ? $costoTotal / $porciones : 0;
    }

    /**
     * Encuentra recetas que usan los elementos especificados
     */
    private function encontrarRecetasQueUsanElementos(array $itemIds, string $date): array
    {
        return RecetaDetalle::whereIn('item_id', $itemIds)
            ->join('receta_version', 'receta_det.receta_version_id', '=', 'receta_version.id')
            ->where('receta_version.version_publicada', true)
            ->where('receta_version.fecha_efectiva', '<=', $date)
            ->pluck('receta_version.receta_id')
            ->unique()
            ->toArray();
    }

    /**
     * Encuentra recetas que usan una receta específica como ingrediente
     */
    private function encontrarRecetasQueUsanReceta(string $recetaId, string $date): array
    {
        // En este sistema, las recetas pueden usarse como ingredientes en otras recetas
        // Asumiendo que los items pueden representar recetas (posiblemente con un tipo especial)
        // y que hay una forma de identificarlas
        
        // Para este caso, asumiremos que una receta puede ser usada como item en otra receta
        // y se identifica por tener un ID que coincide con una receta
        return RecetaDetalle::where('item_id', $recetaId)
            ->join('receta_version', 'receta_det.receta_version_id', '=', 'receta_version.id')
            ->where('receta_version.version_publicada', true)
            ->where('receta_version.fecha_efectiva', '<=', $date)
            ->pluck('receta_version.receta_id')
            ->unique()
            ->toArray();
    }

    /**
     * Registra el historial de costos para una receta
     */
    private function registrarHistorialCosto(string $recetaId, float $costo, string $date, ?float $costoAnterior = null): void
    {
        // Verificar si existe la tabla recipe_cost_history o recipe_extended_cost_history
        $schema = DB::connection('pgsql')->getSchemaBuilder();
        $hasRecipeCostHistory = $schema->hasTable('selemti.recipe_cost_history');
        $hasExtendedCostHistory = $schema->hasTable('selemti.recipe_extended_cost_history');
        
        $data = [
            'receta_id' => $recetaId,
            'costo_unitario' => $costo,
            'fecha_registro' => now(),
            'fecha_efectiva' => $date,
            'costo_anterior' => $costoAnterior,
            'tipo_cambio' => 'AUTOMATICO_RECALCULO',
            'created_at' => now(),
        ];
        
        if ($hasRecipeCostHistory) {
            // Usar la tabla recipe_cost_history si existe
            DB::connection('pgsql')->table('selemti.recipe_cost_history')->insert($data);
        } elseif ($hasExtendedCostHistory) {
            // Usar la tabla recipe_extended_cost_history si recipe_cost_history no existe
            DB::connection('pgsql')->table('selemti.recipe_extended_cost_history')->insert($data);
        }
        // Si no existen ninguna de las tablas, simplemente no registramos el historial
        // ya que no debemos crear nuevas tablas ni columnas
    }

    /**
     * Genera alertas para recetas con margen negativo
     */
    private function generarAlertasMargenNegativo(array $recetasAfectadas, string $date): array
    {
        $alertas = [];
        
        foreach ($recetasAfectadas as $recetaData) {
            $receta = Receta::find($recetaData['receta_id']);
            if (!$receta) continue;
            
            // Calcular margen (esto depende de la lógica de negocio específica)
            $precioVenta = $receta->precio_venta_sugerido ?? 0;
            $costo = $recetaData['nuevo_costo'];
            
            // Calcular porcentaje de margen
            $margen = $precioVenta - $costo;
            $porcentajeMargen = $precioVenta > 0 ? ($margen / $precioVenta) * 100 : 0;
            
            // Verificar si existe la tabla de alertas
            $schema = DB::connection('pgsql')->getSchemaBuilder();
            $hasAlertasTable = $schema->hasTable('selemti.alertas_costos');
            
            // Generar alerta si el margen es negativo o muy bajo (menos del 5% por ejemplo)
            if ($precioVenta > 0 && $margen < 0) {
                $alertaData = [
                    'receta_id' => $recetaData['receta_id'],
                    'nombre' => $receta->nombre_plato,
                    'costo' => $costo,
                    'precio_venta' => $precioVenta,
                    'margen' => $margen,
                    'porcentaje_margen' => $porcentajeMargen,
                    'fecha' => $date,
                    'tipo' => 'MARGEN_NEGATIVO',
                    'nivel' => 'ALTO'
                ];
                
                if ($hasAlertasTable) {
                    // Registrar alerta en tabla de alertas si existe
                    DB::connection('pgsql')->table('selemti.alertas_costos')->insert([
                        'receta_id' => $recetaData['receta_id'],
                        'tipo_alerta' => 'MARGEN_NEGATIVO',
                        'descripcion' => "La receta '{$receta->nombre_plato}' tiene margen negativo: \${$costo} de costo vs \${$precioVenta} de precio venta",
                        'nivel' => 'ALTO',
                        'fecha_alerta' => $date,
                        'datos' => [
                            'costo' => $costo,
                            'precio_venta' => $precioVenta,
                            'margen' => $margen,
                            'porcentaje_margen' => $porcentajeMargen,
                            'costo_anterior' => $recetaData['costo_anterior'] ?? null
                        ],
                        'resuelto' => false,
                        'created_at' => now(),
                    ]);
                } else {
                    // Registrar alerta en log si no existe tabla de alertas
                    \Log::warning('MARGEN_NEGATIVO', $alertaData);
                }
                
                $alertas[] = $alertaData;
            } elseif ($precioVenta > 0 && $porcentajeMargen < 5) {
                // También alertar si el margen es positivo pero muy bajo
                $alertaData = [
                    'receta_id' => $recetaData['receta_id'],
                    'nombre' => $receta->nombre_plato,
                    'costo' => $costo,
                    'precio_venta' => $precioVenta,
                    'margen' => $margen,
                    'porcentaje_margen' => $porcentajeMargen,
                    'fecha' => $date,
                    'tipo' => 'MARGEN_BAJO',
                    'nivel' => 'MEDIO'
                ];
                
                if ($hasAlertasTable) {
                    // Registrar alerta en tabla de alertas si existe
                    DB::connection('pgsql')->table('selemti.alertas_costos')->insert([
                        'receta_id' => $recetaData['receta_id'],
                        'tipo_alerta' => 'MARGEN_BAJO',
                        'descripcion' => "La receta '{$receta->nombre_plato}' tiene margen muy bajo: {$porcentajeMargen}%",
                        'nivel' => 'MEDIO',
                        'fecha_alerta' => $date,
                        'datos' => [
                            'costo' => $costo,
                            'precio_venta' => $precioVenta,
                            'margen' => $margen,
                            'porcentaje_margen' => $porcentajeMargen,
                            'costo_anterior' => $recetaData['costo_anterior'] ?? null
                        ],
                        'resuelto' => false,
                        'created_at' => now(),
                    ]);
                } else {
                    // Registrar alerta en log si no existe tabla de alertas
                    \Log::warning('MARGEN_BAJO', $alertaData);
                }
                
                $alertas[] = $alertaData;
            }
        }
        
        return $alertas;
    }
}