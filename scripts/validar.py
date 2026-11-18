"""Validaciones del repositorio: front matter, bloques de código cerrados y enlaces .md relativos."""
import re, sys, pathlib
docs = pathlib.Path(__file__).resolve().parent.parent / "docs"
errores = []
for md in sorted(docs.rglob("*.md")):
    txt = md.read_text(encoding="utf-8")
    if not txt.startswith("---\n"):
        errores.append(f"{md}: falta front matter")
    if sum(1 for l in txt.splitlines() if l.startswith("```")) % 2:
        errores.append(f"{md}: bloque de código sin cerrar")
    en_codigo = False
    for l in txt.splitlines():
        if l.startswith("```"):
            en_codigo = not en_codigo
        if en_codigo:
            continue
        for m in re.finditer(r"\]\(([^)#\s]+\.md)(#[^)]*)?\)", l):
            if not (md.parent / m.group(1)).resolve().exists():
                errores.append(f"{md}: enlace roto {m.group(1)}")
print("\n".join(errores) or "OK: sin errores")
sys.exit(1 if errores else 0)
