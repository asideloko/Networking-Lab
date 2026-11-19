---
title: "NETWORKING Lab"
description: "Laboratorios de explicación y simulación de redes, complementarios del libro NETWORKING."
hide:

  - toc
---

<div class="sx-hero"><p><img alt="SecOpsMX" class="sx-hero__logo off-glb" src="assets/logo.png"/></p><h1 id="networking-lab">NETWORKING Lab</h1><p class="sx-hero__sub">Laboratorios de explicación<br/>y simulación de redes.</p><p class="sx-hero__lead">Material práctico complementario del libro NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico.</p><p class="sx-hero__cta"><a class="md-button md-button--primary" href="labs/lab-01/index.html">Comenzar por el laboratorio 01</a><a class="md-button" href="https://leanpub.com/networking-fundamentos">Obtener el libro</a></p><p class="sx-hero__meta">Material complementario · Guillermo Castillo · SecOpsMX</p></div>

<div class="sx-stats"><div><b>15</b><span>laboratorios</span></div><div><b>41</b><span>diagramas</span></div><div><b>275</b><span>bloques de comandos</span></div></div>

Cada laboratorio presenta **escenarios ilustrativos** para comprender protocolos, tecnologías, arquitecturas y procesos de comunicación, y lleva la teoría a la terminal mediante comandos de demostración.

!!! info "Qué son (y qué no son) estos laboratorios"
    Son **representaciones didácticas** construidas con *namespaces* de red de Linux: simplifican la realidad para explicar cómo funciona cada tecnología. **No** son procedimientos de implementación profesional ni reproducen todos los componentes de una infraestructura real. Un ejemplo explica correctamente un proceso cuando **representa correctamente ese proceso**; cuando una simplificación afecta a lo explicado (por ejemplo, rutas IP estáticas en lugar de MPLS real), la página lo indica.

## Metodología

El proyecto consta de **15 laboratorios**, uno por cada tema del libro. Cada laboratorio:

1.  Estudia un tema teórico.
2.  Identifica los conceptos implementables.
3.  Plantea un escenario empresarial ilustrativo.
4.  Diseña la topología y el direccionamiento.
5.  Muestra la configuración paso a paso como ejemplo de demostración.
6.  Explica cada procedimiento.
7.  Verifica cada etapa.
8.  Muestra el resultado esperado o una salida de ejemplo (véase la convención siguiente).
9.  Prepara el siguiente laboratorio.

Al finalizar el laboratorio 15 habrás recorrido un escenario que integra direccionamiento, enrutamiento, firewall, servicios y redundancia de *gateway*, entendiendo qué demuestra cada ejemplo y cuáles son sus límites.

## Cómo leer las salidas de los laboratorios

En los laboratorios se mezclan comandos, capturas y resultados. Para no confundirlos se usan estas etiquetas:

| Etiqueta | Significado |
|----------|-------------|
| **Ejemplo de salida** | Resultado **representativo**, no necesariamente ejecutado: los números, horas y direcciones MAC cambiarán en tu equipo. |
| **Captura de referencia** | Evidencia de una **ejecución concreta**. |
| **Resultado esperado** | Comportamiento que **debería producirse** bajo las condiciones descritas. |
| **Esquema conceptual** | **Representación simplificada** de un proceso; no una transcripción literal. |

Cada laboratorio distingue tres niveles: el **conceptual** (cómo funciona la tecnología), el **representativo** (cómo lo ilustra la topología o el ejemplo) y el **técnico** (qué comportamiento tendría una configuración real y en qué condiciones).

## Requisitos

-   Un sistema Linux (máquina virtual, WSL2 o instalación real) con privilegios de superusuario.
-   Conocimientos básicos de línea de comandos.
-   Paquetes de uso común en la serie: `sudo apt install tcpdump traceroute iperf3 dnsutils curl` (cada laboratorio indica si necesita alguno más).
-   Convención de `sudo`: los laboratorios 01 a 05 muestran los comandos sin `sudo` (asumen una sesión de root, `sudo -i`); desde el 06 aparece explícito. Si trabajas con un usuario normal, antepón `sudo` en todos.
-   Ganas de aprender haciendo.

!!! warning "Antes de empezar"
    Los laboratorios crean *namespaces* de red, interfaces virtuales y reglas de firewall en tu equipo. Hazlos en una **máquina virtual o equipo de pruebas**, no en un servidor en producción. Algunos laboratorios necesitan módulos del kernel: `8021q` (05 y 11), `ip_gre` (06 y 09) y `wireguard`, `esp4`/`xfrm_user` y `tun` (09); una máquina virtual Linux estándar los incluye. El laboratorio 10 trata MPLS solo a nivel conceptual (no requiere `mpls_router`). El laboratorio 15 usa `frr`, `keepalived` y `dnsmasq-base`.

