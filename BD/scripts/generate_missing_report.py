import json
from pathlib import Path

with open('BD/patches/missing_objects.json', encoding='utf-8') as fh:
    missing = json.load(fh)

already_covered = {
    ('selemti','type'),
    ('selemti','table'),
    ('selemti','sequence'),
    ('selemti','sequence owned by'),
    ('selemti','function'),
    ('selemti','view'),
    ('selemti','trigger'),
    ('selemti','comment'),
    ('public','function'),
    ('public','view')
}

remaining = {}
for schema, types in missing.items():
    for typ, items in types.items():
        if not items:
            continue
        key = (schema, typ)
        if key in already_covered:
            continue
        remaining.setdefault(schema, {})[typ] = items

print(json.dumps(remaining, indent=2, ensure_ascii=False))
