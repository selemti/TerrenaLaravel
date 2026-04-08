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
    
    // Check access to selemti schema
    $stmt = $pdo->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'selemti'");
    $selemtiTableCount = $stmt->fetchColumn();
    echo "Number of tables in selemti schema: $selemtiTableCount\n";
    
    // Check access to public schema
    $stmt = $pdo->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'");
    $publicTableCount = $stmt->fetchColumn();
    echo "Number of tables in public schema: $publicTableCount\n";
    
    // Show current search_path
    $stmt = $pdo->query("SHOW search_path;");
    $searchPath = $stmt->fetchColumn();
    echo "Current search_path: $searchPath\n";
    
    // Show some users from the selemti schema (if they exist)
    try {
        $stmt = $pdo->query("SELECT id, name, email FROM selemti.users LIMIT 5;");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo "\nSample users from selemti.users:\n";
        foreach ($users as $user) {
            echo "- ID: {$user['id']}, Name: {$user['name']}, Email: {$user['email']}\n";
        }
    } catch (PDOException $e) {
        echo "\nCould not access selemti.users: " . $e->getMessage() . "\n";
    }
    
    $pdo = null;
    echo "\nConnection closed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}