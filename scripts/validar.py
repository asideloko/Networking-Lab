"""Validaciones del repositorio (nivel 1).

- Front matter presente y bloques de código cerrados.
- Enlaces .md relativos que existen.
- Imágenes (Markdown y HTML) y recursos url() de CSS que existen.
- Todo laboratorio que activa ip_forward en el host tiene una sección de reversión.
- Controles estáticos de propiedad de recursos y cambios globales conocidos.
- Rechazo de patrones de limpieza/seguridad peligrosos detectados en la auditoría.
"""
import re, sys, pathlib, subprocess, tomllib

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
    if rel.parts[0] == "02-LABORATORIOS" and rel.parts[1].startswith("lab-"):
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
    if rel.parts[0] == "02-LABORATORIOS" and host_forward:
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
    if rel.parts[0] == "02-LABORATORIOS" and nat_host:
        if not re.search(r"/tmp/[^\s]+host-nat\.added", txt):
            errores.append(f"{rel}: no registra si añadió la regla NAT del host")

# Controles estáticos de seguridad y reversibilidad identificados en la auditoría.
for md in sorted((docs / "02-LABORATORIOS").glob("lab-*/index.md")):
    txt = md.read_text(encoding="utf-8")
    rel = md.relative_to(docs)

    bash_blocks = "\n".join(re.findall(r"^```bash[ \t]*\n(.*?)^```[ \t]*$", txt, re.M | re.S))
    if "StrictHostKeyChecking=no" in bash_blocks or "UserKnownHostsFile=/dev/null" in bash_blocks:
        errores.append(f"{rel}: desactiva la verificación de identidad SSH del servidor")

    if re.search(r"(?m)^\s*(?:sudo )?pkill\s+-f", bash_blocks):
        errores.append(f"{rel}: usa pkill -f; registrar PID y detener procesos propios selectivamente")

    # nf_log_all_netns es global al host: exige copia previa y restauración del mismo archivo.
    if "net.netfilter.nf_log_all_netns=1" in txt:
        if "/tmp/lab08-nf_log_all_netns.orig" not in txt or not re.search(
            r"sysctl -w net\.netfilter\.nf_log_all_netns=\"\$\(cat /tmp/lab08-nf_log_all_netns\.orig\)\"", txt
        ):
            errores.append(f"{rel}: nf_log_all_netns se modifica sin restaurar el valor original")

    # El borrado de OVS debe estar protegido por un marcador creado al crear el bridge.
    if "ovs-vsctl --if-exists del-br ovs-sw" in txt:
        if "ovs-sw.created" not in txt:
            errores.append(f"{rel}: elimina ovs-sw sin verificar propiedad")

    # TCPMSS aplicado al host globalmente es un cambio de firewall peligroso.
    for line in sin_codigo_y_bloques(txt):
        if "iptables -t mangle -A FORWARD" in line and "TCPMSS" in line and "ip netns exec" not in line:
            errores.append(f"{rel}: regla TCPMSS modifica FORWARD del host sin aislamiento")

    # No se permite vaciar indiscriminadamente el estado XFRM del namespace.
    if re.search(r"ip\s+xfrm\s+(?:state|policy)\s+flush", txt):
        errores.append(f"{rel}: vacía XFRM indiscriminadamente; eliminar SA/políticas por selector")

    # Los bridges compartidos del host requieren una comprobación de propiedad por alias.
    if re.search(r"ip link del br-wan", txt) and "ifalias" not in txt:
        errores.append(f"{rel}: elimina br-wan por nombre sin comprobar su propiedad")

