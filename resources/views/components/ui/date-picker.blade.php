@props([
  'id' => null,
  'label' => null,
  'model' => null,  {{-- wire:model.defer="form.fecha" --}}
  'placeholder' => 'Selecciona una fecha',
])

<div>
  @if($label)
    <label for="{{ $id }}" class="block text-sm font-medium mb-1">{{ $label }}</label>
  @endif

  <div x-data="{
    date: @entangle($model).live,
    isOpen: false,
    init() {
      this.date = this.date || '{{ date('Y-m-d') }}';
    }
  }" x-init="init" class="relative">
    <input
      id="{{ $id }}"
      type="text"
      placeholder="{{ $placeholder }}"
      x-model="date"
      x-on:click="isOpen = true"
      x-on:keydown.escape="isOpen = false"
      {{ $attributes->merge(['class' => 'border rounded px-3 py-2 w-full cursor-pointer']) }}
      readonly
    >
    
    <div x-show="isOpen" 
         x-transition 
         @click.away="isOpen = false"
         class="absolute z-10 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg w-full">
      <div class="p-3">
        <input
          type="date"
          x-model="date"
          class="w-full p-2 border border-gray-300 rounded"
          @change="isOpen = false"
        >
      </div>
    </div>
  </div>

  @error(str_replace('form.', '', $model))
    <div class="text-red-600 text-xs mt-1">{{ $message }}</div>
  @enderror
</div>