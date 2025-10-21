<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ $title ?? $__env->yieldContent('title', 'SelemTI - TerrenaPOS') }}</title>

  <meta name="csrf-token" content="{{ csrf_token() }}">
  <script>
    window.__BASE__ = "{{ rtrim(parse_url(url('/'), PHP_URL_PATH), '/') }}";
    window.__API_BASE__ = window.__BASE__;  // API base is the same as app base
  </script>

  {{-- CSS locales (mismo orden que legacy) --}}
  <link href="{{ asset('assets/css/bootstrap.min.css') }}" rel="stylesheet">
  <link href="{{ asset('assets/fontawesome-free-7.0.1-web/css/all.min.css') }}" rel="stylesheet">
  <link rel="stylesheet" href="{{ asset('assets/css/terrena.css') }}">
  <link rel="stylesheet" href="{{ asset('assets/css/caja.css') }}">

  @livewireStyles
  @stack('styles')
</head>
<body>
  <div class="container-fluid p-0 d-flex" style="min-height:100vh">
    
    {{-- Sidebar (réplica exacta del layout.php) --}}
    <aside class="sidebar flex-column" id="sidebar">
      <div class="logo-brand mb-3 d-flex align-items-center justify-content-center">
        <a href="{{ url('/dashboard') }}" class="text-decoration-none">
          <img src="{{ asset('assets/img/logo.svg') }}" id="logoImg" alt="Terrena" style="height:44px">
        </a>
      </div>
      <hr style="margin:0">
      <nav class="nav flex-column gap-1">
        <a class="nav-link {{ ($active ?? '') === 'dashboard' ? 'active' : '' }}" href="{{ url('/dashboard') }}">
          <i class="fa-solid fa-gauge"></i> <span class="label">Dashboard</span>
        </a>
				<a class="nav-link {{ ($active ?? '') === 'cortes' ? 'active' : '' }}" href="{{ route('caja.cortes') }}" class="{{ $active == 'cortes' ? 'active' : '' }}">
						<i class="fa-solid fa-cash-register"></i> Cortes de Caja
				</a>
        <a class="nav-link {{ ($active ?? '') === 'inventario' ? 'active' : '' }}" href="{{ url('/inventario') }}">
          <i class="fa-solid fa-boxes-stacked"></i> <span class="label">Inventario</span>
        </a>
        <a class="nav-link {{ ($active ?? '') === 'compras' ? 'active' : '' }}" href="{{ url('/compras') }}">
          <i class="fa-solid fa-truck"></i> <span class="label">Compras</span>
        </a>
        <a class="nav-link {{ ($active ?? '') === 'recetas' ? 'active' : '' }}" href="{{ url('/recetas') }}">
          <i class="fa-solid fa-bowl-food"></i> <span class="label">Recetas</span>
        </a>
        <a class="nav-link {{ ($active ?? '') === 'produccion' ? 'active' : '' }}" href="{{ url('/produccion') }}">
          <i class="fa-solid fa-industry"></i> <span class="label">Producción</span>
        </a>
        <a class="nav-link {{ ($active ?? '') === 'reportes' ? 'active' : '' }}" href="{{ url('/reportes') }}">
          <i class="fa-solid fa-chart-column"></i> <span class="label">Reportes</span>
        </a>
        <a class="nav-link {{ ($active ?? '') === 'config' ? 'active' : '' }}" href="{{ url('/admin') }}">
          <i class="fa-solid fa-gear"></i> <span class="label">Configuración</span>
        </a>
        <a class="nav-link {{ ($active ?? '') === 'personal' ? 'active' : '' }}" href="{{ url('/personal') }}">
          <i class="fa-solid fa-user-group"></i> <span class="label">Personal</span>
        </a>
      </nav>
      <button class="btn btn-sm btn-outline-secondary d-none d-lg-inline-flex ms-2" id="sidebarCollapse" aria-label="Colapsar menú">
        <i class="fa-solid fa-angles-left"></i>
      </button>
    </aside>

    {{-- Contenido principal --}}
    <main class="main-content flex-grow-1">
      
      {{-- Top Bar (header superior) --}}
      <div class="top-bar sticky-top">
        <div class="d-flex align-items-center gap-2">
          <button class="btn btn-sm btn-outline-secondary d-lg-none" id="sidebarToggleMobile" aria-label="Menú">
            <i class="fa-solid fa-bars"></i>
          </button>
          @hasSection('page-title')
            <h1 class="top-bar-title mb-0">@yield('page-title')</h1>
          @else
            <h1 class="top-bar-title mb-0">{{ $pageTitle ?? 'Dashboard' }}</h1>
          @endif
        </div>

        <div class="d-flex align-items-center gap-3">
          <div class="text-secondary small">
            <i class="fa-regular fa-clock me-1"></i><span id="live-clock">--:--</span>
          </div>
          <div class="text-secondary small">
            <i class="fa-regular fa-calendar me-1"></i><span id="live-date">--/--/----</span>
          </div>

          {{-- Notificaciones --}}
          <div class="dropdown">
            <button class="btn btn-outline-secondary position-relative" data-bs-toggle="dropdown">
              <i class="fa-regular fa-bell"></i>
              <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" id="hdr-alerts-badge">0</span>
            </button>
            <div class="dropdown-menu dropdown-menu-end p-0" style="min-width:320px">
              <div class="px-3 py-2 border-bottom d-flex justify-content-between align-items-center">
                <strong>Alertas</strong>
                <a href="{{ url('/reportes') }}" class="link-more small">Ver todas <i class="fa-solid fa-chevron-right ms-1"></i></a>
              </div>
              <div id="hdr-alerts-list" class="py-1"></div>
            </div>
          </div>

          {{-- Usuario --}}
          <div class="dropdown">
            <button class="btn btn-light d-inline-flex align-items-center gap-2" data-bs-toggle="dropdown">
              <span class="user-profile-icon"><i class="fa-solid fa-user"></i></span>
              <span>{{ optional(auth()->user())->name ?? 'Juan Pérez' }}</span>
              <i class="fa-solid fa-chevron-down small"></i>
            </button>
            <ul class="dropdown-menu dropdown-menu-end">
              <li><a class="dropdown-item" href="{{ url('/personal') }}">Mi perfil</a></li>
              <li><a class="dropdown-item" href="{{ url('/admin') }}">Configuración</a></li>
              <li><hr class="dropdown-divider"></li>
              <li>
                @auth
                  <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button class="dropdown-item text-danger" type="submit">Cerrar sesión</button>
                  </form>
                @else
                  <a class="dropdown-item text-danger" href="{{ url('/logout') }}">Cerrar sesión</a>
                @endauth
              </li>
            </ul>
          </div>
        </div>
      </div>

      {{-- Contenido de cada vista --}}
      <div class="p-3">
        @isset($slot)
          {{ $slot }}
        @else
          @yield('content')
        @endisset
      </div>

      {{-- Footer / Status Bar --}}
      <footer class="status-bar mt-auto">
        <div class="container-status">
          <div class="d-flex align-items-center gap-2">
            <i class="fa-solid fa-store"></i>
            <span>Sucursal: <strong>PRINCIPAL</strong></span>
          </div>
          <div class="ms-auto d-flex align-items-center gap-3">
            <span id="live-clock-bottom" class="text-secondary">--:--</span>
          </div>
        </div>
      </footer>
    </main>
  </div>

  {{-- JS al final (mismo orden que legacy) --}}
  <script src="{{ asset('assets/js/bootstrap.bundle.min.js') }}"></script>
  <script src="{{ asset('assets/js/chart.umd.min.js') }}"></script>
  <script src="{{ asset('assets/vendor/cleave.min.js') }}"></script>
  <script src="{{ asset('assets/js/moneda.js') }}" defer></script>
  <script src="{{ asset('assets/js/terrena.js') }}" defer></script>
  @livewireScripts
  @stack('scripts')
</body>
</html>
