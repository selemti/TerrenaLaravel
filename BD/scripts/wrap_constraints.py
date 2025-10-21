import re
from pathlib import Path

PATTERN = re.compile(r"ALTER TABLE.*?;", re.IGNORECASE | re.DOTALL)
CONSTRAINT_RE = re.compile(r"ADD\s+CONSTRAINT\s+(\S+)", re.IGNORECASE)

PATCH_DIR = Path('BD/patches')

for path in PATCH_DIR.rglob('*constraints.sql'):
    schema = 'public'
    parts = path.parts
    if 'selemti' in parts:
        schema = 'selemti'
    text = path.read_text(encoding='utf-8')
    header_end = text.find('ALTER TABLE')
    if header_end == -1:
        continue
    header = text[:header_end]
    body = text[header_end:]
    statements = PATTERN.findall(body)
    new_body_parts = []
    for stmt in statements:
        constraint_match = CONSTRAINT_RE.search(stmt)
        if not constraint_match:
            new_body_parts.append(stmt)
            continue
        constraint_name = constraint_match.group(1).strip().strip('"')
        block = f"DO $$\nBEGIN\n  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints\n                 WHERE constraint_schema = '{schema}' AND constraint_name = '{constraint_name}') THEN\n    {stmt.strip()}\n  END IF;\nEND;\n$$;\n"
        new_body_parts.append(block)
    footer_index = text.rfind('COMMIT;')
    footer = '' if footer_index == -1 else text[footer_index:]
    new_content = header + '\n'.join(new_body_parts)
    if footer:
        new_content = new_content.rstrip() + '\n' + footer + '\n'
    path.write_text(new_content, encoding='utf-8')
