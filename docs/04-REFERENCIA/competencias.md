---
title: "COMPETENCIAS Y CASOS INTEGRADORES"
description: "Competencias que desarrolla NETWORKING Lab y casos integradores para repasar la serie."
---

<p class="tema-eyebrow">REFERENCIA</p>

# COMPETENCIAS Y CASOS INTEGRADORES

Completar los quince laboratorios te acerca a las tareas de un administrador de redes, pero **no es una certificación**: el material se diseñó con un único fin, **enseñar**. Esta página lista las **competencias que el contenido pretende desarrollar** y propone dos casos para repasarlas. Las competencias se demuestran por completo en el [Proyecto final](../03-PROYECTO-FINAL/index.md).

## Competencias esperadas al finalizar la serie

| Competencia          | Qué debería poder hacer quien termina                                               | Laboratorios   |
| -------------------- | ----------------------------------------------------------------------------------- | -------------- |
| **Fundamentos**      | Explicar cómo se comunican los dispositivos: Ethernet, ARP, IP y protocolos básicos | 01–03          |
| **Direccionamiento** | Diseñar esquemas IPv4, calcular subredes y comprender la segmentación               | 04, 05, 15     |
| **Infraestructura**  | Diferenciar las funciones de switches, routers, firewalls y componentes WAN         | 03, 05, 08, 10, 11 |
| **Conectividad**     | Comprender rutas, enrutamiento estático y dinámico, túneles y VPN                   | 06, 09, 15     |
| **Servicios**        | Explicar DNS, DHCP, TCP, UDP y NAT                                                  | 07, 15         |
| **Seguridad**        | Comprender filtrado, DMZ, cifrado, control de acceso y microsegmentación            | 08, 09, 11, 12 |
| **Arquitectura**     | Interpretar arquitecturas empresariales, de nube e híbridas                         | 10, 11, 12     |
| **Operación**        | Usar herramientas Linux para consultar, observar y diagnosticar redes               | 13, 14         |
| **Disponibilidad**   | Comprender redundancia, ECMP, OSPF y VRRP, y reconocer sus límites                  | 06, 10, 11, 15 |
| **Integración**      | Relacionar todos estos mecanismos en una infraestructura empresarial                | 15             |

## Práctica 1: una sucursal nueva

Resuélvelo **con diagramas, tablas y razonamiento**; no hace falta construir otra topología.

> Una sucursal nueva abre con 20 empleados. Explica, paso a paso: (1) cómo **obtiene conectividad** con la sede, (2) cómo cada equipo **obtiene su dirección y resuelve nombres**, (3) cómo se **controla** qué puede alcanzar, y (4) cómo se comunica de forma **segura** con la sede.

Se deberá poder señalar, en cada paso, **qué mecanismo interviene** (rutas o túnel, DHCP y DNS, firewall, VPN) y **qué falla si ese mecanismo se omite**. Apóyate en el [mapa integral](arquitectura-integral.md) y en la [matriz de servicios y puertos](servicios-puertos.md).

## Práctica 2: informe de una empresa híbrida

> Una empresa con **varias sedes**, **infraestructura híbrida** y **aplicaciones críticas** pide un informe.

Explica:

1.  **Cómo está organizada** la red (capas, zonas, sedes, nube).
2.  **Qué mecanismos mantienen la conectividad** (rutas, OSPF, túneles).
3.  **Cómo se controla el acceso** (firewall, DMZ, microsegmentación, ZTNA).
4.  **Cómo se supervisan** los servicios (NOC, registros, métricas, alertas).
5.  **Qué sucede ante distintos fallos** (usa la [matriz de disponibilidad](arquitectura-integral.md)).
6.  **Qué herramientas diagnostican cada situación** (usa el [método de diagnóstico](diagnostico.md)).
