<p class="tema-num">LABORATORIO 15</p>

# Implementación Práctica Integral

## Contexto empresarial

La empresa **Networking SecOps** ha completado todos los laboratorios anteriores. Ahora debe **integrar todos los conceptos** en una implementación práctica completa: direccionamiento VLSM, enrutamiento dinámico con OSPF, firewall, DHCP y redundancia de *gateway* con VRRP.

!!! info "Mismo modelo que el resto de la serie"
    Todo se construye con **namespaces de red**, igual que en los laboratorios anteriores (no se usan interfaces `eth0`-`eth4` reales del equipo, así que no se toca tu red). Es un laboratorio de integración con una topología nueva, por lo que empieza limpiando el entorno. Requiere instalar `frr` (OSPF), `keepalived` (VRRP) y `dnsmasq-base` (DHCP).

!!! note "Este es un escenario nuevo"
    Los laboratorios 01–14 usaron topologías diferentes. Aquí **se reutilizan los nombres `R1` y `R2` con otra función y otro direccionamiento** (sede y respaldo/sucursal), y el escenario se construye desde cero. Cada apartado funciona por sí mismo, pero la coherencia global se comprueba en el apartado «Revisión de coherencia» al final: que cada bloque funcione aisladamente no garantiza que el conjunto sea coherente.

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

## Construcción

### Paso 0: Limpiar y preparar

Elimina **solo los namespaces de los laboratorios anteriores, por nombre** (un bucle que borrara todos los de `ip netns list` afectaría también a otros entornos de tu equipo):

```bash
for ns in cliente1 cliente2 cliente3 cliente4 router switch \
          ventas1 ventas2 ventas3 it1 it2 it3 admin1 admin2 \
          R1 R2 R3 clienteSede clienteSucA clienteSucB \
          servidorDNS servidorDHCP clienteDHCP \
          firewall servidorWeb servidorDNS_PUB servidorInterno VPN_GW clienteVPN \
          PE1 PE2 PE3 P1 P2 P3 host1 host2 host3 \
          Core1 Core2 Dist1 Dist2 Access1 Firewall ServidorWeb ServidorDNS ventas it admin \
          OnPremise AppServer DBServer AWS_VPC EC2_Server RDS_Server ZTNA_Broker IDP User1 User2 NOC SIEM \
          Router Host1 Host2 ServidorDMZ SWsrv fin ven ges srv suc; do
  sudo ip netns del $ns 2>/dev/null || true
done
sudo ip link del br-wan 2>/dev/null || true
sudo apt-get install -y frr keepalived dnsmasq-base isc-dhcp-client nftables netcat-openbsd

for ns in R1 R2 SWsrv fin ven ges srv suc; do sudo ip netns add $ns; done
for r in R1 R2; do sudo ip netns exec $r sysctl -qw net.ipv4.ip_forward=1; done

# enlace NS_A IF_A IP_A NS_B IF_B IP_B
enlace() {
  sudo ip link add $2 type veth peer name $5
  sudo ip link set $2 netns $1
  sudo ip link set $5 netns $4
  sudo ip netns exec $1 ip addr add $3 dev $2
  sudo ip netns exec $1 ip link set $2 up
  sudo ip netns exec $4 ip addr add $6 dev $5
  sudo ip netns exec $4 ip link set $5 up
}
mkdir -p /tmp/lab15
```

## 15.1 Configuración de red básica

R1 es el router de la sede: una WAN hacia el host (que hace de "Internet"), NAT, y su primera LAN (Finanzas).

La WAN une R1 con el **host** (sin namespace), así que se configura a mano:

```bash
sudo ip link add veth-r1-wan type veth peer name veth-wan-r1
sudo ip link set veth-r1-wan netns R1
sudo ip netns exec R1 ip addr add 192.168.100.1/24 dev veth-r1-wan
sudo ip netns exec R1 ip link set veth-r1-wan up
sudo ip addr add 192.168.100.2/24 dev veth-wan-r1
sudo ip link set veth-wan-r1 up

# R1: ruta por defecto hacia el host y NAT hacia la WAN
sudo ip netns exec R1 ip route add default via 192.168.100.2
sudo ip netns exec R1 iptables -t nat -A POSTROUTING -o veth-r1-wan -j MASQUERADE

# El host reenvía y traduce hacia tu red real (cambia eth0 por tu interfaz de salida)
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -C POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE 2>/dev/null || \
  sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE

# Primera LAN: Finanzas (10.0.1.0/25)
enlace R1 veth-r1fin 10.0.1.1/25 fin veth-fin 10.0.1.10/25
sudo ip netns exec fin ip route add default via 10.0.1.1
```

