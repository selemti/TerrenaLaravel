@extends('layouts.terrena')

@section('content')
<div class="py-5">
    <div class="row justify-content-center">
        <div class="col-lg-6 text-center">
            <div class="mb-4">
                <i class="fa-solid fa-hard-hat text-warning" style="font-size: 5rem;"></i>
            </div>
            <h2 class="fw-bold mb-3">Módulo en construcción</h2>
            <p class="text-muted mb-4">
                Esta funcionalidad está en desarrollo. Pronto estará disponible.
            </p>
            <a href="{{ url('/dashboard') }}" class="btn btn-primary">
                <i class="fa-solid fa-arrow-left me-1"></i>
                Volver al dashboard
            </a>
        </div>
    </div>
</div>
@endsection
