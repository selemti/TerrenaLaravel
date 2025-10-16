@extends('layouts.terrena')

@section('title', 'Login - TerrenaPOS')
@section('page-title', 'Login')

@section('content')
<div class="row justify-content-center mt-4">
  <div class="col-12 col-sm-10 col-md-6 col-lg-4">
    <div class="card-vo p-4">
      <h5 class="card-title mb-3">
        <i class="fa-solid fa-right-to-bracket"></i> Iniciar sesión
      </h5>
      
      <form method="POST" action="{{ route('login') }}">
        @csrf
        
        <div class="mb-2">
          <input 
            class="form-control form-control-sm @error('username') is-invalid @enderror" 
            name="username" 
            placeholder="Usuario" 
            value="{{ old('username') }}"
            required 
            autofocus
          >
          @error('username')
            <div class="invalid-feedback">{{ $message }}</div>
          @enderror
        </div>

        <div class="mb-3">
          <input 
            class="form-control form-control-sm @error('password') is-invalid @enderror" 
            name="password" 
            placeholder="Contraseña" 
            type="password"
            required
          >
          @error('password')
            <div class="invalid-feedback">{{ $message }}</div>
          @enderror
        </div>

        <div class="mb-3 form-check">
          <input type="checkbox" class="form-check-input" id="remember" name="remember">
          <label class="form-check-label small" for="remember">
            Recordarme
          </label>
        </div>

        <button type="submit" class="btn btn-sm text-white w-100" style="background:var(--green-dark)">
          Entrar
        </button>
      </form>

      @if (session('status'))
        <div class="alert alert-success mt-3 small" role="alert">
          {{ session('status') }}
        </div>
      @endif
    </div>
  </div>
</div>
@endsection