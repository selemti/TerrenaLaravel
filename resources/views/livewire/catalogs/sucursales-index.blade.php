<x-app-layout>
  <div class="p-6 space-y-4">
    <h1 class="text-xl font-bold">Catálogo · Sucursales</h1>

    @if (session('ok'))
      <div class="p-2 bg-green-100 border border-green-300 rounded">{{ session('ok') }}</div>
    @endif

    <div class="flex items-center gap-2">
      <input type="text" wire:model.live.debounce.300ms="search" placeholder="Buscar..."
             class="border rounded px-3 py-2">
      <button wire:click="create" class="px-3 py-2 bg-blue-600 text-white rounded">Nueva</button>
    </div>

    <div class="grid md:grid-cols-3 gap-4">
      <div class="border rounded p-4">
        <h2 class="font-semibold mb-2">{{ $editId ? 'Editar' : 'Crear' }}</h2>
        <div class="space-y-2">
          <label class="block">Clave
            <input type="text" wire:model="clave" class="border rounded px-3 py-2 w-full">
            @error('clave') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
          </label>
          <label class="block">Nombre
            <input type="text" wire:model="nombre" class="border rounded px-3 py-2 w-full">
            @error('nombre') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
          </label>
          <label class="block">Ubicación
            <input type="text" wire:model="ubicacion" class="border rounded px-3 py-2 w-full">
          </label>
          <label class="inline-flex items-center gap-2">
            <input type="checkbox" wire:model="activo"> Activo
          </label>
          <div class="flex gap-2">
            <button wire:click="save" class="px-3 py-2 bg-emerald-600 text-white rounded">Guardar</button>
            <button wire:click="create" class="px-3 py-2 bg-gray-200 rounded">Cancelar</button>
          </div>
        </div>
      </div>

      <div class="md:col-span-2 border rounded overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead class="bg-gray-50">
            <tr>
              <th class="p-2 text-left">Clave</th>
              <th class="p-2 text-left">Nombre</th>
              <th class="p-2 text-left">Ubicación</th>
              <th class="p-2 text-left">Activo</th>
              <th class="p-2 text-right">Acciones</th>
            </tr>
          </thead>
          <tbody>
            @foreach ($rows as $r)
            <tr class="border-t">
              <td class="p-2">{{ $r->clave }}</td>
              <td class="p-2">{{ $r->nombre }}</td>
              <td class="p-2">{{ $r->ubicacion }}</td>
              <td class="p-2">{{ $r->activo ? 'Sí' : 'No' }}</td>
              <td class="p-2 text-right">
                <button wire:click="edit({{ $r->id }})" class="px-2 py-1 bg-indigo-600 text-white rounded">Editar</button>
                <button wire:click="delete({{ $r->id }})" class="px-2 py-1 bg-rose-600 text-white rounded"
                        onclick="return confirm('¿Eliminar sucursal?')">Eliminar</button>
              </td>
            </tr>
            @endforeach
          </tbody>
        </table>
        <div class="p-2">
          {{ $rows->links() }}
        </div>
      </div>
    </div>
  </div>
</x-app-layout>
