<!-- resources/views/layouts/sidebar.blade.php -->
<aside class="w-64 bg-gray-800 text-white flex-shrink-0 overflow-y-auto">
    <div class="flex items-center justify-center p-4 h-16 border-b border-gray-700">
        <a href="{{ route('dashboard') }}" class="flex items-center">
            <x-application-logo class="block h-9 w-auto fill-current" />
            <span class="ml-3 font-semibold text-lg">Terrena</span>
        </a>
    </div>

    <nav class="mt-4">
        <span class="px-4 text-xs text-gray-400 uppercase tracking-wider">Principal</span>
        <a href="{{ route('dashboard') }}" class="flex items-center mt-2 py-2 px-4 text-gray-300 hover:bg-gray-700 hover:text-white {{ request()->routeIs('dashboard') ? 'bg-gray-900' : '' }}">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path></svg>
            <span class="ml-3">Dashboard</span>
        </a>

        <span class="px-4 mt-6 text-xs text-gray-400 uppercase tracking-wider">Módulos</span>
        
        <!-- Inventario -->
        <a href="{{ route('inventory.items.index') }}" class="flex items-center mt-2 py-2 px-4 text-gray-300 hover:bg-gray-700 hover:text-white {{ request()->routeIs('inventory.*') || request()->routeIs('inv.*') ? 'bg-gray-900' : '' }}">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"></path></svg>
            <span class="ml-3">Inventario</span>
        </a>

        <!-- Compras -->
        <a href="{{ route('purchasing.requests.index') }}" class="flex items-center mt-2 py-2 px-4 text-gray-300 hover:bg-gray-700 hover:text-white {{ request()->routeIs('purchasing.*') ? 'bg-gray-900' : '' }}">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
            <span class="ml-3">Compras</span>
        </a>

        <!-- Recetas -->
        <a href="{{ route('rec.index') }}" class="flex items-center mt-2 py-2 px-4 text-gray-300 hover:bg-gray-700 hover:text-white {{ request()->routeIs('rec.*') ? 'bg-gray-900' : '' }}">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v11.494m-9-5.747h18"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 3.101l.001 17.798m4.5-17.798l-.001 17.798"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 21.75c-4.83 0-8.75-3.92-8.75-8.75S7.17 4.25 12 4.25s8.75 3.92 8.75 8.75-3.92 8.75-8.75 8.75z"></path></svg>
            <span class="ml-3">Recetas</span>
        </a>

        <!-- Caja Chica -->
        <a href="{{ route('cashfund.index') }}" class="flex items-center mt-2 py-2 px-4 text-gray-300 hover:bg-gray-700 hover:text-white {{ request()->routeIs('cashfund.*') ? 'bg-gray-900' : '' }}">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
            <span class="ml-3">Caja Chica</span>
        </a>

        <span class="px-4 mt-6 text-xs text-gray-400 uppercase tracking-wider">Configuración</span>
        
        <!-- Catálogos -->
        <a href="{{ route('catalogos.index') }}" class="flex items-center mt-2 py-2 px-4 text-gray-300 hover:bg-gray-700 hover:text-white {{ request()->routeIs('cat.*') ? 'bg-gray-900' : '' }}">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16"></path></svg>
            <span class="ml-3">Catálogos</span>
        </a>

        <!-- Personal -->
        <a href="{{ route('personal') }}" class="flex items-center mt-2 py-2 px-4 text-gray-300 hover:bg-gray-700 hover:text-white {{ request()->routeIs('personal') ? 'bg-gray-900' : '' }}">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M15 21a6 6 0 00-9-5.197m0 0A5.978 5.978 0 0112 13a5.979 5.979 0 013 1.003m-3-1.003A4.002 4.002 0 0112 4.354M12 4.354a4 4 0 100 5.292m0 0a4 4 0 100 5.292m0 0a4 4 0 100 5.292"></path></svg>
            <span class="ml-3">Personal</span>
        </a>

        <!-- Auditoría -->
        @can('audit.view')
        <a href="{{ route('audit.log.index') }}" class="flex items-center mt-2 py-2 px-4 text-gray-300 hover:bg-gray-700 hover:text-white {{ request()->routeIs('audit.*') ? 'bg-gray-900' : '' }}">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
            <span class="ml-3">Auditoría</span>
        </a>
        @endcan

    </nav>
</aside>