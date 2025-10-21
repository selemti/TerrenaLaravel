# Parches incrementales Floreant POS / Terrena

Estos archivos se generaron automáticamente a partir de `BD/backup_pre_deploy_20251017_221857.sql`, filtrando sólo los objetos que no existen en el dump funcional (`D:/Tavo/2025/UX/BD/Octubre/UX_17_10_2025_dump.sql`). Cada módulo agrupa los objetos por tipo y esquema, de modo que puedas aplicarlos gradualmente sin recrear tablas ya presentes.

## Estructura

```
BD/patches/
  ├─ public/
  │   ├─ 10_pos_operaciones.sql    # funciones, tablas auxiliares, triggers y secuencias propias del POS
  │   └─ 20_consultas.sql          # vistas, comentarios y ACL de solo lectura
  └─ selemti/
      ├─ 00_base.sql               # tipos ENUM del dominio selemti
      ├─ 05_sequences.sql          # secuencias + OWNED BY faltantes
      ├─ 10_tables.sql             # tablas nuevas del esquema selemti
      ├─ 20_constraints.sql        # PK, CHECK y restricciones generales
      ├─ 25_indexes.sql            # índices simples
      ├─ 30_functions.sql          # funciones PL/pgSQL
      ├─ 40_views.sql              # vistas y materializaciones livianas
      ├─ 50_triggers.sql           # triggers + creación (sin depender de otros módulos)
      └─ 60_comments.sql           # comentarios y ACL
```

Todos los scripts incluyen `BEGIN; ... COMMIT;` para que puedas aplicarlos con `psql -f`. Ejecuta los módulos en el orden mostrado arriba; cada archivo asume que los anteriores ya corrieron.

## Uso sugerido

1. Haz un respaldo de tu BD `pos` (o trabaja sobre una copia).
2. Aplica los módulos `selemti` en orden (`00_base` → `05_sequences` → ... → `60_comments`).
3. Aplica los módulos `public` sólo si corresponde (POS/caja/KDS).
4. Valida funcionalmente: inventario, recetas, conciliaciones, cortes de caja y KDS.

> Nota: Los scripts contienen exactamente las definiciones ausentes en la BD actual según `missing_objects.json`. Si agregas nuevas migraciones, vuelve a ejecutar `BD/scripts/generate_modular_patches.py` para regenerar los patches.