### Verificar

```bash
sudo ip netns exec fin ping -c 3 10.0.1.1
sudo ip netns exec fin ping -c 3 192.168.100.2
```

(Con Internet en tu equipo, `ping 8.8.8.8` y `nslookup google.com 8.8.8.8` desde `fin` también funcionan.)

## 15.2 Subnetting aplicado (VLSM)

**Bloque disponible:** `10.0.0.0/22` (de `10.0.0.0` a `10.0.3.255`).

| Departamento | Hosts | Subred | Máscara | Rango útil | Gateway |
|--------------|-------|--------|---------|------------|---------|
| Servidores | 200 | 10.0.0.0/24 | /24 | 10.0.0.1 - 10.0.0.254 | 10.0.0.1 |
| Finanzas | 100 | 10.0.1.0/25 | /25 | 10.0.1.1 - 10.0.1.126 | 10.0.1.1 |
| Ventas | 50 | 10.0.1.128/26 | /26 | 10.0.1.129 - 10.0.1.190 | 10.0.1.129 |
| Gestión | 10 | 10.0.1.192/28 | /28 | 10.0.1.193 - 10.0.1.206 | 10.0.1.193 |
| Enlace A R1-R2 | 2 | 10.0.1.208/30 | /30 | 10.0.1.209 - 10.0.1.210 | - |
| Enlace B R1-R2 | 2 | 10.0.1.212/30 | /30 | 10.0.1.213 - 10.0.1.214 | - |
| Sucursal (R2) | 200 | 10.0.2.0/24 | /24 | 10.0.2.1 - 10.0.2.254 | 10.0.2.1 |

Cada bloque se asigna de mayor a menor sin solaparse.

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

Ahora creamos el resto de segmentos (Finanzas ya existe):

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
sudo ip link set veth-r1srv netns R1
sudo ip link set veth-sw-r1 netns SWsrv
sudo ip netns exec SWsrv ip link set veth-sw-r1 master br0
sudo ip netns exec SWsrv ip link set veth-sw-r1 up
sudo ip netns exec R1 ip addr add 10.0.0.1/24 dev veth-r1srv
sudo ip netns exec R1 ip link set veth-r1srv up
sudo ip link add veth-srv type veth peer name veth-sw-srv
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

Comprueba que cada equipo alcanza a su *gateway* y entre sí a través de R1:

```bash
sudo ip netns exec fin ping -c 2 10.0.1.130     # Finanzas -> Ventas (R1 enruta)
sudo ip netns exec srv ping -c 2 10.0.1.194     # Servidores -> Gestión
sudo ip netns exec R1 ping -c 2 10.0.1.210      # R1 -> R2 por el enlace A
```

## 15.3 VLAN (variante conceptual)

!!! warning "Ejemplo conceptual, no integrable directamente"
    En 15.2 cada departamento usa **una interfaz independiente** de R1. En una red real lo habitual es **un único enlace *trunk*** que transporta varias VLAN. Esta variante se presenta como **ejemplo conceptual**: **no es una configuración integral que pueda incorporarse directamente a la topología anterior** (no coexisten con las mismas subredes), y no se ha encadenado con el resto del laboratorio. Este laboratorio sigue con segmentos separados para poder verificarlos en cualquier máquina.

La configuración con un bridge Linux con filtrado de VLAN y *router-on-a-stick* es la del laboratorio 05 (requiere el módulo `8021q`). Con Open vSwitch, los elementos que hay que definir son estos:

| Elemento | Qué es | Dónde |
|----------|--------|-------|
| `ovs-sw` | El switch (bridge OVS) | host |
| `puerto-fin`, `puerto-ven`, `puerto-ges` | Puertos **access** de las VLAN 10, 20, 30; cada uno es un extremo de un `veth` cuyo otro extremo va al equipo final (`fin`, `ven`, `ges`) | host (extremo del switch) |
| `trunk-r1` ↔ `trunk` | Enlace **trunk**: `trunk-r1` es el puerto del switch y **recibe/envía las etiquetas 802.1Q**; su otro extremo `trunk` va a R1 | host / R1 |
| `trunk.10`, `trunk.20`, `trunk.30` | **Subinterfaces** de R1 sobre `trunk`, una por VLAN, con la IP del *gateway* de cada VLAN | R1 |

