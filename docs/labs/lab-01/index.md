<p class="tema-num">LABORATORIO 01</p>

# Fundamentos de Redes y Encapsulación

## Contexto empresarial

La empresa **Networking SecOps** acaba de abrir una nueva oficina. Cuenta con dos empleados que necesitan compartir archivos y acceder a Internet. No hay infraestructura de red aún. Se te ha encargado **diseñar la red local** que permita la comunicación entre los equipos y preparar el acceso a la web. Además, debes **demostrar cómo viajan los datos** entre dos equipos y cómo se encapsulan en cada capa.

!!! note "Alcance de este laboratorio"
    En esta primera demostración el equipo intermedio (el namespace `router`) aloja un **bridge Linux** y su función efectiva es la **conmutación Ethernet (capa 2)**. El **enrutamiento entre subredes** todavía no se demuestra; llegará en los laboratorios 02 y 06.

## Problema inicial

-   Dos PCs (Cliente1 y Cliente2) deben comunicarse entre sí.
-   Ambas necesitarán salir a Internet a través de un router (esa salida se prepara en el laboratorio 02).
-   No se dispone de equipos físicos, pero se puede utilizar **Linux** con herramientas de virtualización de red (namespaces, veth, etc.) para simular la topología.

## Objetivos del laboratorio

1.  Comprender el concepto de red y sus componentes.
2.  Implementar una red local sencilla usando **namespaces de red** en Linux.
3.  Asignar direcciones IP y comprobar conectividad.
4.  Observar el proceso de **encapsulación** mediante captura de paquetes con `tcpdump`.
5.  Analizar el flujo de datos desde la generación hasta la transmisión.

## Herramientas necesarias

-   Linux (Debian/Ubuntu recomendado) con privilegios de superusuario.
-   Comandos: `ip`, `ping`, `tcpdump`, `nslookup`, `curl`.
-   Editor de texto para scripts (opcional).

## Topología

```mermaid
graph TB
    C1[Cliente 1 10.0.1.2/24]
    C2[Cliente 2 10.0.1.3/24]
    R["Equipo «router»: bridge br0 (capa 2) 10.0.1.1/24"]
    Internet((Internet: aún sin conectar))
    C1 --- R
    C2 --- R
    R -. "lab 02" .- Internet
```

**Direccionamiento:**

| Dispositivo | Interfaz | Dirección IP       |
|-------------|----------|--------------------|
| Cliente 1   | veth0    | 10.0.1.2/24        |
| Cliente 2   | veth0    | 10.0.1.3/24        |
| Router (bridge) | br0  | 10.0.1.1/24        |
| (Internet)  | —        | No se configura en este laboratorio |

El namespace `router` es un equipo lógico que aloja el bridge `br0`. La dirección `10.0.1.1` pertenece a la interfaz IP del propio bridge: sirve para que el equipo sea alcanzable y para preparar su papel de *gateway* en el laboratorio 02. **No interviene** en la comunicación entre Cliente 1 y Cliente 2.

## Construcción de la red

Usaremos **namespaces de red** para aislar cada dispositivo en un entorno virtual dentro de la misma máquina Linux. Esto nos permite simular una red sin necesidad de hardware extra.

### Paso 1: Verificar el entorno

Asegúrate de tener permisos de root:

```bash
sudo -i
```

### Paso 2: Crear los namespaces

Creamos un namespace para cada dispositivo:

```bash
ip netns add cliente1
ip netns add cliente2
ip netns add router
```

Verificamos que se hayan creado:

```bash
ip netns list
```

**Ejemplo de salida** (representativo; el orden puede variar y, según la versión de `iproute2`, cada nombre puede llevar un sufijo `(id: N)`):

```
router
cliente1
cliente2
```

### Paso 3: Crear los pares de interfaces virtuales (veth)

Necesitamos conectar cada cliente al router. Para ello, creamos dos pares veth:

```bash
# Par para Cliente 1
ip link add veth-c1 type veth peer name veth-r1

# Par para Cliente 2
ip link add veth-c2 type veth peer name veth-r2
```

### Paso 4: Asignar cada extremo a su namespace

