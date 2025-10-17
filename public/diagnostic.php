<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);

echo "<h1>Diagnóstico Laravel</h1>";
echo "PHP Version: " . phpversion() . "<br><br>";

echo "<h2>1. Cargando autoload...</h2>";
try {
    require __DIR__.'/../vendor/autoload.php';
    echo "✅ Autoload OK<br><br>";
} catch (Throwable $e) {
    echo "❌ ERROR en autoload: " . $e->getMessage() . "<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
    die();
}

echo "<h2>2. Cargando bootstrap app...</h2>";
try {
    $app = require_once __DIR__.'/../bootstrap/app.php';
    echo "✅ Bootstrap OK<br><br>";
} catch (Throwable $e) {
    echo "❌ ERROR en bootstrap: " . $e->getMessage() . "<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
    die();
}

echo "<h2>3. Creando Kernel...</h2>";
try {
    $kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
    echo "✅ Kernel OK<br><br>";
} catch (Throwable $e) {
    echo "❌ ERROR en Kernel: " . $e->getMessage() . "<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
    die();
}

echo "<h2>4. Capturando Request...</h2>";
try {
    $request = Illuminate\Http\Request::capture();
    echo "✅ Request OK<br><br>";
} catch (Throwable $e) {
    echo "❌ ERROR en Request: " . $e->getMessage() . "<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
    die();
}

echo "<h2>5. Manejando Request...</h2>";
try {
    $response = $kernel->handle($request);
    echo "✅ Handle OK<br><br>";
    echo "<h3>Response Status: " . $response->getStatusCode() . "</h3>";
} catch (Throwable $e) {
    echo "❌ ERROR en Handle: " . $e->getMessage() . "<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
    die();
}

echo "<h2>✅ TODO FUNCIONA CORRECTAMENTE</h2>";
?>
