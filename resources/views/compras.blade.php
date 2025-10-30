@extends('layouts.terrena')

@php($active = 'compras')
@section('title', 'Compras / Purchasing')
@section('page-title')
  <i class="fa-solid fa-truck"></i> Compras
@endsection

@section('content')
<div class="container py-4">
  <div class="card shadow-sm border-0">
    <div class="card-body">
      <h5 class="card-title">
        <i class="fa-solid fa-circle-info me-2"></i>Módulo en preparación
      </h5>
      <p class="text-muted mb-4">
        Estamos integrando el hub de compras en este espacio. Mientras tanto, utiliza los accesos directos a los módulos ya activos.
      </p>

      <div class="d-flex flex-wrap gap-2">
        <a href="{{ route('purchasing.requests.index') }}" class="btn btn-outline-primary">
          <i class="fa-solid fa-list me-1"></i> Requisiciones
        </a>
        <a href="{{ route('purchasing.orders.index') }}" class="btn btn-outline-primary">
          <i class="fa-solid fa-file-invoice-dollar me-1"></i> Órdenes de compra
        </a>
        <a href="{{ route('purchasing.replenishment.dashboard') }}" class="btn btn-outline-primary">
          <i class="fa-solid fa-repeat me-1"></i> Sugeridos Min/Max
        </a>
      </div>

      <hr class="my-4">

      <div class="alert alert-warning mb-0">
        <strong>Próximamente:</strong> consolidaremos requisiciones, OC, recepciones y proveedores en esta pantalla.
      </div>
      {{-- TODO: enlazar a módulo unificado de compras en Sprint 2.6 --}}
    </div>
  </div>
</div>
@endsection
