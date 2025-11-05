@props([
    'url' => null, // Optional URL for the entire row to be clickable
])

@if($url)
    <tr 
        {{ $attributes->merge(['class' => 'bg-white hover:bg-gray-50 cursor-pointer']) }}
        onclick="window.location='{{ $url }}'"
    >
        {{ $slot }}
    </tr>
@else
    <tr {{ $attributes->merge(['class' => 'bg-white hover:bg-gray-50']) }}>
        {{ $slot }}
    </tr>
@endif