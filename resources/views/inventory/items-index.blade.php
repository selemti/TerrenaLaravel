@extends('layouts.terrena')
@section('title','Inventario')

@section('content')
<div class="container-fluid">

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-3">
    <h1 class="h3 mb-0">
      <i class="fa-solid fa-boxes-stacked me-2"></i> Inventario
    </h1>
    <div class="text-muted small d-none d-md-inline">
      <i class="fa-regular fa-clock me-1"></i><span id="live-clock">--:--</span>
      <span class="ms-2"><i class="fa-regular fa-calendar"></i> {{ date('d/m/Y') }}</span>
    </div>
  </div>

  {{-- Filtros --}}
  <div class="card shadow-sm mb-3">
    <div class="card-body d-flex flex-column flex-lg-row gap-2 align-items-stretch align-items-lg-center">
      <div class="flex-grow-1">
        <input wire:model.debounce.400ms="q" type="text" class="form-control" placeholder="Buscar producto / SKU (Ej. 'Leche 1.5L' o 'SKU-0001')">
      </div>
      <select wire:model="sucursal" class="form-select">
        <option value="">Sucursal: Todas</option>
        <option value="PRINCIPAL">PRINCIPAL</option>
        <option value="NB">NB</option>
        <option value="TORRE">TORRE</option>
        <option value="TERRENA">TERRENA</option>
      </select>
      <select wire:model="categoria" class="form-select">
        <option value="">Categoría: Todas</option>
        {{-- Rellena con tus categorías si tienes tabla --}}
      </select>
      <select wire:model="estado" class="form-select">
        <option value="">Estado: Todos</option>
        <option value="BAJO">Bajo stock</option>
        <option value="NORMAL">Normal</option>
      </select>
      <button class="btn btn-primary">
        <i class="fa-solid fa-filter me-1"></i> Filtrar
      </button>
      <button class="btn btn-outline-secondary">Exportar</button>
    </div>
  </div>

  {{-- KPIs --}}
  <div class="row g-3 mb-2">
    <div class="col-6 col-md-3">
      <div class="card shadow-sm h-100">
        <div class="card-body">
          <div class="text-muted small">Ítems distintos</div>
          <div class="display-6 fs-3">{{ number_format($kpis['items'] ?? 0) }}</div>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="card shadow-sm h-100">
        <div class="card-body">
          <div class="text-muted small">Valor inventario</div>
          <div class="display-6 fs-3">{{ '$ '.number_format($kpis['valor'] ?? 0, 2) }}</div>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="card shadow-sm h-100">
        <div class="card-body">
          <div class="text-muted small">Bajo stock</div>
          <div class="display-6 fs-3">{{ number_format($kpis['bajo'] ?? 0) }}</div>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="card shadow-sm h-100">
        <div class="card-body">
          <div class="text-muted small">Con caducidad &lt; 15 días</div>
          <div class="display-6 fs-3">{{ number_format($kpis['caducidad'] ?? 0) }}</div>
        </div>
      </div>
    </div>
  </div>

  {{-- Tabla --}}
  <div class="d-flex justify-content-between align-items-center mb-2">
    <span class="badge text-bg-light">Vista: Stock</span>
    <div class="d-flex gap-2">
      <button class="btn btn-outline-secondary btn-sm" disabled>Ver Kardex</button>
      <button class="btn btn-primary btn-sm">Movimiento rápido</button>
    </div>
  </div>

  <div class="card shadow-sm">
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th style="width:110px">SKU</th>
            <th>Producto</th>
            <th style="width:100px">UDM base</th>
            <th style="width:130px" class="text-end">Existencia</th>
            <th style="width:110px" class="text-end">Mín</th>
            <th style="width:110px" class="text-end">Máx</th>
            <th style="width:130px" class="text-end">Costo (base)</th>
            <th style="width:130px">Sucursal</th>
            <th style="width:200px" class="text-end">Acciones</th>
          </tr>
        </thead>
        <tbody>
        @forelse($rows as $r)
          @php
            $low = (float)$r->existencia < (float)$r->min;
          @endphp
          <tr>
            <td class="font-monospace">{{ $r->sku }}</td>
            <td>{{ $r->producto }}</td>
            <td>{{ $r->udm_base }}</td>
            <td class="text-end {{ $low ? 'text-danger fw-semibold' : '' }}">{{ number_format((float)$r->existencia, 2) }}</td>
            <td class="text-end">{{ number_format((float)$r->min, 2) }}</td>
            <td class="text-end">{{ number_format((float)$r->max, 2) }}</td>
            <td class="text-end">$ {{ number_format((float)$r->costo_base, 4) }}</td>
            <td>
              <span class="badge text-bg-secondary">{{ strtoupper($r->sucursal) }}</span>
            </td>
            <td class="text-end">
              <button class="btn btn-outline-primary btn-sm" wire:click="mover('{{ $r->sku }}')">Mover</button>
              <button class="btn btn-outline-secondary btn-sm" wire:click="kardex('{{ $r->sku }}')">Kardex</button>
              <button class="btn btn-outline-dark btn-sm" wire:click="editar('{{ $r->sku }}')">Editar</button>
            </td>
          </tr>
        @empty
          <tr>
            <td colspan="9" class="text-center text-muted py-4">
              Sin resultados.
            </td>
          </tr>
        @endforelse
        </tbody>
      </table>
    </div>
    <div class="card-footer py-2">
      {{ $rows->links() }}
    </div>
  </div>

  {{-- Barra inferior fija (opcional) --}}
  <div class="mt-3 text-muted small">
    <i class="fa-solid fa-store me-1"></i> Sucursal: <strong>PRINCIPAL</strong>
  </div>
</div>
@endsection
