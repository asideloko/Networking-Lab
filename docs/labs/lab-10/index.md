<p class="tema-num">LABORATORIO 10</p>

# Infraestructura WAN y Core

## Contexto empresarial

La empresa **Networking SecOps** ha implementado exitosamente su red con VPN y tunelización (Laboratorio 09). Ahora necesita expandir su infraestructura a nivel geográfico, conectando múltiples sucursales y centros de datos a través de una red WAN robusta y escalable.

## Objetivos del laboratorio

1.  Construir una red troncal de proveedor con **routers PE** (*Provider Edge*) y **routers P** (*Provider*) en malla parcial.
2.  Interconectar tres LAN remotas a través del núcleo con **rutas estáticas**.
3.  Comprobar la **redundancia** de la malla y el reparto de carga con **ECMP**.
4.  Comprender (a nivel conceptual) cómo MPLS reenvía por etiquetas y en qué se diferencia de SD-WAN.

!!! warning "Qué es ejecutable y qué es conceptual"
    - **Ejecutable:** topología PE/P, rutas estáticas, failover por métricas y ECMP.
    - **Conceptual:** MPLS (*push/swap/pop*) y SD-WAN. Aquí **no** se configuran etiquetas reales (eso exigiría los módulos `mpls_router` y `mpls_iptunnel`) y no se usa OSPF ni BGP: con rutas estáticas el núcleo **no reconverge solo** ante fallos remotos. El enrutamiento dinámico se practica en el Laboratorio 15.

## Topología

```mermaid
graph TB
    R1[PE1]
    R2[PE2]
    R3[PE3]
    P1[P Router 1]
    P2[P Router 2]
    P3[P Router 3]
    LAN1[Red Local 10.0.0.0/24]
    LAN2[Red Local 10.1.0.0/24]
    LAN3[Red Local 10.2.0.0/24]
    R1 --- P1
    R2 --- P2
    R3 --- P3
    LAN1 --- R1
    LAN2 --- R2
    LAN3 --- R3
    P1 --- P2
    P2 --- P3
    P1 --- P3
```

**Direccionamiento:**

| Dispositivo | Interfaz | Dirección IP | Rol |
|-------------|----------|--------------|-----|
| PE1 | eth0 (LAN) | 10.0.0.1/24 | Provider Edge |
| host1 | - | 10.0.0.10/24 | Equipo de la LAN 1 |
| PE1 | eth1 (P1) | 192.168.1.1/30 | MPLS Core |
| PE2 | eth0 (LAN) | 10.1.0.1/24 | Provider Edge |
| host2 | - | 10.1.0.10/24 | Equipo de la LAN 2 |
| PE2 | eth1 (P2) | 192.168.1.5/30 | MPLS Core |
| PE3 | eth0 (LAN) | 10.2.0.1/24 | Provider Edge |
| host3 | - | 10.2.0.10/24 | Equipo de la LAN 3 |
| PE3 | eth1 (P3) | 192.168.1.9/30 | MPLS Core |
| P1 | eth0 (R1) | 192.168.1.2/30 | P Router |
| P1 | eth1 (P2) | 192.168.1.13/30 | P Router |
| P1 | eth2 (P3) | 192.168.1.17/30 | P Router |
| P2 | eth0 (R2) | 192.168.1.6/30 | P Router |
| P2 | eth1 (P1) | 192.168.1.14/30 | P Router |
| P2 | eth2 (P3) | 192.168.1.21/30 | P Router |
| P3 | eth0 (R3) | 192.168.1.10/30 | P Router |
| P3 | eth1 (P1) | 192.168.1.18/30 | P Router |
| P3 | eth2 (P2) | 192.168.1.22/30 | P Router |

## Construcción de la red

### Paso 0: Limpiar laboratorios anteriores (recomendado)

Este laboratorio usa una topología nueva e independiente. Para no mezclar equipos, elimina lo construido en los laboratorios 01 a 09:

```bash
for ns in $(ip netns list | awk '{print $1}'); do sudo ip netns del $ns; done
sudo ip link del br-wan 2>/dev/null || true
sudo ip link del veth-host 2>/dev/null || true
```

### Paso 1: Crear namespaces

```bash
sudo ip netns add PE1
sudo ip netns add PE2
sudo ip netns add PE3
sudo ip netns add P1
sudo ip netns add P2
sudo ip netns add P3
sudo ip netns add host1
sudo ip netns add host2
sudo ip netns add host3

# Un router solo reenvía si ip_forward vale 1 (en un namespace nuevo vale 0)
for r in PE1 PE2 PE3 P1 P2 P3; do
  sudo ip netns exec $r sysctl -w net.ipv4.ip_forward=1
done
```

### Paso 2: Conectar PE a P

