<p class="tema-num">LABORATORIO 14</p>

# Herramientas Linux Avanzadas

## Contexto empresarial

La empresa **Networking SecOps** ha implementado su infraestructura de red y sistemas de monitoreo (Laboratorio 13). Ahora el equipo de operaciones necesita dominar las herramientas avanzadas de Linux para administrar, diagnosticar y optimizar la red de manera eficiente.

!!! info "Laboratorio independiente"
    Este laboratorio monta su **propia** topología (un router Linux con LAN y DMZ) para practicar las herramientas con calma; no depende de los anteriores. Empieza limpiando **solo los recursos propios de este escenario** (no todo lo que haya en tu equipo).

## Topología

```mermaid
graph TB
    R[Router Linux]
    WAN["«Internet» = el host, 203.0.113.2"]
    LAN1[Red Interna 10.0.0.0/24]
    LAN2[Red DMZ 10.0.1.0/24]
    H1[Host1 10.0.0.10]
    H2[Host2 10.0.0.20]
    S1[Servidor DMZ 10.0.1.10]
    R --- WAN
    R --- LAN1
    R --- LAN2
    H1 --- LAN1
    H2 --- LAN1
    S1 --- LAN2
```

**Direccionamiento:**

| Dispositivo | Interfaz | Dirección IP |
|-------------|----------|--------------|
| Router Linux | veth-r-wan (WAN) | 203.0.113.1/30 (host: 203.0.113.2/30) |
| Router Linux | br-lan (LAN, bridge) | 10.0.0.1/24 |
| Router Linux | veth-r-lan2 (DMZ) | 10.0.1.1/24 |
| Host1 | veth-lan1-r | 10.0.0.10/24 |
| Host2 | veth-lan2h | 10.0.0.20/24 |
| Servidor DMZ | veth-lan2-r | 10.0.1.10/24 |

**Sobre `203.0.113.0/30`.** Ese bloque pertenece al espacio **reservado para documentación y ejemplos** (TEST-NET-3, RFC 5737): no es una dirección pública real asignada a un proveedor. Aquí **el host actúa como representación de la red externa** (extremo `203.0.113.2` del enlace virtual); la salida a Internet real, si existe, depende de la interfaz física del host (véase el opcional del Paso 3).

## Construcción

### Paso 0: Limpiar el entorno

Elimina únicamente los *namespaces* que crea este laboratorio, por nombre. **No** uses un bucle que borre todos los de `ip netns list`: un usuario puede tener otros entornos virtuales, laboratorios o servicios que utilicen *namespaces*, y esa orden los eliminaría. Esta limpieza solo afecta a los cuatro nombres de este escenario (`Router`, `Host1`, `Host2` y `ServidorDMZ`, con esa capitalización; son distintos de `router` o `host1` de laboratorios anteriores).

```bash
for ns in Router Host1 Host2 ServidorDMZ; do
  sudo ip netns del $ns 2>/dev/null || true
done
sudo ip link del veth-wan-r 2>/dev/null || true   # extremo en el host, si quedó de un intento anterior
sudo apt-get install -y ethtool traceroute tcpdump netcat-openbsd nftables
```

Si los *namespaces* de los laboratorios anteriores te estorban, elimínalos tú **por nombre** (véase el Paso 0 del laboratorio 10) y no con un bucle general.

### Paso 1: Crear namespaces

```bash
sudo ip netns add Router
sudo ip netns add Host1
sudo ip netns add Host2
sudo ip netns add ServidorDMZ
```

### Paso 2: Conectar interfaces

La LAN `10.0.0.0/24` es un único segmento con dos equipos, así que el router usa un bridge (`br-lan`):

