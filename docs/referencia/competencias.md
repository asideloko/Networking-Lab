---
title: "COMPETENCIAS Y CASOS INTEGRADORES"
description: "Competencias que desarrolla NETWORKING Lab y casos integradores para repasar la serie."
---

<p class="tema-eyebrow">REFERENCIA</p>

# COMPETENCIAS Y CASOS INTEGRADORES

Completar los 15 laboratorios **no convierte** automáticamente a una persona en administradora de redes empresariales. Esta página lista las **competencias que el contenido pretende desarrollar**; no es una certificación de dominio práctico.

## Competencias esperadas al finalizar la serie

| Competencia | Qué debería poder hacer quien termina | Laboratorios |
|-------------|----------------------------------------|--------------|
| **Fundamentos** | Explicar cómo se comunican los dispositivos: Ethernet, ARP, IP y protocolos básicos | 01–03 |
| **Direccionamiento** | Diseñar esquemas IPv4, calcular subredes y comprender la segmentación | 04, 05, 15 |
| **Infraestructura** | Diferenciar las funciones de switches, routers, firewalls y componentes WAN | 03, 05, 08, 10 |
| **Conectividad** | Comprender rutas, enrutamiento estático y dinámico, túneles y VPN | 06, 09, 15 |
| **Servicios** | Explicar DNS, DHCP, TCP, UDP y NAT | 07 |
| **Seguridad** | Comprender filtrado, DMZ, cifrado, control de acceso y microsegmentación | 08, 09, 12 |
| **Arquitectura** | Interpretar arquitecturas empresariales, de nube e híbridas | 10, 11, 12 |
| **Operación** | Usar herramientas Linux para consultar, observar y diagnosticar redes | 13, 14 |
| **Disponibilidad** | Comprender redundancia, ECMP, OSPF y VRRP, y reconocer sus límites | 06, 10, 11, 15 |
| **Integración** | Relacionar todos estos mecanismos en una infraestructura empresarial | 15 |

## Evidencias verificables de competencia

La tabla anterior expresa resultados esperados, no certificaciones. Para demostrar dominio, cada competencia debe acompañarse de evidencia reproducible:

| Competencia | Evidencia mínima | Criterio de aceptación |
|---|---|---|
| Fundamentos | Captura ARP/Ethernet/ICMP y FDB antes/después | Explica ruta local, aprendizaje por MAC origen y reenvío |
| Direccionamiento | Cálculo VLSM, tabla sin solapamientos y `ip route get` | Justifica prefijos, rangos, gateway y decisión local/remota |
| Infraestructura | Diagrama por capas y matriz VLAN/zonas | Distingue switching, routing, firewall y transporte |
| Conectividad | RIB/rutas, prueba de fallo y captura GRE/IPsec | Explica selección de ruta, encapsulación y límites |
| Servicios | Captura DHCP/DNS/TCP/UDP y conntrack | Interpreta lease, TTL, respuesta DNS y tuplas NAT |
| Seguridad | Matriz de flujos permitidos/denegados y prueba SSH/TLS | Valida identidad y justifica mínimo privilegio |
| Arquitectura | Diagrama que marca implementado/simulado/conceptual | No atribuye propiedades no demostradas a la simulación |
| Operación | Informe de incidente con línea temporal y capturas | Hipótesis, evidencia, causa, corrección y verificación |
| Disponibilidad | Medición de detección, pérdida y recuperación | Distingue routing, STP/RSTP y VRRP |
| Integración | Memoria técnica final y pruebas de reversión | Justifica decisiones y deja el entorno en estado conocido |

### Rúbrica del proyecto final

| Dimensión | Peso |
|---|---:|
| Diseño y direccionamiento | 15% |
| Routing y conectividad | 15% |
| Servicios de red | 10% |
| Seguridad | 15% |
| Disponibilidad | 10% |
| Monitoreo y diagnóstico | 15% |
| Pruebas y reversión | 10% |
| Documentación y justificación | 10% |
| **Total** | **100%** |

Se evalúa tanto el resultado como la explicación causal. Una topología que responde a `ping` no demuestra por sí sola que DNS, seguridad, redundancia o reversión estén correctos.

## Caso integrador del bloque 2 (laboratorios 06–10)

Resuélvelo **con diagramas, tablas y razonamiento**; no hace falta construir otra topología.

> Una sucursal nueva abre con 20 empleados. Explica, paso a paso: (1) cómo **obtiene conectividad** con la sede, (2) cómo cada equipo **obtiene su dirección y resuelve nombres**, (3) cómo se **controla** qué puede alcanzar, y (4) cómo se comunica de forma **segura** con la sede.

Debes poder señalar, en cada paso, **qué mecanismo interviene** (rutas o túnel, DHCP y DNS, firewall, VPN) y **qué falla si ese mecanismo se omite**. Apóyate en el [mapa integral](arquitectura-integral.md) y en la [matriz de servicios y puertos](servicios-puertos.md).

## Caso integrador final (serie completa)

> Una empresa con **varias sedes**, **infraestructura híbrida** y **aplicaciones críticas** pide un informe.

Explica:

1.  **Cómo está organizada** la red (capas, zonas, sedes, nube).
2.  **Qué mecanismos mantienen la conectividad** (rutas, OSPF, túneles).
3.  **Cómo se controla el acceso** (firewall, DMZ, microsegmentación, ZTNA).
4.  **Cómo se supervisan** los servicios (NOC, registros, métricas, alertas).
5.  **Qué sucede ante distintos fallos** (usa la [matriz de disponibilidad](arquitectura-integral.md)).
6.  **Qué herramientas diagnostican cada situación** (usa el [método de diagnóstico](diagnostico.md)).