```bash
sudo apt-get install -y openvswitch-switch
sudo ovs-vsctl add-br ovs-sw

# Equipos finales: veth cuyo extremo "puerto-*" queda en el switch y el otro va a cada equipo
for h in "fin 10" "ven 20" "ges 30"; do
  set -- $h
  sudo ip link add puerto-$1 type veth peer name veth-eq-$1
  sudo ip link set veth-eq-$1 netns $1
  sudo ip link set puerto-$1 up
  sudo ovs-vsctl add-port ovs-sw puerto-$1 tag=$2      # puerto de acceso (sin etiqueta hacia el equipo)
done

# Trunk hacia R1: el switch etiqueta 10, 20 y 30
sudo ip link add trunk-r1 type veth peer name trunk
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
```

Los equipos finales (`fin`, `ven`, `ges`) tendrían su IP y su *gateway* como en 15.2, pero conectados al puerto de acceso de su VLAN. Estas subinterfaces llevan las IP de *gateway* **en lugar de** las interfaces `veth-r1fin`, `veth-r1ven` y `veth-r1ges` del 15.2: **no deben coexistir las dos formas** con las mismas subredes. Verifica en tu propio entorno antes de adoptarlo: este bloque ilustra el modelo trunk/access, no se encadena con el firewall, el DHCP ni el OSPF de los apartados siguientes (que usan los nombres de interfaz del 15.2).

## 15.4 Routing entre redes

### Rutas estáticas

```bash
sudo ip netns exec R2 ip route add default via 10.0.1.209
sudo ip netns exec R1 ip route add 10.0.2.0/24 via 10.0.1.210

sudo ip netns exec suc ping -c 2 10.0.1.10        # Sucursal -> Finanzas
sudo ip netns exec suc ping -c 2 192.168.100.2    # Sucursal -> "Internet" (vía R1 y su NAT)
sudo ip netns exec R1 ip route show
```

Funciona, pero las rutas estáticas no se adaptan solas a los cambios. Las eliminamos y usamos un protocolo dinámico.

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
sudo chown -R frr:frr /tmp/lab15
sudo chmod 755 /tmp /tmp/lab15

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
3.  **Base de datos de estado de enlace (LSDB):** cada router acumula los LSA y construye una **vista idéntica de la topología**.
4.  **Cálculo SPF:** cada router ejecuta el algoritmo de Dijkstra sobre esa base de datos y obtiene el **camino de menor coste acumulado** hacia cada red. El coste de un camino es la **suma** de los costes de los enlaces que atraviesa.
5.  **Selección de ruta:** de entre los caminos calculados (aquí, por el enlace A con coste 10 o por el B con coste 20), se instala en la tabla de rutas el de menor coste. El B queda **preparado** en la base de datos pero no se usa mientras A sea mejor. Si dos caminos tuvieran el mismo coste, se instalarían los dos (ECMP).
6.  **Reconvergencia:** cuando un enlace cae, el router lo **detecta** (por pérdida de la interfaz o por vencer el tiempo de *dead*), **genera un LSA nuevo**, lo propaga, los routers **actualizan su LSDB y recalculan SPF** y se instalan las nuevas rutas.

Por eso la reconvergencia del apartado siguiente es rápida **aquí**: la interfaz cae y se detecta al instante; si el fallo fuera más allá de la interfaz (un fallo remoto), el vecino se declararía caído al vencer el *dead interval* (40 s por defecto), y la reconvergencia sería más lenta salvo con temporizadores ajustados o BFD.

**La ruta por defecto: `default-information originate always`.** Con esta orden R1 **anuncia a los demás routers una ruta por defecto**. La palabra `always` hace que la anuncie **incluso si R1 no dispone de una ruta por defecto válida** en su tabla. En este escenario R1 sí tiene una salida configurada hacia el host (`default via 192.168.100.2`), pero conviene saber qué significa: sin `always`, R1 solo anunciaría la ruta mientras tuviera una propia. **Que se anuncie una ruta no garantiza que el acceso exterior funcione**: si la WAN de R1 cayera, R2 seguiría recibiendo la ruta por defecto (con `always`) y enviando allí el tráfico. Quitar `always` hace que el anuncio dependa de la ruta real de R1.

### Reconvergencia ante un fallo

Tiramos el enlace principal (A) por ambos extremos y observamos cómo OSPF mueve el tráfico al respaldo sin intervención:

```bash
sudo ip netns exec R1 ip link set veth-r1r2a down
sudo ip netns exec R2 ip link set veth-r2r1a down
sleep 5
sudo ip netns exec R1 ip route show 10.0.2.0/24        # ahora por el enlace B (10.0.1.214)
sudo ip netns exec suc ping -c 3 10.0.1.10
sudo ip netns exec R1 ip link set veth-r1r2a up
sudo ip netns exec R2 ip link set veth-r2r1a up
```

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

