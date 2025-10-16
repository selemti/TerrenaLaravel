@php($active = $active ?? '')
<nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow-sm">
  <div class="container-fluid">
    <a class="navbar-brand d-flex align-items-center gap-2" href="{{ url('/') }}">
      <img src="{{ asset('assets/img/logo.svg') }}" alt="Terrena" height="24">
      <span>Terrena</span>
    </a>

    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#terrenaNav" aria-controls="terrenaNav" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="terrenaNav">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
        <li class="nav-item">
          <a class="nav-link {{ str_starts_with($active,'dashboard') ? 'active' : '' }}" href="{{ url('/dashboard') }}">
            <i class="fa-solid fa-gauge-high me-1"></i> Dashboard
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link {{ str_starts_with($active,'inventory') ? 'active' : '' }}" href="{{ url('/inventory') }}">
            <i class="fa-solid fa-boxes-stacked me-1"></i> Inventario
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link {{ str_starts_with($active,'recetas') ? 'active' : '' }}" href="{{ url('/recetas') }}">
            <i class="fa-solid fa-bowl-food me-1"></i> Recetas
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link {{ str_starts_with($active,'catalogos') ? 'active' : '' }}" href="{{ url('/catalogos/unidades') }}">
            <i class="fa-solid fa-list me-1"></i> Catálogos
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link {{ str_starts_with($active,'kds') ? 'active' : '' }}" href="{{ url('/kds') }}">
            <i class="fa-solid fa-display me-1"></i> KDS
          </a>
        </li>
      </ul>

      <ul class="navbar-nav ms-auto">
        @auth
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle d-flex align-items-center gap-2" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">
              <i class="fa-regular fa-user"></i>
              <span>{{ auth()->user()->username ?? auth()->user()->name ?? 'Usuario' }}</span>
            </a>
            <ul class="dropdown-menu dropdown-menu-end">
              <li><a class="dropdown-item" href="{{ url('/perfil') }}">Mi perfil</a></li>
              <li><a class="dropdown-item" href="{{ url('/admin') }}">Configuración</a></li>
              <li><hr class="dropdown-divider"></li>
              <li>
                <form method="POST" action="{{ route('logout') }}">
                  @csrf
                  <button class="dropdown-item text-danger" type="submit">
                    <i class="fa-solid fa-right-from-bracket me-1"></i> Cerrar sesión
                  </button>
                </form>
              </li>
            </ul>
          </li>
        @else
          <li class="nav-item">
            <a class="btn btn-outline-light btn-sm" href="{{ route('login') }}">
              <i class="fa-solid fa-right-to-bracket me-1"></i> Entrar
            </a>
          </li>
        @endauth
      </ul>
    </div>
  </div>
</nav>
