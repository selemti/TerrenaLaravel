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
    
    // Check if selemti schema exists
    $stmt = $pdo->query("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'selemti'");
    $schemas = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    if (in_array('selemti', $schemas)) {
        echo "Schema 'selemti' exists\n";
    } else {
        echo "Schema 'selemti' does not exist\n";
    }
    
    // Check if public schema exists
    if (in_array('public', $schemas)) {
        echo "Schema 'public' exists\n";
    } else {
        echo "Schema 'public' does not exist\n";
    }
    
    // Show some basic information about the database
    $stmt = $pdo->query("SELECT version()");
    $version = $stmt->fetch(PDO::FETCH_COLUMN);
    echo "PostgreSQL version: $version\n";
    
    // Count tables in selemti schema
    $stmt = $pdo->query("
        SELECT COUNT(*) 
        FROM information_schema.tables 
        WHERE table_schema = 'selemti'
    ");
    $tableCount = $stmt->fetch(PDO::FETCH_COLUMN);
    echo "Number of tables in selemti schema: $tableCount\n";
    
    $pdo = null;
    echo "Connection closed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}