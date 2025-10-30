<div class="space-y-5">
    <h1 class="text-2xl font-semibold">
        Transferencia #{{ $transferId }} - Estado: {{ $estado }}
    </h1>

    <p class="text-sm text-gray-600">
        Origen: <span class="font-medium">{{ $origen_nombre }}</span><br>
        Destino: <span class="font-medium">{{ $destino_nombre }}</span>
    </p>

    <div class="flex flex-wrap gap-2 mb-4">
        @if($canApprove)
            <!-- requires: inventory.transfers.approve -->
            <button
                type="button"
                class="rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                wire:click="actionApprove"
            >
                Aprobar solicitud
            </button>
        @endif

        @if($canShip)
            <!-- requires: inventory.transfers.ship -->
            <button
                type="button"
                class="rounded bg-amber-600 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-700 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:ring-offset-2"
                wire:click="actionShip"
            >
                Marcar como enviada
            </button>
        @endif

        @if($canReceive)
            <!-- requires: inventory.transfers.receive -->
            <button
                type="button"
                class="rounded bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2"
                wire:click="actionReceive"
            >
                Marcar como recibida
            </button>
        @endif

        @if($canPost)
            <!-- requires: inventory.transfers.post -->
            <button
                type="button"
                class="rounded bg-purple-600 px-4 py-2 text-sm font-semibold text-white hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2"
                wire:click="actionPost"
            >
                Postear a inventario
            </button>
        @endif
    </div>

    <section class="overflow-x-auto rounded-lg border border-gray-200">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr class="text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                    <th class="px-4 py-2">Item</th>
                    <th class="px-4 py-2">Qty enviada</th>
                    <th class="px-4 py-2">Qty recibida</th>
                    <th class="px-4 py-2">UOM</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white text-sm text-gray-700">
                @forelse($lineas as $linea)
                    <tr>
                        <td class="px-4 py-2">
                            <div class="font-medium">{{ $linea['item_nombre'] ?? 'N/D' }}</div>
                            <div class="text-xs text-gray-500">ID {{ $linea['item_id'] ?? '-' }}</div>
                        </td>
                        <td class="px-4 py-2">{{ $linea['qty_enviada'] ?? '0.000000' }}</td>
                        <td class="px-4 py-2">{{ $linea['qty_recibida'] ?? '0.000000' }}</td>
                        <td class="px-4 py-2">{{ $linea['uom'] ?? 'N/D' }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="4" class="px-4 py-6 text-center text-gray-400 text-sm">
                            Sin líneas
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </section>
</div>
