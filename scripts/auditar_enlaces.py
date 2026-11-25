#!/usr/bin/env python3
# Auditor local de enlaces para NETWORKING LAB
# Solo lectura sobre docs. Genera un informe Markdown.

from pathlib import Path
from urllib.parse import urlsplit, unquote
from html.parser import HTMLParser
from collections import Counter
import difflib
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
REPORT = ROOT / "INFORME_AUDITORIA_ENLACES.md"
CONFIG = ROOT / "zensical.toml"

MARKDOWN_EXTENSIONS = {".md", ".markdown"}
SCANNED_EXTENSIONS = MARKDOWN_EXTENSIONS | {".html", ".htm"}


def read_text(path):
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def site_domain():
    if not CONFIG.exists():
        return ""
    text = read_text(CONFIG)
    match = re.search(
        r'(?m)^\s*site_url\s*=\s*["\']([^"\']+)["\']',
        text
    )
    if not match:
        return ""
    return (urlsplit(match.group(1)).hostname or "").lower()


SITE_DOMAIN = site_domain()


def strip_code_blocks(text):
    return re.sub(
        r"(?ms)^[ \t]*(```|~~~).*?^[ \t]*\1[ \t]*$",
        lambda m: "\n" * m.group(0).count("\n"),
        text
    )


def clean_markdown(text):
    text = strip_code_blocks(text)
    return re.sub(r"`+[^`\n]*`+", "", text)


class LinkHTMLParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for attr in ("href", "src"):
            value = attrs.get(attr)
            if value:
                self.links.append(
                    (value.strip(), self.getpos()[0], f"HTML {tag}[{attr}]")
                )

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)


def extract_links(text):
    found = []
    text = clean_markdown(text)

    md_pattern = re.compile(
        r"!?\[[^\]]*\]\(\s*(?:<([^>]+)>|([^\s)]+))"
    )

    for match in md_pattern.finditer(text):
        target = match.group(1) or match.group(2)
        line = text.count("\n", 0, match.start()) + 1
        found.append((target, line, "Markdown"))

    ref_pattern = re.compile(
        r"(?m)^[ \t]{0,3}\[[^\]]+\]:[ \t]*<?([^\s>]+)"
    )

    for match in ref_pattern.finditer(text):
        line = text.count("\n", 0, match.start()) + 1
        found.append((match.group(1), line, "Referencia Markdown"))

    parser = LinkHTMLParser()
    try:
        parser.feed(text)
        found.extend(parser.links)
    except Exception:
        pass

    return found


def heading_anchors(text):
    """
    Devuelve:
      - conjunto de anclas válidas encontradas;
      - lista de identificadores duplicados.

    Reconoce:
      - IDs explícitos de attr_list: { #identificador }
      - IDs HTML: id="identificador"
      - encabezados Markdown ATX con slug automático.
    """
    anchors = set()
    duplicates = []
    seen = {}

    def register(anchor, line, origin):
        anchor = unquote(anchor).strip()
        if not anchor:
            return

        if anchor in seen:
            duplicates.append({
                "id": anchor,
                "line": line,
                "first_line": seen[anchor]["line"],
                "origin": origin,
            })
        else:
            seen[anchor] = {
                "line": line,
                "origin": origin,
            }

        anchors.add(anchor)

    lines = text.splitlines()
    counts = Counter()

    # IDs explícitos de encabezados y atributos HTML.
    for number, line in enumerate(lines, start=1):
        heading = re.match(
            r"^[ \t]{0,3}#{1,6}[ \t]+(.+?)\s*#*\s*$",
            line
        )

        explicit_ids = []

        if heading:
            # Sintaxis de Python-Markdown attr_list:
            # ## Título { #mi-id }
            attr_blocks = re.findall(r"\{([^{}]*)\}", heading.group(1))

            for block in attr_blocks:
                explicit_ids.extend(
                    re.findall(
                        r"(?:^|\s)#([A-Za-z0-9_.:-]+)(?=\s|$)",
                        block
                    )
                )

        for anchor in explicit_ids:
            register(anchor, number, "attr_list")

        # IDs HTML explícitos.
        for match in re.finditer(
            r'\bid\s*=\s*["\']([^"\']+)["\']',
            line,
            re.I
        ):
            register(match.group(1), number, "HTML")

        if not heading:
            continue

        title = heading.group(1)

        # Elimina los atributos { #id } antes de calcular el slug.
        title = re.sub(r"\{[^{}]*\}", "", title).strip()

        # Si el encabezado tiene ID explícito, ese es su identificador.
        # No se inventa otro slug para el mismo encabezado.
        if explicit_ids:
            continue

        title = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", title)
        title = re.sub(r"[`*_~]", "", title)
        title = title.strip().lower()

        slug = re.sub(r"[^\w\- ]", "", title, flags=re.UNICODE)
        slug = re.sub(r"\s+", "-", slug.strip())

        base = slug
        number_used = counts[base]
        counts[base] += 1

        if number_used:
            slug = f"{base}-{number_used}"

        register(slug, number, "slug Markdown")

    return anchors, duplicates