Una versión anterior permitía el tráfico sin restricción entre las LAN departamentales; eso contradecía la idea de segmentación y se ha sustituido por la política anterior.

!!! note "Permitir el reenvío no equivale a publicar el servicio"
    La regla «Internet → Servidores en 80, 443 y 25» **solo permite el reenvío** si el paquete llega con un destino interno por la interfaz WAN. **No crea por sí sola la traducción de destino ni la accesibilidad exterior.** Para publicar un servicio privado hace falta normalmente **DNAT** (o direccionamiento público, o una arquitectura equivalente), además de rutas y políticas de seguridad. Ejemplo para publicar el puerto 80 del servidor `10.0.0.10` en la dirección WAN de R1:

    ```bash
    sudo ip netns exec R1 iptables -t nat -A PREROUTING -i veth-r1-wan -p tcp --dport 80 -j DNAT --to-destination 10.0.0.10:80
    sudo ip netns exec srv sh -c 'nc -l -p 80 >/dev/null 2>&1 </dev/null &'
    nc -zv -w 2 192.168.100.1 80        # desde el host («Internet»)
    ```

    Sin la regla de `PREROUTING`, el host no alcanzaría el servidor aunque la política de `forward` lo permitiera.

### Verificar

```bash
sudo ip netns exec fin ping -c 2 192.168.100.2     # salida a "Internet": permitida
sudo ip netns exec fin ping -c 2 -W 1 10.0.1.130   # Finanzas -> Ventas: BLOQUEADO (sin regla entre LAN)
sudo ip netns exec ges ping -c 2 10.0.1.10         # Gestión -> Finanzas: permitido (administración)
sudo ip netns exec srv ping -c 2 -W 1 10.0.1.10    # Servidores -> Finanzas: bloqueado
sudo ip netns exec R1 nft list ruleset | grep -A1 counter
```

(La NAT hacia Internet sigue siendo la regla `iptables` de R1 del apartado 15.1.)

## 15.6 Servicios: DHCP con dnsmasq

R1 reparte direcciones en Finanzas y Ventas, con un rango por subred y su propio *gateway*. Antes de leer la configuración, fija la correspondencia:

| Interfaz de R1 | Segmento | Rango DHCP | Máscara | Gateway entregado | Etiqueta de dnsmasq |
|----------------|----------|------------|---------|-------------------|---------------------|
| `veth-r1fin` | Finanzas (10.0.1.0/25) | 10.0.1.20 – 10.0.1.120 | 255.255.255.128 | 10.0.1.1 | `fin` |
| `veth-r1ven` | Ventas (10.0.1.128/26) | 10.0.1.140 – 10.0.1.190 | 255.255.255.192 | 10.0.1.129 | `ven` |

**Cómo se asocian las etiquetas con los rangos.** `dhcp-range=set:fin,…` **crea la etiqueta `fin` para los clientes que reciban una dirección de ese rango**; `dhcp-option=tag:fin,option:router,…` aplica la opción de *gateway* **solo** a los clientes con esa etiqueta. Así, cada cliente recibe el *gateway* de su subred. Dnsmasq decide el rango por la interfaz por la que llega la petición.

**Qué parámetros recibe cada cliente:** dirección IP, máscara, puerta de enlace (`router`), servidor DNS y duración de la concesión (24 h). **Papel del servidor DNS anunciado:** `dhcp-option=option:dns-server,8.8.8.8` indica a los clientes a quién preguntar por nombres. `8.8.8.8` es un **DNS público de ejemplo**, **no un servidor DNS interno de la empresa**; en una red real se anunciaría el DNS corporativo (laboratorio 07). Recuerda que DHCP y DNS son servicios independientes: recibir una IP no garantiza que la resolución funcione.

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
dhcp-option=option:dns-server,8.8.8.8
dhcp-leasefile=/tmp/lab15/dhcp.leases
EOF

sudo dnsmasq --test --conf-file=/tmp/lab15/dhcp.conf
sudo ip netns exec R1 dnsmasq --conf-file=/tmp/lab15/dhcp.conf --pid-file=/tmp/lab15/dhcp.pid
```

Los clientes piden dirección en lugar de tener una fija. Para que `dhclient` no toque el `resolv.conf` de tu equipo, damos a cada namespace el suyo:

```bash
for ns in fin ven; do
  sudo mkdir -p /etc/netns/$ns
  sudo touch /etc/netns/$ns/resolv.conf
done

