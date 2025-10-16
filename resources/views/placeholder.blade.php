@extends('layouts.terrena')

@section('title', $title ?? 'Página')
@section('page-title')
  <i class="fa-solid fa-file"></i> <span class="label">{{ $title ?? 'Página' }}</span>
@endsection

@section('content')
<div class="text-center py-5">
  <i class="fa-solid fa-hammer fa-3x text-muted mb-3"></i>
  <h3>Sección en desarrollo</h3>
  <p class="text-muted">Esta funcionalidad estará disponible próximamente.</p>
  <a href="{{ url('/dashboard') }}" class="btn btn-primary mt-3">
    <i class="fa-solid fa-arrow-left me-2"></i>Volver al Dashboard
  </a>
</div>
@endsection