@props([
  'id' => null,
  'label' => null,
  'model' => null,  {{-- wire:model.defer="form.activo" --}}
])

<div class="flex items-center gap-2">
  <input id="{{ $id }}" type="checkbox" class="size-4" @if($model) wire:model.defer="{{ $model }}" @endif>
  @if($label)
    <label for="{{ $id }}">{{ $label }}</label>
  @endif
</div>
@error(str_replace('form.', '', $model))
  <div class="text-red-600 text-xs mt-1">{{ $message }}</div>
@enderror
