<?php

namespace App\Services\Reporting;

use Illuminate\Contracts\Database\Query\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class ReportService
{
    /**
     * @param  array<string, mixed>  $filters
     */
    public function run(string $slug, array $filters = []): Collection
    {
        $definition = DB::table('selemti.report_definitions')->where('slug', $slug)->first();

        if (! $definition) {
            throw new InvalidArgumentException('Reporte no encontrado');
        }

        $config = json_decode($definition->config, true, 512, JSON_THROW_ON_ERROR);
        $query = $this->buildQuery($config, $filters);

        return collect($query->get());
    }

    /**
     * @param  array<string, mixed>  $config
     * @param  array<string, mixed>  $filters
     */
    protected function buildQuery(array $config, array $filters): Builder
    {
        $builder = DB::connection('pgsql')->table($config['from']);

        foreach ($config['select'] as $column) {
            $builder->selectRaw($column);
        }

        foreach ($config['joins'] ?? [] as $join) {
            $builder->{$join['type'] ?? 'join'}($join['table'], $join['first'], $join['operator'] ?? '=', $join['second']);
        }

        foreach ($config['wheres'] ?? [] as $where) {
            if (($where['type'] ?? 'basic') === 'filter' && isset($filters[$where['key']])) {
                $builder->where($where['column'], $where['operator'] ?? '=', $filters[$where['key']]);
            } elseif (($where['type'] ?? 'basic') === 'between' && isset($filters[$where['key'][0]], $filters[$where['key'][1]])) {
                $builder->whereBetween($where['column'], [$filters[$where['key'][0]], $filters[$where['key'][1]]]);
            } elseif (($where['type'] ?? 'basic') === 'raw') {
                $builder->whereRaw($where['sql'], $where['bindings'] ?? []);
            }
        }

        foreach ($config['group_by'] ?? [] as $group) {
            $builder->groupBy($group);
        }

        foreach ($config['order_by'] ?? [] as $order) {
            $builder->orderBy($order['column'], $order['direction'] ?? 'asc');
        }

        return $builder;
    }
}
