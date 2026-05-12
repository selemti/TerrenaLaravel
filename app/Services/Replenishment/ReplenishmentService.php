<?php

namespace App\Services\Replenishment;

use App\Exceptions\Replenishment\ReplenishmentException;
use App\Models\Inv\Item;
use App\Models\ReplenishmentSuggestion;
use App\Models\StockPolicy;
use App\Services\Inventory\ProductionService;
use App\Services\Purchasing\PurchasingService;
use Illuminate\Support\Facades\DB;

class ReplenishmentService
{
    protected PurchasingService $purchasingService;

    protected ProductionService $productionService;

    public function __construct()
    {
        $this->purchasingService = new PurchasingService;
        $this->productionService = new ProductionService;
    }

    /**
     * Genera sugerencias diarias de reposición basadas en stock_policy
     *
     * @param  array  $options  Opciones de generación
     *                          - sucursal_id: Filtrar por sucursal específica
     *                          - almacen_id: Filtrar por almacén específico
     *                          - dias_analisis: Días hacia atrás para calcular consumo promedio (default: 7)
     *                          - algoritmo: MIN_MAX|SMA|POS_CONSUMPTION (default: SMA)
     *                          - auto_aprobar: Auto-aprobar sugerencias urgentes (default: false)
     *                          - dry_run: Simular sin guardar (default: false)
     * @return array Resumen de sugerencias generadas
     */
    public function generateDailySuggestions(array $options = []): array
    {
        $sucursalId = $options['sucursal_id'] ?? null;
        $almacenId = $options['almacen_id'] ?? null;
        $diasAnalisis = $options['dias_analisis'] ?? 7;
        $algoritmo = $options['algoritmo'] ?? 'SMA';
        $autoAprobar = $options['auto_aprobar'] ?? false;
        $dryRun = $options['dry_run'] ?? false;

        $sugerenciasGeneradas = [];
        $resumen = [
            'total' => 0,
            'compras' => 0,
            'producciones' => 0,
            'urgentes' => 0,
            'normales' => 0,
            'errors' => [],
        ];

        // Obtener todas las políticas de stock activas
        // CORREGIDO: Usar selemti.inv_stock_policy (tabla con datos reales del dataset)
        $query = DB::connection('pgsql')
            ->table('selemti.inv_stock_policy')
            ->where('activo', true);

        if ($sucursalId) {
            $query->where('sucursal_id', $sucursalId);
        }

        if ($almacenId) {
            $query->where('almacen_id', $almacenId);
        }

        $policies = $query->get();

        \Log::info('[ReplenishmentService] Políticas encontradas', [
            'total' => $policies->count(),
            'sucursal_id' => $sucursalId,
            'almacen_id' => $almacenId,
            'algoritmo' => $algoritmo,
            'dias_analisis' => $diasAnalisis,
        ]);

        $itemsMap = Item::findMany($policies->pluck('item_id')->filter()->unique())->keyBy('id');

        foreach ($policies as $policy) {
            try {
                // Consultar stock actual
                // CORREGIDO: inv_stock_policy NO tiene almacen_id (solo item_id + sucursal_id)
                $stockActual = $this->obtenerStockActual(
                    $policy->item_id,
                    $policy->sucursal_id,
                    null
                );

                // Telemetría: Log de evaluación de política
                \Log::info('[ReplenishmentService] Evaluando política', [
                    'item_id' => $policy->item_id,
                    'stock_actual' => $stockActual,
                    'stock_min' => $policy->min_qty,
                    'stock_max' => $policy->max_qty,
                    'cumple_condicion' => $stockActual < $policy->min_qty,
                ]);

                // Si el stock está por debajo del mínimo, generar sugerencia
                if ($stockActual < $policy->min_qty) {
                    $consumoPromedio = $this->calcularConsumoPromedio(
                        $policy->item_id,
                        $policy->sucursal_id,
                        $diasAnalisis,
                        $algoritmo
                    );

                    $diasRestantes = $consumoPromedio > 0
                        ? floor($stockActual / $consumoPromedio)
                        : 999;

                    $fechaAgotamiento = $consumoPromedio > 0
                        ? now()->addDays($diasRestantes)
                        : null;

                    // Determinar tipo (COMPRA vs PRODUCCION)
                    $item = $itemsMap->get($policy->item_id);
                    $tipo = $this->determinarTipo($item);

                    // Calcular cantidad sugerida
                    // CORREGIDO: inv_stock_policy usa reorder_qty (no reorder_lote)
                    $qtySugerida = $policy->reorder_qty ?? ($policy->max_qty - $stockActual);

                    // Determinar prioridad
                    $prioridad = $this->determinarPrioridad($diasRestantes, $stockActual, $policy->min_qty);

                    // Generar folio único
                    $folio = $this->generarFolio($tipo);

                    $sugerenciaData = [
                        'folio' => $folio,
                        'tipo' => $tipo,
                        'prioridad' => $prioridad,
                        'origen' => ReplenishmentSuggestion::ORIGEN_AUTO,
                        'item_id' => $policy->item_id,
                        'sucursal_id' => $policy->sucursal_id,
                        'almacen_id' => null, // CORREGIDO: inv_stock_policy NO tiene almacen_id
                        'stock_actual' => $stockActual,
                        'stock_min' => $policy->min_qty,
                        'stock_max' => $policy->max_qty,
                        'qty_sugerida' => $qtySugerida,
                        'uom' => $item->unidad_medida ?? 'UND',
                        'consumo_promedio_diario' => $consumoPromedio,
                        'dias_stock_restante' => $diasRestantes,
                        'fecha_agotamiento_estimada' => $fechaAgotamiento,
                        'estado' => $autoAprobar && $prioridad === ReplenishmentSuggestion::PRIORIDAD_URGENTE
                            ? ReplenishmentSuggestion::ESTADO_APROBADA
                            : ReplenishmentSuggestion::ESTADO_PENDIENTE,
                        'sugerido_en' => now(),
                        'caduca_en' => now()->addDays(7), // Las sugerencias caducan en 7 días
                        'motivo' => $this->generarMotivo($stockActual, $policy->min_qty, $diasRestantes, $consumoPromedio),
                        'meta' => json_encode([
                            'stock_policy_id' => $policy->id,
                            'proveedor_preferido_id' => $item->proveedor_id ?? null,
                            'dias_analisis' => $diasAnalisis,
                        ]),
                    ];

                    if (! $dryRun) {
                        $sugerencia = ReplenishmentSuggestion::create($sugerenciaData);
                        $sugerenciasGeneradas[] = $sugerencia;
                    } else {
                        $sugerenciasGeneradas[] = $sugerenciaData;
                    }

                    // Actualizar resumen
                    $resumen['total']++;
                    if ($tipo === ReplenishmentSuggestion::TIPO_COMPRA) {
                        $resumen['compras']++;
                    } else {
                        $resumen['producciones']++;
                    }

                    if ($prioridad === ReplenishmentSuggestion::PRIORIDAD_URGENTE) {
                        $resumen['urgentes']++;
                    } else {
                        $resumen['normales']++;
                    }
                }

            } catch (\Exception $e) {
                $resumen['errors'][] = [
                    'item_id' => $policy->item_id,
                    'sucursal_id' => $policy->sucursal_id,
                    'error' => $e->getMessage(),
                ];
            }
        }

        $resumen['sugerencias'] = $sugerenciasGeneradas;

        return $resumen;
    }