```bash
sudo ip link add veth-pe1p1 type veth peer name veth-p1pe1
sudo ip link set veth-pe1p1 netns PE1
sudo ip link set veth-p1pe1 netns P1
sudo ip netns exec PE1 ip addr add 192.168.1.1/30 dev veth-pe1p1
sudo ip netns exec PE1 ip link set veth-pe1p1 up
sudo ip netns exec P1 ip addr add 192.168.1.2/30 dev veth-p1pe1
sudo ip netns exec P1 ip link set veth-p1pe1 up

sudo ip link add veth-pe2p2 type veth peer name veth-p2pe2
sudo ip link set veth-pe2p2 netns PE2
sudo ip link set veth-p2pe2 netns P2
sudo ip netns exec PE2 ip addr add 192.168.1.5/30 dev veth-pe2p2
sudo ip netns exec PE2 ip link set veth-pe2p2 up
sudo ip netns exec P2 ip addr add 192.168.1.6/30 dev veth-p2pe2
sudo ip netns exec P2 ip link set veth-p2pe2 up

sudo ip link add veth-pe3p3 type veth peer name veth-p3pe3
sudo ip link set veth-pe3p3 netns PE3
sudo ip link set veth-p3pe3 netns P3
sudo ip netns exec PE3 ip addr add 192.168.1.9/30 dev veth-pe3p3
sudo ip netns exec PE3 ip link set veth-pe3p3 up
sudo ip netns exec P3 ip addr add 192.168.1.10/30 dev veth-p3pe3
sudo ip netns exec P3 ip link set veth-p3pe3 up
```

### Paso 3: Conectar P routers

```bash
sudo ip link add veth-p1p2 type veth peer name veth-p2p1
sudo ip link set veth-p1p2 netns P1
sudo ip link set veth-p2p1 netns P2
sudo ip netns exec P1 ip addr add 192.168.1.13/30 dev veth-p1p2
sudo ip netns exec P1 ip link set veth-p1p2 up
sudo ip netns exec P2 ip addr add 192.168.1.14/30 dev veth-p2p1
sudo ip netns exec P2 ip link set veth-p2p1 up

sudo ip link add veth-p2p3 type veth peer name veth-p3p2
sudo ip link set veth-p2p3 netns P2
sudo ip link set veth-p3p2 netns P3
sudo ip netns exec P2 ip addr add 192.168.1.21/30 dev veth-p2p3
sudo ip netns exec P2 ip link set veth-p2p3 up
sudo ip netns exec P3 ip addr add 192.168.1.22/30 dev veth-p3p2
sudo ip netns exec P3 ip link set veth-p3p2 up

sudo ip link add veth-p1p3 type veth peer name veth-p3p1
sudo ip link set veth-p1p3 netns P1
sudo ip link set veth-p3p1 netns P3
sudo ip netns exec P1 ip addr add 192.168.1.17/30 dev veth-p1p3
sudo ip netns exec P1 ip link set veth-p1p3 up
sudo ip netns exec P3 ip addr add 192.168.1.18/30 dev veth-p3p1
sudo ip netns exec P3 ip link set veth-p3p1 up
```

### Paso 4: Configurar redes locales (un equipo en cada LAN)

```bash
for n in 1 2 3; do
  case $n in 1) NET=10.0.0.;; 2) NET=10.1.0.;; 3) NET=10.2.0.;; esac
  sudo ip link add veth-pe${n}lan type veth peer name veth-lanpe${n}
  sudo ip link set veth-pe${n}lan netns PE${n}
  sudo ip link set veth-lanpe${n} netns host${n}
  sudo ip netns exec PE${n} ip addr add ${NET}1/24 dev veth-pe${n}lan
  sudo ip netns exec PE${n} ip link set veth-pe${n}lan up
  sudo ip netns exec host${n} ip addr add ${NET}10/24 dev veth-lanpe${n}
  sudo ip netns exec host${n} ip link set veth-lanpe${n} up
  sudo ip netns exec host${n} ip link set lo up
  sudo ip netns exec host${n} ip route add default via ${NET}1
done
```

### Paso 5: Configurar enrutamiento estático

Cada PE envía al P al que está conectado todo lo que no conoce:

```bash
sudo ip netns exec PE1 ip route add default via 192.168.1.2
sudo ip netns exec PE2 ip route add default via 192.168.1.6
sudo ip netns exec PE3 ip route add default via 192.168.1.10
```

Los P conocen el núcleo. Entre P1 y P3 hay un enlace directo (camino preferido) y un camino de respaldo por P2 con `metric 100`:

