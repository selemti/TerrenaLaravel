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

    @auth
    {{-- Sidebar (réplica exacta del layout.php) --}}
    <aside class="sidebar flex-column" id="sidebar">
      <div class="logo-brand mb-3 d-flex align-items-center justify-content-center">
        <a href="{{ url('/dashboard') }}" class="text-decoration-none">
          <img src="{{ asset('assets/img/logo.svg') }}" id="logoImg" alt="Terrena" style="height:44px">
        </a>
      </div>
      <hr style="margin:0">
      <nav class="nav flex-column gap-1">
        {{-- Dashboard --}}
        <a class="nav-link {{ ($active ?? '') === 'dashboard' ? 'active' : '' }}" href="{{ url('/dashboard') }}">
          <i class="fa-solid fa-gauge"></i> <span class="label">Dashboard</span>
        </a>

        {{-- Caja con submenú --}}
        <div class="nav-item">
          <a class="nav-link {{ in_array($active ?? '', ['caja', 'cortes', 'cajachica']) ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuCaja" role="button" aria-expanded="false">
            <i class="fa-solid fa-cash-register"></i> <span class="label">Caja</span>
            <i class="fa-solid fa-chevron-down ms-auto submenu-arrow"></i>
          </a>
          <div class="collapse {{ in_array($active ?? '', ['caja', 'cortes', 'cajachica']) ? 'show' : '' }}" id="menuCaja">
            <div class="submenu">
              <a class="nav-link submenu-link" href="{{ route('caja.cortes') }}">
                <i class="fa-solid fa-receipt"></i> <span class="label">Cortes de Caja</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('cashfund.index') }}">
                <i class="fa-solid fa-wallet"></i> <span class="label">Caja Chica</span>
              </a>
            </div>
          </div>
        </div>

        {{-- Inventario con submenú --}}
        <div class="nav-item">
          <a class="nav-link {{ in_array($active ?? '', ['inventario', 'items', 'lots', 'receptions', 'alerts']) ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuInventario" role="button" aria-expanded="false">
            <i class="fa-solid fa-boxes-stacked"></i> <span class="label">Inventario</span>
            <i class="fa-solid fa-chevron-down ms-auto submenu-arrow"></i>
          </a>
          <div class="collapse {{ in_array($active ?? '', ['inventario', 'items', 'lots', 'receptions', 'alerts']) ? 'show' : '' }}" id="menuInventario">
            <div class="submenu">
              <a class="nav-link submenu-link" href="{{ url('/inventario') }}">
                <i class="fa-solid fa-chart-line"></i> <span class="label">Vista General</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('inventory.items.index') }}">
                <i class="fa-solid fa-box"></i> <span class="label">Items</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('inv.lots') }}">
                <i class="fa-solid fa-tag"></i> <span class="label">Lotes</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('inv.receptions') }}">
                <i class="fa-solid fa-dolly"></i> <span class="label">Recepciones</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('inv.alerts') }}">
                <i class="fa-regular fa-bell"></i> <span class="label">Alertas de costo</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('inv.counts.index') }}">
                <i class="fa-solid fa-clipboard-check"></i> <span class="label">Conteos</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('transfers.index') }}">
                <i class="fa-solid fa-truck-ramp-box"></i> <span class="label">Transferencias</span>
              </a>
            </div>
          </div>
        </div>

        {{-- Compras --}}
        <a class="nav-link {{ ($active ?? '') === 'compras' ? 'active' : '' }}" href="{{ url('/compras') }}">
          <i class="fa-solid fa-truck"></i> <span class="label">Compras</span>
        </a>

        {{-- Recetas --}}
        <a class="nav-link {{ ($active ?? '') === 'recetas' ? 'active' : '' }}" href="{{ route('rec.index') }}">
          <i class="fa-solid fa-bowl-food"></i> <span class="label">Recetas</span>
        </a>

        {{-- Producción --}}
        <a class="nav-link {{ ($active ?? '') === 'produccion' ? 'active' : '' }}" href="{{ url('/produccion') }}">
          <i class="fa-solid fa-industry"></i> <span class="label">Producción</span>
        </a>

        {{-- Reportes --}}
        <a class="nav-link {{ ($active ?? '') === 'reportes' ? 'active' : '' }}" href="{{ url('/reportes') }}">
          <i class="fa-solid fa-chart-column"></i> <span class="label">Reportes</span>
        </a>

        {{-- Configuración con submenú --}}
        @can('admin.access')
        <div class="nav-item">
          <a class="nav-link {{ ($active ?? '') === 'config' ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuConfig" role="button" aria-expanded="false">
            <i class="fa-solid fa-gear"></i> <span class="label">Configuración</span>
            <i class="fa-solid fa-chevron-down ms-auto submenu-arrow"></i>
          </a>
          <div class="collapse {{ ($active ?? '') === 'config' ? 'show' : '' }}" id="menuConfig">
            <div class="submenu">
              <a class="nav-link submenu-link" href="{{ route('catalogos.index') }}">
                <i class="fa-solid fa-book"></i> <span class="label">Catálogos</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('cat.sucursales') }}">
                <i class="fa-solid fa-store"></i> <span class="label">Sucursales</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('cat.almacenes') }}">
                <i class="fa-solid fa-warehouse"></i> <span class="label">Almacenes</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('cat.unidades') }}">
                <i class="fa-solid fa-ruler"></i> <span class="label">Unidades</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('cat.proveedores') }}">
                <i class="fa-solid fa-truck-field"></i> <span class="label">Proveedores</span>
              </a>
              <a class="nav-link submenu-link" href="{{ route('cat.stockpolicy') }}">
                <i class="fa-solid fa-sliders"></i> <span class="label">Políticas Stock</span>
              </a>
              <hr class="my-2 opacity-25">
              <a class="nav-link submenu-link" href="{{ url('/admin') }}">
                <i class="fa-solid fa-cog"></i> <span class="label">Sistema</span>
              </a>
            </div>
          </div>
        </div>
        @endcan

        {{-- Personal --}}
        @can('people.view')
        <a class="nav-link {{ ($active ?? '') === 'personal' ? 'active' : '' }}" href="{{ url('/personal') }}">
          <i class="fa-solid fa-user-group"></i> <span class="label">Personal</span>
        </a>
        @endcan

        {{-- KDS --}}
        <a class="nav-link {{ ($active ?? '') === 'kds' ? 'active' : '' }}" href="{{ route('kds.board') }}">
          <i class="fa-solid fa-tv"></i> <span class="label">KDS</span>
        </a>
      </nav>
      <button class="btn btn-sm btn-outline-secondary d-none d-lg-inline-flex ms-2" id="sidebarCollapse" aria-label="Colapsar menú">
        <i class="fa-solid fa-angles-left"></i>
      </button>
    </aside>
    @endauth

    {{-- Contenido principal --}}
    <main class="main-content flex-grow-1 {{ auth()->check() ? '' : 'w-100' }}">

      @auth
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
              <span>{{ auth()->user()->name }}</span>
              <i class="fa-solid fa-chevron-down small"></i>
            </button>
            <ul class="dropdown-menu dropdown-menu-end">
              <li><a class="dropdown-item" href="{{ url('/profile') }}">Mi perfil</a></li>
              @can('admin.access')
              <li><a class="dropdown-item" href="{{ url('/admin') }}">Configuración</a></li>
              @endcan
              <li><hr class="dropdown-divider"></li>
              <li>
                <form method="POST" action="{{ route('logout') }}">
                  @csrf
                  <button class="dropdown-item text-danger" type="submit">Cerrar sesión</button>
                </form>
              </li>
            </ul>
          </div>
        </div>
      </div>
      @endauth

      {{-- Contenido de cada vista --}}
      <div class="p-3">
        @isset($slot)
          {{ $slot }}
        @else
          @yield('content')
        @endisset
      </div>

      {{-- Footer / Status Bar --}}
      @auth
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
      @endauth
    </main>
  </div>

  {{-- JS al final (mismo orden que legacy) --}}
  <script src="{{ asset('assets/js/bootstrap.bundle.min.js') }}"></script>
  <script src="{{ asset('assets/js/chart.umd.min.js') }}"></script>
  <script src="{{ asset('assets/vendor/cleave.min.js') }}"></script>
  <script src="{{ asset('assets/js/moneda.js') }}"></script>
  <script src="{{ asset('assets/js/terrena.js') }}"></script>
  @livewireScripts
  <script>
    (function () {
      const basePath = window.__BASE__ || '';
      const livewireScript = document.querySelector('script[data-update-uri]');
      if (basePath && livewireScript && livewireScript.dataset.updateUri?.startsWith('/livewire/')) {
        livewireScript.dataset.updateUri = basePath + livewireScript.dataset.updateUri;
      }
      document.addEventListener('livewire:init', () => {
        Livewire.hook('request', ({ options }) => {
          if (!options) return;
          const url = options.url || options.uri;
          if (basePath && typeof url === 'string' && url.startsWith('/livewire/')) {
            const newUrl = basePath + url;
            options.url = newUrl;
            options.uri = newUrl;
          }
        });
      });
    })();
  </script>
  @stack('scripts')
</body>
</html>
