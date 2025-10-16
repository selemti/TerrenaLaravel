<x-app-layout>
  <div class="p-6 space-y-4">
    <h1 class="text-xl font-bold">Políticas de Stock (Min/Max/Reorden)</h1>

    @if (session('ok'))
      <div class="p-2 bg-green-100 border border-green-300 rounded">{{ session('ok') }}</div>
    @endif

    <div class="flex items-center gap-2">
      <input type="text" wire:model.live.debounce.300ms="search" placeholder="Buscar (item/sucursal)..."
             class="border rounded px-3 py-2">
      <button wire:click="create" class="px-3 py-2 bg-blue-600 text-white rounded">Nueva</button>
    </div>

    <div class="grid md:grid-cols-3 gap-4">
      <div class="border rounded p-4">
        <h2 class="font-semibold mb-2">{{ $editId ? 'Editar' : 'Crear' }}</h2>
        <div class="space-y-2">
          <label class="block">Item
            <select wire:model="item_id" class="border rounded px-3 py-2 w-full">
              <option value="">-- Selecciona --</option>
              @foreach ($items as $it)
                <option value="{{ $it->id }}">{{ $it->name }}</option>
              @endforeach
            </select>
            @error('item_id') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
          </label>
          <label class="block">Sucursal
            <select wire:model="sucursal_id" class="border rounded px-3 py-2 w-full">
              <option value="">-- Selecciona --</option>
              @foreach ($sucursales as $s)
                <option value="{{ $s->id }}">{{ $s->nombre }}</option>
              @endforeach
            </select>
            @error('sucursal_id') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
          </label>
          <label class="block">Mínimo
            <input type="number" step="0.0001" wire:model="min_qty" class="border rounded px-3 py-2 w-full">
            @error('min_qty') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
          </label>
          <label class="block">Máximo
            <input type="number" step="0.0001" wire:model="max_qty" class="border rounded px-3 py-2 w-full">
            @error('max_qty') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
          </label>
          <label class="block">Reorden
            <input type="number" step="0.0001" wire:model="reorder_qty" class="border rounded px-3 py-2 w-full">
            @error('reorder_qty') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
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
              <th class="p-2 text-left">Item</th>
              <th class="p-2 text-left">Sucursal</th>
              <th class="p-2 text-right">Mín</th>
              <th class="p-2 text-right">Máx</th>
              <th class="p-2 text-right">Reorden</th>
              <th class="p-2 text-left">Activo</th>
              <th class="p-2 text-right">Acciones</th>
            </tr>
          </thead>
          <tbody>
            @foreach ($rows as $r)
            <tr class="border-t">
              <td class="p-2">{{ $r->item }}</td>
              <td class="p-2">{{ $r->sucursal }}</td>
              <td class="p-2 text-right">{{ $r->min_qty }}</td>
              <td class="p-2 text-right">{{ $r->max_qty }}</td>
              <td class="p-2 text-right">{{ $r->reorder_qty }}</td>
              <td class="p-2">{{ $r->activo ? 'Sí' : 'No' }}</td>
              <td class="p-2 text-right">
                <button wire:click="edit({{ $r->id }})" class="px-2 py-1 bg-indigo-600 text-white rounded">Editar</button>
                <button wire:click="delete({{ $r->id }})" class="px-2 py-1 bg-rose-600 text-white rounded"
                        onclick="return confirm('¿Eliminar política?')">Eliminar</button>
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
