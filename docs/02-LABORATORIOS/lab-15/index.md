---
title: "LABORATORIO 15 · IMPLEMENTACIÓN PRÁCTICA INTEGRAL"
description: "Laboratorio 15 de NETWORKING Lab — Implementación Práctica Integral."
---

<p class="tema-eyebrow">LABORATORIO 15</p>

# IMPLEMENTACIÓN PRÁCTICA INTEGRAL

<p class="tema-meta"><span>29 secciones</span><span>3 diagramas</span><span>18 tablas</span></p>

## El cierre del recorrido

Networking SecOps ha recorrido todos los laboratorios anteriores y ahora debe integrar en una topología ejecutable los mecanismos centrales de este cierre: direccionamiento VLSM, enrutamiento dinámico con OSPF, firewall, DHCP/NAT y redundancia parcial del *gateway* con VRRP. **No es una única implementación de las quince tecnologías**: VLAN, DNS corporativo, VPN, MPLS, nube real, ZTNA y NOC/SIEM se practicaron en escenarios previos o se tratan como variantes y apartados conceptuales; el alcance exacto se detalla en 15.10.

## Introducción técnica

El último laboratorio parte de un entorno vacío y construye una infraestructura multisede: una sede principal con varios segmentos, una sucursal, servicios de red, enrutamiento dinámico, políticas de seguridad y redundancia parcial. Termina con una red implementada, verificada y sometida a escenarios controlados de fallo.

La construcción es progresiva. Cada apartado funciona por sí mismo y añade un mecanismo: direccionamiento VLSM, rutas estáticas y después OSPF con FRRouting, filtrado con `nftables` y NAT, DHCP y DNS, y VRRP para el *gateway* del segmento de servidores. Después se diagnostican fallos reales y se evalúan los límites de la integración.


!!! note "Mismo modelo que el resto de la serie"
    Todo se construye con **namespaces de red**, igual que en los laboratorios anteriores (las interfaces de la práctica son virtuales). **Algunos pasos sí modifican el host**: el reenvío IPv4, una regla NAT y, en un caso de diagnóstico, un archivo persistente en `/etc/sysctl.d`. Están marcados como «Cambio en el host» y se revierten en la sección «Limpieza del laboratorio». Es un laboratorio de integración con una topología nueva, por lo que empieza limpiando el entorno. Requiere instalar `frr` (OSPF), `keepalived` (VRRP), `dnsmasq-base` (DHCP/DNS) y `dnsutils` para las pruebas con `dig`.

!!! note "Este es un escenario nuevo"
    Los laboratorios 01–14 usaron topologías diferentes. Aquí **se reutilizan los nombres `R1` y `R2` con otra función y otro direccionamiento** (sede y respaldo/sucursal), y el escenario se construye desde cero. Cada apartado funciona por sí mismo, pero la coherencia global se comprueba en el apartado «Coherencia del conjunto» al final: que cada bloque funcione aisladamente no garantiza que el conjunto sea coherente.

## Objetivos de aprendizaje

Al terminar este laboratorio deberías poder:

- integrar VLSM, rutas, OSPF, firewall con `nftables`, NAT, DHCP, DNS y VRRP en una red multisede construida por etapas;
- explicar qué protege VRRP y qué queda sin proteger;
- interpretar la reconvergencia de OSPF al caer el enlace principal;
- diagnosticar fallos (MTU, vecinos ARP, rutas) con el método de diagnóstico y evaluar la coherencia del conjunto.

### Conocimientos previos y relación con la práctica anterior

- **Conocimientos previos:** Es una práctica integradora: presupone lo aprendido en los laboratorios 01 a 14 (direccionamiento, enrutamiento, servicios, firewall, VPN y diagnóstico) y no explica de nuevo esos conceptos desde cero. Cuando conviene, remite al laboratorio correspondiente.
- **Relación con la práctica anterior:** *Nueva topología.* Parte de un entorno vacío y construye el escenario desde cero. Reutiliza los nombres `R1` y `R2` con otra función y otro direccionamiento, y empieza limpiando solo los recursos propios de Lab15.

## Mapa de conceptos y ruta de lectura

| Nivel | Contenido |
|-------|-----------|
| **Concepto principal** | Integrar mecanismos ya conocidos y comprobar que son coherentes entre sí, no aprender tecnologías nuevas |
| **Conceptos secundarios** | Dependencias entre servicios, tráfico de control que debe permitir el firewall, alcance real de la redundancia |
| **Novedad de la práctica** | OSPF con FRRouting, que aparece por primera vez en la serie; el resto repasa laboratorios anteriores (VRRP ya se probó en el laboratorio 11) |
| **Reservado para otras prácticas** | VLAN completa, VPN, MPLS y SD-WAN: se estudian antes y no se integran en ejecución |

La práctica se construye por etapas. Cada una funciona por sí misma y añade un mecanismo; la tabla siguiente muestra qué depende de qué y cuándo conviene detenerse a comprobar.

## Etapas, dependencias y puntos de control

| Etapa | Qué añade | Depende de | Punto de control antes de seguir | Se explica en |
|-------|-----------|------------|----------------------------------|----------------|
| **15.1** Configuración básica | WAN de R1, NAT y primera LAN | El host que actúa como «Internet» | La verificación de conectividad WAN | Laboratorio 02 |
| **15.2** VLSM | Plan de `10.0.0.0/22` y todos los segmentos | 15.1 | Cada equipo alcanza su *gateway* y a los demás a través de R1 | Laboratorio 04 |
| **15.3** VLAN | Variante conceptual con *trunk* | No se integra | No hay verificación: no se mezcla con las demás etapas | Laboratorio 05 |
| **15.4** Enrutamiento | Rutas estáticas y después OSPF | 15.2 | Vecinos en estado `Full` y rutas aprendidas | Laboratorio 06 (estáticas); OSPF, aquí |
| **15.5** Firewall | Política con `nftables` y reglas de comunicación | 15.4 (debe permitir OSPF) | Segmentación y políticas verificadas | Laboratorios 08 y 14 |
| **15.6** Servicios | DHCP y DNS con `dnsmasq` | 15.2 y 15.5 (debe permitir UDP 67) | Los clientes reciben dirección y resuelven nombres | Laboratorio 07 |
| **15.7** VRRP | IP virtual del *gateway* de servidores | 15.2 y 15.5 (debe permitir el protocolo 112) | El *failover* del *gateway* funciona | Laboratorio 11 |
| **15.8** Diagnóstico | Casos de MTU y de tabla de vecinos | Todo lo anterior | Cada caso se resuelve con evidencia | Laboratorios 09, 13 y 14 |
| **15.9** Dependencias y fallos | Matriz de dependencias, escenarios de fallo y caso final | Todo lo anterior | Se explica la causa común de la incidencia combinada | Método de diagnóstico |

**Ruta recomendada en una primera lectura:** 15.1, 15.2, 15.4, 15.5 y 15.9. La etapa 15.3 es conceptual y puede omitirse sin perder el hilo; 15.6 a 15.8 se abordan cuando ya funcionan las anteriores.

## Estado inicial

- Hay una sede y una sucursal por construir desde cero, sin direccionamiento ni servicios.
- Se necesita direccionamiento sin solapamientos, caminos que se recalculan solos, tráfico controlado, configuración automática de equipos y un *gateway* que no sea un punto único de fallo.
- Cuando la red falla, el diagnóstico debe apoyarse en evidencias.

## Resultado que se construirá

Queda una red de sede y sucursal con direccionamiento VLSM, enlaces `/30` principal y de respaldo, OSPF, firewall con `nftables`, NAT, DHCP y DNS en R1, y VRRP en el segmento de servidores. Se prueban la reconvergencia al caer el enlace principal, la caída del *gateway* de servidores y varios fallos de diagnóstico (MTU, vecinos ARP, rutas), y se documenta qué componentes no están protegidos.

## Topología

```mermaid
graph TB
    Internet((Internet host))
    R1[R1 Sede]
    R2[R2 Respaldo y Sucursal]
    SW[Switch Servidores]
    FIN[Finanzas]
    VEN[Ventas]
    GES[Gestion]
    SRV[Servidores]
    SUC[Sucursal]
    Internet --- R1
    R1 --- FIN
    R1 --- VEN
    R1 --- GES
    R1 ---|Enlace A y B| R2
    R1 --- SW
    R2 --- SW
    SW --- SRV
    R2 --- SUC
```

### Mapa del escenario: redes, *gateways* y caminos

El diagrama anterior muestra los equipos; este muestra **qué red cuelga de cada interfaz** y **por dónde puede viajar** el tráfico. Es la referencia visual para leer los apartados 15.1 a 15.8:

```mermaid
graph TB
    NET((Internet: el host 192.168.100.2))
    subgraph R1["R1 (sede)"]
        W1["WAN veth-r1-wan 192.168.100.1"]
        F1["Finanzas .1 (10.0.1.0/25)"]
        V1["Ventas .129 (10.0.1.128/26)"]
        G1["Gestión .193 (10.0.1.192/28)"]
        S1["Servidores veth-r1srv (10.0.0.0/24)"]
    end
    subgraph R2["R2 (respaldo y sucursal)"]
        S2["Servidores veth-r2srv"]
        SU["Sucursal .1 (10.0.2.0/24)"]
    end
    NET --- W1
    R1 ===|"Enlace A 10.0.1.208/30 (principal)"| R2
    R1 -.-|"Enlace B 10.0.1.212/30 (respaldo)"| R2
    S1 --- SW[Switch de servidores]
    S2 --- SW
```

Tres ideas para leerlo: (1) la **única salida a Internet** es la WAN de R1 (R2 sale por R1); (2) hay **dos caminos** R1–R2 (A principal, B respaldo) y OSPF decide cuál usar; (3) el **segmento de servidores es compartido** por R1 y R2, y es ahí donde VRRP mueve la IP virtual del *gateway*.

## Construcción

### Paso 0: Limpiar ejecuciones anteriores de Lab15

Este paso solo puede retirar recursos de una ejecución anterior de Lab15. **No elimina namespaces ni interfaces de otros laboratorios**, no toca `br-wan` y no retira `veth-host`, `veth-wan-fw`, `veth-wan-cvpn` ni `veth-wan-op`. Se ejecuta primero la reversión de cada laboratorio anterior para restaurar sus propias rutas, reglas y parámetros del host.

