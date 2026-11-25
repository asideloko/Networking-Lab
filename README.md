# NETWORKING LAB

## Laboratorios prácticos de redes | SecOpsMX

> Del fundamento teórico a la comprensión técnica mediante escenarios de red, topologías y demostraciones prácticas.

[Acceder a NETWORKING Lab](https://asideloko.github.io/Networking-Lab/) 

---


**NETWORKING Lab** es un entorno de aprendizaje práctico que complementa el libro **NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico**, de **Guillermo Castillo (SecOpsMX)**.

El proyecto transforma los conceptos fundamentales de las redes de computadoras en escenarios didácticos que permiten comprender el funcionamiento de protocolos, tecnologías, arquitecturas y servicios de red.

A través de **15 laboratorios**, se presentan topologías, esquemas de comunicación, direccionamiento, configuraciones ilustrativas, comandos y resultados que permiten relacionar los fundamentos teóricos con su representación técnica.

El objetivo es comprender cómo funcionan las redes, cómo interactúan sus componentes y qué sucede durante los diferentes procesos de comunicación.

---

## Contenido

El entorno está organizado en **15 laboratorios**, distribuidos en tres bloques temáticos, además de una sección de referencia técnica y anexos comunes.

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

## Estructura de cada laboratorio

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

> **Importante:** este proyecto tiene una finalidad educativa. Sus escenarios permiten comprender y representar procesos de comunicación, pero no constituyen implementaciones completas de infraestructuras empresariales ni sustituyen equipos físicos o plataformas especializadas de simulación.

Cuando una representación simplifica una tecnología, se documentan sus alcances y limitaciones para evitar confundir un modelo didáctico con una implementación real.

---

## Requisitos

Para trabajar con los laboratorios se recomienda:

- Sistema **Linux** (Debian/Ubuntu recomendado), preferiblemente en una máquina virtual dedicada.
- Kernel con soporte para *network namespaces*, `veth`, bridge y los módulos que requiera cada práctica (`8021q`, `ip_gre`, `xfrm_user`, `tun`, `wireguard`, etc.).
- Sesión con `root` o capacidades efectivas `CAP_NET_ADMIN` y `CAP_NET_RAW` para las prácticas que crean interfaces, rutas, túneles o capturas.
- Herramientas indicadas en cada laboratorio (`iproute2`, `bridge`, `nftables`/`iptables`, `tcpdump`, `dnsmasq`, `keepalived`, `openvpn`, `wireguard-tools`, entre otras).

**Android/Termux no es un entorno de ejecución soportado** para estas topologías: el aislamiento de aplicaciones y las capacidades del kernel suelen impedir crear namespaces, bridges y enlaces `veth`, incluso si se instala `iproute2`. El sitio sí puede consultarse desde Android; para ejecutar las prácticas usa Linux en un PC o VM. WSL2 puede servir para prácticas básicas, pero la disponibilidad de módulos y funciones de red depende de su kernel; verifica cada requisito antes de ejecutar.

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

> **Recomendación:** utilizar una máquina virtual o entorno de pruebas. **No ejecutar las prácticas directamente en servidores de producción.**

---

## Plataforma de documentación

El sitio está construido con **Zensical**, que permite generar documentación técnica mediante **Markdown** y una configuración centralizada.

---

## Desarrollo local

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
│   ├── 04-REFERENCIA/
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

Consulta directamente la licencia en el proyecto. Uso educativo; no se autoriza su redistribución con fines comerciales.

---

**Desarrollado por Guillermo Castillo · SecOpsMX**

**NETWORKING Lab** — *Comprender las redes desde sus fundamentos hasta su implementación técnica.*


