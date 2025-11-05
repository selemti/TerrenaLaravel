@props([
    'label' => null,
    'items' => [],
    'position' => 'bottom-start', // bottom-start, bottom-end, top-start, top-end
])

@php
    $positions = [
        'bottom-start' => 'left-0',
        'bottom-end' => 'right-0',
        'top-start' => 'left-0 bottom-full',
        'top-end' => 'right-0 bottom-full',
    ];
    
    $positionClass = $positions[$position] ?? $positions['bottom-start'];
@endphp

<div class="relative" x-data="{ open: false }">
    <button 
        @click="open = !open"
        class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        type="button"
    >
        {{ $label ?? 'Opciones' }}
        <svg class="-mr-1 ml-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
    </button>

    <div 
        x-show="open"
        @click.away="open = false"
        x-transition:enter="transition ease-out duration-100"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        x-transition:leave="transition ease-in duration-75"
        x-transition:leave-start="transform opacity-100 scale-100"
        x-transition:leave-end="transform opacity-0 scale-95"
        class="z-10 absolute {{ $positionClass }} mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5"
    >
        <div class="py-1">
            @foreach($items as $item)
                @if(isset($item['divider']))
                    <div class="border-t border-gray-200 my-1"></div>
                @else
                    <a 
                        href="{{ $item['href'] ?? 'javascript:void(0)' }}" 
                        wire:navigate
                        @if(!isset($item['href'])) 
                            @click="{{ $item['action'] ?? '' }}; open = false" 
                        @endif
                        class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    >
                        {{ $item['label'] }}
                    </a>
                @endif
            @endforeach
        </div>
    </div>
</div>