<?php

namespace App\Services\Replenishment;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;
use App\Models\ReplenishmentSuggestion;
use App\Models\Item;
use App\Models\StockPolicy;
use App\Services\Purchasing\PurchasingService;
use App\Services\Inventory\ProductionService;

class ReplenishmentService
{
    protected PurchasingService $purchasingService;
    protected ProductionService $productionService;

    public function __construct()
    {
        $this->purchasingService = new PurchasingService();
        $this->productionService = new ProductionService();
    }

    /**
     * Genera sugerencias diarias de reposición basadas en stock_policy
     *
     * @param array $options Opciones de generación
     *   - sucursal_id: Filtrar por sucursal específica
     *   - almacen_id: Filtrar por almacén específico
     *   - dias_analisis: Días hacia atrás para calcular consumo promedio (default: 7)
     *   - auto_aprobar: Auto-aprobar sugerencias urgentes (default: false)
     *   - dry_run: Simular sin guardar (default: false)
     * @return array Resumen de sugerencias generadas
     */
    public function generateDailySuggestions(array $options = []): array
    {
        $sucursalId = $options['sucursal_id'] ?? null;
        $almacenId = $options['almacen_id'] ?? null;
        $diasAnalisis = $options['dias_analisis'] ?? 7;
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
        $query = DB::connection('pgsql')
            ->table('stock_policy')
            ->where('activo', true);

        if ($sucursalId) {
            $query->where('sucursal_id', $sucursalId);
        }

        if ($almacenId) {
            $query->where('almacen_id', $almacenId);
        }

        $policies = $query->get();

        foreach ($policies as $policy) {
            try {
                // Consultar stock actual
                $stockActual = $this->obtenerStockActual(
                    $policy->item_id,
                    $policy->sucursal_id,
                    $policy->almacen_id
                );

                // Si el stock está por debajo del mínimo, generar sugerencia
                if ($stockActual < $policy->min_qty) {
                    $consumoPromedio = $this->calcularConsumoPromedio(
                        $policy->item_id,
                        $policy->sucursal_id,
                        $diasAnalisis
                    );

                    $diasRestantes = $consumoPromedio > 0
                        ? floor($stockActual / $consumoPromedio)
                        : 999;

                    $fechaAgotamiento = $consumoPromedio > 0
                        ? now()->addDays($diasRestantes)
                        : null;

                    // Determinar tipo (COMPRA vs PRODUCCION)
                    $item = Item::find($policy->item_id);
                    $tipo = $this->determinarTipo($item);

                    // Calcular cantidad sugerida
                    $qtySugerida = $policy->reorder_lote ?? ($policy->max_qty - $stockActual);

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
                        'almacen_id' => $policy->almacen_id,
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

                    if (!$dryRun) {
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

        if (!$suggestion->puede_aprobarse) {
            throw new InvalidArgumentException('Esta sugerencia no puede ser convertida.');
        }

        if ($suggestion->tipo !== ReplenishmentSuggestion::TIPO_COMPRA) {
            throw new InvalidArgumentException('Esta sugerencia no es de tipo COMPRA.');
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

        if (!$suggestion->puede_aprobarse) {
            throw new InvalidArgumentException('Esta sugerencia no puede ser convertida.');
        }

        if ($suggestion->tipo !== ReplenishmentSuggestion::TIPO_PRODUCCION) {
            throw new InvalidArgumentException('Esta sugerencia no es de tipo PRODUCCION.');
        }

        $item = $suggestion->item;

        // Obtener receta (simplificado, necesitará modelo Recipe completo)
        $recipeId = $overrides['recipe_id'] ?? $item->recipe_id ?? null;

        if (!$recipeId) {
            throw new InvalidArgumentException('El item no tiene receta asociada.');
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
        $query = DB::connection('pgsql')
            ->table('vw_stock_actual')
            ->where('item_id', $itemId);

        if ($sucursalId) {
            $query->where('sucursal_id', $sucursalId);
        }

        if ($almacenId) {
            $query->where('almacen_id', $almacenId);
        }

        $stock = $query->first();

        return $stock->stock_actual ?? 0;
    }

    /**
     * Calcula el consumo promedio diario basado en movimientos históricos
     */
    protected function calcularConsumoPromedio(string $itemId, ?int $sucursalId, int $dias = 7): float
    {
        $fechaInicio = now()->subDays($dias)->toDateString();

        $totalConsumo = (float) DB::connection('pgsql')
            ->table('mov_inv')
            ->where('item_id', $itemId)
            ->where('tipo', 'VENTA') // O tipos negativos: PROD_OUT, MERMA, etc.
            ->when($sucursalId, fn($q) => $q->where('sucursal_id', $sucursalId))
            ->whereDate('ts', '>=', $fechaInicio)
            ->sum('qty');

        return $totalConsumo / $dias;
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
            $motivo .= "⚠️ SIN STOCK. ";
        } elseif ($diasRestantes <= 1) {
            $motivo .= "⚠️ Stock se agotará en menos de 24 horas. ";
        } elseif ($diasRestantes <= 3) {
            $motivo .= "Stock se agotará en {$diasRestantes} días. ";
        } else {
            $motivo .= "Stock bajo mínimo requerido. ";
        }

        if ($consumoPromedio > 0) {
            $motivo .= "Consumo promedio: " . number_format($consumoPromedio, 2) . " unidades/día.";
        }

        return $motivo;
    }
}
