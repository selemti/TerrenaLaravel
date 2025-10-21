<?php

/**
 * Sincroniza los productos del POS (public.menu_item) con el catálogo de recetas (selemti.receta_*).
 *
 * - Crea receta_cab si no existe.
 * - Inserta versión inicial (no publicada) si faltante.
 * - No registra ingredientes; deja las recetas listas para captura manual.
 *
 * Uso: php scripts/sync_menu_recipes.php
 */

$dsn = 'pgsql:host=172.24.240.1;port=5433;dbname=pos';
$user = 'postgres';
$password = 'T3rr3n4#p0s';

$pdo = new PDO($dsn, $user, $password, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

// Trae todos los ítems del POS (excluye los ocultos) junto con el grupo/categoría
$items = $pdo->query(<<<'SQL'
    SELECT mi.id,
           mi.name,
           mi.price,
           mi.group_id,
           COALESCE(mg.name, 'SIN CATEGORÍA') AS group_name
    FROM public.menu_item AS mi
    LEFT JOIN public.menu_group AS mg ON mg.id = mi.group_id
    WHERE mi.visible = TRUE
    ORDER BY mi.id
SQL)->fetchAll();

$created = 0;
$versions = 0;

$insertRecipeStmt = $pdo->prepare(<<<'SQL'
    INSERT INTO selemti.receta_cab (
        id, nombre_plato, codigo_plato_pos, categoria_plato,
        porciones_standard, costo_standard_porcion,
        precio_venta_sugerido, activo
    )
    VALUES (:id, :nombre_plato, :codigo_plato_pos, :categoria_plato,
            :porciones_standard, :costo_standard_porcion,
            :precio_venta_sugerido, TRUE)
    ON CONFLICT (id) DO NOTHING
SQL);

$versionExistsStmt = $pdo->prepare('SELECT 1 FROM selemti.receta_version WHERE receta_id = :receta_id AND version = 1 LIMIT 1');
$insertVersionStmt = $pdo->prepare(<<<'SQL'
    INSERT INTO selemti.receta_version (
        receta_id, version, descripcion_cambios,
        fecha_efectiva, version_publicada, created_at
    )
    VALUES (:receta_id, 1, :descripcion_cambios,
            CURRENT_DATE, FALSE, NOW())
SQL);

foreach ($items as $item) {
    $recetaId = sprintf('REC-%05d', (int)$item['id']);

    $insertRecipeStmt->execute([
        'id' => $recetaId,
        'nombre_plato' => $item['name'],
        'codigo_plato_pos' => (string)$item['id'],
        'categoria_plato' => mb_substr($item['group_name'], 0, 50),
        'porciones_standard' => 1,
        'costo_standard_porcion' => 0,
        'precio_venta_sugerido' => $item['price'] ?? 0,
    ]);

    if ($insertRecipeStmt->rowCount() > 0) {
        $created++;
    }

    $versionExistsStmt->execute(['receta_id' => $recetaId]);
    if (!$versionExistsStmt->fetchColumn()) {
        $insertVersionStmt->execute([
            'receta_id' => $recetaId,
            'descripcion_cambios' => 'Versión generada automáticamente desde Floreant POS',
        ]);
        $versions++;
    }
}

printf("Recetas creadas: %d\n", $created);
printf("Versiones iniciales: %d\n", $versions);
