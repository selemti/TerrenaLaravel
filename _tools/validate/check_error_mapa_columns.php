<?php
// Read .env file manually to get database credentials
$lines = file('.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
$env = [];
foreach ($lines as $line) {
    if (strpos($line, '=') !== false && strpos($line, '#') !== 0) {
        list($key, $value) = explode('=', $line, 2);
        $env[$key] = $value;
    }
}

// Database configuration
$host = '172.24.240.1'; // Using WSL IP instead of localhost
$port = $env['DB_PORT'] ?? '5433';
$dbname = $env['DB_DATABASE'] ?? 'pos';
$username = $env['DB_USERNAME'] ?? 'postgres';
$password = trim($env['DB_PASSWORD'], '"'); // Remove quotes from password

try {
    // Create PDO connection
    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname;user=$username;password=$password;";
    $pdo = new PDO($dsn);
    
    // Test the connection
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "Successfully connected to the database!\n";
    
    // Check for specific columns that were marked as ERROR_MAPA in Seguridad module
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
        AND column_name IN ('id', 'name', 'email', 'email_verified_at', 'password', 'remember_token', 'created_at', 'updated_at')
    ");
    $stmt->execute();
    $userColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nPublic.users columns that exist in database:\n";
    foreach ($userColumns as $col) {
        echo "- $col\n";
    }
    
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'model_has_permissions'
        AND column_name IN ('id', 'permission_id', 'model_type', 'model_id')
    ");
    $stmt->execute();
    $modelHasPermissionsColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nPublic.model_has_permissions columns that exist in database:\n";
    foreach ($modelHasPermissionsColumns as $col) {
        echo "- $col\n";
    }
    
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'model_has_roles'
        AND column_name IN ('id', 'role_id', 'model_type', 'model_id')
    ");
    $stmt->execute();
    $modelHasRolesColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nPublic.model_has_roles columns that exist in database:\n";
    foreach ($modelHasRolesColumns as $col) {
        echo "- $col\n";
    }
    
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'permissions'
        AND column_name IN ('id', 'name', 'guard_name', 'created_at', 'updated_at')
    ");
    $stmt->execute();
    $permissionsColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nPublic.permissions columns that exist in database:\n";
    foreach ($permissionsColumns as $col) {
        echo "- $col\n";
    }
    
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'roles'
        AND column_name IN ('id', 'name', 'guard_name', 'created_at', 'updated_at')
    ");
    $stmt->execute();
    $rolesColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nPublic.roles columns that exist in database:\n";
    foreach ($rolesColumns as $col) {
        echo "- $col\n";
    }
    
    // Check cat_almacenes columns for Catalogos module
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'selemti' 
        AND table_name = 'cat_almacenes'
        AND column_name IN ('codigo', 'descripcion')
    ");
    $stmt->execute();
    $catAlmacenesColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nSelemti.cat_almacenes columns that exist in database:\n";
    foreach ($catAlmacenesColumns as $col) {
        echo "- $col\n";
    }
    
    // Check cat_sucursales columns for Catalogos module
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'selemti' 
        AND table_name = 'cat_sucursales'
        AND column_name IN ('codigo', 'direccion')
    ");
    $stmt->execute();
    $catSucursalesColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nSelemti.cat_sucursales columns that exist in database:\n";
    foreach ($catSucursalesColumns as $col) {
        echo "- $col\n";
    }
    
    $pdo = null;
    echo "\nVerification completed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}