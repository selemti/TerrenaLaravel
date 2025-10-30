@extends('layouts.terrena')

@php($active = 'admin')
@section('title', 'Configuración (en preparación)')
@section('page-title')
  <i class="fa-solid fa-gears"></i> Configuración
@endsection

@section('content')
<div class="container py-4">
  <div class="card border-0 shadow-sm">
    <div class="card-body">
      <h5 class="card-title"><i class="fa-solid fa-circle-info me-2"></i>Módulo en preparación</h5>
      <p class="text-muted">
        El panel de configuración avanzada se habilitará en próximos sprints. Algunos catálogos ya están disponibles en la sección de Catálogos.
      </p>
      <a href="{{ route('catalogos.index') }}" class="btn btn-outline-primary">
        <i class="fa-solid fa-book me-1"></i> Abrir Catálogos
      </a>
      {{-- TODO: reemplazar con módulo de configuración integral en Sprint 2.6 --}}
    </div>
  </div>
</div>
@endsection
