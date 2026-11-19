---
title: "LABORATORIO 12 · ARQUITECTURAS MODERNAS DE RED"
description: "Laboratorio 12 de NETWORKING Lab — Arquitecturas Modernas de Red."
---

<p class="tema-eyebrow">LABORATORIO 12</p>

# ARQUITECTURAS MODERNAS DE RED

<p class="tema-meta"><span>8 secciones</span><span>3 diagramas</span><span>5 tablas</span></p>

## Contexto empresarial

La empresa **Networking SecOps** ha implementado su arquitectura empresarial tradicional (Laboratorio 11). Ahora necesita modernizar su infraestructura para adaptarse a los nuevos modelos de trabajo híbrido.

!!! warning "Qué es real y qué es simulado"
    - **Real y ejecutable:** conectividad híbrida OnPremise ↔ VPC, acceso remoto con *política por aplicación* en un broker (modelo ZTNA simplificado con `iptables`) y **microsegmentación** entre servidores.
    - **Simulado / conceptual:** el *Identity Provider* (solo se representa como un nodo alcanzable, no autentica a nadie) y **SASE** (SWG, CASB, SD-WAN en un PoP): se explica en el análisis, pero no se construye. Un ZTNA real verifica identidad, dispositivo y contexto en cada conexión; aquí solo se emula la parte de *acceso mínimo por aplicación*.

!!! info "Nube: abstracción didáctica, no la arquitectura real de AWS"
    La VPC se representa como un router Linux y EC2/RDS como *namespaces*. Es una **abstracción válida para enseñar**, pero no reproduce AWS: una **VPC** es una **red virtual definida en la infraestructura del proveedor** (con tablas de rutas, gateways, grupos de seguridad y ACL propios); una **instancia EC2** es un **recurso de cómputo**; **RDS** es un **servicio administrado de bases de datos** (no un host al que se accede por SSH); y la conectividad y la seguridad de AWS usan componentes específicos. **No debe equipararse un *namespace* Linux con una instancia administrada en la nube.**

## Topología

```mermaid
graph TB
    R1[OnPremise Router]
    APP[Servidor App]
    DB[Servidor DB]
    VPC[AWS VPC Router]
    EC2[EC2 Server]
    RDS[RDS Server]
    ZTNA[ZTNA Broker]
    IDP[Identity Provider simulado]
    USER1[Usuario Remoto 1]
    USER2[Usuario Remoto 2]
    USER1 --- ZTNA
    USER2 --- ZTNA
    ZTNA --- IDP
    ZTNA --- R1
    ZTNA --- VPC
    R1 --- APP
    R1 --- DB
    R1 --- VPC
    VPC --- EC2
    VPC --- RDS
```

**Direccionamiento:**

| Dispositivo | Interfaz | Dirección IP | Ubicación |
|-------------|----------|--------------|-----------|
| OnPremise (router) | br-lan | 10.0.0.1/24 | OnPremise |
| Servidor App | - | 10.0.0.10/24 | OnPremise |
| Servidor DB | - | 10.0.0.20/24 | OnPremise |
| OnPremise ↔ VPC | enlace híbrido (un `veth`) | 172.16.255.0/30 (OnPremise .1, VPC .2) | Conexión privada |
| VPC (router) | subred de aplicaciones | 10.100.1.1/24 | AWS (VPC 10.100.0.0/16) |
| EC2 Server | - | 10.100.1.10/24 | AWS |
| VPC (router) | subred de datos | 10.100.2.1/24 | AWS |
| RDS Server | - | 10.100.2.10/24 | AWS |
| ZTNA Broker ↔ OnPremise | conector | 172.16.254.0/30 (OnPremise .1, Broker .2) | Broker |
| ZTNA Broker ↔ VPC | conector | 172.16.253.0/30 (VPC .1, Broker .2) | Broker |
| ZTNA Broker ↔ IDP | - | 192.168.200.0/30 (Broker .1, IDP .2) | Broker |
| ZTNA Broker (usuarios) | br-users | 10.8.0.1/24 | Broker |
| Usuario 1 / Usuario 2 | - | 10.8.0.2/24 y 10.8.0.3/24 | Remoto |

