@extends('layouts.terrena')
@section('title','Editar Unidad')
@section('page-title')<h2 class="mb-0">Editar Unidad</h2>@endsection
@section('content')
  <form method="post" action="{{ route('catalogos.unidades.update',$unidad->id) }}">
    @method('PUT')
    @include('catalogs.unidades._form')
  </form>
@endsection
