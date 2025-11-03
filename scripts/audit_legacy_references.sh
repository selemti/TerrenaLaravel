#!/bin/bash

echo "=== AUDITORÍA DE REFERENCIAS A TABLAS LEGACY EN CÓDIGO ==="
echo ""
echo "Fecha: $(date)"
echo ""

LEGACY_TABLES=(
    "usuario" "rol" "sucursal" "almacen" "bodega" "proveedor"
    "unidad_medida_legacy" "unidades_medida_legacy"
    "conversiones_unidad_legacy" "uom_conversion_legacy"
    "insumo" "lote" "merma" "stock_policy"
    "transfer_cab" "transfer_det" "traspaso_cab" "traspaso_det"
    "op_cab" "op_produccion_cab" "prod_cab" "sol_prod_cab"
    "op_insumo" "prod_det" "sol_prod_det" "op_yield"
    "receta" "receta_cab" "receta_det" "receta_insumo"
    "receta_version" "receta_shadow"
    "caja_fondo" "caja_fondo_mov" "caja_fondo_adj" "caja_fondo_arqueo"
    "auditoria" "audit_log"
)

TOTAL_REFS=0

for table in "${LEGACY_TABLES[@]}"; do
    echo "──────────────────────────────────────────────"
    echo "Buscando referencias a: $table"
    echo "──────────────────────────────────────────────"

    FOUND=0

    # Buscar en modelos
    REFS=$(grep -rin "$table" app/Models/ 2>/dev/null | wc -l)
    if [ "$REFS" -gt 0 ]; then
        echo "  ⚠️ MODELOS: $REFS referencias"
        grep -rin "$table" app/Models/ 2>/dev/null | head -5
        FOUND=$((FOUND + REFS))
    fi

    # Buscar en migraciones
    REFS=$(grep -rin "$table" database/migrations/ 2>/dev/null | wc -l)
    if [ "$REFS" -gt 0 ]; then
        echo "  ⚠️ MIGRACIONES: $REFS referencias"
        grep -rin "$table" database/migrations/ 2>/dev/null | head -5
        FOUND=$((FOUND + REFS))
    fi

    # Buscar en controladores
    REFS=$(grep -rin "$table" app/Http/Controllers/ 2>/dev/null | wc -l)
    if [ "$REFS" -gt 0 ]; then
        echo "  ⚠️ CONTROLADORES: $REFS referencias"
        grep -rin "$table" app/Http/Controllers/ 2>/dev/null | head -5
        FOUND=$((FOUND + REFS))
    fi

    # Buscar en servicios
    REFS=$(grep -rin "$table" app/Services/ 2>/dev/null | wc -l)
    if [ "$REFS" -gt 0 ]; then
        echo "  ⚠️ SERVICIOS: $REFS referencias"
        grep -rin "$table" app/Services/ 2>/dev/null | head -5
        FOUND=$((FOUND + REFS))
    fi

    # Buscar en Livewire
    REFS=$(grep -rin "$table" app/Livewire/ 2>/dev/null | wc -l)
    if [ "$REFS" -gt 0 ]; then
        echo "  ⚠️ LIVEWIRE: $REFS referencias"
        grep -rin "$table" app/Livewire/ 2>/dev/null | head -5
        FOUND=$((FOUND + REFS))
    fi

    if [ "$FOUND" -eq 0 ]; then
        echo "  ✅ Sin referencias - SAFE TO DROP"
    else
        echo "  ❌ TOTAL: $FOUND referencias - REQUIERE REVISIÓN"
        TOTAL_REFS=$((TOTAL_REFS + FOUND))
    fi

    echo ""
done

echo "══════════════════════════════════════════════"
echo "=== RESUMEN FINAL ==="
echo "══════════════════════════════════════════════"
echo "Total de referencias a tablas legacy: $TOTAL_REFS"
echo ""

if [ "$TOTAL_REFS" -eq 0 ]; then
    echo "✅ NO SE ENCONTRARON REFERENCIAS"
    echo "   Todas las tablas legacy pueden eliminarse de forma segura."
else
    echo "⚠️ SE ENCONTRARON $TOTAL_REFS REFERENCIAS"
    echo "   Revisar manualmente antes de ejecutar DROPs."
fi

echo ""
echo "=== FIN DE AUDITORÍA ==="
