{{-- resources/views/layouts/app.blade.php --}}
<!DOCTYPE html>
<html lang="es" class="h-full bg-gray-50">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{{ $title ?? 'Selemti' }}</title>

    @vite(['resources/css/app.css','resources/js/app.js'])
    @livewireStyles
</head>
<body class="h-full">
<div class="min-h-screen flex">
    {{-- Sidebar --}}
    @include('partials.sidebar')

    {{-- Main --}}
    <div class="flex-1 flex flex-col min-h-screen">
        {{-- Topbar --}}
        <header class="bg-white shadow px-4 py-3 flex items-center justify-between">
            <div>
                <h1 class="text-lg font-semibold">
                    {{ $header ?? 'Panel' }}
                </h1>
                @isset($subheader)
                    <p class="text-sm text-gray-500">{{ $subheader }}</p>
                @endisset
            </div>
            <div class="text-sm text-gray-600">
                {{-- Aquí puedes poner el usuario o acciones rápidas --}}
                <a href="{{ route('home') }}" class="hover:underline">Inicio</a>
            </div>
        </header>

        {{-- Content --}}
        <main class="p-4">
            {{ $slot ?? '' }}
            {{-- Soporte para vistas “antiguas” que hacen @extends('layouts.app') / @section('content') --}}
            @yield('content')
        </main>
    </div>
</div>

@livewireScripts
@stack('scripts')
</body>
</html>
