#!/bin/bash
# create_lab15.sh – Implementación Práctica Integral

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml"
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-15"
mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

echo "📁 Creando laboratorio 15 en $LAB_DIR"

printf '%s\n' \
"# Laboratorio 15 – Implementación Práctica Integral" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ha completado todos los laboratorios anteriores. Ahora debe **integrar todos los conceptos** en una implementación práctica completa que sirva como infraestructura de producción funcional." \
"" \
"## Topología" \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    PC1[PC1 192.168.1.10]" \
"    PC2[PC2 192.168.1.20]" \
"    SW[Switch]" \
"    R[Router Linux]" \
"    WAN[Internet]" \
"    PC1 --- SW" \
"    PC2 --- SW" \
"    SW --- R" \
"    R --- WAN" \
"\`\`\`" \
"" \
"## 15.1 Configuración de Red Básica" \
"" \
"### Configurar Router Linux" \
"" \
"\`\`\`bash" \
"ip addr add 192.168.1.1/24 dev eth1" \
"ip link set eth1 up" \
"sysctl -w net.ipv4.ip_forward=1" \
"iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" \
"\`\`\`" \
"" \
"### Configurar PC1" \
"" \
"\`\`\`bash" \
"ip addr add 192.168.1.10/24 dev eth0" \
"ip link set eth0 up" \
"ip route add default via 192.168.1.1" \
"echo 'nameserver 8.8.8.8' > /etc/resolv.conf" \
"\`\`\`" \
"" \
"### Configurar PC2" \
"" \
"\`\`\`bash" \
"ip addr add 192.168.1.20/24 dev eth0" \
"ip link set eth0 up" \
"ip route add default via 192.168.1.1" \
"\`\`\`" \
"" \
"### Verificar" \
"" \
"\`\`\`bash" \
"ping -c 3 192.168.1.20" \
"ping -c 3 192.168.1.1" \
"ping -c 3 8.8.8.8" \
"nslookup google.com" \
"\`\`\`" \
"" \
"## 15.2 Subnetting Aplicado" \
"" \
"**Bloque disponible:** 10.0.0.0/22" \
"" \
"| Departamento | Hosts | Subred | Máscara | Rango Útil |" \
"|--------------|-------|--------|---------|------------|" \
"| Servidores | 200 | 10.0.0.0/24 | /24 | 10.0.0.1 - 10.0.0.254 |" \
"| Finanzas | 100 | 10.0.1.0/25 | /25 | 10.0.1.1 - 10.0.1.126 |" \
"| Ventas | 50 | 10.0.1.128/26 | /26 | 10.0.1.129 - 10.0.1.190 |" \
"| Gestión | 10 | 10.0.1.192/28 | /28 | 10.0.1.193 - 10.0.1.206 |" \
"| Enlace R1-R2 | 2 | 10.0.1.208/30 | /30 | 10.0.1.209 - 10.0.1.210 |" \
"" \
"\`\`\`bash" \
"ip addr add 10.0.0.1/24 dev eth1" \
"ip addr add 10.0.1.1/25 dev eth2" \
"ip addr add 10.0.1.129/26 dev eth3" \
"ip addr add 10.0.1.209/30 dev eth4" \
"\`\`\`" \
"" \
"## 15.3 VLAN" \
"" \
"### Configurar Open vSwitch" \
"" \
"\`\`\`bash" \
"apt install openvswitch-switch" \
"ovs-vsctl add-br ovs-bridge" \
"ovs-vsctl add-port ovs-bridge eth1 tag=10" \
"ovs-vsctl add-port ovs-bridge eth2 tag=20" \
"ovs-vsctl add-port ovs-bridge eth3 tag=30" \
"ovs-vsctl add-port ovs-bridge eth4 trunks=10,20,30" \
"\`\`\`" \
"" \
"### Router-on-a-Stick" \
"" \
"\`\`\`bash" \
"ip link add link eth0 name eth0.10 type vlan id 10" \
"ip addr add 10.0.0.1/24 dev eth0.10" \
"ip link set eth0.10 up" \
"ip link add link eth0 name eth0.20 type vlan id 20" \
"ip addr add 10.0.1.1/25 dev eth0.20" \
"ip link set eth0.20 up" \
"ip link add link eth0 name eth0.30 type vlan id 30" \
"ip addr add 10.0.1.129/26 dev eth0.30" \
"ip link set eth0.30 up" \
"\`\`\`" \
"" \
"## 15.4 Routing entre Redes" \
"" \
"### Rutas estáticas" \
"" \
"\`\`\`bash" \
"ip route add 10.0.1.0/25 via 10.0.1.209 dev eth4" \
"ip route add default via 203.0.113.2 dev eth0" \
"ip route show" \
"\`\`\`" \
"" \
"### OSPF con FRRouting" \
"" \
"\`\`\`bash" \
"cat > /etc/frr/frr.conf << 'EOF'" \
"router ospf" \
" router-id 1.1.1.1" \
" network 10.0.0.0/24 area 0" \
" network 10.0.1.0/25 area 0" \
" network 10.0.1.128/26 area 0" \
" network 10.0.1.208/30 area 0" \
" passive-interface eth1" \
" passive-interface eth2" \
" passive-interface eth3" \
"EOF" \
"systemctl restart frr" \
"show ip ospf neighbor" \
"show ip route ospf" \
"\`\`\`" \
"" \
"## 15.5 Firewall" \
"" \
"### nftables" \
"" \
"\`\`\`bash" \
"cat > /etc/nftables.conf << 'EOF'" \
"table inet firewall {" \
"    chain input {" \
"        type filter hook input priority 0; policy drop;" \
"        iif lo accept" \
"        ct state established,related accept" \
"        iifname eth1 tcp dport 22 accept" \
"        ip protocol icmp limit rate 10/second accept" \
"    }" \
"    chain forward {" \
"        type filter hook forward priority 0; policy drop;" \
"        ct state established,related accept" \
"        iifname { eth1, eth2, eth3 } oifname eth0 accept" \
"        iifname eth0 oifname eth_dmz tcp dport { 80,443,25 } accept" \
"        iifname { eth1, eth2, eth3 } oifname eth_dmz accept" \
"    }" \
"}" \
"table ip nat {" \
"    chain postrouting {" \
"        type nat hook postrouting priority 100;" \
"        iifname { eth1, eth2, eth3 } oifname eth0 masquerade" \
"    }" \
"}" \
"EOF" \
"nft -f /etc/nftables.conf" \
"systemctl enable nftables" \
"\`\`\`" \
"" \
"### Verificar" \
"" \
"\`\`\`bash" \
"curl ifconfig.me" \
"curl http://203.0.113.10" \
"nft list ruleset" \
"\`\`\`" \
"" \
"## 15.6 Red Parcial Integrada" \
"" \
"### DHCP con dnsmasq" \
"" \
"\`\`\`bash" \
"cat > /etc/dnsmasq.conf << 'EOF'" \
"dhcp-range=eth0.10,10.0.0.100,10.0.0.200,255.255.255.0,24h" \
"dhcp-option=eth0.10,3,10.0.0.1" \
"dhcp-option=eth0.10,6,8.8.8.8" \
"dhcp-range=eth0.20,10.0.1.10,10.0.1.120,255.255.255.128,24h" \
"dhcp-option=eth0.20,3,10.0.1.1" \
"dhcp-option=eth0.20,6,8.8.8.8" \
"dhcp-range=eth0.30,10.0.1.130,10.0.1.190,255.255.255.192,24h" \
"dhcp-option=eth0.30,3,10.0.1.129" \
"dhcp-option=eth0.30,6,8.8.8.8" \
"EOF" \
"systemctl restart dnsmasq" \
"\`\`\`" \
"" \
"### Validar" \
"" \
"\`\`\`bash" \
"ip a" \
"ip route" \
"ping 10.0.0.1" \
"ping 8.8.8.8" \
"nslookup google.com" \
"\`\`\`" \
"" \
"## 15.7 Red Empresarial Completa" \
"" \
"### VRRP (redundancia de gateway)" \
"" \
"**Router 1 (MASTER):**" \
"\`\`\`" \
"vrrp_instance LAN10 {" \
"    state MASTER" \
"    interface eth0.10" \
"    virtual_router_id 10" \
"    priority 100" \
"    advert_int 1" \
"    authentication {" \
"        auth_type PASS" \
"        auth_pass SecurePass2024" \
"    }" \
"    virtual_ipaddress {" \
"        10.0.0.1/24" \
"    }" \
"}" \
"\`\`\`" \
"" \
"**Router 2 (BACKUP):**" \
"\`\`\`" \
"vrrp_instance LAN10 {" \
"    state BACKUP" \
"    interface eth0.10" \
"    virtual_router_id 10" \
"    priority 90" \
"    advert_int 1" \
"    authentication {" \
"        auth_type PASS" \
"        auth_pass SecurePass2024" \
"    }" \
"    virtual_ipaddress {" \
"        10.0.0.1/24" \
"    }" \
"}" \
"\`\`\`" \
"" \
"## 15.8 Troubleshooting Real" \
"" \
"### Caso: Degradación por MTU en IPsec" \
"" \
"\`\`\`bash" \
"ping -M do -s 1472 -c 2 10.10.1.100" \
"ping -M do -s 1410 -c 2 10.10.1.100" \
"sudo tcpdump -i eth0 host 10.10.1.100 and port 445 -w captura.pcap" \
"sudo iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360" \
"\`\`\`" \
"" \
"### Caso: Agotamiento de tabla ARP" \
"" \
"\`\`\`bash" \
"dmesg | grep neighbour" \
"ip neigh show | wc -l" \
"sysctl net.ipv4.neigh.default.gc_thresh3" \
"sysctl -w net.ipv4.neigh.default.gc_thresh3=8192" \
"sysctl -w net.ipv4.neigh.default.gc_thresh2=4096" \
"echo 'net.ipv4.neigh.default.gc_thresh3=8192' >> /etc/sysctl.conf" \
"echo 'net.ipv4.neigh.default.gc_thresh2=4096' >> /etc/sysctl.conf" \
"sysctl -p" \
"\`\`\`" \
"" \
"### Script de verificación ARP" \
"" \
"\`\`\`bash" \
"cat > /usr/local/bin/check_arp.sh << 'EOF'" \
"#!/bin/bash" \
"THRESHOLD=7000" \
"CURRENT=\$(ip neigh show | wc -l)" \
"if [ \$CURRENT -gt \$THRESHOLD ]; then" \
"    echo \"WARNING: ARP table usage high: \$CURRENT entries\"" \
"fi" \
"EOF" \
"chmod +x /usr/local/bin/check_arp.sh" \
"\`\`\`" \
"" \
"## Conceptos clave" \
"" \
"| Concepto | Aplicación |" \
"|----------|------------|" \
"| Configuración básica | Conectividad IP y NAT |" \
"| Subnetting | VLSM para segmentación |" \
"| VLAN | Segmentación lógica |" \
"| Routing | Rutas estáticas y OSPF |" \
"| Firewall | nftables para seguridad |" \
"| DHCP | Asignación automática de IP |" \
"| VRRP | Redundancia de gateway |" \
"| Troubleshooting | MTU y ARP |" \
"" \
"## Conclusiones" \
"" \
"Este laboratorio integra todos los conceptos vistos: direccionamiento IP, VLAN, routing, firewall, servicios y troubleshooting. La implementación práctica de una red empresarial completa requiere planificación, documentación y verificación continua." \
"" \
"---" \
"" \
"**¡Laboratorio 15 completado!** Has construido una red empresarial funcional desde cero." \
> "$LAB_DIR/index.md"

if ! grep -q "15 - Implementación" "$PROJECT_DIR/mkdocs.yml"; then
    sed -i '/14 - Herramientas Linux Avanzadas/a \      - '\''15 - Implementación Práctica Integral'\'': '\''labs/lab-15/index.md'\''' "$PROJECT_DIR/mkdocs.yml"
fi

echo "✅ Laboratorio 15 creado"
