@extends('layouts.terrena')
@section('title','Unidades de Medida')
@section('page-title')<h2 class="mb-0"><i class="fa-solid fa-ruler"></i> Unidades de Medida</h2>@endsection
@section('content')
  <div class="d-flex justify-content-between align-items-center mb-3">
    <form method="get" class="d-flex gap-2">
      <input type="text" class="form-control" name="q" placeholder="Buscar..." value="{{ $q }}" />
      <button class="btn btn-outline-secondary">Buscar</button>
    </form>
    <a class="btn btn-primary" href="{{ route('catalogos.unidades.create') }}">Nueva</a>
  </div>
  <div class="table-responsive bg-white shadow-sm rounded">
    <table class="table table-sm align-middle mb-0">
      <thead class="table-light"><tr><th>Código</th><th>Nombre</th><th>Tipo</th><th>Categoría</th><th>Base</th><th>Dec</th><th></th></tr></thead>
      <tbody>
        @forelse($rows as $r)
          <tr>
            <td>{{ $r->codigo }}</td>
            <td>{{ $r->nombre }}</td>
            <td>{{ $r->tipo }}</td>
            <td>{{ $r->categoria }}</td>
            <td>{!! $r->es_base ? '<span class="badge bg-success">Sí</span>' : '' !!}</td>
            <td>{{ $r->decimales }}</td>
            <td class="text-end">
              <a href="{{ route('catalogos.unidades.show',$r->id) }}" class="btn btn-light btn-sm">Ver</a>
              <a href="{{ route('catalogos.unidades.edit',$r->id) }}" class="btn btn-secondary btn-sm">Editar</a>
            </td>
          </tr>
        @empty
          <tr><td colspan="7" class="text-center text-secondary py-4">Sin resultados</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
  <div class="mt-2">{{ $rows->links() }}</div>
@endsection
