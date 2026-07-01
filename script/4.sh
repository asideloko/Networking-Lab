#!/bin/bash
# create_lab04.sh – Crea el Laboratorio 04 (Direccionamiento IP y Subredes)

set -e

PROJECT_DIR="$(pwd)"
if [ ! -f "$PROJECT_DIR/mkdocs.yml" ]; then
    echo "❌ No se encuentra mkdocs.yml. Asegúrate de ejecutar este script desde la raíz del proyecto."
    exit 1
fi

LAB_DIR="$PROJECT_DIR/docs/labs/lab-04"
echo "📁 Creando laboratorio 04 en $LAB_DIR"

mkdir -p "$LAB_DIR"/{images,diagrams,configs,files}

printf '%s\n' \
"# Laboratorio 04 – Direccionamiento IP y Subredes" \
"" \
"## Contexto empresarial" \
"" \
"La empresa **Networking SecOps** ha seguido creciendo. Ahora cuenta con **dos departamentos** con necesidades de red independientes:" \
"" \
"-   **Ventas**: 10 empleados que necesitan acceso a Internet y a un servidor interno." \
"-   **IT/Sistemas**: 6 empleados que administran servidores y necesitan acceso restringido." \
"" \
"La red actual (todos los clientes en una sola subred \`10.0.1.0/24\`) ya no es suficiente. Se necesita **segmentar la red** en subredes separadas para:" \
"" \
"-   Aislar el tráfico entre departamentos." \
"-   Aplicar políticas de seguridad diferentes." \
"-   Mejorar el rendimiento reduciendo dominios de broadcast." \
"-   Optimizar el uso del espacio de direcciones." \
"" \
"## Problema inicial" \
"" \
"-   Todos los clientes están en la misma subred \`10.0.1.0/24\`." \
"-   Se necesitan **dos subredes**: una para Ventas y otra para IT." \
"-   El router debe encaminar el tráfico entre subredes." \
"-   Se debe implementar **VLSM** para optimizar el uso de direcciones." \
"" \
"## Objetivos del laboratorio" \
"" \
"1.  Comprender la estructura de las direcciones IPv4 (32 bits)." \
"2.  Aplicar **subnetting** para dividir una red en subredes más pequeñas." \
"3.  Implementar **VLSM** (Variable Length Subnet Mask) para optimizar direcciones." \
"4.  Configurar **subinterfaces** en el router para soportar múltiples subredes." \
"5.  Verificar la comunicación entre subredes mediante enrutamiento." \
"6.  Analizar la relación Red-Subred-Host." \
"" \
"## Herramientas necesarias" \
"" \
"-   Linux con privilegios de superusuario." \
"-   Comandos: \`ip\`, \`ping\`, \`tcpdump\`, \`ipcalc\` (opcional)." \
"-   Conocimientos de subnetting y notación CIDR." \
"" \
"## Diseño de subredes" \
"" \
"**Red base:** \`10.0.0.0/24\` (para simplificar, aunque en producción sería una red privada /24)." \
"" \
"**Requisitos:**" \
"-   Subred 1: Ventas → 10 hosts (mínimo /28 → 14 hosts útiles)." \
"-   Subred 2: IT → 6 hosts (mínimo /29 → 6 hosts útiles)." \
"-   Subred 3: Enlace router-switch → 2 hosts (mínimo /30 → 2 hosts útiles)." \
"" \
"**Cálculo VLSM:**" \
"" \
"| Subred | Hosts Necesarios | Máscara | Tamaño del Bloque | Dirección de Red | Rango de Hosts | Broadcast |" \
"|--------|------------------|---------|-------------------|------------------|----------------|-----------|" \
"| Ventas | 10 | /28 | 16 | 10.0.0.0/28 | 10.0.0.1 - 10.0.0.14 | 10.0.0.15 |" \
"| IT | 6 | /29 | 8 | 10.0.0.16/29 | 10.0.0.17 - 10.0.0.22 | 10.0.0.23 |" \
"| Enlace Router-Switch | 2 | /30 | 4 | 10.0.0.24/30 | 10.0.0.25 - 10.0.0.26 | 10.0.0.27 |" \
"" \
"## Topología" \
"" \
"\`\`\`mermaid" \
"graph TB" \
"    V1[Ventas 1 10.0.0.1/28]" \
"    V2[Ventas 2 10.0.0.2/28]" \
"    V3[Ventas 3 10.0.0.3/28]" \
"    I1[IT 1 10.0.0.17/29]" \
"    I2[IT 2 10.0.0.18/29]" \
"    I3[IT 3 10.0.0.19/29]" \
"    R[Router 10.0.0.25/30]" \
"    SW[Switch 10.0.0.26/30]" \
"    Internet((Internet))" \
"    V1 --- SW" \
"    V2 --- SW" \
"    V3 --- SW" \
"    I1 --- SW" \
"    I2 --- SW" \
"    I3 --- SW" \
"    SW --- R" \
"    R --- Internet" \
"\`\`\`" \
"" \
"**Nota sobre la topología:** En esta implementación, el switch es un bridge en Linux que opera en capa 2. Los clientes en diferentes subredes están conectados al mismo switch físico (bridge), pero **no pueden comunicarse directamente** porque están en diferentes subredes. La comunicación entre subredes debe pasar por el router." \
"" \
"## Construcción de la red" \
"" \
"### Paso 1: Verificar el estado actual" \
"" \
"Asegurémonos de que los laboratorios anteriores están funcionando:" \
"" \
"\`\`\`bash" \
"# Verificar namespaces" \
"ip netns list" \
"" \
"# Verificar conectividad" \
"ip netns exec cliente1 ping -c 2 10.0.1.3" \
"\`\`\`" \
"" \
"Si los namespaces existen, los eliminaremos para empezar desde cero con el nuevo diseño." \
"" \
"### Paso 2: Limpiar configuración anterior" \
"" \
"\`\`\`bash" \
"# Eliminar namespaces anteriores (si existen)" \
"ip netns del cliente1 2>/dev/null || true" \
"ip netns del cliente2 2>/dev/null || true" \
"ip netns del cliente3 2>/dev/null || true" \
"ip netns del cliente4 2>/dev/null || true" \
"ip netns del router 2>/dev/null || true" \
"ip netns del switch 2>/dev/null || true" \
"" \
"# Eliminar interfaces veth residuales (si existen)" \
"ip link del veth-c1 2>/dev/null || true" \
"ip link del veth-c2 2>/dev/null || true" \
"ip link del veth-c3 2>/dev/null || true" \
"ip link del veth-c4 2>/dev/null || true" \
"ip link del veth-sr 2>/dev/null || true" \
"ip link del veth-host 2>/dev/null || true" \
"\`\`\`" \
"" \
"### Paso 3: Crear namespaces" \
"" \
"\`\`\`bash" \
"# Router" \
"ip netns add router" \
"" \
"# Switch (bridge)" \
"ip netns add switch" \
"" \
"# Clientes del departamento Ventas (3 para demostración)" \
"ip netns add ventas1" \
"ip netns add ventas2" \
"ip netns add ventas3" \
"" \
"# Clientes del departamento IT (3 para demostración)" \
"ip netns add it1" \
"ip netns add it2" \
"ip netns add it3" \
"\`\`\`" \
"" \
"### Paso 4: Crear el bridge en el switch" \
"" \
"\`\`\`bash" \
"# Crear bridge" \
"ip netns exec switch ip link add br0 type bridge" \
"ip netns exec switch ip link set br0 up" \
"\`\`\`" \
"" \
"### Paso 5: Conectar clientes de Ventas al switch" \
"" \
"\`\`\`bash" \
"# Ventas 1" \
"ip link add veth-v1 type veth peer name veth-sv1" \
"ip link set veth-v1 netns ventas1" \
"ip link set veth-sv1 netns switch" \
"ip netns exec ventas1 ip addr add 10.0.0.1/28 dev veth-v1" \
"ip netns exec ventas1 ip link set veth-v1 up" \
"ip netns exec ventas1 ip link set lo up" \
"ip netns exec ventas1 ip route add default via 10.0.0.14" \
"ip netns exec switch ip link set veth-sv1 master br0" \
"ip netns exec switch ip link set veth-sv1 up" \
"" \
"# Ventas 2" \
"ip link add veth-v2 type veth peer name veth-sv2" \
"ip link set veth-v2 netns ventas2" \
"ip link set veth-sv2 netns switch" \
"ip netns exec ventas2 ip addr add 10.0.0.2/28 dev veth-v2" \
"ip netns exec ventas2 ip link set veth-v2 up" \
"ip netns exec ventas2 ip link set lo up" \
"ip netns exec ventas2 ip route add default via 10.0.0.14" \
"ip netns exec switch ip link set veth-sv2 master br0" \
"ip netns exec switch ip link set veth-sv2 up" \
"" \
"# Ventas 3" \
"ip link add veth-v3 type veth peer name veth-sv3" \
"ip link set veth-v3 netns ventas3" \
"ip link set veth-sv3 netns switch" \
"ip netns exec ventas3 ip addr add 10.0.0.3/28 dev veth-v3" \
"ip netns exec ventas3 ip link set veth-v3 up" \
"ip netns exec ventas3 ip link set lo up" \
"ip netns exec ventas3 ip route add default via 10.0.0.14" \
"ip netns exec switch ip link set veth-sv3 master br0" \
"ip netns exec switch ip link set veth-sv3 up" \
"\`\`\`" \
"" \
"### Paso 6: Conectar clientes de IT al switch" \
"" \
"\`\`\`bash" \
"# IT 1" \
"ip link add veth-i1 type veth peer name veth-si1" \
"ip link set veth-i1 netns it1" \
"ip link set veth-si1 netns switch" \
"ip netns exec it1 ip addr add 10.0.0.17/29 dev veth-i1" \
"ip netns exec it1 ip link set veth-i1 up" \
"ip netns exec it1 ip link set lo up" \
"ip netns exec it1 ip route add default via 10.0.0.22" \
"ip netns exec switch ip link set veth-si1 master br0" \
"ip netns exec switch ip link set veth-si1 up" \
"" \
"# IT 2" \
"ip link add veth-i2 type veth peer name veth-si2" \
"ip link set veth-i2 netns it2" \
"ip link set veth-si2 netns switch" \
"ip netns exec it2 ip addr add 10.0.0.18/29 dev veth-i2" \
"ip netns exec it2 ip link set veth-i2 up" \
"ip netns exec it2 ip link set lo up" \
"ip netns exec it2 ip route add default via 10.0.0.22" \
"ip netns exec switch ip link set veth-si2 master br0" \
"ip netns exec switch ip link set veth-si2 up" \
"" \
"# IT 3" \
"ip link add veth-i3 type veth peer name veth-si3" \
"ip link set veth-i3 netns it3" \
"ip link set veth-si3 netns switch" \
"ip netns exec it3 ip addr add 10.0.0.19/29 dev veth-i3" \
"ip netns exec it3 ip link set veth-i3 up" \
"ip netns exec it3 ip link set lo up" \
"ip netns exec it3 ip route add default via 10.0.0.22" \
"ip netns exec switch ip link set veth-si3 master br0" \
"ip netns exec switch ip link set veth-si3 up" \
"\`\`\`" \
"" \
"### Paso 7: Conectar el switch al router (enlace /30)" \
"" \
"\`\`\`bash" \
"# Crear par veth switch-router" \
"ip link add veth-sr type veth peer name veth-rs" \
"ip link set veth-sr netns switch" \
"ip link set veth-rs netns router" \
"" \
"# Configurar en el switch" \
"ip netns exec switch ip addr add 10.0.0.26/30 dev veth-sr" \
"ip netns exec switch ip link set veth-sr up" \
"ip netns exec switch ip route add default via 10.0.0.25" \
"" \
"# Configurar en el router" \
"ip netns exec router ip addr add 10.0.0.25/30 dev veth-rs" \
"ip netns exec router ip link set veth-rs up" \
"\`\`\`" \
"" \
"### Paso 8: Configurar NAT y enrutamiento en el router" \
"" \
"El router necesita saber cómo llegar a las subredes de Ventas e IT y tener NAT hacia Internet." \
"" \
"\`\`\`bash" \
"# Habilitar forwarding" \
"ip netns exec router sysctl -w net.ipv4.ip_forward=1" \
"" \
"# Agregar rutas estáticas hacia las subredes" \
"# El router usa la IP del switch (10.0.0.26) como gateway" \
"ip netns exec router ip route add 10.0.0.0/28 via 10.0.0.26" \
"ip netns exec router ip route add 10.0.0.16/29 via 10.0.0.26" \
"" \
"# Configurar NAT (asumiendo que el host tiene una interfaz con Internet)" \
"# En este laboratorio, simulamos Internet con el host" \
"ip link add veth-host type veth peer name veth-wan" \
"ip link set veth-wan netns router" \
"ip netns exec router ip addr add 192.168.1.2/24 dev veth-wan" \
"ip netns exec router ip link set veth-wan up" \
"ip addr add 192.168.1.1/24 dev veth-host" \
"ip link set veth-host up" \
"" \
"# NAT" \
"ip netns exec router iptables -t nat -A POSTROUTING -o veth-wan -j MASQUERADE" \
"ip netns exec router iptables -A FORWARD -i veth-rs -o veth-wan -j ACCEPT" \
"ip netns exec router iptables -A FORWARD -i veth-wan -o veth-rs -m state --state RELATED,ESTABLISHED -j ACCEPT" \
"" \
"# Ruta en el host para el retorno" \
"ip route add 10.0.0.0/24 via 192.168.1.2" \
"\`\`\`" \
"" \
"### Paso 9: Verificar conectividad dentro de la misma subred" \
"" \
"\`\`\`bash" \
"# Ventas 1 a Ventas 2 (misma subred)" \
"ip netns exec ventas1 ping -c 4 10.0.0.2" \
"" \
"# IT 1 a IT 2 (misma subred)" \
"ip netns exec it1 ping -c 4 10.0.0.18" \
"\`\`\`" \
"" \
"**Salida esperada:** 0% de pérdida (comunicación directa a través del switch)." \
"" \
"### Paso 10: Verificar conectividad entre subredes" \
"" \
"\`\`\`bash" \
"# Ventas 1 a IT 1 (diferente subred)" \
"ip netns exec ventas1 ping -c 4 10.0.0.17" \
"\`\`\`" \
"" \
"**Salida esperada:** 0% de pérdida (el tráfico pasa por el router)." \
"" \
"### Paso 11: Verificar conectividad a Internet" \
"" \
"\`\`\`bash" \
"# Ventas 1 a Internet" \
"ip netns exec ventas1 ping -c 4 8.8.8.8" \
"" \
"# IT 1 a Internet" \
"ip netns exec it1 curl -I http://google.com" \
"\`\`\`" \
"" \
"**Salida esperada:** Respuestas exitosas (NAT funciona)." \
"" \
"## Observación y análisis" \
"" \
"### Paso 12: Ver las tablas de enrutamiento" \
"" \
"\`\`\`bash" \
"# Ruta en Ventas 1" \
"ip netns exec ventas1 ip route show" \
"" \
"# Ruta en el router" \
"ip netns exec router ip route show" \
"\`\`\`" \
"" \
"**Análisis:**" \
"- Los clientes tienen una ruta por defecto hacia su gateway." \
"- El router tiene rutas específicas para cada subred." \
"" \
"### Paso 13: Capturar tráfico entre subredes" \
"" \
"\`\`\`bash" \
"# Capturar en el router (interfaz hacia el switch)" \
"ip netns exec router tcpdump -i veth-rs -n icmp" \
"\`\`\`" \
"" \
"En otra terminal:" \
"" \
"\`\`\`bash" \
"ip netns exec ventas1 ping -c 1 10.0.0.17" \
"\`\`\`" \
"" \
"**Interpretación:**" \
"1.  El paquete sale de Ventas 1 con origen 10.0.0.1 y destino 10.0.0.17." \
"2.  El switch lo recibe y, al ver que el destino no está en la misma subred, lo envía al router (gateway)." \
"3.  El router recibe el paquete, consulta su tabla de enrutamiento y lo reenvía por la misma interfaz hacia el switch." \
"4.  El switch entrega el paquete a IT 1." \
"" \
"## Ejercicios prácticos" \
"" \
"### Ejercicio 1: Calcular subredes adicionales" \
"" \
"Si necesitáramos una tercera subred para **Administración** con 4 hosts, ¿qué máscara usarías y qué rango de direcciones asignarías?" \
"" \
"**Solución:**" \
"- 4 hosts → /29 (8 direcciones, 6 hosts útiles)." \
"- Rango disponible: 10.0.0.28/29." \
"" \
"### Ejercicio 2: Verificar la tabla ARP" \
"" \
"\`\`\`bash" \
"# Ver tabla ARP en Ventas 1" \
"ip netns exec ventas1 ip neigh show" \
"\`\`\`" \
"" \
"### Ejercicio 3: Agregar un nuevo cliente" \
"" \
"Agrega un cuarto cliente al departamento Ventas (10.0.0.4/28) y verifica que puede comunicarse con los demás." \
"" \
"\`\`\`bash" \
"ip netns add ventas4" \
"ip link add veth-v4 type veth peer name veth-sv4" \
"ip link set veth-v4 netns ventas4" \
"ip link set veth-sv4 netns switch" \
"ip netns exec ventas4 ip addr add 10.0.0.4/28 dev veth-v4" \
"ip netns exec ventas4 ip link set veth-v4 up" \
"ip netns exec ventas4 ip link set lo up" \
"ip netns exec ventas4 ip route add default via 10.0.0.14" \
"ip netns exec switch ip link set veth-sv4 master br0" \
"ip netns exec switch ip link set veth-sv4 up" \
"ip netns exec ventas4 ping -c 4 10.0.0.1" \
"\`\`\`" \
"" \
"## Errores comunes y soluciones" \
"" \
"| Error | Causa | Solución |" \
"|-------|-------|----------|" \
"| Clientes en diferentes subredes no pueden hacer ping | El router no tiene rutas. | Agregar rutas estáticas en el router. |" \
"| \`ping: connect: Network is unreachable\` | Máscara de subred incorrecta. | Verificar \`ip addr show\` en el cliente. |" \
"| No sale a Internet | NAT no configurado. | Verificar reglas de iptables y \`ip_forward=1\`. |" \
"" \
"## Conclusiones técnicas" \
"" \
"En este laboratorio hemos:" \
"" \
"1.  **Aplicado subnetting** para dividir una red en subredes más pequeñas." \
"2.  **Implementado VLSM** para optimizar el uso de direcciones." \
"3.  **Configurado rutas estáticas** en el router para comunicar subredes." \
"4.  **Verificado la comunicación entre subredes** a través del router." \
"" \
"## Preparación para el siguiente laboratorio" \
"" \
"Hemos dejado la red con dos subredes (Ventas e IT) y un enlace /30 al router. En el **Laboratorio 05** implementaremos **VLANs** para segmentar físicamente el tráfico." \
"" \
"---" \
"" \
"**¡Laboratorio 04 completado!** Continúa con el **Laboratorio 05**." \
> "$LAB_DIR/index.md"

# Actualizar mkdocs.yml
MKCDOCS="$PROJECT_DIR/mkdocs.yml"
if grep -q "04 - Direccionamiento IP" "$MKCDOCS"; then
    echo "⚠️ El laboratorio 04 ya está registrado en mkdocs.yml. Omitiendo..."
else
    sed -i '/03 - Componentes de Red/a \      - '\''04 - Direccionamiento IP y Subredes'\'': '\''labs/lab-04/index.md'\''' "$MKCDOCS"
    echo "✅ Laboratorio 04 agregado a la navegación en mkdocs.yml"
fi

echo "✅ Laboratorio 04 creado exitosamente en $LAB_DIR"
