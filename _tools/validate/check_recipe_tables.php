<?php
echo "Starting database verification...\n";

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
    
    // Test specific tables that should exist based on our earlier scan
    $stmt = $pdo->prepare('SELECT table_name FROM information_schema.tables WHERE table_schema = \'selemti\' AND table_name IN (\'receta\', \'receta_version\', \'receta_insumo\', \'receta_cab\', \'receta_det\', \'receta_shadow\', \'recipe_version_items\') ORDER BY table_name;');
    $stmt->execute();
    $foundTables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nRecipe-related tables found in selemti schema:\n";
    foreach ($foundTables as $table) {
        echo "- $table\n";
    }
    
    // Check all recipe-related tables in the schema
    $stmt = $pdo->prepare('SELECT table_name FROM information_schema.tables WHERE table_schema = \'selemti\' AND (table_name LIKE \'%receta%\' OR table_name LIKE \'%recipe%\') ORDER BY table_name;');
    $stmt->execute();
    $allRecetaTables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nAll recipe-related tables in selemti schema:\n";
    foreach ($allRecetaTables as $table) {
        echo "- $table\n";
    }
    
    $pdo = null;
    echo "\nVerification completed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}