La red `10.8.0.0/24` es una **red virtual de acceso de los usuarios del escenario**. Que exista no prueba que haya un sistema ZTNA real: el control lo ejerce la política del Paso 8.

## Construcción

### Paso 0: Limpiar laboratorios anteriores

Este laboratorio es un **escenario nuevo** (otros equipos y direccionamiento). Elimina **solo los namespaces de los laboratorios anteriores, por nombre**:

```bash
NS_LAB="cliente1 cliente2 cliente3 cliente4 router switch ventas1 ventas2 ventas3 it1 it2 it3 admin1 admin2 R1 R2 R3 clienteSede clienteSucA clienteSucB servidorDNS servidorDHCP clienteDHCP firewall servidorWeb servidorDNS_PUB servidorInterno VPN_GW clienteVPN PE1 PE2 PE3 P1 P2 P3 host1 host2 host3 Core1 Core2 Dist1 Dist2 Access1 Firewall ServidorWeb ServidorDNS ventas it admin OnPremise AppServer DBServer AWS_VPC EC2_Server RDS_Server ZTNA_Broker IDP User1 User2"
EXISTENTES=$(sudo ip netns list | awk '{print $1}' | while read -r ns; do
  for esperado in $NS_LAB; do [ "$ns" = "$esperado" ] && echo "$ns"; done
done)
VETH_HOST=$(sudo ip -o link show veth-host 2>/dev/null | head -1)
VETH_WAN_FW=$(sudo ip -o link show veth-wan-fw 2>/dev/null | head -1)
BR_WAN_OWNED=0
if [ "$(cat /sys/class/net/br-wan/ifalias 2>/dev/null)" = networking-lab ] && sudo ip -4 -o addr show dev br-wan | grep -q '192\.168\.100\.2/24'; then
  BR_WAN_OWNED=1
fi
printf 'Namespaces existentes: %s\nInterfaz veth-host: %s\nInterfaz veth-wan-fw: %s\nBridge br-wan del proyecto: %s\n' "${EXISTENTES:-(ninguno)}" "${VETH_HOST:-(ausente)}" "${VETH_WAN_FW:-(ausente)}" "$BR_WAN_OWNED"
if [ -n "$EXISTENTES$VETH_HOST$VETH_WAN_FW" ] || [ "$BR_WAN_OWNED" = 1 ]; then
  read -r -p "¿Eliminar únicamente los recursos detectados de los laboratorios anteriores? (s/N) " CONFIRMAR
  if [ "$CONFIRMAR" != s ]; then echo "Cancelado"; exit 1; fi
  for ns in $EXISTENTES; do
    sudo ip netns pids "$ns" 2>/dev/null | xargs -r sudo kill
    sudo ip netns del "$ns" 2>/dev/null || true
  done
  [ "$BR_WAN_OWNED" = 1 ] && sudo ip link del br-wan 2>/dev/null || true
fi
```

### Paso 1: Crear namespaces y la función auxiliar

```bash
for ns in OnPremise AppServer DBServer AWS_VPC EC2_Server RDS_Server ZTNA_Broker IDP User1 User2; do
  sudo ip netns add $ns
done
# Los routers deben reenviar paquetes
for r in OnPremise AWS_VPC ZTNA_Broker; do
  sudo ip netns exec $r sysctl -qw net.ipv4.ip_forward=1
done

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
```

### Paso 2: Red OnPremise (un único segmento con App y DB)

La LAN `10.0.0.0/24` es **un solo segmento**: el router la presenta con un bridge y los servidores se conectan a él (no se reutiliza la subred en dos interfaces distintas).

```bash
sudo ip netns exec OnPremise ip link add br-lan type bridge
sudo ip netns exec OnPremise ip addr add 10.0.0.1/24 dev br-lan
sudo ip netns exec OnPremise ip link set br-lan up

for s in "AppServer veth-app veth-op-app 10.0.0.10/24" "DBServer veth-db veth-op-db 10.0.0.20/24"; do
  set -- $s
  sudo ip link add $2 type veth peer name $3
  sudo ip link set $2 netns $1
  sudo ip link set $3 netns OnPremise
  sudo ip netns exec OnPremise ip link set $3 master br-lan
  sudo ip netns exec OnPremise ip link set $3 up
  sudo ip netns exec $1 ip addr add $4 dev $2
  sudo ip netns exec $1 ip link set $2 up
  sudo ip netns exec $1 ip link set lo up
  sudo ip netns exec $1 ip route add default via 10.0.0.1
done
```

