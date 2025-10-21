from pathlib import Path

PATCH_DIR = Path('BD/patches')

for sql_path in PATCH_DIR.rglob('*.sql'):
    lines = sql_path.read_text(encoding='utf-8').splitlines()
    cleaned = []
    skip = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('Owner:') or stripped == '--':
            continue
        cleaned.append(line)
    sql_path.write_text('\n'.join(cleaned) + '\n', encoding='utf-8')
