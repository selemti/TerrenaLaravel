<?php

// Datos para MasterDataSeeder — restaurante mexicano (corrida E2E)
// Actualizado: 2026-05-16 — Modelo B (sub-recetas como items producibles)
//
// REGLA IDs numéricos (compatibilidad con production_order_inputs.item_id bigint):
//   Insumos de compra:  IDs 1001–1025  (es_producible = false)
//   Items producibles:  IDs 2001–2015  (es_producible = true)

return [

    // =========================================================================
    // ITEMS
    // =========================================================================
    'items' => [

        // --- INSUMOS DE COMPRA (IDs 1001–1025) ---
        // tipo_venta_pos = null → insumos puros, no aparecen en POS

        // CARNES
        ['codigo' => 'INS-001', 'nombre' => 'Pechuga de pollo',        'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 95.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-002', 'nombre' => 'Muslo de pollo',          'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 72.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-003', 'nombre' => 'Carne molida de res',     'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 145.00, 'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-004', 'nombre' => 'Chorizo crudo',           'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 98.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-005', 'nombre' => 'Cecina de res',           'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 220.00, 'es_producible' => false, 'tipo_venta_pos' => null],
        // LACTEOS
        ['codigo' => 'INS-006', 'nombre' => 'Queso de hebra (Oaxaca)', 'categoria' => 'LACTEOS',     'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 180.00, 'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-007', 'nombre' => 'Crema ácida',             'categoria' => 'LACTEOS',     'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 65.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-008', 'nombre' => 'Huevo',                   'categoria' => 'LACTEOS',     'uom_base' => 'PZ', 'uom_compra' => 'CAJ', 'factor_compra' => 30.0, 'costo_promedio' => 4.00,   'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-009', 'nombre' => 'Leche entera',            'categoria' => 'LACTEOS',     'uom_base' => 'L',  'uom_compra' => 'L',   'factor_compra' => 1.0,  'costo_promedio' => 22.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        // VEGETALES
        ['codigo' => 'INS-010', 'nombre' => 'Tomate bola',             'categoria' => 'VEGETALES',   'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 28.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-011', 'nombre' => 'Tomate verde (tomatillo)', 'categoria' => 'VEGETALES',   'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 22.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-012', 'nombre' => 'Cebolla blanca',          'categoria' => 'VEGETALES',   'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 18.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-013', 'nombre' => 'Chile serrano',           'categoria' => 'VEGETALES',   'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 45.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-014', 'nombre' => 'Chile ancho (seco)',      'categoria' => 'VEGETALES',   'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 120.00, 'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-015', 'nombre' => 'Chile pasilla (seco)',    'categoria' => 'VEGETALES',   'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 130.00, 'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-016', 'nombre' => 'Papa blanca',             'categoria' => 'VEGETALES',   'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 16.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-017', 'nombre' => 'Zanahoria',               'categoria' => 'VEGETALES',   'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 14.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        // ABARROTES
        ['codigo' => 'INS-018', 'nombre' => 'Arroz largo grano',       'categoria' => 'ABARROTES',   'uom_base' => 'KG', 'uom_compra' => 'CAJ', 'factor_compra' => 25.0, 'costo_promedio' => 24.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-019', 'nombre' => 'Frijol negro',            'categoria' => 'ABARROTES',   'uom_base' => 'KG', 'uom_compra' => 'CAJ', 'factor_compra' => 20.0, 'costo_promedio' => 32.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-020', 'nombre' => 'Aceite vegetal',          'categoria' => 'ABARROTES',   'uom_base' => 'L',  'uom_compra' => 'CAJ', 'factor_compra' => 20.0, 'costo_promedio' => 38.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-021', 'nombre' => 'Tortilla de maíz',        'categoria' => 'ABARROTES',   'uom_base' => 'KG', 'uom_compra' => 'PAQ', 'factor_compra' => 1.0,  'costo_promedio' => 20.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-022', 'nombre' => 'Masa para tortilla/picada', 'categoria' => 'ABARROTES',  'uom_base' => 'KG', 'uom_compra' => 'PAQ', 'factor_compra' => 1.0,  'costo_promedio' => 14.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-023', 'nombre' => 'Chocolate tablilla',      'categoria' => 'ABARROTES',   'uom_base' => 'KG', 'uom_compra' => 'PAQ', 'factor_compra' => 0.9,  'costo_promedio' => 130.00, 'es_producible' => false, 'tipo_venta_pos' => null],
        // CONDIMENTOS
        ['codigo' => 'INS-024', 'nombre' => 'Ajo en cabeza',           'categoria' => 'CONDIMENTOS', 'uom_base' => 'KG', 'uom_compra' => 'KG',  'factor_compra' => 1.0,  'costo_promedio' => 60.00,  'es_producible' => false, 'tipo_venta_pos' => null],
        ['codigo' => 'INS-025', 'nombre' => 'Sal de mesa',             'categoria' => 'CONDIMENTOS', 'uom_base' => 'KG', 'uom_compra' => 'PAQ', 'factor_compra' => 1.0,  'costo_promedio' => 8.00,   'es_producible' => false, 'tipo_venta_pos' => null],

        // --- ITEMS PRODUCIBLES (IDs 2001–2015, es_producible = true) ---
        // tipo_venta_pos = 'PRODUCCION' → se fabrican internamente, NO se venden directo en POS.
        // Son ingredientes que los platillos PLATILLO consumen al venderse.

        // Salsas base (batch diario/semanal)
        ['codigo' => 'PROD-001', 'nombre' => 'Salsa Roja Base',        'categoria' => 'CONDIMENTOS', 'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 35.00,  'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        ['codigo' => 'PROD-002', 'nombre' => 'Salsa Verde Base',       'categoria' => 'CONDIMENTOS', 'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 28.00,  'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        ['codigo' => 'PROD-003', 'nombre' => 'Salsa Chile Seco',       'categoria' => 'CONDIMENTOS', 'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 55.00,  'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        ['codigo' => 'PROD-004', 'nombre' => 'Frijoles Refritos',      'categoria' => 'ABARROTES',   'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 42.00,  'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        ['codigo' => 'PROD-005', 'nombre' => 'Mole Terrena',           'categoria' => 'CONDIMENTOS', 'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 95.00,  'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        // Proteínas preparadas (batch diario)
        ['codigo' => 'PROD-006', 'nombre' => 'Pollo Deshebrado',       'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 130.00, 'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        ['codigo' => 'PROD-007', 'nombre' => 'Picadillo de Res',       'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 165.00, 'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        ['codigo' => 'PROD-008', 'nombre' => 'Chorizo Frito',          'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 115.00, 'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        ['codigo' => 'PROD-009', 'nombre' => 'Caldo de Pollo',         'categoria' => 'CARNES',      'uom_base' => 'L',  'uom_compra' => 'L',  'factor_compra' => 1.0, 'costo_promedio' => 22.00,  'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
        ['codigo' => 'PROD-010', 'nombre' => 'Pechuga Asada en Tiras', 'categoria' => 'CARNES',      'uom_base' => 'KG', 'uom_compra' => 'KG', 'factor_compra' => 1.0, 'costo_promedio' => 120.00, 'es_producible' => true, 'tipo_venta_pos' => 'PRODUCCION'],
    ],

    // =========================================================================
    // PROVEEDORES — 3 registros
    // =========================================================================
    'proveedores' => [
        [
            'nombre' => 'Distribuidora Alimentos del Centro S.A. de C.V.',
            'rfc' => 'DAC910305HJ8',
        ],
        [
            'nombre' => 'Carnes Selectas Monterrey S. de R.L.',
            'rfc' => 'CSM870622QA3',
        ],
        [
            'nombre' => 'Verduras y Hortalizas Frescas del Bajío',
            'rfc' => 'VHF011118RN7',
        ],
    ],

    // =========================================================================
    // RECETAS
    // tipo: PLATILLO | PROD_SALSA | PROD_PROTEINA
    //   PROD_*  = receta de producción para un item producible (Modelo B)
    //   PLATILLO = receta que se vende en POS
    //
    // item_producido: codigo del item PROD-* que genera esta receta
    //   (solo para tipo PROD_*)
    //
    // ingredientes: item_codigo references items.codigo
    //   Puede ser INS-* (insumo crudo) o PROD-* (item producible ya fabricado)
    // =========================================================================
    'recetas' => [

        // =====================================================================
        // RECETAS DE PRODUCCIÓN (generan items PROD-*)
        // =====================================================================

        [
            'codigo' => 'REC-PROD-001',
            'nombre' => 'Producción: Salsa Roja Base',
            'tipo' => 'PROD_SALSA',
            'item_producido_codigo' => 'PROD-001',
            'item_producido' => 'PROD-001',   // → Salsa Roja Base
            'porciones' => 5.0,          // produce 5 KG por batch
            'uom_salida' => 'KG',
            'tiempo_min' => 30,
            'ingredientes' => [
                ['item_codigo' => 'INS-010', 'qty' => 3.000, 'uom' => 'KG'], // Tomate bola
                ['item_codigo' => 'INS-014', 'qty' => 0.200, 'uom' => 'KG'], // Chile ancho
                ['item_codigo' => 'INS-012', 'qty' => 0.300, 'uom' => 'KG'], // Cebolla
                ['item_codigo' => 'INS-024', 'qty' => 0.050, 'uom' => 'KG'], // Ajo
                ['item_codigo' => 'INS-025', 'qty' => 0.020, 'uom' => 'KG'], // Sal
                ['item_codigo' => 'INS-020', 'qty' => 0.050, 'uom' => 'L'],  // Aceite
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PROD-002',
            'nombre' => 'Producción: Salsa Verde Base',
            'tipo' => 'PROD_SALSA',
            'item_producido_codigo' => 'PROD-002',
            'item_producido' => 'PROD-002',   // → Salsa Verde Base
            'porciones' => 5.0,          // produce 5 KG por batch
            'uom_salida' => 'KG',
            'tiempo_min' => 25,
            'ingredientes' => [
                ['item_codigo' => 'INS-011', 'qty' => 3.000, 'uom' => 'KG'], // Tomate verde
                ['item_codigo' => 'INS-013', 'qty' => 0.150, 'uom' => 'KG'], // Chile serrano
                ['item_codigo' => 'INS-012', 'qty' => 0.200, 'uom' => 'KG'], // Cebolla
                ['item_codigo' => 'INS-024', 'qty' => 0.030, 'uom' => 'KG'], // Ajo
                ['item_codigo' => 'INS-025', 'qty' => 0.015, 'uom' => 'KG'], // Sal
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PROD-003',
            'nombre' => 'Producción: Salsa Chile Seco',
            'tipo' => 'PROD_SALSA',
            'item_producido_codigo' => 'PROD-003',
            'item_producido' => 'PROD-003',   // → Salsa Chile Seco
            'porciones' => 3.0,          // produce 3 KG por batch
            'uom_salida' => 'KG',
            'tiempo_min' => 40,
            'ingredientes' => [
                ['item_codigo' => 'INS-014', 'qty' => 0.500, 'uom' => 'KG'], // Chile ancho
                ['item_codigo' => 'INS-015', 'qty' => 0.300, 'uom' => 'KG'], // Chile pasilla
                ['item_codigo' => 'INS-012', 'qty' => 0.200, 'uom' => 'KG'], // Cebolla
                ['item_codigo' => 'INS-024', 'qty' => 0.040, 'uom' => 'KG'], // Ajo
                ['item_codigo' => 'INS-025', 'qty' => 0.015, 'uom' => 'KG'], // Sal
                ['item_codigo' => 'INS-020', 'qty' => 0.040, 'uom' => 'L'],  // Aceite
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PROD-004',
            'nombre' => 'Producción: Frijoles Refritos',
            'tipo' => 'PROD_SALSA',
            'item_producido_codigo' => 'PROD-004',
            'item_producido' => 'PROD-004',   // → Frijoles Refritos
            'porciones' => 4.0,          // produce 4 KG por batch
            'uom_salida' => 'KG',
            'tiempo_min' => 90,
            'ingredientes' => [
                ['item_codigo' => 'INS-019', 'qty' => 2.000, 'uom' => 'KG'], // Frijol negro
                ['item_codigo' => 'INS-012', 'qty' => 0.150, 'uom' => 'KG'], // Cebolla
                ['item_codigo' => 'INS-024', 'qty' => 0.030, 'uom' => 'KG'], // Ajo
                ['item_codigo' => 'INS-020', 'qty' => 0.080, 'uom' => 'L'],  // Aceite
                ['item_codigo' => 'INS-025', 'qty' => 0.020, 'uom' => 'KG'], // Sal
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PROD-005',
            'nombre' => 'Producción: Mole Terrena',
            'tipo' => 'PROD_SALSA',
            'item_producido_codigo' => 'PROD-005',
            'item_producido' => 'PROD-005',   // → Mole Terrena
            'porciones' => 3.0,          // produce 3 KG por batch
            'uom_salida' => 'KG',
            'tiempo_min' => 120,
            'ingredientes' => [
                ['item_codigo' => 'INS-014', 'qty' => 0.400, 'uom' => 'KG'], // Chile ancho
                ['item_codigo' => 'INS-015', 'qty' => 0.200, 'uom' => 'KG'], // Chile pasilla
                ['item_codigo' => 'INS-023', 'qty' => 0.150, 'uom' => 'KG'], // Chocolate tablilla
                ['item_codigo' => 'INS-012', 'qty' => 0.100, 'uom' => 'KG'], // Cebolla
                ['item_codigo' => 'INS-024', 'qty' => 0.030, 'uom' => 'KG'], // Ajo
                ['item_codigo' => 'INS-025', 'qty' => 0.015, 'uom' => 'KG'], // Sal
                ['item_codigo' => 'INS-020', 'qty' => 0.060, 'uom' => 'L'],  // Aceite
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PROD-006',
            'nombre' => 'Producción: Pollo Deshebrado',
            'tipo' => 'PROD_PROTEINA',
            'item_producido_codigo' => 'PROD-006',
            'item_producido' => 'PROD-006',   // → Pollo Deshebrado
            'porciones' => 3.0,          // produce 3 KG (merma ~25% vs crudo)
            'uom_salida' => 'KG',
            'tiempo_min' => 60,
            'ingredientes' => [
                ['item_codigo' => 'INS-001', 'qty' => 4.000, 'uom' => 'KG'], // Pechuga cruda
                ['item_codigo' => 'INS-012', 'qty' => 0.100, 'uom' => 'KG'], // Cebolla
                ['item_codigo' => 'INS-024', 'qty' => 0.020, 'uom' => 'KG'], // Ajo
                ['item_codigo' => 'INS-025', 'qty' => 0.010, 'uom' => 'KG'], // Sal
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PROD-007',
            'nombre' => 'Producción: Picadillo de Res',
            'tipo' => 'PROD_PROTEINA',
            'item_producido_codigo' => 'PROD-007',
            'item_producido' => 'PROD-007',   // → Picadillo de Res
            'porciones' => 4.0,          // produce 4 KG
            'uom_salida' => 'KG',
            'tiempo_min' => 45,
            'ingredientes' => [
                ['item_codigo' => 'INS-003', 'qty' => 3.000, 'uom' => 'KG'], // Carne molida res
                ['item_codigo' => 'INS-010', 'qty' => 0.400, 'uom' => 'KG'], // Tomate
                ['item_codigo' => 'INS-012', 'qty' => 0.150, 'uom' => 'KG'], // Cebolla
                ['item_codigo' => 'INS-016', 'qty' => 0.200, 'uom' => 'KG'], // Papa
                ['item_codigo' => 'INS-024', 'qty' => 0.020, 'uom' => 'KG'], // Ajo
                ['item_codigo' => 'INS-025', 'qty' => 0.010, 'uom' => 'KG'], // Sal
                ['item_codigo' => 'INS-020', 'qty' => 0.030, 'uom' => 'L'],  // Aceite
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PROD-008',
            'nombre' => 'Producción: Chorizo Frito',
            'tipo' => 'PROD_PROTEINA',
            'item_producido_codigo' => 'PROD-008',
            'item_producido' => 'PROD-008',   // → Chorizo Frito
            'porciones' => 2.0,          // produce 2 KG (merma ~20%)
            'uom_salida' => 'KG',
            'tiempo_min' => 20,
            'ingredientes' => [
                ['item_codigo' => 'INS-004', 'qty' => 2.500, 'uom' => 'KG'], // Chorizo crudo
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PROD-009',
            'nombre' => 'Producción: Caldo de Pollo',
            'tipo' => 'PROD_SALSA',
            'item_producido_codigo' => 'PROD-009',
            'item_producido' => 'PROD-009',   // → Caldo de Pollo
            'porciones' => 8.0,          // produce 8 L por batch
            'uom_salida' => 'L',
            'tiempo_min' => 90,
            'ingredientes' => [
                ['item_codigo' => 'INS-002', 'qty' => 2.000, 'uom' => 'KG'], // Muslo de pollo
                ['item_codigo' => 'INS-012', 'qty' => 0.200, 'uom' => 'KG'], // Cebolla
                ['item_codigo' => 'INS-024', 'qty' => 0.040, 'uom' => 'KG'], // Ajo
                ['item_codigo' => 'INS-017', 'qty' => 0.150, 'uom' => 'KG'], // Zanahoria
                ['item_codigo' => 'INS-025', 'qty' => 0.020, 'uom' => 'KG'], // Sal
            ],
            'sub_recetas' => [],
        ],

        // =====================================================================
        // RECETAS DE PLATILLOS (se venden en POS, consumen items PROD-* + INS-*)
        // =====================================================================

        [
            'codigo' => 'REC-PLA-001',
            'nombre' => 'Picada (base 3 piezas)',
            'tipo' => 'PLATILLO',
            'porciones' => 3,           // 1 orden POS = 3 piezas
            'uom_salida' => 'PZ',
            'tiempo_min' => 10,
            // Base: solo masa. La salsa se descuenta via pos_modifier_inv_mapping.
            'ingredientes' => [
                ['item_codigo' => 'INS-022', 'qty' => 0.240, 'uom' => 'KG'], // Masa (80g × 3 piezas)
                ['item_codigo' => 'INS-020', 'qty' => 0.015, 'uom' => 'L'],  // Aceite para comal
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PLA-002',
            'nombre' => 'Chilaquiles (base)',
            'tipo' => 'PLATILLO',
            'porciones' => 1,
            'uom_salida' => 'PZ',
            'tiempo_min' => 12,
            // Base: tortilla frita. La salsa y proteína vía modifiers.
            'ingredientes' => [
                ['item_codigo' => 'INS-021', 'qty' => 0.120, 'uom' => 'KG'], // Tortilla de maíz
                ['item_codigo' => 'INS-020', 'qty' => 0.040, 'uom' => 'L'],  // Aceite
                ['item_codigo' => 'INS-007', 'qty' => 0.030, 'uom' => 'KG'], // Crema
                ['item_codigo' => 'INS-006', 'qty' => 0.030, 'uom' => 'KG'], // Queso hebra
            ],
            'sub_recetas' => [],
        ],

        [
            'codigo' => 'REC-PLA-003',
            'nombre' => 'Enchiladas (base 3 piezas)',
            'tipo' => 'PLATILLO',
            'porciones' => 3,
            'uom_salida' => 'PZ',
            'tiempo_min' => 15,
            'ingredientes' => [
                ['item_codigo' => 'INS-021', 'qty' => 0.150, 'uom' => 'KG'], // Tortilla de maíz
                ['item_codigo' => 'INS-007', 'qty' => 0.040, 'uom' => 'KG'], // Crema
                ['item_codigo' => 'INS-006', 'qty' => 0.050, 'uom' => 'KG'], // Queso hebra
                ['item_codigo' => 'INS-012', 'qty' => 0.030, 'uom' => 'KG'], // Cebolla (guarnición)
                ['item_codigo' => 'INS-020', 'qty' => 0.030, 'uom' => 'L'],  // Aceite
            ],
            'sub_recetas' => [],
        ],
    ],

    // =========================================================================
    // MAPEO MODIFIERS POS → INVENTARIO
    // Estos datos se usan para sembrar selemti.pos_modifier_inv_mapping.
    //
    // menu_modifier_id: public.menu_modifier.id (READ ONLY ref)
    // item_codigo:      codigo en selemti.items (null = sin efecto en inventario)
    // tipo_efecto:      'SELECTOR' | 'ADICIONAL'
    //   SELECTOR  = elige qué item se descuenta en lugar del slot base
    //   ADICIONAL = suma encima de los ingredientes de la receta base
    // qty_por_unidad: por cada modifier.item_count=1
    // =========================================================================
    'pos_modifier_mapping' => [

        // --- SALSA PICADA (group_id=8) ---
        ['menu_modifier_id' => 14, 'modifier_name_trim' => 'Verde',    'group_id' => 8, 'group_name' => 'Salsa Picada',    'item_codigo' => 'PROD-002', 'qty' => 0.080, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 15, 'modifier_name_trim' => 'Roja',     'group_id' => 8, 'group_name' => 'Salsa Picada',    'item_codigo' => 'PROD-001', 'qty' => 0.080, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 16, 'modifier_name_trim' => 'Chileseco', 'group_id' => 8, 'group_name' => 'Salsa Picada',    'item_codigo' => 'PROD-003', 'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 17, 'modifier_name_trim' => 'Frijoles', 'group_id' => 8, 'group_name' => 'Salsa Picada',    'item_codigo' => 'PROD-004', 'qty' => 0.080, 'uom' => 'KG', 'tipo' => 'SELECTOR'],

        // --- PROTEÍNA PICADA (group_id=9) ---
        ['menu_modifier_id' => 18, 'modifier_name_trim' => 'Sencilla', 'group_id' => 9, 'group_name' => 'Proteína Picada', 'item_codigo' => null,       'qty' => 0.000, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 19, 'modifier_name_trim' => 'Huevo',    'group_id' => 9, 'group_name' => 'Proteína Picada', 'item_codigo' => 'INS-008',  'qty' => 1.000, 'uom' => 'PZ', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 20, 'modifier_name_trim' => 'Pollo',    'group_id' => 9, 'group_name' => 'Proteína Picada', 'item_codigo' => 'PROD-006', 'qty' => 0.080, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 21, 'modifier_name_trim' => 'Chorizo',  'group_id' => 9, 'group_name' => 'Proteína Picada', 'item_codigo' => 'PROD-008', 'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],

        // --- PROTEÍNA PICADA TERRENA (group_id=10) ---
        ['menu_modifier_id' => 22, 'modifier_name_trim' => 'Milanesa', 'group_id' => 10, 'group_name' => 'Proteína Picada Terrena', 'item_codigo' => 'PROD-010', 'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 23, 'modifier_name_trim' => 'Cecina',   'group_id' => 10, 'group_name' => 'Proteína Picada Terrena', 'item_codigo' => 'INS-005',  'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 24, 'modifier_name_trim' => 'Pechuga',  'group_id' => 10, 'group_name' => 'Proteína Picada Terrena', 'item_codigo' => 'PROD-010', 'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 25, 'modifier_name_trim' => 'Chorizo',  'group_id' => 10, 'group_name' => 'Proteína Picada Terrena', 'item_codigo' => 'PROD-008', 'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],

        // --- SALSA ENCHILADAS (group_id=11) ---
        ['menu_modifier_id' => 27, 'modifier_name_trim' => 'Roja',  'group_id' => 11, 'group_name' => 'Salsa Enchiladas', 'item_codigo' => 'PROD-001', 'qty' => 0.120, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 28, 'modifier_name_trim' => 'Verde', 'group_id' => 11, 'group_name' => 'Salsa Enchiladas', 'item_codigo' => 'PROD-002', 'qty' => 0.120, 'uom' => 'KG', 'tipo' => 'SELECTOR'],

        // --- PROTEÍNA ENCHILADAS RELLENAS (group_id=12) ---
        ['menu_modifier_id' => 29, 'modifier_name_trim' => 'Sencillas', 'group_id' => 12, 'group_name' => 'Proteína Enchiladas Rellenas', 'item_codigo' => null,       'qty' => 0.000, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 30, 'modifier_name_trim' => 'Pollo',     'group_id' => 12, 'group_name' => 'Proteína Enchiladas Rellenas', 'item_codigo' => 'PROD-006', 'qty' => 0.120, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 31, 'modifier_name_trim' => 'Huevo',     'group_id' => 12, 'group_name' => 'Proteína Enchiladas Rellenas', 'item_codigo' => 'INS-008',  'qty' => 2.000, 'uom' => 'PZ', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 32, 'modifier_name_trim' => 'Suizas',    'group_id' => 12, 'group_name' => 'Proteína Enchiladas Rellenas', 'item_codigo' => 'PROD-006', 'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],

        // --- PROTEÍNA ENCHILADAS TERRENA (group_id=13) ---
        ['menu_modifier_id' => 34, 'modifier_name_trim' => 'Milanesa', 'group_id' => 13, 'group_name' => 'Proteína Enchiladas Terrena', 'item_codigo' => 'PROD-010', 'qty' => 0.120, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 35, 'modifier_name_trim' => 'Pechuga',  'group_id' => 13, 'group_name' => 'Proteína Enchiladas Terrena', 'item_codigo' => 'PROD-010', 'qty' => 0.120, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 36, 'modifier_name_trim' => 'Cecina',   'group_id' => 13, 'group_name' => 'Proteína Enchiladas Terrena', 'item_codigo' => 'INS-005',  'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],

        // --- PROTEÍNA ENMOLADAS RELLENAS (group_id=14) ---
        ['menu_modifier_id' => 38, 'modifier_name_trim' => 'Pollo',    'group_id' => 14, 'group_name' => 'Proteína Enmoladas Rellenas', 'item_codigo' => 'PROD-006', 'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 39, 'modifier_name_trim' => 'Huevo',    'group_id' => 14, 'group_name' => 'Proteína Enmoladas Rellenas', 'item_codigo' => 'INS-008',  'qty' => 2.000, 'uom' => 'PZ', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 40, 'modifier_name_trim' => 'Jamón',    'group_id' => 14, 'group_name' => 'Proteína Enmoladas Rellenas', 'item_codigo' => null,       'qty' => 0.080, 'uom' => 'KG', 'tipo' => 'ADICIONAL'], // jamón = comprado, agregar item si se quiere rastrear
        ['menu_modifier_id' => 122, 'modifier_name_trim' => 'Sencilla', 'group_id' => 14, 'group_name' => 'Proteína Enmoladas Rellenas', 'item_codigo' => null,       'qty' => 0.000, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],

        // --- SALSA CHILAQUILES (group_id=20) ---
        ['menu_modifier_id' => 55, 'modifier_name_trim' => 'Roja',  'group_id' => 20, 'group_name' => 'Salsa Chilaquiles', 'item_codigo' => 'PROD-001', 'qty' => 0.150, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 56, 'modifier_name_trim' => 'Verde', 'group_id' => 20, 'group_name' => 'Salsa Chilaquiles', 'item_codigo' => 'PROD-002', 'qty' => 0.150, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 57, 'modifier_name_trim' => 'Mole',  'group_id' => 20, 'group_name' => 'Salsa Chilaquiles', 'item_codigo' => 'PROD-005', 'qty' => 0.120, 'uom' => 'KG', 'tipo' => 'SELECTOR'],

        // --- PROTEÍNA CHILAQUILES (group_id=21) ---
        ['menu_modifier_id' => 58,  'modifier_name_trim' => 'Huevo',          'group_id' => 21, 'group_name' => 'Proteína Chilaquiles', 'item_codigo' => 'INS-008',  'qty' => 2.000, 'uom' => 'PZ', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 59,  'modifier_name_trim' => 'Pollo',          'group_id' => 21, 'group_name' => 'Proteína Chilaquiles', 'item_codigo' => 'PROD-006', 'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 61,  'modifier_name_trim' => 'Queso de Hebra', 'group_id' => 21, 'group_name' => 'Proteína Chilaquiles', 'item_codigo' => 'INS-006',  'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 150, 'modifier_name_trim' => 'Sencillos',      'group_id' => 21, 'group_name' => 'Proteína Chilaquiles', 'item_codigo' => null,       'qty' => 0.000, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],

        // --- PROTEÍNA ENFRIJOLADAS (group_id=19) ---
        ['menu_modifier_id' => 51, 'modifier_name_trim' => 'Sencillas', 'group_id' => 19, 'group_name' => 'Proteína Enfrijoladas', 'item_codigo' => null,       'qty' => 0.000, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 52, 'modifier_name_trim' => 'Pollo',     'group_id' => 19, 'group_name' => 'Proteína Enfrijoladas', 'item_codigo' => 'PROD-006', 'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 53, 'modifier_name_trim' => 'Chorizo',   'group_id' => 19, 'group_name' => 'Proteína Enfrijoladas', 'item_codigo' => 'PROD-008', 'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 54, 'modifier_name_trim' => 'Huevo',     'group_id' => 19, 'group_name' => 'Proteína Enfrijoladas', 'item_codigo' => 'INS-008',  'qty' => 2.000, 'uom' => 'PZ', 'tipo' => 'ADICIONAL'],

        // --- RELLENO EMPANADA (group_id=3) ---
        ['menu_modifier_id' => 1, 'modifier_name_trim' => 'Pollo',     'group_id' => 3, 'group_name' => 'Relleno Empanada', 'item_codigo' => 'PROD-006', 'qty' => 0.080, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 2, 'modifier_name_trim' => 'Picadillo', 'group_id' => 3, 'group_name' => 'Relleno Empanada', 'item_codigo' => 'PROD-007', 'qty' => 0.080, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 3, 'modifier_name_trim' => 'Queso',     'group_id' => 3, 'group_name' => 'Relleno Empanada', 'item_codigo' => 'INS-006',  'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'SELECTOR'],

        // --- RELLENO TACO DORADO (group_id=4) ---
        ['menu_modifier_id' => 4, 'modifier_name_trim' => 'Pollo', 'group_id' => 4, 'group_name' => 'Relleno Taco Dorado', 'item_codigo' => 'PROD-006', 'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'SELECTOR'],
        ['menu_modifier_id' => 5, 'modifier_name_trim' => 'Papa',  'group_id' => 4, 'group_name' => 'Relleno Taco Dorado', 'item_codigo' => 'INS-016',  'qty' => 0.080, 'uom' => 'KG', 'tipo' => 'SELECTOR'],

        // --- EXTRA PROTEÍNA (group_id=64) ---
        ['menu_modifier_id' => 219, 'modifier_name_trim' => 'Extra Queso de Hebra',     'group_id' => 64, 'group_name' => 'Extra Proteina', 'item_codigo' => 'INS-006',  'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 220, 'modifier_name_trim' => 'Extra Pollo',              'group_id' => 64, 'group_name' => 'Extra Proteina', 'item_codigo' => 'PROD-006', 'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 221, 'modifier_name_trim' => 'Extra Chorizo',            'group_id' => 64, 'group_name' => 'Extra Proteina', 'item_codigo' => 'PROD-008', 'qty' => 0.060, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 239, 'modifier_name_trim' => 'Extra Huevo',              'group_id' => 64, 'group_name' => 'Extra Proteina', 'item_codigo' => 'INS-008',  'qty' => 1.000, 'uom' => 'PZ', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 241, 'modifier_name_trim' => 'Extra Pechuga Asada',      'group_id' => 64, 'group_name' => 'Extra Proteina', 'item_codigo' => 'PROD-010', 'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
        ['menu_modifier_id' => 243, 'modifier_name_trim' => 'Extra Cecina',             'group_id' => 64, 'group_name' => 'Extra Proteina', 'item_codigo' => 'INS-005',  'qty' => 0.100, 'uom' => 'KG', 'tipo' => 'ADICIONAL'],
    ],

    // =========================================================================
    // MAPEO menu_item POS → recipe selemti (para pos_menu_item_recipe_mapping)
    // =========================================================================
    'pos_menu_item_recipe_mapping' => [
        ['menu_item_id' => 2,  'menu_item_name' => 'Picada',          'recipe_codigo' => 'REC-PLA-001', 'porciones_por_orden' => 3],
        ['menu_item_id' => 8,  'menu_item_name' => 'Picada Terrena',  'recipe_codigo' => 'REC-PLA-001', 'porciones_por_orden' => 3],
        ['menu_item_id' => 33, 'menu_item_name' => 'Chilaquiles',     'recipe_codigo' => 'REC-PLA-002', 'porciones_por_orden' => 1],
        ['menu_item_id' => 34, 'menu_item_name' => 'Chilaquiles Terrena', 'recipe_codigo' => 'REC-PLA-002', 'porciones_por_orden' => 1],
    ],
];