### Paso 3: Red en la nube (VPC con dos subredes)

Una VPC `10.100.0.0/16` se organiza en subredes. Cada servidor tiene un *gateway* que **está dentro de su propia subred**.

```bash
enlace AWS_VPC veth-vpc-ec2 10.100.1.1/24 EC2_Server veth-ec2 10.100.1.10/24
enlace AWS_VPC veth-vpc-rds 10.100.2.1/24 RDS_Server veth-rds 10.100.2.10/24
sudo ip netns exec EC2_Server ip route add default via 10.100.1.1
sudo ip netns exec RDS_Server ip route add default via 10.100.2.1
sudo ip netns exec EC2_Server ip link set lo up
sudo ip netns exec RDS_Server ip link set lo up
```

### Paso 4: Conectar OnPremise con la nube (conectividad híbrida)

Un `veth` representa una conexión virtual entre dos extremos, **pero no reproduce por sí mismo una VPN, AWS Direct Connect ni una interconexión privada empresarial**: no hay cifrado, negociación, ni medio contratado con el proveedor. Aquí solo sirve para ilustrar que ambos entornos están enlazados.

```bash
enlace OnPremise veth-op-vpc 172.16.255.1/30 AWS_VPC veth-vpc-op 172.16.255.2/30
sudo ip netns exec OnPremise ip route add 10.100.0.0/16 via 172.16.255.2
sudo ip netns exec AWS_VPC ip route add 10.0.0.0/24 via 172.16.255.1
```

### Paso 5: Broker de acceso (ZTNA) e identidad

El broker es el **único** punto de entrada de los usuarios remotos. Se conecta a OnPremise y a la nube mediante "conectores" y a un proveedor de identidad (simulado).

**IDP y broker no son el mismo componente.** El **proveedor de identidad (IDP)** participa en la **autenticación** y en la emisión o validación de la identidad (y, normalmente, de sus atributos). El **broker** (punto de aplicación de políticas) **aplica o coordina** las políticas de acceso según la arquitectura, consultando lo que el IDP afirma. En el laboratorio el IDP es solo un nodo alcanzable que **no autentica a nadie**.

```bash
enlace ZTNA_Broker veth-bk-op 172.16.254.2/30 OnPremise veth-op-bk 172.16.254.1/30
enlace ZTNA_Broker veth-bk-vpc 172.16.253.2/30 AWS_VPC veth-vpc-bk 172.16.253.1/30
enlace ZTNA_Broker veth-bk-idp 192.168.200.1/30 IDP veth-idp 192.168.200.2/30

# Rutas del broker hacia las aplicaciones y de ellas de vuelta hacia los usuarios
sudo ip netns exec ZTNA_Broker ip route add 10.0.0.0/24 via 172.16.254.1
sudo ip netns exec ZTNA_Broker ip route add 10.100.0.0/16 via 172.16.253.1
sudo ip netns exec OnPremise ip route add 10.8.0.0/24 via 172.16.254.2
sudo ip netns exec AWS_VPC ip route add 10.8.0.0/24 via 172.16.253.2
```

### Paso 6: Usuarios remotos

Los usuarios comparten un único segmento `10.8.0.0/24` mediante un bridge en el broker (una sola IP `10.8.0.1`, no repetida en dos interfaces).

```bash
sudo ip netns exec ZTNA_Broker ip link add br-users type bridge
sudo ip netns exec ZTNA_Broker ip addr add 10.8.0.1/24 dev br-users
sudo ip netns exec ZTNA_Broker ip link set br-users up

for u in "User1 veth-user1 veth-bk-u1 10.8.0.2/24" "User2 veth-user2 veth-bk-u2 10.8.0.3/24"; do
  set -- $u
  sudo ip link add $2 type veth peer name $3
  sudo ip link set $2 netns $1
  sudo ip link set $3 netns ZTNA_Broker
  sudo ip netns exec ZTNA_Broker ip link set $3 master br-users
  sudo ip netns exec ZTNA_Broker ip link set $3 up
  sudo ip netns exec $1 ip addr add $4 dev $2
  sudo ip netns exec $1 ip link set $2 up
  sudo ip netns exec $1 ip link set lo up
  sudo ip netns exec $1 ip route add default via 10.8.0.1
done
```

