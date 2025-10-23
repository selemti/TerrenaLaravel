@extends('layouts.auth')
@section('title','Iniciar sesión')

@section('content')
<form method="POST" action="{{ route('login') }}" class="needs-validation" novalidate>
    @csrf
    <div class="mb-3">
        <label class="form-label fw-semibold" for="login-input">Usuario o correo electrónico</label>
        <input id="login-input" name="login" value="{{ old('login') }}" class="form-control form-control-lg @error('login') is-invalid @enderror" required autofocus autocomplete="username">
        @error('login')
            <div class="invalid-feedback d-block">{{ $message }}</div>
        @enderror
    </div>

    <div class="mb-3 position-relative">
        <label class="form-label fw-semibold" for="password-input">Contraseña</label>
        <div class="input-group input-group-lg">
            <input id="password-input" type="password" name="password" class="form-control @error('password') is-invalid @enderror" required autocomplete="current-password">
            <button class="btn btn-outline-secondary" type="button" id="toggle-password" aria-label="Mostrar u ocultar contraseña">
                <i class="fa-solid fa-eye"></i>
            </button>
        </div>
        @error('password')
            <div class="invalid-feedback d-block">{{ $message }}</div>
        @enderror
    </div>

    <div class="d-flex justify-content-between align-items-center mb-4">
        <div class="form-check">
            <input class="form-check-input" type="checkbox" value="1" id="remember" name="remember" {{ old('remember') ? 'checked' : '' }}>
            <label class="form-check-label" for="remember">Recordarme</label>
        </div>
        <a class="small text-decoration-none" href="{{ route('password.request') }}">¿Olvidaste tu contraseña?</a>
    </div>

    <button class="btn btn-success w-100 btn-lg" type="submit">
        <i class="fa-solid fa-right-to-bracket me-2"></i>Ingresar
    </button>
</form>
@endsection

@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', () => {
        const toggleBtn = document.getElementById('toggle-password');
        const input = document.getElementById('password-input');
        if (!toggleBtn || !input) {
            return;
        }
        toggleBtn.addEventListener('click', () => {
            const isPassword = input.getAttribute('type') === 'password';
            input.setAttribute('type', isPassword ? 'text' : 'password');
            toggleBtn.querySelector('i').classList.toggle('fa-eye');
            toggleBtn.querySelector('i').classList.toggle('fa-eye-slash');
        });
    });
</script>
@endpush
