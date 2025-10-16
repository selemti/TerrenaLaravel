@extends('layouts.terrena', ['active' => 'recetas'])
@section('title', 'Recetas')

@section('content')
<div class="d-flex align-items-center justify-content-between mb-3">
  <h1 class="h3 mb-0"><i class="fa-solid fa-bowl-food me-2"></i> Recetas</h1>
  <div class="d-flex gap-2">
    <input id="q" type="text" class="form-control" placeholder="Buscar receta...">
    <button id="btn-search" class="btn btn-primary"><i class="fa-solid fa-search me-1"></i> Buscar</button>
    <a href="{{ url('/recetas/nueva') }}" class="btn btn-success"><i class="fa-solid fa-plus me-1"></i> Nueva receta</a>
  </div>
</div>

<div class="card shadow-sm">
  <div class="table-responsive">
    <table class="table table-sm table-striped mb-0" id="tbl-recetas">
      <thead class="table-light">
        <tr>
          <th>Código</th><th>Nombre</th><th>Rendimiento</th><th>Unidad</th><th class="text-end">Costo</th><th class="text-end">Acciones</th>
        </tr>
      </thead>
      <tbody>
        {{-- JS --}}
      </tbody>
    </table>
  </div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', () => {
  const fmt = (n) => new Intl.NumberFormat('es-MX',{style:'currency',currency:'MXN'}).format(n||0);
  const tb = document.querySelector('#tbl-recetas tbody');

  function load(q='') {
    const demo = [
      {cod:'RC-001', nom:'Capuchino 12oz', rend:1, u:'pz', costo:19.5},
      {cod:'RC-002', nom:'Latte 16oz',     rend:1, u:'pz', costo:22.2},
    ].filter(r => !q || (r.cod+r.nom).toLowerCase().includes(q.toLowerCase()));

    tb.innerHTML = demo.map(r => `
      <tr>
        <td>${r.cod}</td><td>${r.nom}</td><td>${r.rend}</td><td>${r.u}</td>
        <td class="text-end">${fmt(r.costo)}</td>
        <td class="text-end">
          <a class="btn btn-sm btn-outline-primary" href="{{ url('/recetas/editar') }}/${r.cod}">
            <i class="fa-regular fa-pen-to-square"></i>
          </a>
        </td>
      </tr>
    `).join('');
  }

  document.getElementById('btn-search').addEventListener('click', () => load(document.getElementById('q').value || ''));
  load();
});
</script>
@endpush
