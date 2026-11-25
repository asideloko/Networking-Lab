#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Instala tipografías locales en Networking-Lab (Zensical).
- Bai Jamjuree: texto general.
- Chakra Petch: encabezados, negritas y destacados.
- TeX Gyre Cursor: código.
Crea copias de seguridad antes de sobrescribir archivos.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import tomllib
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent

SOURCE = (
    Path.home()
    / "storage"
    / "documents"
    / "Markdown-Temas"
    / "fonts"
)

DEST_FONTS = ROOT / "docs" / "fonts"
CSS_PATH = ROOT / "docs" / "stylesheets" / "tipografia-local.css"
CONFIG_PATH = ROOT / "zensical.toml"

FONT_FILES = {
    "Bai-Jamjure": [
        "BaiJamjuree-ExtraLight.ttf",
        "BaiJamjuree-ExtraLightItalic.ttf",
        "BaiJamjuree-Light.ttf",
        "BaiJamjuree-LightItalic.ttf",
        "BaiJamjuree-Regular.ttf",
        "BaiJamjuree-Italic.ttf",
        "BaiJamjuree-Medium.ttf",
        "BaiJamjuree-MediumItalic.ttf",
        "BaiJamjuree-SemiBold.ttf",
        "BaiJamjuree-SemiBoldItalic.ttf",
        "BaiJamjuree-Bold.ttf",
        "BaiJamjuree-BoldItalic.ttf",
    ],
    "Chakra-Petch": [
        "ChakraPetch-Light.ttf",
        "ChakraPetch-LightItalic.ttf",
        "ChakraPetch-Regular.ttf",
        "ChakraPetch-Italic.ttf",
        "ChakraPetch-Medium.ttf",
        "ChakraPetch-MediumItalic.ttf",
        "ChakraPetch-SemiBold.ttf",
        "ChakraPetch-SemiBoldItalic.ttf",
        "ChakraPetch-Bold.ttf",
        "ChakraPetch-BoldItalic.ttf",
    ],
    "TexGyre-Cursor": [
        "texgyrecursor-regular.otf",
        "texgyrecursor-italic.otf",
        "texgyrecursor-bold.otf",
        "texgyrecursor-bolditalic.otf",
    ],
}

CSS_RELATIVE = "stylesheets/tipografia-local.css"


def detener(mensaje: str) -> None:
    print(f"\nERROR: {mensaje}", file=sys.stderr)
    raise SystemExit(1)


def validar_origen() -> list[Path]:
    if not SOURCE.is_dir():
        detener(f"No existe el directorio de fuentes:\n{SOURCE}")

    archivos = []

    for carpeta, nombres in FONT_FILES.items():
        directorio = SOURCE / carpeta

        if not directorio.is_dir():
            detener(f"No existe la carpeta de fuentes:\n{directorio}")

        for nombre in nombres:
            archivo = directorio / nombre

            if not archivo.is_file():
                detener(f"Falta una fuente requerida:\n{archivo}")

            archivos.append(archivo)

    if not CONFIG_PATH.is_file():
        detener(f"No se encuentra la configuración:\n{CONFIG_PATH}")

    return archivos