def relative_to_docs(path):
    try:
        return path.relative_to(DOCS).as_posix()
    except ValueError:
        return str(path)


def case_mismatch(candidate):
    try:
        rel = candidate.relative_to(DOCS)
    except ValueError:
        return None

    current = DOCS
    for part in rel.parts:
        if not current.is_dir():
            return None

        names = [p.name for p in current.iterdir()]
        exact = next(
            (name for name in names if name.lower() == part.lower()),
            None
        )

        if exact is None:
            return None

        current = current / exact

    return current if current.exists() else None


def candidate_paths(source, raw_path):
    raw_path = unquote(raw_path).replace("\\", "/")

    if raw_path.startswith("/"):
        base = DOCS / raw_path.lstrip("/")
    else:
        base = source.parent / raw_path

    options = [base]
    suffix = base.suffix.lower()

    if suffix == ".html":
        options.extend([
            base.with_suffix(".md"),
            base.with_suffix(".markdown"),
        ])
    elif suffix == "":
        options.extend([
            Path(str(base) + ".md"),
            Path(str(base) + ".markdown"),
            base / "index.md",
            base / "index.markdown",
            base / "index.html",
        ])
    elif suffix == ".md":
        options.append(base.with_suffix(".markdown"))

    unique = []
    seen = set()

    for item in options:
        if item not in seen:
            seen.add(item)
            unique.append(item)

    return unique


def resolve_target(source, raw_url):
    raw_url = raw_url.strip()

    if not raw_url:
        return ("IGNORADO", None, "Destino vacío")

    parts = urlsplit(raw_url)
    scheme = parts.scheme.lower()
    host = (parts.hostname or "").lower()

    if scheme in {"mailto", "tel", "javascript", "data"}:
        return (
            "EXTERNO/ESPECIAL",
            None,
            "No es un enlace a una página local"
        )

    if scheme in {"http", "https"}:
        if SITE_DOMAIN and host == SITE_DOMAIN:
            raw_path = unquote(parts.path) or "/"
        else:
            return (
                "EXTERNO",
                None,
                "No se comprueba conexión externa"
            )
    elif scheme:
        return ("EXTERNO/ESPECIAL", None, f"Esquema {scheme}")
    else:
        raw_path = unquote(parts.path)

    candidates = (
        [source] if not raw_path
        else candidate_paths(source, raw_path)
    )

    for candidate in candidates:
        try:
            resolved = candidate.resolve()
            docs_resolved = DOCS.resolve()

            if (
                resolved != docs_resolved
                and docs_resolved not in resolved.parents
            ):
                continue
        except OSError:
            continue

        if resolved.exists() and resolved.is_file():
            return ("OK", resolved, "")

        if resolved.exists() and resolved.is_dir():
            for index_name in ("index.md", "index.html"):
                index = resolved / index_name
                if index.exists():
                    return ("OK", index.resolve(), "")

    for candidate in candidates:
        corrected = case_mismatch(candidate)
        if corrected:
            return (
                "MAYUSCULAS",
                corrected.resolve(),
                "Posible diferencia de mayúsculas/minúsculas: "
                + relative_to_docs(corrected)
            )

    target_name = Path(raw_path).name
    all_files = [
        p for p in DOCS.rglob("*")
        if p.is_file()
        and p.suffix.lower() in SCANNED_EXTENSIONS
    ]

    names = [p.name for p in all_files]
    suggestions = difflib.get_close_matches(
        target_name, names, n=3, cutoff=0.55
    )

    suggestion_text = ""
    if suggestions:
        matches = []
        for name in suggestions:
            matches.extend(
                relative_to_docs(p)
                for p in all_files
                if p.name == name
            )
        suggestion_text = (
            " Posibles destinos: " + ", ".join(matches[:3])
        )

    return (
        "ROTO",
        None,
        "No se encontró el destino." + suggestion_text
    )


