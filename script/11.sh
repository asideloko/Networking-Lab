#!/bin/bash
# create_lab11.sh – Arquitectura de Red Empresarial

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml"
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-11"
mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

echo "📁 Creando laboratorio 11 en $LAB_DIR"

printf '%s\n' \
"# Laboratorio 11 – Arquitectura de Red Empresarial" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ha implementado su infraestructura WAN (Laboratorio 10). Ahora necesita diseñar la arquitectura de red completa para su sede central." \
"" \
"## Topología" \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    C1[Core Switch 1]" \
"    C2[Core Switch 2]" \
"    D1[Dist Switch 1]" \
"    D2[Dist Switch 2]" \
"    A1[Access Switch 1]" \
"    A2[Access Switch 2]" \
"    A3[Access Switch 3]" \
"    FW[Firewall]" \
"    WEB[Servidor Web]" \
"    DNS[Servidor DNS]" \
"    V10[VLAN 10 Ventas]" \
"    V20[VLAN 20 IT]" \
"    V30[VLAN 30 Admin]" \
"    C1 --- C2" \
"    C1 --- D1" \
"    C1 --- D2" \
"    C2 --- D1" \
"    C2 --- D2" \
"    D1 --- A1" \
"    D1 --- A2" \
"    D1 --- A3" \
"    D2 --- A1" \
"    D2 --- A2" \
"    D2 --- A3" \
"    A1 --- V10" \
"    A1 --- V20" \
"    A1 --- V30" \
"    A2 --- V10" \
"    A2 --- V20" \
"    A2 --- V30" \
"    A3 --- V10" \
"    A3 --- V20" \
"    A3 --- V30" \
"    D1 --- FW" \
"    D2 --- FW" \
"    FW --- WEB" \
"    FW --- DNS" \
"    C1 --- Internet" \
"    C2 --- Internet" \
"\`\`\`" \
"" \
"**Direccionamiento:**" \
"" \
"| Dispositivo | Interfaz | Dirección IP | Rol |" \
"|-------------|----------|--------------|-----|" \
"| Core 1 | eth0 | 10.0.0.1/24 | Core |" \
"| Core 2 | eth0 | 10.0.0.2/24 | Core |" \
"| Dist 1 | eth0 | 10.0.1.1/24 | Distribución |" \
"| Dist 2 | eth0 | 10.0.1.2/24 | Distribución |" \
"| Firewall | eth0 (WAN) | 192.168.100.1/24 | Seguridad |" \
"| Firewall | eth1 (DMZ) | 10.0.99.1/24 | DMZ |" \
"| Firewall | eth2 (LAN) | 10.0.0.254/24 | LAN |" \
"| Servidor Web | - | 10.0.99.10/24 | DMZ |" \
"| Servidor DNS | - | 10.0.99.5/24 | DMZ |" \
"| VLAN 10 | - | 10.0.10.0/24 | Ventas |" \
"| VLAN 20 | - | 10.0.20.0/24 | IT |" \
"| VLAN 30 | - | 10.0.30.0/24 | Admin |" \
"" \
"## Construcción" \
"" \
"### Paso 1: Crear namespaces" \
"" \
"\`\`\`bash" \
"sudo ip netns add Core1" \
"sudo ip netns add Core2" \
"sudo ip netns add Dist1" \
"sudo ip netns add Dist2" \
"sudo ip netns add Access1" \
"sudo ip netns add Access2" \
"sudo ip netns add Access3" \
"sudo ip netns add Firewall" \
"sudo ip netns add ServidorWeb" \
"sudo ip netns add ServidorDNS" \
"\`\`\`" \
"" \
"### Paso 2: Conectar Core a Distribución" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-c1d1 type veth peer name veth-d1c1" \
"sudo ip link set veth-c1d1 netns Core1" \
"sudo ip link set veth-d1c1 netns Dist1" \
"sudo ip netns exec Core1 ip addr add 10.0.0.1/24 dev veth-c1d1" \
"sudo ip netns exec Core1 ip link set veth-c1d1 up" \
"sudo ip netns exec Dist1 ip addr add 10.0.1.1/24 dev veth-d1c1" \
"sudo ip netns exec Dist1 ip link set veth-d1c1 up" \
"" \
"sudo ip link add veth-c1d2 type veth peer name veth-d2c1" \
"sudo ip link set veth-c1d2 netns Core1" \
"sudo ip link set veth-d2c1 netns Dist2" \
"sudo ip netns exec Core1 ip addr add 10.0.0.2/24 dev veth-c1d2" \
"sudo ip netns exec Core1 ip link set veth-c1d2 up" \
"sudo ip netns exec Dist2 ip addr add 10.0.1.2/24 dev veth-d2c1" \
"sudo ip netns exec Dist2 ip link set veth-d2c1 up" \
"" \
"sudo ip link add veth-c2d1 type veth peer name veth-d1c2" \
"sudo ip link set veth-c2d1 netns Core2" \
"sudo ip link set veth-d1c2 netns Dist1" \
"sudo ip netns exec Core2 ip addr add 10.0.0.2/24 dev veth-c2d1" \
"sudo ip netns exec Core2 ip link set veth-c2d1 up" \
"sudo ip netns exec Dist1 ip addr add 10.0.1.1/24 dev veth-d1c2" \
"sudo ip netns exec Dist1 ip link set veth-d1c2 up" \
"" \
"sudo ip link add veth-c2d2 type veth peer name veth-d2c2" \
"sudo ip link set veth-c2d2 netns Core2" \
"sudo ip link set veth-d2c2 netns Dist2" \
"sudo ip netns exec Core2 ip addr add 10.0.0.2/24 dev veth-c2d2" \
"sudo ip netns exec Core2 ip link set veth-c2d2 up" \
"sudo ip netns exec Dist2 ip addr add 10.0.1.2/24 dev veth-d2c2" \
"sudo ip netns exec Dist2 ip link set veth-d2c2 up" \
"\`\`\`" \
"" \
"### Paso 3: Conectar Distribución a Acceso" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-d1a1 type veth peer name veth-a1d1" \
"sudo ip link set veth-d1a1 netns Dist1" \
"sudo ip link set veth-a1d1 netns Access1" \
"sudo ip netns exec Dist1 ip link set veth-d1a1 up" \
"sudo ip netns exec Access1 ip link set veth-a1d1 up" \
"" \
"sudo ip link add veth-d2a1 type veth peer name veth-a1d2" \
"sudo ip link set veth-d2a1 netns Dist2" \
"sudo ip link set veth-a1d2 netns Access1" \
"sudo ip netns exec Dist2 ip link set veth-d2a1 up" \
"sudo ip netns exec Access1 ip link set veth-a1d2 up" \
"" \
"sudo ip link add veth-d1a2 type veth peer name veth-a2d1" \
"sudo ip link set veth-d1a2 netns Dist1" \
"sudo ip link set veth-a2d1 netns Access2" \
"sudo ip netns exec Dist1 ip link set veth-d1a2 up" \
"sudo ip netns exec Access2 ip link set veth-a2d1 up" \
"" \
"sudo ip link add veth-d2a2 type veth peer name veth-a2d2" \
"sudo ip link set veth-d2a2 netns Dist2" \
"sudo ip link set veth-a2d2 netns Access2" \
"sudo ip netns exec Dist2 ip link set veth-d2a2 up" \
"sudo ip netns exec Access2 ip link set veth-a2d2 up" \
"" \
"sudo ip link add veth-d1a3 type veth peer name veth-a3d1" \
"sudo ip link set veth-d1a3 netns Dist1" \
"sudo ip link set veth-a3d1 netns Access3" \
"sudo ip netns exec Dist1 ip link set veth-d1a3 up" \
"sudo ip netns exec Access3 ip link set veth-a3d1 up" \
"" \
"sudo ip link add veth-d2a3 type veth peer name veth-a3d2" \
"sudo ip link set veth-d2a3 netns Dist2" \
"sudo ip link set veth-a3d2 netns Access3" \
"sudo ip netns exec Dist2 ip link set veth-d2a3 up" \
"sudo ip netns exec Access3 ip link set veth-a3d2 up" \
"\`\`\`" \
"" \
"### Paso 4: Configurar Firewall y DMZ" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-fw-wan type veth peer name veth-wan-fw" \
"sudo ip link set veth-fw-wan netns Firewall" \
"sudo ip netns exec Firewall ip addr add 192.168.100.1/24 dev veth-fw-wan" \
"sudo ip netns exec Firewall ip link set veth-fw-wan up" \
"sudo ip addr add 192.168.100.2/24 dev veth-wan-fw" \
"sudo ip link set veth-wan-fw up" \
"" \
"sudo ip link add veth-fw-dmz type veth peer name veth-dmz-fw" \
"sudo ip link set veth-fw-dmz netns Firewall" \
"sudo ip netns exec Firewall ip addr add 10.0.99.1/24 dev veth-fw-dmz" \
"sudo ip netns exec Firewall ip link set veth-fw-dmz up" \
"sudo ip link set veth-dmz-fw netns ServidorWeb" \
"sudo ip netns exec ServidorWeb ip addr add 10.0.99.10/24 dev veth-dmz-fw" \
"sudo ip netns exec ServidorWeb ip link set veth-dmz-fw up" \
"sudo ip netns exec ServidorWeb ip route add default via 10.0.99.1" \
"" \
"sudo ip link add veth-fw-lan type veth peer name veth-lan-fw" \
"sudo ip link set veth-fw-lan netns Firewall" \
"sudo ip netns exec Firewall ip addr add 10.0.0.254/24 dev veth-fw-lan" \
"sudo ip netns exec Firewall ip link set veth-fw-lan up" \
"sudo ip link set veth-lan-fw netns Core1" \
"sudo ip netns exec Core1 ip addr add 10.0.0.1/24 dev veth-lan-fw" \
"sudo ip netns exec Core1 ip link set veth-lan-fw up" \
"\`\`\`" \
"" \
"### Paso 5: Configurar enrutamiento y NAT" \
"" \
"\`\`\`bash" \
"sudo ip netns exec Firewall sysctl -w net.ipv4.ip_forward=1" \
"sudo ip netns exec Firewall iptables -t nat -A POSTROUTING -o veth-fw-wan -j MASQUERADE" \
"sudo ip netns exec Firewall iptables -A FORWARD -i veth-fw-lan -o veth-fw-wan -j ACCEPT" \
"sudo ip netns exec Core1 ip route add default via 10.0.0.254" \
"sudo ip netns exec Core2 ip route add default via 10.0.0.254" \
"sudo ip netns exec Dist1 ip route add default via 10.0.0.1" \
"sudo ip netns exec Dist2 ip route add default via 10.0.0.1" \
"\`\`\`" \
"" \
"### Paso 6: Verificar" \
"" \
"\`\`\`bash" \
"sudo ip netns exec Core1 ping -c 4 8.8.8.8" \
"sudo ip netns exec Core1 ping -c 4 10.0.99.10" \
"\`\`\`" \
"" \
"## Alta Disponibilidad" \
"" \
"### Simular fallo de Core1" \
"" \
"\`\`\`bash" \
"sudo ip netns exec Core1 ip link set veth-c1d1 down" \
"sudo ip netns exec Dist1 ping -c 4 10.0.99.10" \
"\`\`\`" \
"" \
"## Segmentación VLAN" \
"" \
"| VLAN | ID | Subred | Propósito |" \
"|------|----|--------|-----------|" \
"| Ventas | 10 | 10.0.10.0/24 | Departamento Ventas |" \
"| IT | 20 | 10.0.20.0/24 | Departamento IT |" \
"| Admin | 30 | 10.0.30.0/24 | Administración |" \
"| DMZ | 99 | 10.0.99.0/24 | Servidores públicos |" \
"" \
"## Ejercicios" \
"" \
"### Ejercicio 1: Agregar redundancia de enlaces" \
"" \
"Conecta Access2 a Dist1 y Dist2 para redundancia." \
"" \
"### Ejercicio 2: Configurar STP" \
"" \
"Investiga STP y cómo prevenir bucles." \
"" \
"## Conceptos clave" \
"" \
"| Concepto | Aplicación |" \
"|----------|------------|" \
"| Modelo jerárquico | Core-Distribución-Acceso |" \
"| Alta disponibilidad | Redundancia Core1/Core2 |" \
"| Redundancia | Enlaces duales |" \
"| Segmentación | VLAN 10, 20, 30 |" \
"| DMZ | Servidores aislados |" \
"" \
"## Conclusiones" \
"" \
"La arquitectura jerárquica proporciona escalabilidad, disponibilidad y facilidad de administración. La redundancia elimina puntos únicos de fallo." \
"" \
"---" \
"" \
"**¡Laboratorio 11 completado!** Continúa con el **Laboratorio 12**." \
> "$LAB_DIR/index.md"

if ! grep -q "11 - Arquitectura" "$PROJECT_DIR/mkdocs.yml"; then
    sed -i '/10 - Infraestructura WAN y Core/a \      - '\''11 - Arquitectura de Red Empresarial'\'': '\''labs/lab-11/index.md'\''' "$PROJECT_DIR/mkdocs.yml"
fi

echo "✅ Laboratorio 11 creado"
