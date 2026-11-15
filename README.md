
# NETWORKING-LAB

## Laboratorios prácticos de redes

**Del fundamento teórico a la implementación práctica.**

*NETWORKING-Lab* es el entorno de laboratorios prácticos que complementa el libro *NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico*, de Guillermo Castillo (SecOpsMX, 2026).

El libro aborda los fundamentos, protocolos, arquitecturas y tecnologías que hacen posible la comunicación entre sistemas y redes. Este laboratorio amplía ese recorrido mediante ejercicios que permiten explorar, configurar, implementar y verificar los conceptos estudiados.

Los laboratorios presentan escenarios ilustrativos de red, topologías, direccionamiento y configuración de tecnologías, además de actividades para comprobar resultados y relacionar los principios técnicos con su aplicación práctica.

## Acceder a los laboratorios

**[Abrir NETWORKING-Lab](https://asideloko.github.io/Networking-Lab/)**

## Áreas de práctica

Los laboratorios abarcan distintas áreas del networking, entre ellas:

- Fundamentos de redes y modelos de comunicación.
- Direccionamiento IPv4 e IPv6.
- Switching, VLAN y routing.
- Protocolos y servicios de red.
- Seguridad, VPN y arquitecturas modernas.
- Monitorización, diagnóstico y resolución de problemas.
- Implementación y verificación de escenarios de red.

El sitio utiliza [Zensical](https://zensical.org/) para generar y presentar la documentación, con el mismo diseño que el sitio del libro.

# Obtener el Libro 
https://leanpub.com/networking-fundamentos

# Obtener el Libro 
https://leanpub.com/networking-fundamentos

## Licencia y uso

Consulta los archivos y avisos de licencia de este repositorio para conocer las condiciones aplicables al uso y la distribución de los materiales.

## Obra de referencia

**NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico**

**Autor:** Guillermo Castillo · SecOpsMX  
**Edición:** 2026

## Estructura del proyecto

- `zensical.toml` — configuración (navegación, tema claro/oscuro, extensiones, Mermaid). `use_directory_urls = false`: el sitio se publica como archivos `.html`. No definir `site_url` con ruta: el servidor local redirigiría «/» a esa ruta.
- `docs/index.md` — portada (hero, método, lectura de salidas, requisitos y tarjetas de los 15 laboratorios).
- `docs/labs/lab-01 … lab-15/index.md` — los 15 laboratorios (rutas idénticas a las del sitio anterior).
- `docs/stylesheets/extra.css`, `docs/javascripts/custom.js` — diseño del libro + estilos de laboratorios; `custom.js` dibuja los diagramas Mermaid y los redibuja al cambiar entre tema claro y oscuro.
- `docs/javascripts/mermaid.min.js` — Mermaid en local (el sitio funciona sin conexión).
- `overrides/` — `main.html` (aviso superior) y `partials/header.html` (el título de la cabecera enlaza al inicio).
- `.github/workflows/docs.yml` — publicación en GitHub Pages.

## Uso

```bash
pip install -r requirements.txt
zensical serve      # vista previa en http://localhost:8000
zensical build      # genera site/
```

## Notas

- El texto de los 15 laboratorios y de la portada se conserva idéntico; solo cambia la presentación (antetítulo, etiquetas de resumen, tarjetas).
- No activar `minify_html` en `zensical.toml`: colapsa los saltos de línea del código fuente de los diagramas Mermaid y los rompe.
- No activar el plugin `macros`: los comandos de ejemplo pueden contener llaves `{{ }}`.
- No usar `navigation.indexes`: todas las páginas se llaman `index.md` y Zensical tomaría la primera de cada grupo como índice de la sección, ocultándola del menú.
