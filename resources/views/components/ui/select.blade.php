@props([
  'id' => null,
  'label' => null,
  'model' => null,   {{-- wire:model.defer="form.campo" --}}
  'options' => [],   {{-- [['value'=>'GR','label'=>'Gramo'], ...] --}}
])

<div>
  @if($label)
    <label for="{{ $id }}" class="block text-sm font-medium mb-1">{{ $label }}</label>
  @endif

  <select id="{{ $id }}" @if($model) wire:model.defer="{{ $model }}" @endif
          {{ $attributes->merge(['class' => 'border rounded px-3 py-2 w-full']) }}>
    <option value="">— Selecciona —</option>
    @foreach($options as $opt)
      <option value="{{ $opt['value'] }}">{{ $opt['label'] }}</option>
    @endforeach
  </select>

  @error(str_replace('form.', '', $model))
    <div class="text-red-600 text-xs mt-1">{{ $message }}</div>
  @enderror
</div>
