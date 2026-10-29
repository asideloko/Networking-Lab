<p class="tema-num">LABORATORIO PRÁCTICO</p>

# NETWORKING Lab

![Networking Lab](img/logo.png){ .logo-lab }

Manual práctico complementario del libro **NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico**. En él **construirás una infraestructura de red empresarial completa**, paso a paso, y llevarás la teoría a la terminal.

## Metodología

El proyecto consta de **15 laboratorios**, uno por cada tema del libro. Cada laboratorio:

1.  Estudia un tema teórico.
2.  Identifica los conceptos implementables.
3.  Diseña un escenario empresarial realista.
4.  Diseña la topología y el direccionamiento.
5.  Implementa la configuración paso a paso.
6.  Explica cada procedimiento.
7.  Verifica cada etapa.
8.  Muestra el resultado esperado.
9.  Prepara el siguiente laboratorio.

Al finalizar el laboratorio 15 tendrás una red funcional que integra enrutamiento, conmutación, VLAN, VPN, seguridad, monitoreo y más.

## Requisitos

-   Un sistema Linux (máquina virtual, WSL2 o instalación real) con privilegios de superusuario.
-   Conocimientos básicos de línea de comandos.
-   Ganas de aprender haciendo.

!!! warning "Antes de empezar"
    Los laboratorios crean *namespaces* de red, interfaces virtuales y reglas de firewall en tu equipo. Hazlos en una **máquina virtual o equipo de pruebas**, no en un servidor en producción. Algunos laboratorios necesitan módulos del kernel: `8021q` (05 y 11), `ip_gre` (06 y 09) y `wireguard`, `esp4`/`xfrm_user` y `tun` (09); una máquina virtual Linux estándar los incluye. El laboratorio 10 trata MPLS solo a nivel conceptual (no requiere `mpls_router`). El laboratorio 15 usa `frr`, `keepalived` y `dnsmasq-base`.

## Laboratorios

Realízalos en orden: **comienza por el laboratorio 01**.

| N.º | Laboratorio | Libro |
|:---:|-------------|:-----:|
| 01 | [Fundamentos de Redes y Encapsulación](labs/lab-01/index.md) | Tema 1 |
| 02 | [Transmisión de Datos y Capa Física](labs/lab-02/index.md) | Tema 2 |
| 03 | [Componentes de Red y Conmutación](labs/lab-03/index.md) | Tema 3 |
| 04 | [Direccionamiento IP y Subredes](labs/lab-04/index.md) | Tema 4 |
| 05 | [Conmutación y Segmentación de Red](labs/lab-05/index.md) | Tema 5 |
| 06 | [Enrutamiento y Conectividad entre Redes](labs/lab-06/index.md) | Tema 6 |
| 07 | [Protocolos y Servicios de Red](labs/lab-07/index.md) | Tema 7 |
| 08 | [Seguridad en Redes](labs/lab-08/index.md) | Tema 8 |
| 09 | [VPN y Tunelización](labs/lab-09/index.md) | Tema 9 |
| 10 | [Infraestructura WAN y Core](labs/lab-10/index.md) | Tema 10 |
| 11 | [Arquitectura de Red Empresarial](labs/lab-11/index.md) | Tema 11 |
| 12 | [Arquitecturas Modernas de Red](labs/lab-12/index.md) | Tema 12 |
| 13 | [Monitoreo y Diagnóstico de Redes](labs/lab-13/index.md) | Tema 13 |
| 14 | [Herramientas Linux Avanzadas](labs/lab-14/index.md) | Tema 14 |
| 15 | [Implementación Práctica Integral](labs/lab-15/index.md) | Tema 15 |
