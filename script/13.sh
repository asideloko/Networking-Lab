#!/bin/bash
# create_lab13.sh – Monitoreo y Diagnóstico de Redes

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml"
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-13"
mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

echo "📁 Creando laboratorio 13 en $LAB_DIR"

printf '%s\n' \
"# Laboratorio 13 – Monitoreo y Diagnóstico de Redes" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ha implementado su infraestructura de red completa con arquitectura moderna (Laboratorio 12). Ahora el equipo de operaciones necesita establecer un sistema de monitoreo y diagnóstico que permita supervisar el estado de la red, detectar anomalías y resolver incidentes de manera eficiente." \
"" \
"## Topología" \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    MON[Servidor Monitoreo 10.0.0.100]" \
"    SIEM[SIEM Server 10.0.0.200]" \
"    R1[Router Core 10.0.0.1]" \
"    APP[Servidor App 10.0.0.10]" \
"    DB[Servidor DB 10.0.0.20]" \
"    VPC[VPC AWS 10.100.0.0/16]" \
"    EC2[EC2 Server 10.100.1.10]" \
"    MON --- R1" \
"    SIEM --- R1" \
"    APP --- R1" \
"    DB --- R1" \
"    R1 --- VPC" \
"    EC2 --- VPC" \
"    R1 --- Internet" \
"\`\`\`" \
"" \
"**Direccionamiento:**" \
"" \
"| Dispositivo | Interfaz | Dirección IP | Rol |" \
"|-------------|----------|--------------|-----|" \
"| Router Core | eth0 (LAN) | 10.0.0.1/24 | Gateway |" \
"| Servidor App | - | 10.0.0.10/24 | Aplicación |" \
"| Servidor DB | - | 10.0.0.20/24 | Base de datos |" \
"| Servidor Monitoreo | - | 10.0.0.100/24 | NOC |" \
"| SIEM Server | - | 10.0.0.200/24 | Logs |" \
"| EC2 Server | - | 10.100.1.10/24 | Cloud |" \
"" \
"## Construcción de la red" \
"" \
"### Paso 1: Verificar infraestructura existente" \
"" \
"\`\`\`bash" \
"sudo ip netns list" \
"sudo ip netns exec OnPremise ping -c 2 10.100.1.10" \
"\`\`\`" \
"" \
"### Paso 2: Crear servidores de monitoreo" \
"" \
"\`\`\`bash" \
"sudo ip netns add NOC" \
"sudo ip netns add SIEM" \
"\`\`\`" \
"" \
"### Paso 3: Conectar servidores de monitoreo" \
"" \
"\`\`\`bash" \
"sudo ip link add veth-noc type veth peer name veth-core-noc" \
"sudo ip link set veth-noc netns NOC" \
"sudo ip link set veth-core-noc netns OnPremise" \
"sudo ip netns exec NOC ip addr add 10.0.0.100/24 dev veth-noc" \
"sudo ip netns exec NOC ip link set veth-noc up" \
"sudo ip netns exec NOC ip route add default via 10.0.0.1" \
"sudo ip netns exec OnPremise ip link set veth-core-noc up" \
"" \
"sudo ip link add veth-siem type veth peer name veth-core-siem" \
"sudo ip link set veth-siem netns SIEM" \
"sudo ip link set veth-core-siem netns OnPremise" \
"sudo ip netns exec SIEM ip addr add 10.0.0.200/24 dev veth-siem" \
"sudo ip netns exec SIEM ip link set veth-siem up" \
"sudo ip netns exec SIEM ip route add default via 10.0.0.1" \
"sudo ip netns exec OnPremise ip link set veth-core-siem up" \
"\`\`\`" \
"" \
"### Paso 4: Herramientas básicas de diagnóstico" \
"" \
"\`\`\`bash" \
"sudo ip netns exec NOC ping -c 4 10.0.0.10" \
"sudo ip netns exec NOC ping -c 4 10.100.1.10" \
"sudo ip netns exec NOC ping -c 4 8.8.8.8" \
"sudo ip netns exec NOC traceroute -n 10.100.1.10" \
"sudo ip netns exec NOC traceroute -n 8.8.8.8" \
"sudo ip netns exec NOC nslookup google.com" \
"\`\`\`" \
"" \
"### Paso 5: MTR" \
"" \
"\`\`\`bash" \
"sudo apt-get install -y mtr" \
"sudo ip netns exec NOC mtr -n -r -c 10 8.8.8.8" \
"\`\`\`" \
"" \
"### Paso 6: Captura de tráfico con tcpdump" \
"" \
"\`\`\`bash" \
"sudo ip netns exec NOC tcpdump -i veth-noc -c 10 -n" \
"sudo ip netns exec NOC tcpdump -i veth-noc -n host 10.0.0.10 and port 80" \
"sudo ip netns exec NOC tcpdump -i veth-noc -w /tmp/captura.pcap -c 100" \
"sudo ip netns exec NOC tcpdump -r /tmp/captura.pcap -n" \
"\`\`\`" \
"" \
"### Paso 7: Análisis de rendimiento con iperf3" \
"" \
"\`\`\`bash" \
"sudo ip netns exec AppServer iperf3 -s -D" \
"sudo ip netns exec NOC iperf3 -c 10.0.0.10" \
"sudo ip netns exec NOC iperf3 -c 10.0.0.10 -u -b 100M -t 10" \
"\`\`\`" \
"" \
"### Paso 8: SIEM Básico con rsyslog" \
"" \
"\`\`\`bash" \
"sudo ip netns exec SIEM apt-get update" \
"sudo ip netns exec SIEM apt-get install -y rsyslog" \
"sudo ip netns exec SIEM cat > /etc/rsyslog.conf << 'EOF'" \
"module(load=\"imtcp\")" \
"input(type=\"imtcp\" port=\"514\")" \
"template(name=\"RemoteLogs\" type=\"string\" string=\"%HOSTNAME% %syslogtag% %msg%\n\")" \
"*.* /var/log/remote.log;RemoteLogs" \
"EOF" \
"sudo ip netns exec SIEM systemctl restart rsyslog" \
"sudo ip netns exec NOC echo '*.* @10.0.0.200:514' >> /etc/rsyslog.conf" \
"sudo ip netns exec NOC systemctl restart rsyslog" \
"sudo ip netns exec AppServer echo '*.* @10.0.0.200:514' >> /etc/rsyslog.conf" \
"sudo ip netns exec AppServer systemctl restart rsyslog" \
"sudo ip netns exec SIEM tail -f /var/log/remote.log" \
"\`\`\`" \
"" \
"## Ejercicios" \
"" \
"### Ejercicio 1: Analizar captura Wireshark" \
"" \
"\`\`\`bash" \
"sudo ip netns exec NOC curl -v http://10.0.0.10" \
"sudo ip netns exec NOC tcpdump -i veth-noc -w /tmp/http.pcap -c 50" \
"sudo ip netns exec NOC tshark -r /tmp/http.pcap -Y \"http\"" \
"\`\`\`" \
"" \
"### Ejercicio 2: Monitoreo bidireccional" \
"" \
"\`\`\`bash" \
"sudo ip netns exec NOC iperf3 -c 10.0.0.10 --bidir" \
"\`\`\`" \
"" \
"### Ejercicio 3: Simular fallo de MTU" \
"" \
"\`\`\`bash" \
"sudo ip netns exec AppServer ip link set veth-app-op mtu 1400" \
"sudo ip netns exec NOC ping -M do -s 1450 10.0.0.10" \
"\`\`\`" \
"" \
"## Errores comunes" \
"" \
"| Error | Solución |" \
"|-------|----------|" \
"| Ping falla | Verificar firewall |" \
"| Captura vacía | Verificar interfaz |" \
"| iperf3 no conecta | Ejecutar servidor |" \
"" \
"## Conceptos clave" \
"" \
"| Concepto | Aplicación |" \
"|----------|------------|" \
"| Ping | Conectividad básica |" \
"| Traceroute | Identificar saltos |" \
"| MTR | Análisis continuo |" \
"| tcpdump | Captura de tráfico |" \
"| iperf3 | Medición de ancho de banda |" \
"| SIEM | Centralización de logs |" \
"" \
"## Conclusiones" \
"" \
"Las herramientas de monitoreo y diagnóstico permiten detectar y resolver incidentes de red de manera rápida y estructurada." \
"" \
"---" \
"" \
"**¡Laboratorio 13 completado!** Continúa con el **Laboratorio 14**." \
> "$LAB_DIR/index.md"

if ! grep -q "13 - Monitoreo" "$PROJECT_DIR/mkdocs.yml"; then
    sed -i '/12 - Arquitecturas Modernas de Red/a \      - '\''13 - Monitoreo y Diagnóstico de Redes'\'': '\''labs/lab-13/index.md'\''' "$PROJECT_DIR/mkdocs.yml"
fi

echo "✅ Laboratorio 13 creado"
