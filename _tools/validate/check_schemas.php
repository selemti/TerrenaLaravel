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
    
    // Show all schemas in the database
    $stmt = $pdo->query("SELECT schema_name FROM information_schema.schemata ORDER BY schema_name");
    $schemas = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "All schemas in the database:\n";
    foreach ($schemas as $schema) {
        echo "- $schema\n";
    }
    
    // Show some information about key tables in selemti schema
    echo "\nKey tables in selemti schema:\n";
    $stmt = $pdo->query("
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'selemti'
        AND table_name IN ('users', 'inventory_items', 'cash_funds', 'recipes', 'purchases', 'transfers')
        ORDER BY table_name
    ");
    $keyTables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($keyTables as $table) {
        echo "- $table\n";
    }
    
    $pdo = null;
    echo "\nConnection closed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}