```bash
# WAN: el router se conecta al host (que hace de "Internet")
sudo ip link add veth-r-wan type veth peer name veth-wan-r
sudo ip link set veth-r-wan netns Router
sudo ip netns exec Router ip addr add 203.0.113.1/30 dev veth-r-wan
sudo ip netns exec Router ip link set veth-r-wan up
sudo ip addr add 203.0.113.2/30 dev veth-wan-r
sudo ip link set veth-wan-r up

# LAN: bridge en el router con Host1 y Host2
sudo ip netns exec Router ip link add br-lan type bridge
sudo ip netns exec Router ip addr add 10.0.0.1/24 dev br-lan
sudo ip netns exec Router ip link set br-lan up

sudo ip link add veth-r-lan1 type veth peer name veth-lan1-r
sudo ip link set veth-r-lan1 netns Router
sudo ip link set veth-lan1-r netns Host1
sudo ip netns exec Router ip link set veth-r-lan1 master br-lan
sudo ip netns exec Router ip link set veth-r-lan1 up
sudo ip netns exec Host1 ip addr add 10.0.0.10/24 dev veth-lan1-r
sudo ip netns exec Host1 ip link set veth-lan1-r up
sudo ip netns exec Host1 ip link set lo up
sudo ip netns exec Host1 ip route add default via 10.0.0.1

sudo ip link add veth-r-lan2h type veth peer name veth-lan2h
sudo ip link set veth-r-lan2h netns Router
sudo ip link set veth-lan2h netns Host2
sudo ip netns exec Router ip link set veth-r-lan2h master br-lan
sudo ip netns exec Router ip link set veth-r-lan2h up
sudo ip netns exec Host2 ip addr add 10.0.0.20/24 dev veth-lan2h
sudo ip netns exec Host2 ip link set veth-lan2h up
sudo ip netns exec Host2 ip link set lo up
sudo ip netns exec Host2 ip route add default via 10.0.0.1

# DMZ: enlace punto a punto con el servidor
sudo ip link add veth-r-lan2 type veth peer name veth-lan2-r
sudo ip link set veth-r-lan2 netns Router
sudo ip link set veth-lan2-r netns ServidorDMZ
sudo ip netns exec Router ip addr add 10.0.1.1/24 dev veth-r-lan2
sudo ip netns exec Router ip link set veth-r-lan2 up
sudo ip netns exec ServidorDMZ ip addr add 10.0.1.10/24 dev veth-lan2-r
sudo ip netns exec ServidorDMZ ip link set veth-lan2-r up
sudo ip netns exec ServidorDMZ ip link set lo up
sudo ip netns exec ServidorDMZ ip route add default via 10.0.1.1
```

### Paso 3: Configurar enrutamiento y NAT

```bash
sudo ip netns exec Router sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec Router ip route add default via 203.0.113.2
sudo ip netns exec Router ip route show

# NAT del router hacia la WAN
sudo ip netns exec Router iptables -t nat -A POSTROUTING -o veth-r-wan -j MASQUERADE

# (Opcional, para salir de verdad a Internet) El host reenvía y traduce.
# Cambia eth0 por tu interfaz de salida:
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -C POSTROUTING -s 203.0.113.0/30 -o eth0 -j MASQUERADE 2>/dev/null || \
  sudo iptables -t nat -A POSTROUTING -s 203.0.113.0/30 -o eth0 -j MASQUERADE
```

Comprueba la conectividad básica:

```bash
sudo ip netns exec Host1 ping -c 2 10.0.0.20
sudo ip netns exec Host1 ping -c 2 10.0.1.10
sudo ip netns exec Host1 ping -c 2 203.0.113.2
```

### Paso 4: iproute2

```bash
sudo ip netns exec Router ip addr show
sudo ip -br addr                              # vista resumida (en el host)
sudo ip netns exec Router ip -s link show veth-r-lan2   # contadores de la interfaz
sudo ip netns exec Router ip neigh show       # tabla ARP
sudo ip netns exec Router ip rule show        # reglas de política de enrutamiento
sudo ip netns exec Router ip route get 10.0.1.10   # ¿qué ruta usaría el router para este destino?
```

**Cambiar la MTU.** Una MTU mayor solo sirve si **todos** los extremos del enlace la soportan. Cámbiala en **ambos** lados del enlace Router - DMZ y verifícalo:

```bash
sudo ip netns exec Router ip link set veth-r-lan2 mtu 9000
sudo ip netns exec ServidorDMZ ip link set veth-lan2-r mtu 9000
sudo ip netns exec Router ping -c 2 -M do -s 8972 10.0.1.10   # 8972 + 28 = 9000: pasa
```

El cálculo `8972 + 28 = 9000` es correcto para IPv4 con cabeceras IP (20) e ICMP (8) **sin opciones**: la opción `-s` de `ping` indica el tamaño de los **datos ICMP**, no el tamaño total del paquete IP (que es `-s` + 28).

