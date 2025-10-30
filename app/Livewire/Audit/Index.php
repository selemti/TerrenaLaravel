<?php

namespace App\Livewire\Audit;

use Livewire\Component;

/**
 * Componente Livewire para el dashboard de auditoría operativa
 * 
 * Este componente permite a usuarios con permisos filtrar y visualizar
 * registros de auditoría en una interfaz web.
 */
class Index extends Component
{
    public $user_id = '';
    public $accion = '';
    public $entidad = '';
    public $entidad_id = '';
    public $date_from = '';
    public $date_to = '';

    public $rows = [];

    public function mount()
    {
        // Opcionalmente setear date_from = hoy-1
        $this->date_from = now()->subDay()->format('Y-m-d');
        $this->date_to = now()->format('Y-m-d');
    }

    /**
     * Buscar registros de auditoría
     * 
     * TODO: esto asume que el frontend ya tiene un token Sanctum válido.
     * En el futuro, se deberá obtener el token de forma segura (posiblemente
     * desde la sesión del usuario autenticado) para hacer la solicitud HTTP.
     */
    public function search()
    {
        // En una implementación completa, se usaría el token Sanctum del usuario
        // para hacer la solicitud al endpoint API. Por ahora, usamos un enfoque
        // que requiere que el token esté disponible en el frontend.
        
        // Ejemplo de cómo se haría con Http::withToken():
        // $response = Http::withToken(session('sanctum_token')) // Esto es un ejemplo
        //     ->get(config('app.url') . '/api/audit/logs', [
        //         'user_id' => $this->user_id,
        //         'accion' => $this->accion,
        //         'entidad' => $this->entidad,
        //         'entidad_id' => $this->entidad_id,
        //         'date_from' => $this->date_from,
        //         'date_to' => $this->date_to,
        //     ]);
        
        // Para este scaffolding, dejaremos que el frontend maneje la llamada
        // y simplemente devolveremos los filtros actuales para que se muestren
        // en el frontend
        
        // En lugar de hacer la llamada aquí, simplemente actualizamos
        // la propiedad para que el frontend pueda usar los datos
        $this->dispatch('audit-filters-updated', [
            'filters' => [
                'user_id' => $this->user_id,
                'accion' => $this->accion,
                'entidad' => $this->entidad,
                'entidad_id' => $this->entidad_id,
                'date_from' => $this->date_from,
                'date_to' => $this->date_to,
            ]
        ]);
    }

    public function render()
    {
        return view('livewire.audit.index');
    }
}