@props([
    'label' => null,
    'type' => 'text',
    'name' => null,
    'id' => null,
    'value' => '',
    'placeholder' => '',
    'required' => false,
    'disabled' => false,
    'readonly' => false,
    'help' => null,
    'error' => null,
    'model' => null, // For Livewire integration
    'options' => [], // For select inputs
    'multiple' => false, // For multi-select
    'rows' => 3, // For textarea
])

@php
    $id = $id ?: $name;
    $hasError = $error !== null;
    $inputClasses = 'form-control';
    
    if ($hasError) {
        $inputClasses .= ' is-invalid';
    }
    
    if ($disabled) {
        $inputClasses .= ' disabled';
    }
    
    if ($readonly) {
        $inputClasses .= ' readonly';
    }
    
    // Determine if this is a select, textarea, or regular input
    $isSelect = $type === 'select';
    $isTextarea = $type === 'textarea';
    $isCheckbox = $type === 'checkbox';
    $isRadio = $type === 'radio';
@endphp

<div class="mb-3">
    @if($label)
        <label for="{{ $id }}" class="form-label fw-semibold">
            {{ $label }}
            @if($required)
                <span class="text-danger">*</span>
            @endif
        </label>
    @endif

    @if($isSelect)
        <select 
            id="{{ $id }}" 
            name="{{ $name }}"
            class="{{ $inputClasses }}"
            {{ $disabled ? 'disabled' : '' }}
            {{ $readonly ? 'readonly' : '' }}
            {{ $multiple ? 'multiple' : '' }}
            {{ $attributes->merge(['class' => '']) }}
            @if($model) wire:model.defer="{{ $model }}" @endif
        >
            @if(!$multiple)
                <option value="">-- Selecciona --</option>
            @endif
            @foreach($options as $optionValue => $optionLabel)
                <option value="{{ $optionValue }}" {{ $optionValue == $value ? 'selected' : '' }}>
                    {{ $optionLabel }}
                </option>
            @endforeach
        </select>
    @elseif($isTextarea)
        <textarea
            id="{{ $id }}"
            name="{{ $name }}"
            rows="{{ $rows }}"
            class="{{ $inputClasses }}"
            placeholder="{{ $placeholder }}"
            {{ $required ? 'required' : '' }}
            {{ $disabled ? 'disabled' : '' }}
            {{ $readonly ? 'readonly' : '' }}
            {{ $attributes->merge(['class' => '']) }}
            @if($model) wire:model.defer="{{ $model }}" @endif
        >{{ $value }}</textarea>
    @elseif($isCheckbox || $isRadio)
        <div class="form-check">
            <input
                type="{{ $type }}"
                id="{{ $id }}"
                name="{{ $name }}"
                value="{{ $value }}"
                class="form-check-input {{ $hasError ? 'is-invalid' : '' }}"
                {{ $value ? 'checked' : '' }}
                {{ $required ? 'required' : '' }}
                {{ $disabled ? 'disabled' : '' }}
                {{ $readonly ? 'readonly' : '' }}
                {{ $attributes->merge(['class' => '']) }}
                @if($model) wire:model.defer="{{ $model }}" @endif
            >
            <label class="form-check-label" for="{{ $id }}">
                {{ $label }}
                @if($required)
                    <span class="text-danger">*</span>
                @endif
            </label>
        </div>
    @else
        <input
            type="{{ $type }}"
            id="{{ $id }}"
            name="{{ $name }}"
            value="{{ $value }}"
            class="{{ $inputClasses }}"
            placeholder="{{ $placeholder }}"
            {{ $required ? 'required' : '' }}
            {{ $disabled ? 'disabled' : '' }}
            {{ $readonly ? 'readonly' : '' }}
            {{ $attributes->merge(['class' => '']) }}
            @if($model) wire:model.defer="{{ $model }}" @endif
        >
    @endif

    @if($help)
        <div class="form-text">{{ $help }}</div>
    @endif

    @if($hasError)
        <div class="invalid-feedback">
            {{ $error }}
        </div>
    @endif
</div>