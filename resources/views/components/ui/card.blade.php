@props([
    'title' => null,
    'subtitle' => null,
    'padding' => 'p-5',  {{-- p-3 | p-5 | p-6 --}}
])

<div {{ $attributes->merge(['class' => 'bg-white rounded-lg border border-gray-200 shadow-sm']) }}>
    @if($title || $slot)
        <div class="border-b border-gray-200 {{ $padding }}">
            @if($title)
                <h3 class="text-lg font-semibold text-gray-900">{{ $title }}</h3>
                @if($subtitle)
                    <p class="text-sm text-gray-500 mt-1">{{ $subtitle }}</p>
                @endif
            @endif
            {{ $slot }}
        </div>
    @endif

    @if(isset($content))
        <div class="{{ $padding }}">
            {{ $content }}
        </div>
    @endif

    @if(isset($footer))
        <div class="border-t border-gray-200 px-5 py-3 bg-gray-50 rounded-b-lg">
            {{ $footer }}
        </div>
    @endif
</div>