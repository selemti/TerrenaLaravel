<?php
require __DIR__ . '/vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

$host = $_ENV['DB_HOST'] ?? 'localhost';
$port = $_ENV['DB_PORT'] ?? '5432';
$dbname = $_ENV['DB_DATABASE'] ?? 'terrena';
$user = $_ENV['DB_USERNAME'] ?? 'postgres';
$password = $_ENV['DB_PASSWORD'] ?? '';

$pdo = new PDO("pgsql:host=$host;port=$port;dbname=$dbname", $user, $password);

echo "=== Estructura de la tabla TICKET ===\n\n";
$stmt = $pdo->query("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ticket' ORDER BY ordinal_position");
while ($row = $stmt->fetch(PDO::FETCH_OBJ)) {
    echo sprintf("%-30s %-20s %s\n", $row->column_name, $row->data_type, $row->is_nullable);
}
