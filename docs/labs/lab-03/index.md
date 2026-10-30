<p class="tema-num">LABORATORIO 03</p>

# Componentes de Red y Conmutación

## Contexto empresarial

La empresa **Networking SecOps** ha crecido. Ahora hay **4 empleados** en la oficina, cada uno con su propio equipo. La red actual (Cliente 1 y Cliente 2 conectados directamente al router) ya no es suficiente. Se necesita una **infraestructura más organizada** que permita conectar múltiples dispositivos de forma escalable y eficiente.

El equipo de TI ha decidido implementar un **switch** para centralizar las conexiones de los clientes, y así: 

-   Reducir el tráfico innecesario en el router.
-   Permitir la comunicación directa entre clientes sin pasar por el router.
-   Facilitar la expansión futura (más clientes, VLANs, etc.).

Además, se debe **documentar el funcionamiento del switch**: cómo aprende direcciones MAC, cómo reenvía tramas y cómo segmenta el tráfico.

## Problema inicial

-   La red actual tiene solo 2 clientes conectados directamente al router vía bridge.
-   Se necesita conectar **4 clientes** (Cliente 1, 2, 3 y 4).
-   El router debe mantener su función de enrutamiento y NAT hacia Internet.
-   Se debe implementar un **switch** (bridge en Linux) que interconecte a todos los clientes.

## Objetivos del laboratorio

1.  Comprender la función de los **dispositivos finales** (hosts) y **dispositivos intermedios** (switch, router).
2.  Implementar un **switch** en Linux usando un bridge.
3.  Conectar **4 clientes** al switch y verificar su comunicación.
4.  Observar el **aprendizaje de direcciones MAC** en el switch.
5.  Analizar el **flujo de datos** en una red conmutada.
6.  Comprender el concepto de **MTU** y su impacto en la transmisión.

## Herramientas necesarias

-   Linux con privilegios de superusuario.
-   Comandos: `ip`, `ping`, `tcpdump`, `bridge`, `ethtool`.
-   Conocimientos básicos de direccionamiento MAC e IP.

## Topología

```mermaid
graph TB
    C1[Cliente 1 10.0.1.2/24]
    C2[Cliente 2 10.0.1.3/24]
    C3[Cliente 3 10.0.1.4/24]
    C4[Cliente 4 10.0.1.5/24]
    SW["Switch (namespace switch): bridge br0, capa 2"]
    R["Router (namespace router): veth-rs 10.0.1.1/24, capa 3"]
    ISP[Proveedor Internet]
    C1 --- SW
    C2 --- SW
    C3 --- SW
    C4 --- SW
    SW -- "enlace virtual veth-sr / veth-rs" --- R
    R --- ISP
```

El **switch** (namespace `switch`) y el **router** (namespace `router`) son ahora dos equipos lógicos distintos. El bridge `br0` pertenece solo al switch; la dirección IP `10.0.1.1` pertenece a la interfaz `veth-rs` del router, que está conectada al bridge mediante un enlace virtual. Así se separa la función de capa 2 (conmutar tramas) de la de capa 3 (*gateway* hacia otras redes).

**Direccionamiento:**

| Dispositivo | Interfaz | Dirección IP       |
|-------------|----------|--------------------|
| Cliente 1   | veth0    | 10.0.1.2/24        |
| Cliente 2   | veth0    | 10.0.1.3/24        |
| Cliente 3   | veth0    | 10.0.1.4/24        |
| Cliente 4   | veth0    | 10.0.1.5/24        |
| Switch      | br0 (puertos `veth-s1`…`veth-s4` y `veth-sr`) | - (capa 2, sin IP) |
| Router (LAN)| veth-rs  | 10.0.1.1/24        |
| Router (WAN)| veth-wan | 192.168.1.2/24    |

## Construcción de la red

### Paso 1: Verificar el estado actual

Asegurémonos de que el laboratorio 02 está funcionando:

```bash
# Verificar namespaces
ip netns list

# Verificar conectividad a Internet
ip netns exec cliente1 ping -c 2 8.8.8.8
```

Si no existen los namespaces, ejecuta los comandos de los laboratorios 01 y 02 para crearlos.