```bash
NS_LAB="R1 R2 SWsrv fin ven ges srv suc"
EXISTENTES=$(sudo ip netns list | awk '{print $1}' | while read -r ns; do
  for esperado in $NS_LAB; do [ "$ns" = "$esperado" ] && echo "$ns"; done
done)
for ns in $EXISTENTES; do
  if [ "$(sudo ip netns exec "$ns" cat /sys/class/net/lo/ifalias 2>/dev/null)" != networking-lab-lab-15 ]; then
    echo "Se aborta: $ns no tiene la marca exclusiva de Lab15; ejecuta la limpieza de su laboratorio propietario."
    exit 1
  fi
  PIDS=$(sudo ip netns pids "$ns" 2>/dev/null || true)
  if [ -n "$PIDS" ]; then echo "$ns tiene procesos activos ($PIDS); ejecuta la limpieza antes de repetir Lab15."; exit 1; fi
done
if [ -e /tmp/lab15 ]; then echo "/tmp/lab15 existe; ejecuta la limpieza completa de Lab15 antes de repetirlo."; exit 1; fi
for f in /tmp/lab15-ip_forward.orig /tmp/lab15-host-nat.added /tmp/lab15-forward-out.added /tmp/lab15-forward-in.added; do
  if [ -e "$f" ]; then echo "Existe el marcador $f; ejecuta la reversión completa de Lab15 antes de repetirlo."; exit 1; fi
done
if [ -e /sys/class/net/veth-wan-r1 ] && [ "$(cat /sys/class/net/veth-wan-r1/ifalias 2>/dev/null)" != networking-lab-lab-15 ]; then
  echo "veth-wan-r1 existe sin marca exclusiva de Lab15; se aborta sin modificarla."; exit 1
fi
for ns in $EXISTENTES; do sudo ip netns del "$ns" 2>/dev/null || true; done
if [ "$(cat /sys/class/net/veth-wan-r1/ifalias 2>/dev/null)" = networking-lab-lab-15 ]; then sudo ip link del veth-wan-r1; fi
```

Si aparece un namespace `R1` o `R2` de otra práctica, no lo borres aquí: ejecuta la reversión de esa práctica primero.
## 15.1 Configuración de red básica

R1 es el router de la sede: una WAN hacia el host (que hace de "Internet"), NAT, y su primera LAN (Finanzas).

La WAN une R1 con el **host** (sin namespace), así que se configura a mano:

```bash
sudo ip link add veth-r1-wan type veth peer name veth-wan-r1
sudo ip link set veth-r1-wan alias networking-lab-lab-15
sudo ip link set veth-wan-r1 alias networking-lab-lab-15
sudo ip link set veth-r1-wan netns R1
sudo ip netns exec R1 ip addr add 192.168.100.1/24 dev veth-r1-wan
sudo ip netns exec R1 ip link set veth-r1-wan up
sudo ip addr add 192.168.100.2/24 dev veth-wan-r1
sudo ip link set veth-wan-r1 up

# R1: ruta por defecto hacia el host y NAT hacia la WAN
sudo ip netns exec R1 ip route add default via 192.168.100.2
sudo ip netns exec R1 iptables -t nat -A POSTROUTING -o veth-r1-wan -j MASQUERADE

# El host reenvía y traduce hacia la red real (cambia eth0 por tu interfaz de salida)
# Guarda el valor original de ip_forward: la limpieza lo restaura
mkdir -p /tmp/lab15
sysctl -n net.ipv4.ip_forward > /tmp/lab15/ip_forward.orig
sudo sysctl -w net.ipv4.ip_forward=1
if ! sudo iptables -C FORWARD -i veth-wan-r1 -o eth0 -s 192.168.100.0/24 -j ACCEPT; then
  sudo iptables -I FORWARD 1 -i veth-wan-r1 -o eth0 -s 192.168.100.0/24 -j ACCEPT && touch /tmp/lab15/host-forward-out.added
fi
if ! sudo iptables -C FORWARD -i eth0 -o veth-wan-r1 -d 192.168.100.0/24 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; then
  sudo iptables -I FORWARD 1 -i eth0 -o veth-wan-r1 -d 192.168.100.0/24 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT && touch /tmp/lab15/host-forward-in.added
fi
if ! sudo iptables -t nat -C POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE; then
  sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE && touch /tmp/lab15-host-nat.added
fi

# Primera LAN: Finanzas (10.0.1.0/25)
enlace R1 veth-r1fin 10.0.1.1/25 fin veth-fin 10.0.1.10/25
sudo ip netns exec fin ip route add default via 10.0.1.1
```

!!! danger "Cambio en el host en este apartado"
    Los comandos `sudo ip addr add … dev veth-wan-r1`, `sudo sysctl -w net.ipv4.ip_forward=1` e `iptables -t nat … -o eth0 -j MASQUERADE` **se ejecutan en el equipo real**, no dentro de un namespace (los de `ip netns exec R1 …` sí están aislados). El valor original de `ip_forward` y la creación de la regla NAT quedan registrados para revertirlos al terminar.

### Verificar conectividad WAN

```bash
sudo ip netns exec fin ping -c 3 10.0.1.1
sudo ip netns exec fin ping -c 3 192.168.100.2
```

(Con Internet en el equipo, `ping 8.8.8.8` y `nslookup google.com 8.8.8.8` desde `fin` también funcionan.)

## 15.2 Subnetting aplicado (VLSM)

**Bloque disponible:** `10.0.0.0/22` (de `10.0.0.0` a `10.0.3.255`).

| Departamento | Hosts | Subred | Máscara | Rango útil | Gateway |
|--------------|-------|--------|---------|------------|---------|
| Servidores | 200 | 10.0.0.0/24 | /24 | 10.0.0.1 - 10.0.0.254 | 10.0.0.1 |
| Sucursal (R2) | 200 | 10.0.2.0/24 | /24 | 10.0.2.1 - 10.0.2.254 | 10.0.2.1 |
| Finanzas | 100 | 10.0.1.0/25 | /25 | 10.0.1.1 - 10.0.1.126 | 10.0.1.1 |
| Ventas | 50 | 10.0.1.128/26 | /26 | 10.0.1.129 - 10.0.1.190 | 10.0.1.129 |
| Gestión | 10 | 10.0.1.192/28 | /28 | 10.0.1.193 - 10.0.1.206 | 10.0.1.193 |
| Enlace A R1-R2 | 2 | 10.0.1.208/30 | /30 | 10.0.1.209 - 10.0.1.210 | - |
| Enlace B R1-R2 | 2 | 10.0.1.212/30 | /30 | 10.0.1.213 - 10.0.1.214 | - |

**Algoritmo VLSM que debe poder reproducir el lector:**

1. Ordenar las necesidades de mayor a menor cantidad de hosts (incluyendo redes del mismo tamaño).
2. Para cada segmento, sumar red y broadcast (`hosts + 2`) y redondear al siguiente tamaño potencia de dos.
3. Calcular el prefijo: `32 − log2(tamaño del bloque)`; comprobar que el bloque queda alineado en su frontera de red.
4. Asignar cada bloque dentro de `10.0.0.0/22`, sin solapamientos, reservando espacio de crecimiento.
5. Verificar red, broadcast, rango útil, gateway y máscara de cada segmento.

Ejemplos: 200 hosts requieren 202 direcciones → bloque 256 → `/24`; 100 requieren 102 → bloque 128 → `/25`; 50 requieren 52 → bloque 64 → `/26`; 10 requieren 12 → bloque 16 → `/28`; un enlace punto a punto con 2 hosts requiere 4 direcciones → `/30`. El orden de la tabla sigue el tamaño descendente; la red `10.0.3.0/24` y el resto libre de `10.0.1.0/24` quedan reservados para crecimiento.

**Correspondencia entre cada red y su interfaz.** Cada gateway pertenece a la interfaz que representa ese segmento y no a otra; las redes departamentales se distinguen de los enlaces punto a punto:

| Segmento | Red | Interfaz de R1 (o R2) | Dirección del router |
|----------|-----|-----------------------|----------------------|
| Servidores | 10.0.0.0/24 | `veth-r1srv` (R1), `veth-r2srv` (R2, apartado 15.7) | 10.0.0.1 (en 15.7 pasa a ser IP virtual; R1 = .2, R2 = .3) |
| Finanzas | 10.0.1.0/25 | `veth-r1fin` | 10.0.1.1 |
| Ventas | 10.0.1.128/26 | `veth-r1ven` | 10.0.1.129 |
| Gestión | 10.0.1.192/28 | `veth-r1ges` | 10.0.1.193 |
| Enlace A (principal) | 10.0.1.208/30 | `veth-r1r2a` (R1 .209) ↔ `veth-r2r1a` (R2 .210) | — (punto a punto) |
| Enlace B (respaldo) | 10.0.1.212/30 | `veth-r1r2b` (R1 .213) ↔ `veth-r2r1b` (R2 .214) | — (punto a punto) |
| Sucursal | 10.0.2.0/24 | `veth-r2suc` (R2) | 10.0.2.1 |

Ahora se crean el resto de segmentos (Finanzas ya existe):

```bash
# Ventas y Gestión: una interfaz de R1 por segmento
enlace R1 veth-r1ven 10.0.1.129/26 ven veth-ven 10.0.1.130/26
sudo ip netns exec ven ip route add default via 10.0.1.129
enlace R1 veth-r1ges 10.0.1.193/28 ges veth-ges 10.0.1.194/28
sudo ip netns exec ges ip route add default via 10.0.1.193

# Servidores: un switch (bridge) que más adelante compartirán R1 y R2
sudo ip netns exec SWsrv ip link add br0 type bridge
sudo ip netns exec SWsrv ip link set br0 up
sudo ip link add veth-r1srv type veth peer name veth-sw-r1
sudo ip link set veth-r1srv alias networking-lab-lab-15
sudo ip link set veth-sw-r1 alias networking-lab-lab-15
sudo ip link set veth-r1srv netns R1
sudo ip link set veth-sw-r1 netns SWsrv
sudo ip netns exec SWsrv ip link set veth-sw-r1 master br0
sudo ip netns exec SWsrv ip link set veth-sw-r1 up
sudo ip netns exec R1 ip addr add 10.0.0.1/24 dev veth-r1srv
sudo ip netns exec R1 ip link set veth-r1srv up
sudo ip link add veth-srv type veth peer name veth-sw-srv
sudo ip link set veth-srv alias networking-lab-lab-15
sudo ip link set veth-sw-srv alias networking-lab-lab-15
sudo ip link set veth-srv netns srv
sudo ip link set veth-sw-srv netns SWsrv
sudo ip netns exec SWsrv ip link set veth-sw-srv master br0
sudo ip netns exec SWsrv ip link set veth-sw-srv up
sudo ip netns exec srv ip addr add 10.0.0.10/24 dev veth-srv
sudo ip netns exec srv ip link set veth-srv up
sudo ip netns exec srv ip route add default via 10.0.0.1

# R2 y su sucursal; dos enlaces /30 entre R1 y R2 (A: principal, B: respaldo)
enlace R1 veth-r1r2a 10.0.1.209/30 R2 veth-r2r1a 10.0.1.210/30
enlace R1 veth-r1r2b 10.0.1.213/30 R2 veth-r2r1b 10.0.1.214/30
enlace R2 veth-r2suc 10.0.2.1/24 suc veth-suc 10.0.2.10/24
sudo ip netns exec suc ip route add default via 10.0.2.1
```

Se comprueba que cada equipo alcanza a su *gateway* y entre sí a través de R1:

```bash
sudo ip netns exec fin ping -c 2 10.0.1.130     # Finanzas -> Ventas (R1 enruta)
sudo ip netns exec srv ping -c 2 10.0.1.194     # Servidores -> Gestión
sudo ip netns exec R1 ping -c 2 10.0.1.210      # R1 -> R2 por el enlace A
```

## 15.3 VLAN (variante conceptual)

!!! warning "Ejemplo conceptual, no integrable directamente"
    En 15.2 cada departamento usa **una interfaz independiente** de R1. En una red real lo habitual es **un único enlace *trunk*** que transporta varias VLAN. Esta variante se presenta como **ejemplo conceptual**: **no es una configuración integral que pueda incorporarse directamente a la topología anterior** (no coexisten con las mismas subredes), y no se ha encadenado con el resto del laboratorio. Este laboratorio sigue con segmentos separados para poder verificarlos en cualquier máquina.

