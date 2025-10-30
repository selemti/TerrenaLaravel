{{-- TODO: Reemplazar por componente Livewire que liste recepciones reales --}}
<section class="space-y-3">
    <h2 class="text-lg font-semibold">Recepciones recientes</h2>
    <div class="overflow-x-auto rounded border border-gray-200">
        <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs font-semibold uppercase text-gray-500">
                <tr>
                    <th class="px-4 py-2 text-left">Recepción ID</th>
                    <th class="px-4 py-2 text-left">Estado</th>
                    <th class="px-4 py-2 text-left">Acción</th>
                </tr>
            </thead>
            <tbody class="bg-white">
                <tr>
                    <td class="px-4 py-2">123</td>
                    <td class="px-4 py-2">VALIDADA</td>
                    <td class="px-4 py-2">
                        <a href="{{ route('inv.receptions.detail', ['id' => 123]) }}" class="text-blue-600 hover:underline">
                            Ver detalle
                        </a>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</section>
