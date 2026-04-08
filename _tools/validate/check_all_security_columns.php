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
    
    // Check all columns that were marked as ERROR_MAPA in Seguridad module
    
    // Check for users table
    echo "\n### Public.users table columns:\n";
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
    ");
    $stmt->execute();
    $userColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($userColumns as $col) {
        echo "- $col\n";
    }
    
    // Check for model_has_permissions table
    echo "\n### Public.model_has_permissions table columns:\n";
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'model_has_permissions'
    ");
    $stmt->execute();
    $modelHasPermissionsColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($modelHasPermissionsColumns as $col) {
        echo "- $col\n";
    }
    
    // Check for model_has_roles table
    echo "\n### Public.model_has_roles table columns:\n";
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'model_has_roles'
    ");
    $stmt->execute();
    $modelHasRolesColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($modelHasRolesColumns as $col) {
        echo "- $col\n";
    }
    
    // Check for permissions table
    echo "\n### Public.permissions table columns:\n";
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'permissions'
    ");
    $stmt->execute();
    $permissionsColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($permissionsColumns as $col) {
        echo "- $col\n";
    }
    
    // Check for roles table
    echo "\n### Public.roles table columns:\n";
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'roles'
    ");
    $stmt->execute();
    $rolesColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($rolesColumns as $col) {
        echo "- $col\n";
    }
    
    // Check cat_almacenes columns for Catalogos module
    echo "\n### Selemti.cat_almacenes table columns:\n";
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'selemti' 
        AND table_name = 'cat_almacenes'
    ");
    $stmt->execute();
    $catAlmacenesColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($catAlmacenesColumns as $col) {
        echo "- $col\n";
    }
    
    // Check cat_sucursales columns for Catalogos module
    echo "\n### Selemti.cat_sucursales table columns:\n";
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'selemti' 
        AND table_name = 'cat_sucursales'
    ");
    $stmt->execute();
    $catSucursalesColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($catSucursalesColumns as $col) {
        echo "- $col\n";
    }
    
    // Check pos_map table for the meta column specifically
    echo "\n### Selemti.pos_map table columns:\n";
    $stmt = $pdo->prepare("
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'selemti' 
        AND table_name = 'pos_map'
    ");
    $stmt->execute();
    $posMapColumns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($posMapColumns as $col) {
        echo "- $col\n";
    }
    
    $pdo = null;
    echo "\nVerification completed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}