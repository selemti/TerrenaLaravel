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

    // Get all schemas
    $stmt = $pdo->prepare("SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'pg_temp_1', 'pg_toast_temp_1')");
    $stmt->execute();
    $schemas = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nSchemas in the database:\n";
    foreach ($schemas as $schema) {
        echo "- $schema\n";
    }
    
    // Get all tables in selemti schema
    $stmt = $pdo->prepare("SELECT table_name FROM information_schema.tables WHERE table_schema = 'selemti' ORDER BY table_name");
    $stmt->execute();
    $selemti_tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nTables in selemti schema:\n";
    foreach ($selemti_tables as $table) {
        echo "- $table\n";
    }
    
    // Get all tables in public schema
    $stmt = $pdo->prepare("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name");
    $stmt->execute();
    $public_tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\nTables in public schema:\n";
    foreach ($public_tables as $table) {
        echo "- $table\n";
    }
    
    // Validate some specific tables mentioned in documentation
    $important_tables = [
        'selemti.mov_inv',
        'selemti.receta',
        'selemti.receta_version', 
        'selemti.receta_insumo',
        'selemti.pos_map',
        'selemti.recepcion_cab',
        'selemti.recepcion_det',
        'selemti.transfer_cab',
        'selemti.transfer_det',
        'selemti.cash_funds',
        'selemti.cash_fund_movements',
        'selemti.cat_almacenes',
        'selemti.cat_sucursales',
        'selemti.cat_proveedores',
        'public.ticket',
        'public.ticket_item'
    ];
    
    echo "\nValidation of important tables against documentation:\n";
    foreach ($important_tables as $table_path) {
        list($schema, $table_name) = explode('.', $table_path);
        
        $stmt = $pdo->prepare("
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_schema = ? 
            AND table_name = ?
            ORDER BY ordinal_position
        ");
        $stmt->execute([$schema, $table_name]);
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        if (count($columns) > 0) {
            echo "\n✓ $schema.$table_name EXISTS with " . count($columns) . " columns\n";
            
            // Show first few columns as sample
            $sample_cols = array_slice($columns, 0, 5);
            foreach ($sample_cols as $col) {
                echo "  - {$col['column_name']} ({$col['data_type']}, nullable: {$col['is_nullable']})\n";
            }
            if (count($columns) > 5) {
                echo "  ... and " . (count($columns) - 5) . " more columns\n";
            }
        } else {
            echo "\n✗ $schema.$table_name does NOT EXIST\n";
        }
    }
    
    $pdo = null;
    echo "\nValidation completed successfully.\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}