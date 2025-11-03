#!/bin/bash
# =============================================================================
# SCRIPT: 00_verificar_referencias_codigo.sh
# Fecha: 2025-11-02
# Objetivo: Buscar referencias en código a tablas que se van a eliminar
# =============================================================================

echo "==================================================================="
echo "VERIFICACIÓN DE REFERENCIAS EN CÓDIGO - TABLAS A ELIMINAR"
echo "==================================================================="
echo ""
echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd /c/xampp3/htdocs/TerrenaLaravel

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de referencias encontradas
TOTAL_REFS=0

# Función para buscar referencias
check_table() {
    local table_name=$1
    local description=$2

    echo "-------------------------------------------------------------------"
    echo "Buscando referencias a: $table_name ($description)"
    echo "-------------------------------------------------------------------"

    # Buscar en archivos PHP
    local refs=$(grep -r "\b$table_name\b" app/ --include="*.php" 2>/dev/null | wc -l)

    if [ $refs -gt 0 ]; then
        echo -e "${RED}⚠️  ENCONTRADAS $refs referencias en código:${NC}"
        grep -r "\b$table_name\b" app/ --include="*.php" -n 2>/dev/null
        TOTAL_REFS=$((TOTAL_REFS + refs))
    else
        echo -e "${GREEN}✅ No se encontraron referencias${NC}"
    fi

    echo ""
}

# =============================================================================
# 1. TABLAS LEGACY
# =============================================================================
echo ""
echo "==================================================================="
echo "1. TABLAS LEGACY (con sufijo _legacy)"
echo "==================================================================="
echo ""

check_table "conversiones_unidad_legacy" "Conversiones de Unidad Legacy"
check_table "uom_conversion_legacy" "UOM Conversion Legacy"
check_table "unidad_medida_legacy" "Unidad de Medida Legacy"
check_table "unidades_medida_legacy" "Unidades de Medida Legacy"

# =============================================================================
# 2. TABLAS DUPLICADAS DE CATÁLOGOS
# =============================================================================
echo ""
echo "==================================================================="
echo "2. TABLAS DUPLICADAS DE CATÁLOGOS (vacías)"
echo "==================================================================="
echo ""

# Buscar 'sucursal' pero excluir 'sucursales' y 'sucursal_id'
echo "-------------------------------------------------------------------"
echo "Buscando referencias a: sucursal (Catálogo Sucursal)"
echo "-------------------------------------------------------------------"
refs=$(grep -r "table.*=.*['\"]sucursal['\"]" app/ --include="*.php" 2>/dev/null | wc -l)
if [ $refs -gt 0 ]; then
    echo -e "${RED}⚠️  ENCONTRADAS $refs referencias en modelos:${NC}"
    grep -r "table.*=.*['\"]sucursal['\"]" app/ --include="*.php" -n 2>/dev/null
    TOTAL_REFS=$((TOTAL_REFS + refs))
else
    echo -e "${GREEN}✅ No se encontraron referencias en \$table${NC}"
fi
echo ""

# Buscar 'almacen' pero excluir 'almacenes' y 'almacen_id'
echo "-------------------------------------------------------------------"
echo "Buscando referencias a: almacen (Catálogo Almacén)"
echo "-------------------------------------------------------------------"
refs=$(grep -r "table.*=.*['\"]almacen['\"]" app/ --include="*.php" 2>/dev/null | wc -l)
if [ $refs -gt 0 ]; then
    echo -e "${RED}⚠️  ENCONTRADAS $refs referencias en modelos:${NC}"
    grep -r "table.*=.*['\"]almacen['\"]" app/ --include="*.php" -n 2>/dev/null
    TOTAL_REFS=$((TOTAL_REFS + refs))
else
    echo -e "${GREEN}✅ No se encontraron referencias en \$table${NC}"
fi
echo ""

# Buscar 'proveedor' pero excluir 'proveedores' y 'proveedor_id'
echo "-------------------------------------------------------------------"
echo "Buscando referencias a: proveedor (Catálogo Proveedor)"
echo "-------------------------------------------------------------------"
refs=$(grep -r "table.*=.*['\"]proveedor['\"]" app/ --include="*.php" 2>/dev/null | wc -l)
if [ $refs -gt 0 ]; then
    echo -e "${RED}⚠️  ENCONTRADAS $refs referencias en modelos:${NC}"
    grep -r "table.*=.*['\"]proveedor['\"]" app/ --include="*.php" -n 2>/dev/null
    TOTAL_REFS=$((TOTAL_REFS + refs))
else
    echo -e "${GREEN}✅ No se encontraron referencias en \$table${NC}"
fi
echo ""

check_table "receta[^_]" "Receta (no receta_cab, receta_det)"
check_table "receta_cab" "Receta Cabecera"

