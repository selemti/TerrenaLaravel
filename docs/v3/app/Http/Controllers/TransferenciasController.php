<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;

class TransferenciasController extends Controller {
    public function index() { return response()->json(['ok'=>true]); }
    public function store(Request $r) { return response()->json(['ok'=>true,'data'=>$r->all()]); }
    public function show($id) { return response()->json(['ok'=>true,'id'=>$id]); }
    public function update(Request $r,$id) { return response()->json(['ok'=>true,'id'=>$id,'data'=>$r->all()]); }
    public function destroy($id) { return response()->json(['ok'=>true,'id'=>$id]); }
}