## Laboratorios

Realízalos en orden: **comienza por el laboratorio 01**. No todos usan la misma topología: cuando un laboratorio abre un **escenario nuevo** (otro direccionamiento, otros dispositivos o nombres reutilizados con otra función), la página lo indica al principio.

## Laboratorios 1 a 5

<div class="sx-cards"><a class="sx-card" href="labs/lab-01/index.html"><span class="sx-card__n">01</span><span class="sx-card__t">FUNDAMENTOS DE REDES Y ENCAPSULACIÓN</span><span class="sx-card__m">Tema 1 del libro</span></a><a class="sx-card" href="labs/lab-02/index.html"><span class="sx-card__n">02</span><span class="sx-card__t">TRANSMISIÓN DE DATOS Y CAPA FÍSICA</span><span class="sx-card__m">Tema 2 del libro</span></a><a class="sx-card" href="labs/lab-03/index.html"><span class="sx-card__n">03</span><span class="sx-card__t">COMPONENTES DE RED Y CONMUTACIÓN</span><span class="sx-card__m">Tema 3 del libro</span></a><a class="sx-card" href="labs/lab-04/index.html"><span class="sx-card__n">04</span><span class="sx-card__t">DIRECCIONAMIENTO IP Y SUBREDES</span><span class="sx-card__m">Tema 4 del libro</span></a><a class="sx-card" href="labs/lab-05/index.html"><span class="sx-card__n">05</span><span class="sx-card__t">CONMUTACIÓN Y SEGMENTACIÓN DE RED</span><span class="sx-card__m">Tema 5 del libro</span></a></div>

## Laboratorios 6 a 10

<div class="sx-cards"><a class="sx-card" href="labs/lab-06/index.html"><span class="sx-card__n">06</span><span class="sx-card__t">ENRUTAMIENTO Y CONECTIVIDAD ENTRE REDES</span><span class="sx-card__m">Tema 6 del libro</span></a><a class="sx-card" href="labs/lab-07/index.html"><span class="sx-card__n">07</span><span class="sx-card__t">PROTOCOLOS Y SERVICIOS DE RED</span><span class="sx-card__m">Tema 7 del libro</span></a><a class="sx-card" href="labs/lab-08/index.html"><span class="sx-card__n">08</span><span class="sx-card__t">SEGURIDAD EN REDES</span><span class="sx-card__m">Tema 8 del libro</span></a><a class="sx-card" href="labs/lab-09/index.html"><span class="sx-card__n">09</span><span class="sx-card__t">VPN Y TUNELIZACIÓN</span><span class="sx-card__m">Tema 9 del libro</span></a><a class="sx-card" href="labs/lab-10/index.html"><span class="sx-card__n">10</span><span class="sx-card__t">INFRAESTRUCTURA WAN Y CORE</span><span class="sx-card__m">Tema 10 del libro</span></a></div>

## Laboratorios 11 a 15

<div class="sx-cards"><a class="sx-card" href="labs/lab-11/index.html"><span class="sx-card__n">11</span><span class="sx-card__t">ARQUITECTURA DE RED EMPRESARIAL</span><span class="sx-card__m">Tema 11 del libro</span></a><a class="sx-card" href="labs/lab-12/index.html"><span class="sx-card__n">12</span><span class="sx-card__t">ARQUITECTURAS MODERNAS DE RED</span><span class="sx-card__m">Tema 12 del libro</span></a><a class="sx-card" href="labs/lab-13/index.html"><span class="sx-card__n">13</span><span class="sx-card__t">MONITOREO Y DIAGNÓSTICO DE REDES</span><span class="sx-card__m">Tema 13 del libro</span></a><a class="sx-card" href="labs/lab-14/index.html"><span class="sx-card__n">14</span><span class="sx-card__t">HERRAMIENTAS LINUX AVANZADAS</span><span class="sx-card__m">Tema 14 del libro</span></a><a class="sx-card" href="labs/lab-15/index.html"><span class="sx-card__n">15</span><span class="sx-card__t">IMPLEMENTACIÓN PRÁCTICA INTEGRAL</span><span class="sx-card__m">Tema 15 del libro</span></a></div>

<figure class="portada-libro" markdown="span"><img alt="Portada y contraportada del libro NETWORKING" src="assets/portada-libro.jpg"/></figure>


## Operaciones que afectan al equipo anfitrión

