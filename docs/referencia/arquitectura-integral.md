---
title: "ARQUITECTURA INTEGRAL Y MAPAS DE SÍNTESIS"
description: "Mapa integral de una infraestructura empresarial, comparación de tecnologías de conectividad, mapa de seguridad y matriz de disponibilidad de NETWORKING Lab."
---

<p class="tema-eyebrow">REFERENCIA</p>

# ARQUITECTURA INTEGRAL Y MAPAS DE SÍNTESIS

Los laboratorios usan topologías distintas a propósito: cada uno aísla un mecanismo. Estos mapas **reúnen las piezas** para ver la infraestructura como un **sistema** y no como una colección de dispositivos. No sustituyen las topologías particulares ni son una configuración ejecutable: son un **esquema conceptual**.

## Mapa integral de una infraestructura empresarial

```mermaid
graph TB
    subgraph Remoto["Usuarios remotos"]
        U["Usuario remoto"]
    end
    subgraph Nube["Nube e infraestructura híbrida"]
        VPC["VPC (subredes pública y privada)"]
    end
    subgraph WAN["Red WAN / proveedor"]
        PE["PE / P: núcleo del proveedor"]
    end
    subgraph Sede["Sede central"]
        FW["Firewall perimetral"]
        DMZ["DMZ: servidores públicos"]
        CORE["Core"]
        DIST["Distribución (gateway, políticas)"]
        ACC["Acceso (VLAN)"]
        NOC["NOC y colector de logs"]
    end
    subgraph Suc["Sucursales"]
        RS["Router de sucursal"]
    end
    U -->|"ZTNA / VPN"| FW
    FW --- DMZ
    FW --- CORE
    CORE --- DIST --- ACC
    NOC -.-|"supervisa"| CORE
    FW ---|"WAN"| PE
    PE --- RS
    RS ---|"túnel GRE/IPsec"| FW
    FW ---|"conectividad híbrida"| VPC
```

| Zona | Función | Laboratorios |
|------|---------|--------------|
| Acceso, Distribución, Core | Conectar equipos, segmentar y transportar | 03, 05, 11 |
| Firewall y DMZ | Controlar el tráfico entre zonas | 08, 11 |
| Sucursales y túneles | Extender la red a otras sedes | 06, 09 |
| WAN / proveedor | Transporte entre sedes | 10 |
| Nube y acceso remoto | Entornos modernos y Zero Trust | 12 |
| NOC y colector | Observar y diagnosticar | 13, 14 |

## Comparación de tecnologías de conectividad

| Tecnología | Qué resuelve | Cifra | Complejidad | Dónde se practica |
|------------|--------------|-------|-------------|-------------------|
| **Rutas estáticas** | Conectar redes con caminos fijos | No | Baja; no escala | 06, 10 |
| **GRE** | Enlace virtual entre redes no contiguas | No | Baja | 06, 09 |
| **IPsec** | Proteger tráfico entre sedes | Sí | Alta (claves, políticas, NAT-T) | 09 |
| **OpenVPN** | VPN de acceso remoto o sitio a sitio | Sí | Media (PKI en producción) | 09 |
| **WireGuard** | VPN ligera basada en pares de claves | Sí | Baja | 09 |
| **MPLS** | Transporte del proveedor con servicios (L3VPN, QoS) | No por defecto | Alta; lo opera el proveedor | 10 (conceptual) |
| **SD-WAN** | Gestión por políticas sobre varios transportes | Según diseño | Media; control centralizado | 10 (conceptual) |

## Mapa de seguridad y flujo del tráfico

Qué zonas se comunican, quién controla y dónde se aplica la política:

```mermaid
flowchart LR
    NET((Internet)) -->|"solo servicios publicados"| FW["Firewall"]
    FW -->|"80/443/53 al servidor correspondiente"| DMZ["DMZ"]
    FW -.->|"denegado"| LAN
    LAN["LAN interna"] -->|"permitido con NAT"| FW
    LAN -->|"ICMP, SSH, HTTPS limitados"| DMZ
    DMZ -.->|"denegado"| LAN
    REM["Usuario remoto"] -->|"acceso por aplicación (ZTNA)"| BR["Broker"]
    BR --> APP["Aplicación concreta"]
```

Principios que se repiten: **denegar por defecto**, permitir solo el flujo necesario (**mínimo privilegio**), **no confiar** en la ubicación del origen y **dejar rastro** de lo denegado.

## Matriz de disponibilidad

| Componente | Fallo posible | Mecanismo relacionado | Se practica en |
|------------|---------------|------------------------|----------------|
| Enlace | Pérdida de conectividad | Ruta alternativa (métrica) | 06, 10, 11 |
| Router | Pérdida de *gateway* | VRRP | 15 |
| Ruta | Pérdida de camino | OSPF (reconvergencia) | 15 |
| Servicio | Aplicación inaccesible | Monitoreo y diagnóstico | 13, 14 |
| Segmento | Acceso no autorizado | Firewall y microsegmentación | 08, 12 |
| Salida WAN | Pérdida de Internet con el *gateway* vivo | WAN independiente y seguimiento (`track`) | 15 (caso B) |

!!! warning "Disponibilidad no es presencia de equipos duplicados"
    Un equipo de respaldo solo aporta disponibilidad si hay un mecanismo que **detecte el fallo** y **mueva el tráfico**, y si el respaldo **no comparte** el mismo punto único de fallo (la misma WAN, el mismo *switch*).

Véase también: [Comparaciones conceptuales](comparaciones.md) · [Método de diagnóstico](diagnostico.md).
