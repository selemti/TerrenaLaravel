<?php

require_once __DIR__ . '/vendor/autoload.php';

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "=== TESTING LOGIN SYSTEM ===" . PHP_EOL;

try {
    // Check if user table exists and has data
    echo "1. Checking users table..." . PHP_EOL;
    $userCount = \DB::table('users')->count();
    echo "   Total users in database: " . $userCount . PHP_EOL;

    // Find soporte user
    echo "2. Finding soporte@selemti.com..." . PHP_EOL;
    $user = \DB::table('users')->where('email', 'soporte@selemti.com')->first();

    if ($user) {
        echo "   ✓ User found!" . PHP_EOL;
        echo "   ID: " . $user->id . PHP_EOL;
        echo "   Name: " . $user->name . PHP_EOL;
        echo "   Email: " . $user->email . PHP_EOL;
        echo "   Email verified: " . ($user->email_verified_at ? 'YES' : 'NO') . PHP_EOL;

        // Test Laravel auth
        echo "3. Testing Laravel User model..." . PHP_EOL;
        $laravelUser = \App\Models\User::find($user->id);
        if ($laravelUser) {
            echo "   ✓ Laravel User model works!" . PHP_EOL;
            echo "   Permissions: ";
            $permissions = $laravelUser->getAllPermissions()->pluck('name')->toArray();
            echo implode(', ', $permissions) . PHP_EOL;
        } else {
            echo "   ✗ Laravel User model failed" . PHP_EOL;
        }

    } else {
        echo "   ✗ User NOT found!" . PHP_EOL;

        // Show all users for debugging
        $allUsers = \DB::table('users')->select('id', 'email', 'name')->get();
        echo "   Available users:" . PHP_EOL;
        foreach ($allUsers as $u) {
            echo "   - ID: {$u->id}, Email: {$u->email}, Name: {$u->name}" . PHP_EOL;
        }
    }

    echo PHP_EOL . "=== SYSTEM READY FOR LOGIN TEST ===" . PHP_EOL;

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . PHP_EOL;
    echo "File: " . $e->getFile() . PHP_EOL;
    echo "Line: " . $e->getLine() . PHP_EOL;
}