@extends('layouts.terrena')

@section('title', $title ?? 'Página')
@section('page-title')
  <i class="fa-solid fa-file"></i> <span class="label">{{ $title ?? 'Página' }}</span>
@endsection

@section('content')
@include('partials.under-construction')
@endsection