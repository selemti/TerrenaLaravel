@extends('layouts.terrena')
@section('title','Detalle Unidad')
@section('page-title')<h2 class="mb-0">Detalle Unidad</h2>@endsection
@section('content')
  <dl class="row">
    <dt class="col-sm-3">Código</dt><dd class="col-sm-9">{{ $unidad->codigo }}</dd>
    <dt class="col-sm-3">Nombre</dt><dd class="col-sm-9">{{ $unidad->nombre }}</dd>
    <dt class="col-sm-3">Tipo</dt><dd class="col-sm-9">{{ $unidad->tipo }}</dd>
    <dt class="col-sm-3">Categoría</dt><dd class="col-sm-9">{{ $unidad->categoria }}</dd>
    <dt class="col-sm-3">Base</dt><dd class="col-sm-9">{{ $unidad->es_base ? 'Sí' : 'No' }}</dd>
    <dt class="col-sm-3">Decimales</dt><dd class="col-sm-9">{{ $unidad->decimales }}</dd>
  </dl>
  <div class="d-flex gap-2">
    <a href="{{ route('catalogos.unidades.edit',$unidad->id) }}" class="btn btn-secondary">Editar</a>
    <a href="{{ route('catalogos.unidades.index') }}" class="btn btn-light">Volver</a>
  </div>
@endsection
