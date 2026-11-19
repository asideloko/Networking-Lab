"""Validaciones del repositorio (nivel 1).

- Front matter presente y bloques de código cerrados.
- Enlaces .md relativos que existen.
- Imágenes (Markdown y HTML) y recursos url() de CSS que existen.
- Todo laboratorio que activa ip_forward en el host tiene una sección de reversión.
"""
import re, sys, pathlib, subprocess

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
    if rel.parts[0] == "labs" and rel.parts[1].startswith("lab-"):
        if not re.search(r"^##+ .*?(?:Limpieza|Revertir los cambios del host)", txt, re.M):
            errores.append(f"{rel}: falta una sección explícita de limpieza o reversión")
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
    # Los cambios del host deben conservar y restaurar el estado previo.
    host_forward = any("sysctl -w net.ipv4.ip_forward=1" in l and "netns exec" not in l
                       for l in sin_codigo_y_bloques(txt))
    if rel.parts[0] == "labs" and host_forward:
        if not re.search(r"^##+ (Revertir los cambios del host|.*Limpieza)", txt, re.M):
            errores.append(f"{rel}: modifica ip_forward en el host y no tiene sección de reversión/limpieza")
        guardado = re.search(r"sysctl -n net\.ipv4\.ip_forward[^\n]*(?:>\s*|tee\s+)(/tmp/[^\s]+)", txt)
        restaurado = re.search(r"sysctl -w net\.ipv4\.ip_forward=\"\$\(cat\s+([^ )]+)\)\"", txt)
        if not guardado:
            errores.append(f"{rel}: no guarda el valor original de ip_forward antes de modificar el host")
        elif not restaurado or restaurado.group(1) != guardado.group(1):
            errores.append(f"{rel}: no restaura el mismo archivo de estado de ip_forward")
        if re.search(r"sysctl -w net\.ipv4\.ip_forward=0", txt):
            errores.append(f"{rel}: contiene una reversión fija a 0 en lugar de restaurar el valor original")

    # Las reglas NAT del host solo se eliminan si el laboratorio las añadió.
    nat_host = [l for l in sin_codigo_y_bloques(txt)
                if "iptables -t nat -A POSTROUTING" in l and "netns exec" not in l]
    if rel.parts[0] == "labs" and nat_host:
        if not re.search(r"/tmp/[^\s]+host-nat\.added", txt):
            errores.append(f"{rel}: no registra si añadió la regla NAT del host")

# Sintaxis de bloques Bash completos (sin ejecutar comandos ni modificar el sistema).
for md in sorted(docs.rglob("*.md")):
    txt = md.read_text(encoding="utf-8")
    for n, match in enumerate(re.finditer(r"^```bash[ \t]*\n(.*?)^```[ \t]*$", txt, re.M | re.S), 1):
        resultado = subprocess.run(["bash", "-n"], input=match.group(1), text=True,
                                   capture_output=True, check=False)
        if resultado.returncode:
            detalle = resultado.stderr.strip().splitlines()[-1]
            errores.append(f"{md.relative_to(docs)}: sintaxis Bash inválida en bloque {n}: {detalle}")

avisos = []
for css in sorted(docs.rglob("*.css")):
    for ref in re.findall(r"url\(['\"]?([^)'\"]+)", css.read_text(encoding="utf-8")):
        if not existe(css.parent, ref):
            avisos.append(f"{css.relative_to(docs)}: recurso no encontrado {ref}")

for a in avisos:
    print("AVISO:", a)
print("\n".join(errores) or "OK: sin errores")
sys.exit(1 if errores else 0)
