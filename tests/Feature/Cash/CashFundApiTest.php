<?php

namespace Tests\Feature\Cash;

use App\Services\Cash\CashFundService;
use Illuminate\Contracts\Auth\Authenticatable;
use Mockery;
use Tests\TestCase;

class CashFundApiTest extends TestCase
{
    public function tearDown(): void
    {
        parent::tearDown();
        Mockery::close();
    }

    public function test_guest_cannot_open_cash_fund(): void
    {
        $response = $this->postJson('/api/cash-funds', []);

        $response->assertStatus(401);
    }

    public function test_user_without_permission_is_forbidden(): void
    {
        $this->actingAs($this->fakeUser(false), 'web');

        $response = $this->postJson('/api/cash-funds', [
            'sucursal_id' => 1,
            'monto_inicial' => 100,
        ]);

        $response->assertStatus(403);
    }

    public function test_user_with_permission_can_open_cash_fund(): void
    {
        $this->actingAs($this->fakeUser(true), 'web');

        $mock = Mockery::mock(CashFundService::class);
        $mock->shouldReceive('open')->once()->andReturn(321);
        app()->instance(CashFundService::class, $mock);

        $payload = [
            'sucursal_id' => 99,
            'monto_inicial' => 1500,
            'usuarios' => [
                ['user_id' => 5, 'rol' => 'TITULAR'],
            ],
        ];

        $response = $this->postJson('/api/cash-funds', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('data.id', 321);
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
                if (in_array($ability, ['cashfund.manage', 'cashfund.view'], true)) {
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
                return false;
            }
        };
    }
}
