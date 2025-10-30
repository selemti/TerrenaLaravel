@extends('layouts.terrena', ['active' => 'inventory'])

@section('title', 'Conteos Físicos')

@section('content')
<div>
    @livewire('inventory.inventory-counts-index')
</div>
@endsection