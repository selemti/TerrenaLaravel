@props([
    'title' => null,
    'subtitle' => null,
    'headerActions' => null,
    'footer' => null,
    'padding' => 'p-5',  {{-- p-3 | p-5 | p-6 --}}
    'border' => true,   {{-- Show/hide border --}}
    'shadow' => true,   {{-- Add shadow --}}
])

@php
    $classes = ['bg-white'];
    
    if ($border) {
        $classes[] = 'border border-gray-200';
    }
    
    if ($shadow) {
        $classes[] = 'shadow-sm';
    }
    
    $classString = implode(' ', $classes);
@endendphp

<div {{ $attributes->merge(['class' => $classString . ' rounded-lg']) }}>
    @if($title || $headerActions)
        <div class="border-b border-gray-200 {{ $padding }} flex flex-wrap items-center justify-between gap-4">
            <div>
                @if($title)
                    <h3 class="text-lg font-semibold text-gray-900">{{ $title }}</h3>
                @endif
                @if($subtitle)
                    <p class="text-sm text-gray-500 mt-1">{{ $subtitle }}</p>
                @endif
            </div>
            
            @if($headerActions)
                <div>
                    {{ $headerActions }}
                </div>
            @endif
        </div>
    @elseif($slot)
        @if($border)
            <div class="border-b border-gray-200 {{ $padding }}">
        @else
            <div class="{{ $padding }}">
        @endif
            {{ $slot }}
        </div>
    @endif

    @if(isset($content))
        <div class="{{ $padding }}">
            {{ $content }}
        </div>
    @endif
    
    {{ $slot }}

    @if($footer)
        <div class="border-t border-gray-200 {{ $padding }} bg-gray-50 rounded-b-lg">
            {{ $footer }}
        </div>
    @endif
</div>