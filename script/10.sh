#!/bin/bash
# create_lab10.sh – Infraestructura WAN y Core

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml"
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-10"
mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

echo "📁 Creando laboratorio 10 en $LAB_DIR"

printf '%s\n' \
"# Laboratorio 10 – Infraestructura WAN y Core" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ha implementado exitosamente su red con VPN y tunelización (Laboratorio 09). Ahora necesita expandir su infraestructura a nivel geográfico, conectando múltiples sucursales y centros de datos a través de una red WAN robusta y escalable." \
"" \
"## Topología" \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    R1[Router Core 1]" \
"    R2[Router Core 2]" \
"    R3[Router Core 3]" \
"    P1[P Router 1]" \
"    P2[P Router 2]" \
"    P3[P Router 3]" \
"    LAN1[Red Local 10.0.0.0/24]" \
"    LAN2[Red Local 10.1.0.0/24]" \
"    LAN3[Red Local 10.2.0.0/24]" \
"    R1 --- P1" \
"    R2 --- P2" \
"    R3 --- P3" \
"    LAN1 --- R1" \
"    LAN2 --- R2" \
"    LAN3 --- R3" \
"    P1 --- P2" \
"    P2 --- P3" \
"    P1 --- P3" \
"    R1 --- Internet" \
"\`\`\`" \
"" \
"**Direccionamiento:**" \
"" \
"| Dispositivo | Interfaz | Dirección IP | Rol |" \
"|-------------|----------|--------------|-----|" \
"| R1 (PE) | eth0 (LAN) | 10.0.0.1/24 | Provider Edge |" \
"| R1 (PE) | eth1 (P1) | 192.168.1.1/30 | MPLS Core |" \
"| R2 (PE) | eth0 (LAN) | 10.1.0.1/24 | Provider Edge |" \
"| R2 (PE) | eth1 (P2) | 192.168.1.5/30 | MPLS Core |" \
"| R3 (PE) | eth0 (LAN) | 10.2.0.1/24 | Provider Edge |" \
"| R3 (PE) | eth1 (P3) | 192.168.1.9/30 | MPLS Core |" \
"| P1 | eth0 (R1) | 192.168.1.2/30 | P Router |" \
"| P1 | eth1 (P2) | 192.168.1.13/30 | P Router |" \
"| P1 | eth2 (P3) | 192.168.1.17/30 | P Router |" \
"| P2 | eth0 (R2) | 192.168.1.6/30 | P Router |" \
"| P2 | eth1 (P1) | 192.168.1.14/30 | P Router |" \
"| P2 | eth2 (P3) | 192.168.1.21/30 | P Router |" \
"| P3 | eth0 (R3) | 192.168.1.10/30 | P Router |" \
"| P3 | eth1 (P1) | 192.168.1.18/30 | P Router |" \
"| P3 | eth2 (P2) | 192.168.1.22/30 | P Router |" \
"" \
"## Construcción de la red" \
"" \
"### Paso 1: Crear namespaces" \
"" \
"\`\`\`bash" \
"sudo ip netns add PE1" \
"sudo ip netns add PE2" \
"sudo ip netns add PE3" \
"sudo ip netns add P1" \
"sudo ip netns add P2" \
"sudo ip netns add P3" \
"\`\`\`" \
"" \
"### Paso 2: Conectar PE a P" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-pe1p1 type veth peer name veth-p1pe1" \
"sudo ip link set veth-pe1p1 netns PE1" \
"sudo ip link set veth-p1pe1 netns P1" \
"sudo ip netns exec PE1 ip addr add 192.168.1.1/30 dev veth-pe1p1" \
"sudo ip netns exec PE1 ip link set veth-pe1p1 up" \
"sudo ip netns exec P1 ip addr add 192.168.1.2/30 dev veth-p1pe1" \
"sudo ip netns exec P1 ip link set veth-p1pe1 up" \
"" \
"sudo ip link add veth-pe2p2 type veth peer name veth-p2pe2" \
"sudo ip link set veth-pe2p2 netns PE2" \
"sudo ip link set veth-p2pe2 netns P2" \
"sudo ip netns exec PE2 ip addr add 192.168.1.5/30 dev veth-pe2p2" \
"sudo ip netns exec PE2 ip link set veth-pe2p2 up" \
"sudo ip netns exec P2 ip addr add 192.168.1.6/30 dev veth-p2pe2" \
"sudo ip netns exec P2 ip link set veth-p2pe2 up" \
"" \
"sudo ip link add veth-pe3p3 type veth peer name veth-p3pe3" \
"sudo ip link set veth-pe3p3 netns PE3" \
"sudo ip link set veth-p3pe3 netns P3" \
"sudo ip netns exec PE3 ip addr add 192.168.1.9/30 dev veth-pe3p3" \
"sudo ip netns exec PE3 ip link set veth-pe3p3 up" \
"sudo ip netns exec P3 ip addr add 192.168.1.10/30 dev veth-p3pe3" \
"sudo ip netns exec P3 ip link set veth-p3pe3 up" \
"\`\`\`" \
"" \
"### Paso 3: Conectar P routers" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-p1p2 type veth peer name veth-p2p1" \
"sudo ip link set veth-p1p2 netns P1" \
"sudo ip link set veth-p2p1 netns P2" \
"sudo ip netns exec P1 ip addr add 192.168.1.13/30 dev veth-p1p2" \
"sudo ip netns exec P1 ip link set veth-p1p2 up" \
"sudo ip netns exec P2 ip addr add 192.168.1.14/30 dev veth-p2p1" \
"sudo ip netns exec P2 ip link set veth-p2p1 up" \
"" \
"sudo ip link add veth-p2p3 type veth peer name veth-p3p2" \
"sudo ip link set veth-p2p3 netns P2" \
"sudo ip link set veth-p3p2 netns P3" \
"sudo ip netns exec P2 ip addr add 192.168.1.21/30 dev veth-p2p3" \
"sudo ip netns exec P2 ip link set veth-p2p3 up" \
"sudo ip netns exec P3 ip addr add 192.168.1.22/30 dev veth-p3p2" \
"sudo ip netns exec P3 ip link set veth-p3p2 up" \
"" \
"sudo ip link add veth-p1p3 type veth peer name veth-p3p1" \
"sudo ip link set veth-p1p3 netns P1" \
"sudo ip link set veth-p3p1 netns P3" \
"sudo ip netns exec P1 ip addr add 192.168.1.17/30 dev veth-p1p3" \
"sudo ip netns exec P1 ip link set veth-p1p3 up" \
"sudo ip netns exec P3 ip addr add 192.168.1.18/30 dev veth-p3p1" \
"sudo ip netns exec P3 ip link set veth-p3p1 up" \
"\`\`\`" \
"" \
"### Paso 4: Configurar redes locales" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-pe1lan type veth peer name veth-lanpe1" \
"sudo ip link set veth-pe1lan netns PE1" \
"sudo ip netns exec PE1 ip addr add 10.0.0.1/24 dev veth-pe1lan" \
"sudo ip netns exec PE1 ip link set veth-pe1lan up" \
"" \
"sudo ip link add veth-pe2lan type veth peer name veth-lanpe2" \
"sudo ip link set veth-pe2lan netns PE2" \
"sudo ip netns exec PE2 ip addr add 10.1.0.1/24 dev veth-pe2lan" \
"sudo ip netns exec PE2 ip link set veth-pe2lan up" \
"" \
"sudo ip link add veth-pe3lan type veth peer name veth-lanpe3" \
"sudo ip link set veth-pe3lan netns PE3" \
"sudo ip netns exec PE3 ip addr add 10.2.0.1/24 dev veth-pe3lan" \
"sudo ip netns exec PE3 ip link set veth-pe3lan up" \
"\`\`\`" \
"" \
"### Paso 5: Configurar enrutamiento" \
"" \
"\`\`\`bash" \
"sudo ip netns exec P1 ip route add 192.168.1.4/30 via 192.168.1.14" \
"sudo ip netns exec P1 ip route add 192.168.1.8/30 via 192.168.1.18" \
"sudo ip netns exec P1 ip route add 10.0.0.0/24 via 192.168.1.1" \
"sudo ip netns exec P1 ip route add 10.1.0.0/24 via 192.168.1.14" \
"sudo ip netns exec P1 ip route add 10.2.0.0/24 via 192.168.1.18" \
"" \
"sudo ip netns exec P2 ip route add 192.168.1.0/30 via 192.168.1.13" \
"sudo ip netns exec P2 ip route add 192.168.1.8/30 via 192.168.1.22" \
"sudo ip netns exec P2 ip route add 10.0.0.0/24 via 192.168.1.13" \
"sudo ip netns exec P2 ip route add 10.1.0.0/24 via 192.168.1.5" \
"sudo ip netns exec P2 ip route add 10.2.0.0/24 via 192.168.1.22" \
"" \
"sudo ip netns exec P3 ip route add 192.168.1.0/30 via 192.168.1.17" \
"sudo ip netns exec P3 ip route add 192.168.1.4/30 via 192.168.1.22" \
"sudo ip netns exec P3 ip route add 10.0.0.0/24 via 192.168.1.17" \
"sudo ip netns exec P3 ip route add 10.1.0.0/24 via 192.168.1.22" \
"sudo ip netns exec P3 ip route add 10.2.0.0/24 via 192.168.1.9" \
"\`\`\`" \
"" \
"### Paso 6: Verificar conectividad" \
"" \
"\`\`\`bash" \
"sudo ip netns exec PE1 ping -c 4 192.168.1.5" \
"sudo ip netns exec PE1 ping -c 4 10.1.0.1" \
"sudo ip netns exec PE1 ping -c 4 10.2.0.1" \
"\`\`\`" \
"" \
"## Análisis MPLS" \
"" \
"MPLS utiliza etiquetas para el reenvío. El flujo es:" \
"" \
"1. **Push**: PE1 añade etiqueta al paquete." \
"2. **Swap**: P routers intercambian etiquetas." \
"3. **Pop**: PE3 elimina etiqueta y entrega." \
"" \
"## Comparación MPLS vs SD-WAN" \
"" \
"| Característica | MPLS | SD-WAN |" \
"|----------------|------|--------|" \
"| Control | Distribuido | Centralizado |" \
"| Transporte | Circuitos privados | Múltiples enlaces |" \
"| QoS | Garantizada | Best-effort |" \
"| Costo | Alto | Bajo |" \
"| Agilidad | Baja | Alta |" \
"" \
"## Ejercicios" \
"" \
"### Ejercicio 1: Simular fallo" \
"" \
"\`\`\`bash" \
"sudo ip netns exec P1 ip link set veth-p1p2 down" \
"sudo ip netns exec PE1 ping -c 4 10.2.0.1" \
"\`\`\`" \
"" \
"### Ejercicio 2: Balanceo ECMP" \
"" \
"\`\`\`bash" \
"sudo ip netns exec P1 ip route del 10.2.0.0/24" \
"sudo ip netns exec P1 ip route add 10.2.0.0/24 via 192.168.1.18" \
"sudo ip netns exec P1 ip route add 10.2.0.0/24 via 192.168.1.14" \
"\`\`\`" \
"" \
"## Conceptos clave" \
"" \
"| Concepto | Aplicación |" \
"|----------|------------|" \
"| MPLS | Backbone con etiquetas |" \
"| SD-WAN | Optimización multi-enlace |" \
"| Backbone | Red troncal con P y PE |" \
"| Peering | Intercambio directo entre AS |" \
"" \
"## Conclusiones" \
"" \
"MPLS proporciona QoS garantizada. SD-WAN ofrece flexibilidad y reducción de costos. Las arquitecturas híbridas aprovechan lo mejor de ambos mundos." \
"" \
"---" \
"" \
"**¡Laboratorio 10 completado!** Continúa con el **Laboratorio 11**." \
> "$LAB_DIR/index.md"

if ! grep -q "10 - Infraestructura WAN" "$PROJECT_DIR/mkdocs.yml"; then
    sed -i '/09 - VPN y Tunelización/a \      - '\''10 - Infraestructura WAN y Core'\'': '\''labs/lab-10/index.md'\''' "$PROJECT_DIR/mkdocs.yml"
fi

echo "✅ Laboratorio 10 creado"
