<?php

namespace Tests\Feature\Inventory;

use Illuminate\Contracts\Auth\Authenticatable;
use Tests\TestCase;

class PriceApiAuthTest extends TestCase
{
    public function test_guest_cannot_store_vendor_price(): void
    {
        $response = $this->postJson('/api/inventory/prices', []);

        $response->assertStatus(401);
    }

    public function test_user_without_permission_gets_forbidden(): void
    {
        $this->actingAs($this->fakeUser(false), 'web');

        $response = $this->postJson('/api/inventory/prices', [
            'item_id' => '1',
            'vendor_id' => '1',
            'price' => 10,
            'pack_qty' => 1,
            'pack_uom' => 'KG',
        ]);

        $response->assertStatus(403);
    }

    public function test_user_with_permission_reaches_validation_layer(): void
    {
        $this->actingAs($this->fakeUser(true), 'web');

        $response = $this->postJson('/api/inventory/prices', []);

        $response->assertStatus(422);
    }

    protected function fakeUser(bool $authorized): Authenticatable
    {
        return new class($authorized) implements Authenticatable, \Illuminate\Contracts\Auth\Access\Authorizable {
            public function __construct(private bool $authorized)
            {
            }

            public function getAuthIdentifierName()
            {
                return 'id';
            }

            public function getAuthIdentifier()
            {
                return 1;
            }

            public function getAuthPassword()
            {
                return 'secret';
            }

            public function getAuthPasswordName()
            {
                return 'password_hash';
            }

            public function getRememberToken()
            {
                return null;
            }

            public function setRememberToken($value): void
            {
            }

            public function getRememberTokenName()
            {
                return 'remember_token';
            }

            public function can($ability, $arguments = [])
            {
                if ($ability === 'inventory.prices.manage') {
                    return $this->authorized;
                }

                return false;
            }

            public function cannot($ability, $arguments = [])
            {
                return ! $this->can($ability, $arguments);
            }

            public function hasRole($roles)
            {
                if (is_array($roles)) {
                    return in_array('inventario.manager', $roles, true) && $this->authorized;
                }

                return $roles === 'inventario.manager' && $this->authorized;
            }
        };
    }
}
