<div class="p-6 max-w-7xl mx-auto">
  <h1 class="text-2xl font-semibold mb-4">{{ $title }}</h1>

  @if (session('ok'))
    <div class="mb-3 rounded bg-green-100 border border-green-200 text-green-800 px-3 py-2">
      {{ session('ok') }}
    </div>
  @endif

  {{-- Filtros y acciones --}}
  <div class="flex flex-col sm:flex-row sm:items-center gap-3 mb-4">
    <div class="flex items-center gap-2">
      <input type="text" class="border rounded px-3 py-2 w-64"
             placeholder="Buscar…"
             wire:model.live.debounce.300ms="search" />
      <select class="border rounded px-2 py-2" wire:model.live="perPage">
        <option value="10">10</option><option value="25">25</option><option value="50">50</option>
      </select>
    </div>
    <div class="ml-auto">
      <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded"
              wire:click="createNew">+ Nuevo</button>
    </div>
  </div>

  {{-- Tabla --}}
  <div class="overflow-x-auto border rounded">
    <table class="min-w-full text-sm">
      <thead class="bg-gray-50">
        <tr>
          @foreach ($columns as $col)
            <th class="text-left px-3 py-2">{{ $col['label'] }}</th>
          @endforeach
          <th class="text-right px-3 py-2">Acciones</th>
        </tr>
      </thead>
      <tbody>
      @forelse ($rows as $r)
        <tr class="border-t">
          @foreach ($columns as $col)
            @php
              $value = data_get($r, $col['field']);
            @endphp
            <td class="px-3 py-2">
              @switch($col['type'] ?? 'text')
                @case('boolean')
                  <span class="px-2 py-1 rounded {{ $value ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600' }}">
                    {{ $value ? 'Sí' : 'No' }}
                  </span>
                @break
                @case('badge')
                  <span class="px-2 py-1 rounded bg-gray-100 text-gray-700">{{ $value }}</span>
                @break
                @default
                  {{ $value }}
              @endswitch
            </td>
          @endforeach
          <td class="px-3 py-2 text-right">
            <button class="px-3 py-1 rounded bg-amber-500 hover:bg-amber-600 text-white"
                    wire:click="edit({{ $r->id }})">Editar</button>
            @if(method_exists($this,'toggleActivo') && array_key_exists('activo', $r->getAttributes()))
              <button class="px-3 py-1 rounded bg-gray-600 hover:bg-gray-700 text-white"
                      wire:click="toggleActivo({{ $r->id }})">{{ $r->activo ? 'Desactivar' : 'Activar' }}</button>
            @endif
            @if(method_exists($this,'delete'))
              <button class="px-3 py-1 rounded bg-red-600 hover:bg-red-700 text-white"
                      wire:click="delete({{ $r->id }})">Borrar</button>
            @endif
          </td>
        </tr>
      @empty
        <tr><td class="px-3 py-4" colspan="{{ count($columns)+1 }}">Sin resultados…</td></tr>
      @endforelse
      </tbody>
    </table>
  </div>

  <div class="mt-4">{{ $rows->links() }}</div>

  {{-- Modal de creación/edición --}}
  <x-ui.modal :title="$editingId ? ('Editar ' . $title) : ('Nuevo ' . $title)" modalId="crudModal" :size="$modalSize ?? 'max-w-2xl'">
    <div class="space-y-3">
      @foreach ($formSchema as $field)
        @php
          $fname = $field['name'];
          $label = $field['label'] ?? $fname;
          $type  = $field['type']  ?? 'text';
          $model = "form.$fname";
        @endphp

        @if ($type === 'select')
          <x-ui.select :id="$fname" :label="$label" :model="$model" :options="$field['options'] ?? []" />
        @elseif ($type === 'checkbox')
          <x-ui.checkbox :id="$fname" :label="$label" :model="$model" />
        @else
          <x-ui.input :id="$fname" :label="$label" :type="$type" :model="$model" :placeholder="($field['placeholder'] ?? '')" />
        @endif
      @endforeach
    </div>

    <x-slot:footer>
      <div class="flex justify-end gap-2">
        <button class="px-4 py-2 rounded border" x-on:click="$dispatch('close-modal',{id:'crudModal'})">Cancelar</button>
        <button class="px-4 py-2 rounded bg-blue-600 hover:bg-blue-700 text-white" wire:click="save">
          Guardar
        </button>
      </div>
    </x-slot:footer>
  </x-ui.modal>
</div>