```bash
# P1
sudo ip netns exec P1 ip route add 192.168.1.4/30 via 192.168.1.14
sudo ip netns exec P1 ip route add 192.168.1.8/30 via 192.168.1.18
sudo ip netns exec P1 ip route add 192.168.1.8/30 via 192.168.1.14 metric 100
sudo ip netns exec P1 ip route add 10.0.0.0/24 via 192.168.1.1
sudo ip netns exec P1 ip route add 10.1.0.0/24 via 192.168.1.14
sudo ip netns exec P1 ip route add 10.2.0.0/24 via 192.168.1.18
sudo ip netns exec P1 ip route add 10.2.0.0/24 via 192.168.1.14 metric 100

# P2
sudo ip netns exec P2 ip route add 192.168.1.0/30 via 192.168.1.13
sudo ip netns exec P2 ip route add 192.168.1.8/30 via 192.168.1.22
sudo ip netns exec P2 ip route add 10.0.0.0/24 via 192.168.1.13
sudo ip netns exec P2 ip route add 10.1.0.0/24 via 192.168.1.5
sudo ip netns exec P2 ip route add 10.2.0.0/24 via 192.168.1.22

# P3
sudo ip netns exec P3 ip route add 192.168.1.0/30 via 192.168.1.17
sudo ip netns exec P3 ip route add 192.168.1.0/30 via 192.168.1.21 metric 100
sudo ip netns exec P3 ip route add 192.168.1.4/30 via 192.168.1.21
sudo ip netns exec P3 ip route add 10.0.0.0/24 via 192.168.1.17
sudo ip netns exec P3 ip route add 10.0.0.0/24 via 192.168.1.21 metric 100
sudo ip netns exec P3 ip route add 10.1.0.0/24 via 192.168.1.21
sudo ip netns exec P3 ip route add 10.2.0.0/24 via 192.168.1.9
```

### Paso 6: Verificar conectividad

```bash
# Entre equipos de LAN distintas, a través del núcleo
sudo ip netns exec host1 ping -c 4 10.1.0.10
sudo ip netns exec host1 ping -c 4 10.2.0.10

# Camino que sigue el tráfico (host1 -> host3 pasa por PE1, P1, P3, PE3)
sudo ip netns exec host1 traceroute -n 10.2.0.10

# Entre routers PE
sudo ip netns exec PE1 ping -c 4 192.168.1.5
```

## Análisis MPLS (conceptual)

MPLS utiliza etiquetas para el reenvío. El flujo es:

1. **Push**: PE1 añade etiqueta al paquete.
2. **Swap**: P routers intercambian etiquetas.
3. **Pop**: PE3 elimina etiqueta y entrega.

## Comparación MPLS vs SD-WAN

| Característica | MPLS | SD-WAN |
|----------------|------|--------|
| Control | Distribuido | Centralizado |
| Transporte | Circuitos privados | Múltiples enlaces |
| QoS | Garantizada | Best-effort |
| Costo | Alto | Bajo |
| Agilidad | Baja | Alta |

## Ejercicios

### Ejercicio 1: Simular un fallo en el núcleo

Tiramos el enlace directo P1-P3 (camino preferido) **por sus dos extremos**: así ambos routers retiran su ruta y activan la de respaldo por P2.

```bash
sudo ip netns exec P1 ip link set veth-p1p3 down
sudo ip netns exec P3 ip link set veth-p3p1 down
sudo ip netns exec host1 ping -c 4 10.2.0.10
sudo ip netns exec host1 traceroute -n 10.2.0.10
```

**Salida esperada:** 0% de pérdida y un salto más (P2, `192.168.1.14`). Restablece después el enlace (`up` en ambos extremos) y vuelve a añadir las rutas de métrica 0 que se retiraron al bajar la interfaz.

!!! warning "Sin reconvergencia automática"
    Si en lugar del enlace P1-P3 cae el P2-P3, P1 **no se entera** y sigue usando una ruta estática que ya no sirve. Detectar fallos remotos es tarea de OSPF/BGP (Laboratorio 15).

### Ejercicio 2: Balanceo ECMP

ECMP reparte el tráfico entre varios caminos de igual coste. Se define con **una sola ruta de varios saltos** (`nexthop`), no con dos `ip route add` (el segundo daría `File exists`). Por defecto el reparto se calcula solo con las IP de origen y destino; con la política 1 también se usan los puertos y se ven los dos caminos:

```bash
sudo ip netns exec P1 sysctl -w net.ipv4.fib_multipath_hash_policy=1
sudo ip netns exec P1 ip route replace 10.2.0.0/24 nexthop via 192.168.1.18 weight 1 nexthop via 192.168.1.14 weight 1
sudo ip netns exec P1 ip route show 10.2.0.0/24

# Varios flujos TCP distintos (puertos de origen distintos) pueden tomar caminos distintos
for sp in 40001 40002 40003 40004 40005 40006; do
  sudo ip netns exec P1 ip route get 10.2.0.10 from 10.0.0.10 iif veth-p1pe1 ipproto tcp sport $sp dport 80 | head -1
done
```

## Conceptos clave

| Concepto | Aplicación |
|----------|------------|
| MPLS | Backbone con etiquetas |
| SD-WAN | Optimización multi-enlace |
| Backbone | Red troncal con P y PE (rutas estáticas con respaldo) |
| ECMP | Reparto de carga entre caminos de igual coste |

## Conclusiones

MPLS permite ingeniería de tráfico y QoS mediante el reenvío por etiquetas (la calidad no es automática: depende de cómo el proveedor la configure). SD-WAN ofrece flexibilidad y reducción de costos. Las arquitecturas híbridas aprovechan lo mejor de ambos mundos.

---

**¡Laboratorio 10 completado!** Continúa con el **Laboratorio 11**.
