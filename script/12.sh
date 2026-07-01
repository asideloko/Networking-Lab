#!/bin/bash
# create_lab12.sh – Arquitecturas Modernas de Red

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml"
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-12"
mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

echo "📁 Creando laboratorio 12 en $LAB_DIR"

printf '%s\n' \
"# Laboratorio 12 – Arquitecturas Modernas de Red" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ha implementado su arquitectura empresarial tradicional (Laboratorio 11). Ahora necesita modernizar su infraestructura para adaptarse a los nuevos modelos de trabajo híbrido." \
"" \
"## Topología" \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    R1[Router Core]" \
"    APP[Servidor App]" \
"    DB[Servidor DB]" \
"    VPC[VPC AWS]" \
"    EC2[EC2 Server]" \
"    ZTNA[ZTNA Broker]" \
"    IDP[Identity Provider]" \
"    SASE[SASE PoP]" \
"    USER1[Usuario Remoto 1]" \
"    USER2[Usuario Remoto 2]" \
"    USER1 --- ZTNA" \
"    USER2 --- ZTNA" \
"    ZTNA --- IDP" \
"    ZTNA --- APP" \
"    ZTNA --- EC2" \
"    R1 --- VPC" \
"    R1 --- APP" \
"    R1 --- DB" \
"    SASE --- R1" \
"    SASE --- VPC" \
"    R1 --- Internet" \
"    VPC --- Internet" \
"\`\`\`" \
"" \
"**Direccionamiento:**" \
"" \
"| Dispositivo | Interfaz | Dirección IP | Ubicación |" \
"|-------------|----------|--------------|-----------|" \
"| Router Core | eth0 (LAN) | 10.0.0.1/24 | OnPremise |" \
"| Servidor App | - | 10.0.0.10/24 | OnPremise |" \
"| Servidor DB | - | 10.0.0.20/24 | OnPremise |" \
"| VPC Gateway | - | 10.100.0.1/16 | AWS Cloud |" \
"| EC2 Server | - | 10.100.1.10/24 | AWS Cloud |" \
"| ZTNA Broker | - | 203.0.113.10 | Proxy Cloud |" \
"| SASE PoP | - | 198.51.100.10 | SASE Cloud |" \
"" \
"## Construcción" \
"" \
"### Paso 1: Crear namespaces" \
"" \
"\`\`\`bash" \
"sudo ip netns add OnPremise" \
"sudo ip netns add AppServer" \
"sudo ip netns add DBServer" \
"sudo ip netns add AWS_VPC" \
"sudo ip netns add EC2_Server" \
"sudo ip netns add ZTNA_Broker" \
"sudo ip netns add IDP" \
"sudo ip netns add SASE_PoP" \
"sudo ip netns add User1" \
"sudo ip netns add User2" \
"\`\`\`" \
"" \
"### Paso 2: Conectar OnPremise" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-op-app type veth peer name veth-app-op" \
"sudo ip link set veth-op-app netns OnPremise" \
"sudo ip link set veth-app-op netns AppServer" \
"sudo ip netns exec OnPremise ip addr add 10.0.0.1/24 dev veth-op-app" \
"sudo ip netns exec OnPremise ip link set veth-op-app up" \
"sudo ip netns exec AppServer ip addr add 10.0.0.10/24 dev veth-app-op" \
"sudo ip netns exec AppServer ip link set veth-app-op up" \
"sudo ip netns exec AppServer ip route add default via 10.0.0.1" \
"" \
"sudo ip link add veth-op-db type veth peer name veth-db-op" \
"sudo ip link set veth-op-db netns OnPremise" \
"sudo ip link set veth-db-op netns DBServer" \
"sudo ip netns exec OnPremise ip addr add 10.0.0.2/24 dev veth-op-db" \
"sudo ip netns exec OnPremise ip link set veth-op-db up" \
"sudo ip netns exec DBServer ip addr add 10.0.0.20/24 dev veth-db-op" \
"sudo ip netns exec DBServer ip link set veth-db-op up" \
"sudo ip netns exec DBServer ip route add default via 10.0.0.1" \
"\`\`\`" \
"" \
"### Paso 3: Conectar Cloud" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-vpc-ec2 type veth peer name veth-ec2-vpc" \
"sudo ip link set veth-vpc-ec2 netns AWS_VPC" \
"sudo ip link set veth-ec2-vpc netns EC2_Server" \
"sudo ip netns exec AWS_VPC ip addr add 10.100.0.1/16 dev veth-vpc-ec2" \
"sudo ip netns exec AWS_VPC ip link set veth-vpc-ec2 up" \
"sudo ip netns exec EC2_Server ip addr add 10.100.1.10/24 dev veth-ec2-vpc" \
"sudo ip netns exec EC2_Server ip link set veth-ec2-vpc up" \
"sudo ip netns exec EC2_Server ip route add default via 10.100.0.1" \
"\`\`\`" \
"" \
"### Paso 4: Conectar OnPremise a Cloud" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-op-vpc type veth peer name veth-vpc-op" \
"sudo ip link set veth-op-vpc netns OnPremise" \
"sudo ip link set veth-vpc-op netns AWS_VPC" \
"sudo ip netns exec OnPremise ip addr add 192.168.100.1/30 dev veth-op-vpc" \
"sudo ip netns exec OnPremise ip link set veth-op-vpc up" \
"sudo ip netns exec AWS_VPC ip addr add 192.168.100.2/30 dev veth-vpc-op" \
"sudo ip netns exec AWS_VPC ip link set veth-vpc-op up" \
"sudo ip netns exec OnPremise ip route add 10.100.0.0/16 via 192.168.100.2" \
"sudo ip netns exec AWS_VPC ip route add 10.0.0.0/24 via 192.168.100.1" \
"\`\`\`" \
"" \
"### Paso 5: Configurar Zero Trust (ZTNA)" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-broker-op type veth peer name veth-op-broker" \
"sudo ip link set veth-broker-op netns ZTNA_Broker" \
"sudo ip link set veth-op-broker netns OnPremise" \
"sudo ip netns exec ZTNA_Broker ip addr add 203.0.113.10/32 dev veth-broker-op" \
"sudo ip netns exec ZTNA_Broker ip link set veth-broker-op up" \
"sudo ip netns exec OnPremise ip route add 203.0.113.10/32 dev veth-op-broker" \
"" \
"sudo ip link add veth-broker-cloud type veth peer name veth-cloud-broker" \
"sudo ip link set veth-broker-cloud netns ZTNA_Broker" \
"sudo ip link set veth-cloud-broker netns AWS_VPC" \
"sudo ip netns exec ZTNA_Broker ip addr add 203.0.113.20/32 dev veth-broker-cloud" \
"sudo ip netns exec ZTNA_Broker ip link set veth-broker-cloud up" \
"sudo ip netns exec AWS_VPC ip route add 203.0.113.10/32 via 203.0.113.20" \
"" \
"sudo ip link add veth-broker-idp type veth peer name veth-idp-broker" \
"sudo ip link set veth-broker-idp netns ZTNA_Broker" \
"sudo ip link set veth-idp-broker netns IDP" \
"sudo ip netns exec ZTNA_Broker ip addr add 192.168.200.1/30 dev veth-broker-idp" \
"sudo ip netns exec ZTNA_Broker ip link set veth-broker-idp up" \
"sudo ip netns exec IDP ip addr add 192.168.200.2/30 dev veth-idp-broker" \
"sudo ip netns exec IDP ip link set veth-idp-broker up" \
"\`\`\`" \
"" \
"### Paso 6: Configurar Usuarios Remotos" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-user1 type veth peer name veth-broker-u1" \
"sudo ip link set veth-user1 netns User1" \
"sudo ip link set veth-broker-u1 netns ZTNA_Broker" \
"sudo ip netns exec User1 ip addr add 10.8.0.2/24 dev veth-user1" \
"sudo ip netns exec User1 ip link set veth-user1 up" \
"sudo ip netns exec User1 ip route add default via 10.8.0.1" \
"sudo ip netns exec ZTNA_Broker ip addr add 10.8.0.1/24 dev veth-broker-u1" \
"sudo ip netns exec ZTNA_Broker ip link set veth-broker-u1 up" \
"" \
"sudo ip link add veth-user2 type veth peer name veth-broker-u2" \
"sudo ip link set veth-user2 netns User2" \
"sudo ip link set veth-broker-u2 netns ZTNA_Broker" \
"sudo ip netns exec User2 ip addr add 10.8.0.3/24 dev veth-user2" \
"sudo ip netns exec User2 ip link set veth-user2 up" \
"sudo ip netns exec User2 ip route add default via 10.8.0.1" \
"sudo ip netns exec ZTNA_Broker ip addr add 10.8.0.1/24 dev veth-broker-u2" \
"sudo ip netns exec ZTNA_Broker ip link set veth-broker-u2 up" \
"\`\`\`" \
"" \
"### Paso 7: Configurar SASE" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-sase-op type veth peer name veth-op-sase" \
"sudo ip link set veth-sase-op netns SASE_PoP" \
"sudo ip link set veth-op-sase netns OnPremise" \
"sudo ip netns exec SASE_PoP ip addr add 198.51.100.10/32 dev veth-sase-op" \
"sudo ip netns exec SASE_PoP ip link set veth-sase-op up" \
"sudo ip netns exec OnPremise ip route add 198.51.100.10/32 dev veth-op-sase" \
"" \
"sudo ip link add veth-sase-cloud type veth peer name veth-cloud-sase" \
"sudo ip link set veth-sase-cloud netns SASE_PoP" \
"sudo ip link set veth-cloud-sase netns AWS_VPC" \
"sudo ip netns exec SASE_PoP ip addr add 198.51.100.20/32 dev veth-sase-cloud" \
"sudo ip netns exec SASE_PoP ip link set veth-sase-cloud up" \
"sudo ip netns exec AWS_VPC ip route add 198.51.100.10/32 via 198.51.100.20" \
"\`\`\`" \
"" \
"### Paso 8: Microsegmentación" \
"" \
"\`\`\`bash" \
"sudo ip netns exec AppServer iptables -A OUTPUT -d 10.0.0.20 -p tcp --dport 3306 -j ACCEPT" \
"sudo ip netns exec AppServer iptables -A OUTPUT -j DROP" \
"sudo ip netns exec DBServer iptables -A INPUT -s 10.0.0.10 -p tcp --dport 3306 -j ACCEPT" \
"sudo ip netns exec DBServer iptables -A INPUT -j DROP" \
"sudo ip netns exec EC2_Server iptables -A OUTPUT -d 10.100.2.10 -p tcp --dport 5432 -j ACCEPT" \
"sudo ip netns exec EC2_Server iptables -A OUTPUT -j DROP" \
"\`\`\`" \
"" \
"### Paso 9: Verificar" \
"" \
"\`\`\`bash" \
"sudo ip netns exec User1 ping -c 4 10.0.0.10" \
"sudo ip netns exec User1 ping -c 4 10.100.1.10" \
"\`\`\`" \
"" \
"## Análisis" \
"" \
"**Cloud Networking:** VPC con conectividad híbrida." \
"" \
"**Zero Trust:** Verificación continua, mínimo privilegio." \
"" \
"**ZTNA:** Acceso remoto seguro por aplicación." \
"" \
"**SASE:** SD-WAN + SWG + CASB integrados." \
"" \
"**Microsegmentación:** Políticas granulares App→DB, EC2→RDS." \
"" \
"## Ejercicios" \
"" \
"### Ejercicio 1: Agregar usuario remoto" \
"" \
"Configura un tercer usuario en ZTNA." \
"" \
"### Ejercicio 2: Definir políticas SASE" \
"" \
"Define políticas de seguridad para el tráfico entre usuarios y aplicaciones." \
"" \
"## Conceptos clave" \
"" \
"| Concepto | Aplicación |" \
"|----------|------------|" \
"| Cloud Networking | VPC, conectividad híbrida |" \
"| Zero Trust | Verificación continua |" \
"| ZTNA | Acceso remoto por aplicación |" \
"| SASE | SD-WAN + SWG + CASB |" \
"| Microsegmentación | Políticas granulares |" \
"" \
"## Conclusiones" \
"" \
"Las arquitecturas modernas combinan Cloud Networking, Zero Trust, ZTNA, SASE y microsegmentación para adaptarse a entornos híbridos con agilidad y seguridad." \
"" \
"---" \
"" \
"**¡Laboratorio 12 completado!**" \
> "$LAB_DIR/index.md"

if ! grep -q "12 - Arquitecturas Modernas" "$PROJECT_DIR/mkdocs.yml"; then
    sed -i '/11 - Arquitectura de Red Empresarial/a \      - '\''12 - Arquitecturas Modernas de Red'\'': '\''labs/lab-12/index.md'\''' "$PROJECT_DIR/mkdocs.yml"
fi

echo "✅ Laboratorio 12 creado"
