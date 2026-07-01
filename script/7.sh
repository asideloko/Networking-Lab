#!/bin/bash
# create_lab07.sh – Crea el Laboratorio 07 (Protocolos y Servicios de Red)

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml. Asegúrate de ejecutar este script desde la raíz del proyecto."
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-07"
echo "📁 Creando laboratorio 07 en $LAB_DIR"

mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

printf '%s\n' \
"# Laboratorio 07 – Protocolos y Servicios de Red" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ya tiene su infraestructura de red funcionando con enrutamiento entre la sede y las sucursales (Laboratorio 06). Ahora necesita implementar **servicios de red esenciales** para que los usuarios puedan trabajar eficientemente:" \
"" \
"1. **DNS** – Resolución de nombres para acceder a servidores por nombre en lugar de IP." \
"2. **DHCP** – Asignación automática de direcciones IP a los clientes." \
"3. **NAT/PAT** – Permitir que los clientes de la red interna accedan a Internet." \
"4. **TCP/UDP** – Comprender la diferencia entre ambos protocolos." \
"" \
"El equipo de TI ha decidido implementar estos servicios en la sede central y documentar su funcionamiento para futuras expansiones." \
"" \
"## Problema inicial" \
"" \
"- Los clientes tienen direcciones IP configuradas manualmente (administración tediosa)." \
"- No hay un servidor DNS interno que resuelva nombres locales." \
"- Los clientes de la sede y sucursales no pueden acceder a Internet." \
"- Se necesita implementar NAT para salida a Internet." \
"" \
"## Objetivos del laboratorio" \
"" \
"1.  Comprender la diferencia entre **TCP y UDP** y sus casos de uso." \
"2.  Implementar un servidor **DNS** con \`dnsmasq\`." \
"3.  Configurar un servidor **DHCP** para asignación automática de IPs." \
"4.  Implementar **NAT/PAT** para salida a Internet." \
"5.  Analizar el **MSS** (Maximum Segment Size) en TCP." \
"6.  Verificar los servicios con herramientas de diagnóstico." \
"" \
"## Herramientas necesarias" \
"" \
"- Linux con privilegios de superusuario." \
"- Comandos: \`ip\`, \`ping\`, \`tcpdump\`, \`curl\`, \`nslookup\`, \`dig\`." \
"- \`dnsmasq\` para servicios DNS y DHCP." \
"- \`iptables\` para NAT." \
"" \
"## Topología" \
"" \
"La topología extiende la del laboratorio 06 agregando servidores DNS y DHCP en la sede." \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    subgraph Sede_Central" \
"        R1[Router 1 Sede 10.0.0.1]" \
"        LAN1[Red Sede 10.0.0.0/24]" \
"        DNS[Servidor DNS 10.0.0.5]" \
"        DHCP[Servidor DHCP 10.0.0.6]" \
"        NAT[NAT/PAT Gateway]" \
"    end" \
"    subgraph Sucursal_A" \
"        R2[Router 2 Sucursal A 10.0.1.1]" \
"        LAN2[Red Sucursal A 10.0.1.0/24]" \
"    end" \
"    subgraph Sucursal_B" \
"        R3[Router 3 Sucursal B 10.0.2.1]" \
"        LAN3[Red Sucursal B 10.0.2.0/24]" \
"    end" \
"    R1 --- R2" \
"    R2 --- R3" \
"    LAN1 --- R1" \
"    DNS --- R1" \
"    DHCP --- R1" \
"    NAT --- R1" \
"    LAN2 --- R2" \
"    LAN3 --- R3" \
"    R1 --- Internet((Internet))" \
"\`\`\`" \
"" \
"**Direccionamiento:**" \
"" \
"| Dispositivo | Interfaz | Dirección IP |" \
"|-------------|----------|--------------|" \
"| R1 (Sede) | eth0 (LAN) | 10.0.0.1/24 |" \
"| R1 (Sede) | eth1 (R1-R2) | 192.168.1.1/30 |" \
"| R1 (Sede) | WAN | 192.168.100.1/24 |" \
"| R2 (Sucursal A) | eth0 (LAN) | 10.0.1.1/24 |" \
"| R2 (Sucursal A) | eth1 (R1-R2) | 192.168.1.2/30 |" \
"| R3 (Sucursal B) | eth0 (LAN) | 10.0.2.1/24 |" \
"| R3 (Sucursal B) | eth1 (R2-R3) | 192.168.2.2/30 |" \
"| Servidor DNS | - | 10.0.0.5/24 |" \
"| Servidor DHCP | - | 10.0.0.6/24 |" \
"| Cliente Sede (DHCP) | - | 10.0.0.100/24 |" \
"| Cliente Sucursal A | - | 10.0.1.10/24 |" \
"| Cliente Sucursal B | - | 10.0.2.10/24 |" \
"" \
"## Construcción de la red" \
"" \
"### Paso 1: Verificar infraestructura existente" \
"" \
"Asegurémonos de que el laboratorio 06 está funcionando:" \
"" \
"\`\`\`bash" \
"# Verificar namespaces" \
"sudo ip netns list" \
"" \
"# Verificar conectividad entre sede y sucursales" \
"sudo ip netns exec clienteSede ping -c 2 10.0.1.10" \
"\`\`\`" \
"" \
"Si no existen los namespaces, ejecuta los comandos del laboratorio 06." \
"" \
"### Paso 2: Crear namespaces para servicios" \
"" \
"\`\`\`bash" \
"# Servidores de servicios" \
"sudo ip netns add servidorDNS" \
"sudo ip netns add servidorDHCP" \
"sudo ip netns add clienteDHCP" \
"\`\`\`" \
"" \
"### Paso 3: Conectar servicios a la red" \
"" \
"\`\`\`bash" \
"# Servidor DNS -> R1" \
"sudo ip link add veth-dns type veth peer name veth-r1dns" \
"sudo ip link set veth-dns netns servidorDNS" \
"sudo ip link set veth-r1dns netns R1" \
"" \
"# Servidor DHCP -> R1" \
"sudo ip link add veth-dhcp type veth peer name veth-r1dhcp" \
"sudo ip link set veth-dhcp netns servidorDHCP" \
"sudo ip link set veth-r1dhcp netns R1" \
"" \
"# Cliente DHCP -> R1" \
"sudo ip link add veth-dhcpcl type veth peer name veth-r1dhcpcl" \
"sudo ip link set veth-dhcpcl netns clienteDHCP" \
"sudo ip link set veth-r1dhcpcl netns R1" \
"\`\`\`" \
"" \
"### Paso 4: Asignar direcciones IP" \
"" \
"\`\`\`bash" \
"# Servidor DNS" \
"sudo ip netns exec servidorDNS ip addr add 10.0.0.5/24 dev veth-dns" \
"sudo ip netns exec servidorDNS ip link set veth-dns up" \
"sudo ip netns exec servidorDNS ip link set lo up" \
"sudo ip netns exec servidorDNS ip route add default via 10.0.0.1" \
"" \
"# Servidor DHCP" \
"sudo ip netns exec servidorDHCP ip addr add 10.0.0.6/24 dev veth-dhcp" \
"sudo ip netns exec servidorDHCP ip link set veth-dhcp up" \
"sudo ip netns exec servidorDHCP ip link set lo up" \
"sudo ip netns exec servidorDHCP ip route add default via 10.0.0.1" \
"" \
"# Cliente DHCP (sin IP fija, usará DHCP)" \
"sudo ip netns exec clienteDHCP ip link set veth-dhcpcl up" \
"sudo ip netns exec clienteDHCP ip link set lo up" \
"\`\`\`" \
"" \
"### Paso 5: Configurar NAT en R1 para salida a Internet" \
"" \
"\`\`\`bash" \
"# Crear interfaz WAN en R1" \
"sudo ip link add veth-wan type veth peer name veth-host" \
"sudo ip link set veth-wan netns R1" \
"sudo ip netns exec R1 ip addr add 192.168.100.1/24 dev veth-wan" \
"sudo ip netns exec R1 ip link set veth-wan up" \
"sudo ip addr add 192.168.100.2/24 dev veth-host" \
"sudo ip link set veth-host up" \
"" \
"# Habilitar forwarding y NAT" \
"sudo ip netns exec R1 sysctl -w net.ipv4.ip_forward=1" \
"sudo ip netns exec R1 iptables -t nat -A POSTROUTING -o veth-wan -j MASQUERADE" \
"sudo ip netns exec R1 iptables -A FORWARD -i veth-r1c -o veth-wan -j ACCEPT" \
"sudo ip netns exec R1 iptables -A FORWARD -i veth-wan -o veth-r1c -m state --state RELATED,ESTABLISHED -j ACCEPT" \
"" \
"# Ruta en el host para el retorno" \
"sudo ip route add 10.0.0.0/8 via 192.168.100.1" \
"\`\`\`" \
"" \
"### Paso 6: Instalar y configurar servidor DNS" \
"" \
"\`\`\`bash" \
"# Instalar dnsmasq en el servidor DNS" \
"sudo ip netns exec servidorDNS apt-get update" \
"sudo ip netns exec servidorDNS apt-get install -y dnsmasq" \
"" \
"# Configurar dnsmasq" \
"sudo ip netns exec servidorDNS cat > /etc/dnsmasq.conf << 'EOF'" \
"interface=veth-dns" \
"bind-interfaces" \
"dhcp-range=10.0.0.100,10.0.0.200,255.255.255.0,12h" \
"dhcp-option=3,10.0.0.1" \
"dhcp-option=6,10.0.0.5" \
"server=8.8.8.8" \
"server=8.8.4.4" \
"EOF" \
"" \
"# Iniciar dnsmasq" \
"sudo ip netns exec servidorDNS dnsmasq" \
"\`\`\`" \
"" \
"### Paso 7: Instalar y configurar servidor DHCP" \
"" \
"\`\`\`bash" \
"# Instalar dnsmasq en el servidor DHCP" \
"sudo ip netns exec servidorDHCP apt-get update" \
"sudo ip netns exec servidorDHCP apt-get install -y dnsmasq" \
"" \
"# Configurar dnsmasq como DHCP" \
"sudo ip netns exec servidorDHCP cat > /etc/dnsmasq.conf << 'EOF'" \
"interface=veth-dhcp" \
"bind-interfaces" \
"dhcp-range=10.0.0.100,10.0.0.200,255.255.255.0,12h" \
"dhcp-option=3,10.0.0.1" \
"dhcp-option=6,10.0.0.5" \
"EOF" \
"" \
"# Iniciar dnsmasq" \
"sudo ip netns exec servidorDHCP dnsmasq" \
"\`\`\`" \
"" \
"### Paso 8: Configurar cliente DHCP" \
"" \
"\`\`\`bash" \
"# En el cliente DHCP, obtener IP mediante dhclient" \
"sudo ip netns exec clienteDHCP dhclient veth-dhcpcl" \
"\`\`\`" \
"" \
"### Paso 9: Verificar conectividad" \
"" \
"\`\`\`bash" \
"# Cliente DHCP a Internet" \
"sudo ip netns exec clienteDHCP ping -c 4 8.8.8.8" \
"" \
"# Cliente DHCP a Sucursal A" \
"sudo ip netns exec clienteDHCP ping -c 4 10.0.1.10" \
"" \
"# Resolución DNS (usando el servidor configurado)" \
"sudo ip netns exec clienteDHCP nslookup google.com" \
"\`\`\`" \
"" \
"**Salida esperada:** Todos los pings con 0% de pérdida." \
"" \
"## Análisis de TCP y UDP" \
"" \
"### Paso 10: Capturar tráfico TCP (HTTP)" \
"" \
"\`\`\`bash" \
"# Iniciar captura en R1" \
"sudo ip netns exec R1 tcpdump -i veth-r1c -n -v tcp port 80" \
"\`\`\`" \
"" \
"En otra terminal:" \
"" \
"\`\`\`bash" \
"sudo ip netns exec clienteDHCP curl -s http://google.com > /dev/null" \
"\`\`\`" \
"" \
"**Interpretación:** Se observa el handshake TCP (SYN, SYN-ACK, ACK) y la transferencia de datos." \
"" \
"### Paso 11: Capturar tráfico UDP (DNS)" \
"" \
"\`\`\`bash" \
"# Iniciar captura en R1" \
"sudo ip netns exec R1 tcpdump -i veth-r1c -n -v udp port 53" \
"\`\`\`" \
"" \
"En otra terminal:" \
"" \
"\`\`\`bash" \
"sudo ip netns exec clienteDHCP nslookup google.com" \
"\`\`\`" \
"" \
"**Interpretación:** Se observan paquetes UDP sin handshake previo." \
"" \
"## Análisis de MSS" \
"" \
"### Paso 12: Verificar MSS en conexiones TCP" \
"" \
"\`\`\`bash" \
"sudo ip netns exec clienteDHCP curl -v http://google.com 2>&1 | grep MSS" \
"\`\`\`" \
"" \
"**Interpretación:** El MSS típico en Ethernet es 1460 bytes (MTU 1500 - 40 bytes de overhead TCP/IP)." \
"" \
"## Ejercicios prácticos" \
"" \
"### Ejercicio 1: Agregar registros DNS locales" \
"" \
"Agrega entradas al archivo \`/etc/hosts\` del servidor DNS para resolver nombres internos." \
"" \
"\`\`\`bash" \
"sudo ip netns exec servidorDNS echo '10.0.0.10 servidor-interno.secops.local' >> /etc/hosts" \
"\`\`\`" \
"" \
"### Ejercicio 2: Analizar NAT en R1" \
"" \
"\`\`\`bash" \
"# Ver tabla NAT" \
"sudo ip netns exec R1 iptables -t nat -L -v" \
"" \
"# Ver conexiones NAT activas" \
"sudo ip netns exec R1 conntrack -L" \
"\`\`\`" \
"" \
"### Ejercicio 3: Verificar con dig" \
"" \
"\`\`\`bash" \
"sudo ip netns exec clienteDHCP dig google.com" \
"\`\`\`" \
"" \
"## Errores comunes y soluciones" \
"" \
"| Error | Causa | Solución |" \
"|-------|-------|----------|" \
"| DHCP no asigna IP | dnsmasq no está corriendo. | Verificar proceso con \`ps aux | grep dnsmasq\`. |" \
"| DNS no resuelve | Servidor DNS no configurado. | Verificar \`/etc/dnsmasq.conf\`. |" \
"| No sale a Internet | NAT no configurado. | Verificar \`ip_forward=1\` y reglas de iptables. |" \
"| Paquetes fragmentados | MSS incorrecto. | Verificar MTU/MSS en la conexión. |" \
"" \
"## Conceptos clave del Tema 7 aplicados" \
"" \
"| Concepto | Aplicación en el laboratorio |" \
"|----------|------------------------------|" \
"| TCP | Transferencia HTTP, conexión orientada |" \
"| UDP | Consultas DNS, no orientado a conexión |" \
"| MSS | Tamaño máximo de segmento TCP (1460 bytes) |" \
"| DNS | Resolución de nombres con dnsmasq |" \
"| DHCP | Asignación automática de IPs |" \
"| NAT/PAT | Traducción de direcciones para salida a Internet |" \
"" \
"## Conclusiones técnicas" \
"" \
"En este laboratorio hemos:" \
"" \
"1.  Implementado **servicios DNS y DHCP** en la red." \
"2.  Configurado **NAT/PAT** para salida a Internet." \
"3.  Analizado la diferencia entre **TCP y UDP** mediante capturas." \
"4.  Verificado el **MSS** en conexiones TCP." \
"5.  Comprendido la importancia de los servicios de red para los usuarios." \
"" \
"Los protocolos y servicios de red son la capa que permite a los usuarios finales utilizar la infraestructura de red de manera transparente. DNS y DHCP simplifican la administración, mientras que NAT permite el acceso a Internet con direcciones privadas." \
"" \
"## Preparación para el siguiente laboratorio" \
"" \
"Hemos dejado la red con servicios DNS, DHCP y NAT funcionando en la sede. En el **Laboratorio 08** exploraremos **Seguridad en Redes**, implementando firewalls, ACLs y una DMZ para proteger la infraestructura." \
"" \
"---" \
"" \
"**¡Laboratorio 07 completado!** Has implementado servicios de red esenciales. Continúa con el **Laboratorio 08**." \
> "$LAB_DIR/index.md"

# Actualizar mkdocs.yml
MKCDOCS="$PROJECT_DIR/mkdocs.yml"
if grep -q "07 - Protocolos" "$MKCDOCS"; then
    echo "⚠️ El laboratorio 07 ya está registrado en mkdocs.yml. Omitiendo..."
else
    sed -i '/06 - Enrutamiento y Conectividad entre Redes/a \      - '\''07 - Protocolos y Servicios de Red'\'': '\''labs/lab-07/index.md'\''' "$MKCDOCS"
    echo "✅ Laboratorio 07 agregado a la navegación en mkdocs.yml"
fi

echo "✅ Laboratorio 07 creado exitosamente en $LAB_DIR"
echo "📝 Ahora compila el sitio con: mkdocs build --clean && mkdocs serve --dev-addr=127.0.0.1:8000"
