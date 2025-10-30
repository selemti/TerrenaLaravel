<?php

namespace App\Livewire\Inventory;

use Illuminate\Support\Facades\Http;
use Livewire\Component;

class ReceptionDetail extends Component
{
    public int $recepcionId;
    public string $estado = 'EN_PROCESO';
    public bool $requiere_aprobacion = false;
    public array $lineas = [];
    public bool $canValidate = false;
    public bool $canOverride = false;
    public bool $canPost = false;

    /**
     * Inicializa el componente con la recepción objetivo.
     *
     * @param int|string $id
     * @return void
     */
    public function mount($id): void
    {
        $this->recepcionId = (int) $id;
        $this->refreshData();
    }

    private function refreshData(): void
    {
        // TODO: usar autenticación real (token/session) al consumir la API en producción.
        $receptionResponse = Http::get("/api/purchasing/receptions/{$this->recepcionId}");

        if ($receptionResponse->successful() && ($receptionResponse['ok'] ?? false)) {
            $data = $receptionResponse['data'] ?? [];
            $this->estado = $data['estado'] ?? $this->estado;
            $this->requiere_aprobacion = (bool) ($data['requiere_aprobacion'] ?? false);
            $this->lineas = $data['lineas'] ?? [];
        } else {
            // TODO: manejar errores (logs/notificaciones) cuando la API no responda.
        }

        // TODO: usar autenticación real (token/session) al consumir la API en producción.
        $permissionsResponse = Http::get('/api/me/permissions');
        if ($permissionsResponse->successful() && ($permissionsResponse['ok'] ?? false)) {
            $perms = $permissionsResponse['data']['permissions'] ?? [];
            $this->canValidate = in_array('inventory.receptions.validate', $perms, true);
            $this->canOverride = in_array('inventory.receptions.override_tolerance', $perms, true);
            $this->canPost = in_array('inventory.receptions.post', $perms, true);
        } else {
            // TODO: manejar errores cuando no se puedan obtener permisos.
        }
    }

    public function actionValidate(): void
    {
        // TODO: agregar manejo de errores/autorización real para la llamada POST.
        $response = Http::post("/api/purchasing/receptions/{$this->recepcionId}/validate");
        if (!($response->successful() && ($response['ok'] ?? false))) {
            // TODO: manejar errores si la petición falla (notificar al usuario, etc.).
        }
        $this->refreshData();
    }

    public function actionApprove(): void
    {
        // TODO: agregar manejo de errores/autorización real para la llamada POST.
        $response = Http::post("/api/purchasing/receptions/{$this->recepcionId}/approve");
        if (!($response->successful() && ($response['ok'] ?? false))) {
            // TODO: manejar errores si la petición falla (notificar al usuario, etc.).
        }
        $this->refreshData();
    }

    public function actionPost(): void
    {
        // TODO: agregar manejo de errores/autorización real para la llamada POST.
        $response = Http::post("/api/purchasing/receptions/{$this->recepcionId}/post");
        if (!($response->successful() && ($response['ok'] ?? false))) {
            // TODO: manejar errores si la petición falla (notificar al usuario, etc.).
        }
        $this->refreshData();
    }

    public function render()
    {
        return view('livewire.inventory.reception-detail');
    }
}