### Paso 7: Servicios de prueba

Cada aplicación se representa con un servicio TCP sencillo (`nc` en modo escucha):

```bash
sudo ip netns exec AppServer sh -c 'nc -lk -p 8080 >/dev/null 2>&1 </dev/null &'
sudo ip netns exec DBServer  sh -c 'nc -lk -p 3306 >/dev/null 2>&1 </dev/null &'
sudo ip netns exec EC2_Server sh -c 'nc -lk -p 8080 >/dev/null 2>&1 </dev/null &'
sudo ip netns exec RDS_Server sh -c 'nc -lk -p 5432 >/dev/null 2>&1 </dev/null &'
```

### Paso 8: Política Zero Trust en el broker (acceso mínimo por aplicación)

Por defecto **nada** pasa a través del broker. Se abre solo lo necesario para cada usuario: el Usuario 1 accede a la aplicación on-premise y el Usuario 2 a la aplicación en la nube.

!!! warning "Una IP de origen no es una identidad"
    Las reglas identifican al usuario por su dirección (`-s 10.8.0.2`), que es un **sustituto** de la identidad. En un ZTNA real la decisión se basa en la identidad verificada del usuario, el estado del dispositivo y el contexto, **no** en la dirección de red. Lo que sí ilustra bien este paso es el **acceso por recurso y puerto**: el usuario no recibe acceso a la red interna ni a la subred de datos, solo a **una aplicación concreta**.

```bash
sudo ip netns exec ZTNA_Broker iptables -P FORWARD DROP
sudo ip netns exec ZTNA_Broker iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo ip netns exec ZTNA_Broker iptables -A FORWARD -s 10.8.0.2 -d 10.0.0.10 -p tcp --dport 8080 -j ACCEPT
sudo ip netns exec ZTNA_Broker iptables -A FORWARD -s 10.8.0.3 -d 10.100.1.10 -p tcp --dport 8080 -j ACCEPT
```

### Paso 9: Microsegmentación entre servidores

Cada servidor acepta **solo** lo que su función necesita, con política por defecto "denegar":

```bash
# DB (on-premise): solo el servidor App, y solo al puerto 3306
sudo ip netns exec DBServer iptables -P INPUT DROP
sudo ip netns exec DBServer iptables -A INPUT -i lo -j ACCEPT
sudo ip netns exec DBServer iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo ip netns exec DBServer iptables -A INPUT -s 10.0.0.10 -p tcp --dport 3306 -j ACCEPT

# RDS (nube): solo EC2, y solo al puerto 5432
sudo ip netns exec RDS_Server iptables -P INPUT DROP
sudo ip netns exec RDS_Server iptables -A INPUT -i lo -j ACCEPT
sudo ip netns exec RDS_Server iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo ip netns exec RDS_Server iptables -A INPUT -s 10.100.1.10 -p tcp --dport 5432 -j ACCEPT
```

### Paso 10: Verificar

```bash
# Usuario 1: SÍ a la app on-premise, NO a la de la nube
sudo ip netns exec User1 nc -zv -w 2 10.0.0.10 8080
sudo ip netns exec User1 nc -zv -w 2 10.100.1.10 8080

# Usuario 2: SÍ a la app en la nube, NO a la on-premise ni a las bases de datos
sudo ip netns exec User2 nc -zv -w 2 10.100.1.10 8080
sudo ip netns exec User2 nc -zv -w 2 10.0.0.10 8080
sudo ip netns exec User2 nc -zv -w 2 10.0.0.20 3306

# Microsegmentación: App -> DB (SÍ, 3306); App -> DB por otro puerto (NO); EC2 -> RDS (SÍ); on-premise -> RDS (NO)
sudo ip netns exec AppServer nc -zv -w 2 10.0.0.20 3306
sudo ip netns exec AppServer nc -zv -w 2 10.0.0.20 22
sudo ip netns exec EC2_Server nc -zv -w 2 10.100.2.10 5432
sudo ip netns exec AppServer nc -zv -w 2 10.100.2.10 5432
```

