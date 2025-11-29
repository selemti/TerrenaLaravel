#!/bin/bash
# Script de protección para prevenir ejecución accidental de scripts destructivos

# Este script identifica y protege los archivos que contienen comandos destructivos
# de base de datos como DROP DATABASE

echo "🔍 Buscando scripts potencialmente destructivos..."

# Buscar archivos que contienen DROP DATABASE
destructive_files=$(find . -name "*.sql" -exec grep -l "DROP DATABASE" {} \;)

if [ -n "$destructive_files" ]; then
    echo "⚠️  Se encontraron archivos con comandos destructivos:"
    echo "$destructive_files"
    
    echo ""
    echo "🔒 Protegiendo archivos sensibles..."
    
    # Crear un directorio para scripts destructivos
    mkdir -p ./scripts_destructivos_protected
    
    # Mover los archivos a la carpeta protegida
    for file in $destructive_files; do
        if [ "$file" != "./scripts_destructivos_protected"/* ]; then
            echo "Moviendo $file a ./scripts_destructivos_protected/"
            mv "$file" ./scripts_destructivos_protected/
        fi
    done
    
    echo "✅ Archivos destructivos movidos a ./scripts_destructivos_protected/"
    echo "💡 Recomendación: Agregar una confirmación antes de ejecutar cualquier script de esta carpeta"
else
    echo "✅ No se encontraron scripts con comandos destructivos"
fi