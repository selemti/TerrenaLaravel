@extends('layouts.terrena')
@section('title','Nueva Unidad')
@section('page-title')<h2 class="mb-0">Nueva Unidad</h2>@endsection
@section('content')
  <form method="post" action="{{ route('catalogos.unidades.store') }}">
    @include('catalogs.unidades._form')
  </form>
@endsection
