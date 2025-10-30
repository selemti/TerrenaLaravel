<?php

namespace App\Livewire\Audit;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class LogViewer extends Component
{
    public $desde;
    public $hasta;
    public $userId;
    public $module;
    public $search;
    
    public $rows = [];
    public $selectedLog = null;
    public $usersList = [];
    public $modulesList = [];
    
    public $isLoading = false;

    public function mount(): void
    {
        // Rango por defecto: último día
        $this->desde = now()->subDay()->format('Y-m-d');
        $this->hasta = now()->format('Y-m-d');
        
        // Cargar listas para filtros
        $this->loadUsersList();
        $this->loadModulesList();
        
        // Cargar datos iniciales
        $this->load();
    }

    public function load(): void
    {
        $this->isLoading = true;
        
        $query = AuditLog::query()
            ->with('user:id,nombre_completo,username')
            ->orderBy('timestamp', 'desc')
            ->limit(50);

        // Aplicar filtros
        if ($this->desde) {
            $query->whereDate('timestamp', '>=', $this->desde);
        }

        if ($this->hasta) {
            $query->whereDate('timestamp', '<=', $this->hasta);
        }

        if ($this->userId) {
            $query->where('user_id', $this->userId);
        }

        if ($this->module) {
            $query->where('entidad', $this->module);
        }

        if ($this->search) {
            $search = strtolower(trim($this->search));
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(accion) ILIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(entidad_id::text) ILIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(motivo) ILIKE ?', ["%{$search}%"])
                    ->orWhereHas('user', function ($subQuery) use ($search) {
                        $subQuery->whereRaw('LOWER(nombre_completo) ILIKE ?', ["%{$search}%"])
                            ->orWhereRaw('LOWER(username) ILIKE ?', ["%{$search}%"]);
                    });
            });
        }

        $this->rows = $query->get()->map(function ($log) {
            return [
                'id' => $log->id,
                'timestamp' => $log->timestamp->format('Y-m-d H:i:s'),
                'username' => $log->user?->username ?? '—',
                'user_full_name' => $log->user?->nombre_completo ?? '—',
                'module' => $log->module_name,
                'action' => $log->accion,
                'entity' => $log->entity_description,
                'entity_type' => $log->entidad,
                'entity_id' => $log->entidad_id,
                'reason' => $log->motivo,
                'evidence_url' => $log->evidencia_url,
                'has_payload' => !empty($log->payload_json),
            ];
        })->toArray();
        
        $this->isLoading = false;
    }

    public function selectLog(int $id): void
    {
        $log = AuditLog::with('user')->findOrFail($id);
        
        $this->selectedLog = [
            'id' => $log->id,
            'timestamp' => $log->timestamp->format('Y-m-d H:i:s'),
            'user' => [
                'id' => $log->user?->id,
                'username' => $log->user?->username,
                'full_name' => $log->user?->nombre_completo,
            ],
            'module' => $log->module_name,
            'action' => $log->accion,
            'entity' => $log->entity_description,
            'entity_type' => $log->entidad,
            'entity_id' => $log->entidad_id,
            'reason' => $log->motivo,
            'evidence_url' => $log->evidencia_url,
            'payload' => $log->payload_json,
        ];
        
        $this->dispatch('show-log-detail');
    }

    public function closeLogDetail(): void
    {
        $this->selectedLog = null;
    }

    protected function loadUsersList(): void
    {
        $this->usersList = User::query()
            ->select('id', 'username', 'nombre_completo')
            ->orderBy('nombre_completo')
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'username' => $user->username,
                    'full_name' => $user->nombre_completo,
                ];
            })
            ->toArray();
    }

    protected function loadModulesList(): void
    {
        $modules = DB::connection('pgsql')
            ->table('selemti.audit_log')
            ->select('entidad')
            ->distinct()
            ->whereNotNull('entidad')
            ->orderBy('entidad')
            ->pluck('entidad')
            ->toArray();

        // Agregar módulos conocidos incluso si no hay registros aún
        $knownModules = [
            'inventario',
            'transferencia',
            'pos',
            'caja_chica',
            'recetas',
            'produccion',
        ];

        $this->modulesList = array_unique(array_merge($modules, $knownModules));
        sort($this->modulesList);
    }

    public function render()
    {
        return view('livewire.audit.log-viewer');
    }
}