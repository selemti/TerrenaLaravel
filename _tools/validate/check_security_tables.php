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
    
    // Check if spatie tables exist in the public schema
    $securityTables = ['users', 'model_has_permissions', 'model_has_roles', 'permissions', 'roles'];
    foreach ($securityTables as $table) {
        $stmt = $pdo->prepare("
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = ?
        ");
        $stmt->execute([$table]);
        $result = $stmt->fetch();
        
        if ($result) {
            echo "\nTable: $table EXISTS in public schema\n";
            
            // Get columns for this table
            $stmt = $pdo->prepare("
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = ?
            ");
            $stmt->execute([$table]);
            $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            echo "Columns: " . implode(', ', $columns) . "\n";
        } else {
            echo "\nTable: $table DOES NOT EXIST in public schema\n";
        }
    }
    
    // Check if these tables exist in selemti schema
    foreach ($securityTables as $table) {
        $stmt = $pdo->prepare("
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'selemti' 
            AND table_name = ?
        ");
        $stmt->execute([$table]);
        $result = $stmt->fetch();
        
        if ($result) {
            echo "\nTable: $table EXISTS in selemti schema\n";
            
            // Get columns for this table
            $stmt = $pdo->prepare("
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_schema = 'selemti' 
                AND table_name = ?
            ");
            $stmt->execute([$table]);
            $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            echo "Columns: " . implode(', ', $columns) . "\n";
        } else {
            echo "\nTable: $table DOES NOT EXIST in selemti schema\n";
        }
    }
    
    $pdo = null;
    echo "\nVerification completed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}