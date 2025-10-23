@extends('layouts.terrena', ['active' => 'personal'])

@section('title', 'Mi Perfil - TerrenaPOS')
@section('page-title')
  <i class="fa-solid fa-user"></i> <span class="label">Mi Perfil</span>
@endsection

@section('content')
<div class="row justify-content-center">
  <div class="col-lg-6">
    @if (session('status') === 'profile-updated')
      <div class="alert alert-success alert-dismissible fade show" role="alert">
        <i class="fa-solid fa-circle-check me-2"></i>Perfil actualizado correctamente.
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    <div class="card shadow-sm mb-4">
      <div class="card-body">
        <h5 class="card-title mb-3">Información general</h5>
        <dl class="row mb-0">
          <dt class="col-sm-4">Nombre de usuario</dt>
          <dd class="col-sm-8">{{ $user->username ?? '—' }}</dd>
          <dt class="col-sm-4">Correo electrónico</dt>
          <dd class="col-sm-8">{{ $user->email }}</dd>
          <dt class="col-sm-4">Rol(es)</dt>
          <dd class="col-sm-8">{{ $user->getRoleNames()->implode(', ') ?: 'Sin rol asignado' }}</dd>
        </dl>
      </div>
    </div>

    <div class="card shadow-sm">
      <div class="card-body">
        <h5 class="card-title mb-3">Actualizar datos</h5>
        <form method="POST" action="{{ route('profile.update') }}">
          @csrf
          @method('PUT')

          <div class="mb-3">
            <label class="form-label" for="profile-name">Nombre para mostrar</label>
            <input id="profile-name" type="text" name="name" class="form-control @error('name') is-invalid @enderror" value="{{ old('name', $user->name) }}" required>
            @error('name')
              <div class="invalid-feedback">{{ $message }}</div>
            @enderror
          </div>

          <div class="row">
            <div class="col-md-6">
              <div class="mb-3">
                <label class="form-label" for="profile-password">Nueva contraseña</label>
                <input id="profile-password" type="password" name="password" class="form-control @error('password') is-invalid @enderror" autocomplete="new-password">
                <div class="form-text">Dejar en blanco para mantener la actual.</div>
                @error('password')
                  <div class="invalid-feedback">{{ $message }}</div>
                @enderror
              </div>
            </div>
            <div class="col-md-6">
              <div class="mb-3">
                <label class="form-label" for="profile-password-confirmation">Confirmar contraseña</label>
                <input id="profile-password-confirmation" type="password" name="password_confirmation" class="form-control" autocomplete="new-password">
              </div>
            </div>
          </div>

          <button type="submit" class="btn btn-success">
            <i class="fa-solid fa-floppy-disk me-1"></i>Guardar cambios
          </button>
        </form>
      </div>
    </div>
  </div>
</div>
@endsection
