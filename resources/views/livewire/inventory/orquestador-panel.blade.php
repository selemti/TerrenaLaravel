<div class="container mx-auto p-6">
    <h1 class="text-2xl font-bold mb-6">Panel de Orquestación de Inventarios</h1>
    
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-6">
        <div class="bg-white p-4 rounded-lg shadow">
            <label class="block text-sm font-medium text-gray-700 mb-2">Fecha</label>
            <input 
                type="date" 
                wire:model="selectedDate" 
                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
            >
        </div>
        
        <div class="bg-white p-4 rounded-lg shadow">
            <label class="block text-sm font-medium text-gray-700 mb-2">Sucursal</label>
            <select 
                wire:model="selectedBranch" 
                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
            >
                <option value="1">Sucursal 1</option>
                <option value="2">Sucursal 2</option>
                <option value="3">Sucursal 3</option>
            </select>
        </div>
        
        <div class="bg-white p-4 rounded-lg shadow flex items-end">
            <button 
                wire:click="executeDailyProcess"
                wire:loading.attr="disabled"
                class="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
                <span wire:loading.remove wire:target="executeDailyProcess">Ejecutar Proceso Diario</span>
                <span wire:loading wire:target="executeDailyProcess">Procesando...</span>
            </button>
        </div>
    </div>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div class="bg-white p-4 rounded-lg shadow">
            <h2 class="text-lg font-medium mb-4">Cierre Diario</h2>
            <div class="space-y-2">
                <button 
                    wire:click="runDailyClose"
                    wire:loading.attr="disabled"
                    class="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 mb-4"
                >
                    <span wire:loading.remove wire:target="runDailyClose">Ejecutar Cierre Diario</span>
                    <span wire:loading wire:target="runDailyClose">Procesando...</span>
                </button>
                
                @if($closeStatus)
                    <div class="mt-4">
                        <h3 class="font-medium">Estado del Cierre:</h3>
                        <div class="text-sm bg-gray-100 p-3 rounded mt-1">
                            <pre>{{ json_encode($closeStatus, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) }}</pre>
                        </div>
                    </div>
                @endif
            </div>
        </div>
        
        <div class="bg-white p-4 rounded-lg shadow">
            <h2 class="text-lg font-medium mb-4">Recálculo de Costos</h2>
            <div class="space-y-2">
                <button 
                    wire:click="runCostRecalculation"
                    wire:loading.attr="disabled"
                    class="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 mb-4"
                >
                    <span wire:loading.remove wire:target="runCostRecalculation">Recalcular Costos</span>
                    <span wire:loading wire:target="runCostRecalculation">Procesando...</span>
                </button>
                
                @if($recalculationResult)
                    <div class="mt-4">
                        <h3 class="font-medium">Resultado del Recálculo:</h3>
                        <div class="text-sm bg-gray-100 p-3 rounded mt-1">
                            <pre>{{ json_encode($recalculationResult, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) }}</pre>
                        </div>
                    </div>
                @endif
            </div>
        </div>
    </div>
    
    <div class="bg-white p-4 rounded-lg shadow mb-6">
        <h2 class="text-lg font-medium mb-4">Generar Snapshot</h2>
        <div class="space-y-2">
            <button 
                wire:click="generateSnapshot"
                wire:loading.attr="disabled"
                class="w-full bg-purple-600 text-white py-2 px-4 rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:opacity-50 mb-4"
            >
                <span wire:loading.remove wire:target="generateSnapshot">Generar Snapshot de Inventario</span>
                <span wire:loading wire:target="generateSnapshot">Procesando...</span>
            </button>
        </div>
    </div>
    
    <div class="bg-white p-4 rounded-lg shadow">
        <h2 class="text-lg font-medium mb-4">Registro de Actividad</h2>
        <div class="bg-gray-100 p-4 rounded font-mono text-sm h-64 overflow-y-auto">
            <pre>{{ $logOutput }}</pre>
        </div>
    </div>
</div>