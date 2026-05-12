<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Modo Financiero Canónico (SSOT)
    |--------------------------------------------------------------------------
    |
    | Cuando se activa, el sistema ignora el cálculo aritmético de 'total_discount'
    | y utiliza public.transactions como la Fuente Única de Verdad (SSOT).
    |
    | Activable dinámicamente vía ?mode=canon en la URL.
    |
    */
    'use_canon_mode' => env('FINANCE_USE_CANON_MODE', false),

    /*
    |--------------------------------------------------------------------------
    | Parámetros de Conciliación
    |--------------------------------------------------------------------------
    */
    'tolerance_cents' => 5, // Diferencia tolerable en centavos para reportes
];