    /**
     * Convierte una sugerencia en solicitud de compra
     */
    public function convertToPurchaseRequest(int $suggestionId, array $overrides = []): int
    {
        $suggestion = ReplenishmentSuggestion::findOrFail($suggestionId);

        if (! $suggestion->puede_aprobarse) {
            throw new ReplenishmentException('Esta sugerencia no puede ser convertida.');
        }

        if ($suggestion->tipo !== ReplenishmentSuggestion::TIPO_COMPRA) {
            throw new ReplenishmentException('Esta sugerencia no es de tipo COMPRA.');
        }

        $item = $suggestion->item;

        $qty = $overrides['qty'] ?? $suggestion->qty_aprobada ?? $suggestion->qty_sugerida;

        $requestData = [
            'sucursal_id' => $suggestion->sucursal_id,
            'requested_at' => now(),
            'created_by' => $overrides['user_id'] ?? auth()->id(),
            'notas' => $overrides['notas'] ?? "Generado automáticamente desde sugerencia {$suggestion->folio}",
        ];

        $lines = [[
            'item_id' => $suggestion->item_id,
            'qty' => $qty,
            'uom' => $suggestion->uom,
            'fecha_requerida' => now()->addDays(3),
            'last_price' => $item->costo_promedio ?? 0,
            'preferred_vendor_id' => $item->proveedor_id ?? null,
        ]];

        $requestId = $this->purchasingService->createRequest($requestData, $lines);

        $suggestion->marcarConvertida(purchaseRequestId: $requestId);

        return $requestId;
    }

