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
    
    // Check columns in recipe_version_items table
    $stmt = $pdo->prepare("
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'selemti' 
        AND table_name = 'recipe_version_items'
        ORDER BY ordinal_position
    ");
    $stmt->execute();
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if ($results) {
        echo "\nColumns in selemti.recipe_version_items table:\n";
        foreach ($results as $row) {
            echo "- {$row['column_name']} (type: {$row['data_type']}, nullable: {$row['is_nullable']})\n";
        }
    } else {
        echo "\nTable selemti.recipe_version_items does not exist in database.\n";
    }
    
    $pdo = null;
    echo "\nValidation completed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}