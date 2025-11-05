@props([
    'loading' => false,
    'rows' => 5,
])

@if($loading)
    <div {{ $attributes->merge(['class' => 'animate-pulse']) }}>
        @for($i = 0; $i < $rows; $i++)
            <div class="rounded h-4 bg-gray-200 mb-2"></div>
        @endfor
    </div>
@else
    {{ $slot }}
@endif