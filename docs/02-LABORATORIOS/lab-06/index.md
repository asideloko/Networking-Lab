---
title: "LABORATORIO 06 · ENRUTAMIENTO Y CONECTIVIDAD ENTRE REDES"
description: "Laboratorio 06 de NETWORKING Lab — Enrutamiento y Conectividad entre Redes."
---

<p class="tema-eyebrow">LABORATORIO 06</p>

# ENRUTAMIENTO Y CONECTIVIDAD ENTRE REDES

<p class="tema-meta"><span>12 secciones</span><span>4 diagramas</span><span>7 tablas</span></p>

## Contexto empresarial

La empresa **Networking SecOps** ha implementado exitosamente su red con VLANs y Router-on-a-Stick. Ahora necesita **conectar su sede central con dos sucursales** (Sucursal A y Sucursal B) que se encuentran en ubicaciones geográficas diferentes. Cada sucursal tiene su propia red local y necesita comunicarse con la sede y entre sí.

El equipo de redes ha decidido implementar:

1. **Rutas estáticas** para conectar las oficinas, con una ruta alternativa (métricas) para tolerar fallos.
2. **Túneles GRE** para conectar redes no contiguas a través de Internet.

!!! note "Alcance: enrutamiento dinámico"
    Este laboratorio trabaja **solo con enrutamiento estático**. Las rutas estáticas no se adaptan solas a un fallo remoto; esa limitación es la que justifica un protocolo dinámico. **[OSPF](https://www.rfc-editor.org/rfc/rfc2328) se implementa de forma real con FRRouting en el Laboratorio 15.**

## Problema inicial

- La sede central tiene una red con VLANs (Ventas, IT, Administración).
- Las sucursales A y B tienen sus propias redes locales.
- No hay conectividad entre las oficinas.
- Se necesita enrutar el tráfico entre todas las redes.

## Objetivos del laboratorio

1.  Comprender los principios del enrutamiento IP.
2.  Configurar **rutas estáticas** y la **ruta por defecto**.
3.  Comprender por qué el enrutamiento estático no basta a escala (OSPF se practica en el Laboratorio 15).
4.  Analizar la **tabla de enrutamiento** y el proceso de **[longest prefix match](https://www.rfc-editor.org/rfc/rfc1812)**.
5.  Configurar un **túnel GRE** para interconectar redes remotas.
6.  Verificar la conectividad entre todas las oficinas.

## Topología

La topología consta de tres routers (R1, R2, R3) que representan la sede y dos sucursales. Para centrarnos en el enrutamiento, la sede se simplifica a una sola LAN (`10.0.0.0/24`): las VLAN del Laboratorio 05 no se vuelven a montar aquí.

```mermaid
graph TB
    subgraph Sede_Central
        R1[Router 1 Sede]
        LAN1[Red Sede 10.0.0.0/24]
    end
    subgraph Sucursal_A
        R2[Router 2 Sucursal A]
        LAN2[Red Sucursal A 10.0.1.0/24]
    end
    subgraph Sucursal_B
        R3[Router 3 Sucursal B]
        LAN3[Red Sucursal B 10.0.2.0/24]
    end
    R1 ---|"192.168.1.0/30"| R2
    R2 ---|"192.168.2.0/30"| R3
    LAN1 --- R1
    R1 ---|"192.168.3.0/30 (Paso 6)"| R3
    LAN2 --- R2
    LAN3 --- R3
```

**Redes de tránsito.** Existen tres redes punto a punto distintas, una por enlace entre routers:

-   `192.168.1.0/30`: R1–R2.
-   `192.168.2.0/30`: R2–R3.
-   `192.168.3.0/30`: R1–R3 (se añade en el Paso 6).

Además, cada router tiene conectada su propia LAN (`10.0.0.0/24`, `10.0.1.0/24`, `10.0.2.0/24`).

**Direccionamiento:**

| Dispositivo | Interfaz | Dirección IP |
|-------------|----------|--------------|
| R1 (Sede) | `veth-r1c` (LAN) | 10.0.0.1/24 |
| R1 (Sede) | `veth-r1r2` (R1-R2) | 192.168.1.1/30 |
| R1 (Sede) | `veth-r1r3` (R1-R3, Paso 6) | 192.168.3.1/30 |
| R2 (Sucursal A) | `veth-r2c` (LAN) | 10.0.1.1/24 |
| R2 (Sucursal A) | `veth-r2r1` (R1-R2) | 192.168.1.2/30 |
| R2 (Sucursal A) | `veth-r2r3` (R2-R3) | 192.168.2.1/30 |
| R3 (Sucursal B) | `veth-r3c` (LAN) | 10.0.2.1/24 |
| R3 (Sucursal B) | `veth-r3r2` (R2-R3) | 192.168.2.2/30 |
| R3 (Sucursal B) | `veth-r3r1` (R1-R3, Paso 6) | 192.168.3.2/30 |
| Cliente Sede | - | 10.0.0.10/24 |
| Cliente Sucursal A | - | 10.0.1.10/24 |
| Cliente Sucursal B | - | 10.0.2.10/24 |

## Construcción de la red

### Paso 0: Limpiar ejecuciones anteriores de este laboratorio

Este paso solo retira los namespaces creados por Lab06. No elimina recursos de Lab05 ni de otros laboratorios: ejecuta primero la limpieza de la práctica propietaria para que sus rutas, reglas y cambios del host se reviertan correctamente.

```bash
NS_LAB="R1 R2 R3 clienteSede clienteSucA clienteSucB"
EXISTENTES=$(sudo ip netns list | awk '{print $1}' | while read -r ns; do
  for esperado in $NS_LAB; do [ "$ns" = "$esperado" ] && echo "$ns"; done
done)
NS_SIN_MARCA=""
for ns in $EXISTENTES; do
  if [ "$(sudo ip netns exec "$ns" cat /sys/class/net/lo/ifalias 2>/dev/null)" != networking-lab-owned ]; then NS_SIN_MARCA="$NS_SIN_MARCA $ns"; fi
done
if [ -n "$NS_SIN_MARCA" ]; then echo "Se aborta; namespaces sin marca:$NS_SIN_MARCA"; exit 1; fi
for ns in $EXISTENTES; do
  PIDS=$(sudo ip netns pids "$ns" 2>/dev/null || true)
  if [ -n "$PIDS" ]; then echo "$ns tiene procesos activos ($PIDS); ejecuta su limpieza antes de repetir Lab06."; exit 1; fi
done
for ns in $EXISTENTES; do sudo ip netns del "$ns" 2>/dev/null || true; done
```

Si siguen activos namespaces de otras prácticas, ejecuta su reversión; este paso no los modifica.
### Paso 1: Crear namespaces y enlaces

Creamos tres routers y tres clientes (uno por oficina).

```bash
# Routers
sudo ip netns add R1
sudo ip netns exec R1 ip link set lo alias networking-lab-owned
sudo ip netns add R2
sudo ip netns exec R2 ip link set lo alias networking-lab-owned
sudo ip netns add R3
sudo ip netns exec R3 ip link set lo alias networking-lab-owned

# Clientes
sudo ip netns add clienteSede
sudo ip netns exec clienteSede ip link set lo alias networking-lab-owned
sudo ip netns add clienteSucA
sudo ip netns exec clienteSucA ip link set lo alias networking-lab-owned
sudo ip netns add clienteSucB
sudo ip netns exec clienteSucB ip link set lo alias networking-lab-owned
```

### Paso 2: Conectar routers y clientes

```bash
# Enlace R1 - R2
sudo ip link add veth-r1r2 type veth peer name veth-r2r1
sudo ip link set veth-r1r2 alias networking-lab-lab-06
sudo ip link set veth-r2r1 alias networking-lab-lab-06
sudo ip link set veth-r1r2 netns R1
sudo ip link set veth-r2r1 netns R2

# Enlace R2 - R3
sudo ip link add veth-r2r3 type veth peer name veth-r3r2
sudo ip link set veth-r2r3 alias networking-lab-lab-06
sudo ip link set veth-r3r2 alias networking-lab-lab-06
sudo ip link set veth-r2r3 netns R2
sudo ip link set veth-r3r2 netns R3

# Cliente Sede -> R1
sudo ip link add veth-c1 type veth peer name veth-r1c
sudo ip link set veth-c1 alias networking-lab-lab-06
sudo ip link set veth-r1c alias networking-lab-lab-06
sudo ip link set veth-c1 netns clienteSede
sudo ip link set veth-r1c netns R1

# Cliente Sucursal A -> R2
sudo ip link add veth-c2 type veth peer name veth-r2c
sudo ip link set veth-c2 alias networking-lab-lab-06
sudo ip link set veth-r2c alias networking-lab-lab-06
sudo ip link set veth-c2 netns clienteSucA
sudo ip link set veth-r2c netns R2

# Cliente Sucursal B -> R3
sudo ip link add veth-c3 type veth peer name veth-r3c
sudo ip link set veth-c3 alias networking-lab-lab-06
sudo ip link set veth-r3c alias networking-lab-lab-06
sudo ip link set veth-c3 netns clienteSucB
sudo ip link set veth-r3c netns R3
```

### Paso 3: Asignar direcciones IP y activar interfaces

**Router R1 (Sede):**

```bash
sudo ip netns exec R1 ip addr add 10.0.0.1/24 dev veth-r1c
sudo ip netns exec R1 ip addr add 192.168.1.1/30 dev veth-r1r2
sudo ip netns exec R1 ip link set veth-r1c up
sudo ip netns exec R1 ip link set veth-r1r2 up
sudo ip netns exec R1 ip link set lo up
```

**Router R2 (Sucursal A):**

```bash
sudo ip netns exec R2 ip addr add 10.0.1.1/24 dev veth-r2c
sudo ip netns exec R2 ip addr add 192.168.1.2/30 dev veth-r2r1
sudo ip netns exec R2 ip addr add 192.168.2.1/30 dev veth-r2r3
sudo ip netns exec R2 ip link set veth-r2c up
sudo ip netns exec R2 ip link set veth-r2r1 up
sudo ip netns exec R2 ip link set veth-r2r3 up
sudo ip netns exec R2 ip link set lo up
```

**Router R3 (Sucursal B):**

```bash
sudo ip netns exec R3 ip addr add 10.0.2.1/24 dev veth-r3c
sudo ip netns exec R3 ip addr add 192.168.2.2/30 dev veth-r3r2
sudo ip netns exec R3 ip link set veth-r3c up
sudo ip netns exec R3 ip link set veth-r3r2 up
sudo ip netns exec R3 ip link set lo up
```

**Clientes:**

```bash
# Sede
sudo ip netns exec clienteSede ip addr add 10.0.0.10/24 dev veth-c1
sudo ip netns exec clienteSede ip link set veth-c1 up
sudo ip netns exec clienteSede ip link set lo up

# Sucursal A
sudo ip netns exec clienteSucA ip addr add 10.0.1.10/24 dev veth-c2
sudo ip netns exec clienteSucA ip link set veth-c2 up
sudo ip netns exec clienteSucA ip link set lo up

# Sucursal B
sudo ip netns exec clienteSucB ip addr add 10.0.2.10/24 dev veth-c3
sudo ip netns exec clienteSucB ip link set veth-c3 up
sudo ip netns exec clienteSucB ip link set lo up
```

### Paso 4: Habilitar el reenvío y configurar rutas estáticas

**Cómo decide un router el siguiente salto.** Para cada paquete, el router busca en su tabla la ruta con el prefijo **más específico** que contenga la dirección de destino (*longest prefix match*). Esa ruta indica el siguiente salto (`via`) o la interfaz de salida (`dev`). Un router solo conoce automáticamente las redes **directamente conectadas**; las LAN que están *detrás* de otro router no las conoce hasta que se le indica (ruta estática) o las aprende (protocolo dinámico). Por eso R1 necesita una ruta hacia `10.0.1.0/24` y `10.0.2.0/24`, y cada router otra hacia las LAN remotas.

Un router solo reenvía paquetes entre interfaces si `ip_forward` vale 1. En un namespace nuevo vale 0, así que hay que activarlo **en cada router**:

```bash
for r in R1 R2 R3; do
  sudo ip netns exec $r sysctl -w net.ipv4.ip_forward=1
done
```

Las rutas hacia la sucursal más lejana se declaran con `metric 100` para poder añadir después, sin conflicto, una ruta mejor (Paso 6). Dos rutas al mismo prefijo con la misma métrica no pueden coexistir: `ip route add` respondería `File exists`.

**En R1 (Sede):**

```bash
sudo ip netns exec R1 ip route add 10.0.1.0/24 via 192.168.1.2
sudo ip netns exec R1 ip route add 10.0.2.0/24 via 192.168.1.2 metric 100
```

**En R2 (Sucursal A):**

```bash
sudo ip netns exec R2 ip route add 10.0.0.0/24 via 192.168.1.1
sudo ip netns exec R2 ip route add 10.0.2.0/24 via 192.168.2.2
```

**En R3 (Sucursal B):**

```bash
sudo ip netns exec R3 ip route add 10.0.0.0/24 via 192.168.2.1 metric 100
sudo ip netns exec R3 ip route add 10.0.1.0/24 via 192.168.2.1
```

**Ruta por defecto en clientes:**

```bash
sudo ip netns exec clienteSede ip route add default via 10.0.0.1
sudo ip netns exec clienteSucA ip route add default via 10.0.1.1
sudo ip netns exec clienteSucB ip route add default via 10.0.2.1
```

### Paso 5: Verificar conectividad

```bash
# Desde Sede a Sucursal A
sudo ip netns exec clienteSede ping -c 4 10.0.1.10

# Desde Sucursal A a Sucursal B
sudo ip netns exec clienteSucA ping -c 4 10.0.2.10

# Ver tabla de enrutamiento en R1
sudo ip netns exec R1 ip route show
```

**Resultado esperado:** 0% de pérdida en todos los pings.

### Ruta por defecto frente a ruta específica

Hasta ahora todas las rutas entre oficinas son **específicas** (un prefijo concreto, como `10.0.1.0/24`). Una **ruta por defecto** (`default`, es decir, `0.0.0.0/0`) es la que se usa **solo cuando no existe una coincidencia más específica** en la tabla. Los clientes de este laboratorio la usan: no saben dónde está cada red remota, así que envían todo lo que no es local a su router. Una ruta por defecto en un router de sucursal serviría, por ejemplo, para enviar a la sede todo lo que no sea su LAN; en este laboratorio no la configuramos en los routers porque queremos ver el *longest prefix match* con rutas específicas. Puedes comprobar cuál se elige con:

```bash
sudo ip netns exec R1 ip route get 10.0.2.10
```

### Tipos de ruta en la tabla

| Tipo | Cómo aparece en `ip route` | Quién la crea | Cuándo se usa |
|------|----------------------------|---------------|---------------|
| **Conectada** | `10.0.0.0/24 dev … scope link` | El kernel, al asignar IP a una interfaz | Destino en una red directamente conectada |
| **Estática** | `10.0.2.0/24 via 192.168.1.2` | El administrador | Destino en una red remota conocida |
| **Por defecto** | `default via …` | El administrador (o [DHCP](https://www.rfc-editor.org/rfc/rfc2131)) | Solo si **ninguna** ruta más específica coincide |

### Cómo se elige la ruta: *longest prefix match*

El router compara la IP de destino con **todas** las rutas y elige la de **prefijo más largo** (máscara más específica); la métrica solo desempata entre rutas del **mismo** prefijo.

```mermaid
flowchart TD
    P(["Paquete a 10.0.2.10"]) --> T{"Rutas que coinciden"}
    T --> A["default 0.0.0.0/0 (prefijo /0)"]
    T --> B["10.0.0.0/16 (prefijo /16)"]
    T --> C["10.0.2.0/24 (prefijo /24)"]
    A --> W{"¿Cuál es la más específica?"}
    B --> W
    C --> W
    W --> R(["Gana 10.0.2.0/24: el prefijo más largo"])
```

### Recorrido de un paquete entre sucursales

`clienteSucA → clienteSucB` (`10.0.1.10 → 10.0.2.10`) atraviesa dos routers. La **IP** de origen y de destino no cambian; en cada salto se **reescribe la cabecera Ethernet** y el **TTL baja en 1**.

```mermaid
sequenceDiagram
    participant CA as clienteSucA 10.0.1.10
    participant R2 as R2
    participant R3 as R3
    participant CB as clienteSucB 10.0.2.10
    CA->>R2: IP 10.0.1.10 a 10.0.2.10, TTL 64 (gateway por defecto)
    R2->>R3: mismo IP, TTL 63 (siguiente salto 192.168.2.2)
    R3->>CB: mismo IP, TTL 62 (red conectada)
    CB-->>CA: respuesta por el camino de retorno
```

El **TTL** evita bucles infinitos: cada router lo decrementa y, si llega a 0, descarta el paquete y envía un ICMP *Time Exceeded*. `traceroute` lo aprovecha: manda paquetes con TTL 1, 2, 3… y registra quién responde en cada salto.

### Paso 6: Agregar un enlace directo R1-R3 (camino preferido)

Un enlace directo es un camino más corto. Lo agregamos y le damos una **métrica menor (50)**: Linux elige siempre la ruta de menor métrica, y deja la ruta por R2 (métrica 100) como respaldo.

```bash
# Crear enlace R1-R3
sudo ip link add veth-r1r3 type veth peer name veth-r3r1
sudo ip link set veth-r1r3 alias networking-lab-lab-06
sudo ip link set veth-r3r1 alias networking-lab-lab-06
sudo ip link set veth-r1r3 netns R1
sudo ip link set veth-r3r1 netns R3
sudo ip netns exec R1 ip addr add 192.168.3.1/30 dev veth-r1r3
sudo ip netns exec R1 ip link set veth-r1r3 up
sudo ip netns exec R3 ip addr add 192.168.3.2/30 dev veth-r3r1
sudo ip netns exec R3 ip link set veth-r3r1 up

# Rutas por el enlace directo (preferidas por su métrica menor)
sudo ip netns exec R1 ip route add 10.0.2.0/24 via 192.168.3.2 metric 50
sudo ip netns exec R3 ip route add 10.0.0.0/24 via 192.168.3.1 metric 50
```

Comprueba qué camino usa ahora el tráfico (debe pasar directamente por R3):

```bash
sudo ip netns exec R1 ip route show 10.0.2.0/24
sudo ip netns exec clienteSede traceroute -n 10.0.2.10
```

(Si `traceroute` no está instalado: `sudo apt install traceroute`.)

### Paso 7: Simular un fallo y verificar la redundancia

Tiramos el **enlace preferido** (R1-R3) por **sus dos extremos**. Con rutas estáticas, un router solo "sabe" que un enlace cayó si es uno de sus propios enlaces: por eso el fallo debe afectar a ambos routers del enlace.

```bash
sudo ip netns exec R1 ip link set veth-r1r3 down
sudo ip netns exec R3 ip link set veth-r3r1 down

# La ruta de métrica 50 desaparece y entra la de métrica 100 (por R2)
sudo ip netns exec R1 ip route show 10.0.2.0/24
sudo ip netns exec clienteSede ping -c 4 10.0.2.10
sudo ip netns exec clienteSede traceroute -n 10.0.2.10
```

**Resultado esperado:** 0% de pérdida y un salto adicional (R2, `192.168.1.2`) en el `traceroute`.

**Los dos caminos entre R1 y R3.** Con ambos enlaces activos decide la métrica; al caer el directo, solo queda el alternativo:

```mermaid
graph LR
    R1((R1)) ==>|"directo, métrica 50 (preferido)"| R3((R3))
    R1 -->|"métrica 100"| R2((R2))
    R2 -->|"192.168.2.0/30"| R3
```

| Momento | `ip route show 10.0.2.0/24` en R1 | `traceroute` a `10.0.2.10` |
|---------|-----------------------------------|-----------------------------|
| Enlace directo activo | `via 192.168.3.2 metric 50` (la de métrica 100 queda en reserva) | 2 saltos: R1, R3 |
| Enlace directo caído | solo `via 192.168.1.2 metric 100` | 3 saltos: R1, R2, R3 |

!!! info "Enlaces redundantes no son convergencia automática"
    Tener un camino alternativo **configurado** no equivale a tener un mecanismo de **convergencia**. Aquí la conmutación al respaldo funciona porque el fallo es **local** (el propio router ve su interfaz caer y el kernel retira la ruta). Ante un fallo remoto, o con la interfaz activa pero un camino roto más allá, la ruta estática seguiría instalada y el tráfico se perdería. Un protocolo dinámico (OSPF) intercambia información de topología y recalcula por sí mismo.

!!! warning "Limitación de las rutas estáticas"
    Si en cambio cae el enlace R2-R3 (un fallo **remoto** para R1), R1 seguiría enviando tráfico por R2 y se perdería: las rutas estáticas no detectan fallos que no son de su propio enlace. Para eso existen los protocolos dinámicos (Laboratorio 15).

Restablece el enlace antes de continuar:

```bash
sudo ip netns exec R1 ip link set veth-r1r3 up
sudo ip netns exec R3 ip link set veth-r3r1 up
sudo ip netns exec R1 ip route replace 10.0.2.0/24 via 192.168.3.2 metric 50
sudo ip netns exec R3 ip route replace 10.0.0.0/24 via 192.168.3.1 metric 50
```

### Paso 8: Configurar túnel GRE

**GRE** (Generic Routing Encapsulation) **encapsula paquetes de una red dentro de otros paquetes IP** (protocolo IP 47), de modo que dos extremos pueden comportarse como si tuvieran un enlace punto a punto entre ellos. Cuatro precisiones:

-   Los **extremos del túnel deben ser alcanzables** entre sí por IP (aquí, `192.168.3.1` y `192.168.3.2` sobre el enlace directo del Paso 6).
-   **Crear el túnel no crea rutas** hacia las redes remotas: solo existe la red del propio túnel (`10.100.0.0/30`). Hay que añadir rutas que usen `gre1` como salida.
-   **GRE no cifra ni autentica** el tráfico. Para protegerlo se combina con IPsec (laboratorio 09).
-   El encabezado adicional reduce la MTU efectiva del túnel (en Linux, `gre1` suele quedar en 1476).

Necesitan el módulo `ip_gre` del kernel (`sudo modprobe ip_gre`). El túnel se monta sobre el enlace directo R1-R3 del Paso 6, que debe estar activo. En un caso real los extremos estarían a través de Internet; aquí es un enlace virtual.

```bash
# En R1
sudo ip netns exec R1 ip tunnel add gre1 mode gre remote 192.168.3.2 local 192.168.3.1 ttl 255
sudo ip netns exec R1 ip addr add 10.100.0.1/30 dev gre1
sudo ip netns exec R1 ip link set gre1 up

# En R3
sudo ip netns exec R3 ip tunnel add gre1 mode gre remote 192.168.3.1 local 192.168.3.2 ttl 255
sudo ip netns exec R3 ip addr add 10.100.0.2/30 dev gre1
sudo ip netns exec R3 ip link set gre1 up

# Verificar túnel
sudo ip netns exec R1 ping -c 4 10.100.0.2
```

Para que el túnel transporte tráfico entre las LAN hay que dirigir hacia él las rutas correspondientes. Ejemplo (con métrica menor que las rutas anteriores, y deshaciéndolo después):

```bash
sudo ip netns exec R1 ip route add 10.0.2.0/24 via 10.100.0.2 metric 20
sudo ip netns exec R3 ip route add 10.0.0.0/24 via 10.100.0.1 metric 20
sudo ip netns exec R1 ip route get 10.0.2.10     # sale por gre1
sudo ip netns exec clienteSede ping -c 2 10.0.2.10
sudo ip netns exec clienteSede traceroute -n 10.0.2.10   # el túnel cuenta como un solo salto

# Deshacer
sudo ip netns exec R1 ip route del 10.0.2.0/24 via 10.100.0.2 metric 20
sudo ip netns exec R3 ip route del 10.0.0.0/24 via 10.100.0.1 metric 20
# ... y el propio túnel, para dejar libre el nombre gre1 (el laboratorio 09 lo reutiliza)
sudo ip netns exec R1 ip tunnel del gre1
sudo ip netns exec R3 ip tunnel del gre1
```

Fíjate en que `traceroute` ahora ve el túnel como **un solo salto** (`10.100.0.2`).

### Redundancia frente a convergencia

| Concepto | Qué es | En este laboratorio |
|----------|--------|---------------------|
| **Redundancia** | Existen caminos alternativos **configurados**. | La ruta de métrica 100 por R2. |
| **Convergencia** | Los routers **detectan** el cambio y recalculan por sí mismos. | **No existe**: solo hay detección local (caída de la propia interfaz). |

Un fallo **remoto** sigue rompiendo la comunicación con rutas estáticas; resolverlo exige un protocolo dinámico (OSPF en el laboratorio 15).

### GRE frente a IPsec (adelanto del laboratorio 09)

| Aspecto | GRE | IPsec (ESP, modo túnel) |
|---------|-----|--------------------------|
| Función | **Encapsular** (crea un enlace virtual punto a punto) | **Proteger** (cifrar, autenticar, verificar integridad) |
| Cifrado | No | Sí |
| Multicast / protocolos de enrutamiento | Los admite | Limitado (suele combinarse con GRE) |
| Uso habitual | Interconectar redes no contiguas | Proteger tráfico entre sedes |

Se complementan: un diseño habitual es **GRE sobre IPsec**.

## Análisis de la tabla de enrutamiento

```bash
sudo ip netns exec R1 ip route show
```

**Interpretación de la salida:**

- Las rutas conectadas directamente (directas) aparecen con `dev` y `scope link`.
- Las rutas estáticas aparecen con `via` (el siguiente salto) y, si se indicó, `metric`.
- La ruta por defecto (si existe) aparece como `default via …` (equivale a `0.0.0.0/0`); en R1 no hay ninguna.
- Para ver qué ruta se **elegiría** para un destino concreto, usa `ip route get`.

## Ejercicios prácticos

### Ejercicio 1: Agregar una nueva oficina

Agrega una cuarta oficina (Sucursal C) con red 10.0.3.0/24, conéctala a R2 y configura las rutas necesarias para que todos los clientes se comuniquen.

### Ejercicio 2: Verificar el TTL

Desde el cliente Sede, haz un `traceroute` a la Sucursal B y observa cómo los routers decrementan el TTL.

```bash
sudo ip netns exec clienteSede traceroute -n 10.0.2.10
```

### Ejercicio 3: Fallo remoto y rutas de respaldo

Baja el enlace R2-R3 por **ambos extremos** (`veth-r2r3` en R2 y `veth-r3r2` en R3) y comprueba que `clienteSucA` ya no alcanza a `clienteSucB`, aunque físicamente exista el camino R2 → R1 → R3. Después agrega rutas de respaldo con métrica 100 (en R2 hacia `192.168.1.1`; en R3, para la Sucursal A, hacia `192.168.3.1`) y vuelve a probar.

## Errores comunes y soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| Ping falla entre oficinas | Falta ruta de retorno. | Verificar rutas en ambos sentidos. |
| Traceroute muestra asteriscos | Firewall bloquea ICMP. | Permitir ICMP en las políticas. |
| El túnel GRE no funciona | IPs de extremos no accesibles. | Verificar conectividad entre extremos. |

## Conceptos clave del Tema 6 aplicados

| Concepto | Aplicación en el laboratorio |
|----------|------------------------------|
| Enrutamiento | Conexión entre redes diferentes |
| Ruta estática | Configuración manual de rutas |
| Ruta por defecto | Gateway para el tráfico sin coincidencia más específica (la usan los clientes) |
| Tabla de enrutamiento | `ip route show` en cada router |
| Longest prefix match | Selección de ruta más específica |
| Túnel GRE | Conexión de redes no contiguas |

## Limpieza del laboratorio

Todos los dispositivos y enlaces de esta topología viven dentro de los *namespaces*. No se modifica el reenvío, las rutas ni el firewall global del host. Esta limpieza elimina únicamente los seis namespaces de la práctica; ejecútala cuando hayas terminado los ejercicios.

```bash
NS_LEFT=0
for ns in clienteSede clienteSucA clienteSucB R1 R2 R3; do
  if sudo ip netns list | awk '{print $1}' | grep -Fxq "$ns"; then
    if [ "$(sudo ip netns exec "$ns" cat /sys/class/net/lo/ifalias 2>/dev/null)" = networking-lab-owned ]; then
      PIDS=$(sudo ip netns pids "$ns" 2>/dev/null || true)
      if [ -n "$PIDS" ]; then echo "Se conserva $ns: quedan procesos activos ($PIDS)."; NS_LEFT=1
      else sudo ip netns del "$ns" 2>/dev/null || true
      fi
    else echo "Se conserva $ns: no tiene la marca de propiedad Networking Lab."; NS_LEFT=1
    fi
  fi
done
if [ "$NS_LEFT" = 0 ]; then
  for f in /sys/class/net/*/ifalias; do
    [ -r "$f" ] || continue
    [ "$(cat "$f")" = networking-lab-lab-06 ] || continue
    dev=${f%/ifalias}; dev=${dev##*/}
    sudo ip link del "$dev" 2>/dev/null || true
  done
else echo "Se conservan enlaces host; hay namespaces con procesos activos."; fi
```

**Comprobación:** `sudo ip netns list` no debe mostrar ninguno de esos seis nombres. Al repetir la práctica, comienza de nuevo por el Paso 0.

## Profundización: plano de control y plano de datos

La **[RIB](https://www.rfc-editor.org/rfc/rfc8349)** es la base de información de routing que reúne rutas aprendidas y sus atributos; la selección de rutas decide cuáles son preferibles. La **[FIB](https://www.rfc-editor.org/rfc/rfc8349)** es la estructura optimizada que utiliza el plano de datos para reenviar paquetes. En Linux, `ip route` consulta la tabla de routing del kernel; no es una visualización universal de la implementación interna de hardware de un router comercial.

### Reconstrucción de un reenvío

```bash
sudo ip netns exec R1 ip route get 10.0.2.10
sudo ip netns exec R1 ip route show table main
sudo ip netns exec R1 ip neigh show
sudo ip netns exec R1 ip -s link
```

El router aplica *longest prefix match* entre rutas elegibles; después resuelve el siguiente salto y la interfaz de salida. Si el vecino no está en caché, ARP resuelve la MAC del siguiente salto en el enlace Ethernet. El router construye una nueva trama de capa 2, decrementa el TTL IPv4 y reenvía el paquete. Si el TTL llega a cero, descarta y normalmente genera ICMP Time Exceeded, sujeto a políticas y rate limiting.

### Métrica no significa calidad física

La métrica es un criterio administrativo de preferencia dentro de la selección de rutas; no mide automáticamente latencia, ancho de banda, pérdida ni número de saltos. Compara una ruta con métrica menor y RTT mayor frente a otra con métrica superior y RTT menor: Linux puede preferir la primera por su métrica, aunque la segunda parezca más rápida en una medición puntual.

### GRE y underlay

El enlace virtual `192.168.3.0/30` simula el **underlay IP** entre extremos; no representa Internet pública. GRE añade una cabecera GRE y una cabecera IP exterior alrededor del paquete interior. El TTL exterior y el interior son campos distintos; observa ambos con capturas en el extremo del túnel y en la interfaz subyacente. La MTU efectiva disminuye por el overhead y debe probarse en ambos sentidos.

### Fallo local frente a fallo remoto

Registra el tiempo, paquetes perdidos y ruta seleccionada cuando bajas una interfaz local. Repite con un fallo remoto que no provoque pérdida de portadora (por ejemplo, descartar tráfico en el extremo remoto dentro del laboratorio). Una ruta estática con siguiente salto todavía alcanzable a nivel de enlace no desaparece necesariamente ante un fallo remoto; no la describas como convergencia automática.


## Preguntas de reflexión

1.  ¿Qué mecanismo hace que R1 envíe `10.0.2.10` por el enlace directo y no por R2?
2.  ¿Qué sucedería si se borra la ruta de métrica 100 y después cae el enlace directo?
3.  ¿Qué diferencia hay entre un fallo local (cae mi interfaz) y uno remoto (cae un enlace más allá del vecino)?
4.  ¿Qué limitaciones tiene el enrutamiento estático cuando la red crece a decenas de sucursales?
5.  ¿En qué escenario empresarial usarías un túnel GRE, y qué le falta para ser seguro?
6.  ¿Qué otro mecanismo podría resolver la conectividad entre sedes sin configurar rutas a mano?

## Conclusiones técnicas

En este laboratorio hemos:

1.  Implementado una topología con tres routers interconectados.
2.  Configurado **rutas estáticas** para interconectar las oficinas.
3.  Analizado la **tabla de enrutamiento** y el proceso de selección.
4.  Agregado **enlaces redundantes** con rutas de respaldo (útiles ante fallos locales, no un mecanismo de convergencia).
5.  Configurado un **túnel GRE** para conectar redes no contiguas (encapsula, pero no cifra).

El enrutamiento es el corazón de la comunicación entre redes. Las rutas estáticas son simples pero no escalan ni reaccionan a fallos remotos. Los protocolos dinámicos como OSPF funcionan de otro modo: los routers establecen adyacencias, intercambian el estado de sus enlaces, construyen una base de datos de topología común y calculan los caminos más cortos ([SPF](https://www.rfc-editor.org/rfc/rfc2328)), reconvergiendo cuando algo cambia. Se implementa de forma real en el Laboratorio 15. Los túneles GRE permiten extender redes a través de infraestructuras IP.

## Preparación para el siguiente laboratorio

En el **Laboratorio 07** exploraremos **protocolos y servicios de red** como DHCP, DNS, NAT y firewalls.

---

**¡Laboratorio 06 completado!** Has implementado enrutamiento entre redes. Continúa con el **Laboratorio 07**.