```bash
# Cliente 1
ip link set veth-c1 netns cliente1

# Cliente 2
ip link set veth-c2 netns cliente2

# Router (extremos r1 y r2)
ip link set veth-r1 netns router
ip link set veth-r2 netns router
```

### Paso 5: Configurar direcciones IP y activar interfaces

**Cliente 1:**

```bash
ip netns exec cliente1 ip addr add 10.0.1.2/24 dev veth-c1
ip netns exec cliente1 ip link set veth-c1 up
ip netns exec cliente1 ip link set lo up
```

**Cliente 2:**

```bash
ip netns exec cliente2 ip addr add 10.0.1.3/24 dev veth-c2
ip netns exec cliente2 ip link set veth-c2 up
ip netns exec cliente2 ip link set lo up
```

**Router – Usaremos un bridge para conectar ambos clientes:**

```bash
# En el namespace router
ip netns exec router ip link add br0 type bridge
ip netns exec router ip link set veth-r1 master br0
ip netns exec router ip link set veth-r2 master br0
ip netns exec router ip addr add 10.0.1.1/24 dev br0
ip netns exec router ip link set br0 up
ip netns exec router ip link set veth-r1 up
ip netns exec router ip link set veth-r2 up
```

### Paso 6: Configurar la salida a Internet (opcional)

El router todavía **no dispone de una interfaz WAN funcional**: para que los clientes accedan a Internet hará falta una interfaz externa, una ruta por defecto, reenvío IP y NAT. Todo ello se construye en el laboratorio 02. Por ahora nos centramos en la comunicación local.

### Paso 7: Verificar conectividad entre clientes

Desde Cliente 1, hacemos ping a Cliente 2:

```bash
ip netns exec cliente1 ping -c 4 10.0.1.3
```

**Resultado esperado:** 4 respuestas exitosas.

Desde Cliente 2 a Cliente 1:

```bash
ip netns exec cliente2 ping -c 4 10.0.1.2
```

**Resultado esperado:** 4 respuestas exitosas.

### Paso 8: Verificar conectividad con el router

Desde Cliente 1 al router:

```bash
ip netns exec cliente1 ping -c 4 10.0.1.1
```

**Resultado esperado:** 4 respuestas exitosas.

## Observación de la encapsulación

Vamos a capturar el tráfico en el bridge del equipo intermedio para ver cómo viaja un paquete ICMP (ping) desde Cliente 1 a Cliente 2.

### Paso 9: Iniciar captura en el router

Abrimos otra terminal (o usamos `tmux`) y ejecutamos:

```bash
ip netns exec router tcpdump -i br0 -n -v icmp
```

### Paso 10: Enviar un ping desde Cliente 1

En la terminal original:

```bash
ip netns exec cliente1 ping -c 1 10.0.1.3
```

### Paso 11: Analizar la captura

Ejemplo de salida (representativo; los identificadores, las horas y las MAC variarán):

```
tcpdump: listening on br0, link-type EN10MB (Ethernet), capture size 262144 bytes
14:23:45.678901 IP (tos 0x0, ttl 64, id 12345, offset 0, flags [DF], proto ICMP (1), length 84)
    10.0.1.2 > 10.0.1.3: ICMP echo request, id 1, seq 1, length 64
14:23:45.678987 IP (tos 0x0, ttl 64, id 54321, offset 0, flags [none], proto ICMP (1), length 84)
    10.0.1.3 > 10.0.1.2: ICMP echo reply, id 1, seq 1, length 64
```

**Interpretación:**

-   Se ve la trama Ethernet (link-type EN10MB) que contiene el paquete IP.
-   El paquete IP tiene origen 10.0.1.2 y destino 10.0.1.3.
-   El protocolo es ICMP (1).
-   Los datos ICMP (echo request/reply) están encapsulados dentro del paquete IP, que a su vez va dentro de la trama Ethernet.

Podemos ver más detalles si usamos `-e` para mostrar la cabecera Ethernet:

```bash
ip netns exec router tcpdump -i br0 -n -e icmp
```

