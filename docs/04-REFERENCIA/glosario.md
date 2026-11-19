---
title: "GLOSARIO"
description: "Glosario de servicios, protocolos y conceptos de los 15 laboratorios de NETWORKING Lab."
---

<p class="tema-eyebrow">REFERENCIA</p>

# GLOSARIO

Definiciones breves de los términos que se usan a lo largo de la serie. Entre paréntesis, el laboratorio donde aparecen por primera vez o se practican.

## Fundamentos y direccionamiento

**[ARP](https://www.rfc-editor.org/rfc/rfc826)** (01)
:   Protocolo que resuelve una dirección IP a la MAC correspondiente dentro de la red local.

**[Bridge](https://docs.kernel.org/networking/bridge.html)** (01, 03)
:   Dispositivo (o función del kernel) que reenvía tramas Ethernet según la MAC de destino.

**Dominio de *[broadcast](https://www.rfc-editor.org/rfc/rfc919)*** (01, 05)
:   Conjunto de equipos que reciben las tramas enviadas a todos. Una VLAN divide ese dominio.

**[Encapsulación](https://www.rfc-editor.org/rfc/rfc1122)** (01)
:   Proceso por el que cada capa añade su cabecera a los datos de la capa superior.

**[MAC](https://www.rfc-editor.org/rfc/rfc9542)** (01)
:   Dirección de una interfaz en el enlace local (capa 2).

**[MTU](https://www.rfc-editor.org/rfc/rfc1191) / [MSS](https://www.rfc-editor.org/rfc/rfc9293)** (03, 07, 15)
:   Tamaño máximo del paquete en un enlace (MTU) y de los datos TCP por segmento (MSS = MTU − 40 en IPv4).

**[Namespace de red](https://man7.org/linux/man-pages/man7/network_namespaces.7.html)** (01)
:   Mecanismo de Linux que aísla interfaces, rutas y reglas de red; aquí simula un equipo independiente.

**[veth](https://man7.org/linux/man-pages/man4/veth.4.html)** (01)
:   Par de interfaces virtuales conectadas entre sí: lo que entra por una sale por la otra.

**[VLSM](https://www.cisco.com/c/en/us/support/docs/ip/routing-information-protocol-rip/13788-3.html)** (04, 15)
:   Subnetting con máscaras de longitud variable para ajustar cada subred a su tamaño.

## Conmutación y enrutamiento

**[802.1Q / trunk](https://1.ieee802.org/maintenance/802-1q/)** (05)
:   Estándar de etiquetado de VLAN; un trunk transporta varias VLAN por un mismo enlace.

**[ECMP](https://www.rfc-editor.org/rfc/rfc2992)** (10)
:   Reparto de tráfico por flujo entre varios caminos de igual coste.

**[GRE](https://www.rfc-editor.org/rfc/rfc2784)** (06, 09)
:   Protocolo de encapsulación (IP 47); no cifra.

**[Longest prefix match](https://www.rfc-editor.org/rfc/rfc1812)** (06)
:   Regla de selección de rutas: gana la que tiene el prefijo más largo.

**[OSPF](https://www.rfc-editor.org/rfc/rfc2328)** (15)
:   Protocolo de enrutamiento de estado de enlace; los routers forman adyacencias, comparten la LSDB y calculan rutas con SPF.

**[Router-on-a-Stick](https://www.cisco.com/c/en/us/support/docs/lan-switching/inter-vlan-routing/10023-3.html)** (05)
:   Router con subinterfaces que enruta entre VLAN a través de un único trunk.

**[STP](https://1.ieee802.org/spanning-tree/) / [RSTP](https://1.ieee802.org/spanning-tree/)** (11)
:   Protocolos que evitan bucles de capa 2 bloqueando los puertos redundantes.

**[TTL](https://www.rfc-editor.org/rfc/rfc791)** (06)
:   Contador que cada router decrementa; evita que un paquete circule indefinidamente.

**[VRRP](https://www.rfc-editor.org/rfc/rfc9568)** (15)
:   Protocolo que ofrece una IP virtual de *gateway* compartida por varios routers.

## Servicios

**[DHCP](https://www.rfc-editor.org/rfc/rfc2131)** (07)
:   Servicio que entrega a los clientes dirección, máscara, *gateway* y DNS (proceso DORA).

**[DNS](https://www.rfc-editor.org/rfc/rfc1034)** (07)
:   Servicio que resuelve nombres a registros de recursos (direcciones, entre otros).

**[NAT](https://www.rfc-editor.org/rfc/rfc3022) / [PAT](https://www.cisco.com/c/en/us/support/docs/ip/network-address-translation-nat/218012-troubleshoot-network-address-translation.html)** (02, 07)
:   Traducción de direcciones (y puertos). PAT permite que muchas conexiones privadas compartan una sola dirección.

**[TCP](https://www.rfc-editor.org/rfc/rfc9293) / [UDP](https://www.rfc-editor.org/rfc/rfc768)** (07)
:   Protocolos de transporte: TCP, fiable y orientado a conexión; UDP, sin conexión.

## Seguridad y VPN

**[ACL](https://www.cisco.com/c/en/us/td/docs/switches/lan/c9000/security/acls/acls-configuration-guide/access-control-lists.html)** (08)
:   Lista ordenada de reglas de permitir/denegar que se aplica en un punto de control.

**[CIA](https://csrc.nist.gov/glossary/term/cia_triad)** (08)
:   Tríada de seguridad: confidencialidad, integridad y disponibilidad.

**[DMZ](https://csrc.nist.gov/glossary/term/demilitarized_zone)** (08)
:   Zona intermedia donde se alojan servidores públicos, separada de la red interna.

**[DNAT](https://netfilter.org/documentation/HOWTO/NAT-HOWTO-6.html) / [SNAT](https://netfilter.org/documentation/HOWTO/NAT-HOWTO-6.html)** (08)
:   Traducción del destino (publicar un servicio) o del origen (salida a Internet).

**[ESP](https://www.rfc-editor.org/rfc/rfc4303) / [IPsec](https://www.rfc-editor.org/rfc/rfc4301)** (09)
:   Protocolo de IPsec (IP 50) que cifra y autentica el contenido de los paquetes.

**[NAT-T](https://www.rfc-editor.org/rfc/rfc3947)** (09)
:   Encapsulación de ESP en UDP 4500 para atravesar NAT.

**[Stateful](https://csrc.nist.gov/glossary/term/stateful_inspection) / con estado** (08)
:   Firewall que recuerda las conexiones y permite automáticamente sus respuestas.

**[TLS](https://www.rfc-editor.org/rfc/rfc8446)** (08)
:   Protocolo que cifra y autentica comunicaciones de aplicación (HTTPS).

**[WireGuard](https://www.wireguard.com/)** (09)
:   VPN basada en pares de claves públicas; `AllowedIPs` define qué tráfico se enruta a cada par.

## Arquitectura y operación

**Broker [ZTNA](https://csrc.nist.gov/pubs/sp/800/207/final)** (12)
:   Elemento que aplica la política de acceso por aplicación a los usuarios remotos.

**[CE](https://www.rfc-editor.org/rfc/rfc4364) / [PE](https://www.rfc-editor.org/rfc/rfc4364) / [P](https://www.rfc-editor.org/rfc/rfc4364)** (10)
:   Equipo del cliente (CE), de frontera del proveedor (PE) y de núcleo (P). Son **funciones**, no tipos de hardware.

**[IdP](https://csrc.nist.gov/glossary/term/identity_provider)** (12)
:   Proveedor de identidad: verifica quién es el usuario.

**[LFIB](https://www.rfc-editor.org/rfc/rfc3031) / [LDP](https://www.rfc-editor.org/rfc/rfc5036) / [FEC](https://www.rfc-editor.org/rfc/rfc3031)** (10)
:   Tabla de reenvío por etiquetas, protocolo que reparte etiquetas y clase de reenvío equivalente (MPLS).

**[Microsegmentación](https://www.cisa.gov/zero-trust-maturity-model)** (12)
:   Reglas granulares entre servidores o aplicaciones (por ejemplo, App → DB solo al puerto 3306).

**[MPLS](https://www.rfc-editor.org/rfc/rfc3031) / [SD-WAN](https://www.cisco.com/c/en/us/solutions/enterprise-networks/sd-wan/what-is-sd-wan.html)** (10)
:   Reenvío por etiquetas dentro de un proveedor / gestión por políticas sobre varios transportes.

**[NOC](https://www.cisco.com/c/en/us/products/routers/what-is-network-operations-center-noc.html) / [SIEM](https://csrc.nist.gov/glossary/term/security_information_and_event_management)** (13)
:   Centro de operaciones de red / plataforma de correlación de eventos de seguridad.

**[SASE](https://www.cisco.com/c/en/us/products/security/what-is-sase.html) / [Zero Trust](https://csrc.nist.gov/pubs/sp/800/207/final)** (12)
:   Servicio en la nube que combina red y seguridad / modelo de seguridad sin confianza implícita.

**[VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)** (12)
:   Red virtual definida en la infraestructura de un proveedor de nube.


## Fuentes oficiales y estándares

Las definiciones se enlazan, cuando existe una fuente normativa, a RFC del [RFC Editor](https://www.rfc-editor.org/), estándares de [IEEE 802](https://www.ieee802.org/), documentación del [kernel Linux](https://docs.kernel.org/networking/), manuales de Linux y documentación oficial de los proyectos o fabricantes correspondientes. Los enlaces abren la especificación o documentación primaria para ampliar cada concepto.