# Regresiones concretas de la auditoría por laboratorio.
checks = {
    "lab-02": ["/tmp/lab02-ip_forward.orig", "sysctl -w net.ipv4.ip_forward=\"$(cat /tmp/lab02-ip_forward.orig)\""] ,
    "lab-04": ["veth-v1", "veth-v2", "veth-v3", "veth-v4", "veth-i1", "veth-i2", "veth-i3", "/tmp/lab04-forward-out.added", "/tmp/lab04-forward-in.added", "networking-lab-lab-04"],
    "lab-05": ["/tmp/lab05-forward-out.added", "/tmp/lab05-forward-in.added", "iptables -D FORWARD -i veth-host"],
    "lab-07": ["/tmp/lab07-forward-out.added", "/tmp/lab07-forward-in.added", "networking-lab-lab-07", "ip link del br-lan", "ip addr replace 10.0.0.1/24 dev veth-r1c"],
    "lab-12": ["/tmp/lab12-pids", "echo \"$! 8080\" >> /tmp/lab12-pids", "tr '\\0' ' ' < \"/proc/$pid/cmdline\""],
    "lab-15": ["ovs-sw.created", "/tmp/lab15/tcpmss.added", "/tmp/lab15/r1/zebra.pid", "dnsmasq --conf-file=/tmp/lab15/dns.conf", "dhcp-option=tag:fin,option:dns-server,10.0.1.1", "ip -4 neigh show nud all", "cmdline=$(tr '\\0' ' ' < \"/proc/$pid/cmdline\")", "/tmp/lab15/host-forward-out.added", "networking-lab-lab-15"],
    "lab-08": ["/tmp/lab08-nf_log_all_netns.orig", "/tmp/lab08/R1-default.before", "R1-nat-removed.added", "StrictHostKeyChecking=yes", "subjectAltName=DNS:servidorWeb", "/tmp/lab08-forward-out.added", "/tmp/lab08-forward-in.added", "networking-lab-lab-08"],
    "lab-09": ["ip xfrm state delete", "ip xfrm policy delete", "ip tunnel del", "Noise_IK", "--allow-deprecated-insecure-static-crypto", "fw-dnat.added", "networking-lab-lab-09"],
    "lab-10": ["VETH_WAN_CVPN_OWNED", "networking-lab-lab-09"],
    "lab-11": ["keepalived-dist1.conf", "virtual_router_id 110", "stp_state 1", "/tmp/lab11-forward-out.added", "remote-drop.added"],
    "lab-12": ["PDP (Policy Decision Point)", "PEP (Policy Enforcement Point)", "Device posture", "/tmp/lab12-pids"],
    "lab-13": ["/tmp/lab13-forward-out.added", "/tmp/lab13-forward-in.added", "networking-lab-lab-13", "ping -c 2 -W 1 -M do -s 1472", "Fragmentation Needed", "PIDS_ONPREMISE"],
    "lab-14": ["/tmp/lab14-forward-out.added", "/tmp/lab14-forward-in.added", "networking-lab-lab-14"],
}
for lab, required in checks.items():
    md = docs / "02-LABORATORIOS" / lab / "index.md"
    content = md.read_text(encoding="utf-8")
    # Los enlaces Markdown no deben invalidar una comprobación de contenido:
    # [PDP](URL) se compara como PDP, conservando el texto visible.
    contenido_visible = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", content)
    for token in required:
        if token not in contenido_visible:
            errores.append(f"{md.relative_to(docs)}: falta control de auditoría: {token}")

# Cada namespace nuevo debe llevar una marca en lo para que la limpieza no actúe por nombre solamente.
for n in (1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15):
    md = docs / "02-LABORATORIOS" / f"lab-{n:02d}" / "index.md"
    content = md.read_text(encoding="utf-8")
    if "ip netns add" in content and not re.search(r"ip link set lo alias networking-lab-(?:owned|lab-\d{2})", content):
        errores.append(f"{md.relative_to(docs)}: crea namespaces sin marca de propiedad")

# La navegación debe apuntar a destinos internos existentes (evita enlaces rotos en el menú).
config_path = docs.parent / "zensical.toml"
try:
    config = tomllib.loads(config_path.read_text(encoding="utf-8"))
    nav = config.get("project", {}).get("nav", [])
    def validar_nav(items):
        for item in items:
            for label, target in item.items():
                if isinstance(target, str):
                    if not re.match(r"^(https?:|mailto:)", target) and not (docs / target).is_file():
                        errores.append(f"zensical.toml: destino inexistente en navegación: {label} -> {target}")
                elif isinstance(target, list):
                    validar_nav(target)
    validar_nav(nav)
