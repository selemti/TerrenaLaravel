<x-layouts.app>
<div class="d-flex justify-content-between align-items-center mb-3">
  <h1 class="h5">Recepciones</h1>
  <a class="btn btn-primary" href="{{ route('inv.receptions.new') }}">Nueva</a>
</div>

<table class="table table-sm">
  <thead><tr><th>ID</th><th>Proveedor</th><th>Fecha</th></tr></thead>
  <tbody>
    @foreach($rows as $r)
      <tr><td>{{ $r->id }}</td><td>{{ $r->proveedor_id }}</td><td>{{ $r->ts }}</td></tr>
    @endforeach
  </tbody>
</table>
</x-layouts.app>
