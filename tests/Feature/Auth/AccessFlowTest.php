<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Tests\TestCase;

class AccessFlowTest extends TestCase
{
    public function test_guest_is_redirected_from_dashboard(): void
    {
        $response = $this->get('/dashboard');

        $response->assertRedirect('/login');
    }

    public function test_authenticated_user_can_view_dashboard(): void
    {
        $user = User::factory()->make([
            'id' => 1,
            'email' => 'support@selemti.com',
            'nombre_completo' => 'Soporte Terrena',
        ]);

        $this->be($user);

        $response = $this->get('/dashboard');

        $response->assertOk();
    }

    public function test_logout_redirects_to_home(): void
    {
        $user = User::factory()->make([
            'id' => 2,
            'email' => 'tester@example.com',
            'nombre_completo' => 'Tester',
        ]);

        $this->be($user);

        $response = $this->get('/logout');

        $response->assertRedirect('/');
    }
}
