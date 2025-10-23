<?php

namespace Tests\Feature\People;

use App\Models\User;
use Illuminate\Support\Facades\Gate;
use Tests\TestCase;

class UsersAccessTest extends TestCase
{
    public function test_guest_is_redirected_from_personal(): void
    {
        $response = $this->get('/personal');

        $response->assertRedirect('/login');
    }

    public function test_user_without_permission_gets_forbidden(): void
    {
        Gate::define('people.view', fn () => false);
        $user = User::factory()->make();
        $this->be($user);

        $response = $this->get('/personal');

        $response->assertForbidden();
    }

    public function test_user_with_permission_can_view_personal(): void
    {
        Gate::define('people.view', fn () => true);
        Gate::define('people.users.manage', fn () => true);
        Gate::define('people.roles.manage', fn () => true);

        $user = User::factory()->make();
        $this->be($user);

        $response = $this->get('/personal');

        $response->assertOk();
    }
}
