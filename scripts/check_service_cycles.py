from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1] / "src" / "server" / "Services"
files = {p.stem: p for p in root.glob("*.luau")}
graph = {name: set() for name in files}
pattern = re.compile(r"require\(script\.Parent\.([A-Za-z0-9_]+)\)")
for name, path in files.items():
    for target in pattern.findall(path.read_text()):
        if target in files:
            graph[name].add(target)

visiting = set()
visited = set()
stack = []

def visit(node):
    if node in visiting:
        start = stack.index(node)
        cycle = stack[start:] + [node]
        raise RuntimeError("service require cycle: " + " -> ".join(cycle))
    if node in visited:
        return
    visiting.add(node)
    stack.append(node)
    for target in sorted(graph[node]):
        visit(target)
    stack.pop()
    visiting.remove(node)
    visited.add(node)

try:
    for node in sorted(graph):
        visit(node)
except RuntimeError as exc:
    print(exc, file=sys.stderr)
    sys.exit(1)

print(f"service dependency graph clean ({len(graph)} services)")