### Paso 2: Eliminar la configuración anterior (bridge del router)

En el laboratorio 01, creamos un bridge `br0` dentro del router para conectar los clientes. Ahora el bridge pasará a un **namespace propio para el switch**, de modo que el router quede solo con funciones de capa 3. Eliminamos el bridge y los cables virtuales anteriores (al borrar un extremo de un par veth desaparece también el otro; los clientes perderán su IP y su ruta, que se reconfiguran en el Paso 7):

```bash
ip netns exec router ip link delete br0
ip netns exec router ip link delete veth-r1
ip netns exec router ip link delete veth-r2
```

!!! warning "Las reglas del laboratorio 02 mencionaban `br0`"
    Las reglas de `FORWARD` del router creadas en el laboratorio 02 usan `-i br0`. Al borrar el bridge del router esas reglas dejan de aplicarse. Con la política por defecto (`ACCEPT`) la salida a Internet seguirá funcionando, pero conviene mantener la coherencia: tras el Paso 9 sustituye `br0` por `veth-rs` en ellas (`iptables -D FORWARD -i br0 …` y `iptables -A FORWARD -i veth-rs …`, ejecutadas con `ip netns exec router`). La regla de `MASQUERADE` usa `-o veth-wan` y no se ve afectada.

### Paso 3: Crear el namespace del switch

```bash
ip netns add switch
```

### Paso 4: Crear el bridge en el switch

```bash
# Crear bridge en el namespace switch
ip netns exec switch ip link add br0 type bridge
ip netns exec switch ip link set br0 up
```

### Paso 5: Crear el namespace del Cliente 3 y Cliente 4

```bash
ip netns add cliente3
ip netns add cliente4
```

### Paso 6: Crear interfaces para los 4 clientes

```bash
# Cliente 1
ip link add veth-c1 type veth peer name veth-s1
ip link set veth-c1 netns cliente1
ip link set veth-s1 netns switch

# Cliente 2
ip link add veth-c2 type veth peer name veth-s2
ip link set veth-c2 netns cliente2
ip link set veth-s2 netns switch

# Cliente 3
ip link add veth-c3 type veth peer name veth-s3
ip link set veth-c3 netns cliente3
ip link set veth-s3 netns switch

# Cliente 4
ip link add veth-c4 type veth peer name veth-s4
ip link set veth-c4 netns cliente4
ip link set veth-s4 netns switch
```

### Paso 7: Configurar los clientes

```bash
# Cliente 1
ip netns exec cliente1 ip addr add 10.0.1.2/24 dev veth-c1
ip netns exec cliente1 ip link set veth-c1 up
ip netns exec cliente1 ip link set lo up
ip netns exec cliente1 ip route add default via 10.0.1.1

# Cliente 2
ip netns exec cliente2 ip addr add 10.0.1.3/24 dev veth-c2
ip netns exec cliente2 ip link set veth-c2 up
ip netns exec cliente2 ip link set lo up
ip netns exec cliente2 ip route add default via 10.0.1.1

# Cliente 3
ip netns exec cliente3 ip addr add 10.0.1.4/24 dev veth-c3
ip netns exec cliente3 ip link set veth-c3 up
ip netns exec cliente3 ip link set lo up
ip netns exec cliente3 ip route add default via 10.0.1.1

# Cliente 4
ip netns exec cliente4 ip addr add 10.0.1.5/24 dev veth-c4
ip netns exec cliente4 ip link set veth-c4 up
ip netns exec cliente4 ip link set lo up
ip netns exec cliente4 ip route add default via 10.0.1.1
```

### Paso 8: Conectar las interfaces del switch al bridge

```bash
# En el namespace switch
ip netns exec switch ip link set veth-s1 master br0
ip netns exec switch ip link set veth-s2 master br0
ip netns exec switch ip link set veth-s3 master br0
ip netns exec switch ip link set veth-s4 master br0
ip netns exec switch ip link set veth-s1 up
ip netns exec switch ip link set veth-s2 up
ip netns exec switch ip link set veth-s3 up
ip netns exec switch ip link set veth-s4 up
```

### Paso 9: Conectar el switch al router

Necesitamos un enlace entre el switch y el router:

