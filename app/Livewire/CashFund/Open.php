<?php

namespace App\Livewire\CashFund;

use App\Models\CashFund;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

/**
 * Componente para apertura de fondo de caja chica
 *
 * Guarda directamente en la tabla cash_funds
 */
class Open extends Component
{
    public array $form = [
        'sucursal_id' => null,
        'fecha' => '',
        'monto_inicial' => '',
        'moneda' => 'MXN',
        'descripcion' => '',
        'responsable_user_id' => null,
    ];

    public array $sucursales = [];
    public array $usuarios = [];
    public bool $loading = false;

    public function mount(): void
    {
        $this->form['fecha'] = now()->format('Y-m-d');
        $this->loadSucursales();
        $this->loadUsuarios();

        // Pre-seleccionar sucursal si el usuario tiene una asignada
        if (count($this->sucursales) === 1) {
            $this->form['sucursal_id'] = $this->sucursales[0]['id'];
        }

        // Pre-seleccionar usuario actual como responsable
        $this->form['responsable_user_id'] = Auth::id();
    }

    public function save()
    {
        $this->validate($this->rules(), $this->messages());

        $this->loading = true;

        try {
            DB::transaction(function () {
                // Crear el fondo en la base de datos
                $fondo = CashFund::create([
                    'sucursal_id' => $this->form['sucursal_id'],
                    'fecha' => $this->form['fecha'],
                    'monto_inicial' => $this->form['monto_inicial'],
                    'moneda' => $this->form['moneda'],
                    'descripcion' => $this->form['descripcion'] ?: null,
                    'estado' => 'ABIERTO',
                    'responsable_user_id' => $this->form['responsable_user_id'],
                    'created_by_user_id' => Auth::id(),
                ]);

                $this->dispatch('toast',
                    type: 'success',
                    body: "Fondo #{$fondo->id} abierto correctamente"
                );

                // Redirigir a la pantalla de movimientos
                return redirect()->route('cashfund.movements', ['id' => $fondo->id]);
            });
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al crear el fondo: ' . $e->getMessage()
            );
        } finally {
            $this->loading = false;
        }
    }

    public function render()
    {
        return view('livewire.cash-fund.open')
            ->layout('layouts.terrena', [
                'active' => 'caja',
                'title' => 'Apertura de Fondo · Caja Chica',
                'pageTitle' => 'Apertura de Fondo de Caja Chica',
            ]);
    }

    protected function rules(): array
    {
        return [
            'form.sucursal_id' => 'required|integer',
            'form.fecha' => 'required|date|before_or_equal:today',
            'form.monto_inicial' => 'required|numeric|min:0.01|max:999999.99',
            'form.moneda' => 'required|in:MXN,USD',
            'form.descripcion' => 'nullable|string|max:255',
            'form.responsable_user_id' => 'required|exists:users,id',
        ];
    }

    protected function messages(): array
    {
        return [
            'form.sucursal_id.required' => 'Selecciona una sucursal',
            'form.fecha.required' => 'La fecha es obligatoria',
            'form.fecha.before_or_equal' => 'La fecha no puede ser futura',
            'form.monto_inicial.required' => 'El monto inicial es obligatorio',
            'form.monto_inicial.min' => 'El monto debe ser mayor a cero',
            'form.monto_inicial.max' => 'El monto no puede exceder $999,999.99',
            'form.moneda.required' => 'Selecciona una moneda',
            'form.moneda.in' => 'La moneda debe ser MXN o USD',
            'form.responsable_user_id.required' => 'Selecciona un responsable',
            'form.responsable_user_id.exists' => 'El usuario seleccionado no es válido',
        ];
    }

    protected function loadSucursales(): void
    {
        try {
            $this->sucursales = DB::connection('pgsql')
                ->table('selemti.cat_sucursales')
                ->where('activo', true)
                ->orderBy('nombre')
                ->get(['id', 'nombre', 'clave'])
                ->map(fn($row) => [
                    'id' => (int) $row->id,
                    'nombre' => trim(($row->clave ? "{$row->clave} - " : '') . $row->nombre),
                ])
                ->toArray();
        } catch (\Exception $e) {
            // Si falla la consulta, usar mock mínimo
            $this->sucursales = [
                ['id' => 1, 'nombre' => 'PRINCIPAL - Sucursal Principal'],
            ];
        }
    }

    protected function loadUsuarios(): void
    {
        $this->usuarios = User::orderBy('nombre_completo')
            ->get(['id', 'nombre_completo', 'email'])
            ->map(fn($user) => [
                'id' => $user->id,
                'nombre' => $user->nombre_completo,
            ])
            ->toArray();
    }
}