def generar_css() -> str:
    declaraciones = []

    bai = [
        ("ExtraLight", 200, False),
        ("ExtraLightItalic", 200, True),
        ("Light", 300, False),
        ("LightItalic", 300, True),
        ("Regular", 400, False),
        ("Italic", 400, True),
        ("Medium", 500, False),
        ("MediumItalic", 500, True),
        ("SemiBold", 600, False),
        ("SemiBoldItalic", 600, True),
        ("Bold", 700, False),
        ("BoldItalic", 700, True),
    ]

    chakra = [
        ("Light", 300, False),
        ("LightItalic", 300, True),
        ("Regular", 400, False),
        ("Italic", 400, True),
        ("Medium", 500, False),
        ("MediumItalic", 500, True),
        ("SemiBold", 600, False),
        ("SemiBoldItalic", 600, True),
        ("Bold", 700, False),
        ("BoldItalic", 700, True),
    ]

    cursor = [
        ("regular", 400, False),
        ("italic", 400, True),
        ("bold", 700, False),
        ("bolditalic", 700, True),
    ]

    def agregar(familia, carpeta, variantes, prefijo, extension):
        for nombre, peso, cursiva in variantes:
            archivo = f"{prefijo}{nombre}.{extension}"
            estilo = "italic" if cursiva else "normal"
            formato = "opentype" if extension == "otf" else "truetype"

            declaraciones.append(
                f"""@font-face {{
  font-family: "{familia}";
  src: url("../fonts/{carpeta}/{archivo}") format("{formato}");
  font-style: {estilo};
  font-weight: {peso};
  font-display: swap;
}}"""
            )

    agregar(
        "Bai Jamjuree",
        "Bai-Jamjure",
        bai,
        "BaiJamjuree-",
        "ttf",
    )
    agregar(
        "Chakra Petch",
        "Chakra-Petch",
        chakra,
        "ChakraPetch-",
        "ttf",
    )
    agregar(
        "TeX Gyre Cursor",
        "TexGyre-Cursor",
        cursor,
        "texgyrecursor-",
        "otf",
    )

    encabezado = """/*
 * Networking-Lab | Tipografía local
 * Texto: Bai Jamjuree
 * Encabezados y destacados: Chakra Petch
 * Código: TeX Gyre Cursor
 */

"""

    reglas = r"""
:root {
  --md-text-font: "Bai Jamjuree";
  --md-code-font: "TeX Gyre Cursor";
  font-synthesis: none;
}

/* Texto general */
html,
body,
.md-typeset,
.md-nav,
.md-header,
.md-tabs,
.md-search,
.md-footer {
  font-family: "Bai Jamjuree", sans-serif;
}

/* Encabezados */
h1, h2, h3, h4, h5, h6,
.md-typeset h1,
.md-typeset h2,
.md-typeset h3,
.md-typeset h4,
.md-typeset h5,
.md-typeset h6 {
  font-family: "Chakra Petch", sans-serif;
}

/* Negritas y destacados */
strong,
b,
.md-typeset strong,
.md-typeset b,
.md-typeset .admonition-title,
.md-typeset summary,
.md-typeset .tabbed-labels > label {
  font-family: "Chakra Petch", sans-serif;
}

/* Código, terminal y fragmentos */
code,
pre,
kbd,
samp,
.md-typeset code,
.md-typeset pre,
.highlight,
.highlight code,
.highlight pre,
.md-clipboard,
.md-typeset .highlighttable {
  font-family: "TeX Gyre Cursor", monospace;
}

/* Mantener el código legible sin alterar su peso */
.md-typeset code,
.md-typeset pre {
  font-synthesis: none;
}

/* Controles y elementos de navegación */
button,
input,
select,
textarea {
  font-family: "Bai Jamjuree", sans-serif;
}
"""

    return encabezado + "\n\n".join(declaraciones) + "\n" + reglas.strip() + "\n"


def obtener_seccion(texto: str, nombre: str):
    patron = re.compile(
        rf"(?m)^\[{re.escape(nombre)}\][ \t]*$"
    )
    coincidencia = patron.search(texto)

    if not coincidencia:
        return None

    siguiente = re.search(
        r"(?m)^\[[^\]]+\][ \t]*$",
        texto[coincidencia.end():],
    )

    fin = (
        coincidencia.end() + siguiente.start()
        if siguiente
        else len(texto)
    )

    return coincidencia.start(), coincidencia.end(), fin


def actualizar_seccion(
    texto: str,
    nombre: str,
    clave: str,
    valor: str,
) -> str:
    seccion = obtener_seccion(texto, nombre)

    if seccion is None:
        return texto.rstrip() + f"\n\n[{nombre}]\n{clave} = {valor}\n"

    inicio, cabecera_fin, fin = seccion
    bloque = texto[inicio:fin]

    patron = re.compile(
        rf"(?m)^{re.escape(clave)}[ \t]*=.*(?:\n[ \t]+.*)*"
    )

    if patron.search(bloque):
        bloque = patron.sub(
            f"{clave} = {valor}",
            bloque,
            count=1,
        )
    else:
        bloque = bloque.rstrip() + f"\n{clave} = {valor}\n"

    return texto[:inicio] + bloque + texto[fin:]


def actualizar_configuracion(texto: str) -> str:
    try:
        actual = tomllib.loads(texto)
    except tomllib.TOMLDecodeError as exc:
        detener(f"zensical.toml tiene errores antes de modificarlo:\n{exc}")

    proyecto = actual.get("project", {})
    extra_css = proyecto.get("extra_css", [])

    if isinstance(extra_css, str):
        extra_css = [extra_css]

    if not isinstance(extra_css, list):
        detener("La propiedad project.extra_css no es una lista.")

    extra_css = list(extra_css)

    if CSS_RELATIVE not in extra_css:
        extra_css.append(CSS_RELATIVE)

    valor_css = "[" + ", ".join(
        repr(item) for item in extra_css
    ) + "]"

    texto = actualizar_seccion(
        texto,
        "project",
        "extra_css",
        valor_css,
    )

    # Desactiva la descarga automática de Google Fonts.
    texto = actualizar_seccion(
        texto,
        "project.theme",
        "font",
        "false",
    )

    try:
        tomllib.loads(texto)
    except tomllib.TOMLDecodeError as exc:
        detener(f"La configuración resultante no es TOML válido:\n{exc}")

    return texto