# =============================================================================
# 3. TABLAS DE CAJA CHICA
# =============================================================================
echo ""
echo "==================================================================="
echo "3. TABLAS DE CAJA CHICA (verificar cuál usa el módulo)"
echo "==================================================================="
echo ""

echo "-------------------------------------------------------------------"
echo "Buscando referencias a: caja_fondo"
echo "-------------------------------------------------------------------"
refs=$(grep -r "table.*=.*['\"]caja_fondo['\"]" app/ --include="*.php" 2>/dev/null | wc -l)
if [ $refs -gt 0 ]; then
    echo -e "${YELLOW}⚠️  ENCONTRADAS $refs referencias en modelos:${NC}"
    grep -r "table.*=.*['\"]caja_fondo['\"]" app/ --include="*.php" -n 2>/dev/null
    echo -e "${YELLOW}⚠️  ADVERTENCIA: Verificar si esta tabla está en uso antes de eliminar${NC}"
    TOTAL_REFS=$((TOTAL_REFS + refs))
else
    echo -e "${GREEN}✅ No se encontraron referencias en \$table${NC}"
fi
echo ""

echo "-------------------------------------------------------------------"
echo "Buscando referencias a: cash_funds (exacto, no cash_fund_*)"
echo "-------------------------------------------------------------------"
refs=$(grep -r "table.*=.*['\"]cash_funds['\"]" app/ --include="*.php" 2>/dev/null | wc -l)
if [ $refs -gt 0 ]; then
    echo -e "${YELLOW}⚠️  ENCONTRADAS $refs referencias en modelos:${NC}"
    grep -r "table.*=.*['\"]cash_funds['\"]" app/ --include="*.php" -n 2>/dev/null
    echo -e "${YELLOW}⚠️  ADVERTENCIA: Verificar si esta tabla está en uso antes de eliminar${NC}"
    TOTAL_REFS=$((TOTAL_REFS + refs))
else
    echo -e "${GREEN}✅ No se encontraron referencias en \$table${NC}"
fi
echo ""

# =============================================================================
# 4. TABLAS DE USUARIOS Y ROLES
# =============================================================================
echo ""
echo "==================================================================="
echo "4. TABLAS DE USUARIOS Y ROLES"
echo "==================================================================="
echo ""

echo "-------------------------------------------------------------------"
echo "Buscando referencias a: usuario (no usuarios, usuario_id)"
echo "-------------------------------------------------------------------"
refs=$(grep -r "table.*=.*['\"]usuario['\"]" app/ --include="*.php" 2>/dev/null | wc -l)
if [ $refs -gt 0 ]; then
    echo -e "${RED}⚠️  ENCONTRADAS $refs referencias en modelos:${NC}"
    grep -r "table.*=.*['\"]usuario['\"]" app/ --include="*.php" -n 2>/dev/null
    TOTAL_REFS=$((TOTAL_REFS + refs))
else
    echo -e "${GREEN}✅ No se encontraron referencias en \$table${NC}"
fi
echo ""

echo "-------------------------------------------------------------------"
echo "Buscando referencias a: rol (exacto, no roles, rol_id)"
echo "-------------------------------------------------------------------"
refs=$(grep -r "table.*=.*['\"]rol['\"]" app/ --include="*.php" 2>/dev/null | wc -l)
if [ $refs -gt 0 ]; then
    echo -e "${RED}⚠️  ENCONTRADAS $refs referencias en modelos:${NC}"
    grep -r "table.*=.*['\"]rol['\"]" app/ --include="*.php" -n 2>/dev/null
    TOTAL_REFS=$((TOTAL_REFS + refs))
else
    echo -e "${GREEN}✅ No se encontraron referencias en \$table${NC}"
fi
echo ""

# =============================================================================
# RESUMEN FINAL
# =============================================================================
echo ""
echo "==================================================================="
echo "RESUMEN DE VERIFICACIÓN"
echo "==================================================================="
echo ""
echo "Total de referencias encontradas: $TOTAL_REFS"
echo ""

if [ $TOTAL_REFS -eq 0 ]; then
    echo -e "${GREEN}✅ SAFE TO PROCEED: No se encontraron referencias a tablas que se van a eliminar${NC}"
    echo -e "${GREEN}   Puedes ejecutar los scripts de eliminación de forma segura.${NC}"
else
    echo -e "${RED}⚠️  ADVERTENCIA: Se encontraron $TOTAL_REFS referencias en código${NC}"
    echo -e "${RED}   Debes revisar y actualizar el código antes de eliminar tablas.${NC}"
    echo -e "${RED}   Revisa el output arriba para ver las ubicaciones exactas.${NC}"
fi

echo ""
echo "==================================================================="
echo "FIN DE VERIFICACIÓN"
echo "==================================================================="
