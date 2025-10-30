<?php

namespace App\Livewire\Inventory;

use Livewire\Component;
use Illuminate\Support\Facades\Http;

/**
 * Pantalla operativa para una transferencia entre almacenes/sucursales.
 * Estados esperados (ejemplo): DRAFT → APROBADA → EN_CAMINO → RECIBIDA → POSTEADA.
 * Similar a las recepciones, esta vista:
 * - Lee permisos vía /api/me/permissions
 * - Lee datos de la transferencia vía API
 * - Muestra botones según permisos
 *
 * TODO:
 *  - Autenticación real (token/session) en llamadas Http::get()/post()
 *  - Manejo de errores / flashes al usuario
 *  - Amarrar esto a políticas reales de inventario
 */
class TransferDetail extends Component
{
    public int $transferId;

    // Datos visibles en encabezado / estado:
    public string $estado = 'DRAFT';
    public string $origen_nombre = '';
    public string $destino_nombre = '';
    public array $lineas = [];

    // Permisos / acciones disponibles en UI:
    public bool $canApprove = false; // inventory.transfers.approve
    public bool $canShip    = false; // inventory.transfers.ship
    public bool $canReceive = false; // inventory.transfers.receive
    public bool $canPost    = false; // inventory.transfers.post  (cerrar kardex)

    /**
     * mount: inicializa el componente con el ID de la transferencia.
     * Luego dispara refreshData() para consultar API.
     */
    public function mount($id): void
    {
        $this->transferId = (int) $id;
        $this->refreshData();
    }

    /**
     * Refresca datos desde backend:
     * - GET /api/inventory/transfers/{transfer_id}  (detalle operativo de la transferencia)
     * - GET /api/me/permissions                    (permisos asignados al usuario actual)
     *
     * Estructura esperada del GET /api/inventory/transfers/{id}:
     * {
     *   "ok": true,
     *   "data": {
     *     "transfer_id": 77,
     *     "estado": "EN_CAMINO",
     *     "origen_nombre": "Bodega Central",
     *     "destino_nombre": "Sucursal Reforma",
     *     "lineas": [
     *       {
     *         "item_id": 45,
     *         "item_nombre": "Papas saco 20kg",
     *         "qty_enviada": "5.000000",
     *         "qty_recibida": "0.000000",
     *         "uom": "KG"
     *       }
     *     ]
     *   }
     * }
     */
    private function refreshData(): void
    {
        // TODO: usar autenticación real y manejo de errores.
        $transferResp = Http::get("/api/inventory/transfers/{$this->transferId}");
        if ($transferResp->successful() && ($transferResp['ok'] ?? false)) {
            $data = $transferResp['data'] ?? [];
            $this->estado         = $data['estado']         ?? $this->estado;
            $this->origen_nombre  = $data['origen_nombre']  ?? $this->origen_nombre;
            $this->destino_nombre = $data['destino_nombre'] ?? $this->destino_nombre;
            $this->lineas         = $data['lineas']         ?? [];
        } else {
            // TODO: log / notificar error al usuario
        }

        // TODO: usar autenticación real y manejo de errores.
        $permResp = Http::get('/api/me/permissions');
        if ($permResp->successful() && ($permResp['ok'] ?? false)) {
            $perms = $permResp['data']['permissions'] ?? [];

            $this->canApprove = in_array('inventory.transfers.approve', $perms, true);
            $this->canShip    = in_array('inventory.transfers.ship', $perms, true);
            $this->canReceive = in_array('inventory.transfers.receive', $perms, true);
            $this->canPost    = in_array('inventory.transfers.post', $perms, true);
        } else {
            // TODO: log / notificar error permisos
        }
    }

    /**
     * Acciones operativas.
     * Cada una:
     *  - POST al endpoint REST correspondiente
     *  - si ok === true, llamamos $this->refreshData() para reflejar nuevos estados/botones
     *
     * IMPORTANTE: por ahora sólo stub. No manejar errores finos.
     */

    public function actionApprove(): void
    {
        // requires: inventory.transfers.approve
        $resp = Http::post("/api/inventory/transfers/{$this->transferId}/approve");
        if (!($resp->successful() && ($resp['ok'] ?? false))) {
            // TODO: manejar error
        }
        $this->refreshData();
    }

    public function actionShip(): void
    {
        // requires: inventory.transfers.ship
        $resp = Http::post("/api/inventory/transfers/{$this->transferId}/ship");
        if (!($resp->successful() && ($resp['ok'] ?? false))) {
            // TODO: manejar error
        }
        $this->refreshData();
    }

    public function actionReceive(): void
    {
        // requires: inventory.transfers.receive
        $resp = Http::post("/api/inventory/transfers/{$this->transferId}/receive");
        if (!($resp->successful() && ($resp['ok'] ?? false))) {
            // TODO: manejar error
        }
        $this->refreshData();
    }

    public function actionPost(): void
    {
        // requires: inventory.transfers.post
        $resp = Http::post("/api/inventory/transfers/{$this->transferId}/post");
        if (!($resp->successful() && ($resp['ok'] ?? false))) {
            // TODO: manejar error
        }
        $this->refreshData();
    }

    public function render()
    {
        return view('livewire.inventory.transfer-detail');
    }
}
