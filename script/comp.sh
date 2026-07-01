#!/bin/bash
# compile_and_test.sh – Compila el sitio y lo sirve localmente para pruebas

set -e

PROJECT_DIR="$(pwd)"

if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml. Asegúrate de ejecutar este script desde la raíz del proyecto."
    exit 1
fi

echo "📦 Instalando dependencias..."
pip install --quiet mkdocs mkdocs-material pymdown-extensions markdown

echo "🔨 Compilando el sitio..."
mkdocs build --clean

echo "✅ Compilación exitosa!"
echo ""
echo "🚀 Sirviendo el sitio en http://127.0.0.1:8000"
echo "📝 Presiona Ctrl+C para detener el servidor"
echo ""
echo "📋 Laboratorios disponibles:"
echo "  - 01: Fundamentos de Redes y Encapsulación"
echo "  - 02: Transmisión de Datos y Capa Física"
echo "  - 03: Componentes de Red y Conmutación"
echo "  - 04: Direccionamiento IP y Subredes"
echo "  - 05: Conmutación y VLANs"
echo ""

mkdocs serve --dev-addr=127.0.0.1:8000
