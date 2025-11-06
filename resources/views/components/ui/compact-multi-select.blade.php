@props([
    'name',
    'options' => [],
    'placeholder' => 'Seleccionar',
    'searchPlaceholder' => 'Buscar',
    'clearLabel' => 'Limpiar',
    'doneLabel' => 'Hecho',
    'emptyMessage' => 'Sin opciones disponibles.',
])

@php
    use Illuminate\Support\Str;

    $componentId = 'multi-' . Str::uuid()->toString();
    $optionsCollection = collect($options)
        ->map(function ($option) {
            $value = (string) ($option['value'] ?? $option['id'] ?? '');
            if ($value === '') {
                return null;
            }

            return [
                'value' => $value,
                'label' => (string) ($option['label'] ?? $value),
                'selected' => (bool) ($option['selected'] ?? false),
                'indicator_color' => $option['indicator_color'] ?? $option['color'] ?? null,
                'badge' => $option['badge'] ?? null,
                'highlight' => (bool) ($option['highlight'] ?? false),
            ];
        })
        ->filter()
        ->values();
@endphp

<div {{ $attributes->class(['dropdown w-100']) }}
     data-report-multi-select
     data-component-id="{{ $componentId }}"
     data-placeholder="{{ $placeholder }}">
    <button class="btn btn-outline-secondary w-100 d-flex justify-content-between align-items-center"
            type="button"
            data-bs-toggle="dropdown"
            aria-expanded="false">
        <span class="text-truncate" data-summary>{{ $placeholder }}</span>
        <i class="fa-solid fa-chevron-down small text-muted ms-2"></i>
    </button>
    <div class="dropdown-menu w-100 p-3 shadow-sm">
        <div class="mb-2">
            <input type="search"
                   class="form-control form-control-sm"
                   placeholder="{{ $searchPlaceholder }}"
                   data-search>
        </div>
        <div class="mb-2" data-options>
            @forelse($optionsCollection as $option)
                @php
                    $badge = is_array($option['badge'] ?? null) ? $option['badge'] : null;
                @endphp
                <label @class([
                        'form-check',
                        'd-flex',
                        'align-items-center',
                        'gap-2',
                        'mb-1',
                        'rounded',
                        'px-2',
                        'py-1',
                        'bg-primary-subtle border border-primary-subtle' => $option['highlight'] ?? false,
                    ])
                       data-option-row>
                    <input class="form-check-input"
                           type="checkbox"
                           value="{{ $option['value'] }}"
                           data-option
                           data-label="{{ $option['label'] }}"
                           @checked($option['selected'])>
                    <span class="flex-grow-1 text-truncate">{{ $option['label'] }}</span>
                    @if(!empty($option['indicator_color']))
                        <span class="report-dot" style="background-color: {{ $option['indicator_color'] }}"></span>
                    @endif
                    @if($badge && ($badge['label'] ?? '') !== '')
                        @php
                            $badgeColor = $badge['color'] ?? '#1f2937';
                            $badgeText = $badge['text_color'] ?? '#ffffff';
                        @endphp
                        <span class="badge rounded-pill"
                              style="background-color: {{ $badgeColor }}; color: {{ $badgeText }};">
                            {{ $badge['label'] }}
                        </span>
                    @endif
                </label>
            @empty
                <p class="text-muted small mb-0">{{ $emptyMessage }}</p>
            @endforelse
        </div>
        <div class="d-flex justify-content-between align-items-center pt-2 mt-2 border-top">
            <button type="button" class="btn btn-sm btn-outline-secondary" data-clear>{{ $clearLabel }}</button>
            <button type="button" class="btn btn-sm btn-primary" data-close>{{ $doneLabel }}</button>
        </div>
    </div>
    <select name="{{ $name }}" multiple class="d-none" data-hidden-select>
        @foreach($optionsCollection as $option)
            <option value="{{ $option['value'] }}" @selected($option['selected'])>
                {{ $option['label'] }}
            </option>
        @endforeach
    </select>
</div>

@once
    @push('styles')
        <style>
            .report-dot {
                width: 0.75rem;
                height: 0.75rem;
                border-radius: 50%;
                display: inline-block;
                flex-shrink: 0;
            }
        </style>
    @endpush
@endonce

@once
    @push('scripts')
        <script>
            document.addEventListener('DOMContentLoaded', function () {
                document.querySelectorAll('[data-report-multi-select]').forEach(function (component) {
                    var dropdownToggle = component.querySelector('[data-bs-toggle="dropdown"]');
                    var dropdownInstance = dropdownToggle && window.bootstrap
                        ? window.bootstrap.Dropdown.getOrCreateInstance(dropdownToggle)
                        : null;
                    var summaryEl = component.querySelector('[data-summary]');
                    var placeholder = component.getAttribute('data-placeholder') || 'Seleccionar';
                    var hiddenSelect = component.querySelector('[data-hidden-select]');
                    var searchInput = component.querySelector('[data-search]');
                    var clearBtn = component.querySelector('[data-clear]');
                    var closeBtn = component.querySelector('[data-close]');
                    var checkboxes = Array.prototype.slice.call(
                        component.querySelectorAll('input[type="checkbox"][data-option]')
                    );

                    if (hiddenSelect) {
                        Array.prototype.slice.call(hiddenSelect.options).forEach(function (opt) {
                            opt.selected = checkboxes.some(function (cb) {
                                return cb.value === opt.value && cb.checked;
                            });
                        });
                    }

                    var updateSummary = function () {
                        if (hiddenSelect) {
                            Array.prototype.forEach.call(hiddenSelect.options, function (opt) {
                                opt.selected = false;
                            });
                        }

                        var selected = [];
                        checkboxes.forEach(function (cb) {
                            var isChecked = cb.checked;
                            if (hiddenSelect) {
                                Array.prototype.forEach.call(hiddenSelect.options, function (opt) {
                                    if (opt.value === cb.value) {
                                        opt.selected = isChecked;
                                    }
                                });
                            }
                            if (isChecked) {
                                selected.push({
                                    value: cb.value,
                                    label: cb.getAttribute('data-label') || cb.value
                                });
                            }
                        });

                        if (summaryEl) {
                            if (selected.length === 0) {
                                summaryEl.textContent = placeholder;
                            } else if (selected.length <= 2) {
                                summaryEl.textContent = selected.map(function (item) {
                                    return item.label;
                                }).join(', ');
                            } else {
                                summaryEl.textContent = selected.length + ' seleccionadas';
                            }
                        }
                    };

                    checkboxes.forEach(function (cb) {
                        cb.addEventListener('change', updateSummary);
                    });

                    if (clearBtn) {
                        clearBtn.addEventListener('click', function () {
                            checkboxes.forEach(function (cb) {
                                cb.checked = false;
                            });
                            updateSummary();
                        });
                    }

                    if (closeBtn && dropdownInstance) {
                        closeBtn.addEventListener('click', function () {
                            dropdownInstance.hide();
                        });
                    }

                    if (searchInput) {
                        searchInput.addEventListener('input', function (event) {
                            var term = event.target.value.trim().toLowerCase();
                            component.querySelectorAll('[data-option-row]').forEach(function (row) {
                                var checkbox = row.querySelector('[data-option]');
                                var label = checkbox
                                    ? (checkbox.getAttribute('data-label') || '').toLowerCase()
                                    : '';
                                row.classList.toggle('d-none', term !== '' && !label.includes(term));
                            });
                        });
                    }

                    updateSummary();
                });
            });
        </script>
    @endpush
@endonce
