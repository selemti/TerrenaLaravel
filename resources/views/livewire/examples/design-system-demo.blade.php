<div class="p-6">
    <!-- Notification Manager - This would be included in your layout -->
    <x-ui.notification-manager position="top-right" />
    
    <x-ui.card title="Demo del Sistema de Diseño" subtitle="Ejemplo de uso de componentes UI">
        <x-slot:content>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Form Section -->
                <div class="space-y-4">
                    <h3 class="text-lg font-medium">Formulario de Ejemplo</h3>
                    
                    <x-ui.input 
                        label="Nombre" 
                        id="name" 
                        model="name" 
                        placeholder="Ingresa tu nombre" 
                    />
                    
                    <x-ui.input 
                        label="Email" 
                        id="email" 
                        type="email"
                        model="email" 
                        placeholder="tu@email.com" 
                    />
                    
                    <x-ui.select 
                        label="Selecciona una opción" 
                        id="option" 
                        model="selectedOption"
                        :options="$options"
                    />
                    
                    <x-ui.date-picker
                        label="Fecha"
                        id="date"
                        model="date"
                    />
                    
                    <x-ui.checkbox
                        label="¿Deseas suscribirte?"
                        id="subscription"
                        model="isSubscribed"
                    />
                    
                    <div>
                        <label class="block text-sm font-medium mb-1">Mensaje</label>
                        <textarea 
                            wire:model="message" 
                            class="border rounded px-3 py-2 w-full" 
                            rows="3"
                            placeholder="Escribe tu mensaje aquí..."
                        ></textarea>
                        @error('message')
                            <div class="text-red-600 text-xs mt-1">{{ $message }}</div>
                        @enderror
                    </div>
                    
                    <div class="pt-4">
                        <x-primary-button wire:click="submitForm">
                            Enviar Formulario
                        </x-primary-button>
                    </div>
                </div>
                
                <!-- Search and Table Section -->
                <div class="space-y-4">
                    <h3 class="text-lg font-medium">Búsqueda y Tabla</h3>
                    
                    <x-ui.search-input
                        label="Buscar en la tabla"
                        id="search"
                        model="searchTerm"
                        placeholder="Buscar..."
                    />
                    
                    <x-ui.advanced-table 
                        :headers="$headers" 
                        class="mt-4"
                        :actions="true"
                        :bulk-actions="true"
                    >
                        @foreach($tableData as $row)
                            <x-ui.table-row>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ $row['id'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ $row['name'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $row['email'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $row['date'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                    <x-ui.dropdown
                                        label="Acciones"
                                        :items="[
                                            ['label' => 'Ver', 'action' => 'showToast(\'info\', \'Ver\', \'Mostrando detalle del registro: ' . $row['id'] . '\')'],
                                            ['label' => 'Editar', 'action' => 'showToast(\'warning\', \'Editar\', \'Editando registro: ' . $row['id'] . '\')'],
                                            ['divider' => true],
                                            ['label' => 'Eliminar', 'action' => 'showToast(\'error\', \'Eliminar\', \'Eliminar registro: ' . $row['id'] . '\')']
                                        ]"
                                    />
                                </td>
                            </x-ui.table-row>
                        @endforeach
                    </x-ui.advanced-table>
                </div>
            </div>
            
            <!-- Toast Notification Example -->
            <div class="mt-6">
                <h3 class="text-lg font-medium mb-4">Componentes de Notificación</h3>
                
                <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <button 
                        wire:click="showToast('info', 'Info', 'Este es un mensaje informativo')"
                        class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
                    >
                        Info
                    </button>
                    <button 
                        wire:click="showToast('success', 'Éxito', 'Operación completada correctamente')"
                        class="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
                    >
                        Success
                    </button>
                    <button 
                        wire:click="showToast('warning', 'Advertencia', 'Operación puede tener impacto')"
                        class="px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600"
                    >
                        Warning
                    </button>
                    <button 
                        wire:click="showToast('error', 'Error', 'Ocurrió un problema en la operación')"
                        class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
                    >
                        Error
                    </button>
                </div>
                
                <div class="mt-4 space-y-2">
                    <x-ui.banner type="info" title="Banner de Información" message="Este es un ejemplo de banner informativo." />
                    <x-ui.banner type="success" title="Operación Exitosa" message="La operación se completó con éxito." closable="true" />
                </div>
            </div>
        </x-slot:content>
    </x-ui.card>
</div>