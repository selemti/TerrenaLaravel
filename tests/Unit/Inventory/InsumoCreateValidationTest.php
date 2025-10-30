<?php

namespace Tests\Unit\Inventory;

use App\Livewire\Inventory\InsumoCreate;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class InsumoCreateValidationTest extends TestCase
{
    public function test_um_id_is_required(): void
    {
        /** @var InsumoCreate $component */
        $component = app(InsumoCreate::class);
        $component->authorized = true;
        $component->units = [
            ['id' => 1, 'clave' => 'KG', 'nombre' => 'Kilogramo'],
        ];
        $component->categoria = 'MP';
        $component->subcategoria = 'LAC';
        $component->nombre = 'Harina de trigo';
        $component->merma_pct = 0.0;

        $this->expectException(ValidationException::class);

        $component->save();
    }

    public function test_um_id_must_belong_to_allowed_units(): void
    {
        /** @var InsumoCreate $component */
        $component = app(InsumoCreate::class);
        $component->authorized = true;
        $component->units = [
            ['id' => 1, 'clave' => 'KG', 'nombre' => 'Kilogramo'],
        ];
        $component->categoria = 'MP';
        $component->subcategoria = 'LAC';
        $component->nombre = 'Leche entera';
        $component->merma_pct = 0.0;
        $component->um_id = 999; // No está en units

        $this->expectException(ValidationException::class);

        $component->save();
    }
}
