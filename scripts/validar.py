"""Validaciones del repositorio (nivel 1).

- Front matter presente y bloques de código cerrados.
- Enlaces .md relativos que existen.
- Imágenes (Markdown y HTML) y recursos url() de CSS que existen.
- Todo laboratorio que activa ip_forward en el host tiene una sección de reversión.
"""
import re, sys, pathlib

docs = pathlib.Path(__file__).resolve().parent.parent / "docs"
errores = []


def sin_codigo(txt):
    en = False
    for l in txt.splitlines():
        if l.startswith("```"):
            en = not en
            continue
        if not en:
            yield l


def sin_codigo_y_bloques(txt):
    """Todas las líneas, incluidas las de bloques de código (donde viven los comandos)."""
    return (l.strip().lstrip("$ ") for l in txt.splitlines() if not l.lstrip().startswith("#"))


def existe(base, ref):
    ref = ref.split("#")[0].split("?")[0]
    if not ref or re.match(r"^(https?:|mailto:|data:|//)", ref):
        return True
    destino = (docs / ref.lstrip("/")) if ref.startswith("/") else (base / ref)
    return destino.resolve().exists()


for md in sorted(docs.rglob("*.md")):
    txt = md.read_text(encoding="utf-8")
    rel = md.relative_to(docs)
    if not txt.startswith("---\n"):
        errores.append(f"{rel}: falta front matter")
    if sum(1 for l in txt.splitlines() if l.startswith("```")) % 2:
        errores.append(f"{rel}: bloque de código sin cerrar")
    for l in sin_codigo(txt):
        for m in re.finditer(r"\]\(([^)#\s]+\.md)(#[^)]*)?\)", l):
            if not existe(md.parent, m.group(1)):
                errores.append(f"{rel}: enlace roto {m.group(1)}")
        for m in re.finditer(r"!\[[^\]]*\]\(([^)\s]+)", l):
            if not existe(md.parent, m.group(1)):
                errores.append(f"{rel}: imagen no encontrada {m.group(1)}")
        for m in re.finditer(r'<img[^>]+src="([^"]+)"', l):
            if not existe(md.parent, m.group(1)):
                errores.append(f"{rel}: imagen no encontrada {m.group(1)}")
    # Los laboratorios que cambian el reenvío del host deben explicar cómo revertirlo
    host_forward = any("sysctl -w net.ipv4.ip_forward=1" in l and "netns exec" not in l
                       for l in sin_codigo_y_bloques(txt))
    if rel.parts[0] == "labs" and host_forward:
        if not re.search(r"^##+ (Revertir los cambios del host|.*Limpieza)", txt, re.M):
            errores.append(f"{rel}: modifica ip_forward en el host y no tiene sección de reversión/limpieza")

avisos = []
for css in sorted(docs.rglob("*.css")):
    for ref in re.findall(r"url\(['\"]?([^)'\"]+)", css.read_text(encoding="utf-8")):
        if not existe(css.parent, ref):
            avisos.append(f"{css.relative_to(docs)}: recurso no encontrado {ref}")

for a in avisos:
    print("AVISO:", a)
print("\n".join(errores) or "OK: sin errores")
sys.exit(1 if errores else 0)
