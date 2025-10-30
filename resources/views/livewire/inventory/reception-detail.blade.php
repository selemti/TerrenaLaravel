<div class="space-y-5">
    <h1 class="text-2xl font-semibold">
        Recepción #{{ $recepcionId }} - Estado: {{ $estado }}
    </h1>

    @if($requiere_aprobacion)
        <div class="alert alert-warning">
            Fuera de tolerancia - requiere aprobación
        </div>
    @endif

    <div class="flex flex-wrap gap-2 mb-4">
        @if($canValidate)
            <!-- requires: inventory.receptions.validate -->
            <button
                type="button"
                class="rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                wire:click="actionValidate"
            >
                Validar recepción
            </button>
        @endif

        @if($canOverride && $requiere_aprobacion)
            <!-- requires: inventory.receptions.override_tolerance -->
            <button
                type="button"
                class="rounded bg-amber-600 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-700 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:ring-offset-2"
                wire:click="actionApprove"
            >
                Aprobar fuera de tolerancia
            </button>
        @endif

        @if($canPost)
            <!-- requires: inventory.receptions.post -->
            <button
                type="button"
                class="rounded bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2"
                wire:click="actionPost"
            >
                Postear a inventario
            </button>
        @endif
    </div>

    <!-- TODO: esta vista hace fetch via API en mount(), no usa datos de Blade -->
    <section class="overflow-x-auto rounded-lg border border-gray-200">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr class="text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                    <th class="px-4 py-2">Item</th>
                    <th class="px-4 py-2">Qty ordenada</th>
                    <th class="px-4 py-2">Qty recibida</th>
                    <th class="px-4 py-2">% diferencia</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white text-sm text-gray-700">
                @forelse($lineas as $linea)
                    <tr @class(['bg-yellow-50' => $linea['fuera_tolerancia'] ?? false])>
                        <td class="px-4 py-2">
                            <div class="font-medium">{{ $linea['item_nombre'] ?? 'N/D' }}</div>
                            <div class="text-xs text-gray-500">ID {{ $linea['item_id'] ?? '-' }}</div>
                        </td>
                        <td class="px-4 py-2">{{ $linea['qty_ordenada'] ?? '0.000000' }}</td>
                        <td class="px-4 py-2">{{ $linea['qty_recibida'] ?? '0.000000' }}</td>
                        <td class="px-4 py-2">
                            {{ number_format($linea['diferencia_pct'] ?? 0, 2) }}%
                            @if($linea['fuera_tolerancia'] ?? false)
                                <span class="ml-2 inline-block rounded bg-yellow-200 px-2 text-xs font-semibold text-yellow-900">
                                    fuera
                                </span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="4" class="px-4 py-3 text-center text-gray-400">
                            Sin líneas registradas
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </section>
</div>
