---
title: "COMPARACIONES CONCEPTUALES"
description: "Once pares de conceptos que suelen confundirse en networking, comparados con una estructura común: definición, función, diferencias y ejemplo."
---

<p class="tema-eyebrow">REFERENCIA</p>

# COMPARACIONES CONCEPTUALES

Hay conceptos que se aprenden juntos, para ayudar a fortalecer y reforzar la teoría la siguiente sección compara con definiciones puntuales, los términos que se abordaron y pudiesen tener similitud o semejanza que infiera a una conclusión no correcta. Cada comparación sigue la misma estructura: **definición**, **función**, **diferencias** y **ejemplo de aplicación** en la serie.

## 1. Bridge frente a router

| | Bridge | Router |
|--|--------|--------|
| **Definición** | Equipo que reenvía **tramas Ethernet** según la MAC de destino. | Equipo que reenvía **paquetes IP** según la tabla de rutas. |
| **Función** | Unir segmentos dentro de **una misma red**. | **Interconectar redes distintas**. |
| **Diferencias** | Aprende MAC; no modifica la cabecera; un solo dominio de *broadcast*. | Consulta rutas; reescribe la cabecera Ethernet en cada salto; separa dominios de *broadcast*. |
| **Ejemplo** | `br0` del laboratorio 01. | R1, R2 y R3 del laboratorio 06. |

## 2. MAC frente a IP

| | MAC | IP |
|--|-----|----|
| **Definición** | Identificador de una **interfaz** en el enlace. | Dirección **lógica** de un equipo en una red. |
| **Función** | Entregar la trama al siguiente equipo del enlace. | Hacer llegar el paquete a su destino de extremo a extremo. |
| **Diferencias** | Solo vale en el enlace local; **un router la sustituye** en cada salto de capa 3, mientras que switches y bridges la conservan. | Se conserva de origen a destino (salvo NAT). |
| **Ejemplo** | `tcpdump -e` en el laboratorio 01. | `10.0.1.2 → 10.0.1.3`. |

## 3. Subred frente a VLAN

| | Subred | VLAN |
|--|--------|------|
| **Definición** | Rango de direcciones IP definido por una máscara. | Dominio de *broadcast* de capa 2 definido por etiquetas 802.1Q y puertos. |
| **Función** | Organizar el direccionamiento (capa 3). | Segmentar la red conmutada (capa 2). |
| **Diferencias** | Se separa con rutas. | Se separa con puertos y etiquetas; para comunicarse se necesita enrutar. |
| **Ejemplo** | `10.0.10.0/24` (laboratorio 04). | VLAN 10 «Ventas» (laboratorio 05). |

## 4. Switching frente a routing

| | Switching | Routing |
|--|-----------|---------|
| **Definición** | Decidir por MAC dentro de la red local. | Decidir por IP entre redes. |
| **Función** | Conectar equipos de la misma red. | Conectar redes. |
| **Diferencias** | Reenvío de tramas; aprendizaje de MAC. | Tablas de rutas, siguiente salto, TTL. |
| **Ejemplo** | Switch del laboratorio 03. | Rutas estáticas del laboratorio 06 y OSPF del 15. |

## 5. NAT frente a firewall

| | NAT | Firewall |
|--|-----|----------|
| **Definición** | **Traducción** de direcciones (y puertos). | **Filtrado** de tráfico según una política. |
| **Función** | Que redes privadas salgan con una dirección compartida, o publicar un servidor (DNAT). | Permitir o denegar flujos entre zonas. |
| **Diferencias** | Modifica paquetes; **no es una medida de seguridad por sí misma**. | Decide si el paquete pasa; puede llevar estado. |
| **Ejemplo** | `MASQUERADE` en R1 (laboratorios 02 y 07). | Reglas `FORWARD` con DMZ (laboratorio 08). |

## 6. GRE frente a IPsec

| | GRE | IPsec |
|--|-----|-------|
| **Definición** | Protocolo de **encapsulación** (IP 47). | Conjunto de protocolos de **protección** (ESP, IKE). |
| **Función** | Crear un enlace virtual entre redes no contiguas. | Cifrar, autenticar y verificar la integridad. |
| **Diferencias** | No cifra; admite multicast y enrutamiento dinámico. | Cifra; más complejo; sensible al NAT (NAT-T). |
| **Ejemplo** | Túnel R1–R2 (laboratorios 06 y 09). | ESP en modo túnel (laboratorio 09). |

## 7. TCP frente a UDP

| | TCP | UDP |
|--|-----|-----|
| **Definición** | Transporte **orientado a conexión**, fiable. | Transporte **sin conexión**, sin garantías. |
| **Función** | Entrega completa y ordenada. | Entrega rápida con poca sobrecarga. |
| **Diferencias** | *Handshake*, retransmisión, control de flujo. | Sin estado; la aplicación decide qué hacer con la pérdida. |
| **Ejemplo** | HTTPS, SSH. | DNS, DHCP. Laboratorio 07. |

## 8. ECMP frente a *failover*

| | ECMP | *Failover* |
|--|------|-----------|
| **Definición** | **Reparto** de tráfico entre caminos de igual coste. | **Conmutación** a un camino de respaldo cuando falla el principal. |
| **Función** | Capacidad y aprovechamiento de caminos. | Disponibilidad. |
| **Diferencias** | Varios caminos activos a la vez (por flujo). | Un camino activo y otro en espera. |
| **Ejemplo** | Rutas con la misma métrica (laboratorio 10). | Métrica 50 y métrica 100 (laboratorios 06 y 10). |

## 9. NOC frente a SIEM

| | NOC | SIEM |
|--|-----|------|
| **Definición** | Centro que **opera** la infraestructura. | Plataforma que **correlaciona eventos de seguridad**. |
| **Función** | Disponibilidad y rendimiento. | Detección de incidentes de seguridad. |
| **Diferencias** | Pregunta «¿funciona?». | Pregunta «¿hay un patrón anómalo?». |
| **Ejemplo** | `ping`, `mtr`, `iperf3` (laboratorio 13). | Colector `rsyslog` (laboratorio 13): solo la parte de **recolección**. |

## 10. Zero Trust frente a ZTNA

| | Zero Trust | ZTNA |
|--|------------|------|
| **Definición** | **Modelo** de seguridad: no confiar por estar «dentro». | **Tecnología** de acceso remoto por aplicación. |
| **Función** | Guiar el diseño de la seguridad. | Aplicar el acceso mínimo a cada aplicación. |
| **Diferencias** | Es un conjunto de principios. | Es una implementación concreta (con un broker). |
| **Ejemplo** | Principios de NIST SP 800-207. | Broker con política por aplicación (laboratorio 12). |

## 11. VRRP frente a OSPF

| | VRRP | OSPF |
|--|------|------|
| **Definición** | Protocolo de **redundancia de *gateway*** (IP virtual). | Protocolo de **enrutamiento dinámico** (estado de enlace). |
| **Función** | Que los **hosts** conserven un *gateway*. | Que los **routers** conozcan y recalculen la topología. |
| **Diferencias** | Actúa en una LAN; no aprende rutas. | Actúa entre routers; no da un *gateway* a los hosts. |
| **Ejemplo** | IP virtual `10.0.0.1` (15.7). | Adyacencia R1–R2 (15.4). |

!!! info "No compiten: se complementan"
    VRRP y OSPF resuelven problemas **distintos**. En el laboratorio 15 conviven: OSPF mantiene las rutas entre routers y VRRP mantiene el *gateway* de los servidores.

Véase también: [Servicios, protocolos y puertos](servicios-puertos.md).
