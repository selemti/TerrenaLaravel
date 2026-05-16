<?php

namespace App\Services\Production;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;

class ProductionOrderReadService
{
    private const ESTADO_LABELS = [
        'BORRADOR' => 'Borrador',
        'EN_PROCESO' => 'En proceso',
        'COMPLETADO' => 'Completado',
        'POSTEADO' => 'Posteado',
        'CANCELADO' => 'Cancelado',
    ];

    public function list(array $filters): array
    {
        $perPage = min(max((int) ($filters['per_page'] ?? 25), 1), 100);
        $page = max((int) ($filters['page'] ?? 1), 1);

        $query = $this->baseOrderQuery()
            ->when($filters['estado'] ?? null, fn ($query, $estado) => $query->where('po.estado', $estado))
            ->when($filters['sucursal_id'] ?? null, fn ($query, $sucursalId) => $query->where('po.sucursal_id', $sucursalId))
            ->when($filters['from'] ?? null, fn ($query, $from) => $query->where('po.programado_para', '>=', Carbon::createFromFormat('Y-m-d', $from)->startOfDay()))
            ->when($filters['to'] ?? null, fn ($query, $to) => $query->where('po.programado_para', '<=', Carbon::createFromFormat('Y-m-d', $to)->endOfDay()))
            ->when($filters['recipe_id'] ?? null, fn ($query, $recipeId) => $query->whereRaw('po.recipe_id::text = ?', [(string) $recipeId]));

        $total = (clone $query)->count('po.id');
        $rows = $query
            ->orderByDesc('po.programado_para')
            ->orderByDesc('po.id')
            ->forPage($page, $perPage)
            ->get();

        return [
            'orders' => $rows->map(fn ($row) => $this->formatListRow($row))->all(),
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => (int) max(1, ceil($total / $perPage)),
            ],
        ];
    }

    public function detail(int $orderId): array
    {
        $order = $this->baseOrderQuery()
            ->where('po.id', $orderId)
            ->first();

        if (! $order) {
            throw (new ModelNotFoundException)->setModel('selemti.production_orders', [$orderId]);
        }

        return [
            ...$this->formatListRow($order),
            'recipe' => $this->formatRecipe($order, true),
            'uom_base' => $order->uom_base,
            'sucursal_id' => $order->sucursal_id,
            'almacen' => $order->almacen_id === null ? null : [
                'id' => (string) $order->almacen_id,
                'clave' => $order->almacen_clave,
                'nombre' => $order->almacen_nombre,
            ],
            'notas' => $order->notas,
            'aprobado_por' => $order->aprobado_por_nombre,
            'inputs' => $this->inputs($orderId),
            'outputs' => $this->outputs($orderId),
            'updated_at' => $this->iso($order->updated_at),
        ];
    }

    private function baseOrderQuery()
    {
        return DB::connection('pgsql')
            ->table('selemti.production_orders as po')
            ->leftJoin('selemti.receta_cab as rc', DB::raw('rc.id::text'), '=', DB::raw('po.recipe_id::text'))
            ->leftJoin('selemti.items as i', DB::raw('i.id::text'), '=', DB::raw('po.item_id::text'))
            ->leftJoin('selemti.cat_almacenes as a', DB::raw('a.id::text'), '=', 'po.almacen_id')
            ->leftJoin('selemti.users as creador', 'creador.id', '=', 'po.creado_por')
            ->leftJoin('selemti.users as aprobador', 'aprobador.id', '=', 'po.aprobado_por')
            ->select([
                'po.id',
                'po.folio',
                'po.estado',
                'po.recipe_id',
                'po.item_id',
                'po.qty_programada',
                'po.qty_producida',
                'po.qty_merma',
                'po.uom_base',
                'po.sucursal_id',
                'po.almacen_id',
                'po.programado_para',
                'po.iniciado_en',
                'po.cerrado_en',
                'po.notas',
                'po.created_at',
                'po.updated_at',
                'rc.nombre_plato as recipe_nombre',
                'i.nombre as item_nombre',
                'i.unidad_medida as item_uom_base',
                'a.clave as almacen_clave',
                'a.nombre as almacen_nombre',
                'creador.name as creado_por_nombre',
                'aprobador.name as aprobado_por_nombre',
            ]);
    }

    private function inputs(int $orderId): array
    {
        return DB::connection('pgsql')
            ->table('selemti.production_order_inputs as inp')
            ->leftJoin('selemti.items as i', DB::raw('i.id::text'), '=', DB::raw('inp.item_id::text'))
            ->where('inp.production_order_id', $orderId)
            ->orderBy('inp.id')
            ->get([
                'inp.item_id',
                'inp.inventory_batch_id',
                'inp.qty',
                'inp.uom',
                'i.nombre as item_nombre',
            ])
            ->map(function ($row) {
                return [
                    'item_id' => (string) $row->item_id,
                    'item_nombre' => $row->item_nombre,
                    'uom_base' => $row->uom,
                    'qty_planned' => $this->quantity($row->qty),
                    'qty_actual' => $this->quantity($row->qty),
                    'costo_unit' => null,
                    'costo_total' => null,
                    'lote_id' => $row->inventory_batch_id === null ? null : (int) $row->inventory_batch_id,
                ];
            })
            ->all();
    }

    private function outputs(int $orderId): array
    {
        return DB::connection('pgsql')
            ->table('selemti.production_order_outputs as out')
            ->leftJoin('selemti.items as i', DB::raw('i.id::text'), '=', DB::raw('out.item_id::text'))
            ->where('out.production_order_id', $orderId)
            ->orderBy('out.id')
            ->get([
                'out.item_id',
                'out.qty',
                'out.uom',
                'out.lote_producido',
                'i.nombre as item_nombre',
            ])
            ->map(function ($row) {
                return [
                    'item_id' => (string) $row->item_id,
                    'item_nombre' => $row->item_nombre,
                    'uom_base' => $row->uom,
                    'qty_planned' => $this->quantity($row->qty),
                    'qty_actual' => $this->quantity($row->qty),
                    'lote_resultado' => $row->lote_producido,
                ];
            })
            ->all();
    }

    private function formatListRow(object $row): array
    {
        $qtyProgramada = $this->quantity($row->qty_programada);
        $qtyProducida = $this->quantity($row->qty_producida);

        return [
            'id' => (int) $row->id,
            'folio' => $row->folio,
            'estado' => $row->estado,
            'estado_label' => $this->estadoLabel($row->estado),
            'recipe' => $this->formatRecipe($row),
            'item_producido' => $row->item_id === null ? null : [
                'id' => (string) $row->item_id,
                'nombre' => $row->item_nombre,
                'uom_base' => $row->item_uom_base ?? $row->uom_base,
            ],
            'qty_programada' => $qtyProgramada,
            'qty_producida' => $qtyProducida,
            'qty_merma' => $this->quantity($row->qty_merma),
            'pct_cumplimiento' => $qtyProgramada == 0.0 ? null : round(($qtyProducida / $qtyProgramada) * 100, 2),
            'programado_para' => $this->iso($row->programado_para),
            'iniciado_en' => $this->iso($row->iniciado_en),
            'cerrado_en' => $this->iso($row->cerrado_en),
            'almacen' => $row->almacen_id === null ? null : [
                'id' => (string) $row->almacen_id,
                'nombre' => $row->almacen_nombre,
            ],
            'creado_por' => $row->creado_por_nombre,
            'created_at' => $this->iso($row->created_at),
        ];
    }

    private function formatRecipe(object $row, bool $includeVersion = false): ?array
    {
        if ($row->recipe_id === null) {
            return null;
        }

        $recipe = [
            'id' => (int) $row->recipe_id,
            'nombre' => $row->recipe_nombre,
        ];

        if ($includeVersion) {
            $version = DB::connection('pgsql')
                ->table('selemti.receta_version')
                ->where('receta_id', (string) $row->recipe_id)
                ->orderByDesc('version')
                ->value('version');

            $recipe['version'] = $version === null ? null : (string) $version;
        }

        return $recipe;
    }

    private function estadoLabel(?string $estado): string
    {
        return self::ESTADO_LABELS[$estado] ?? (string) $estado;
    }

    private function quantity(mixed $value): float
    {
        return round((float) ($value ?? 0), 6);
    }

    private function iso(mixed $value): ?string
    {
        return $value === null ? null : Carbon::parse($value)->toIso8601String();
    }
}