Aparecerán direcciones MAC de origen y destino, lo que confirma la encapsulación en la capa de enlace. Observa que la MAC de destino de cada trama es la de **Cliente 2** (y la de Cliente 1 en la respuesta), no la del bridge.

## Análisis del flujo de datos

1.  **Cliente 1 genera el mensaje:** La aplicación `ping` crea un mensaje ICMP Echo Request.
2.  **Capa de transporte:** ICMP no usa puertos, pero se considera parte de la capa de red en el modelo TCP/IP. A efectos prácticos, el mensaje se entrega a la capa IP.
3.  **Capa de red (IP):** Se añade el encabezado IP con origen 10.0.1.2 y destino 10.0.1.3.
4.  **Resolución ARP:** como 10.0.1.3 pertenece a la misma subred que el origen, Cliente 1 no necesita gateway: envía una solicitud ARP por *broadcast* preguntando «¿quién tiene 10.0.1.3?». Cliente 2 responde con su MAC. (Esos mensajes ARP no aparecen en la captura anterior porque el filtro es `icmp`; puedes verlos con `tcpdump -i br0 -n -e arp`.)
5.  **Capa de enlace:** Se añade la cabecera Ethernet con MAC origen (de `veth-c1`) y MAC destino (la de `veth-c2`, obtenida por ARP).
6.  **El bridge conmuta la trama.** No desencapsula el paquete IP ni consulta tablas de rutas. Aprende la MAC de origen de cada trama que recibe y la asocia al puerto de entrada; para decidir la salida busca la MAC de destino en su tabla. Si la conoce, reenvía la trama **sin modificarla** solo por ese puerto (`veth-r2`); si no la conoce, la inunda por todos los puertos excepto el de entrada. Puedes ver la tabla con `ip netns exec router bridge fdb show br br0`.
7.  **Cliente 2 recibe la trama**, la desencapsula y entrega el mensaje ICMP a la aplicación, que genera la respuesta y repite el proceso inverso.

!!! info "Bridge frente a router"
    Un **bridge** aprende direcciones MAC y reenvía **tramas Ethernet** dentro de una misma red. Un **router** consulta información de capa 3 y reenvía **paquetes IP** entre redes distintas, reescribiendo la cabecera Ethernet en cada salto. Cuando los dos clientes están en la misma subred, la comunicación es de capa 2 y el router no participa.

## Conclusiones técnicas

-   Hemos implementado una red funcional utilizando **namespaces de red**, que simulan dispositivos independientes.
-   Hemos verificado la conectividad capa a capa (IP y Ethernet).
-   Mediante `tcpdump` hemos observado la **encapsulación** en tiempo real:
    -   Datos → ICMP (mensaje) → IP (paquete) → Ethernet (trama).
-   El equipo lógico denominado `router` contiene un **bridge** que realiza la **conmutación de capa 2** entre los dos clientes. **No se ha demostrado todavía enrutamiento entre subredes**.
-   Este laboratorio sienta las bases para los siguientes, donde agregaremos más dispositivos, VLANs, enrutamiento y servicios.

## Errores comunes y soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| `ping: connect: Network is unreachable` | No se ha asignado IP o la interfaz está down. | Verificar `ip addr show` y `ip link set ... up`. |
| `tcpdump: no suitable device found` | El dispositivo no existe o no se ha activado. | Asegurar que el bridge esté up. |
| No se ven paquetes en tcpdump | La captura está en interfaz incorrecta. | Capturar en `br0` o en `any`. |
| Los clientes no pueden hacer ping al router | El router no tiene la IP en la interfaz correcta. | Verificar que `br0` tenga la IP y esté up. |

## Preparación para el siguiente laboratorio

Hemos dejado la red con los dos clientes y el equipo `router` (con bridge). Este equipo **aún no tiene salida a Internet**. En el **Laboratorio 02** le añadiremos una interfaz externa, una ruta por defecto y NAT para que los clientes puedan salir a la web.

---

**¡Laboratorio 01 completado!** Has construido tu primera red virtual y has observado cómo se encapsulan y conmutan los datos. Continúa con el **Laboratorio 02**.
