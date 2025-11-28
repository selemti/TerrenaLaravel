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
  <link rel="stylesheet" href="{{ asset('assets/css/design-system.css') }}">
  <link rel="stylesheet" href="{{ asset('assets/css/utilities.css') }}">
  <link rel="stylesheet" href="{{ asset('assets/css/caja.css') }}">

  @livewireStyles
  @stack('styles')
</head>
<body>
  <div class="container-fluid p-0 d-flex flex-column" style="min-height:100vh">
    <div class="d-flex flex-grow-1">

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
          <div class="collapse {{ in_array($active ?? '', ['caja', 'cortes', 'cajachica', 'aprobaciones']) ? 'show' : '' }} ms-3" id="menuCaja">
            <a class="nav-link submenu-link" href="{{ route('caja.cortes') }}">
              <i class="fa-solid fa-receipt"></i> <span class="label">Cortes de Caja</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('caja.historico') }}">
              <i class="fa-solid fa-clock-rotate-left"></i> <span class="label">Histórico de Cortes</span>
            </a>
            <a class="nav-link submenu-link"
               href="{{ route('caja.aprobaciones') }}"
               x-show="permsLoaded && window.TerrenaHasPerm('aprobar-cortes-irregulares')"
               x-cloak>
              <i class="fa-solid fa-user-check"></i> <span class="label">Aprobaciones</span>
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
        <div class="nav-item"
             x-show="permsLoaded && window.TerrenaHasPerm('reports.view')"
             x-cloak>
          <a class="nav-link {{ in_array($active ?? '', ['reportes','reports']) ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuReportes" role="button" aria-expanded="false">
            <i class="fa-solid fa-chart-column"></i> <span class="label">Reportes</span>
            <i class="fa-solid fa-chevron-down ms-auto small"></i>
          </a>
          <div class="collapse {{ in_array($active ?? '', ['reportes','reports']) ? 'show' : '' }} ms-3" id="menuReportes">
            <a class="nav-link submenu-link" href="{{ route('reports.dashboard') }}">
              <i class="fa-solid fa-gauge-high"></i> <span class="label">Dashboard ERP</span>
            </a>
            <div class="border-top my-1"></div>
            <div class="text-muted small ps-3 mb-1" style="font-size: 0.75rem;">VENTAS</div>
            <a class="nav-link submenu-link" href="{{ route('reports.sales') }}">
              <i class="fa-solid fa-clipboard-list"></i> <span class="label">Centro de Ventas</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.mix') }}">
              <i class="fa-solid fa-chart-pie"></i> <span class="label">Mix de Ventas</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.summary') }}">
              <i class="fa-solid fa-table"></i> <span class="label">Resumen de Ventas</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.detail') }}">
              <i class="fa-solid fa-list"></i> <span class="label">Detalle de Ventas</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.balance') }}">
              <i class="fa-solid fa-wallet"></i> <span class="label">Balance por Forma de Pago</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.exceptions') }}">
              <i class="fa-solid fa-triangle-exclamation"></i> <span class="label">Excepciones</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.journal') }}">
              <i class="fa-solid fa-book"></i> <span class="label">Journal</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.drawer') }}">
              <i class="fa-solid fa-cash-register"></i> <span class="label">Cajón vs Efectivo</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.diagnostics') }}">
              <i class="fa-solid fa-stethoscope"></i> <span class="label">Diagnósticos diarios</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.tickets.open') }}">
              <i class="fa-solid fa-ticket"></i> <span class="label">Cuentas Abiertas/Pagadas</span>
            </a>
            <div class="border-top my-1"></div>
            <div class="text-muted small ps-3 mb-1" style="font-size: 0.75rem;">MENÚ</div>
            <a class="nav-link submenu-link" href="{{ route('reports.menu.usage') }}">
              <i class="fa-solid fa-utensils"></i> <span class="label">Uso de Menú</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('reports.sales.mods') }}">
              <i class="fa-solid fa-bowl-food"></i> <span class="label">Ítems + Modificadores</span>
            </a>
          </div>
        </div>

        {{-- Configuración / Catálogos --}}
        @can('admin.access')
        <div class="nav-item">
          <a class="nav-link {{ in_array($active ?? '', ['catalogos','config','admin']) ? 'active' : '' }}"
             data-bs-toggle="collapse" href="#menuConfig" role="button" aria-expanded="false">
            <i class="fa-solid fa-gear"></i> <span class="label">Configuración</span>
            <i class="fa-solid fa-chevron-down ms-auto small"></i>
          </a>
          <div class="collapse {{ in_array($active ?? '', ['catalogos','config','admin']) ? 'show' : '' }} ms-3" id="menuConfig">
            <a class="nav-link submenu-link" href="{{ url('/catalogos') }}">
              <i class="fa-solid fa-database"></i> <span class="label">Catálogos</span>
            </a>
            <a class="nav-link submenu-link" href="{{ route('admin.tickets.management') }}">
              <i class="fa-solid fa-ticket"></i> <span class="label">Gestión de Tickets</span>
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
                <a href="{{ route('reports.dashboard') }}" class="link-more small">Ver todas <i class="fa-solid fa-chevron-right ms-1"></i></a>
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
    </main>
    </div>

    {{-- Footer / Status Bar --}}
    @auth
    <footer class="status-bar">
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
  </div>

  {{-- JS al final (mismo orden que legacy) --}}
  <script src="{{ asset('assets/js/bootstrap.bundle.min.js') }}"></script>

  {{-- Inicialización global de tooltips de Bootstrap --}}
  <script>
  (function() {
    /**
     * Inicializa todos los tooltips de Bootstrap en la página
     * Destruye tooltips existentes primero para evitar duplicados
     * Se ejecuta automáticamente al cargar la página y expone una función global
     * para reinicializar cuando se carga contenido dinámico
     */
    function initTooltips() {
      // Destruir tooltips existentes para evitar duplicados
      const existingTooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
      existingTooltips.forEach(function(el) {
        const existingTooltip = bootstrap.Tooltip.getInstance(el);
        if (existingTooltip) {
          existingTooltip.dispose();
        }
      });

      // Inicializar tooltips con configuración estandarizada
      const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
      tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl, {
          trigger: 'hover focus',
          html: false,
          animation: true,
          delay: { show: 300, hide: 100 }
        });
      });
    }

    // Inicializar al cargar el DOM
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initTooltips);
    } else {
      initTooltips();
    }

    // Exponer función global para reinicializar tooltips después de cargar contenido dinámico
    window.TerrenaInitTooltips = initTooltips;

    // Reinicializar tooltips después de eventos de Livewire
    document.addEventListener('livewire:navigated', initTooltips);
    document.addEventListener('livewire:load', initTooltips);
  })();
  </script>

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
        ['menuCaja', 'menuReportes', 'menuInventario', 'menuCompras', 'menuConfig'].forEach(id => {
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
      ['menuCaja', 'menuReportes', 'menuInventario', 'menuCompras', 'menuConfig'].forEach(id => {
        const el = document.getElementById(id);
        if (el) {
          el.addEventListener('shown.bs.collapse', saveCollapseStates);
          el.addEventListener('hidden.bs.collapse', saveCollapseStates);
        }
      });
    });
  })();
  </script>

  {{-- Sistema de Alertas en Navbar --}}
  <script>
  (function() {
    const ALERTS_POLL_INTERVAL = 30000; // 30 seconds
    let pollTimer = null;

    // Get base path from window.__BASE__ variable
    const basePath = window.__BASE__ || '';

    // Elements
    const badgeEl = document.getElementById('hdr-alerts-badge');
    const listEl = document.getElementById('hdr-alerts-list');
    const dropdownBtn = document.querySelector('[data-bs-toggle="dropdown"]')?.closest('.dropdown');

    if (!badgeEl || !listEl) {
      console.warn('[Terrena Alerts] Badge or list elements not found');
      return;
    }

    /**
     * Fetch alerts count from API
     */
    async function fetchAlertsCount() {
      try {
        const response = await fetch(basePath + '/api/caja/alertas/count', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          }
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();

        if (data.ok && typeof data.count === 'number') {
          updateBadge(data.count);
        }
      } catch (error) {
        console.error('[Terrena Alerts] Error fetching count:', error);
        // Don't show error to user, just log it
      }
    }

    /**
     * Update badge with count
     */
    function updateBadge(count) {
      if (count > 0) {
        badgeEl.textContent = count > 99 ? '99+' : count;
        badgeEl.classList.remove('d-none');
        badgeEl.classList.add('d-inline-block');
      } else {
        badgeEl.textContent = '0';
        badgeEl.classList.add('d-none');
        badgeEl.classList.remove('d-inline-block');
      }
    }

    /**
     * Fetch recent alerts from API
     */
    async function fetchRecentAlerts() {
      try {
        const response = await fetch(basePath + '/api/caja/alertas?limit=10', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          }
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();

        if (data.ok && Array.isArray(data.data)) {
          renderAlerts(data.data);
        }
      } catch (error) {
        console.error('[Terrena Alerts] Error fetching alerts:', error);
        listEl.innerHTML = '<div class="px-3 py-3 text-muted small text-center">Error al cargar alertas</div>';
      }
    }

    /**
     * Render alerts in dropdown
     */
    function renderAlerts(alerts) {
      if (!alerts || alerts.length === 0) {
        listEl.innerHTML = '<div class="px-3 py-3 text-muted small text-center">No hay alertas pendientes</div>';
        return;
      }

      const html = alerts.map(alert => {
        const icon = getAlertIcon(alert.tipo);
        const color = getAlertColor(alert.tipo);
        const time = formatTime(alert.creado_en);
        const unread = !alert.leido_en;

        return `
          <a href="${getAlertLink(alert)}"
             class="dropdown-item py-2 px-3 ${unread ? 'bg-light' : ''}"
             data-alert-id="${alert.id}"
             onclick="markAsRead(${alert.id})">
            <div class="d-flex align-items-start">
              <div class="flex-shrink-0 me-2">
                <i class="${icon} ${color}"></i>
              </div>
              <div class="flex-grow-1">
                <div class="small fw-semibold">${escapeHtml(alert.titulo)}</div>
                <div class="small text-muted">${escapeHtml(alert.mensaje)}</div>
                <div class="small text-muted mt-1">${time}</div>
              </div>
              ${unread ? '<span class="badge bg-primary rounded-pill">Nuevo</span>' : ''}
            </div>
          </a>
        `;
      }).join('');

      listEl.innerHTML = html;
    }

    /**
     * Get icon for alert type
     */
    function getAlertIcon(tipo) {
      switch (tipo) {
        case 'REQUIERE_APROBACION':
          return 'fa-solid fa-exclamation-triangle';
        case 'APROBADO':
          return 'fa-solid fa-check-circle';
        case 'RECHAZADO':
          return 'fa-solid fa-times-circle';
        default:
          return 'fa-solid fa-bell';
      }
    }

    /**
     * Get color for alert type
     */
    function getAlertColor(tipo) {
      switch (tipo) {
        case 'REQUIERE_APROBACION':
          return 'text-warning';
        case 'APROBADO':
          return 'text-success';
        case 'RECHAZADO':
          return 'text-danger';
        default:
          return 'text-primary';
      }
    }

    /**
     * Get link for alert
     */
    function getAlertLink(alert) {
      if (alert.tipo === 'REQUIERE_APROBACION') {
        return basePath + '/caja/cortes/aprobaciones';
      }
      // For APROBADO/RECHAZADO, could link to cashier's own cortes
      return basePath + '/caja/mis-cortes';
    }

    /**
     * Format time (relative or absolute)
     */
    function formatTime(dateStr) {
      if (!dateStr) return '';

      const date = new Date(dateStr);
      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.floor(diffMs / 60000);

      if (diffMins < 1) return 'Ahora';
      if (diffMins < 60) return `Hace ${diffMins} min`;

      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `Hace ${diffHours}h`;

      const diffDays = Math.floor(diffHours / 24);
      if (diffDays < 7) return `Hace ${diffDays}d`;

      return date.toLocaleDateString('es-MX', { month: 'short', day: 'numeric' });
    }

    /**
     * Escape HTML to prevent XSS
     */
    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    /**
     * Mark alert as read
     */
    window.markAsRead = async function(alertId) {
      try {
        await fetch(`${basePath}/api/caja/alertas/${alertId}/marcar-leido`, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          }
        });

        // Refresh count after marking as read
        setTimeout(() => fetchAlertsCount(), 500);
      } catch (error) {
        console.error('[Terrena Alerts] Error marking as read:', error);
      }
    };

    /**
     * Initialize alerts system
     */
    function init() {
      // Fetch count on page load
      fetchAlertsCount();

      // Fetch alerts when dropdown is opened
      if (dropdownBtn) {
        dropdownBtn.addEventListener('show.bs.dropdown', () => {
          fetchRecentAlerts();
        });
      }

      // Poll for new alerts every 30 seconds
      pollTimer = setInterval(fetchAlertsCount, ALERTS_POLL_INTERVAL);
    }

    // Start on DOM ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', init);
    } else {
      init();
    }

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
      if (pollTimer) clearInterval(pollTimer);
    });
  })();
  </script>

  @stack('scripts')
</body>
</html>
