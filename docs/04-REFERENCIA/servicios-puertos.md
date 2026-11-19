---
title: "SERVICIOS, PROTOCOLOS Y PUERTOS"
description: "Matriz de referencia de los servicios, protocolos y puertos que aparecen en los 15 laboratorios de NETWORKING Lab."
---

<p class="tema-eyebrow">REFERENCIA</p>

# SERVICIOS, PROTOCOLOS Y PUERTOS

Una referencia común para consultar **qué protocolo usa cada servicio, por dónde viaja y dónde se practica**. Sirve también para **escribir reglas de firewall sin olvidar protocolos de control** (el error más habitual: permitir el servicio pero no el protocolo que lo sostiene).

!!! info "Puerto frente a número de protocolo"
    TCP y UDP identifican los servicios con **puertos**. Otros protocolos (GRE, ESP, OSPF, VRRP) viajan **directamente sobre IP** y se identifican con un **número de protocolo IP**: no tienen puertos, así que una regla `--dport` no los alcanza.

## Servicios de aplicación

| Servicio | Transporte | Puerto | Función | Laboratorios |
|----------|-----------|--------|---------|--------------|
| **DNS** | UDP (TCP para respuestas grandes y transferencias de zona) | 53 | Resolver nombres a direcciones | 07, 08, 12 |
| **DHCP** | UDP | 67 (servidor), 68 (cliente) | Entregar dirección, máscara, *gateway* y DNS | 07, 15 |
| **HTTP** | TCP | 80 | Web en claro | 08 |
| **HTTPS** (TLS) | TCP | 443 | Web cifrada y autenticada por certificado | 08 |
| **SSH** | TCP | 22 | Administración remota cifrada | 08, 15 |
| **SMTP** | TCP | 25 | Envío de correo entre servidores (referido en la política de 15.5) | 15 |
| **Syslog** | UDP (o TCP) | 514 | Centralizar registros | 13 |
| **iperf3** | TCP/UDP | 5201 | Medir rendimiento | 13 |

## Protocolos de red y control

| Protocolo | Va sobre | Identificador | Función | Laboratorios |
|-----------|----------|---------------|---------|--------------|
| **ARP** | Directamente sobre Ethernet | EtherType `0x0806` | Resolver IP → MAC en la red local | 01, 15 |
| **ICMP** | IP | Protocolo 1 | Diagnóstico y control (`ping`, *Time Exceeded*) | 01, 06 |
| **OSPF** | IP | Protocolo 89 | Enrutamiento dinámico (adyacencias, LSDB, SPF) | 15 |
| **VRRP** | IP | Protocolo 112 | Redundancia de *gateway* (IP virtual) | 15 |

## Túneles y VPN

| Tecnología | Va sobre | Identificador | Protege el contenido | Laboratorios |
|------------|----------|---------------|----------------------|--------------|
| **GRE** | IP | Protocolo 47 | No (solo encapsula) | 06, 09 |
| **IPsec ESP** | IP | Protocolo 50 | Sí (cifra y autentica) | 09 |
| **IKE** | UDP | 500 | Negociación de claves de IPsec (aquí, claves manuales) | 09 |
| **NAT-T** | UDP | 4500 | ESP dentro de UDP cuando hay NAT en el camino | 09 |
| **OpenVPN** | UDP (o TCP) | 1194 (el del laboratorio) | Sí (TLS; aquí, clave estática de demostración) | 09 |
| **WireGuard** | UDP | 51820 (el del laboratorio, configurable) | Sí (pares de claves) | 09 |

## Cómo usar esta matriz al diseñar una política

1.  **Lista los servicios** que deben funcionar (columna «Servicio»).
2.  **Añade los protocolos de control** que los sostienen: OSPF y VRRP en la cadena `input` del router; UDP 67 para DHCP; ICMP para diagnóstico.
3.  **Distingue la dirección del tráfico**: lo que va **al** equipo (`input`), lo que lo **atraviesa** (`forward`) y lo que **genera** (`output`).
4.  **Documenta cada regla** con el servicio al que responde. Una regla sin justificación es una deuda de seguridad.

Véase también: [Comparaciones conceptuales](comparaciones.md) y [Método de diagnóstico](diagnostico.md).
