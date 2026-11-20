# NETWORKING LAB

**Documentación técnica de redes | SecOpsMX**

> Fundamentos, arquitecturas, servicios, seguridad y operación de redes mediante escenarios reproducibles.

**🌐 [Acceder a NETWORKING Lab](https://asideloko.github.io/Networking-Lab/) · 💻 [Código fuente](https://github.com/asideloko/Networking-Lab)**

---


**NETWORKING Lab** es una documentación técnica complementaria el libro **NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico**, de **Guillermo Castillo (SecOpsMX)**.

El sitio reúne escenarios reproducibles, topologías, configuraciones, comandos y resultados técnicos para documentar el funcionamiento de protocolos, tecnologías, arquitecturas y servicios de red.

A través de **15 laboratorios**, se presentan topologías, esquemas de comunicación, direccionamiento, configuraciones ilustrativas, comandos y resultados que permiten relacionar los fundamentos teóricos con su representación técnica.

El objetivo es comprender cómo funcionan las redes, cómo interactúan sus componentes y qué sucede durante los diferentes procesos de comunicación.

---

## Contenido

El contenido está organizado en **15 laboratorios**, una sección de referencia técnica y anexos.

### Laboratorios 01–05 · Fundamentos e infraestructura

| N.º | Laboratorio |
|---:|---|
| 01 | Fundamentos de Redes y Encapsulación |
| 02 | Transmisión de Datos y Capa Física |
| 03 | Componentes de Red y Conmutación |
| 04 | Direccionamiento IP y Subredes |
| 05 | Conmutación y Segmentación de Red |

### Laboratorios 06–10 · Conectividad y servicios

| N.º | Laboratorio |
|---:|---|
| 06 | Enrutamiento y Conectividad entre Redes |
| 07 | Protocolos y Servicios de Red |
| 08 | Seguridad en Redes |
| 09 | VPN y Tunelización |
| 10 | Infraestructura WAN y Core |

### Laboratorios 11–15 · Arquitecturas y operación

| N.º | Laboratorio |
|---:|---|
| 11 | Arquitectura de Red Empresarial |
| 12 | Arquitecturas Modernas de Red |
| 13 | Monitoreo y Diagnóstico de Redes |
| 14 | Herramientas Linux Avanzadas |
| 15 | Implementación Práctica Integral |

---

## Metodología de aprendizaje

Cada laboratorio desarrolla un recorrido técnico que incluye:

1. Fundamentos teóricos del tema.
2. Identificación de conceptos y tecnologías.
3. Presentación de escenarios de red.
4. Diseño de topologías y direccionamiento.
5. Configuraciones y comandos explicados.
6. Diagramas de arquitectura y comunicación.
7. Verificación de procedimientos.
8. Interpretación de resultados.
9. Relación con los siguientes temas del recorrido.

---

## Tecnologías y áreas de estudio

El contenido aborda diferentes componentes del networking:

- Modelos de comunicación y encapsulación.
- Ethernet y transmisión de datos.
- Direccionamiento IPv4 e IPv6.
- Switching y segmentación mediante VLAN.
- Routing y conectividad entre redes.
- Protocolos y servicios de infraestructura.
- Seguridad de redes y filtrado de tráfico.
- VPN y tecnologías de tunelización.
- Infraestructura WAN y arquitecturas empresariales.
- Monitorización y diagnóstico.
- Administración de redes mediante herramientas Linux.
- Alta disponibilidad e integración de servicios.

---

## Entorno de simulación y alcance

Los laboratorios utilizan escenarios ilustrativos basados en tecnologías de **Linux**, incluidos **network namespaces**, interfaces virtuales y herramientas de red.

> **Alcance:** los escenarios permiten verificar mecanismos de red en entornos controlados. No deben confundirse con implementaciones empresariales completas ni con equipos físicos.

Las simplificaciones, dependencias y limitaciones de cada representación se indican junto al escenario correspondiente.

---

## Requisitos

Para trabajar con los laboratorios se recomienda:

- Sistema **Linux** (Debian/Ubuntu recomendado), preferiblemente en una máquina virtual dedicada.
- Kernel con soporte para *network namespaces*, `veth`, bridge y los módulos que requiera cada práctica (`8021q`, `ip_gre`, `xfrm_user`, `tun`, `wireguard`, etc.).
- Sesión con `root` o capacidades efectivas `CAP_NET_ADMIN` y `CAP_NET_RAW` para los ejercicios que crean interfaces, rutas, túneles o capturas.
- Herramientas indicadas en cada laboratorio (`iproute2`, `bridge`, `nftables`/`iptables`, `tcpdump`, `dnsmasq`, `keepalived`, `openvpn`, `wireguard-tools`, entre otras).

**Android/Termux no es un entorno de ejecución soportado** para estas topologías: el aislamiento de aplicaciones y las capacidades del kernel suelen impedir crear namespaces, bridges y enlaces `veth`, incluso si se instala `iproute2`. El sitio sí puede consultarse desde Android; para ejecutar las prácticas usa Linux en un PC o VM. WSL2 puede servir para ejercicios básicos, pero la disponibilidad de módulos y funciones de red depende de su kernel; verifica cada requisito antes de ejecutar.

Antes de comparar resultados entre equipos, registra las versiones y el kernel disponibles:

```bash
uname -sr
ip -Version
bridge -Version
nft --version 2>/dev/null || iptables --version
ethtool --version 2>/dev/null || true
openvpn --version 2>/dev/null | head -1 || true
wg --version 2>/dev/null || true
```

> **Recomendación:** utilizar una máquina virtual o entorno de pruebas. **No ejecutar los ejercicios directamente en servidores de producción.**

---

## Plataforma de documentación

El sitio está construido con **Zensical**, que permite generar documentación técnica mediante **Markdown** y una configuración centralizada.

Entre sus componentes se encuentran:

- Navegación estructurada de los 15 laboratorios.
- Tema claro y oscuro.
- Diagramas **Mermaid**.
- Bloques de código y comandos.
- Hojas de estilo personalizadas.
- Recursos gráficos y tipografía local.
- Documentación adaptable a dispositivos móviles.

---

## Entorno de documentación

Para ejecutar el proyecto en un entorno compatible con **Python**:

```bash
git clone https://github.com/asideloko/Networking-Lab.git

cd Networking-Lab

pip install -r requirements.txt
```

Iniciar el servidor de desarrollo:

```bash
zensical serve
```

Abrir:

```text
http://localhost:8000
```

Generar la versión estática:

```bash
zensical build
```

Los archivos generados se encuentran en el directorio `site/`.

---

## Estructura del repositorio

```text
Networking-Lab/
│
├── .github/
│   └── workflows/
│       └── docs.yml
│
├── docs/
│   ├── index.md
│   ├── 02-LABORATORIOS/
│   │   ├── lab-01/ ... lab-15/
│   ├── 03-PROYECTO-FINAL/
│   │   └── index.md
│   ├── 04-REFERENCIA/
│   │   ├── competencias.md
│   │   ├── comparaciones.md
│   │   ├── diagnostico.md
│   │   ├── servicios-puertos.md
│   │   ├── arquitectura-integral.md
│   │   └── glosario.md
│   ├── 05-ANEXOS/
│   │   ├── guia-de-uso.md
│   │   └── diagramacion-y-topologias.md
│   ├── assets/
│   ├── javascripts/
│   └── stylesheets/
│
├── overrides/
│   ├── main.html
│   └── partials/
│
├── scripts/
│   └── validar.py
│
├── README.md
├── requirements.txt
└── zensical.toml
```

---

## Libro de referencia

**NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico**

- **Autor:** Guillermo Castillo
- **Editorial / proyecto:** SecOpsMX
- **Edición:** 2026

Consultar y obtener el libro en [**Leanpub**](https://leanpub.com/networking-fundamentos).

---

## Licencia y uso

Material complementario del libro NETWORKING. No se autoriza su redistribución con fines comerciales.

---

**Desarrollado por Guillermo Castillo · SecOpsMX**

**NETWORKING Lab** — *Comprender las redes desde sus fundamentos hasta su implementación técnica.*


## Referencias visuales y enlaces técnicos

- `docs/05-ANEXOS/diagramacion-y-topologias.md` reúne los diagramas Mermaid de los laboratorios, el proyecto final y las referencias, con descripción y código fuente.
- `docs/04-REFERENCIA/glosario.md` enlaza términos y acrónimos a RFC, estándares IEEE y documentación oficial. La primera aparición de cada término reconocido también enlaza a su fuente técnica.
- `docs/stylesheets/extra.css` contiene la identidad visual del proyecto y los estilos de lectura; `docs/javascripts/custom.js` aplica colores semánticos a los nodos Mermaid (infraestructura, procesos, servicios, decisiones y seguridad).
