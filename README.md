# SecOpsDev - Laboratorios de Networking y Seguridad

Este repositorio contiene una plataforma de laboratorios de redes y seguridad en formato HTML estatico. Los 15 laboratorios incluyen diagramas, comandos Linux y notas profesionales.

## Como usar los laboratorios

No necesita instalar nada. Solo debe abrir el archivo `website/index.html` en su navegador.

### Ver localmente (metodo recomendado)

```bash
cd SecOpsDev-Core/website
python3 -m http.server 8000
```
Luego abre http://localhost:8000 en tu navegador.

### Ver directamente (puede fallar en algunos navegadores por CORS)

Haz doble clic en `website/index.html` o abrelo con tu navegador.

## Despliegue en hosting estatico

### GitHub Pages

1. Sube todo el contenido de la carpeta `website` a la raiz de un repositorio GitHub.
2. En Ajustes del repositorio, activa GitHub Pages (rama main, carpeta /root).
3. El sitio estara disponible en `https://tusuario.github.io/repositorio`.

### Netlify

Arrastra la carpeta `website` a netlify.com (drop area) y obtendras una URL publica.

## Contenido

- 15 laboratorios progresivos desde fundamentos de redes hasta implementacion empresarial.
- Diagramas Mermaid interactivos.
- Comandos para Linux (Ubuntu/Debian) con notas para Windows y Cisco.

## Requisitos

Navegador web moderno. No se necesita MkDocs ni servidor web (aunque se recomienda usar el servidor HTTP de Python para mejor experiencia).
# Networking-Lab
# Networking-Lab
