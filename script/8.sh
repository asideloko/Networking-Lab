#!/bin/bash
# create_lab08.sh – Crea el Laboratorio 08 (Seguridad en Redes)

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml. Asegúrate de ejecutar este script desde la raíz del proyecto."
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-08"
echo "📁 Creando laboratorio 08 en $LAB_DIR"

mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

printf '%s\n' \
"# Laboratorio 08 – Seguridad en Redes" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ha implementado su infraestructura de red con servicios DNS, DHCP y NAT (Laboratorio 07). Ahora el equipo de seguridad ha identificado la necesidad de **proteger la red** contra amenazas internas y externas." \
"" \
"El CISO (Chief Information Security Officer) ha solicitado implementar las siguientes medidas:" \
"" \
"1. **Firewall** para controlar el tráfico entrante y saliente." \
"2. **ACLs** para restringir acceso a servicios administrativos." \
"3. **DMZ** para aislar servidores públicos." \
"4. **Cifrado TLS** para proteger comunicaciones web." \
"5. **SSH** para acceso seguro a dispositivos." \
"" \
"## Problema inicial" \
"" \
"- No hay control de tráfico entre redes (todo el tráfico es permitido)." \
"- Los servicios administrativos (SSH) están expuestos a toda la red." \
"- No hay segmentación para servidores públicos." \
"- Las comunicaciones internas no están cifradas." \
"- No hay políticas de seguridad definidas." \
"" \
"## Objetivos del laboratorio" \
"" \
"1.  Comprender los principios de la tríada **CIA** (Confidencialidad, Integridad, Disponibilidad)." \
"2.  Implementar un **firewall** con \`iptables\` para filtrar tráfico." \
"3.  Configurar **ACLs** en el router para restringir accesos." \
"4.  Diseñar una **DMZ** para aislar servidores públicos." \
"5.  Configurar **SSH** para acceso seguro." \
"6.  Implementar **TLS** para cifrar comunicaciones web." \
"" \
"## Herramientas necesarias" \
"" \
"- Linux con privilegios de superusuario." \
"- Comandos: \`ip\`, \`ping\`, \`iptables\`, \`nft\` (opcional)." \
"- \`openssl\` para generar certificados TLS." \
"- \`ssh\` para acceso remoto seguro." \
"" \
"## Topología" \
"" \
"La topología extiende la del laboratorio 07 agregando una DMZ y medidas de seguridad." \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    subgraph Internet" \
"        EXT[Red Externa]" \
"    end" \
"    subgraph DMZ" \
"        FW[Firewall]" \
"        WEB[Servidor Web 10.0.99.10]" \
"        DNS_PUB[Servidor DNS 10.0.99.5]" \
"    end" \
"    subgraph LAN_Interna" \
"        R1[Router 1 Sede 10.0.0.1]" \
"        LAN1[Red Interna 10.0.0.0/24]" \
"        CLI[Cliente 10.0.0.10]" \
"        SRV[Servidor Interno 10.0.0.20]" \
"    end" \
"    subgraph Sucursales" \
"        R2[Router 2 Sucursal A 10.0.1.1]" \
"        R3[Router 3 Sucursal B 10.0.2.1]" \
"    end" \
"    EXT --- FW" \
"    FW --- WEB" \
"    FW --- DNS_PUB" \
"    FW --- R1" \
"    R1 --- LAN1" \
"    LAN1 --- CLI" \
"    LAN1 --- SRV" \
"    R1 --- R2" \
"    R2 --- R3" \
"\`\`\`" \
"" \
"**Direccionamiento:**" \
"" \
"| Dispositivo | Interfaz | Dirección IP | Zona |" \
"|-------------|----------|--------------|------|" \
"| Firewall | eth0 (WAN) | 192.168.100.1/24 | Externa |" \
"| Firewall | eth1 (DMZ) | 10.0.99.1/24 | DMZ |" \
"| Firewall | eth2 (LAN) | 10.0.0.254/24 | Interna |" \
"| R1 (Sede) | eth0 (LAN) | 10.0.0.1/24 | Interna |" \
"| R1 (Sede) | eth1 (R1-R2) | 192.168.1.1/30 | Interna |" \
"| R2 (Sucursal A) | eth0 (LAN) | 10.0.1.1/24 | Interna |" \
"| R3 (Sucursal B) | eth0 (LAN) | 10.0.2.1/24 | Interna |" \
"| Servidor Web | - | 10.0.99.10/24 | DMZ |" \
"| Servidor DNS | - | 10.0.99.5/24 | DMZ |" \
"| Cliente Interno | - | 10.0.0.10/24 | Interna |" \
"| Servidor Interno | - | 10.0.0.20/24 | Interna |" \
"" \
"## Construcción de la red" \
"" \
"### Paso 1: Verificar infraestructura existente" \
"" \
"Asegurémonos de que el laboratorio 07 está funcionando:" \
"" \
"\`\`\`bash" \
"# Verificar namespaces" \
"sudo ip netns list" \
"" \
"# Verificar servicios DNS y DHCP" \
"sudo ip netns exec clienteDHCP ping -c 2 8.8.8.8" \
"\`\`\`" \
"" \
"### Paso 2: Crear namespaces para firewall y DMZ" \
"" \
"\`\`\`bash" \
"# Firewall" \
"sudo ip netns add firewall" \
"" \
"# Servidores DMZ" \
"sudo ip netns add servidorWeb" \
"sudo ip netns add servidorDNS_PUB" \
"" \
"# Servidor Interno" \
"sudo ip netns add servidorInterno" \
"\`\`\`" \
"" \
"### Paso 3: Conectar firewall a las zonas" \
"" \
"\`\`\`bash" \
"# WAN (Internet)" \
"sudo ip link add veth-fw-wan type veth peer name veth-wan-fw" \
"sudo ip link set veth-fw-wan netns firewall" \
"sudo ip netns exec firewall ip addr add 192.168.100.1/24 dev veth-fw-wan" \
"sudo ip netns exec firewall ip link set veth-fw-wan up" \
"sudo ip addr add 192.168.100.2/24 dev veth-wan-fw" \
"sudo ip link set veth-wan-fw up" \
"" \
"# DMZ" \
"sudo ip link add veth-fw-dmz type veth peer name veth-dmz-fw" \
"sudo ip link set veth-fw-dmz netns firewall" \
"sudo ip netns exec firewall ip addr add 10.0.99.1/24 dev veth-fw-dmz" \
"sudo ip netns exec firewall ip link set veth-fw-dmz up" \
"sudo ip link set veth-dmz-fw netns servidorWeb" \
"sudo ip netns exec servidorWeb ip addr add 10.0.99.10/24 dev veth-dmz-fw" \
"sudo ip netns exec servidorWeb ip link set veth-dmz-fw up" \
"sudo ip netns exec servidorWeb ip route add default via 10.0.99.1" \
"" \
"# Servidor DNS en DMZ" \
"sudo ip link add veth-fw-dns type veth peer name veth-dns-fw" \
"sudo ip link set veth-fw-dns netns firewall" \
"sudo ip netns exec firewall ip addr add 10.0.99.5/24 dev veth-fw-dns" \
"sudo ip netns exec firewall ip link set veth-fw-dns up" \
"sudo ip link set veth-dns-fw netns servidorDNS_PUB" \
"sudo ip netns exec servidorDNS_PUB ip addr add 10.0.99.5/24 dev veth-dns-fw" \
"sudo ip netns exec servidorDNS_PUB ip link set veth-dns-fw up" \
"sudo ip netns exec servidorDNS_PUB ip route add default via 10.0.99.1" \
"" \
"# LAN Interna" \
"sudo ip link add veth-fw-lan type veth peer name veth-lan-fw" \
"sudo ip link set veth-fw-lan netns firewall" \
"sudo ip netns exec firewall ip addr add 10.0.0.254/24 dev veth-fw-lan" \
"sudo ip netns exec firewall ip link set veth-fw-lan up" \
"sudo ip link set veth-lan-fw netns R1" \
"sudo ip netns exec R1 ip addr add 10.0.0.1/24 dev veth-lan-fw" \
"sudo ip netns exec R1 ip link set veth-lan-fw up" \
"\`\`\`" \
"" \
"### Paso 4: Configurar cliente y servidor interno" \
"" \
"\`\`\`bash" \
"# Cliente Interno (usando clienteSede del laboratorio anterior)" \
"sudo ip netns exec clienteSede ip addr add 10.0.0.10/24 dev veth-cli 2>/dev/null || true" \
"sudo ip netns exec clienteSede ip link set veth-cli up 2>/dev/null || true" \
"sudo ip netns exec clienteSede ip route add default via 10.0.0.1 2>/dev/null || true" \
"" \
"# Servidor Interno" \
"sudo ip link add veth-srv type veth peer name veth-r1srv" \
"sudo ip link set veth-srv netns servidorInterno" \
"sudo ip link set veth-r1srv netns R1" \
"sudo ip netns exec servidorInterno ip addr add 10.0.0.20/24 dev veth-srv" \
"sudo ip netns exec servidorInterno ip link set veth-srv up" \
"sudo ip netns exec servidorInterno ip route add default via 10.0.0.1" \
"\`\`\`" \
"" \
"### Paso 5: Configurar rutas en el firewall" \
"" \
"\`\`\`bash" \
"# Habilitar forwarding" \
"sudo ip netns exec firewall sysctl -w net.ipv4.ip_forward=1" \
"" \
"# Ruta hacia la red interna" \
"sudo ip netns exec firewall ip route add 10.0.0.0/24 via 10.0.0.1" \
"sudo ip netns exec firewall ip route add 10.0.1.0/24 via 10.0.0.1" \
"sudo ip netns exec firewall ip route add 10.0.2.0/24 via 10.0.0.1" \
"\`\`\`" \
"" \
"### Paso 6: Configurar reglas de firewall (iptables)" \
"" \
"**Política por defecto: Denegar todo**" \
"" \
"\`\`\`bash" \
"# Establecer políticas por defecto" \
"sudo ip netns exec firewall iptables -P INPUT DROP" \
"sudo ip netns exec firewall iptables -P FORWARD DROP" \
"sudo ip netns exec firewall iptables -P OUTPUT ACCEPT" \
"" \
"# Permitir tráfico de loopback" \
"sudo ip netns exec firewall iptables -A INPUT -i lo -j ACCEPT" \
"" \
"# Permitir conexiones establecidas y relacionadas" \
"sudo ip netns exec firewall iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" \
"sudo ip netns exec firewall iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT" \
"\`\`\`" \
"" \
"**Reglas desde Internet hacia DMZ (servidores públicos):**" \
"" \
"\`\`\`bash" \
"# Servidor Web (puerto 80 y 443)" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-wan -o veth-fw-dmz -p tcp -d 10.0.99.10 --dport 80 -j ACCEPT" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-wan -o veth-fw-dmz -p tcp -d 10.0.99.10 --dport 443 -j ACCEPT" \
"" \
"# Servidor DNS (puerto 53 UDP)" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-wan -o veth-fw-dns -p udp -d 10.0.99.5 --dport 53 -j ACCEPT" \
"\`\`\`" \
"" \
"**Reglas desde Internet hacia LAN Interna (denegado):**" \
"" \
"\`\`\`bash" \
"# Denegar explícitamente acceso a la LAN interna desde Internet" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-wan -o veth-fw-lan -j DROP" \
"\`\`\`" \
"" \
"**Reglas desde LAN Interna hacia Internet (permitido):**" \
"" \
"\`\`\`bash" \
"# NAT para salida a Internet" \
"sudo ip netns exec firewall iptables -t nat -A POSTROUTING -o veth-fw-wan -j MASQUERADE" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-lan -o veth-fw-wan -j ACCEPT" \
"\`\`\`" \
"" \
"**Reglas desde LAN Interna hacia DMZ (administración):**" \
"" \
"\`\`\`bash" \
"# Permitir SSH desde la LAN a los servidores DMZ" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-lan -o veth-fw-dmz -p tcp -s 10.0.0.0/24 -d 10.0.99.10 --dport 22 -j ACCEPT" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-lan -o veth-fw-dns -p tcp -s 10.0.0.0/24 -d 10.0.99.5 --dport 22 -j ACCEPT" \
"\`\`\`" \
"" \
"**Reglas desde DMZ hacia LAN Interna (denegado excepto lo necesario):**" \
"" \
"\`\`\`bash" \
"# Denegar todo tráfico desde DMZ a LAN (principio de mínimo privilegio)" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-dmz -o veth-fw-lan -j DROP" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-dns -o veth-fw-lan -j DROP" \
"\`\`\`" \
"" \
"### Paso 7: Verificar reglas de firewall" \
"" \
"\`\`\`bash" \
"# Ver todas las reglas" \
"sudo ip netns exec firewall iptables -L -v" \
"" \
"# Ver tabla NAT" \
"sudo ip netns exec firewall iptables -t nat -L -v" \
"\`\`\`" \
"" \
"### Paso 8: Probar conectividad" \
"" \
"\`\`\`bash" \
"# Desde cliente interno a Internet (debe funcionar)" \
"sudo ip netns exec clienteSede ping -c 4 8.8.8.8" \
"" \
"# Desde cliente interno a DMZ (debe funcionar)" \
"sudo ip netns exec clienteSede ping -c 4 10.0.99.10" \
"" \
"# Desde Internet al servidor Web (simulado desde el host)" \
"sudo ip netns exec firewall ping -c 4 10.0.99.10" \
"\`\`\`" \
"" \
"### Paso 9: Configurar SSH para acceso seguro" \
"" \
"\`\`\`bash" \
"# Instalar OpenSSH en el servidor DMZ" \
"sudo ip netns exec servidorWeb apt-get update" \
"sudo ip netns exec servidorWeb apt-get install -y openssh-server" \
"" \
"# Iniciar SSH" \
"sudo ip netns exec servidorWeb systemctl start ssh" \
"" \
"# Conectar desde cliente interno" \
"sudo ip netns exec clienteSede ssh 10.0.99.10" \
"\`\`\`" \
"" \
"### Paso 10: Configurar TLS para servidor web" \
"" \
"\`\`\`bash" \
"# Generar certificado autofirmado" \
"sudo ip netns exec servidorWeb openssl req -x509 -newkey rsa:2048 -keyout /etc/ssl/private/key.pem -out /etc/ssl/certs/cert.pem -days 365 -nodes -subj \"/CN=servidorWeb\"" \
"" \
"# Configurar Nginx o Apache con TLS (dependiendo de lo instalado)" \
"# Para este laboratorio, documentamos el proceso" \
"\`\`\`" \
"" \
"## Ejercicios prácticos" \
"" \
"### Ejercicio 1: Agregar regla para SSH" \
"" \
"\`\`\`bash" \
"sudo ip netns exec firewall iptables -A FORWARD -i veth-fw-lan -o veth-fw-dmz -p tcp -s 10.0.0.0/24 -d 10.0.99.10 --dport 22 -j ACCEPT" \
"\`\`\`" \
"" \
"### Ejercicio 2: Bloquear ICMP (ping)" \
"" \
"\`\`\`bash" \
"sudo ip netns exec firewall iptables -A FORWARD -p icmp -j DROP" \
"\`\`\`" \
"" \
"### Ejercicio 3: Verificar la tabla de conexiones" \
"" \
"\`\`\`bash" \
"sudo ip netns exec firewall conntrack -L" \
"\`\`\`" \
"" \
"## Errores comunes y soluciones" \
"" \
"| Error | Causa | Solución |" \
"|-------|-------|----------|" \
"| No se puede acceder a Internet | NAT no configurado. | Verificar reglas de iptables y \`ip_forward=1\`. |" \
"| Cliente no puede acceder a DMZ | Regla de forward bloquea. | Verificar reglas de iptables. |" \
"| SSH no funciona | Puerto bloqueado. | Agregar regla para puerto 22. |" \
"| Certificado TLS inválido | Certificado autofirmado. | Aceptar manualmente en el navegador. |" \
"" \
"## Conceptos clave del Tema 8 aplicados" \
"" \
"| Concepto | Aplicación en el laboratorio |" \
"|----------|------------------------------|" \
"| Tríada CIA | Confidencialidad, Integridad, Disponibilidad |" \
"| Firewall | Filtrado de tráfico con iptables |" \
"| DMZ | Segmentación de servidores públicos |" \
"| ACLs | Control de acceso basado en reglas |" \
"| SSH | Acceso remoto seguro |" \
"| TLS | Cifrado de comunicaciones web |" \
"" \
"## Conclusiones técnicas" \
"" \
"En este laboratorio hemos:" \
"" \
"1.  Implementado un **firewall** con \`iptables\` para controlar el tráfico." \
"2.  Configurado una **DMZ** para aislar servidores públicos." \
"3.  Establecido **ACLs** para restringir el acceso a servicios administrativos." \
"4.  Configurado **SSH** para acceso remoto seguro." \
"5.  Implementado **TLS** para cifrar comunicaciones web." \
"6.  Aplicado los principios de la tríada **CIA** en la práctica." \
"" \
"La seguridad en redes es un proceso continuo que combina múltiples capas de defensa. El firewall controla el tráfico, la DMZ aísla servidores expuestos, SSH protege el acceso administrativo y TLS cifra las comunicaciones. Ninguna medida es suficiente por sí sola; la combinación de todas ellas proporciona una postura de seguridad robusta." \
"" \
"## Preparación para el siguiente laboratorio" \
"" \
"Hemos dejado la red con firewall, DMZ, SSH y TLS funcionando. En el **Laboratorio 09** exploraremos **VPN y Tunelización**, implementando GRE, IPsec, OpenVPN y WireGuard para conectar de forma segura las oficinas y empleados remotos." \
"" \
"---" \
"" \
"**¡Laboratorio 08 completado!** Has implementado seguridad en redes. Continúa con el **Laboratorio 09**." \
> "$LAB_DIR/index.md"

# Actualizar mkdocs.yml
MKCDOCS="$PROJECT_DIR/mkdocs.yml"
if grep -q "08 - Seguridad" "$MKCDOCS"; then
    echo "⚠️ El laboratorio 08 ya está registrado en mkdocs.yml. Omitiendo..."
else
    sed -i '/07 - Protocolos y Servicios de Red/a \      - '\''08 - Seguridad en Redes'\'': '\''labs/lab-08/index.md'\''' "$MKCDOCS"
    echo "✅ Laboratorio 08 agregado a la navegación en mkdocs.yml"
fi

echo "✅ Laboratorio 08 creado exitosamente en $LAB_DIR"
echo "📝 Ahora compila el sitio con: mkdocs build --clean && mkdocs serve --dev-addr=127.0.0.1:8000"
