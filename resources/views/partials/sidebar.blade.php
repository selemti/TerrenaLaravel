{{-- resources/views/partials/sidebar.blade.php --}}
<aside class="w-64 bg-white border-r min-h-screen">
    <div class="px-4 py-4 border-b">
        <a href="{{ route('home') }}" class="text-xl font-bold">Selemti</a>
        <div class="text-xs text-gray-500">v0.1 (UI)</div>
    </div>

    <nav class="p-3 space-y-1 text-sm">
        <div class="px-2 pt-2 pb-1 text-gray-500 uppercase text-xs">Catálogos</div>
        <a href="{{ route('cat.unidades') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Unidades</a>
        <a href="{{ route('cat.uom') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Conversiones UOM</a>
        <a href="{{ route('cat.almacenes') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Almacenes</a>
        <a href="{{ route('cat.proveedores') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Proveedores</a>
        <a href="{{ route('cat.sucursales') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Sucursales</a>
        <a href="{{ route('cat.stockpolicy') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Políticas de Stock</a>

        <div class="px-2 pt-4 pb-1 text-gray-500 uppercase text-xs">Inventario</div>
        <a href="{{-- route('inventory.items.index') --}}" class="block px-3 py-2 rounded hover:bg-gray-100">Items</a>
        <a href="{{ route('inv.receptions') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Recepciones</a>
        <a href="{{ route('inv.receptions.new') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Nueva Recepción</a>
        <a href="{{ route('inv.lots') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Lotes</a>

        <div class="px-2 pt-4 pb-1 text-gray-500 uppercase text-xs">Recetas</div>
        <a href="{{ route('rec.index') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Listado</a>
        <a href="{{ route('rec.editor') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Editor</a>

        <div class="px-2 pt-4 pb-1 text-gray-500 uppercase text-xs">KDS</div>
        <a href="{{ route('kds.board') }}" class="block px-3 py-2 rounded hover:bg-gray-100">Tablero</a>
    </nav>
</aside>
