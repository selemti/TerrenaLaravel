@extends('layouts.auth')

@section('title', 'Recuperar contraseña')

@section('content')
    <h1 class="h4 fw-bold text-center mb-3">Recuperar acceso</h1>

    <p class="text-muted small text-center mb-4">
        Ingresa el correo electrónico asociado a tu cuenta y te enviaremos un enlace para restablecer tu contraseña.
    </p>

    @if (session('status'))
        <div class="alert alert-success" role="alert">
            <i class="fa-solid fa-circle-check me-1"></i>{{ session('status') }}
        </div>
    @endif

    <form method="POST" action="{{ route('password.email') }}" class="needs-validation" novalidate>
        @csrf
        <div class="mb-3">
            <label for="email" class="form-label fw-semibold">Correo electrónico</label>
            <input id="email" type="email" name="email" value="{{ old('email') }}" required autofocus
                   class="form-control form-control-lg @error('email') is-invalid @enderror" autocomplete="email">
            @error('email')
                <div class="invalid-feedback d-block">{{ $message }}</div>
            @enderror
        </div>

        <button type="submit" class="btn btn-success w-100 btn-lg mb-3">
            <i class="fa-solid fa-paper-plane me-2"></i>Enviar enlace de recuperación
        </button>
    </form>

    <div class="text-center">
        <a href="{{ route('login') }}" class="text-decoration-none small">
            <i class="fa-solid fa-arrow-left me-1"></i>Volver al inicio de sesión
        </a>
    </div>
@endsection
