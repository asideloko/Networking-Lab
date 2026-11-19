#!/usr/bin/env bash
# Smoke test funcional aislado: veth, bridge/FDB, routing, firewall y reversión.
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Ejecuta este test como root (sudo bash scripts/pruebas_funcionales.sh)" >&2
  exit 1
fi
for cmd in ip ping; do
  command -v "$cmd" >/dev/null || { echo "Falta dependencia: $cmd" >&2; exit 1; }
done
FIREWALL_BACKEND=""
if command -v nft >/dev/null 2>&1; then FIREWALL_BACKEND=nft
elif command -v iptables >/dev/null 2>&1; then FIREWALL_BACKEND=iptables
fi

SUF="$$"
A="nlci_a_${SUF}"; B="nlci_b_${SUF}"; SW="nlci_sw_${SUF}"; R="nlci_r_${SUF}"; C="nlci_c_${SUF}"
NAMESPACES=("$A" "$B" "$SW" "$R" "$C")
cleanup() {
  for ns in "${NAMESPACES[@]}"; do ip netns del "$ns" 2>/dev/null || true; done
  for dev in "nlci_a_${SUF}" "nlci_b_${SUF}" "nlci_sw_${SUF}" "nlci_r_${SUF}" "nlci_c_${SUF}"; do ip link del "$dev" 2>/dev/null || true; done
}
trap cleanup EXIT INT TERM

for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then
    echo "Namespace de prueba preexistente: $ns" >&2; exit 1
  fi
  if ! ip netns add "$ns" 2>/tmp/nlci-netns-error; then
    cleanup
    if grep -qiE 'operation not permitted|permission denied|mount --make-shared' /tmp/nlci-netns-error; then
      echo "SKIP: el entorno no permite crear namespaces de red (se requiere CAP_SYS_ADMIN/CAP_NET_ADMIN)"
      rm -f /tmp/nlci-netns-error
      trap - EXIT INT TERM
      exit 0
    fi
    cat /tmp/nlci-netns-error >&2
    rm -f /tmp/nlci-netns-error
    exit 1
  fi
done
rm -f /tmp/nlci-netns-error

# Dos hosts en un dominio L2 conmutado.
ip link add a0 type veth peer name sw_a
ip link set a0 netns "$A"; ip link set sw_a netns "$SW"
ip link add b0 type veth peer name sw_b
ip link set b0 netns "$B"; ip link set sw_b netns "$SW"
ip link add sw_r type veth peer name r_lan
ip link set sw_r netns "$SW"; ip link set r_lan netns "$R"
ip netns exec "$SW" ip link add br0 type bridge
for dev in sw_a sw_b sw_r; do
  ip netns exec "$SW" ip link set "$dev" master br0
  ip netns exec "$SW" ip link set "$dev" up
done
ip netns exec "$SW" ip link set br0 up

# Segundo segmento L3 detrás del router.
ip link add r_wan type veth peer name c_wan
ip link set r_wan netns "$R"; ip link set c_wan netns "$C"
for ns in "$A" "$B" "$R" "$C"; do ip netns exec "$ns" ip link set lo up; done
ip netns exec "$A" ip addr add 10.10.1.2/24 dev a0
ip netns exec "$A" ip link set a0 up
ip netns exec "$B" ip addr add 10.10.1.3/24 dev b0
ip netns exec "$B" ip link set b0 up
ip netns exec "$R" ip addr add 10.10.1.1/24 dev r_lan
ip netns exec "$R" ip link set r_lan up
ip netns exec "$R" ip addr add 10.20.1.1/24 dev r_wan
ip netns exec "$R" ip link set r_wan up
ip netns exec "$C" ip addr add 10.20.1.2/24 dev c_wan
ip netns exec "$C" ip link set c_wan up
ip netns exec "$R" sysctl -qw net.ipv4.ip_forward=1
ip netns exec "$A" ip route add default via 10.10.1.1
ip netns exec "$B" ip route add default via 10.10.1.1
ip netns exec "$C" ip route add default via 10.20.1.1

# Política de forwarding: permitir solo A/B -> C y el retorno establecido.
if [[ "$FIREWALL_BACKEND" == nft ]]; then
  ip netns exec "$R" nft add table inet ci
  ip netns exec "$R" nft 'add chain inet ci forward { type filter hook forward priority 0; policy drop; }'
  ip netns exec "$R" nft add rule inet ci forward ct state established,related accept
  ip netns exec "$R" nft add rule inet ci forward iifname "r_lan" oifname "r_wan" ip saddr 10.10.1.0/24 ip daddr 10.20.1.0/24 icmp type echo-request accept
elif [[ "$FIREWALL_BACKEND" == iptables ]]; then
  ip netns exec "$R" iptables -P FORWARD DROP
  ip netns exec "$R" iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  ip netns exec "$R" iptables -A FORWARD -i r_lan -o r_wan -s 10.10.1.0/24 -d 10.20.1.0/24 -p icmp --icmp-type echo-request -j ACCEPT
else
  echo "AVISO: nft/iptables no disponible; se omite la comprobación de filtrado, no L2/routing"
fi

ip netns exec "$A" ping -c 2 -W 2 10.10.1.3 >/dev/null
ip netns exec "$A" ping -c 2 -W 2 10.20.1.2 >/dev/null
if [[ -n "$FIREWALL_BACKEND" ]] && ip netns exec "$C" ping -c 1 -W 1 10.10.1.2 >/dev/null 2>&1; then
  echo "FALLO: el firewall permitió una conexión iniciada desde el segmento C" >&2
  exit 1
fi
ip netns exec "$SW" bridge fdb show br br0 | grep -q .

# Reversión explícita y comprobación: el trap debe dejar todos los namespaces ausentes.
cleanup
for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then
    echo "FALLO: quedó namespace residual $ns" >&2; exit 1
  fi
done
trap - EXIT INT TERM
echo "OK: L2/FDB, routing y reversión verificados; backend de firewall: ${FIREWALL_BACKEND:-no disponible}"
