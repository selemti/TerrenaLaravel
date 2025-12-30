#!/usr/bin/env python3
"""
Extraer tablas específicas del dump productivo UX_Full_dump.sql
Tablas a extraer: precorte_efectivo, postcorte, auditoria
"""

import re
import sys

def extract_table_from_dump(dump_file, table_name, output_file):
    """Extraer INSERTs de una tabla específica del dump"""

    print(f"Extrayendo tabla: {table_name}")

    with open(dump_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Patrón para encontrar INSERTs de la tabla
    pattern = rf'INSERT INTO selemti\.{table_name}\s*\([^)]*\)\s*VALUES\s*(.*?);'

    # Encontrar todos los INSERTs de la tabla
    matches = re.findall(pattern, content, re.DOTALL | re.IGNORECASE)

    if not matches:
        print(f"⚠️  No se encontraron INSERTs para la tabla {table_name}")
        return

    # Escribir los INSERTs al archivo de salida
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(f"-- INSERTs para {table_name} extraídos de UX_Full_dump.sql\n")
        f.write(f"-- Total de registros: {len(matches)}\n\n")

        for i, match in enumerate(matches, 1):
            # Asegurar que cada INSERT termine con punto y coma
            insert_sql = f"INSERT INTO selemti.{table_name} VALUES {match.strip()};"

            # Eliminar comillas extra si existen
            insert_sql = insert_sql.replace("''", "'")

            f.write(insert_sql + "\n")

            if i % 100 == 0:
                print(f"  Procesados {i} registros...")

    print(f"✅ Extraídos {len(matches)} registros de {table_name} -> {output_file}")

def main():
    dump_file = "./BD/Diciembre/08_12_2025/UX_Full_dump.sql"

    # Tablas a extraer
    tables = [
        ("precorte_efectivo", "todos_precorte_efectivo_productivos.sql"),
        ("postcorte", "todos_postcorte_productivos.sql"),
        ("auditoria", "todos_auditoria_productivos.sql")
    ]

    print("=== EXTRAYENDO TABLAS FALTANTES DEL DUMP PRODUCTIVO ===\n")

    for table_name, output_file in tables:
        output_path = f"./BD/Diciembre/08_12_2025/{output_file}"
        extract_table_from_dump(dump_file, table_name, output_path)

    print("\n=== EXTRACCIÓN COMPLETADA ===")
    print("Archivos generados:")
    for _, output_file in tables:
        print(f"  - ./BD/Diciembre/08_12_2025/{output_file}")

if __name__ == "__main__":
    main()