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

    // Global variables for permissions and API token
    window.TerrenaPermissions = [];
    window.TerrenaApiToken = null;
    window.TerrenaPermissionsLoaded = false;

    // Session storage keys
    const STORAGE_TOKEN_KEY = 'terrena_api_token';
    const STORAGE_PERMS_KEY = 'terrena_permissions';

    /**
     * Helper function to check if user has a specific permission
     * @param {string} permName - Permission name to check
     * @returns {boolean}
     */
    window.TerrenaHasPerm = function(permName) {
      if (!window.TerrenaPermissions || !Array.isArray(window.TerrenaPermissions)) {
        return false;
      }
      return window.TerrenaPermissions.includes(permName);
    };

    /**
     * Load API token for authenticated API calls
     * Uses sessionStorage cache to avoid repeated requests
     */
    async function TerrenaLoadApiToken() {
      // Check cache first with expiration
      const cached = getCachedValue(STORAGE_TOKEN_KEY);
      if (cached) {
        window.TerrenaApiToken = cached;
        console.log('[Terrena] API token loaded from cache');
        return;
      }

      // Fetch from server
      try {
        const res = await fetch("{{ url('/session/api-token') }}", {
          credentials: 'include',
          headers: {
            'Accept': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
          }
        });

        if (res.ok) {
          const data = await res.json();
          window.TerrenaApiToken = data.token;
          setCachedValue(STORAGE_TOKEN_KEY, data.token);
          console.log('[Terrena] API token loaded from server');
        } else {
          console.warn('[Terrena] Failed to load API token, status:', res.status);
        }
      } catch (e) {
        console.error('[Terrena] Error loading API token:', e);
      }
    }

    /**
     * Load user permissions from API
     * Uses sessionStorage cache to avoid repeated requests
     */
    async function TerrenaLoadPermissions() {
      // Check cache first with expiration
      const cached = getCachedValue(STORAGE_PERMS_KEY);
      if (cached) {
        window.TerrenaPermissions = cached;
        window.TerrenaPermissionsLoaded = true;
        document.dispatchEvent(new Event('terrena:perms-ready'));
        console.log('[Terrena] Loaded', window.TerrenaPermissions.length, 'permissions from cache');
        return;
      }

      // Fetch from server
      try {
        // Wait for token to be loaded first
        if (!window.TerrenaApiToken) {
          await TerrenaLoadApiToken();
        }

        const headers = {
          'Accept': 'application/json',
        };

        if (window.TerrenaApiToken) {
          headers['Authorization'] = 'Bearer ' + window.TerrenaApiToken;
        }

        const res = await fetch("{{ url('/api/me/permissions') }}", { headers });

        if (res.ok) {
          const data = await res.json();
          window.TerrenaPermissions = data.permissions || [];
          setCachedValue(STORAGE_PERMS_KEY, window.TerrenaPermissions);
          window.TerrenaPermissionsLoaded = true;
          document.dispatchEvent(new Event('terrena:perms-ready'));
          console.log('[Terrena] Loaded', window.TerrenaPermissions.length, 'permissions from server');
        } else {
          console.warn('[Terrena] Failed to load permissions, status:', res.status);
          window.TerrenaPermissionsLoaded = true;
          document.dispatchEvent(new Event('terrena:perms-ready'));
        }
      } catch (e) {
        console.error('[Terrena] Error loading permissions:', e);
        window.TerrenaPermissionsLoaded = true;
        document.dispatchEvent(new Event('terrena:perms-ready'));
      }
    }

    /**
     * Clear cached token and permissions (call on logout)
     */
    window.TerrenaClearAuth = function() {
      sessionStorage.removeItem(STORAGE_TOKEN_KEY);
      sessionStorage.removeItem(STORAGE_PERMS_KEY);
      window.TerrenaApiToken = null;
      window.TerrenaPermissions = [];
      window.TerrenaPermissionsLoaded = false;
      console.log('[Terrena] Auth cache cleared');
    };

    /**
     * Set cached values with timestamp for expiration
     */
    function setCachedValue(key, value) {
      const item = {
        data: value,
        timestamp: Date.now()
      };
      sessionStorage.setItem(key, JSON.stringify(item));
    }

    /**
     * Get cached values with expiration check (24 hours)
     */
    function getCachedValue(key, maxAge = 24 * 60 * 60 * 1000) { // 24 hours default
      try {
        const item = JSON.parse(sessionStorage.getItem(key));
        if (!item || !item.data || !item.timestamp) {
          return null;
        }
        
        const isExpired = Date.now() - item.timestamp > maxAge;
        if (isExpired) {
          sessionStorage.removeItem(key);
          return null;
        }
        
        return item.data;
      } catch (e) {
        sessionStorage.removeItem(key);
        return null;
      }
    }

    // Auto-load on page load for authenticated users (only once per session)
    @auth
    document.addEventListener('DOMContentLoaded', function() {
      TerrenaLoadApiToken().then(() => {
        TerrenaLoadPermissions();
      });
    });
    @endauth
    
    /**
     * Enhanced logout handler that revokes API tokens before session logout
     */
    async function handleTerrenaLogout(event) {
      event.preventDefault();
      
      // Clear auth cache
      if (typeof window.TerrenaClearAuth === 'function') {
        window.TerrenaClearAuth();
      }
      
      // Revoke API token if available
      if (window.TerrenaApiToken) {
        try {
          await fetch("{{ url('/session/api-token/revoke') }}", {
            method: 'POST',
            credentials: 'include',
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
              'Authorization': 'Bearer ' + window.TerrenaApiToken
            }
          });
        } catch (e) {
          console.warn('[Terrena] Could not revoke API token:', e);
          // Continue with logout even if token revocation fails
        }
      }
      
      // Submit the form to perform the actual logout
      document.getElementById('logout-form').submit();
    }
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
      <nav
          class="nav flex-column gap-1"
          x-data="{
              permsLoaded: window.TerrenaPermissionsLoaded || false,
          }"
          x-init="
              // Escuchar evento de permisos listos
              document.addEventListener('terrena:perms-ready', () => {
                  permsLoaded = true;
              });

              // Si los permisos ya están cargados al montar, marcar como listo
              if (window.TerrenaPermissionsLoaded) {
                  permsLoaded = true;
              } else if (typeof getCachedValue === 'function' && getCachedValue(STORAGE_PERMS_KEY)) {
                  // Si hay permisos cacheados, marcar como listo inmediatamente
                  permsLoaded = true;
              }
          "
      >
        {{-- Dashboard (siempre visible) --}}
        <a class="nav-link {{ ($active ?? '') === 'dashboard' ? 'active' : '' }}"
           href="{{ url('/dashboard') }}">
          <i class="fa-solid fa-gauge"></i> <span class="label">Dashboard</span>
        </a>

        {{-- Caja con submenú (Cortes siempre visible, Caja Chica sólo si permiso) --}}
        <div class="nav-item">
          <a class="nav-link {{ in_array($active ?? '', ['caja', 'cortes', 'cajachica']) ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuCaja" role="button" aria-expanded="false">
            <i class="fa-solid fa-cash-register"></i> <span class="label">Caja</span>
            <i class="fa-solid fa-chevron-down ms-auto small"></i>
          </a>
          <div class="collapse {{ in_array($active ?? '', ['caja', 'cortes', 'cajachica']) ? 'show' : '' }} ms-3" id="menuCaja">
            <a class="nav-link submenu-link" href="{{ route('caja.cortes') }}">
              <i class="fa-solid fa-receipt"></i> <span class="label">Cortes de Caja</span>
            </a>
            <a class="nav-link submenu-link"
               href="{{ route('cashfund.index') }}"
               x-show="permsLoaded && window.TerrenaHasPerm('cashfund.manage')"
               x-cloak>
              <i class="fa-solid fa-wallet"></i> <span class="label">Caja Chica</span>
            </a>
          </div>
        </div>

        {{-- Inventario (grupo completo visible sólo si permiso can_manage_purchasing) --}}
        <div class="nav-item"
             x-show="permsLoaded && window.TerrenaHasPerm('can_manage_purchasing')"
             x-cloak>
          <a class="nav-link {{ in_array($active ?? '', ['inventario','items','lots','receptions','alerts','transfers','counts']) ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuInventario" role="button" aria-expanded="false">
            <i class="fa-solid fa-boxes-stacked"></i> <span class="label">Inventario</span>
            <i class="fa-solid fa-chevron-down ms-auto small"></i>
          </a>
          <div class="collapse {{ in_array($active ?? '', ['inventario','items','lots','receptions','alerts','transfers','counts']) ? 'show' : '' }} ms-3" id="menuInventario">
            <a class="nav-link submenu-link" href="{{ route('inv.alerts') }}">
              <i class="fa-solid fa-bell"></i> <span class="label">Alertas</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('inv.receptions') }}">
              <i class="fa-solid fa-dolly"></i> <span class="label">Recepciones</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('inventory.items.index') }}">
              <i class="fa-solid fa-box"></i> <span class="label">Items</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('inv.lots') }}">
              <i class="fa-solid fa-layer-group"></i> <span class="label">Lotes</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('inv.counts.index') }}">
              <i class="fa-solid fa-list-check"></i> <span class="label">Conteos</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('transfers.index') }}">
              <i class="fa-solid fa-arrow-right-arrow-left"></i> <span class="label">Transferencias</span>
            </a>
          </div>
        </div>

        {{-- Compras (requiere can_manage_purchasing) --}}
        <div class="nav-item"
             x-show="permsLoaded && window.TerrenaHasPerm('can_manage_purchasing')"
             x-cloak>
          <a class="nav-link {{ in_array($active ?? '', ['compras','purchasing']) ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuCompras" role="button" aria-expanded="false">
            <i class="fa-solid fa-truck"></i> <span class="label">Compras</span>
            <i class="fa-solid fa-chevron-down ms-auto small"></i>
          </a>
          <div class="collapse {{ in_array($active ?? '', ['compras','purchasing']) ? 'show' : '' }} ms-3" id="menuCompras">
            <a class="nav-link submenu-link" href="{{ route('purchasing.requests.index') }}">
              <i class="fa-solid fa-file-circle-plus"></i> <span class="label">Solicitudes</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('purchasing.orders.index') }}">
              <i class="fa-solid fa-file-invoice-dollar"></i> <span class="label">Órdenes</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('purchasing.replenishment.dashboard') }}">
              <i class="fa-solid fa-rotate"></i> <span class="label">Reposición</span>
            </a>
          </div>
        </div>

        {{-- Recetas (can_view_recipe_dashboard) --}}
        <a class="nav-link {{ ($active ?? '') === 'recetas' ? 'active' : '' }}"
           href="{{ route('rec.index') }}"
           x-show="permsLoaded && window.TerrenaHasPerm('can_view_recipe_dashboard')"
           x-cloak>
          <i class="fa-solid fa-bowl-food"></i> <span class="label">Recetas</span>
        </a>

        {{-- Producción (can_edit_production_order) --}}
        <a class="nav-link {{ ($active ?? '') === 'produccion' ? 'active' : '' }}"
           href="{{ url('/produccion') }}"
           x-show="permsLoaded && window.TerrenaHasPerm('can_edit_production_order')"
           x-cloak>
          <i class="fa-solid fa-industry"></i> <span class="label">Producción</span>
        </a>

        {{-- Reportes (reports.view) --}}
        <a class="nav-link {{ ($active ?? '') === 'reportes' ? 'active' : '' }}"
           href="{{ url('/reportes') }}"
           x-show="permsLoaded && window.TerrenaHasPerm('reports.view')"
           x-cloak>
          <i class="fa-solid fa-chart-column"></i> <span class="label">Reportes</span>
        </a>

        {{-- Configuración / Catálogos --}}
        @can('admin.access')
        <div class="nav-item">
          <a class="nav-link {{ in_array($active ?? '', ['catalogos','config']) ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuConfig" role="button" aria-expanded="false">
            <i class="fa-solid fa-gear"></i> <span class="label">Configuración</span>
            <i class="fa-solid fa-chevron-down ms-auto small"></i>
          </a>
          <div class="collapse {{ in_array($active ?? '', ['catalogos','config']) ? 'show' : '' }} ms-3" id="menuConfig">
            <a class="nav-link submenu-link" href="{{ url('/catalogos') }}">
              <i class="fa-solid fa-database"></i> <span class="label">Catálogos</span>
            </a>
            <a class="nav-link submenu-link" href="{{ url('/profile') }}">
              <i class="fa-solid fa-user-gear"></i> <span class="label">Perfil</span>
            </a>
          </div>
        </div>
        @endcan

        {{-- Personal (gestión RRHH / permisos) --}}
        @can('people.view')
        <a class="nav-link {{ ($active ?? '') === 'personal' ? 'active' : '' }}"
           href="{{ url('/personal') }}">
          <i class="fa-solid fa-users"></i> <span class="label">Personal</span>
        </a>
        @endcan

        {{-- Auditoría Operacional --}}
        <a class="nav-link {{ ($active ?? '') === 'audit-log' ? 'active' : '' }}"
           href="{{ route('audit.log.index') }}"
           x-show="permsLoaded && window.TerrenaHasPerm('audit.view')"
           x-cloak>
          <i class="fa-solid fa-clipboard-list"></i> <span class="label">Auditoría</span>
        </a>

        {{-- KDS (mostrar si tiene kitchen.view_kds o permisos de producción) --}}
        <a class="nav-link {{ ($active ?? '') === 'kds' ? 'active' : '' }}"
           href="{{ route('kds.board') }}"
           x-show="permsLoaded && (window.TerrenaHasPerm('kitchen.view_kds') || window.TerrenaHasPerm('can_edit_production_order'))"
           x-cloak>
          <i class="fa-solid fa-desktop"></i> <span class="label">KDS</span>
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
                <form id="logout-form" method="POST" action="{{ route('logout') }}" 
                      onsubmit="handleTerrenaLogout(event)">
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

  {{-- Persistencia del estado de los collapse del sidebar --}}
  <script>
  (function() {
    const STORAGE_KEY = 'terrena_sidebar_collapses';

    // Restaurar estado de collapse al cargar
    function restoreCollapseStates() {
      try {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (!saved) return;

        const states = JSON.parse(saved);
        Object.keys(states).forEach(id => {
          const el = document.getElementById(id);
          if (el && states[id]) {
            el.classList.add('show');
          }
        });
      } catch (e) {
        console.warn('[Terrena] Error restaurando estado de collapse:', e);
      }
    }

    // Guardar estado de collapse
    function saveCollapseStates() {
      try {
        const states = {};
        ['menuCaja', 'menuInventario', 'menuCompras', 'menuConfig'].forEach(id => {
          const el = document.getElementById(id);
          if (el) {
            states[id] = el.classList.contains('show');
          }
        });
        localStorage.setItem(STORAGE_KEY, JSON.stringify(states));
      } catch (e) {
        console.warn('[Terrena] Error guardando estado de collapse:', e);
      }
    }

    // Escuchar cambios en collapse
    document.addEventListener('DOMContentLoaded', () => {
      restoreCollapseStates();

      // Observar cambios en collapse
      ['menuCaja', 'menuInventario', 'menuCompras', 'menuConfig'].forEach(id => {
        const el = document.getElementById(id);
        if (el) {
          el.addEventListener('shown.bs.collapse', saveCollapseStates);
          el.addEventListener('hidden.bs.collapse', saveCollapseStates);
        }
      });
    });
  })();
  </script>

  @stack('scripts')
</body>
</html>