**Resultado esperado:** `succeeded` en las conexiones permitidas y expiración del tiempo de espera en las demás. Se verifica con conexiones TCP a puertos concretos (no con `ping`): las políticas son por aplicación y puerto.

## Análisis

**Cloud Networking:** VPC con subredes y conectividad híbrida (aquí, un enlace privado entre OnPremise y la VPC).

**Zero Trust** (NIST SP 800-207) es un **modelo**, no un producto: la presencia de un broker y de una red de usuarios **no constituye por sí misma Zero Trust**. Se define por principios:

-   **Verificación explícita** de la identidad (usuario y, cuando procede, dispositivo y servicio).
-   **Evaluación del contexto** (estado del dispositivo, ubicación, riesgo, hora).
-   **Autorización por recurso**, no por pertenencia a una red.
-   **Acceso de mínimo privilegio**.
-   **Reevaluación continua de la confianza**: el acceso no se concede de una vez para siempre.
-   **Protección de los recursos**, no solo del perímetro.

**En este laboratorio** solo se ilustran el acceso por recurso (Paso 8), el mínimo privilegio y la microsegmentación (Paso 9). **No** hay verificación de identidad, evaluación de contexto ni reevaluación.

**ZTNA:** acceso remoto por aplicación a través de un broker (en el laboratorio, con una política estática; en producción, decidida por el proveedor de identidad y el estado del dispositivo).

**SASE (conceptual):** SD-WAN + SWG + CASB + ZTNA como servicio en la nube. No se construye en este laboratorio.

**Microsegmentación:** políticas granulares App→DB y EC2→RDS.

### Flujo Usuario → IdP → Broker → Aplicación

El **proveedor de identidad (IdP)** responde a «¿quién eres y puedes acceder?»; el **broker** aplica la política: «¿puede *esta* identidad llegar a *esta* aplicación?». En el laboratorio el IdP es solo un nodo alcanzable, pero el flujo real es:

```mermaid
sequenceDiagram
    participant U as Usuario remoto
    participant B as Broker ZTNA
    participant I as IdP (identidad)
    participant A as Aplicación
    U->>B: Solicita acceso a la aplicación
    B->>I: ¿Quién es y cumple las condiciones?
    I-->>B: Identidad verificada (y estado del dispositivo)
    B->>B: Evalúa política: usuario, aplicación, puerto
    B->>A: Abre solo esa conexión
    A-->>U: Respuesta (por el broker)
```

### Matriz de acceso por usuario, aplicación y puerto

Hace visible el **mínimo privilegio**: cada fila es un permiso explícito; todo lo que no aparece está denegado.

| Origen | Destino | Puerto | Permitido |
|--------|---------|--------|-----------|
| Usuario 1 (`10.8.0.2`) | App on-premise (`10.0.0.10`) | TCP 8080 | **Sí** (Paso 8) |
| Usuario 2 (`10.8.0.3`) | EC2 (`10.100.1.10`) | TCP 8080 | **Sí** (Paso 8) |
| Usuario 1 | EC2 (nube) | 8080 | No |
| Usuario 2 | App on-premise | 8080 | No |
| Cualquier usuario | Bases de datos (`10.0.0.20`, `10.100.2.10`) | cualquiera | No |
| App (`10.0.0.10`) | DB (`10.0.0.20`) | TCP 3306 | **Sí** (Paso 9) |
| EC2 (`10.100.1.10`) | RDS (`10.100.2.10`) | TCP 5432 | **Sí** (Paso 9) |
| App | RDS (nube) | 5432 | No |

La política por defecto es **denegar**: lo que no aparece en la tabla no pasa. Mantener una matriz así permite revisar el mínimo privilegio sin leer reglas una por una.

### Conectividad híbrida, VPN y conexión dedicada

| | VPN sitio a sitio sobre Internet | Conexión privada dedicada (tipo *Direct Connect*) | Este laboratorio |
|--|-----------------------------------|------------------------------------------------------|------------------|
| Medio | Internet público | Circuito privado contratado | Un `veth` entre dos *namespaces* |
| Cifrado | Sí (IPsec, WireGuard) | No por defecto (se añade si se requiere) | No |
| Latencia y capacidad | Variables | Predecibles, contratadas | Las del kernel |
| Coste y plazo | Bajo y rápido | Alto y lento | Ninguno |