La configuración con un bridge Linux con filtrado de VLAN y *router-on-a-stick* es la del laboratorio 05 (requiere el módulo `8021q`). Con [Open vSwitch](https://www.openvswitch.org/), los elementos que hay que definir son estos:

| Elemento | Qué es | Dónde |
|----------|--------|-------|
| `ovs-sw` | El switch (bridge [OVS](https://www.openvswitch.org/)) | host |
| `puerto-fin`, `puerto-ven`, `puerto-ges` | Puertos **access** de las VLAN 10, 20, 30; cada uno es un extremo de un `veth` cuyo otro extremo va al equipo final (`fin`, `ven`, `ges`) | host (extremo del switch) |
| `trunk-r1` ↔ `trunk` | Enlace **trunk**: `trunk-r1` es el puerto del switch y **recibe/envía las etiquetas 802.1Q**; su otro extremo `trunk` va a R1 | host / R1 |
| `trunk.10`, `trunk.20`, `trunk.30` | **Subinterfaces** de R1 sobre `trunk`, una por VLAN, con la IP del *gateway* de cada VLAN | R1 |

```bash
sudo apt-get install -y openvswitch-switch
mkdir -p /tmp/lab15
if sudo ovs-vsctl br-exists ovs-sw; then
  echo "Ya existe ovs-sw: no se reutiliza ni se elimina un bridge preexistente."
  exit 1
fi
sudo ovs-vsctl add-br ovs-sw && touch /tmp/lab15/ovs-sw.created

# Equipos finales: veth cuyo extremo "puerto-*" queda en el switch y el otro va a cada equipo
for h in "fin 10" "ven 20" "ges 30"; do
  set -- $h
  sudo ip link add puerto-$1 type veth peer name veth-eq-$1
  sudo ip link set puerto-$1 alias networking-lab-lab-15
  sudo ip link set veth-eq-$1 alias networking-lab-lab-15
  sudo ip link set veth-eq-$1 netns $1
  sudo ip link set puerto-$1 up
  sudo ovs-vsctl add-port ovs-sw puerto-$1 tag=$2      # puerto de acceso (sin etiqueta hacia el equipo)
done

# Trunk hacia R1: el switch etiqueta 10, 20 y 30
sudo ip link add trunk-r1 type veth peer name trunk
sudo ip link set trunk-r1 alias networking-lab-lab-15
sudo ip link set trunk alias networking-lab-lab-15
sudo ip link set trunk netns R1
sudo ip link set trunk-r1 up
sudo ovs-vsctl add-port ovs-sw trunk-r1 trunks=10,20,30

# En R1, una subinterfaz por VLAN con el gateway de cada subred
sudo ip netns exec R1 ip link set trunk up
for v in "10 10.0.1.1/25" "20 10.0.1.129/26" "30 10.0.1.193/28"; do
  set -- $v
  sudo ip netns exec R1 ip link add link trunk name trunk.$1 type vlan id $1
  sudo ip netns exec R1 ip addr add $2 dev trunk.$1
  sudo ip netns exec R1 ip link set trunk.$1 up
done

# Limpieza (el bridge OVS persiste incluso tras reiniciar):
# sudo ovs-vsctl --if-exists del-br ovs-sw
```

Los equipos finales (`fin`, `ven`, `ges`) tendrían su IP y su *gateway* como en 15.2, pero conectados al puerto de acceso de su VLAN. Estas subinterfaces llevan las IP de *gateway* **en lugar de** las interfaces `veth-r1fin`, `veth-r1ven` y `veth-r1ges` del 15.2: **no deben coexistir las dos formas** con las mismas subredes. Se verifica en el entorno propio antes de adoptarlo: este bloque ilustra el modelo trunk/access, no se encadena con el firewall, el DHCP ni el OSPF de los apartados siguientes (que usan los nombres de interfaz del 15.2).

## 15.4 Routing entre redes

### Rutas estáticas

```bash
sudo ip netns exec R2 ip route add default via 10.0.1.209
sudo ip netns exec R1 ip route add 10.0.2.0/24 via 10.0.1.210

sudo ip netns exec suc ping -c 2 10.0.1.10        # Sucursal -> Finanzas
sudo ip netns exec suc ping -c 2 192.168.100.2    # Sucursal -> "Internet" (vía R1 y su NAT)
sudo ip netns exec R1 ip route show
```

Funciona, pero las rutas estáticas no se adaptan solas a los cambios. Se eliminan y se usa un protocolo dinámico.

### OSPF con FRRouting

Cada router ejecuta sus propios demonios `zebra` (conecta FRR con el kernel) y `ospfd`, dentro de su namespace y con archivos propios en `/tmp/lab15/<router>/`. Primero quitamos las rutas estáticas del tramo anterior:

```bash
sudo ip netns exec R2 ip route del default via 10.0.1.209
sudo ip netns exec R1 ip route del 10.0.2.0/24 via 10.0.1.210
```

Configuración de OSPF (los enlaces se declaran *punto a punto* para que la adyacencia llegue a `Full` enseguida, sin elección de DR; el enlace A, con coste 10, es el principal; el B, con coste 20, el respaldo; R1 anuncia además una ruta por defecto hacia Internet):

```bash
mkdir -p /tmp/lab15/r1 /tmp/lab15/r2

cat > /tmp/lab15/r1/zebra.conf << 'EOF'
hostname r1
EOF
cat > /tmp/lab15/r1/ospfd.conf << 'EOF'
hostname r1
interface veth-r1r2a
 ip ospf network point-to-point
 ip ospf cost 10
interface veth-r1r2b
 ip ospf network point-to-point
 ip ospf cost 20
router ospf
 ospf router-id 1.1.1.1
 passive-interface default
 no passive-interface veth-r1r2a
 no passive-interface veth-r1r2b
 network 10.0.0.0/24 area 0
 network 10.0.1.0/25 area 0
 network 10.0.1.128/26 area 0
 network 10.0.1.192/28 area 0
 network 10.0.1.208/30 area 0
 network 10.0.1.212/30 area 0
 default-information originate always
EOF

cat > /tmp/lab15/r2/zebra.conf << 'EOF'
hostname r2
EOF
cat > /tmp/lab15/r2/ospfd.conf << 'EOF'
hostname r2
interface veth-r2r1a
 ip ospf network point-to-point
 ip ospf cost 10
interface veth-r2r1b
 ip ospf network point-to-point
 ip ospf cost 20
router ospf
 ospf router-id 2.2.2.2
 passive-interface default
 no passive-interface veth-r2r1a
 no passive-interface veth-r2r1b
 network 10.0.2.0/24 area 0
 network 10.0.1.208/30 area 0
 network 10.0.1.212/30 area 0
EOF

# Los demonios se ejecutan como el usuario frr: necesita acceder a los archivos
sudo chown -R frr:frr /tmp/lab15/r1 /tmp/lab15/r2   # solo los directorios de los demonios
sudo chmod 755 /tmp/lab15                            # ¡no cambies los permisos de /tmp!

# Arrancar los demonios en cada namespace
for r in r1 r2; do
  R=$(echo $r | tr a-z A-Z)
  sudo ip netns exec $R /usr/lib/frr/zebra -d -u frr -g frr -f /tmp/lab15/$r/zebra.conf \
      -i /tmp/lab15/$r/zebra.pid -z /tmp/lab15/$r/zserv.api --vty_socket /tmp/lab15/$r
  sudo ip netns exec $R /usr/lib/frr/ospfd -d -u frr -g frr -f /tmp/lab15/$r/ospfd.conf \
      -i /tmp/lab15/$r/ospfd.pid -z /tmp/lab15/$r/zserv.api --vty_socket /tmp/lab15/$r
done
```

Los comandos `show ...` no son del *shell*: son del intérprete de FRR (`vtysh`). Desde el *shell* se ejecutan con `vtysh -c`, indicando el socket de cada router:

```bash
sleep 20
sudo vtysh --vty_socket /tmp/lab15/r1 -c "show ip ospf neighbor"
sudo vtysh --vty_socket /tmp/lab15/r1 -c "show ip route ospf"
sudo vtysh --vty_socket /tmp/lab15/r2 -c "show ip route ospf"

sudo ip netns exec suc ping -c 3 10.0.1.10
sudo ip netns exec suc ping -c 3 192.168.100.2
```

**Resultado esperado:** R1 y R2 son vecinos en estado `Full`; R2 aprende las redes de R1 y una ruta por defecto (`O>* 0.0.0.0/0`), y R1 aprende `10.0.2.0/24`.

**Qué hace OSPF (y qué no es).** OSPF no es «un mecanismo que cambia de interfaz cuando se cae un enlace». El resultado que observas es la consecuencia de un proceso en varias etapas:

1.  **Adyacencia:** R1 y R2 se descubren con paquetes *Hello* por cada enlace y establecen una relación de vecindad (`Full`). Hay una adyacencia **por enlace** (A y B).
2.  **Intercambio de estado de enlace:** cada router describe en **LSA** sus interfaces, sus redes y su **coste**, y se los envía al vecino.
3.  **Base de datos de estado de enlace ([LSDB](https://www.rfc-editor.org/rfc/rfc2328)):** cada router acumula los LSA y construye una **vista idéntica de la topología**.
4.  **Cálculo SPF:** cada router ejecuta el algoritmo de Dijkstra sobre esa base de datos y obtiene el **camino de menor coste acumulado** hacia cada red. El coste de un camino es la **suma** de los costes de los enlaces que atraviesa.
5.  **Selección de ruta:** de entre los caminos calculados (aquí, por el enlace A con coste 10 o por el B con coste 20), se instala en la tabla de rutas el de menor coste. El B queda **preparado** en la base de datos pero no se usa mientras A sea mejor. Si dos caminos tuvieran el mismo coste, se instalarían los dos (ECMP).
6.  **Reconvergencia:** cuando un enlace cae, el router lo **detecta** (por pérdida de la interfaz o por vencer el tiempo de *dead*), **genera un LSA nuevo**, lo propaga, los routers **actualizan su LSDB y recalculan SPF** y se instalan las nuevas rutas.

Por eso la reconvergencia del apartado siguiente es rápida **aquí**: la interfaz cae y se detecta al instante; si el fallo fuera más allá de la interfaz (un fallo remoto), el vecino se declararía caído al vencer el *dead interval* (40 s por defecto), y la reconvergencia sería más lenta salvo con temporizadores ajustados o BFD.

**La ruta por defecto: `default-information originate always`.** Con esta orden R1 **anuncia a los demás routers una ruta por defecto**. La palabra `always` hace que la anuncie **incluso si R1 no dispone de una ruta por defecto válida** en su tabla. En este escenario R1 sí tiene una salida configurada hacia el host (`default via 192.168.100.2`), pero conviene saber qué significa: sin `always`, R1 solo anunciaría la ruta mientras tuviera una propia. **Que se anuncie una ruta no garantiza que el acceso exterior funcione**: si la WAN de R1 cayera, R2 seguiría recibiendo la ruta por defecto (con `always`) y enviando allí el tráfico. Quitar `always` hace que el anuncio dependa de la ruta real de R1.

### Reconvergencia ante un fallo

Se baja el enlace principal (A) por ambos extremos y se observa cómo OSPF mueve el tráfico al respaldo sin intervención:

```bash
sudo ip netns exec R1 ip link set veth-r1r2a down
sudo ip netns exec R2 ip link set veth-r2r1a down
sleep 5
sudo ip netns exec R1 ip route show 10.0.2.0/24        # ahora por el enlace B (10.0.1.214)
sudo ip netns exec suc ping -c 3 10.0.1.10
sudo ip netns exec R1 ip link set veth-r1r2a up
sudo ip netns exec R2 ip link set veth-r2r1a up
```

**Las rutas antes y después de la caída del enlace A** (R1 hacia la sucursal `10.0.2.0/24`):

| Momento | `ip route show 10.0.2.0/24` en R1 | Quién lo decide |
|---------|-----------------------------------|-----------------|
| Enlace A activo | `via 10.0.1.210 dev veth-r1r2a proto ospf` | OSPF elige el camino de menor coste |
| Enlace A caído (tras ~5 s) | `via 10.0.1.214 dev veth-r1r2b proto ospf` | OSPF detecta la pérdida de la adyacencia y **recalcula** (SPF) |
| Enlace A restablecido | Vuelve `via 10.0.1.210` | Se restablece la adyacencia y el camino de menor coste |

Compárese con el laboratorio 06: allí el respaldo era una **segunda ruta estática** y solo valía para fallos locales; aquí el protocolo **descubre** el cambio por sí mismo, incluso si el fallo no fuera de la interfaz propia.

## 15.5 Firewall

Reglas en **nftables** para R1, guardadas en un archivo y cargadas dentro de su namespace. Las interfaces son las reales de R1: la WAN es `veth-r1-wan` y la zona de servidores `veth-r1srv`.

```bash
cat > /tmp/lab15/fw.nft << 'EOF'
table inet firewall {
    chain input {
        type filter hook input priority 0; policy drop;
        iif lo accept
        ct state established,related accept
        ip protocol icmp limit rate 10/second accept
        ip protocol ospf accept
        ip protocol vrrp accept
        iifname { "veth-r1fin", "veth-r1ven" } udp dport 67 accept
        iifname { "veth-r1fin", "veth-r1ven" } udp dport 53 accept
        iifname { "veth-r1fin", "veth-r1ven" } tcp dport 53 accept
        iifname { "veth-r1fin", "veth-r1ven", "veth-r1ges" } tcp dport 22 accept
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
        ct state established,related accept
        iifname { "veth-r1fin", "veth-r1ven", "veth-r1ges", "veth-r1r2a", "veth-r1r2b" } oifname "veth-r1-wan" accept
        iifname { "veth-r1fin", "veth-r1ven", "veth-r1ges", "veth-r1r2a", "veth-r1r2b" } oifname "veth-r1srv" accept
        iifname "veth-r1-wan" oifname "veth-r1srv" tcp dport { 80, 443, 25 } accept
        # Entre LAN departamentales: por defecto NADA; solo Gestión puede administrar Finanzas y Ventas
        iifname "veth-r1ges" oifname { "veth-r1fin", "veth-r1ven" } icmp type echo-request accept
        iifname "veth-r1ges" oifname { "veth-r1fin", "veth-r1ven" } tcp dport 22 accept
        counter    # cuenta lo que llega al final de la cadena: lo que descartará la política
    }
}
EOF

sudo ip netns exec R1 nft -f /tmp/lab15/fw.nft
sudo ip netns exec R1 nft list ruleset
```

El protocolo OSPF (número 89) debe aceptarse en `input`, o R1 dejaría de ver a sus vecinos; igual que VRRP (número 112, apartado 15.7); y el puerto UDP 67 de las LAN de Finanzas y Ventas, o R1 no podría repartir direcciones DHCP (apartado 15.6). La política de `forward` es "denegar" y solo se abre lo necesario.

**Política de comunicación que implementan estas reglas** (segmentación no equivale a aislamiento absoluto: las reglas deben responder a una política definida):

| Origen → Destino | Política |
|------------------|----------|
| LAN (Finanzas, Ventas, Gestión) y enlaces a R2 → Internet | Permitido |
| LAN y sucursal → Servidores | Permitido |
| Finanzas ↔ Ventas, y Servidores → LAN | **Denegado** |
| Gestión → Finanzas / Ventas | Solo ICMP y SSH (administración) |
| Internet → Servidores | Solo TCP 80, 443 y 25 (si el servicio se publica; véase abajo) |

!!! info "Permitir el reenvío no equivale a publicar el servicio"
    La regla «Internet → Servidores en 80, 443 y 25» **solo permite el reenvío** si el paquete llega con un destino interno por la interfaz WAN. **No crea por sí sola la traducción de destino ni la accesibilidad exterior.** Para publicar un servicio privado hace falta normalmente **DNAT** (o direccionamiento público, o una arquitectura equivalente), además de rutas y políticas de seguridad. Ejemplo para publicar el puerto 80 del servidor `10.0.0.10` en la dirección WAN de R1:

    ```bash
    sudo ip netns exec R1 iptables -t nat -A PREROUTING -i veth-r1-wan -p tcp --dport 80 -j DNAT --to-destination 10.0.0.10:80
    sudo ip netns exec srv sh -c 'nc -l -p 80 >/dev/null 2>&1 </dev/null &'
    nc -zv -w 2 192.168.100.1 80        # desde el host («Internet»)
    ```

    Sin la regla de `PREROUTING`, el host no alcanzaría el servidor aunque la política de `forward` lo permitiera.

**Convivencia de nftables e iptables en esta práctica.** El filtrado de R1 se escribe en `nftables`; la NAT de salida y el DNAT de demostración usan la interfaz `iptables`. Se comprueba qué backend utiliza `iptables` dentro del namespace:

```bash
sudo ip netns exec R1 iptables --version
sudo ip netns exec R1 iptables-save
sudo ip netns exec R1 nft list ruleset
```

Si `iptables --version` termina en `(nf_tables)`, `iptables` traduce sus reglas al backend nftables; ambas vistas pertenecen al mismo framework, aunque `iptables-save` sigue siendo la vista más directa de las reglas administradas por esa interfaz. Si termina en `(legacy)`, usa el backend xtables antiguo, separado del ruleset nftables y no visible como reglas nft nativas. Mezclar backends puede complicar el orden y el diagnóstico. Aquí se conserva deliberadamente para mostrar compatibilidad; en un despliegue real elige y administra un único backend, evita reglas duplicadas y se verifica siempre las reglas efectivas en ambos planos.

### Verificar segmentación y políticas

```bash
sudo ip netns exec fin ping -c 2 192.168.100.2     # salida a "Internet": permitida
sudo ip netns exec fin ping -c 2 -W 1 10.0.1.130   # Finanzas -> Ventas: BLOQUEADO (sin regla entre LAN)
sudo ip netns exec ges ping -c 2 10.0.1.10         # Gestión -> Finanzas: permitido (administración)
sudo ip netns exec srv ping -c 2 -W 1 10.0.1.10    # Servidores -> Finanzas: bloqueado
sudo ip netns exec R1 nft list chain inet firewall forward | grep counter   # paquetes descartados por la política
```

(La NAT hacia Internet sigue siendo la regla `iptables` de R1 del apartado 15.1.)

## 15.6 Servicios: DHCP con dnsmasq

R1 reparte direcciones en Finanzas y Ventas, con un rango por subred y su propio *gateway*. Antes de leer la configuración, fija la correspondencia:

| Interfaz de R1 | Segmento | Rango DHCP | Máscara | Gateway entregado | Etiqueta de dnsmasq |
|----------------|----------|------------|---------|-------------------|---------------------|
| `veth-r1fin` | Finanzas (10.0.1.0/25) | 10.0.1.20 – 10.0.1.120 | 255.255.255.128 | 10.0.1.1 | `fin` |
| `veth-r1ven` | Ventas (10.0.1.128/26) | 10.0.1.140 – 10.0.1.190 | 255.255.255.192 | 10.0.1.129 | `ven` |

**Cómo se asocian las etiquetas con los rangos.** `dhcp-range=set:fin,…` **crea la etiqueta `fin` para los clientes que reciban una dirección de ese rango**; `dhcp-option=tag:fin,option:router,…` aplica la opción de *gateway* **solo** a los clientes con esa etiqueta. Así, cada cliente recibe el *gateway* de su subred. Dnsmasq decide el rango por la interfaz por la que llega la petición.

**Qué parámetros recibe cada cliente:** dirección IP, máscara, puerta de enlace (`router`), servidor DNS y duración de la concesión (24 h). La configuración siguiente anuncia un **DNS interno opcional** ejecutado en R1: Finanzas consulta `10.0.1.1` y Ventas `10.0.1.129`, ambas direcciones del mismo router en sus respectivas redes. El servicio mantiene una zona de demostración `secops.local` y reenvía otros nombres a `8.8.8.8` si el host dispone de salida. DHCP y DNS siguen siendo servicios independientes: recibir una IP no garantiza que la resolución funcione.

```bash
cat > /tmp/lab15/dhcp.conf << 'EOF'
port=0
bind-interfaces
interface=veth-r1fin
interface=veth-r1ven
dhcp-range=set:fin,10.0.1.20,10.0.1.120,255.255.255.128,24h
dhcp-option=tag:fin,option:router,10.0.1.1
dhcp-range=set:ven,10.0.1.140,10.0.1.190,255.255.255.192,24h
dhcp-option=tag:ven,option:router,10.0.1.129
dhcp-option=tag:fin,option:dns-server,10.0.1.1
dhcp-option=tag:ven,option:dns-server,10.0.1.129
dhcp-leasefile=/tmp/lab15/dhcp.leases
EOF

sudo dnsmasq --test --conf-file=/tmp/lab15/dhcp.conf
sudo ip netns exec R1 dnsmasq --conf-file=/tmp/lab15/dhcp.conf --pid-file=/tmp/lab15/dhcp.pid
```

### DNS interno opcional: completar el ciclo DHCP → DNS → aplicación

El servidor DHCP anterior usa `port=0`, por lo que no presta DNS. Para recuperar la práctica del laboratorio 07, se levanta una segunda instancia de dnsmasq, dedicada a DNS, en las dos interfaces departamentales. No se presenta como DNS autoritativo empresarial completo: es una zona local pequeña y un reenviador para el resto.

```bash
cat > /tmp/lab15/dns.conf << 'EOF'
port=53
bind-interfaces
interface=veth-r1fin
interface=veth-r1ven
listen-address=10.0.1.1,10.0.1.129
no-resolv
server=8.8.8.8
domain-needed
bogus-priv
domain=secops.local
local=/secops.local/
host-record=app.secops.local,10.0.0.10
host-record=db.secops.local,10.0.0.20
cache-size=1000
EOF

sudo dnsmasq --test --conf-file=/tmp/lab15/dns.conf
sudo ip netns exec R1 dnsmasq --conf-file=/tmp/lab15/dns.conf --pid-file=/tmp/lab15/dns.pid
```

Tras obtener las concesiones DHCP, se comprueba que cada segmento recibió su DNS y que la zona local resuelve:

```bash
sudo ip netns exec fin cat /etc/resolv.conf
sudo ip netns exec fin dig @10.0.1.1 app.secops.local A +noall +answer
sudo ip netns exec ven dig @10.0.1.129 db.secops.local A +noall +answer
sudo ip netns exec fin dig @10.0.1.1 app.secops.local A +tcp +noall +answer
sudo ip netns exec fin dig @10.0.1.1 inexistente.secops.local A
```

Resultados esperados: `app.secops.local` devuelve `10.0.0.10`, `db.secops.local` devuelve `10.0.0.20` y el nombre inexistente devuelve `NXDOMAIN`. Si la consulta externa falla pero la zona interna responde, revisa salida WAN/forwarding antes de atribuir el fallo al DNS interno.

Los clientes piden dirección en lugar de tener una fija. Para que `dhclient` no toque el `resolv.conf` de el equipo, se asigna a cada namespace el suyo:

```bash
for ns in fin ven; do
  sudo mkdir -p /etc/netns/$ns
  sudo touch /etc/netns/$ns/resolv.conf
done

# Finanzas: quitar la IP fija y pedirla por DHCP
sudo ip netns exec fin ip addr flush dev veth-fin
sudo ip netns exec fin dhclient -v -pf /tmp/lab15/dhclient-fin.pid -lf /tmp/lab15/dhclient-fin.leases veth-fin
sudo ip netns exec fin ip -4 addr show dev veth-fin
sudo ip netns exec fin ip route show

# Ventas
sudo ip netns exec ven ip addr flush dev veth-ven
sudo ip netns exec ven dhclient -v -pf /tmp/lab15/dhclient-ven.pid -lf /tmp/lab15/dhclient-ven.leases veth-ven
sudo ip netns exec ven ip -4 addr show dev veth-ven
```

### Validar

```bash
sudo ip netns exec fin ip route
sudo ip netns exec fin ping -c 2 10.0.1.1
sudo ip netns exec fin ping -c 2 192.168.100.2
sudo ip netns exec ven ping -c 2 192.168.100.2
```

## 15.7 Red empresarial completa: VRRP (redundancia de *gateway*)

Los servidores usan `10.0.0.1` como *gateway*. Si R1 falla, quedarían aislados. Con **VRRP** (aquí con `keepalived`) R1 y R2 comparten una **IP virtual** `10.0.0.1`: la tiene el router de mayor prioridad y, si cae, la toma el otro.

**Los elementos de VRRP:**

| Elemento | En este laboratorio |
|----------|---------------------|
| Dirección física de R1 | `10.0.0.2` (en `veth-r1srv`) |
| Dirección física de R2 | `10.0.0.3` (en `veth-r2srv`) |
| Dirección virtual compartida | `10.0.0.1` (el *gateway* de los servidores) |
| Router activo (*master*) | R1, prioridad 100 |
| Router de respaldo (*backup*) | R2, prioridad 90 |
| Anuncios VRRP | El *master* envía un anuncio cada segundo (`advert_int 1`) por multicast (224.0.0.18, protocolo IP 112) |
| Cambio de estado | Si el respaldo deja de recibir anuncios durante unos tres intervalos, **se declara *master*** y **adquiere la dirección virtual** (y avisa con ARP gratuito) |

R2 se une al switch de servidores y R1 pasa a usar una IP propia distinta (`10.0.0.2`), dejando `10.0.0.1` para la IP virtual (no puede estar configurada a la vez como IP normal):

```bash
# R2 en el segmento de servidores
sudo ip link add veth-r2srv type veth peer name veth-sw-r2
sudo ip link set veth-r2srv alias networking-lab-lab-15
sudo ip link set veth-sw-r2 alias networking-lab-lab-15
sudo ip link set veth-r2srv netns R2
sudo ip link set veth-sw-r2 netns SWsrv
sudo ip netns exec SWsrv ip link set veth-sw-r2 master br0
sudo ip netns exec SWsrv ip link set veth-sw-r2 up
sudo ip netns exec R2 ip addr add 10.0.0.3/24 dev veth-r2srv
sudo ip netns exec R2 ip link set veth-r2srv up

# R1: su IP real pasa a 10.0.0.2 (10.0.0.1 será la IP virtual)
sudo ip netns exec R1 ip addr del 10.0.0.1/24 dev veth-r1srv
sudo ip netns exec R1 ip addr add 10.0.0.2/24 dev veth-r1srv
```

Configuración de VRRP en cada router (la contraseña de autenticación tiene como máximo 8 caracteres; la clave `PASS` de VRRP es débil y solo sirve para evitar errores de configuración, no como seguridad):

```bash
cat > /tmp/lab15/ka-r1.conf << 'EOF'
vrrp_instance SERVIDORES {
    state MASTER
    interface veth-r1srv
    virtual_router_id 10
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass Secur24
    }
    virtual_ipaddress {
        10.0.0.1/24
    }
}
EOF
sed -e 's/MASTER/BACKUP/' -e 's/veth-r1srv/veth-r2srv/' -e 's/priority 100/priority 90/' /tmp/lab15/ka-r1.conf > /tmp/lab15/ka-r2.conf

sudo ip netns exec R1 keepalived -P -f /tmp/lab15/ka-r1.conf -p /tmp/lab15/ka-r1.pid -r /tmp/lab15/ka-r1.vrrp.pid
sudo ip netns exec R2 keepalived -P -f /tmp/lab15/ka-r2.conf -p /tmp/lab15/ka-r2.pid -r /tmp/lab15/ka-r2.vrrp.pid
```

### Verificar y probar el *failover*

```bash
sleep 5
sudo ip netns exec R1 ip -4 addr show dev veth-r1srv     # R1 tiene 10.0.0.1 como IP virtual
sudo ip netns exec srv ping -c 2 10.0.0.1

# Falla R1: detener solo los dos procesos keepalived registrados de R1.
for pf in /tmp/lab15/ka-r1.vrrp.pid /tmp/lab15/ka-r1.pid; do
  pid=$(cat "$pf" 2>/dev/null || true)
  [[ "$pid" =~ ^[0-9]+$ ]] || { echo "PID inválido en $pf; aborta el failover."; exit 1; }
  cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
  if [[ "$cmdline" == *keepalived* && "$cmdline" == *"/tmp/lab15/ka-r1.conf"* ]]; then
    sudo kill -TERM "$pid"
  else
    echo "PID $pid no coincide con keepalived de ka-r1.conf; no se detiene ningún proceso."
    exit 1
  fi
done
sleep 2
for pf in /tmp/lab15/ka-r1.vrrp.pid /tmp/lab15/ka-r1.pid; do
  pid=$(cat "$pf" 2>/dev/null || true)
  [[ "$pid" =~ ^[0-9]+$ ]] || continue
  [ -r "/proc/$pid/cmdline" ] || continue
  cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline")
  if [[ "$cmdline" == *keepalived* && "$cmdline" == *"/tmp/lab15/ka-r1.conf"* ]]; then sudo kill -KILL "$pid" 2>/dev/null || true; fi
done
sleep 5
sudo ip netns exec R2 ip -4 addr show dev veth-r2srv     # ahora R2 tiene 10.0.0.1
sudo ip netns exec srv ping -c 3 10.0.0.1                # el gateway sigue respondiendo
```

**Alcance de VRRP.** VRRP proporciona **redundancia del *gateway***, **no redundancia integral de toda la infraestructura**. Si R1 pierde **solo su conectividad WAN** pero **su interfaz LAN sigue funcionando**, R1 sigue enviando anuncios y conservando la IP virtual: **la configuración mostrada no provoca una transferencia automática**, y los servidores seguirían enviando su tráfico a un *gateway* sin salida. Para cubrir esa condición hace falta **seguimiento del estado de interfaces o rutas** y una **política de prioridad** que lo acompañe. Con `keepalived`:

```
vrrp_instance SERVIDORES {
    ...
    track_interface {
        veth-r1-wan weight -20     # si la WAN cae, la prioridad de R1 baja de 100 a 80 (< 90 de R2)
    }
}
```

(Ilustrativo: en **esta** topología R2 sale a Internet a través de R1, así que transferir el *gateway* a R2 no restablecería la salida; el seguimiento solo sirve cuando el respaldo tiene un camino alternativo.) La clave `PASS` no es una protección criptográfica: ya se advirtió arriba que es débil, y esa advertencia se mantiene.

### Cambio de *master* y *backup*

```mermaid
sequenceDiagram
    participant S as srv (gateway 10.0.0.1)
    participant R1 as R1 (prioridad 100)
    participant R2 as R2 (prioridad 90)
    R1->>R2: Anuncios VRRP cada 1 s (R1 es MASTER y tiene 10.0.0.1)
    S->>R1: Tráfico hacia el gateway 10.0.0.1
    Note over R1: Falla el servicio VRRP de R1
    R2->>R2: Deja de oír anuncios y pasa a MASTER
    R2->>S: ARP gratuito: 10.0.0.1 ahora está en R2
    S->>R2: El mismo gateway 10.0.0.1, otro equipo detrás
```

### Dos casos que no deben confundirse

**Caso A: falla el *servicio de gateway* de R1.** Es el que demuestra el apartado anterior: R2 asume la IP virtual y los servidores conservan su *gateway*. Lo que se demuestra es **disponibilidad del *gateway***.

**Caso B: falla la conectividad **WAN** de R1, pero R1 sigue vivo.** Obsérvalo con VRRP funcionando y R1 como *master* (hazlo **antes** del *failover* anterior o reinicia primero el `keepalived` de R1):

```bash
sudo ip netns exec R1 ip link set veth-r1-wan down
sudo ip netns exec srv ping -c 2 -W 1 10.0.0.1          # el gateway sigue respondiendo
sudo ip netns exec srv ping -c 2 -W 1 192.168.100.2     # pero ya no hay salida a «Internet»

# Restablecer: al bajar la interfaz el kernel retiró la ruta por defecto
sudo ip netns exec R1 ip link set veth-r1-wan up
sudo ip netns exec R1 ip route replace default via 192.168.100.2
```

La IP virtual **no se movió** porque R1 sigue enviando anuncios por su LAN. Para que el caso B se resuelva hace falta, además, que **R2 tenga una salida WAN propia**:

| Requisito | Por qué |
|-----------|---------|
| Una salida WAN independiente en R2 (otro enlace al exterior) | Si R2 sale por R1, transferir el *gateway* no restablece nada |
| Ruta por defecto y NAT en R2 | Para que, al ser *master*, pueda sacar el tráfico |
| Seguimiento de la WAN en `keepalived` (`track_interface` o `track_script`) | Para que R1 **baje su prioridad** al perder la WAN y R2 pase a ser *master* |
| Reglas de firewall equivalentes en R2 | Para que la política no cambie al cambiar de *master* |

Es la diferencia entre **disponibilidad del *gateway*** (caso A) y **continuidad integral del servicio** (caso B).

## 15.8 Troubleshooting real

Casos de diagnóstico habituales. Los ejemplos de direcciones (`10.10.1.100`) son **ilustrativos**: no corresponden a un equipo de esta topología. Los comandos siguientes sirven para **representar un diagnóstico de paquetes que atraviesan un túnel**; **no** verifican el túnel construido en apartados anteriores (en este laboratorio no hay ningún túnel GRE ni IPsec).

### Caso: degradación por MTU en un túnel (IPsec/GRE)

**MTU y MSS no son intercambiables:**

| Concepto | Qué es | Ejemplo |
|----------|--------|---------|
| **MTU del enlace** | Tamaño máximo del paquete IP en ese enlace | 1500 |
| **MTU efectiva del túnel** | La MTU del enlace **menos el *overhead* de la encapsulación** | p. ej. ~1400 con IPsec |
| **MSS anunciado por TCP** | Máximo de **datos TCP** por segmento que un extremo anuncia (MTU − 20 IP − 20 TCP) | 1460 con MTU 1500; 1360 con MTU 1400 |
| **Ajuste de MSS** (*MSS clamping*) | El router reescribe el MSS de los SYN para que los segmentos quepan en el túnel | `TCPMSS --set-mss 1360` |
| **Fragmentación y PMTUD** | Si un paquete excede la MTU: se fragmenta (si no tiene DF) o se descarta y se avisa por ICMP «fragmentation needed» (PMTUD); si ese ICMP se filtra, la conexión **se bloquea** |  |

```bash
# Sondear la MTU efectiva con DF activado.
# -s es el tamaño de los DATOS ICMP: 1472 + 28 = 1500, el tamaño máximo con MTU 1500.
# Si falla, la MTU del camino es menor que 1500 (por ejemplo, por la encapsulación de un túnel).
ping -M do -s 1472 -c 2 10.10.1.100
ping -M do -s 1410 -c 2 10.10.1.100
sudo tcpdump -i eth0 host 10.10.1.100 and port 445 -w captura.pcap

# Limitar el MSS de las conexiones que atraviesan el router (se aplica habitualmente en la tabla mangle).
# 1360 = 1400 (MTU efectiva del túnel) - 20 (IP) - 20 (TCP).
# Aplicar dentro del router del laboratorio y limitarlo al flujo ilustrativo.
# No modifica el firewall global del host. El destino es de ejemplo, no parte de la topología base.
if ! sudo ip netns exec R1 iptables -t mangle -C FORWARD -s 10.0.0.0/22 -d 10.10.1.100/32 -o veth-r1-wan -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360; then
  sudo ip netns exec R1 iptables -t mangle -A FORWARD -s 10.0.0.0/22 -d 10.10.1.100/32 -o veth-r1-wan -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
  touch /tmp/lab15/tcpmss.added
fi
# Alternativa dinámica (elige clamp-mss-to-pmtu en lugar de set-mss, no ambas).
```

### Caso: presión sobre la tabla de vecinos IPv4 (ARP)

Estas órdenes actúan sobre el **host** (`sysctl` y `/etc/sysctl.d`), no sobre un namespace. La prueba inspecciona el número de vecinos IPv4 y muestra cómo se ajustan los umbrales de recolección; **no genera ni simula un agotamiento real** de la tabla. No lo ejecutes en un equipo de producción.

```bash
dmesg | grep -i neighbour
ip -4 neigh show nud all | awk 'NF {n++} END {print "Vecinos IPv4 actuales:", n+0}'
sysctl net.ipv4.neigh.default.gc_thresh2
sysctl net.ipv4.neigh.default.gc_thresh3
# Guarda los valores originales: la limpieza los restaura
sysctl -n net.ipv4.neigh.default.gc_thresh2 > /tmp/lab15/gc_thresh2.orig
sysctl -n net.ipv4.neigh.default.gc_thresh3 > /tmp/lab15/gc_thresh3.orig
sudo sysctl -w net.ipv4.neigh.default.gc_thresh3=8192
sudo sysctl -w net.ipv4.neigh.default.gc_thresh2=4096
# ⚠ CAMBIO PERSISTENTE EN EL HOST: sobrevive a reinicios (reversión en «Limpieza del laboratorio»)
# Si 99-networking-lab-arp.conf ya existe es tuyo: no lo toques; elige otro nombre o cancela
[ -e /etc/sysctl.d/99-networking-lab-arp.conf ] && echo "99-networking-lab-arp.conf ya existe: no continúes" || {
  echo 'net.ipv4.neigh.default.gc_thresh3=8192' | sudo tee /etc/sysctl.d/99-networking-lab-arp.conf
  echo 'net.ipv4.neigh.default.gc_thresh2=4096' | sudo tee -a /etc/sysctl.d/99-networking-lab-arp.conf
  touch /tmp/lab15/creado-99-arp
}
if [ -f /tmp/lab15/creado-99-arp ]; then
  sudo sysctl -p /etc/sysctl.d/99-networking-lab-arp.conf
fi
```

### Script de verificación ARP

```bash
cat > /tmp/lab15/check_arp.sh << 'EOF'
#!/usr/bin/env bash
# Diagnóstico orientativo: cuenta vecinos IPv4 y compara dos muestras.
# No provoca agotamiento ni sustituye métricas del kernel.
set -eu
THRESHOLD=${THRESHOLD:-7000}   # umbral didáctico configurable, no universal
INTERVAL=${INTERVAL:-10}
count_ipv4_neigh() {
  ip -4 neigh show nud all | awk 'NF {n++} END {print n+0}'
}
ANTES=$(count_ipv4_neigh)
sleep "$INTERVAL"
DESPUES=$(count_ipv4_neigh)
DELTA=$((DESPUES - ANTES))
printf 'Vecinos IPv4 antes=%s después=%s variación=%+d en %ss\n' "$ANTES" "$DESPUES" "$DELTA" "$INTERVAL"
if [ "$DESPUES" -ge "$THRESHOLD" ]; then
  echo "AVISO: el recuento alcanzó el umbral orientativo ($THRESHOLD); revisa tendencia, interfaces y gc_thresh2/3."
elif [ "$DELTA" -ge 100 ]; then
  echo "AVISO: crecimiento rápido de vecinos IPv4; confirma si es esperado."
else
  echo "Sin alerta según estos umbrales orientativos."
fi
EOF
chmod 700 /tmp/lab15/check_arp.sh
/tmp/lab15/check_arp.sh
```

## 15.9 Dependencias, fallos e incidencias

### Matriz de dependencias

Los servicios de red no son independientes: unos **necesitan** que otros funcionen y la política de seguridad **los condiciona a todos**.

| Servicio | Depende de | Qué permite el firewall (`input`) | Si falta algo |
|----------|------------|-------------------------------------|----------------|
| **Routing (OSPF)** | Enlaces A/B activos | Protocolo 89 | No hay adyacencia: R1 y R2 no intercambian rutas |
| **DHCP (dnsmasq)** | Interfaz de la LAN y rango definido | UDP 67 desde Finanzas y Ventas | Los clientes no reciben IP |
| **VRRP** | Misma LAN de servidores en R1 y R2 | Protocolo 112 | Ambos routers se creen *master* |
| **Salida a Internet** | WAN de R1, NAT y ruta por defecto | `forward` LAN → WAN | Hay *gateway*, pero no hay salida |
| **Administración (SSH)** | Alcance a R1 desde Gestión | TCP 22 desde Gestión | No se puede gestionar el router |

### Dependencias ocultas entre etapas

Hay dependencias que no se ven al construir cada etapa por separado y que solo aparecen cuando falla algo.

| Dependencia | Qué se rompe si falta | Cómo se nota |
|-------------|------------------------|--------------|
| Firewall (`input`) y OSPF (protocolo 89) | No hay adyacencia | Los *Hello* llegan por `tcpdump`, pero R1 no declara al vecino |
| Firewall (`input`) y DHCP (UDP 67) | Los clientes no reciben dirección | Entran los `DISCOVER` y no sale ningún `OFFER` |
| Firewall (`input`) y VRRP (protocolo 112) | Ambos routers se creen *master* | Los dos tienen la IP virtual |
| VRRP (15.7) y el direccionamiento de servidores | `10.0.0.1` pasa a ser la IP virtual y R1 usa `10.0.0.2`; la IP no puede estar configurada a la vez como IP normal | Conflicto de direcciones en el segmento de servidores |
| NAT (`iptables`) y filtrado (`nftables`) | Conviven en el mismo namespace y cada uno se gestiona aparte | Se limpia uno y el otro sigue aplicándose |

La lección es la misma del caso final: ante varios síntomas, se busca primero lo que tienen en común.

### Escenarios de fallo y comportamiento esperado

| Fallo | Qué ocurre | Quién lo resuelve | ¿Se recupera solo? |
|-------|------------|-------------------|--------------------|
| Cae el enlace A (R1–R2) | El tráfico pasa al enlace B | OSPF | Sí, en segundos |
| Cae el servicio VRRP de R1 | R2 asume la IP virtual `10.0.0.1` | VRRP | Sí, en segundos |
| Cae la WAN de R1 (R1 sigue vivo) | Los servidores conservan el *gateway* pero pierden la salida | **Nadie** (falta seguimiento y WAN en R2) | **No** (caso B) |
| Se omite `ip protocol ospf accept` | Se pierde la adyacencia; el enlace «funciona» pero no hay rutas dinámicas | El administrador | No |
| Se omite DHCP (UDP 67) en `input` | Los clientes no obtienen IP | El administrador | No |
| Falta la regla DNAT | El servicio publicado no es alcanzable desde fuera aunque `forward` lo permita | El administrador | No |
| MTU menor en un túnel | Las conexiones pequeñas funcionan y las transferencias grandes se cuelgan | Ajuste de MTU/MSS | No |

### Caso final: una incidencia combinada

> **Aviso del equipo:** tras publicar una nueva versión del archivo `fw.nft` en R1, **los equipos que piden dirección ya no reciben IP** y, además, la **sucursal perdió las rutas dinámicas**. Los enlaces A y B están arriba y R1 responde a `ping`.

Los dos síntomas se investigan con una secuencia común de comprobaciones. La práctica dispone de `ping`, `tcpdump`, `nft -a list chain inet firewall input` y `vtysh -c "show ip ospf neighbor"`; la solución desarrollada a continuación muestra cómo correlacionar las evidencias antes de modificar reglas.

??? success "Solución razonada"
    1.  **Conectividad básica.** `ping` a R1 funciona: `input` acepta ICMP. Así que no es un problema de enlace ni de capa 2.
    2.  **Síntoma de rutas.** `show ip ospf neighbor` en R1 no muestra a R2 en estado *Full*. Con `tcpdump -i veth-r1r2a proto ospf` se ven los *Hello* de R2 **llegar** a R1, pero R1 no los procesa y nunca declara al vecino: los descarta el firewall.
    3.  **Síntoma de DHCP.** `tcpdump -i veth-r1fin port 67 or port 68` muestra los `DISCOVER` entrando y ningún `OFFER` saliendo: `dnsmasq` no llega a recibirlos.
    4.  **Un punto en común.** OSPF y DHCP son tráfico **destinado a R1** (cadena `input`), no tráfico que lo atraviesa. Con `policy drop`, solo pasa lo que `input` acepta de forma explícita. `nft -a list chain inet firewall input` muestra que en la nueva versión **faltan** las reglas de protocolo 89 y de UDP 67.
    5.  **Corrección y verificación.** Se restituyen las reglas, se comprueba que la adyacencia vuelve a *Full* y que un cliente obtiene IP. **Una sola causa** (la política de `input`) explicaba dos síntomas aparentemente independientes.

    Lección: ante varios síntomas, busca primero lo que tienen en común (aquí, que el destino era el propio router), y no trates cada servicio por separado.

Para **reproducirlo** (opcional), elimina esas reglas por su *handle* y restitúyelas después:

```bash
sudo ip netns exec R1 nft -a list chain inet firewall input        # anota los handle de «ospf» y «udp dport 67»
sudo ip netns exec R1 nft delete rule inet firewall input handle N   # repite con cada handle

# Restituir
sudo ip netns exec R1 nft insert rule inet firewall input ip protocol ospf accept
sudo ip netns exec R1 nft insert rule inet firewall input iifname '{ "veth-r1fin", "veth-r1ven" }' udp dport 67 accept
```

## Limpieza del laboratorio

Al terminar, se detienen los demonios y elimina solo lo creado aquí. Un namespace **no desaparece del todo mientras tenga procesos dentro**, así que primero se detienen los procesos (todos usan archivos de `/tmp/lab15`):

```bash
# Detener demonios por PID file solo después de validar su línea de comandos.
# Todos los procesos de esta práctica se arrancan con configuración o PID file bajo /tmp/lab15.
PROC_LEFT=0
PIDS_LAB15="/tmp/lab15/r1/zebra.pid /tmp/lab15/r1/ospfd.pid /tmp/lab15/r2/zebra.pid /tmp/lab15/r2/ospfd.pid /tmp/lab15/dhcp.pid /tmp/lab15/dns.pid /tmp/lab15/ka-r1.pid /tmp/lab15/ka-r2.pid /tmp/lab15/ka-r1.vrrp.pid /tmp/lab15/ka-r2.vrrp.pid /tmp/lab15/dhclient-fin.pid /tmp/lab15/dhclient-ven.pid"
pid_matches_lab15() {
  pf=$1; pid=$2
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [ -r "/proc/$pid/cmdline" ] || return 2
  CMDLINE=$(tr '\0' ' ' < "/proc/$pid/cmdline")
  case "$pf" in
    */r1/zebra.pid) [[ "$CMDLINE" == *zebra* && "$CMDLINE" == *"$pf"* ]] ;;
    */r1/ospfd.pid) [[ "$CMDLINE" == *ospfd* && "$CMDLINE" == *"$pf"* ]] ;;
    */r2/zebra.pid) [[ "$CMDLINE" == *zebra* && "$CMDLINE" == *"$pf"* ]] ;;
    */r2/ospfd.pid) [[ "$CMDLINE" == *ospfd* && "$CMDLINE" == *"$pf"* ]] ;;
    */dhcp.pid) [[ "$CMDLINE" == *dnsmasq* && "$CMDLINE" == *"/tmp/lab15/dhcp.conf"* ]] ;;
    */dns.pid) [[ "$CMDLINE" == *dnsmasq* && "$CMDLINE" == *"/tmp/lab15/dns.conf"* ]] ;;
    */ka-r1.pid|*/ka-r1.vrrp.pid) [[ "$CMDLINE" == *keepalived* && "$CMDLINE" == *"/tmp/lab15/ka-r1.conf"* ]] ;;
    */ka-r2.pid|*/ka-r2.vrrp.pid) [[ "$CMDLINE" == *keepalived* && "$CMDLINE" == *"/tmp/lab15/ka-r2.conf"* ]] ;;
    */dhclient-fin.pid) [[ "$CMDLINE" == *dhclient* && "$CMDLINE" == *"$pf"* && "$CMDLINE" == *veth-fin* ]] ;;
    */dhclient-ven.pid) [[ "$CMDLINE" == *dhclient* && "$CMDLINE" == *"$pf"* && "$CMDLINE" == *veth-ven* ]] ;;
    *) return 1 ;;
  esac
}
for pf in $PIDS_LAB15; do
  [ -s "$pf" ] || continue
  pid=$(cat "$pf" 2>/dev/null || true)
  if ! [[ "$pid" =~ ^[0-9]+$ ]]; then echo "PID inválido en $pf; se conserva el estado."; PROC_LEFT=1; continue; fi
  [ -r "/proc/$pid/cmdline" ] || continue
  if pid_matches_lab15 "$pf" "$pid"; then sudo kill -TERM "$pid" 2>/dev/null || true
  else echo "PID $pid no coincide con el servicio esperado para $pf; no se detiene."; PROC_LEFT=1
  fi
done
# Espera una salida normal; KILL solo se aplica si PID, proceso y configuración siguen coincidiendo.
sleep 2
for pf in $PIDS_LAB15; do
  [ -s "$pf" ] || continue
  pid=$(cat "$pf" 2>/dev/null || true)
  [[ "$pid" =~ ^[0-9]+$ ]] || continue
  [ -r "/proc/$pid/cmdline" ] || continue
  if pid_matches_lab15 "$pf" "$pid"; then sudo kill -KILL "$pid" 2>/dev/null || true; fi
done
# Eliminar namespaces propios solo cuando ya no contienen procesos no registrados.
NS_LEFT=0
for ns in R1 R2 SWsrv fin ven ges srv suc; do
  if sudo ip netns list | awk '{print $1}' | grep -Fxq "$ns"; then
    if [ "$(sudo ip netns exec "$ns" cat /sys/class/net/lo/ifalias 2>/dev/null)" != networking-lab-lab-15 ]; then echo "Se conserva $ns: no tiene la marca exclusiva de Lab15."; NS_LEFT=1
    else
      PIDS=$(sudo ip netns pids "$ns" 2>/dev/null || true)
      if [ -n "$PIDS" ]; then echo "Se conserva $ns: quedan procesos no registrados ($PIDS)."; NS_LEFT=1; fi
    fi
  fi
done
if [ "$NS_LEFT" = 0 ] && [ "$PROC_LEFT" = 0 ]; then
  # Retirar TCPMSS dentro de R1 solo si Lab15 añadió la regla.
  if [ -f /tmp/lab15/tcpmss.added ]; then
    sudo ip netns exec R1 iptables -t mangle -D FORWARD -s 10.0.0.0/22 -d 10.10.1.100/32 -o veth-r1-wan -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360 2>/dev/null || true
  fi
  for ns in R1 R2 SWsrv fin ven ges srv suc; do
    if sudo ip netns list | awk '{print $1}' | grep -Fxq "$ns"; then sudo ip netns del "$ns" 2>/dev/null || true; fi
  done
  if [ "$(cat /sys/class/net/veth-wan-r1/ifalias 2>/dev/null)" = networking-lab-lab-15 ]; then sudo ip link del veth-wan-r1; fi
  # /etc/netns/fin y /etc/netns/ven: borrar solo si no existían antes del laboratorio.
  if [ -f /tmp/lab15/netns.preexistente ]; then
    for ns in fin ven; do grep -qx "$ns" /tmp/lab15/netns.preexistente || sudo rm -rf "/etc/netns/$ns"; done
  fi
else echo "Se conservan interfaces y /etc/netns: hay namespaces o PID que requieren revisión."; fi
# Restaura ip_forward al valor original (no se asume 0)
if [ -f /tmp/lab15/host-forward-out.added ]; then
  sudo iptables -D FORWARD -i veth-wan-r1 -o eth0 -s 192.168.100.0/24 -j ACCEPT 2>/dev/null || true
fi
if [ -f /tmp/lab15/host-forward-in.added ]; then
  sudo iptables -D FORWARD -i eth0 -o veth-wan-r1 -d 192.168.100.0/24 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
fi
[ -f /tmp/lab15/ip_forward.orig ] && sudo sysctl -w net.ipv4.ip_forward="$(cat /tmp/lab15/ip_forward.orig)"
# Archivos persistentes del caso ARP: solo si los creó este laboratorio
[ -f /tmp/lab15/creado-99-arp ] && sudo rm -f /etc/sysctl.d/99-networking-lab-arp.conf

# Restaura los umbrales ARP originales
for n in 2 3; do
  [ -f /tmp/lab15/gc_thresh$n.orig ] && sudo sysctl -w net.ipv4.neigh.default.gc_thresh$n="$(cat /tmp/lab15/gc_thresh$n.orig)"
done
if [ -f /tmp/lab15-host-nat.added ]; then
  sudo iptables -t nat -D POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE 2>/dev/null || true
  rm -f /tmp/lab15-host-nat.added
fi
if [ "$NS_LEFT" = 0 ] && [ "$PROC_LEFT" = 0 ]; then
  # Solo eliminar el bridge OVS si el marcador demuestra que lo creó esta práctica.
  if [ -f /tmp/lab15/ovs-sw.created ]; then sudo ovs-vsctl --if-exists del-br ovs-sw; fi
  # Retirar solo interfaces huérfanas en el host con la marca de este laboratorio.
  for f in /sys/class/net/*/ifalias; do
    [ -r "$f" ] || continue
    [ "$(cat "$f")" = networking-lab-lab-15 ] || continue
    dev=${f%/ifalias}; dev=${dev##*/}
    sudo ip link del "$dev" 2>/dev/null || true
  done
else echo "Se conservan OVS y enlaces host mientras existan namespaces o PID que requieren revisión."; fi
if [ "$NS_LEFT" = 0 ] && [ "$PROC_LEFT" = 0 ]; then sudo rm -rf /tmp/lab15; else echo "Se conserva /tmp/lab15 para inspección y limpieza posterior."; fi
```

### Revertir lo que se hizo en el host

| Cambio | Reversión |
|--------|-----------|
| `net.ipv4.ip_forward=1` | Lo restaura el bloque de limpieza con el valor guardado en `/tmp/lab15/ip_forward.orig`; sin ese archivo, usa el valor que anotaste |
| Regla `MASQUERADE` del host | La línea `iptables -t nat -D …` de arriba |
| Interfaz `veth-wan-r1` | La línea `ip link del veth-wan-r1` de arriba |
| **Persistente:** `/etc/sysctl.d/99-networking-lab-arp.conf` (ajuste opcional de umbrales) | Lo elimina el bloque de limpieza, solo si lo creó el laboratorio (si ya existía, no se toca) |
| `gc_thresh2` y `gc_thresh3` cambiados con `sysctl -w` | Los restaura el bloque de limpieza con los valores guardados en `/tmp/lab15/gc_thresh2.orig` y `gc_thresh3.orig` |
| `/tmp/lab15/check_arp.sh` | Se elimina al retirar el directorio temporal `/tmp/lab15` |

Se comprueba al final: `sysctl net.ipv4.ip_forward`, `iptables -t nat -S POSTROUTING` y `ls /etc/sysctl.d/`.

## Conceptos clave

| Concepto | Aplicación |
|----------|------------|
| Configuración básica | Conectividad IP, NAT y ruta por defecto |
| Subnetting | VLSM para segmentación (`10.0.0.0/22`) |
| VLAN | Segmentación lógica (variante **conceptual** con trunk) |
| Routing | Rutas estáticas y OSPF (adyacencia, LSDB, SPF, reconvergencia) |
| Firewall | nftables con política "denegar" y una política de comunicación explícita (el reenvío no publica servicios sin DNAT) |
| DHCP/DNS | Un rango, gateway y resolver DNS interno por subred; zona `secops.local` simplificada opcional |
| VRRP | IP virtual de *gateway* con failover; no redunda toda la infraestructura |
| Troubleshooting | MTU frente a MSS, y tabla ARP |

## Coherencia del conjunto
Cada apartado funciona por sí mismo, pero conviene comprobar que **el conjunto es coherente**:

-   **Direccionamiento:** el mapa red ↔ interfaz del apartado 15.2 es la referencia única; no hay dos interfaces con la misma dirección. En 15.7 la IP de R1 en servidores cambia de `10.0.0.1` a `10.0.0.2` (y la `10.0.0.1` pasa a ser virtual); OSPF sigue anunciando `10.0.0.0/24`.
-   **Firewall frente a protocolos de control:** `input` acepta OSPF, VRRP y DHCP; si falta alguno, ese servicio se rompe de forma silenciosa.
-   **NAT y firewall:** la NAT de salida sigue siendo `iptables` y la política de reenvío es de `nftables`; conviven en el mismo namespace.
-   **VLAN:** el apartado 15.3 es una variante; no se mezcla con los demás.
-   **Alcance de las pruebas:** las comprobaciones de cada apartado demuestran lo que se afirma en él; no demuestran, por ejemplo, que una caída de la WAN se gestione sola (véase VRRP).

## 15.10. Alcance y límites de la integración
La topología principal integra VLSM, routing estático/OSPF, firewall, DHCP, NAT y VRRP en los segmentos indicados. No integra en ejecución VLAN completa, DNS corporativo empresarial (incluye solo una zona interna simplificada opcional), VPN/IPsec/WireGuard, MPLS, ZTNA, nube real ni NOC/SIEM. Esas tecnologías se estudian en escenarios previos o variantes; no debe afirmarse que la topología final las implementa todas.

### RIB, LSDB, SPF y FIB en OSPF

La LSDB describe la topología mediante LSAs; no contiene una ruta de respaldo ya instalada. SPF calcula los caminos a partir de la LSDB; el proceso de routing instala las rutas seleccionadas en la RIB; el kernel mantiene la información de forwarding que usa el plano de datos (FIB). Un cambio en la topología puede provocar nueva ejecución de SPF y actualización de rutas, pero los tiempos dependen de detección, temporizadores, procesamiento y convergencia.

### DHCP y DNS: cerrar el ciclo de servicio

La asignación DHCP debe verificarse junto con máscara, gateway, DNS y lease. La extensión opcional anuncia el DNS interno de R1 y sirve una zona local simplificada; no es un DNS corporativo autoritativo completo. Se comprueba respuestas positivas, TTL, NXDOMAIN y consultas TCP; el reenvío externo depende de la salida WAN. No debe confundirse una concesión DHCP válida con resolución DNS funcional.

### Matriz de disponibilidad por segmento

VRRP se ejecuta solo en la red de servidores en el escenario descrito. Finanzas, Ventas y Gestión mantienen gateways asociados a R1; la sucursal depende de R2; Internet y DHCP también tienen dependencias propias. La matriz siguiente resume las dependencias; el *failover* del *gateway* de servidores no debe generalizarse a toda la empresa:

| Segmento/servicio | Gateway redundante | Dependencia residual | Resultado ante caída de R1 |
|---|---|---|---|
| Servidores | Sí, VIP VRRP | Servicios y rutas de R2 | Solo continuidad si R2 tiene camino y servicios necesarios |
| Finanzas | No en topología base | Gateway R1 | Pierde gateway |
| Ventas | No en topología base | Gateway R1 | Pierde gateway |
| Gestión | No en topología base | Gateway R1 | Pierde gateway |
| Sucursal | No equivalente a VRRP | R2 y su WAN | Depende del enlace y rutas de R2 |
| Internet | No hay WAN independiente en R2 | R1/host | No hay continuidad automática |
| DHCP | Servicio central en R1 | Proceso y conectividad a R1 | Los clientes existentes pueden conservar lease; nuevas concesiones/renovaciones pueden fallar |

### Precauciones operativas
**Open vSwitch:** no elimines `ovs-sw` solo por su nombre. Antes de crearlo, se comprueba que no exista; se registra un marcador de propiedad únicamente cuando esta práctica lo crea. En limpieza, ejecuta `ovs-vsctl --if-exists del-br ovs-sw` solo si existe el marcador y elimina el marcador después. Si el bridge ya existía, se detiene la prueba y no lo reutilices ni lo borres.

**TCPMSS:** una regla ejecutada sin `ip netns exec` modificaría el firewall del host y puede afectar tráfico ajeno. La opción preferida es aplicar la regla dentro del router del laboratorio y limitarla a las interfaces/redes de la práctica. Si por un motivo didáctico se conserva en el host, debe restringirse a interfaces y prefijos propios, registrarse con un marcador y eliminarse con la regla exacta en la limpieza. Nunca debe dejarse una regla global sin reversión.

**Procesos:** evita `pkill -f` como mecanismo general de limpieza. Se guarda PID de `zebra`, `ospfd`, `dnsmasq`, `keepalived` y `dhclient` al iniciarlos; valida que el proceso pertenece a `/tmp/lab15` o a la configuración del laboratorio antes de enviar TERM. Se espera su salida y usa KILL solo como último recurso sobre esos PID validados.

**ARP:** el ajuste de `gc_thresh2/3` modifica umbrales del host; no demuestra por sí mismo agotamiento de la tabla. La prueba se limita a inspección y ajuste de umbrales, cuenta vecinos IPv4 y se comparan dos muestras temporales. No se denomina “simulación de agotamiento”.

## Pruebas de comportamiento

### Prueba 1: Reconvergencia de OSPF

```bash
sudo ip netns exec R1 ip link set veth-r1r2a down
sudo ip netns exec R2 ip link set veth-r2r1a down
sleep 5
sudo ip netns exec R1 ip route show 10.0.2.0/24
sudo ip netns exec suc ping -c 3 10.0.1.10
sudo ip netns exec R1 ip link set veth-r1r2a up
sudo ip netns exec R2 ip link set veth-r2r1a up
```

**Resultado esperado:** la ruta hacia la sucursal pasa del enlace A al B por decisión de OSPF y vuelve al A al restablecerlo.

### Prueba 2: *Failover* de VRRP

Sigue «Verificar y probar el *failover*» del apartado 15.7. **Resultado esperado:** R2 asume la IP virtual del *gateway* de servidores cuando R1 deja de anunciarse.

### Prueba 3: Dos fallos que no deben confundirse

Compara la caída del servicio VRRP de R1 con la caída de su WAN (apartado 15.7). **Resultado esperado:** en el primer caso R2 asume el *gateway*; en el segundo los servidores conservan el *gateway* pero pierden la salida, porque nada protege la WAN de R1.

## Diagnóstico de problemas frecuentes

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| No hay rutas dinámicas aunque el enlace «funciona» | Se omitió `ip protocol ospf accept` en `input` | Permitir el protocolo 89 y comprobar la adyacencia. |
| Los clientes no reciben IP | Se omitió DHCP (UDP 67) en `input` | Permitir UDP 67 desde Finanzas y Ventas. |
| Ambos routers se creen *master* | El firewall bloquea el protocolo 112 de VRRP | Permitir el protocolo 112 en `input`. |
| Los servidores conservan el *gateway* pero pierden la salida | Cae la WAN de R1 mientras R1 sigue vivo | Nadie lo resuelve solo: falta seguimiento y WAN en R2. |
| Un servicio publicado no es alcanzable desde fuera aunque `forward` lo permite | Falta la regla DNAT | Añadir el DNAT. |
| Las conexiones pequeñas funcionan y las transferencias grandes se cuelgan | MTU menor en un túnel | Ajustar MTU o MSS. |

## Análisis técnico y decisiones

VRRP permite que R2 asuma la dirección IP virtual del gateway cuando R1 deja de anunciarse como maestro. Esto protege únicamente el segmento donde está configurado y no crea una segunda salida WAN ni replica automáticamente DHCP, NAT o servicios. Si el firewall bloquea el protocolo IP 112 (VRRP), los routers no intercambian anuncios y la elección puede fallar o producir estados inconsistentes. OSPF detecta cambios de topología y recalcula rutas según sus temporizadores y estado de vecinos; una ruta estática no detecta por sí sola un fallo remoto si el siguiente salto sigue accesible. La implementación conserva dependencias: WAN única, servicios centrales y segmentos sin gateway redundante. Una segunda conexión ISP con routing apropiado, BGP o SD-WAN puede cubrir fallos de salida que VRRP no resuelve.

## Qué no demuestra esta práctica

- VRRP protege únicamente el segmento de servidores: Finanzas, Ventas, Gestión y la sucursal conservan sus dependencias de R1 o R2.
- DHCP y NAT no se replican automáticamente entre R1 y R2.
- No reúne en ejecución todas las tecnologías de los quince laboratorios ni constituye un despliegue de producción.

## Comprensión y reflexión

Responde con tus propias palabras antes de abrir las respuestas orientativas. Un resultado correcto en la terminal no demuestra por sí solo que se haya comprendido el mecanismo.

**Nivel 1 — Reconocimiento.** ¿Qué protege VRRP y qué no protege en este escenario?

**Nivel 2 — Interpretación.** OSPF reconverge al caer el enlace principal: ¿qué determina el tiempo que tarda y qué muestran las rutas antes y después?

**Nivel 3 — Razonamiento.** Bloquea el protocolo IP 112 en el firewall: predice qué le sucede a la elección de VRRP y por qué.

**Caso de diagnóstico.** R2 asume la dirección virtual del *gateway* de servidores, pero los equipos siguen sin servicios. Aplica el [método de diagnóstico](../../04-REFERENCIA/diagnostico.md): síntoma, capa o mecanismo, herramientas, evidencia y conclusión técnica.

??? success "Respuestas orientativas"
    **Nivel 1.** Protege la dirección del *gateway* del segmento de servidores; no crea una segunda salida WAN ni replica DHCP, NAT o servicios.

    **Nivel 2.** Los temporizadores de OSPF determinan cuánto tarda en detectar el cambio y recalcular; la tabla pasa de usar el enlace principal a usar el de respaldo.

    **Nivel 3.** Sin intercambio de anuncios VRRP, los routers no se coordinan: la elección puede fallar o producir estados inconsistentes.

    **Caso de diagnóstico.** Síntoma: servicios sin respuesta tras la conmutación. Mecanismo: VRRP solo cubre el segmento. Herramientas: estado de VRRP, `ip route`, reglas de `nft`, `conntrack`. Evidencia: la dirección virtual está en R2 pero NAT o DHCP siguen configurados solo en R1. Conclusión: son servicios no replicados.

## Estado final

Queda construida y validada una red multisede dentro del alcance declarado: VLSM, OSPF, firewall, DHCP, DNS, NAT y VRRP parcial, con fallos controlados diagnosticados.

VRRP protege únicamente el segmento de servidores; Finanzas, Ventas, Gestión y la sucursal conservan sus dependencias de R1 o R2, y DHCP y NAT no se replican automáticamente. Antes de trasladar el modelo a producción hacen falta planificación, documentación y verificación continua.

## Continuidad técnica

Networking SecOps cierra el recorrido con una infraestructura multisede construida, verificada y sometida a fallos controlados: de dos equipos y un bridge en una oficina vacía a una sede y una sucursal con direccionamiento VLSM, OSPF, firewall, servicios de red y redundancia parcial del *gateway*. Los mecanismos que no entran en esta topología (VLAN, VPN, MPLS, nube, ZTNA y NOC/SIEM) se practicaron en laboratorios previos, y los límites de disponibilidad de la matriz del escenario indican qué falta antes de llevar el diseño a producción.