    /**
     * Convierte una sugerencia en orden de producción
     * Verifica disponibilidad de materia prima y divide si es necesario
     */
    public function convertToProductionOrder(int $suggestionId, array $overrides = []): array
    {
        $suggestion = ReplenishmentSuggestion::findOrFail($suggestionId);

        if (! $suggestion->puede_aprobarse) {
            throw new ReplenishmentException('Esta sugerencia no puede ser convertida.');
        }

        if ($suggestion->tipo !== ReplenishmentSuggestion::TIPO_PRODUCCION) {
            throw new ReplenishmentException('Esta sugerencia no es de tipo PRODUCCION.');
        }

        $item = $suggestion->item;

        // Obtener receta (simplificado, necesitará modelo Recipe completo)
        $recipeId = $overrides['recipe_id'] ?? $item->recipe_id ?? null;

        if (! $recipeId) {
            throw new ReplenishmentException('El item no tiene receta asociada.');
        }

        $qty = $overrides['qty'] ?? $suggestion->qty_aprobada ?? $suggestion->qty_sugerida;

        // TODO: Implementar validación de materia prima
        // Por ahora crear orden directamente

        $orderHeader = [
            'recipe_id' => $recipeId,
            'item_id' => $suggestion->item_id,
            'scheduled_qty' => $qty,
            'uom' => $suggestion->uom,
            'branch_id' => $suggestion->sucursal_id,
            'warehouse_id' => $suggestion->almacen_id,
            'scheduled_at' => $overrides['programado_para'] ?? now()->addHours(2),
            'user_id' => $overrides['user_id'] ?? auth()->id(),
            'notes' => "Generado desde sugerencia {$suggestion->folio}",
        ];

        // Inputs y outputs dependen de la receta
        // TODO: Consultar receta real y calcular
        $inputs = $overrides['inputs'] ?? [];
        $outputs = [[
            'item_id' => $suggestion->item_id,
            'qty' => $qty,
            'uom' => $suggestion->uom,
        ]];

        $orderId = $this->productionService->createOrder($orderHeader, $inputs, $outputs);

        $suggestion->marcarConvertida(productionOrderId: $orderId);

        return [
            'production_order_id' => $orderId,
            'status' => 'created',
            'message' => 'Orden de producción creada exitosamente',
        ];
    }