(Si la cambiaras en un solo extremo, los paquetes grandes del lado de MTU mayor serían descartados por el otro.) Restablécela:

```bash
sudo ip netns exec Router ip link set veth-r-lan2 mtu 1500
sudo ip netns exec ServidorDMZ ip link set veth-lan2-r mtu 1500
```

**Agregar una ruta estática.** El siguiente salto debe ser **otro** equipo alcanzable directamente (no una dirección del propio router). Supongamos que existe una red `10.0.2.0/24` detrás de Host1. Para que **la ruta funcione como se describe**, Host1 tiene que **actuar como siguiente salto de capa 3 y reenviar tráfico**, y tener esa red (o un camino hacia ella); de lo contrario la ruta se instala pero el tráfico no llega. Lo simulamos con una interfaz ficticia:

```bash
# Host1 como siguiente salto: reenvía y tiene la red 10.0.2.0/24 «detrás»
sudo ip netns exec Host1 sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec Host1 ip link add dum0 type dummy
sudo ip netns exec Host1 ip addr add 10.0.2.1/24 dev dum0
sudo ip netns exec Host1 ip link set dum0 up

sudo ip netns exec Router ip route add 10.0.2.0/24 via 10.0.0.10
sudo ip netns exec Router ip route get 10.0.2.1       # muestra via 10.0.0.10
sudo ip netns exec Router ping -c 2 10.0.2.1          # llega: Host1 es el siguiente salto

sudo ip netns exec Router ip route del 10.0.2.0/24
sudo ip netns exec Host1 ip link del dum0
```

Sin el `ip_forward` y la red detrás de Host1, la ruta se instalaría igualmente (`ip route get` la mostraría), pero un paquete dirigido a otro equipo de `10.0.2.0/24` no tendría adónde ir.

### Paso 5: ss (sockets)

Arrancamos dos servicios de prueba en Host1 y establecemos una conexión desde Host2:

```bash
sudo ip netns exec Host1 sh -c 'nc -lk -p 9000 >/dev/null 2>&1 </dev/null &'
sudo ip netns exec Host1 sh -c 'nc -lk -p 8443 >/dev/null 2>&1 </dev/null &'
sudo ip netns exec Host2 sh -c 'sleep 30 | nc 10.0.0.10 9000 >/dev/null 2>&1 &'

sudo ip netns exec Host1 ss -tln                    # puertos TCP a la escucha
sudo ip netns exec Host1 ss -tlnp                   # ... con el proceso dueño
sudo ip netns exec Host1 ss -tn state established   # conexiones establecidas (verás la de Host2)
sudo ip netns exec Host1 ss -tn dport = :9000       # filtrar por puerto
```

`ss` muestra los sockets **del namespace en el que se ejecuta**. Una conexión TCP solo aparece en los equipos que son sus **extremos**: un router que simplemente **reenvía** tráfico entre sus interfaces **no aparece como extremo** (para él los paquetes pasan, no terminan en un socket; puede verse el seguimiento de la conexión con `conntrack`, no con `ss`).

### Paso 6: nftables

Cuando una orden `nft` lleva llaves y puntos y coma, hay que **entrecomillarla**: sin comillas, el *shell* corta la orden en cada `;`.

```bash
sudo ip netns exec Router nft add table inet filter
sudo ip netns exec Router nft add chain inet filter input '{ type filter hook input priority 0 ; policy drop ; }'
sudo ip netns exec Router nft add rule inet filter input iif lo accept
sudo ip netns exec Router nft add rule inet filter input ct state established,related accept
sudo ip netns exec Router nft add rule inet filter input icmp type echo-request accept
sudo ip netns exec Router nft add rule inet filter input tcp dport 22 accept
sudo ip netns exec Router nft add rule inet filter input tcp dport '{ 80, 443 }' accept
sudo ip netns exec Router nft -a list ruleset
```

La opción `-a` muestra el *handle* de cada regla, que sirve para borrarla (`nft delete rule inet filter input handle N`).

**Las cadenas `input`, `forward` y `output`.** Son tres puntos de enganche distintos del flujo de un paquete en el router:

