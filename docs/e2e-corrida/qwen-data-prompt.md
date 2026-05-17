# Prompt para Qwen — Datos realistas MasterDataSeeder

Necesito que generes los arrays de datos para el `MasterDataSeeder` de un ERP de restaurante
mexicano de comida corrida / a la carta (estilo Terrena). Los datos deben ser realistas y
coherentes entre sí. Devuelve PHP arrays listos para copiar y pegar.

---

## 1. Items / Insumos (~25 registros)

Genera un array PHP `$items` con exactamente 25 insumos. Cada insumo tiene:
- `codigo` — clave única, ej: `'INS-001'`
- `nombre` — nombre real de insumo de cocina mexicana
- `categoria` — una de: `CARNES`, `LACTEOS`, `ABARROTES`, `VEGETALES`, `BEBIDAS`, `CONDIMENTOS`
- `uom_base_clave` — la unidad base: `KG` (para sólidos/cárnicos), `L` (para líquidos), `PZ` (para piezas)
- `uom_compra_clave` — la unidad de compra: puede ser `KG`, `L`, `PZ`, `PAQ`, `CAJ`
- `factor_compra` — cuántas unidades base trae 1 unidad de compra (si uom_compra=uom_base → 1.0)
- `costo_promedio` — precio promedio en MXN por unidad base (realista para México 2025)

Incluye variedad: carnes (pollo, res, cerdo), lácteos (queso, crema, leche), vegetales (tomate,
cebolla, chile, aguacate), abarrotes (arroz, frijol, aceite, harina), bebidas (refresco, agua),
condimentos (sal, pimienta, comino, ajo).

## 2. Proveedores (3 registros)

Array `$proveedores`:
- `nombre` — nombre realista de distribuidor mexicano
- `rfc` — RFC ficticio válido formato mexicano
- `contacto` — nombre de contacto
- `telefono`, `email`

## 3. Recetas (~8 registros)

Array `$recetas` con 8 platillos/preparaciones, incluyendo 2 sub-recetas (bases usadas en otros):

Estructura por receta:
```php
[
    'codigo'      => 'REC-001',
    'nombre'      => 'Pollo en Salsa de Chile Ancho',
    'porciones'   => 4,
    'tipo'        => 'PLATILLO',  // o 'SUB_RECETA'
    'ingredientes' => [
        ['insumo_codigo' => 'INS-001', 'qty' => 0.500, 'uom' => 'KG'],
        // ...
    ]
]
```

Las 2 sub-recetas (tipo='SUB_RECETA') deben ser referenciadas como ingrediente en al menos
2 platillos principales.

Platillos sugeridos para restaurante mexicano: Pollo a la plancha, Arroz rojo, Frijoles de olla,
Enchiladas verdes, Sopa de lima, Guisado de res, Agua de horchata, Salsa verde (sub-receta),
Caldo de pollo base (sub-receta).

## 4. Output esperado

Devuelve el archivo PHP completo listo para guardar como
`database/seeders/E2E/RestaurantDataArrays.php`:

```php
<?php
// Datos generados para MasterDataSeeder — restaurante mexicano
return [
    'items'       => [ /* 25 items */ ],
    'proveedores' => [ /* 3 proveedores */ ],
    'recetas'     => [ /* 8 recetas con ingredientes */ ],
];
```

Asegúrate de que los `insumo_codigo` en los ingredientes de las recetas correspondan exactamente
a los `codigo` del array de items. Los cantidades deben ser realistas para las porciones indicadas.
