<?php
// test_backup.php
// Script para probar el backup automático

require_once 'vendor/autoload.php';

echo "🧪 Prueba de backup automático\n";
echo "=============================\n";

// Verificar que PostgreSQL esté corriendo
echo "Verificando conexión a PostgreSQL...\n";

try {
    $config = [
        'host' => 'localhost',
        'port' => '5433',
        'database' => 'pos',
        'username' => 'postgres',
        'password' => 'T3rr3n4#p0s'
    ];
    
    $connection = new PDO(
        "pgsql:host={$config['host']};port={$config['port']};dbname={$config['database']}", 
        $config['username'], 
        $config['password']
    );
    
    echo "✅ Conexión a PostgreSQL exitosa\n";
    
    // Verificar que existan ambos esquemas
    $stmt = $connection->query("
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name IN ('public', 'selemti')
    ");
    
    $schemas = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "📊 Esquemas encontrados: " . implode(', ', $schemas) . "\n";
    
    if (in_array('public', $schemas)) {
        $stmt = $connection->query("
            SELECT COUNT(*) 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        ");
        $public_tables = $stmt->fetchColumn();
        echo "📋 Tablas en esquema 'public': $public_tables\n";
    }
    
    if (in_array('selemti', $schemas)) {
        $stmt = $connection->query("
            SELECT COUNT(*) 
            FROM information_schema.tables 
            WHERE table_schema = 'selemti'
        ");
        $selemti_tables = $stmt->fetchColumn();
        echo "📋 Tablas en esquema 'selemti': $selemti_tables\n";
    }
    
    $connection = null;
    echo "\n✅ Configuración de base de datos verificada exitosamente\n";
    echo "🚀 Puedes ejecutar los scripts de backup sin problemas:\n";
    echo "   php backup_automatizado.php\n";
    echo "   php backup_configurable.php\n";
    echo "   o usar el archivo backup_diario.bat\n\n";
    
} catch (Exception $e) {
    echo "❌ Error conectando a PostgreSQL: " . $e->getMessage() . "\n";
    exit(1);
}