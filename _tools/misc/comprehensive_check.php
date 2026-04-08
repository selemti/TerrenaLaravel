<?php
echo "Starting comprehensive database verification...\n";

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
$host = '172.24.240.1'; // Using WSL IP 
$port = $env['DB_PORT'] ?? '5433';
$dbname = $env['DB_DATABASE'] ?? 'pos';
$username = $env['DB_USERNAME'] ?? 'postgres';
$password = trim($env['DB_PASSWORD'], '"'); // Remove quotes from password

echo "Connecting to database: $host:$port/$dbname\n";

try {
    // Create PDO connection
    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname;user=$username;password=$password;";
    $pdo = new PDO($dsn);
    
    // Test the connection
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "Successfully connected to the database!\n";
    
    // Check inventory-related tables
    $inventoryTables = ['recepcion_cab', 'recepcion_det', 'transfer_cab', 'transfer_det', 'mov_inv', 'stock_policy', 'inventory_batch'];
    echo "\nChecking inventory-related tables:\n";
    foreach ($inventoryTables as $table) {
        $stmt = $pdo->prepare('SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = \'selemti\' AND table_name = ?);');
        $stmt->execute([$table]);
        $exists = $stmt->fetchColumn();
        echo "Table selemti.$table: " . ($exists ? 'EXISTS' : 'DOES NOT EXIST') . "\n";
    }
    
    // Check security-related tables
    $securityTables = ['users', 'roles', 'permissions', 'model_has_permissions', 'model_has_roles', 'role_has_permissions'];
    echo "\nChecking security-related tables in selemti:\n";
    foreach ($securityTables as $table) {
        $stmt = $pdo->prepare('SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = \'selemti\' AND table_name = ?);');
        $stmt->execute([$table]);
        $exists = $stmt->fetchColumn();
        echo "Table selemti.$table: " . ($exists ? 'EXISTS' : 'DOES NOT EXIST') . "\n";
    }
    
    echo "\nChecking security-related tables in public:\n";
    foreach ($securityTables as $table) {
        $stmt = $pdo->prepare('SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = \'public\' AND table_name = ?);');
        $stmt->execute([$table]);
        $exists = $stmt->fetchColumn();
        echo "Table public.$table: " . ($exists ? 'EXISTS' : 'DOES NOT EXIST') . "\n";
    }
    
    // Check catalog-related tables
    $catalogTables = ['cat_almacenes', 'cat_sucursales', 'cat_proveedores', 'cat_unidades'];
    echo "\nChecking catalog-related tables:\n";
    foreach ($catalogTables as $table) {
        $stmt = $pdo->prepare('SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = \'selemti\' AND table_name = ?);');
        $stmt->execute([$table]);
        $exists = $stmt->fetchColumn();
        echo "Table selemti.$table: " . ($exists ? 'EXISTS' : 'DOES NOT EXIST') . "\n";
    }
    
    // Find all tables with common naming variations that may indicate discrepancies with documentation
    $stmt = $pdo->prepare('SELECT table_name FROM information_schema.tables WHERE table_schema = \'selemti\' AND (table_name LIKE \'%receta%\' OR table_name LIKE \'%recipe%\' OR table_name LIKE \'%recepcion%\' OR table_name LIKE \'%transfer%\' OR table_name LIKE \'%mov_inv%\' OR table_name LIKE \'%pos_map%\') ORDER BY table_name;');
    $stmt->execute();
    $relatedTables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nAll related tables in selemti schema:\n";
    foreach ($relatedTables as $table) {
        echo "- $table\n";
    }
    
    $pdo = null;
    echo "\nComprehensive verification completed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}