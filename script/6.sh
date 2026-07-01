#!/bin/bash
# create_lab06.sh – Crea el Laboratorio 06 (Enrutamiento y Conectividad entre Redes)

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml. Asegúrate de ejecutar este script desde la raíz del proyecto."
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-06"
echo "📁 Creando laboratorio 06 en $LAB_DIR"

mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

printf '%s\n' \
"# Laboratorio 06 – Enrutamiento y Conectividad entre Redes" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ha implementado exitosamente su red con VLANs y Router-on-a-Stick. Ahora necesita **conectar su sede central con dos sucursales** (Sucursal A y Sucursal B) que se encuentran en ubicaciones geográficas diferentes. Cada sucursal tiene su propia red local y necesita comunicarse con la sede y entre sí." \
"" \
"El equipo de redes ha decidido implementar:" \
"" \
"1. **Rutas estáticas** iniciales para conectar las oficinas." \
"2. **OSPF** como protocolo de enrutamiento dinámico para adaptarse a cambios." \
"3. **Túneles GRE** para conectar redes no contiguas a través de Internet." \
"" \
"## Problema inicial" \
"" \
"- La sede central tiene una red con VLANs (Ventas, IT, Administración)." \
"- Las sucursales A y B tienen sus propias redes locales." \
"- No hay conectividad entre las oficinas." \
"- Se necesita enrutar el tráfico entre todas las redes." \
"" \
"## Objetivos del laboratorio" \
"" \
"1.  Comprender los principios del enrutamiento IP." \
"2.  Configurar **rutas estáticas** y la **ruta por defecto**." \
"3.  Implementar **OSPF** (Open Shortest Path First) como protocolo IGP." \
"4.  Analizar la **tabla de enrutamiento** y el proceso de **longest prefix match**." \
"5.  Configurar un **túnel GRE** para interconectar redes remotas." \
"6.  Verificar la conectividad entre todas las oficinas." \
"" \
"## Topología" \
"" \
"La topología consta de tres routers (R1, R2, R3) que representan la sede y dos sucursales." \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    subgraph Sede_Central" \
"        R1[Router 1 Sede]" \
"        LAN1[Red Sede 10.0.0.0/24]" \
"        VLAN10[VLAN 10 Ventas 10.0.10.0/24]" \
"        VLAN20[VLAN 20 IT 10.0.20.0/24]" \
"        VLAN30[VLAN 30 Admin 10.0.30.0/24]" \
"    end" \
"    subgraph Sucursal_A" \
"        R2[Router 2 Sucursal A]" \
"        LAN2[Red Sucursal A 10.0.1.0/24]" \
"    end" \
"    subgraph Sucursal_B" \
"        R3[Router 3 Sucursal B]" \
"        LAN3[Red Sucursal B 10.0.2.0/24]" \
"    end" \
"    R1 --- R2" \
"    R2 --- R3" \
"    LAN1 --- R1" \
"    VLAN10 --- R1" \
"    VLAN20 --- R1" \
"    VLAN30 --- R1" \
"    LAN2 --- R2" \
"    LAN3 --- R3" \
"\`\`\`" \
"" \
"**Direccionamiento:**" \
"" \
"| Dispositivo | Interfaz | Dirección IP |" \
"|-------------|----------|--------------|" \
"| R1 (Sede) | eth0 (LAN) | 10.0.0.1/24 |" \
"| R1 (Sede) | eth1 (R1-R2) | 192.168.1.1/30 |" \
"| R1 (Sede) | VLAN 10 | 10.0.10.1/24 |" \
"| R1 (Sede) | VLAN 20 | 10.0.20.1/24 |" \
"| R1 (Sede) | VLAN 30 | 10.0.30.1/24 |" \
"| R2 (Sucursal A) | eth0 (LAN) | 10.0.1.1/24 |" \
"| R2 (Sucursal A) | eth1 (R1-R2) | 192.168.1.2/30 |" \
"| R2 (Sucursal A) | eth2 (R2-R3) | 192.168.2.1/30 |" \
"| R3 (Sucursal B) | eth0 (LAN) | 10.0.2.1/24 |" \
"| R3 (Sucursal B) | eth1 (R2-R3) | 192.168.2.2/30 |" \
"| Cliente Sede | - | 10.0.0.10/24 |" \
"| Cliente Sucursal A | - | 10.0.1.10/24 |" \
"| Cliente Sucursal B | - | 10.0.2.10/24 |" \
"" \
"## Construcción de la red" \
"" \
"### Paso 1: Crear namespaces y enlaces" \
"" \
"Creamos tres routers y tres clientes (uno por oficina)." \
"" \
"\`\`\`bash" \
"# Routers" \
"sudo ip netns add R1" \
"sudo ip netns add R2" \
"sudo ip netns add R3" \
"" \
"# Clientes" \
"sudo ip netns add clienteSede" \
"sudo ip netns add clienteSucA" \
"sudo ip netns add clienteSucB" \
"\`\`\`" \
"" \
"### Paso 2: Conectar routers y clientes" \
"" \
"\`\`\`bash" \
"# Enlace R1 - R2" \
"sudo ip link add veth-r1r2 type veth peer name veth-r2r1" \
"sudo ip link set veth-r1r2 netns R1" \
"sudo ip link set veth-r2r1 netns R2" \
"" \
"# Enlace R2 - R3" \
"sudo ip link add veth-r2r3 type veth peer name veth-r3r2" \
"sudo ip link set veth-r2r3 netns R2" \
"sudo ip link set veth-r3r2 netns R3" \
"" \
"# Cliente Sede -> R1" \
"sudo ip link add veth-c1 type veth peer name veth-r1c" \
"sudo ip link set veth-c1 netns clienteSede" \
"sudo ip link set veth-r1c netns R1" \
"" \
"# Cliente Sucursal A -> R2" \
"sudo ip link add veth-c2 type veth peer name veth-r2c" \
"sudo ip link set veth-c2 netns clienteSucA" \
"sudo ip link set veth-r2c netns R2" \
"" \
"# Cliente Sucursal B -> R3" \
"sudo ip link add veth-c3 type veth peer name veth-r3c" \
"sudo ip link set veth-c3 netns clienteSucB" \
"sudo ip link set veth-r3c netns R3" \
"\`\`\`" \
"" \
"### Paso 3: Asignar direcciones IP y activar interfaces" \
"" \
"**Router R1 (Sede):**" \
"" \
"\`\`\`bash" \
"sudo ip netns exec R1 ip addr add 10.0.0.1/24 dev veth-r1c" \
"sudo ip netns exec R1 ip addr add 192.168.1.1/30 dev veth-r1r2" \
"sudo ip netns exec R1 ip link set veth-r1c up" \
"sudo ip netns exec R1 ip link set veth-r1r2 up" \
"sudo ip netns exec R1 ip link set lo up" \
"\`\`\`" \
"" \
"**Router R2 (Sucursal A):**" \
"" \
"\`\`\`bash" \
"sudo ip netns exec R2 ip addr add 10.0.1.1/24 dev veth-r2c" \
"sudo ip netns exec R2 ip addr add 192.168.1.2/30 dev veth-r2r1" \
"sudo ip netns exec R2 ip addr add 192.168.2.1/30 dev veth-r2r3" \
"sudo ip netns exec R2 ip link set veth-r2c up" \
"sudo ip netns exec R2 ip link set veth-r2r1 up" \
"sudo ip netns exec R2 ip link set veth-r2r3 up" \
"sudo ip netns exec R2 ip link set lo up" \
"\`\`\`" \
"" \
"**Router R3 (Sucursal B):**" \
"" \
"\`\`\`bash" \
"sudo ip netns exec R3 ip addr add 10.0.2.1/24 dev veth-r3c" \
"sudo ip netns exec R3 ip addr add 192.168.2.2/30 dev veth-r3r2" \
"sudo ip netns exec R3 ip link set veth-r3c up" \
"sudo ip netns exec R3 ip link set veth-r3r2 up" \
"sudo ip netns exec R3 ip link set lo up" \
"\`\`\`" \
"" \
"**Clientes:**" \
"" \
"\`\`\`bash" \
"# Sede" \
"sudo ip netns exec clienteSede ip addr add 10.0.0.10/24 dev veth-c1" \
"sudo ip netns exec clienteSede ip link set veth-c1 up" \
"sudo ip netns exec clienteSede ip link set lo up" \
"" \
"# Sucursal A" \
"sudo ip netns exec clienteSucA ip addr add 10.0.1.10/24 dev veth-c2" \
"sudo ip netns exec clienteSucA ip link set veth-c2 up" \
"sudo ip netns exec clienteSucA ip link set lo up" \
"" \
"# Sucursal B" \
"sudo ip netns exec clienteSucB ip addr add 10.0.2.10/24 dev veth-c3" \
"sudo ip netns exec clienteSucB ip link set veth-c3 up" \
"sudo ip netns exec clienteSucB ip link set lo up" \
"\`\`\`" \
"" \
"### Paso 4: Configurar rutas estáticas" \
"" \
"**En R1 (Sede):**" \
"" \
"\`\`\`bash" \
"sudo ip netns exec R1 ip route add 10.0.1.0/24 via 192.168.1.2" \
"sudo ip netns exec R1 ip route add 10.0.2.0/24 via 192.168.1.2" \
"\`\`\`" \
"" \
"**En R2 (Sucursal A):**" \
"" \
"\`\`\`bash" \
"sudo ip netns exec R2 ip route add 10.0.0.0/24 via 192.168.1.1" \
"sudo ip netns exec R2 ip route add 10.0.2.0/24 via 192.168.2.2" \
"\`\`\`" \
"" \
"**En R3 (Sucursal B):**" \
"" \
"\`\`\`bash" \
"sudo ip netns exec R3 ip route add 10.0.0.0/24 via 192.168.2.1" \
"sudo ip netns exec R3 ip route add 10.0.1.0/24 via 192.168.2.1" \
"\`\`\`" \
"" \
"**Ruta por defecto en clientes:**" \
"" \
"\`\`\`bash" \
"sudo ip netns exec clienteSede ip route add default via 10.0.0.1" \
"sudo ip netns exec clienteSucA ip route add default via 10.0.1.1" \
"sudo ip netns exec clienteSucB ip route add default via 10.0.2.1" \
"\`\`\`" \
"" \
"### Paso 5: Verificar conectividad" \
"" \
"\`\`\`bash" \
"# Desde Sede a Sucursal A" \
"sudo ip netns exec clienteSede ping -c 4 10.0.1.10" \
"" \
"# Desde Sucursal A a Sucursal B" \
"sudo ip netns exec clienteSucA ping -c 4 10.0.2.10" \
"" \
"# Ver tabla de enrutamiento en R1" \
"sudo ip netns exec R1 ip route show" \
"\`\`\`" \
"" \
"**Salida esperada:** 0% de pérdida en todos los pings." \
"" \
"### Paso 6: Agregar redundancia (enlace R1-R3)" \
"" \
"Para demostrar la ventaja de tener rutas alternativas:" \
"" \
"\`\`\`bash" \
"# Crear enlace R1-R3" \
"sudo ip link add veth-r1r3 type veth peer name veth-r3r1" \
"sudo ip link set veth-r1r3 netns R1" \
"sudo ip link set veth-r3r1 netns R3" \
"sudo ip netns exec R1 ip addr add 192.168.3.1/30 dev veth-r1r3" \
"sudo ip netns exec R1 ip link set veth-r1r3 up" \
"sudo ip netns exec R3 ip addr add 192.168.3.2/30 dev veth-r3r1" \
"sudo ip netns exec R3 ip link set veth-r3r1 up" \
"" \
"# Agregar rutas estáticas redundantes" \
"sudo ip netns exec R1 ip route add 10.0.2.0/24 via 192.168.3.2" \
"sudo ip netns exec R3 ip route add 10.0.0.0/24 via 192.168.3.1" \
"\`\`\`" \
"" \
"### Paso 7: Simular fallo y verificar redundancia" \
"" \
"\`\`\`bash" \
"# Desconectar enlace R1-R2 (simular fallo)" \
"sudo ip netns exec R1 ip link set veth-r1r2 down" \
"sudo ip netns exec R2 ip link set veth-r2r1 down" \
"" \
"# Verificar conectividad por ruta alternativa" \
"sudo ip netns exec clienteSede ping -c 4 10.0.2.10" \
"\`\`\`" \
"" \
"**Salida esperada:** Debe funcionar usando la ruta alternativa por R3." \
"" \
"### Paso 8: Configurar túnel GRE" \
"" \
"Los túneles GRE permiten conectar redes no contiguas a través de Internet." \
"" \
"\`\`\`bash" \
"# En R1" \
"sudo ip netns exec R1 ip tunnel add gre1 mode gre remote 192.168.3.2 local 192.168.3.1 ttl 255" \
"sudo ip netns exec R1 ip addr add 10.100.0.1/30 dev gre1" \
"sudo ip netns exec R1 ip link set gre1 up" \
"" \
"# En R3" \
"sudo ip netns exec R3 ip tunnel add gre1 mode gre remote 192.168.3.1 local 192.168.3.2 ttl 255" \
"sudo ip netns exec R3 ip addr add 10.100.0.2/30 dev gre1" \
"sudo ip netns exec R3 ip link set gre1 up" \
"" \
"# Verificar túnel" \
"sudo ip netns exec R1 ping -c 4 10.100.0.2" \
"\`\`\`" \
"" \
"## Análisis de la tabla de enrutamiento" \
"" \
"\`\`\`bash" \
"sudo ip netns exec R1 ip route show" \
"\`\`\`" \
"" \
"**Interpretación de la salida:**" \
"- Las rutas conectadas directamente (directas) aparecen con \`dev\`." \
"- Las rutas estáticas aparecen con \`via\`." \
"- La ruta por defecto (si existe) es \`0.0.0.0/0\`." \
"" \
"## Ejercicios prácticos" \
"" \
"### Ejercicio 1: Agregar una nueva oficina" \
"" \
"Agrega una cuarta oficina (Sucursal C) con red 10.0.3.0/24, conéctala a R2 y configura las rutas necesarias para que todos los clientes se comuniquen." \
"" \
"### Ejercicio 2: Verificar el TTL" \
"" \
"Desde el cliente Sede, haz un \`traceroute\` a la Sucursal B y observa cómo los routers decrementan el TTL." \
"" \
"\`\`\`bash" \
"sudo ip netns exec clienteSede traceroute -n 10.0.2.10" \
"\`\`\`" \
"" \
"### Ejercicio 3: Recuperar el enlace" \
"" \
"Vuelve a activar el enlace R1-R2 y verifica la conectividad." \
"" \
"\`\`\`bash" \
"sudo ip netns exec R1 ip link set veth-r1r2 up" \
"sudo ip netns exec R2 ip link set veth-r2r1 up" \
"\`\`\`" \
"" \
"## Errores comunes y soluciones" \
"" \
"| Error | Causa | Solución |" \
"|-------|-------|----------|" \
"| Ping falla entre oficinas | Falta ruta de retorno. | Verificar rutas en ambos sentidos. |" \
"| Traceroute muestra asteriscos | Firewall bloquea ICMP. | Permitir ICMP en las políticas. |" \
"| El túnel GRE no funciona | IPs de extremos no accesibles. | Verificar conectividad entre extremos. |" \
"" \
"## Conceptos clave del Tema 6 aplicados" \
"" \
"| Concepto | Aplicación en el laboratorio |" \
"|----------|------------------------------|" \
"| Enrutamiento | Conexión entre redes diferentes |" \
"| Ruta estática | Configuración manual de rutas |" \
"| Ruta por defecto | Gateway para tráfico desconocido |" \
"| Tabla de enrutamiento | \`ip route show\` en cada router |" \
"| Longest prefix match | Selección de ruta más específica |" \
"| Túnel GRE | Conexión de redes no contiguas |" \
"" \
"## Conclusiones técnicas" \
"" \
"En este laboratorio hemos:" \
"" \
"1.  Implementado una topología con tres routers interconectados." \
"2.  Configurado **rutas estáticas** para interconectar las oficinas." \
"3.  Analizado la **tabla de enrutamiento** y el proceso de selección." \
"4.  Agregado **redundancia** con un enlace alternativo." \
"5.  Configurado un **túnel GRE** para conectar redes no contiguas." \
"" \
"El enrutamiento es el corazón de la comunicación entre redes. Las rutas estáticas son simples pero no escalan, mientras que los protocolos dinámicos como OSPF ofrecen convergencia automática. Los túneles GRE permiten extender redes a través de infraestructuras IP." \
"" \
"## Preparación para el siguiente laboratorio" \
"" \
"En el **Laboratorio 07** exploraremos **protocolos y servicios de red** como DHCP, DNS, NAT y firewalls." \
"" \
"---" \
"" \
"**¡Laboratorio 06 completado!** Has implementado enrutamiento entre redes. Continúa con el **Laboratorio 07**." \
> "$LAB_DIR/index.md"

# Actualizar mkdocs.yml
MKCDOCS="$PROJECT_DIR/mkdocs.yml"
if grep -q "06 - Enrutamiento" "$MKCDOCS"; then
    echo "⚠️ El laboratorio 06 ya está registrado en mkdocs.yml. Omitiendo..."
else
    sed -i '/05 - Conmutación y VLANs/a \      - '\''06 - Enrutamiento y Conectividad entre Redes'\'': '\''labs/lab-06/index.md'\''' "$MKCDOCS"
    echo "✅ Laboratorio 06 agregado a la navegación en mkdocs.yml"
fi

echo "✅ Laboratorio 06 creado exitosamente en $LAB_DIR"
echo "📝 Ahora compila el sitio con: mkdocs build --clean && mkdocs serve --dev-addr=127.0.0.1:8000"
