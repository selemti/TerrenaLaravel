<x-layouts.app>
<h1 class="h5 mb-3">Lotes</h1>
<table class="table table-sm align-middle">
  <thead><tr>
    <th>ID</th><th>Item</th><th>Lote</th><th>Caducidad</th><th>Estado</th><th>Stock</th>
  </tr></thead>
  <tbody>
  @foreach($lots as $l)
    <tr class="@if($l->caducidad && $l->caducidad <= now()->toDateString()) table-danger @endif">
      <td>{{ $l->id }}</td>
      <td>{{ $l->item_id }}</td>
      <td>{{ $l->lote }}</td>
      <td>{{ $l->caducidad ?? '—' }}</td>
      <td>{{ $l->estado }}</td>
      <td>{{ number_format($l->stock,2) }}</td>
    </tr>
  @endforeach
  </tbody>
</table>
</x-layouts.app>