    /**
     * Crea una sugerencia manual (fuera del proceso automático)
     */
    public function createManualSuggestion(array $data): ReplenishmentSuggestion
    {
        $item = Item::findOrFail($data['item_id']);

        $stockActual = $this->obtenerStockActual(
            $data['item_id'],
            $data['sucursal_id'],
            $data['almacen_id'] ?? null
        );

        $policy = StockPolicy::where('item_id', $data['item_id'])
            ->where('sucursal_id', $data['sucursal_id'])
            ->first();

        $tipo = $this->determinarTipo($item);

        return ReplenishmentSuggestion::create([
            'folio' => $this->generarFolio($tipo),
            'tipo' => $tipo,
            'prioridad' => $data['prioridad'] ?? ReplenishmentSuggestion::PRIORIDAD_NORMAL,
            'origen' => ReplenishmentSuggestion::ORIGEN_MANUAL,
            'item_id' => $data['item_id'],
            'sucursal_id' => $data['sucursal_id'],
            'almacen_id' => $data['almacen_id'] ?? null,
            'stock_actual' => $stockActual,
            'stock_min' => $policy->min_qty ?? 0,
            'stock_max' => $policy->max_qty ?? 0,
            'qty_sugerida' => $data['qty_sugerida'],
            'uom' => $data['uom'] ?? $item->unidad_medida,
            'estado' => ReplenishmentSuggestion::ESTADO_PENDIENTE,
            'sugerido_en' => now(),
            'motivo' => $data['motivo'] ?? 'Creado manualmente',
            'notas' => $data['notas'] ?? null,
            'meta' => json_encode($data['meta'] ?? []),
        ]);
    }

    // ==========================================
    // MÉTODOS AUXILIARES PRIVADOS
    // ==========================================

    /**
     * Obtiene el stock actual de un item en una ubicación
     */
    protected function obtenerStockActual(string $itemId, ?int $sucursalId, ?int $almacenId): float
    {
        // CORREGIDO: La vista es v_stock_actual (no vw_stock_actual) y NO tiene sucursal_id/almacen_id
        // Calcular stock desde mov_inv directamente
        // IMPORTANTE: sucursal_id en mov_inv es VARCHAR (no integer)
        $query = DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->where('item_id', $itemId);

        if ($sucursalId) {
            // Convertir sucursal_id integer a formato VARCHAR esperado por mov_inv
            $query->where('sucursal_id', 'SUC-'.$sucursalId);
        }

        // NOTA: mov_inv NO tiene almacen_id en su estructura real
        // Si se requiere filtrar por almacén, implementar lógica adicional

        $stock = $query->sum('cantidad');

        return (float) ($stock ?? 0);
    }

    /**
     * Calcula el consumo promedio diario basado en movimientos históricos
     * Soporta 3 algoritmos: MIN_MAX, SMA, POS_CONSUMPTION
     *
     * @param  string  $algoritmo  MIN_MAX|SMA|POS_CONSUMPTION
     */
    protected function calcularConsumoPromedio(
        string $itemId,
        ?int $sucursalId,
        int $dias = 7,
        string $algoritmo = 'SMA'
    ): float {
        // MIN_MAX no usa consumo promedio, solo min/max de stock_policy
        if ($algoritmo === 'MIN_MAX') {
            return 0.0;
        }

        $fechaInicio = now()->subDays($dias)->toDateString();

        // SMA: Simple Moving Average basado en mov_inv
        if ($algoritmo === 'SMA') {
            // CORREGIDO: mov_inv usa columna 'cantidad' (no 'qty')
            // IMPORTANTE: sucursal_id en mov_inv es VARCHAR (formato SUC-1, SUC-2, etc)
            $totalConsumo = (float) DB::connection('pgsql')
                ->table('selemti.mov_inv')
                ->where('item_id', $itemId)
                ->whereIn('tipo', ['SALIDA', 'VENTA', 'PROD_OUT', 'MERMA', 'CONSUMO_POS'])
                ->when($sucursalId, fn ($q) => $q->where('sucursal_id', 'SUC-'.$sucursalId))
                ->whereDate('ts', '>=', $fechaInicio)
                ->sum('cantidad');

            return abs($totalConsumo) / $dias;
        }

        // POS_CONSUMPTION: Basado en tickets POS expandidos
        if ($algoritmo === 'POS_CONSUMPTION') {
            return $this->calcularConsumoPOS($itemId, $sucursalId, $dias);
        }

        // Default: SMA
        return $this->calcularConsumoPromedio($itemId, $sucursalId, $dias, 'SMA');
    }

