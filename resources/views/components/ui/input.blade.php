@props([
  'id' => null,
  'label' => null,
  'type' => 'text',
  'model' => null,  {{-- wire:model.defer="form.campo" --}}
  'placeholder' => '',
  'help' => null,
])

<div>
  @if($label)
    <label for="{{ $id }}" class="block text-sm font-medium mb-1">{{ $label }}</label>
  @endif

  <input
    id="{{ $id }}"
    type="{{ $type }}"
    placeholder="{{ $placeholder }}"
    {{ $attributes->merge(['class' => 'border rounded px-3 py-2 w-full']) }}
    @if($model) wire:model.defer="{{ $model }}" @endif
  >

  @if($help)
    <div class="text-xs text-gray-500 mt-1">{{ $help }}</div>
  @endif

  @error(str_replace('form.', '', $model))
    <div class="text-red-600 text-xs mt-1">{{ $message }}</div>
  @enderror
</div>