Una conexión `veth` **no** es una VPN ni una conexión dedicada: solo representa que existe un enlace privado.

### VPC con subred pública y privada

```mermaid
graph TB
    Internet((Internet)) --- IGW[Puerta de enlace a Internet]
    subgraph VPC["VPC 10.100.0.0/16"]
        subgraph Publica["Subred pública"]
            WEB[Servidor expuesto]
        end
        subgraph Privada["Subred privada"]
            DB[(Base de datos)]
        end
    end
    IGW --- WEB
    WEB --- DB
```

Aquí hay dos subredes (`10.100.1.0/24` aplicaciones y `10.100.2.0/24` datos), sin Internet: la diferencia pública/privada la define **qué ruta tiene cada subred** hacia la puerta de enlace.

### Zero Trust, ZTNA y SASE

| Término | Qué es | Nivel |
|---------|--------|-------|
| **Zero Trust** | **Modelo** de seguridad: no se confía por estar «dentro» de la red | Principios (NIST SP 800-207) |
| **ZTNA** | **Tecnología** de acceso remoto por aplicación, bajo Zero Trust | Acceso |
| **SASE** | **Servicio** en la nube que combina red (SD-WAN) y seguridad (SWG, CASB, ZTNA) | Arquitectura de servicio |

No son sinónimos: ZTNA puede ser un componente de SASE, y ambos intentan aplicar Zero Trust.

### Grupos de seguridad y ACL de nube

La microsegmentación del Paso 9 equivale, en un proveedor de nube, a **grupos de seguridad** (reglas con estado, asociadas a recursos: «la base de datos solo acepta el puerto 5432 desde el grupo de la aplicación») y **ACL de subred** (reglas sin estado, a nivel de subred). Es la misma idea que `iptables` entre `App` y `DB`, con otra herramienta.

## Ejercicios

### Ejercicio 1: Agregar usuario remoto

Configura un tercer usuario en el broker (`10.8.0.4`) con acceso solo a la base de datos de la nube por el puerto 5432 y comprueba que los demás usuarios no ganan ese acceso.

### Ejercicio 2: Definir políticas SASE

Redacta (sin implementarlas) las políticas que un SASE aplicaría al tráfico de los usuarios: categorías web permitidas (SWG), aplicaciones SaaS autorizadas (CASB) y condiciones de dispositivo.

## Conceptos clave

| Concepto | Aplicación |
|----------|------------|
| Cloud Networking | VPC con subredes, conectividad híbrida |
| Zero Trust | Denegar por defecto, acceso mínimo |
| ZTNA | Acceso remoto por aplicación (broker) |
| SASE | SD-WAN + SWG + CASB (conceptual) |
| Microsegmentación | Políticas granulares entre servidores |

## Preguntas de reflexión

1.  ¿Qué mecanismo distingue dar acceso a una **aplicación** de dar acceso a toda una **red**?
2.  ¿Qué sucedería si el broker permitiera cualquier puerto hacia la base de datos?
3.  ¿Qué diferencia hay entre lo que el IdP simulado hace aquí y lo que haría uno real?
4.  ¿Qué limitaciones tiene representar una VPC con *namespaces* y routers Linux?
5.  ¿En qué escenario empresarial sustituirías una VPN de acceso remoto por ZTNA?
6.  ¿Qué otros mecanismos aportarían identidad y estado del dispositivo?

## Conclusiones

Las arquitecturas modernas combinan Cloud Networking, Zero Trust, ZTNA, SASE y microsegmentación para adaptarse a entornos híbridos con agilidad y seguridad. En este laboratorio se ha **representado** la conectividad híbrida (con una abstracción de la nube), el acceso mínimo por aplicación y la microsegmentación; la verificación de identidad, la evaluación de contexto y SASE quedan como conceptos explicados, y el escenario **no equivale a una plataforma ZTNA ni a AWS reales**.

---

**¡Laboratorio 12 completado!** Continúa con el **Laboratorio 13**.