```bash
# Crear par veth switch-router
ip link add veth-sr type veth peer name veth-rs
ip link set veth-sr netns switch
ip link set veth-rs netns router

# Conectar al bridge del switch
ip netns exec switch ip link set veth-sr master br0
ip netns exec switch ip link set veth-sr up

# Configurar IP en el router (interfaz hacia el switch)
ip netns exec router ip addr add 10.0.1.1/24 dev veth-rs
ip netns exec router ip link set veth-rs up
```

### Paso 10: Verificar conectividad entre clientes

```bash
# Cliente 1 a Cliente 3
ip netns exec cliente1 ping -c 4 10.0.1.4

# Cliente 2 a Cliente 4
ip netns exec cliente2 ping -c 4 10.0.1.5

# Cliente 3 al router
ip netns exec cliente3 ping -c 4 10.0.1.1
```

**Resultado esperado:** Todas las pruebas con 0% de pérdida.

### Paso 11: Verificar conectividad a Internet

```bash
ip netns exec cliente3 ping -c 4 8.8.8.8
ip netns exec cliente4 curl -I http://google.com
```

## Observación del funcionamiento del switch

### Paso 12: Ver la tabla de direcciones MAC del switch

El switch aprende las direcciones MAC de los dispositivos conectados:

```bash
# Ver tabla MAC del bridge
ip netns exec switch bridge fdb show br br0
```

**Ejemplo de salida** (representativo; las direcciones MAC serán distintas en tu equipo, pues Linux las genera al azar; para poder seguirlas, anótalas con `ip netns exec cliente1 ip link show veth-c1`):

```
5e:1c:9a:03:77:b1 dev veth-s1 master br0
c2:4d:08:6f:12:e4 dev veth-s2 master br0
...
```

**Qué significa cada entrada:** `5e:1c:9a:03:77:b1 dev veth-s1 master br0` quiere decir «la MAC `5e:1c:…` se ha visto como **origen** de una trama recibida por el puerto `veth-s1`; por tanto, las tramas cuyo destino sea esa MAC deben salir por `veth-s1`». El switch **aprende** leyendo la MAC de origen de cada trama entrante y **consulta** la tabla usando la MAC de destino. Solo aparecen las MAC de los equipos que ya han enviado tráfico: si la tabla está vacía, ejecuta antes los pings del Paso 10. Si la MAC de destino no está en la tabla (o es *broadcast*), el switch inunda la trama por todos los puertos excepto el de entrada. Las entradas caducan tras un tiempo de envejecimiento (por defecto, 300 s en Linux).

También verás entradas con `permanent` o `self`: corresponden a las MAC de las propias interfaces del bridge y no a equipos aprendidos.

### Paso 13: Capturar tráfico en el switch

Para observar cómo el switch reenvía tramas, capturamos en el bridge. Ten en cuenta que `br0` ve el tráfico que **entra o sale por el propio bridge**, no distingue por sí solo por qué puerto físico salió cada trama; para comprobar que el reenvío es selectivo, captura además en un puerto concreto (por ejemplo `-i veth-s4`, que **no** debería ver el ping entre Cliente 1 y Cliente 3 una vez aprendidas las MAC):

```bash
# Capturar en el switch (interfaz br0)
ip netns exec switch tcpdump -i br0 -n -e icmp
```

En otra terminal, enviamos un ping de Cliente 1 a Cliente 3:

```bash
ip netns exec cliente1 ping -c 1 10.0.1.4
```

**Interpretación de la captura:**

1.  Cliente 1 envía una trama con **MAC origen = la de `veth-c1`** y **MAC destino = la de `veth-c3`**.
2.  El switch recibe la trama por `veth-s1`.
3.  El switch consulta su tabla MAC y encuentra que la MAC destino está en `veth-s3`.
4.  El switch reenvía la trama **solo por `veth-s3`** (no por los demás puertos).
5.  Cliente 3 recibe la trama y responde.

**Esto demuestra la conmutación en capa 2:** el switch aprende y reenvía solo al puerto correcto, reduciendo el tráfico innecesario. (La primera trama de la conversación puede inundarse si la MAC de destino aún no se conoce, y ARP se envía por *broadcast*.)

