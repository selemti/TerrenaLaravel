<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "PHP Version: " . phpversion() . "<br>";
echo "Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "<br>";
echo "Script Filename: " . $_SERVER['SCRIPT_FILENAME'] . "<br>";
echo "<br>Intentando cargar Laravel...<br><br>";

try {
    require __DIR__.'/../vendor/autoload.php';
    echo "✓ Autoload cargado correctamente<br>";
    
    $app = require_once __DIR__.'/../bootstrap/app.php';
    echo "✓ App bootstrap cargado correctamente<br>";
    
} catch (Exception $e) {
    echo "<strong style='color:red'>ERROR:</strong> " . $e->getMessage() . "<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}
?>
