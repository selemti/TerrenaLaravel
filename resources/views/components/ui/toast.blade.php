@props([
    'type' => 'info', // info, success, warning, error
    'title' => null,
    'message' => null,
])

@php
    $colors = [
        'info' => 'bg-blue-50 border-blue-200 text-blue-700',
        'success' => 'bg-green-50 border-green-200 text-green-700',
        'warning' => 'bg-yellow-50 border-yellow-200 text-yellow-700',
        'error' => 'bg-red-50 border-red-200 text-red-700',
    ];
    
    $color = $colors[$type] ?? $colors['info'];
@endphp

<div 
    {{ $attributes->merge(['class' => "rounded-lg border p-4 $color"]) }}
    x-data="{ show: true }"
    x-show="show"
    x-init="setTimeout(() => { show = false }, 5000)"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="transform opacity-0 translate-y-1"
    x-transition:enter-end="transform opacity-100 translate-y-0"
    x-transition:leave="transition ease-in duration-300"
    x-transition:leave-start="transform opacity-100 translate-y-0"
    x-transition:leave-end="transform opacity-0 translate-y-1"
>
    <div class="flex items-start">
        <div class="flex-1">
            @if($title)
                <h3 class="text-sm font-medium">{{ $title }}</h3>
            @endif
            @if($message)
                <p class="mt-1 text-sm">{{ $message }}</p>
            @endif
            {{ $slot }}
        </div>
        <button 
            @click="show = false" 
            class="ml-4 text-gray-400 hover:text-gray-500"
            aria-label="Cerrar"
        >
            <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
            </svg>
        </button>
    </div>
</div>