def check_fragment(target, fragment):
    if not fragment:
        return ("OK", "")

    if target.suffix.lower() not in MARKDOWN_EXTENSIONS:
        return (
            "NO_VERIFICABLE",
            "Destino no Markdown; ancla no comprobada"
        )

    anchors, _ = heading_anchors(read_text(target))
    fragment = unquote(fragment).lstrip("#")

    if fragment in anchors:
        return ("OK", "")

    return (
        "ANCLA_ROTA",
        f"No se encontró el ancla #{fragment} en el destino"
    )


def main():
    if not DOCS.is_dir():
        print(f"ERROR: No existe el directorio {DOCS}")
        sys.exit(2)

    files = sorted(
        p for p in DOCS.rglob("*")
        if p.is_file()
        and p.suffix.lower() in SCANNED_EXTENSIONS
    )

    results = []
    duplicate_results = []
    total_links = 0
    counts = Counter()

    # Analizar archivos y construir inventario de anclas.
    for source in files:
        text = read_text(source)

        if source.suffix.lower() in MARKDOWN_EXTENSIONS:
            _, duplicates = heading_anchors(text)

            for duplicate in duplicates:
                duplicate_results.append({
                    "source": relative_to_docs(source),
                    **duplicate,
                })

        for raw_url, line, kind in extract_links(text):
            total_links += 1
            status, target, detail = resolve_target(source, raw_url)

            fragment = urlsplit(raw_url).fragment

            if status == "OK" and fragment:
                fragment_status, fragment_detail = check_fragment(
                    target, fragment
                )

                if fragment_status == "ANCLA_ROTA":
                    status = fragment_status
                    detail = fragment_detail
                elif fragment_status == "NO_VERIFICABLE":
                    detail = fragment_detail

            counts[status] += 1

            results.append({
                "status": status,
                "source": relative_to_docs(source),
                "line": line,
                "kind": kind,
                "url": raw_url,
                "target": relative_to_docs(target) if target else "",
                "detail": detail,
            })

    errors = {"ROTO", "ANCLA_ROTA", "MAYUSCULAS"}
    problem_count = sum(counts[x] for x in errors)

    lines = [
        "# Informe de auditoría automática de enlaces",
        "",
        f"- Proyecto: `{ROOT}`",
        f"- Directorio inspeccionado: `{DOCS}`",
        f"- Archivos examinados: **{len(files)}**",
        f"- Enlaces detectados: **{total_links}**",
        f"- Dominio interno detectado en configuración: "
        f"`{SITE_DOMAIN or 'No definido'}`",
        "- Modo: **solo lectura; no se modificaron archivos fuente**",
        "",
        "## Resumen",
        "",
        "| Resultado | Cantidad |",
        "|---|---:|",
    ]

    for status in [
        "OK", "ROTO", "ANCLA_ROTA", "MAYUSCULAS",
        "EXTERNO", "EXTERNO/ESPECIAL", "NO_VERIFICABLE", "IGNORADO"
    ]:
        lines.append(f"| {status} | {counts[status]} |")

    lines += [
        "",
        f"**Problemas de enlaces: {problem_count}**",
        f"**Identificadores duplicados: {len(duplicate_results)}**",
        "",
        "## Incidencias de enlaces",
        "",
    ]

    problem_results = [
        r for r in results if r["status"] in errors
    ]

    if not problem_results:
        lines.append(
            "No se detectaron enlaces rotos, anclas inexistentes "
            "ni diferencias de mayúsculas/minúsculas."
        )
    else:
        for r in problem_results:
            lines += [
                f"### {r['status']} — `{r['source']}:{r['line']}`",
                f"- Tipo: {r['kind']}",
                f"- Enlace: `{r['url']}`",
                f"- Destino encontrado: `{r['target'] or 'Ninguno'}`",
                f"- Detalle: {r['detail']}",
                "",
            ]

    lines += [
        "## Identificadores duplicados",
        "",
        "Un identificador duplicado puede hacer que un enlace "
        "salte a una sección equivocada.",
        "",
    ]

    if not duplicate_results:
        lines.append("No se detectaron identificadores duplicados.")
    else:
        for item in duplicate_results:
            lines += [
                f"- `{item['source']}:{item['line']}` — "
                f"`{item['id']}`; primera aparición en línea "
                f"{item['first_line']}; origen: {item['origin']}"
            ]

    lines += [
        "",
        "## Enlaces externos y no verificables",
        "",
        "Estos destinos no se han probado por Internet.",
        "",
    ]

    external_results = [
        r for r in results
        if r["status"] in {
            "EXTERNO", "EXTERNO/ESPECIAL", "NO_VERIFICABLE"
        }
    ]

    if not external_results:
        lines.append("No se detectaron enlaces externos.")
    else:
        for r in external_results:
            lines.append(
                f"- `{r['source']}:{r['line']}` — "
                f"`{r['url']}` ({r['status']})"
            )

    lines += [
        "",
        "## Inventario de enlaces locales",
        "",
        "| Estado | Archivo y línea | Enlace | Destino resuelto |",
        "|---|---|---|---|",
    ]

    for r in results:
        if r["status"] in {
            "OK", "ROTO", "ANCLA_ROTA", "MAYUSCULAS"
        }:
            url = r["url"].replace("|", "\\|")
            lines.append(
                f"| {r['status']} | `{r['source']}:{r['line']}` "
                f"| `{url}` | `{r['target']}` |"
            )

    lines += [
        "",
        "## Interpretación",
        "",
        "- `ROTO`: no se encontró el archivo de destino.",
        "- `ANCLA_ROTA`: no se encontró el fragmento indicado.",
        "- `MAYUSCULAS`: posible diferencia de mayúsculas/minúsculas.",
        "- `OK`: el destino local existe y el ancla, si existe, fue validada.",
        "- `EXTERNO`: enlace externo no comprobado.",
        "- `NO_VERIFICABLE`: no se pudo comprobar el fragmento.",
        "- Identificador duplicado: dos elementos declaran el mismo ID.",
        "",
        "## Limitaciones",
        "",
        "- La auditoría se realiza sobre los archivos fuente.",
        "- No comprueba enlaces externos ni el estado de GitHub Pages.",
        "- Los slugs automáticos pueden variar según extensiones del generador.",
        "- Los enlaces construidos dinámicamente por JavaScript no se detectan.",
        "- No sustituye una comprobación del sitio compilado.",
        "",
    ]

    REPORT.write_text("\n".join(lines), encoding="utf-8")

    print("=" * 58)
    print(" NETWORKING LAB | AUDITORÍA DE ENLACES")
    print("=" * 58)
    print(f"Proyecto:                  {ROOT}")
    print(f"Archivos examinados:       {len(files)}")
    print(f"Enlaces detectados:        {total_links}")
    print(f"Enlaces correctos:         {counts['OK']}")
    print(f"Enlaces rotos:             {counts['ROTO']}")
    print(f"Anclas rotas:              {counts['ANCLA_ROTA']}")
    print(f"Diferencias de caso:       {counts['MAYUSCULAS']}")
    print(f"Identificadores duplicados:{len(duplicate_results):>5}")
    print(f"Externos:                  "
          f"{counts['EXTERNO'] + counts['EXTERNO/ESPECIAL']}")
    print("-" * 58)
    print(f"Problemas de enlaces:      {problem_count}")
    print(f"INFORME:                   {REPORT}")
    print("=" * 58)

    if problem_count or duplicate_results:
        print("RESULTADO: se encontraron incidencias para revisar.")
    else:
        print("RESULTADO: no se detectaron problemas locales.")


if __name__ == "__main__":
    main()
