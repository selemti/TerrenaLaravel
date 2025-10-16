@extends('layouts.terrena', ['active' => 'dashboard'])
@section('title','Iniciar sesión')

@section('content')
<div class="content-wrapper px-3 py-4" style="max-width:640px">
  <div class="card shadow-sm">
    <div class="card-body">
      <form method="POST" action="{{ route('login') }}">
        @csrf
        <div class="mb-3">
          <label class="form-label">Usuario o correo</label>
          <input name="login" value="{{ old('login') }}" class="form-control @error('login') is-invalid @enderror" required autofocus>
          @error('login') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="mb-3">
          <label class="form-label">Contraseña</label>
          <input type="password" name="password" class="form-control @error('password') is-invalid @enderror" required>
          @error('password') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <button class="btn btn-success">
          <i class="fa-solid fa-right-to-bracket me-1"></i> Entrar
        </button>
      </form>
    </div>
  </div>
</div>
@endsection
