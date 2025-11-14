<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\Sucursal;
use Illuminate\Validation\Rule;
use Livewire\Attributes\On;
use Livewire\Component;
use Livewire\WithPagination;

class SucursalesIndex extends Component
{
    use WithPagination;

    protected string $paginationTheme = 'bootstrap';

    public string $search = '';

    public ?int $editId = null;

    public string $clave = '';

    public string $nombre = '';

    public string $ubicacion = '';

    public ?string $pos_location = null;

    public bool $activo = true;

    protected function rules(): array
    {
        return [
            'clave' => [
                // Solo requerida en edición, en creación se genera automáticamente
                $this->editId ? 'required' : 'nullable',
                'string',
                'max:16',
                Rule::unique('cat_sucursales', 'clave')->ignore($this->editId),
            ],
            'nombre' => ['required', 'string', 'max:120'],
            'ubicacion' => ['nullable', 'string', 'max:160'],
            'pos_location' => ['nullable', 'string', 'max:64'],
            'activo' => ['boolean'],
        ];
    }

    private function resetForm(): void
    {
        $this->reset(['editId', 'clave', 'nombre', 'ubicacion', 'pos_location']);
        $this->activo = true;
    }

    public function create()
    {
        $this->resetForm();
        $this->dispatch('toggle-sucursal-modal', open: true);
    }

    public function edit(int $id)
    {
        $sucursal = Sucursal::findOrFail($id);

        $this->editId = $sucursal->id;
        $this->clave = $sucursal->clave;
        $this->nombre = $sucursal->nombre;
        $this->ubicacion = $sucursal->ubicacion ?? '';
        $this->pos_location = $sucursal->pos_location;
        $this->activo = (bool) $sucursal->activo;
        $this->dispatch('toggle-sucursal-modal', open: true);
    }

    public function save()
    {
        $this->validate();

        // Generar clave automáticamente si es nuevo registro
        if (! $this->editId) {
            $this->clave = $this->generateUniqueClave($this->nombre);
        }

        $payload = [
            'clave' => strtoupper(trim($this->clave)),
            'nombre' => trim($this->nombre),
            'ubicacion' => $this->ubicacion ? trim($this->ubicacion) : null,
            'pos_location' => $this->pos_location ?: null,
            'activo' => (bool) $this->activo,
        ];

        if ($this->editId) {
            Sucursal::findOrFail($this->editId)->update($payload);
        } else {
            Sucursal::create($payload);
        }

        $this->resetForm();
        session()->flash('ok', 'Sucursal guardada');
        $this->dispatch('toggle-sucursal-modal', open: false);
    }

    /**
     * Genera una clave única basada en el nombre
     */
    private function generateUniqueClave(string $nombre): string
    {
        // Crear slug del nombre (primeras letras significativas)
        $words = explode(' ', trim($nombre));

        // Si es una palabra, tomar los primeros 3-6 caracteres
        if (count($words) === 1) {
            $base = strtoupper(substr($words[0], 0, 6));
        } else {
            // Si son múltiples palabras, tomar iniciales o primeras letras
            $base = '';
            foreach ($words as $word) {
                if (strlen($word) > 2) { // Ignorar palabras muy cortas como "de", "la", etc.
                    $base .= strtoupper(substr($word, 0, 1));
                }
            }
            // Si el resultado es muy corto, complementar con letras del primer word
            if (strlen($base) < 3) {
                $base = strtoupper(substr($words[0], 0, 6));
            }
        }

        // Limitar a 10 caracteres máximo
        $base = substr($base, 0, 10);

        // Verificar si ya existe
        $clave = $base;
        $counter = 1;

        while (Sucursal::where('clave', $clave)->exists()) {
            $clave = $base.$counter;
            $counter++;
        }

        return $clave;
    }

    public function delete(int $id)
    {
        Sucursal::whereKey($id)->delete();
        session()->flash('ok', 'Sucursal eliminada');
        $this->resetForm();
        $this->dispatch('toggle-sucursal-modal', open: false);
    }

    public function closeModal(): void
    {
        $this->resetForm();
        $this->dispatch('toggle-sucursal-modal', open: false);
    }

    /**
     * Vincular rápidamente una location del POS creando una nueva sucursal
     */
    public function linkPosLocation(string $location)
    {
        // Generar nombre sugerido basado en la location
        $nombre = 'Sucursal '.ucfirst(strtolower($location));
        $clave = $this->generateUniqueClave($nombre);

        Sucursal::create([
            'clave' => $clave,
            'nombre' => $nombre,
            'ubicacion' => null,
            'pos_location' => $location,
            'activo' => true,
        ]);

        session()->flash('ok', "Sucursal vinculada: $nombre → POS Location: $location");
    }

    /**
     * Abrir modal para editar/vincular una location específica
     */
    public function createWithPosLocation(string $location)
    {
        $this->resetForm();
        $this->pos_location = $location;
        $this->nombre = 'Sucursal '.ucfirst(strtolower($location));
        $this->dispatch('toggle-sucursal-modal', open: true);
    }

    public function render()
    {
        $rows = Sucursal::query()
            ->when($this->search !== '', function ($query) {
                $needle = '%'.$this->search.'%';
                $query->where(function ($sub) use ($needle) {
                    $sub->where('clave', 'ilike', $needle)
                        ->orWhere('nombre', 'ilike', $needle)
                        ->orWhere('ubicacion', 'ilike', $needle)
                        ->orWhere('pos_location', 'ilike', $needle);
                });
            })
            ->orderBy('clave')
            ->paginate(10);

        // Get available POS locations from public.terminal
        $posLocations = Sucursal::getAvailablePosLocations();

        // Get unlinked POS locations (exist in POS but not linked to any sucursal)
        $unlinkedPosLocations = Sucursal::getUnlinkedPosLocations();

        return view('livewire.catalogs.sucursales-index', compact('rows', 'posLocations', 'unlinkedPosLocations'))
            ->layout('layouts.terrena', [
                'active' => 'config',
                'title' => 'Catálogo · Sucursales',
                'pageTitle' => 'Sucursales',
            ]);
    }

    #[On('sucursal-modal-closed')]
    public function handleModalClosed(): void
    {
        $this->resetForm();
    }
}