Un *namespace* aísla la **red**, no el equipo. Los pasos que modifican el **host** (reenvío IPv4, reglas NAT, `/etc/sysctl.d`, rutas temporales) aparecen siempre bajo el aviso **«Cambio en el host»**, y cada laboratorio que los usa (02, 04, 05, 07, 08, 09, 11, 13, 14 y 15) incluye su sección de **reversión**. Las paradas de procesos se hacen por PID o con `ip netns pids <namespace>`, nunca con `pkill` sobre el sistema completo. Antes de empezar anota `sysctl net.ipv4.ip_forward` y `iptables -t nat -S POSTROUTING`; así sabrás a qué estado volver.

## Material de referencia

Además de los laboratorios, el sitio incluye páginas de síntesis para consultar mientras practicas:

-   [Servicios, protocolos y puertos](referencia/servicios-puertos.md): matriz común de la serie.
-   [Comparaciones conceptuales](referencia/comparaciones.md): bridge/router, MAC/IP, subred/VLAN, GRE/IPsec y más.
-   [Método de diagnóstico](referencia/diagnostico.md): del síntoma a la causa.
-   [Arquitectura integral](referencia/arquitectura-integral.md): mapas de síntesis y matriz de disponibilidad.
-   [Glosario](referencia/glosario.md).
-   [Competencias y casos integradores](referencia/competencias.md): qué se espera al terminar y casos para repasar la serie.

Cada laboratorio termina con **preguntas de reflexión**: qué mecanismo se demuestra, qué pasa si se elimina un componente, qué limitaciones tiene y dónde se usaría en una empresa.

## Recopilación de diagramas de los laboratorios

Esta sección reúne los diagramas incluidos en los 15 laboratorios. Cada enlace lleva al diagrama original, dentro de su explicación y contexto; las descripciones siguientes resumen qué representa.

### Laboratorio 01 — Fundamentos de redes y encapsulación

