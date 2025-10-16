<!DOCTYPE html>
<html lang="es" data-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>@yield('title', 'Terrena')</title>

  <meta name="csrf-token" content="{{ csrf_token() }}">
  {{-- Base de la app para JS "guard" --}}
  <meta name="app-base" content="{{ rtrim(url('/'), '/') }}/">

  {{-- CSS locales --}}
  <link rel="icon" href="{{ asset('assets/img/favicon.ico') }}">
  <link rel="stylesheet" href="{{ asset('assets/css/bootstrap.min.css') }}">
  <link rel="stylesheet" href="{{ asset('assets/css/all.min.css') }}"> {{-- Font Awesome --}}
  <link rel="stylesheet" href="{{ asset('assets/css/terrena.css') }}">

  @stack('head')
</head>
<body class="min-vh-100 d-flex flex-column">

  <nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow-sm">
    <div class="container-fluid">
      <a class="navbar-brand d-flex align-items-center gap-2" href="{{ url('/') }}">
        <img src="{{ asset('assets/img/logo.svg') }}" alt="Terrena" height="24">
        <span>Terrena</span>
      </a>

      <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#terrenaNav">
        <span class="navbar-toggler-icon"></span>
      </button>

      <div class="collapse navbar-collapse" id="terrenaNav">
        <ul class="navbar-nav me-auto">
          <li class="nav-item">
            <a class="nav-link" href="{{ route('dashboard') }}">
              <i class="fa-solid fa-gauge-high me-1"></i> Dashboard
            </a>
          </li>
        </ul>
        <ul class="navbar-nav ms-auto">
          @auth
            <li class="nav-item">
              <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button class="btn btn-outline-light btn-sm">
                  <i class="fa-solid fa-right-from-bracket me-1"></i> Salir
                </button>
              </form>
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

  <main class="flex-fill py-3">
    <div class="container">
      @yield('content')
      {{ $slot ?? '' }}
    </div>
  </main>

  <footer class="bg-light border-top py-2">
    <div class="container small text-muted d-flex justify-content-between">
      <span>Terrena — 2025</span>
      <span>Sistema de operaciones para restaurante</span>
    </div>
  </footer>

  {{-- JS locales --}}
  <script src="{{ asset('assets/js/bootstrap.bundle.min.js') }}"></script>

  {{-- GUARD: evita salirte a http://localhost/... corrigiendo href="/..." --}}
  <script>
  (function(){
    const BASE = (document.querySelector('meta[name="app-base"]')?.content || '').replace(/\/+$/, '') + '/';
    function toAppUrl(href) {
      if (!href) return href;
      // deja intactos http(s)://, mailto:, tel:, #
      if (/^(https?:|mailto:|tel:|#)/i.test(href)) return href;
      // si empieza con /  -> conviértelo a BASE + (sin / delante)
      if (href.startsWith('/')) return BASE + href.replace(/^\/+/, '');
      return href;
    }
    document.addEventListener('click', function(e){
      const a = e.target.closest('a[href]');
      if (!a) return;
      const fixed = toAppUrl(a.getAttribute('href'));
      if (fixed && fixed !== a.getAttribute('href')) {
        e.preventDefault(); window.location.assign(fixed);
      }
    }, true);

    // Corrige actions absolutos en formularios
    document.querySelectorAll('form[action^="/"]').forEach(f => {
      f.setAttribute('action', toAppUrl(f.getAttribute('action')));
    });
  })();
  </script>

  @stack('scripts')
</body>
</html>
