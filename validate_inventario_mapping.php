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
    
    // Check if the tables and columns for Inventario module MISMATCH cases exist
    $mismatchCases = [
        ['table' => 'mov_inv', 'column' => 'ts'],
        ['table' => 'mov_inv', 'column' => 'costo_unit'],
        ['table' => 'mov_inv', 'column' => 'tipo'],
        ['table' => 'mov_inv', 'column' => 'ref_tipo'],
        ['table' => 'mov_inv', 'column' => 'ref_id'],
        ['table' => 'mov_inv', 'column' => 'sucursal_id'],
        ['table' => 'stock_policy', 'column' => 'sucursal_id'],
        ['table' => 'stock_policy', 'column' => 'almacen_id']
    ];
    
    echo "\nValidating MISMATCH cases:\n";
    foreach ($mismatchCases as $case) {
        $table = $case['table'];
        $column = $case['column'];
        
        $stmt = $pdo->prepare("
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
            AND table_name = :table 
            AND column_name = :column
        ");
        $stmt->execute(['table' => $table, 'column' => $column]);
        $result = $stmt->fetch();
        
        if ($result) {
            echo "✓ Table: $table, Column: $column - EXISTS\n";
        } else {
            echo "✗ Table: $table, Column: $column - DOES NOT EXIST\n";
        }
    }
    
    // Check if the tables for Inventario module FANTASMA cases exist
    $fantasmaCases = [
        ['table' => 'stock', 'column' => 'item_id'],
        ['table' => 'stock', 'column' => 'almacen_id'],
        ['table' => 'stock', 'column' => 'cantidad_actual'],
        ['table' => 'recepcion', 'column' => 'id'],
        ['table' => 'recepcion', 'column' => 'proveedor_id'],
        ['table' => 'recepcion', 'column' => 'almacen_id']
    ];
    
    echo "\nValidating FANTASMA cases:\n";
    foreach ($fantasmaCases as $case) {
        $table = $case['table'];
        $column = $case['column'];
        
        $stmt = $pdo->prepare("
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
            AND table_name = :table 
            AND column_name = :column
        ");
        $stmt->execute(['table' => $table, 'column' => $column]);
        $result = $stmt->fetch();
        
        if ($result) {
            echo "✓ Table: $table, Column: $column - EXISTS (CONTRADICTS MAPA!)\n";
        } else {
            echo "✗ Table: $table, Column: $column - DOES NOT EXIST (CONFIRMS MAPA)\n";
        }
        
        // Also check if table itself exists
        $stmt2 = $pdo->prepare("
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'selemti' 
            AND table_name = :table
        ");
        $stmt2->execute(['table' => $table]);
        $tableResult = $stmt2->fetch();
        
        if ($tableResult) {
            echo "  → Table $table EXISTS\n";
        } else {
            echo "  → Table $table DOES NOT EXIST\n";
        }
    }
    
    $pdo = null;
    echo "\nValidation completed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}