except (OSError, tomllib.TOMLDecodeError, AttributeError, TypeError) as exc:
    errores.append(f"zensical.toml: no se pudo validar la navegación: {exc}")

# No debe publicarse un registro interno de auditoría no solicitado.
if (docs / "04-REFERENCIA" / "auditoria-atendida.md").exists():
    errores.append("docs/referencia/auditoria-atendida.md: documento interno no solicitado en la documentación pública")
if "auditoria-atendida.md" in (docs.parent / "zensical.toml").read_text(encoding="utf-8"):
    errores.append("zensical.toml: contiene una entrada de navegación al registro interno de auditoría")

# Sintaxis de bloques Bash completos (sin ejecutar comandos ni modificar el sistema).
for md in sorted(docs.rglob("*.md")):
    txt = md.read_text(encoding="utf-8")
    for n, match in enumerate(re.finditer(r"^```bash[ \t]*\n(.*?)^```[ \t]*$", txt, re.M | re.S), 1):
        resultado = subprocess.run(["bash", "-n"], input=match.group(1), text=True,
                                   capture_output=True, check=False)
        if resultado.returncode:
            detalle = resultado.stderr.strip().splitlines()[-1]
            errores.append(f"{md.relative_to(docs)}: sintaxis Bash inválida en bloque {n}: {detalle}")

funcional = pathlib.Path(__file__).with_name("pruebas_funcionales.sh")
if funcional.exists():
    resultado = subprocess.run(["bash", "-n", str(funcional)], text=True, capture_output=True, check=False)
    if resultado.returncode:
        errores.append(f"scripts/{funcional.name}: sintaxis Bash inválida: {resultado.stderr.strip()}")

# --- Coherencia narrativa de los laboratorios -------------------------------------------------
# Todos los laboratorios comparten el mismo arco: contexto -> problema -> objetivos -> topología ->
# ... -> preguntas -> conclusiones -> puente al siguiente. Los contadores de la cabecera se comprueban
# contra el contenido para que no queden desactualizados.
ESENCIALES = ["Contexto empresarial", "Problema inicial", "Objetivos del laboratorio", "Topología",
              "Preguntas de reflexión", "Conclusiones técnicas", "Preparación para el siguiente"]
for md in sorted((docs / "02-LABORATORIOS").glob("lab-*/index.md")):
    txt = md.read_text(encoding="utf-8")
    prosa = re.sub(r"```.*?```", "", txt, flags=re.S)
    titulos = [h.strip() for h in re.findall(r"^## (.+)$", prosa, re.M)]
    for esencial in ESENCIALES:
        if not any(t.startswith(esencial) for t in titulos):
            errores.append(f"{md.relative_to(docs)}: falta la sección narrativa «{esencial}»")
    meta = re.search(r'<p class="tema-meta"><span>(\d+) secciones</span><span>(\d+) diagramas?</span><span>(\d+) tablas?</span></p>', txt)
    if not meta:
        errores.append(f"{md.relative_to(docs)}: falta la cabecera con contadores (tema-meta)")
    else:
        real = (len(titulos), len(re.findall(r"```mermaid", txt)), len(re.findall(r"^\|[ :\-|]+\|\s*$", prosa, re.M)))
        if tuple(map(int, meta.groups())) != real:
            errores.append(f"{md.relative_to(docs)}: contadores de la cabecera {tuple(map(int, meta.groups()))} no coinciden con el contenido {real}")

avisos = []
for css in sorted(docs.rglob("*.css")):
    for ref in re.findall(r"url\(['\"]?([^)'\"]+)", css.read_text(encoding="utf-8")):
        if not existe(css.parent, ref):
            avisos.append(f"{css.relative_to(docs)}: recurso no encontrado {ref}")

for a in avisos:
    print("AVISO:", a)
print("\n".join(errores) or "OK: sin errores")
sys.exit(1 if errores else 0)
