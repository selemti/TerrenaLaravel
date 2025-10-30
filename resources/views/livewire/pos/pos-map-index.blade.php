<div>
    <div class="p-6">
        <div class="flex items-center justify-between">
            <h1 class="text-2xl font-semibold text-gray-700">Mapeo POS</h1>
        </div>

        @if (session()->has('message'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative" role="alert">
                <span class="block sm:inline">{{ session('message') }}</span>
            </div>
        @endif

        <div class="mt-4">
            @if($updateMode)
                @include('livewire.pos.update')
            @else
                @include('livewire.pos.create')
            @endif
        </div>

        <div class="mt-6">
            <h2 class="text-xl font-semibold text-gray-700">Ventas sin Mapeo</h2>
            <div class="overflow-x-auto mt-2">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Menu Item
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Ticket ID
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Fecha Venta
                            </th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        @forelse ($unmappedSales as $sale)
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    {{ $sale->menu_item_name }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    {{ $sale->ticket_id }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    {{ $sale->fecha_venta }}
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="3" class="px-6 py-4 whitespace-nowrap text-center text-sm text-gray-500">
                                    No hay ventas sin mapeo.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <div class="mt-6">
            <h2 class="text-xl font-semibold text-gray-700">Mapeos Existentes</h2>
            <div class="overflow-x-auto mt-2">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                PLU
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Receta
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Tipo
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Acciones
                            </th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        @foreach ($mappings as $mapping)
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    {{ $mapping->plu }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    {{ $mapping->recipe->nombre ?? 'N/A' }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    {{ $mapping->tipo }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                    <button wire:click="edit({{ $mapping->id }})" class="text-indigo-600 hover:text-indigo-900">Editar</button>
                                    <button wire:click="destroy({{ $mapping->id }})" class="text-red-600 hover:text-red-900 ml-4">Eliminar</button>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            <div class="mt-4">
                {{ $mappings->links() }}
            </div>
        </div>
    </div>
</div>