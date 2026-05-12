import json

try:
    with open('graphify-out/graph.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception as e:
    print(f"Error loading graph.json: {e}")
    exit(1)

nodes = data.get('nodes', [])
links = data.get('links', [])

connected_nodes = set()
for l in links:
    connected_nodes.add(l.get('source'))
    connected_nodes.add(l.get('target'))

orphans = [n for n in nodes if n.get('id') not in connected_nodes]

print(f"Total nodes: {len(nodes)}")
print(f"Total links: {len(links)}")
print(f"Total orphans: {len(orphans)}")
print("-" * 40)

app_orphans = [n for n in orphans if 'app/' in n.get('id', '') or 'routes/' in n.get('id', '')]
print(f"Huérfanos críticos (en app/ o routes/): {len(app_orphans)}\n")

for o in sorted([n['id'] for n in app_orphans])[:30]:
    print(f" - {o}")
if len(app_orphans) > 30:
    print(f" ... y {len(app_orphans) - 30} más.")