def guardar_respaldo(rutas: list[Path]) -> Path:
    marca = datetime.now().strftime("%Y%m%d_%H%M%S")
    carpeta = ROOT / "backups" / f"tipografias_{marca}"
    carpeta.mkdir(parents=True, exist_ok=True)

    for original in rutas:
        if original.exists():
            relativo = original.relative_to(ROOT)
            destino = carpeta / relativo
            destino.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(original, destino)

    return carpeta


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Instala las tipografías locales de Networking-Lab."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Comprueba las fuentes y muestra cambios sin aplicarlos.",
    )
    args = parser.parse_args()

    print("=" * 58)
    print(" NETWORKING-LAB | INSTALACIÓN DE TIPOGRAFÍAS")
    print("=" * 58)
    print(f"Origen:  {SOURCE}")
    print(f"Destino: {ROOT}")

    fuentes = validar_origen()
    css = generar_css()

    config_original = CONFIG_PATH.read_text(encoding="utf-8")
    config_nueva = actualizar_configuracion(config_original)

    # Comprueba que las rutas referenciadas por el CSS coincidan
    # con los archivos que se instalarán.
    for fuente in fuentes:
        relativo = Path("..") / "fonts" / fuente.parent.name / fuente.name
        destino = CSS_PATH.parent / relativo
        esperado = DEST_FONTS / fuente.parent.name / fuente.name

        if destino.resolve() != esperado.resolve():
            detener(f"Ruta de fuente inconsistente: {fuente.name}")

    archivos_destino = [
        DEST_FONTS / carpeta / nombre
        for carpeta, nombres in FONT_FILES.items()
        for nombre in nombres
    ]

    licencias = []
    for carpeta in FONT_FILES:
        licencia = SOURCE / carpeta / "OFL.txt"
        if licencia.is_file():
            licencias.append(licencia)

    if args.dry_run:
        print("\nMODO DE SIMULACIÓN: no se modificó ningún archivo.")
        print(f"Fuentes que se copiarían: {len(fuentes)}")
        print(f"Licencias OFL encontradas: {len(licencias)}")
        print(f"CSS: {CSS_PATH}")
        print(f"Configuración: {CONFIG_PATH}")
        print("Se registraría extra_css y font = false.")
        return

    # Respaldar todos los archivos que podrían sobrescribirse.
    candidatos = [
        CONFIG_PATH,
        CSS_PATH,
        *archivos_destino,
    ]

    for carpeta in FONT_FILES:
        destino_licencia = DEST_FONTS / carpeta / "OFL.txt"
        candidatos.append(destino_licencia)

    existentes = [ruta for ruta in candidatos if ruta.exists()]
    respaldo = guardar_respaldo(existentes)

    print(f"\nRespaldo creado en: {respaldo}")

    # Instalar fuentes y licencias.
    total = 0

    for carpeta, nombres in FONT_FILES.items():
        origen = SOURCE / carpeta
        destino = DEST_FONTS / carpeta
        destino.mkdir(parents=True, exist_ok=True)

        for nombre in nombres:
            shutil.copy2(origen / nombre, destino / nombre)
            total += 1

        licencia = origen / "OFL.txt"
        if licencia.is_file():
            shutil.copy2(licencia, destino / "OFL.txt")

    # Instalar CSS.
    CSS_PATH.parent.mkdir(parents=True, exist_ok=True)
    CSS_PATH.write_text(css, encoding="utf-8")

    # Actualizar configuración.
    CONFIG_PATH.write_text(config_nueva, encoding="utf-8")

    # Verificación posterior.
    try:
        configuracion = tomllib.loads(
            CONFIG_PATH.read_text(encoding="utf-8")
        )
    except tomllib.TOMLDecodeError as exc:
        detener(
            "La configuración falló en la comprobación posterior. "
            f"El respaldo está en {respaldo}\n{exc}"
        )

    if CSS_RELATIVE not in configuracion.get("project", {}).get("extra_css", []):
        detener(f"No se registró correctamente el CSS. Respaldo: {respaldo}")

    if configuracion.get("project", {}).get("theme", {}).get("font") is not False:
        detener(f"No se desactivó la fuente remota. Respaldo: {respaldo}")

    faltantes = [
        ruta for ruta in archivos_destino
        if not ruta.is_file()
    ]

    if faltantes:
        detener(
            "Faltan archivos después de copiar:\n"
            + "\n".join(str(ruta) for ruta in faltantes)
            + f"\nRespaldo: {respaldo}"
        )

    print("\nINSTALACIÓN COMPLETADA")
    print(f"Fuentes instaladas: {total}")
    print(f"Licencias OFL copiadas: {len(licencias)}")
    print(f"CSS instalado: {CSS_PATH.relative_to(ROOT)}")
    print("Google Fonts: desactivado")
    print("Configuración TOML: válida")
    print(f"Respaldo: {respaldo}")


if __name__ == "__main__":
    main()