# Finanzas: quitar la IP fija y pedirla por DHCP
sudo ip netns exec fin ip addr flush dev veth-fin
sudo ip netns exec fin dhclient -v veth-fin
sudo ip netns exec fin ip -4 addr show dev veth-fin
sudo ip netns exec fin ip route show

# Ventas
sudo ip netns exec ven ip addr flush dev veth-ven
sudo ip netns exec ven dhclient -v veth-ven
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

# Falla R1 (se detiene su VRRP): la IP virtual pasa a R2
sudo kill $(cat /tmp/lab15/ka-r1.vrrp.pid) $(cat /tmp/lab15/ka-r1.pid)
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

## 15.8 Troubleshooting real

Casos de diagnóstico habituales. Los ejemplos de direcciones (`10.10.1.100`) son **ilustrativos**: no corresponden a un equipo de esta topología. Los comandos siguientes sirven para **representar un diagnóstico de paquetes que atraviesan un túnel**; **no** verifican el túnel construido en apartados anteriores (en este laboratorio no hay ningún túnel GRE ni IPsec).

### Caso: degradación por MTU en un túnel (IPsec/GRE)

**No uses MTU y MSS indistintamente:**

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
sudo iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
# (o, sin fijar el valor: -j TCPMSS --clamp-mss-to-pmtu)
```

### Caso: agotamiento de la tabla ARP

```bash
dmesg | grep -i neighbour
ip neigh show | wc -l
sysctl net.ipv4.neigh.default.gc_thresh3
sudo sysctl -w net.ipv4.neigh.default.gc_thresh3=8192
sudo sysctl -w net.ipv4.neigh.default.gc_thresh2=4096
# Para que persista tras reiniciar:
echo 'net.ipv4.neigh.default.gc_thresh3=8192' | sudo tee -a /etc/sysctl.d/99-arp.conf
echo 'net.ipv4.neigh.default.gc_thresh2=4096' | sudo tee -a /etc/sysctl.d/99-arp.conf
sudo sysctl --system
```

### Script de verificación ARP

```bash
sudo tee /usr/local/bin/check_arp.sh > /dev/null << 'EOF'
#!/bin/bash
THRESHOLD=7000
CURRENT=$(ip neigh show | wc -l)
if [ "$CURRENT" -gt "$THRESHOLD" ]; then
    echo "WARNING: ARP table usage high: $CURRENT entries"
fi
EOF
sudo chmod +x /usr/local/bin/check_arp.sh
```

## Conceptos clave

| Concepto | Aplicación |
|----------|------------|
| Configuración básica | Conectividad IP, NAT y ruta por defecto |
| Subnetting | VLSM para segmentación (`10.0.0.0/22`) |
| VLAN | Segmentación lógica (variante **conceptual** con trunk) |
| Routing | Rutas estáticas y OSPF (adyacencia, LSDB, SPF, reconvergencia) |
| Firewall | nftables con política "denegar" y una política de comunicación explícita (el reenvío no publica servicios sin DNAT) |
| DHCP | Un rango y un gateway por subred; DNS público de ejemplo |
| VRRP | IP virtual de *gateway* con failover; no redunda toda la infraestructura |
| Troubleshooting | MTU frente a MSS, y tabla ARP |

## Revisión de coherencia del escenario global

Cada apartado funciona por sí mismo, pero conviene comprobar que **el conjunto es coherente**:

-   **Direccionamiento:** el mapa red ↔ interfaz del apartado 15.2 es la referencia única; no hay dos interfaces con la misma dirección. En 15.7 la IP de R1 en servidores cambia de `10.0.0.1` a `10.0.0.2` (y la `10.0.0.1` pasa a ser virtual); OSPF sigue anunciando `10.0.0.0/24`.
-   **Firewall frente a protocolos de control:** `input` acepta OSPF, VRRP y DHCP; si falta alguno, ese servicio se rompe de forma silenciosa.
-   **NAT y firewall:** la NAT de salida sigue siendo `iptables` y la política de reenvío es de `nftables`; conviven en el mismo namespace.
-   **VLAN:** el apartado 15.3 es una variante; no se mezcla con los demás.
-   **Alcance de las pruebas:** las comprobaciones de cada apartado demuestran lo que se afirma en él; no demuestran, por ejemplo, que una caída de la WAN se gestione sola (véase VRRP).

## Conclusiones

Este laboratorio integra los conceptos de la serie: direccionamiento IP, enrutamiento dinámico, firewall, servicios y alta disponibilidad de *gateway*, y cierra con técnicas de diagnóstico. La implementación práctica de una red empresarial completa requiere planificación, documentación y verificación continua.

---

**¡Laboratorio 15 completado!** Has construido una red empresarial funcional.