| Cadena | Qué controla | Ejemplo |
|--------|--------------|---------|
| `input` | Tráfico **dirigido al propio router** (destino = una IP del router) | SSH o ping **al router** (`10.0.0.1`) |
| `forward` | Tráfico que **atraviesa** el router hacia otra red | Host1 → ServidorDMZ |
| `output` | Tráfico **generado por el propio router** | Un `ping` lanzado desde el router |

Una regla de `input` **controla el tráfico dirigido al router, no el que lo atraviesa**. Esta diferencia es fundamental para comprender un firewall. Compruébalo: aunque la cadena `input` tiene política `drop`, Host1 sigue alcanzando al servidor de la DMZ, porque ese tráfico pasa por `forward`, que aún no tiene reglas:

```bash
sudo ip netns exec Host1 ping -c 2 10.0.1.10        # funciona: no pasa por input
```

Ahora añadimos una cadena `forward` con política `drop` y solo lo necesario:

```bash
sudo ip netns exec Router nft add chain inet filter forward '{ type filter hook forward priority 0 ; policy drop ; }'
sudo ip netns exec Router nft add rule inet filter forward ct state established,related accept
sudo ip netns exec Router nft add rule inet filter forward iifname "br-lan" oifname "veth-r-lan2" tcp dport 22 accept
sudo ip netns exec Host1 ping -c 2 -W 1 10.0.1.10   # ahora falla: forward lo descarta
```

### Paso 7: Diagnóstico

```bash
sudo ip netns exec Router ethtool veth-r-lan2          # velocidad, dúplex, estado del enlace
sudo ip netns exec Router ethtool -S veth-r-lan2       # estadísticas del controlador
sudo ip netns exec Router ping -c 4 10.0.0.10
sudo ip netns exec Router traceroute -n 203.0.113.2
sudo ip netns exec Router tcpdump -i br-lan -c 5 -n
```

Con Internet disponible en tu equipo: `sudo ip netns exec Router traceroute -n 8.8.8.8`.

### Paso 8: Limpieza selectiva

Al terminar, elimina **solo** lo creado por este laboratorio:

```bash
for ns in Router Host1 Host2 ServidorDMZ; do sudo ip netns del $ns 2>/dev/null || true; done
sudo ip link del veth-wan-r 2>/dev/null || true
sudo iptables -t nat -D POSTROUTING -s 203.0.113.0/30 -o eth0 -j MASQUERADE 2>/dev/null || true   # solo si lo añadiste (ajusta eth0)
```

Eliminar un *namespace* borra también sus interfaces y sus reglas de `nft`/`iptables`; las órdenes que tocaron el **host** (`veth-wan-r`, la regla de `MASQUERADE` y `net.ipv4.ip_forward`) hay que revertirlas aparte.

## Ejercicios

### Ejercicio 1: Bloquear ICMP con nftables

Una regla añadida con `add` va **al final** de la cadena, después de la que acepta el ping. Insértala al principio:

```bash
sudo ip netns exec Router nft insert rule inet filter input ip protocol icmp drop
sudo ip netns exec Host1 ping -c 2 -W 1 10.0.0.1     # ahora no responde
sudo ip netns exec Router nft -a list chain inet filter input
```

Para quitar la regla usa `nft delete rule inet filter input handle N` con el *handle* que muestra el listado.

### Ejercicio 2: Verificar conexiones con ss

```bash
sudo ip netns exec Host1 ss -tn state established
sudo ip netns exec Host2 ss -tn state established
```

Comprueba que la conexión de Paso 5 aparece en **ambos** extremos (Host1 y Host2) pero no en el router.

## Conceptos clave

| Concepto | Aplicación |
|----------|------------|
| iproute2 | Administración moderna de red |
| ss | Análisis de sockets del namespace donde se ejecuta |
| nftables | Firewall moderno; `input` ≠ `forward` ≠ `output` |
| ethtool | Diagnóstico físico |
| Netcat | Pruebas de conectividad |

## Conclusiones

Las herramientas avanzadas de Linux (`ip`, `ss`, `nft`) permiten administrar y diagnosticar redes de manera eficiente y han sustituido en la práctica a las tradicionales (`ifconfig`, `netstat`, `iptables`), que siguen existiendo en muchos sistemas. Entender **dónde engancha cada regla** (`input`, `forward`, `output`) es clave para comprender un firewall.

---

**¡Laboratorio 14 completado!** Continúa con el **Laboratorio 15**.