1. [Topología](labs/lab-01/index.md#topologia): equipos y enlaces virtuales del escenario inicial.
2. [Conexión lógica del escenario](labs/lab-01/index.md#conexion-logica-del-escenario): relación entre los dispositivos y sus segmentos de red.
3. [Esquema de encapsulación con campos](labs/lab-01/index.md#esquema-de-encapsulacion-con-campos): cómo se anidan los encabezados de las distintas capas.

### Laboratorio 02 — Transmisión de datos y capa física

4. [Topología](labs/lab-02/index.md#topologia): recorrido físico y lógico de la transmisión representada.

### Laboratorio 03 — Componentes de red y conmutación

5. [Topología](labs/lab-03/index.md#topologia): dispositivos y enlaces utilizados para estudiar la conmutación.

### Laboratorio 04 — Direccionamiento IP y subredes

6. [Topología](labs/lab-04/index.md#topologia): redes y subredes que forman el escenario de direccionamiento.

### Laboratorio 05 — Conmutación y segmentación de red

7. [Topología](labs/lab-05/index.md#topologia): separación de segmentos y conexiones del escenario VLAN.
8. [Subred frente a VLAN](labs/lab-05/index.md#subred-frente-a-vlan): diferencia entre el límite lógico de capa 3 y el dominio de capa 2.

### Laboratorio 06 — Enrutamiento y conectividad entre redes

9. [Topología](labs/lab-06/index.md#topologia): routers, redes y enlaces entre sucursales.
10. [Cómo se elige la ruta: *longest prefix match*](labs/lab-06/index.md#como-se-elige-la-ruta-longest-prefix-match): selección de la ruta más específica antes de comparar métricas.
11. [Recorrido de un paquete entre sucursales](labs/lab-06/index.md#recorrido-de-un-paquete-entre-sucursales): saltos que atraviesa un paquete entre redes remotas.
12. [Cambio de ruta por métrica](labs/lab-06/index.md#la-ruta-de-metrica-50-desaparece-y-entra-la-de-metrica-100-por-r2): sustitución de la ruta preferida cuando deja de estar disponible.

### Laboratorio 07 — Protocolos y servicios de red

13. [Topología](labs/lab-07/index.md#topologia): clientes, servidores y servicios del escenario.
14. [Relación entre los cuatro servicios](labs/lab-07/index.md#como-se-relacionan-los-cuatro-servicios): interacción de los servicios básicos de red.
15. [Resolución DNS](labs/lab-07/index.md#resolucion-dns): consulta y respuesta para traducir un nombre en una dirección.
16. [Proceso DHCP (DORA)](labs/lab-07/index.md#proceso-dhcp-dora): secuencia Discover, Offer, Request y Acknowledge.
17. [Establecimiento y cierre de una conexión TCP](labs/lab-07/index.md#establecimiento-y-cierre-de-una-conexion-tcp): negociación inicial y terminación ordenada de la sesión.

### Laboratorio 08 — Seguridad en redes

18. [Topología](labs/lab-08/index.md#topologia): zonas, equipos y puntos de control de seguridad.
19. [Recorrido de un paquete por el firewall](labs/lab-08/index.md#recorrido-de-un-paquete-por-el-firewall): decisión de filtrado según el recorrido del paquete por Netfilter.

### Laboratorio 09 — VPN y tunelización

20. [Topología](labs/lab-09/index.md#topologia): extremos y redes conectadas mediante túneles.
21. [Qué añade cada tecnología a un paquete](labs/lab-09/index.md#que-anade-cada-tecnologia-a-un-paquete): comparación de encapsulación GRE y protección ESP/IPsec.
22. [Establecimiento de un túnel](labs/lab-09/index.md#establecimiento-de-un-tunel): acuerdo de parámetros, envío encapsulado y retorno entre extremos.
23. [NAT-T y AllowedIPs](labs/lab-09/index.md#nat-t-y-allowedips): transporte de IPsec a través de NAT y selección de tráfico en WireGuard.

### Laboratorio 10 — Infraestructura WAN y Core

24. [Topología](labs/lab-10/index.md#topologia): estructura de proveedor y conexiones WAN del escenario.
25. [Red de proveedor: roles PE y P](labs/lab-10/index.md#red-de-proveedor-roles-pe-y-p): separación de routers de borde y routers internos del proveedor.
26. [Push, swap y pop](labs/lab-10/index.md#push-swap-y-pop): operaciones de imposición, sustitución y retirada de etiquetas MPLS.
27. [Failover frente a ECMP](labs/lab-10/index.md#failover-frente-a-ecmp): diferencia entre respaldo de ruta y reparto entre caminos equivalentes.

### Laboratorio 11 — Arquitectura de red empresarial

28. [Las capas son funciones, no niveles físicos](labs/lab-11/index.md#las-capas-son-funciones-no-niveles-fisicos): funciones de acceso, distribución y core en el diseño jerárquico.
29. [Topología](labs/lab-11/index.md#topologia): componentes y enlaces de la arquitectura empresarial.
30. [STP/RSTP: redundancia física sin bucles](labs/lab-11/index.md#stprstp-redundancia-fisica-sin-bucles): bloqueo de caminos redundantes para evitar bucles de capa 2.
31. [Ejemplo de crecimiento: Access2 y Access3](labs/lab-11/index.md#ejemplo-de-crecimiento-access2-y-access3): ampliación de la capa de acceso y sus conexiones.

### Laboratorio 12 — Arquitecturas modernas de red

32. [Topología](labs/lab-12/index.md#topologia): componentes y límites de confianza del escenario moderno.
33. [Componentes de una arquitectura ZTNA real](labs/lab-12/index.md#componentes-de-una-arquitectura-ztna-real): relación entre identidad, decisión de acceso y punto de aplicación de políticas.
34. [VPC con subred pública y privada](labs/lab-12/index.md#vpc-con-subred-publica-y-privada): separación de recursos expuestos y recursos internos.

### Laboratorio 13 — Monitoreo y diagnóstico de redes

35. [Topología](labs/lab-13/index.md#topologia): fuentes, colectores y puntos de observación.
36. [Del síntoma a la causa: método de diagnóstico](labs/lab-13/index.md#del-sintoma-a-la-causa-metodo-de-diagnostico): secuencia para acotar una falla con evidencias.

### Laboratorio 14 — Herramientas Linux avanzadas

37. [Topología](labs/lab-14/index.md#topologia): interfaces, rutas y nodos empleados en las pruebas avanzadas.
38. [Recorrido de un paquete: input, forward y output](labs/lab-14/index.md#recorrido-de-un-paquete-input-forward-y-output): cadenas que atraviesa el tráfico según su destino en el host.

### Laboratorio 15 — Implementación práctica integral

39. [Topología](labs/lab-15/index.md#topologia): vista general de routers, servicios, redes y redundancia.
40. [Mapa del escenario: redes, *gateways* y caminos](labs/lab-15/index.md#mapa-del-escenario-redes-gateways-y-caminos): direccionamiento y caminos previstos para la práctica integral.
41. [Cambio de *master* y *backup*](labs/lab-15/index.md#cambio-de-master-y-backup): transición del rol activo al respaldo en la redundancia de gateway.
