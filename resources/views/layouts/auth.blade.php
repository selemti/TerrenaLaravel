<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Acceder a TerrenaPOS' }}</title>
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <link href="{{ asset('assets/css/bootstrap.min.css') }}" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('assets/fontawesome-free-7.0.1-web/css/all.min.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/css/terrena.css') }}">
    <style>
        body.auth-layout {
            min-height: 100vh;
            background: var(--green-darker, #1E3A2A);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem 1rem;
        }

        .auth-card {
            background: #ffffff;
            border-radius: 1rem;
            box-shadow: 0 20px 45px rgba(0, 0, 0, 0.25);
            max-width: 420px;
            width: 100%;
            padding: 2.5rem 2.25rem;
        }

        .auth-logo {
            height: 64px;
        }
    </style>
    @stack('styles')
</head>
<body class="auth-layout">
    <main class="auth-card">
        <div class="text-center mb-4">
            <img src="{{ asset('assets/img/logo.svg') }}" alt="Terrena" class="auth-logo">
        </div>

        @isset($slot)
            {{ $slot }}
        @else
            @yield('content')
        @endisset
    </main>

    <script src="{{ asset('assets/js/bootstrap.bundle.min.js') }}"></script>
    @stack('scripts')
</body>
</html>
