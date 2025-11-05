@props([
  'id' => null,
  'label' => null,
  'model' => null,  {{-- wire:model.live.debounce.500ms="search" --}}
  'placeholder' => 'Buscar...',
  'icon' => 'search', // search, filter, etc.
])

<div>
  @if($label)
    <label for="{{ $id }}" class="block text-sm font-medium mb-1">{{ $label }}</label>
  @endif

  <div class="relative">
    <div class="absolute inset-y-0 start-0 flex items-center ps-3 pointer-events-none">
      <svg class="w-4 h-4 text-gray-500" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 20">
        <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m19 19-4-4m0-7A7 7 0 1 1 1 8a7 7 0 0 1 14 0Z"/>
      </svg>
    </div>
    <input
      id="{{ $id }}"
      type="text"
      placeholder="{{ $placeholder }}"
      {{ $attributes->merge(['class' => 'border rounded px-3 ps-10 py-2 w-full']) }}
      @if($model) wire:model="{{ $model }}" @endif
    >
  </div>

  @error(str_replace('form.', '', $model))
    <div class="text-red-600 text-xs mt-1">{{ $message }}</div>
  @enderror
</div>