!!! info "Bridge Linux frente a switch físico"
    La equivalencia funcional es una herramienta didáctica. Un bridge Linux no reproduce necesariamente funciones propias de un switch empresarial: STP configurado y gestionado por defecto, administración avanzada (SNMP, CLI de proveedor), QoS por hardware, PoE, apilado o rendimiento por ASIC.

## Análisis de MTU

Conviene distinguir cinco magnitudes que suelen confundirse:

| Concepto | Qué es |
|----------|--------|
| **MTU de una interfaz** | Tamaño máximo del **paquete IP** (cabecera IP + datos) que la interfaz puede transmitir. Con 1500, un paquete IP de hasta 1500 bytes. |
| **Carga útil (payload)** | Los datos que van dentro del paquete (en IPv4 sin opciones, 1500 − 20 de cabecera IP = 1480 para TCP/UDP/ICMP). |
| **Tamaño total de la trama Ethernet** | Paquete IP **más** la cabecera Ethernet (14 bytes) y el FCS (4): hasta 1518 bytes con MTU 1500 (1522 con etiqueta 802.1Q). La cabecera Ethernet se añade *fuera* del MTU. |
| **Fragmentación IPv4** | División de un paquete mayor que la MTU en fragmentos, si el bit DF no lo prohíbe. |
| **Path MTU Discovery (PMTUD)** | Mecanismo con el que el origen descubre la MTU más pequeña del camino, enviando paquetes con DF y atendiendo los mensajes ICMP «fragmentation needed». |

### Paso 14: Verificar la MTU actual

```bash
# Ver MTU de las interfaces
ip netns exec cliente1 ip link show veth-c1
```

**Resultado esperado:** `mtu 1500`

### Paso 15: Probar MTU con ping

Enviamos un ping con una carga mayor que la MTU. **Recuerda:** la opción `-s` de `ping` indica el tamaño de los **datos ICMP**; el paquete IP resultante mide `-s` + 8 (cabecera ICMP) + 20 (cabecera IP). Con `-s 2000` el paquete IP mide 2028 bytes:

```bash
# Ping con 2000 bytes de datos (paquete IP de 2028 bytes: se fragmentará)
ip netns exec cliente1 ping -c 2 -M do -s 2000 10.0.1.4
```

**Resultado esperado:** con `-M do` (prohibir fragmentación) y MTU 1500, el propio `ping` rechaza el envío antes de transmitirlo:

```
ping: local error: message too long, mtu=1500
```

Si en cambio permites la fragmentación (`-M dont`, el valor por defecto en Linux), el paquete se divide en fragmentos de hasta 1500 bytes, el destino los reensambla y el ping responde con normalidad:

```bash
ip netns exec cliente1 ping -c 2 -M dont -s 2000 10.0.1.4
```

Esto demuestra la importancia de la MTU: los paquetes que exceden el tamaño máximo deben fragmentarse o, si está prohibido, no pueden enviarse. En el tamaño máximo sin fragmentar, `-s 1472` (1472 + 8 + 20 = 1500) funciona con `-M do` y `-s 1473` no.

Este experimento es **local**: el error lo genera el propio origen. En un camino real con varios saltos, PMTUD depende de que los routers intermedios devuelvan ICMP «fragmentation needed» y de que ningún filtro lo bloquee.

### Paso 16: Cambiar MTU (opcional)

Podemos cambiar la MTU para soportar jumboframes entre Cliente 1 y Cliente 3. La MTU debe subirse en **todos los extremos del camino**: ambos clientes y los puertos del switch por los que pasa la trama (y el bridge, que adopta la menor MTU de sus puertos):

```bash
ip netns exec cliente1 ip link set veth-c1 mtu 9000
ip netns exec cliente3 ip link set veth-c3 mtu 9000
ip netns exec switch ip link set veth-s1 mtu 9000
ip netns exec switch ip link set veth-s3 mtu 9000
ip netns exec switch ip link set br0 mtu 9000
```

