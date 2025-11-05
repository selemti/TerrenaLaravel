@props([
    'headers' => [],
    'actions' => null,     // Column for row actions (edit, delete, etc.)
    'bulkActions' => null, // Component for bulk actions (select all, delete selected, etc.)
    'responsive' => true,  // Make table responsive on mobile
])

<div class="{{ $responsive ? 'overflow-x-auto' : '' }}">
    <table {{ $attributes->merge(['class' => 'min-w-full divide-y divide-gray-200']) }}>
        <thead class="bg-gray-50">
            <tr>
                @if($bulkActions)
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-12">
                        <input type="checkbox" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50">
                    </th>
                @endif
                
                @foreach($headers as $header)
                    @if(is_string($header))
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            {{ $header }}
                        </th>
                    @else
                        <th 
                            scope="col" 
                            class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                            @if(isset($header['class'])) {{ $header['class'] }} @endif
                        >
                            {{ $header['label'] }}
                        </th>
                    @endif
                @endforeach
                
                @if($actions)
                    <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Acciones
                    </th>
                @endif
            </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
            {{ $slot }}
        </tbody>
    </table>
</div>

@if(isset($footer))
    <div class="px-4 py-3 border-t border-gray-200 bg-gray-50 sm:px-6 rounded-b-lg">
        {{ $footer }}
    </div>
@endif