# Debug Report: Ítems y Modificadores - 10 de Diciembre 2025

## Problema Principal
Error crítico en el reporte `item_mod_combos` donde:
- Items sin modificadores muestran $0.00 en ventas en lugar de valores reales
- "MENU DEL DÍA" muestra $0.00 cuando debería mostrar $43,537
- "EMPANADA" muestra 2 unidades cuando debería mostrar 190+

## Estado Actual del Problema

### ✅ Descubierto
- **El servicio funciona correctamente**: `ItemModsReportService` retorna **234 filas** con datos correctos
- **El controller recibe los datos**: 234 filas del servicio
- **El controller NO transmite los datos**: Retorna **0 filas** a la vista
- **La vista recibe 0 filas**: Muestra datos incorrectos

### ❓ Por determinar
- ¿Dónde se pierden las 234 filas en el controller?
- ¿Hay alguna condición que filtra los resultados?
- ¿Hay transformación de datos que causa el problema?

## Archivos Clave

### 1. Service (Funciona correctamente)
`app/Services/Reports/ItemModsReportService.php`
```php
// fetch() retorna 234 filas correctas
// summarize() calcula correctamente
// Unidades de empanada: 190+
```

### 2. Controller (Problemático)
`app/Http/Reports/SalesModsController.php`
```php
public function show(Request $request): View
{
    // ... lines 53-73 ...
    if ($view !== 'legacy') {
        $dataset = $this->service->fetch($start, $end, $filters); // ✅ 234 filas
        $summary = $this->service->summarize($dataset, $view);
        // ... más procesamiento ...
    }

    return view('reports.sales.mods', [
        'rows' => $dataset, // ❌ somehow 0 filas
    ]);
}
```

### 3. Vista (Recibe 0 filas)
`resources/views/reports/sales/mods.blade.php`
- Incluye `mods-table-combos.blade.php`
- Procesa `$rows` pero llega vacío

## Scripts de Debug

### test_controller.php
```bash
php test_controller.php
# Resultado:
# Dataset fetched: 234 rows
# Respuesta del controller: 0 rows
```

### debug_controller_paso_a_paso.php
En progreso - necesita corrección del método `extractBranchesFromNewData`

## Próximos Pasos

### 1. Completar Debug del Controller
```php
// Necesario verificar:
- ¿Qué hace extractBranchesFromNewData()?
- ¿Hay algún filtro que elimine las filas?
- ¿La transformación de datos causa el problema?
```

### 2. Revisión Detallada del Flujo
1. Service fetch → 234 filas ✅
2. Controller processing → ? ❓
3. Vista receive → 0 filas ❌

### 3. Solución a Implementar
Una vez identificado el punto exacto del problema:
- Corregir la lógica del controller
- Asegurar que todos los datos lleguen a la vista
- Verificar que la vista procese correctamente

## Comandos Útiles

```bash
# Limpiar caché
php artisan cache:clear
php artisan config:clear
php artisan view:clear
php artisan route:clear

# Ejecutar tests
php debug_controller.php

# Revisar logs
tail -f storage/logs/laravel.log
```

## URLs de Referencia

- Reporte con problema: `http://localhost/TerrenaLaravel/reports/sales/mods?start_date=2025-12-02&end_date=2025-12-08&view=item_mod_combos&include_empty=1`

## Notas Importantes

- El problema está específicamente en el controller, no en el servicio
- Los datos en la base de datos son correctos (verificado con consultas directas)
- La vista funciona correctamente, solo recibe datos vacíos
- Es un problema de transmisión de datos entre capas

---

**Para continuar mañana:**
1. Ejecutar el debug paso a paso corregido
2. Identificar exactamente dónde se pierden los datos en el controller
3. Implementar la corrección
4. Verificar que la vista muestre los datos correctos