Ahora un ping con `-s 8972` (8972 + 8 + 20 = 9000) y `-M do` entre Cliente 1 y Cliente 3 debería funcionar. Un ping con `-s 9000` no cabría: sumaría 28 bytes de cabeceras. Los otros puertos del bridge (`veth-s2`, `veth-s4`, `veth-sr`) conservan 1500, de modo que el tráfico hacia ellos sigue limitado por esa MTU.

## Ejercicios prácticos

### Ejercicio 1: Observar el aprendizaje de MAC

1.  Limpiar la tabla MAC del switch:

    ```bash
    ip netns exec switch bridge fdb flush dev br0
    ```

2.  Enviar un ping de Cliente 1 a Cliente 2.
3.  Ver la tabla MAC nuevamente.
4.  **Pregunta:** ¿Cuánto tiempo tarda el switch en aprender la MAC de Cliente 2?

### Ejercicio 2: Broadcast en la red

1.  Enviar un ping de Cliente 1 a la dirección de broadcast `10.0.1.255`:

    ```bash
    ip netns exec cliente1 ping -c 1 -b 10.0.1.255
    ```

    Linux ignora por defecto los ping a broadcast (`net.ipv4.icmp_echo_ignore_broadcasts=1`), así que no verás respuestas. Para que los demás clientes contesten, ejecuta antes en cada uno: `ip netns exec clienteN sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0`.
2.  Capturar en el switch para ver cómo se reenvía la trama de broadcast.
3.  **Pregunta:** ¿Por qué el switch envía el broadcast a todos los puertos?

### Ejercicio 3: Impacto de la MTU en el rendimiento

1.  Medir el throughput con MTU 1500:

    ```bash
    ip netns exec router iperf3 -s &
    ip netns exec cliente1 iperf3 -c 10.0.1.1
    ```

2.  Cambiar la MTU a 9000 en todos los enlaces del camino (`veth-c1`, `veth-s1`, `br0`, `veth-sr`, `veth-rs`) y repetir la medición.
3.  **Pregunta:** ¿Mejora el throughput con jumboframes? ¿Por qué?

## Errores comunes y soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| Los clientes no pueden hacer ping entre sí | El switch no tiene los puertos en el bridge. | Verificar `bridge link show`. |
| `ping: local error: message too long` | El paquete excede la MTU y se pidió no fragmentar (`-M do`). | Reducir `-s`, aumentar la MTU en todos los enlaces o usar `-M dont`. |
| El switch no aprende MAC | La interfaz está down. | Verificar `ip link set ... up`. |
| No sale a Internet | El router no tiene ruta al switch. | Verificar IP en `veth-rs` y que el switch esté conectado al router. |

## Conclusiones técnicas

En este laboratorio hemos:

1.  **Implementado una red conmutada** usando un bridge en Linux como switch.
2.  **Conectado 4 clientes** al switch y verificado su comunicación.
3.  **Observado el aprendizaje de direcciones MAC** en el switch.
4.  **Analizado el reenvío de tramas** en capa 2 (unicast, broadcast).
5.  **Comprendido el concepto de MTU** y su impacto en la transmisión.
6.  **Demostrado la escalabilidad** de una red conmutada.

El switch es un componente fundamental en las redes modernas. Su capacidad para aprender direcciones MAC y reenviar tráfico solo por el puerto correcto permite:

-   Mayor eficiencia en el uso del ancho de banda.
-   Dominios de colisión separados por puerto (en redes conmutadas dúplex, las colisiones prácticamente desaparecen).
-   Escalabilidad para conectar cientos o miles de dispositivos.
-   Base para implementar VLANs y otras tecnologías de segmentación.

La MTU, por su parte, es un parámetro crítico que debe ser configurado correctamente para evitar fragmentación y pérdida de rendimiento.

## Preparación para el siguiente laboratorio

Hemos dejado la red con 4 clientes conectados a un switch, y el switch conectado al router con salida a Internet. En el **Laboratorio 04** comenzaremos a trabajar con **direccionamiento IP y subredes**, segmentando la red en diferentes subredes y y preparando el enrutamiento entre ellas.

---

**¡Laboratorio 03 completado!** Ahora tenemos una red conmutada escalable y hemos analizado el funcionamiento de los componentes de red. Continúa con el **Laboratorio 04**.
