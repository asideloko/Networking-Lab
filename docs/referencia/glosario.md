---
title: "GLOSARIO"
description: "Glosario de servicios, protocolos y conceptos de los 15 laboratorios de NETWORKING Lab."
---

<p class="tema-eyebrow">REFERENCIA</p>

# GLOSARIO

Definiciones breves de los términos que se usan a lo largo de la serie. Entre paréntesis, el laboratorio donde aparecen por primera vez o se practican.

## Fundamentos y direccionamiento

**ARP** (01)
:   Protocolo que resuelve una dirección IP a la MAC correspondiente dentro de la red local.

**Bridge** (01, 03)
:   Dispositivo (o función del kernel) que reenvía tramas Ethernet según la MAC de destino.

**Dominio de *broadcast*** (01, 05)
:   Conjunto de equipos que reciben las tramas enviadas a todos. Una VLAN divide ese dominio.

**Encapsulación** (01)
:   Proceso por el que cada capa añade su cabecera a los datos de la capa superior.

**MAC** (01)
:   Dirección de una interfaz en el enlace local (capa 2).

**MTU / MSS** (03, 07, 15)
:   Tamaño máximo del paquete en un enlace (MTU) y de los datos TCP por segmento (MSS = MTU − 40 en IPv4).

**Namespace de red** (01)
:   Mecanismo de Linux que aísla interfaces, rutas y reglas de red; aquí simula un equipo independiente.

**veth** (01)
:   Par de interfaces virtuales conectadas entre sí: lo que entra por una sale por la otra.

**VLSM** (04, 15)
:   Subnetting con máscaras de longitud variable para ajustar cada subred a su tamaño.

## Conmutación y enrutamiento

**802.1Q / trunk** (05)
:   Estándar de etiquetado de VLAN; un trunk transporta varias VLAN por un mismo enlace.

**ECMP** (10)
:   Reparto de tráfico por flujo entre varios caminos de igual coste.

**GRE** (06, 09)
:   Protocolo de encapsulación (IP 47); no cifra.

**Longest prefix match** (06)
:   Regla de selección de rutas: gana la que tiene el prefijo más largo.

**OSPF** (15)
:   Protocolo de enrutamiento de estado de enlace; los routers forman adyacencias, comparten la LSDB y calculan rutas con SPF.

**Router-on-a-Stick** (05)
:   Router con subinterfaces que enruta entre VLAN a través de un único trunk.

**STP / RSTP** (11)
:   Protocolos que evitan bucles de capa 2 bloqueando los puertos redundantes.

**TTL** (06)
:   Contador que cada router decrementa; evita que un paquete circule indefinidamente.

**VRRP** (15)
:   Protocolo que ofrece una IP virtual de *gateway* compartida por varios routers.

## Servicios

**DHCP** (07)
:   Servicio que entrega a los clientes dirección, máscara, *gateway* y DNS (proceso DORA).

**DNS** (07)
:   Servicio que resuelve nombres a registros de recursos (direcciones, entre otros).

**NAT / PAT** (02, 07)
:   Traducción de direcciones (y puertos). PAT permite que muchas conexiones privadas compartan una sola dirección.

**TCP / UDP** (07)
:   Protocolos de transporte: TCP, fiable y orientado a conexión; UDP, sin conexión.

## Seguridad y VPN

**ACL** (08)
:   Lista ordenada de reglas de permitir/denegar que se aplica en un punto de control.

**CIA** (08)
:   Tríada de seguridad: confidencialidad, integridad y disponibilidad.

**DMZ** (08)
:   Zona intermedia donde se alojan servidores públicos, separada de la red interna.

**DNAT / SNAT** (08)
:   Traducción del destino (publicar un servicio) o del origen (salida a Internet).

**ESP / IPsec** (09)
:   Protocolo de IPsec (IP 50) que cifra y autentica el contenido de los paquetes.

**NAT-T** (09)
:   Encapsulación de ESP en UDP 4500 para atravesar NAT.

**Stateful / con estado** (08)
:   Firewall que recuerda las conexiones y permite automáticamente sus respuestas.

**TLS** (08)
:   Protocolo que cifra y autentica comunicaciones de aplicación (HTTPS).

**WireGuard** (09)
:   VPN basada en pares de claves públicas; `AllowedIPs` define qué tráfico se enruta a cada par.

## Arquitectura y operación

**Broker ZTNA** (12)
:   Elemento que aplica la política de acceso por aplicación a los usuarios remotos.

**CE / PE / P** (10)
:   Equipo del cliente (CE), de frontera del proveedor (PE) y de núcleo (P). Son **funciones**, no tipos de hardware.

**IdP** (12)
:   Proveedor de identidad: verifica quién es el usuario.

**LFIB / LDP / FEC** (10)
:   Tabla de reenvío por etiquetas, protocolo que reparte etiquetas y clase de reenvío equivalente (MPLS).

**Microsegmentación** (12)
:   Reglas granulares entre servidores o aplicaciones (por ejemplo, App → DB solo al puerto 3306).

**MPLS / SD-WAN** (10)
:   Reenvío por etiquetas dentro de un proveedor / gestión por políticas sobre varios transportes.

**NOC / SIEM** (13)
:   Centro de operaciones de red / plataforma de correlación de eventos de seguridad.

**SASE / Zero Trust** (12)
:   Servicio en la nube que combina red y seguridad / modelo de seguridad sin confianza implícita.

**VPC** (12)
:   Red virtual definida en la infraestructura de un proveedor de nube.