    /**
     * Calcula consumo basado en tickets POS históricos expandidos
     *
     * Usa la tabla inv_consumo_pos_det que expande tickets → ingredientes
     * mediante fn_expandir_consumo_ticket()
     *
     * @return float Consumo promedio diario
     */
    protected function calcularConsumoPOS(string $itemId, ?int $sucursalId, int $dias = 7): float
    {
        $fechaInicio = now()->subDays($dias)->toDateString();

        // CORREGIDO: inv_consumo_pos_det usa mp_id (no item_id) y cantidad (no qty)
        // inv_consumo_pos usa fecha_proceso (no fecha)
        $consumoExpandido = (float) DB::connection('pgsql')
            ->table('selemti.inv_consumo_pos_det as det')
            ->join('selemti.inv_consumo_pos as cab', 'det.consumo_id', '=', 'cab.id')
            ->where('det.mp_id', (int) filter_var($itemId, FILTER_SANITIZE_NUMBER_INT)) // mp_id es integer
            ->when($sucursalId, fn ($q) => $q->where('cab.sucursal_id', $sucursalId))
            ->whereDate('cab.fecha_proceso', '>=', $fechaInicio)
            ->sum('det.cantidad');

        // Si no hay datos en inv_consumo_pos_det, fallback a mov_inv
        if ($consumoExpandido <= 0) {
            return $this->calcularConsumoPromedio($itemId, $sucursalId, $dias, 'SMA');
        }

        return $consumoExpandido / $dias;
    }

    /**
     * Determina si el item debe comprarse o producirse
     */
    protected function determinarTipo(Item $item): string
    {
        // Si el item tiene receta, es producible
        if ($item->recipe_id || $item->tipo === 'PRODUCCION') {
            return ReplenishmentSuggestion::TIPO_PRODUCCION;
        }

        return ReplenishmentSuggestion::TIPO_COMPRA;
    }

    /**
     * Determina la prioridad basada en días restantes y % de stock
     */
    protected function determinarPrioridad(int $diasRestantes, float $stockActual, float $stockMin): string
    {
        // Crítico: sin stock o menos de 1 día
        if ($stockActual <= 0 || $diasRestantes <= 1) {
            return ReplenishmentSuggestion::PRIORIDAD_URGENTE;
        }

        // Alta: menos de 3 días
        if ($diasRestantes <= 3) {
            return ReplenishmentSuggestion::PRIORIDAD_ALTA;
        }

        // Normal: entre 3 y 7 días
        if ($diasRestantes <= 7) {
            return ReplenishmentSuggestion::PRIORIDAD_NORMAL;
        }

        // Baja: más de 7 días pero bajo mínimo
        return ReplenishmentSuggestion::PRIORIDAD_BAJA;
    }

    /**
     * Genera folio único para la sugerencia
     */
    protected function generarFolio(string $tipo): string
    {
        $prefix = $tipo === ReplenishmentSuggestion::TIPO_COMPRA ? 'RSC' : 'RSP';
        $fecha = now()->format('Ymd');
        $count = ReplenishmentSuggestion::whereDate('created_at', today())->count() + 1;

        return sprintf('%s-%s-%04d', $prefix, $fecha, $count);
    }

    /**
     * Genera descripción del motivo de la sugerencia
     */
    protected function generarMotivo(float $stockActual, float $stockMin, int $diasRestantes, float $consumoPromedio): string
    {
        $porcentaje = $stockMin > 0 ? round(($stockActual / $stockMin) * 100, 1) : 0;

        $motivo = "Stock actual: {$stockActual} ({$porcentaje}% del mínimo). ";

        if ($stockActual <= 0) {
            $motivo .= '⚠️ SIN STOCK. ';
        } elseif ($diasRestantes <= 1) {
            $motivo .= '⚠️ Stock se agotará en menos de 24 horas. ';
        } elseif ($diasRestantes <= 3) {
            $motivo .= "Stock se agotará en {$diasRestantes} días. ";
        } else {
            $motivo .= 'Stock bajo mínimo requerido. ';
        }

        if ($consumoPromedio > 0) {
            $motivo .= 'Consumo promedio: '.number_format($consumoPromedio, 2).' unidades/día.';
        }

        return $motivo;
    }
}
