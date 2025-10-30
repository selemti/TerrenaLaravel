<div class="container mx-auto px-4 py-8">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold text-gray-800">Mapeos POS</h1>
        <button 
            wire:click="openCreate"
            class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        >
            Nuevo Mapeo
        </button>
    </div>

    <!-- Filtros -->
    <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Buscar</label>
                <input 
                    type="text" 
                    wire:model.live="search"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    placeholder="PLU o Receta ID..."
                >
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Sistema POS</label>
                <select 
                    wire:model.live="system"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                >
                    <option value="">Todos</option>
                    @foreach($systems as $system)
                        <option value="{{ $system }}">{{ $system }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Tipo</label>
                <select 
                    wire:model.live="tipo"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                >
                    <option value="">Todos</option>
                    <option value="MENU">Menú</option>
                    <option value="MODIFICADOR">Modificador</option>
                    <option value="COMBO">Combo</option>
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Estado</label>
                <select 
                    wire:model.live="status"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                >
                    <option value="all">Todos</option>
                    <option value="activo">Activo</option>
                    <option value="inactivo">Inactivo</option>
                </select>
            </div>
        </div>

        <!-- Reportes de mapeo incompleto -->
        <div class="mt-4 pt-4 border-t border-gray-200">
            <h3 class="text-lg font-medium text-gray-900 mb-2">Reportes de mapeo incompleto</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-red-50 p-4 rounded-md">
                    <h4 class="font-medium text-red-800">Ventas sin mapeo a receta</h4>
                    <p class="text-sm text-gray-600 mt-1">Items de menú vendidos sin mapeo POS→Receta</p>
                    <button 
                        wire:click="checkUnmappedSales"
                        class="mt-2 bg-red-600 hover:bg-red-700 text-white py-1 px-3 rounded text-sm"
                    >
                        Verificar hoy
                    </button>
                </div>
                <div class="bg-yellow-50 p-4 rounded-md">
                    <h4 class="font-medium text-yellow-800">Modificadores sin mapeo</h4>
                    <p class="text-sm text-gray-600 mt-1">Modificadores vendidos sin mapeo POS</p>
                    <button 
                        wire:click="checkUnmappedModifiers"
                        class="mt-2 bg-yellow-600 hover:bg-yellow-700 text-white py-1 px-3 rounded text-sm"
                    >
                        Verificar hoy
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Tabla de mapeos -->
    <div class="bg-white rounded-lg shadow-md overflow-hidden">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">PLU</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Receta ID</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Válido desde</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Válido hasta</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Vigente desde</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    @forelse($mappings as $mapping)
                    <tr>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ $mapping->plu }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $mapping->tipo }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $mapping->receta_id }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $mapping->valid_from }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            @if($mapping->valid_to)
                                {{ $mapping->valid_to }}
                            @else
                                <span class="text-green-600">Vigente</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            @if($mapping->vigente_desde)
                                {{ $mapping->vigente_desde }}
                            @else
                                <span class="text-gray-400">No especificado</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                            <button 
                                wire:click="openEdit(['{{ $mapping->pos_system }}', '{{ $mapping->plu }}', '{{ $mapping->valid_from }}', '{{ $mapping->sys_from }}'])"
                                class="text-indigo-600 hover:text-indigo-900 mr-3"
                            >
                                Editar
                            </button>
                            <button 
                                wire:click="delete(['{{ $mapping->pos_system }}', '{{ $mapping->plu }}', '{{ $mapping->valid_from }}', '{{ $mapping->sys_from }}'])"
                                class="text-red-600 hover:text-red-900"
                            >
                                Eliminar
                            </button>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="px-6 py-4 text-center text-sm text-gray-500">
                            No se encontraron mapeos POS
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="bg-gray-50 px-6 py-3">
            {{ $mappings->links() }}
        </div>
    </div>

    <!-- Formulario Modal -->
    @if($showForm)
    <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white">
            <div class="mt-3">
                <div class="flex justify-between items-center pb-3 border-b">
                    <h3 class="text-lg font-medium text-gray-900">
                        {{ $isEditing ? 'Editar Mapeo POS' : 'Nuevo Mapeo POS' }}
                    </h3>
                    <button 
                        wire:click="closeForm"
                        class="text-gray-400 hover:text-gray-600"
                    >
                        <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                <form wire:submit.prevent="save" class="mt-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Sistema POS</label>
                            <select 
                                wire:model="form.pos_system"
                                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            >
                                <option value="FLOREANT">FLOREANT</option>
                                <option value="OTRO">OTRO</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">PLU</label>
                            <input 
                                type="text"
                                wire:model="form.plu"
                                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                                placeholder="Código PLU"
                            >
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Tipo</label>
                            <select 
                                wire:model="form.tipo"
                                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            >
                                @foreach($tipoOptions as $tipo)
                                <option value="{{ $tipo }}">{{ $tipo }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">ID de Receta</label>
                            <input 
                                type="text"
                                wire:model="form.receta_id"
                                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                                placeholder="ID de la receta"
                            >
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Versión de Receta</label>
                            <input 
                                type="number"
                                wire:model="form.receta_version_id"
                                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                                placeholder="Versión de receta"
                            >
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Válido desde</label>
                            <input 
                                type="date"
                                wire:model="form.valid_from"
                                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            >
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Válido hasta</label>
                            <input 
                                type="date"
                                wire:model="form.valid_to"
                                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            >
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Vigente desde</label>
                            <input 
                                type="date"
                                wire:model="form.vigente_desde"
                                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            >
                        </div>
                    </div>
                    <div class="mt-4">
                        <label class="block text-sm font-medium text-gray-700">Metadatos (JSON)</label>
                        <textarea 
                            wire:model="form.meta"
                            rows="3"
                            class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            placeholder="Metadatos adicionales en formato JSON"
                        ></textarea>
                    </div>
                    <div class="flex justify-end space-x-3 mt-6">
                        <button 
                            type="button"
                            wire:click="closeForm"
                            class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md border border-gray-300"
                        >
                            Cancelar
                        </button>
                        <button 
                            type="submit"
                            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md border border-transparent"
                        >
                            {{ $isEditing ? 'Actualizar' : 'Guardar' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    @endif

    <!-- Modal de confirmación de eliminación -->
    <div x-data="{ show: false, id: null }" x-show="show" x-on:confirm-delete.window="show = true; id = $event.detail.id" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" x-cloak>
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-1/3 shadow-lg rounded-md bg-white">
            <div class="mt-3 text-center">
                <h3 class="text-lg font-medium text-gray-900">Confirmar eliminación</h3>
                <div class="mt-2 px-7 py-3">
                    <p class="text-sm text-gray-500">
                        ¿Está seguro que desea eliminar este mapeo POS? Esta acción no se puede deshacer.
                    </p>
                </div>
                <div class="items-center px-4 py-3">
                    <button 
                        x-on:click="show = false"
                        class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md border border-gray-300 mr-2"
                    >
                        Cancelar
                    </button>
                    <button 
                        x-on:click="$wire.delete(id); show = false"
                        class="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-md border border-transparent"
                    >
                        Eliminar
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>