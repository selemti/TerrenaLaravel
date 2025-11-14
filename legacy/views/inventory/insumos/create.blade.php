@extends('layouts.terrena')

@section('page-title')
    <i class="fa-solid fa-boxes-stacked me-1"></i> Alta de insumo
@endsection

@section('content')
    <div class="container-fluid">
        <livewire:inventory.insumo-create />
    </div>
@endsection
