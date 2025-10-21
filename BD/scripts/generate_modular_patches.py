import json
import re
from pathlib import Path

BACKUP_PATH = Path('BD/backup_pre_deploy_20251017_221857.sql')
MISSING_PATH = Path('BD/patches/missing_objects.json')
OUT_DIR = Path('BD/patches')

MODULE_MAP = {
    'public': {
        'function': 'public/10_pos_operaciones.sql',
        'view': 'public/20_consultas.sql',
        'table': 'public/10_pos_operaciones.sql',
        'sequence': 'public/10_pos_operaciones.sql',
        'sequence owned by': 'public/10_pos_operaciones.sql',
        'trigger': 'public/10_pos_operaciones.sql',
        'constraint': 'public/10_pos_operaciones.sql',
        'fk constraint': 'public/10_pos_operaciones.sql',
        'index': 'public/10_pos_operaciones.sql',
        'default': 'public/10_pos_operaciones.sql',
        'comment': 'public/20_consultas.sql',
        'acl': 'public/20_consultas.sql'
    },
    'selemti': {
        'type': 'selemti/00_base.sql',
        'sequence': 'selemti/05_sequences.sql',
        'sequence owned by': 'selemti/15_sequence_owned_by.sql',
        'table': 'selemti/10_tables.sql',
        'default': 'selemti/10_tables.sql',
        'constraint': 'selemti/20_constraints.sql',
        'fk constraint': 'selemti/20_constraints.sql',
        'index': 'selemti/25_indexes.sql',
        'function': 'selemti/30_functions.sql',
        'view': 'selemti/40_views.sql',
        'trigger': 'selemti/50_triggers.sql',
        'comment': 'selemti/60_comments.sql',
        'acl': 'selemti/60_comments.sql'
    }
}

HEADER_TEMPLATE = """-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql\nBEGIN;\nSET search_path = selemti, public;\n"""
FOOTER = "COMMIT;\n"

COMMENT_PATTERN = re.compile(r'--\s+Name:\s+(?P<name>.+?);\s+Type:\s+(?P<type>.+?);\s+Schema:\s+(?P<schema>.+?);')


def parse_backup(text: str):
    matches = list(COMMENT_PATTERN.finditer(text))
    objects = []
    for i, match in enumerate(matches):
        start = match.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[start:end].strip('\n')
        objects.append({
            'name': match.group('name').strip(),
            'type': match.group('type').strip().lower(),
            'schema': match.group('schema').strip().lower(),
            'body': body
        })
    return objects


def load_missing():
    if not MISSING_PATH.exists():
        return None
    with MISSING_PATH.open(encoding='utf-8') as fh:
        return json.load(fh)


def ensure_header(modules: dict, module_path: str):
    if module_path not in modules:
        modules[module_path] = HEADER_TEMPLATE


ALWAYS_INCLUDE = {'view'}


def should_include(schema: str, typ: str, name: str, missing):
    if typ in ALWAYS_INCLUDE:
        return True
    if missing is None:
        return True
    names = missing.get(schema, {}).get(typ)
    if names is None:
        return False
    return name in names


def main():
    backup_text = BACKUP_PATH.read_text(encoding='utf-8', errors='ignore')
    objects = parse_backup(backup_text)
    missing = load_missing()

    modules: dict[str, str] = {}

    for obj in objects:
        schema = obj['schema']
        typ = obj['type']
        name = obj['name']
        body = obj['body']

        if schema not in MODULE_MAP:
            continue
        module_path = MODULE_MAP[schema].get(typ)
        if not module_path:
            continue
        if not should_include(schema, typ, name, missing):
            continue

        ensure_header(modules, module_path)
        modules[module_path] += body.strip() + '\n\n'

    for path, content in modules.items():
        if not content.endswith(FOOTER):
            content += FOOTER
        full_path = OUT_DIR / path
        full_path.parent.mkdir(parents=True, exist_ok=True)
        full_path.write_text(content, encoding='utf-8')


if __name__ == '__main__':
    main()
