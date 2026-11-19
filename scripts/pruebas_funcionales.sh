#!/usr/bin/env bash
# Pruebas funcionales aisladas: L2/FDB, routing, firewall, VLAN 802.1Q, GRE, continuidad y reversión.
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Ejecuta este test como root (sudo bash scripts/pruebas_funcionales.sh)" >&2
  exit 1
fi
for cmd in ip ping dnsmasq dhclient dig keepalived; do
  command -v "$cmd" >/dev/null || { echo "Falta dependencia: $cmd (instala iproute2, iputils-ping, dnsmasq-base, isc-dhcp-client, dnsutils y keepalived)" >&2; exit 1; }
done
FIREWALL_BACKEND=""
if command -v nft >/dev/null 2>&1; then FIREWALL_BACKEND=nft
elif command -v iptables >/dev/null 2>&1; then FIREWALL_BACKEND=iptables
fi
if [[ -z "$FIREWALL_BACKEND" && "${CI:-}" == true ]]; then
  echo "FALLO: CI no tiene nftables ni iptables; no se puede validar el filtrado." >&2
  exit 1
fi

SUF="$$"
A="nlci_a_${SUF}"; B="nlci_b_${SUF}"; SW="nlci_sw_${SUF}"; R="nlci_r_${SUF}"; C="nlci_c_${SUF}"
NAMESPACES=("$A" "$B" "$SW" "$R" "$C")
HOST_LINKS=("nlci_a_${SUF}" "nlci_b_${SUF}" "nlci_sw_${SUF}" "nlci_r_${SUF}" "nlci_c_${SUF}")
PID_FILES=()
TEMP_FILES=()
HOST_IP_FORWARD_ORIG=""
HOST_IP_FORWARD_CHANGED=0
HOST_NFT_TABLE=""
HOST_IPTABLES_NAT_MARKER=""
HOST_IPTABLES_FORWARD_OUT_MARKER=""
HOST_IPTABLES_FORWARD_IN_MARKER=""
HOST_LINK_IN=""
HOST_LINK_OUT=""
cleanup() {
  # La limpieza debe continuar aunque falle una operación de reversión puntual.
  local restore_errexit=0
  [[ $- == *e* ]] && restore_errexit=1
  set +e
  # Revertir primero las reglas temporales del host, si la prueba las creó.
  if [[ -n "$HOST_NFT_TABLE" ]] && command -v nft >/dev/null 2>&1; then
    nft delete table inet "$HOST_NFT_TABLE" 2>/dev/null || true
  fi
  if [[ -n "$HOST_IPTABLES_NAT_MARKER" && -f "$HOST_IPTABLES_NAT_MARKER" ]]; then
    iptables -t nat -D POSTROUTING -s 198.18.0.0/30 -o "$HOST_LINK_OUT" -j MASQUERADE 2>/dev/null || true
    rm -f "$HOST_IPTABLES_NAT_MARKER"
  fi
  if [[ -n "$HOST_IPTABLES_FORWARD_OUT_MARKER" && -f "$HOST_IPTABLES_FORWARD_OUT_MARKER" ]]; then
    iptables -D FORWARD -i "$HOST_LINK_IN" -o "$HOST_LINK_OUT" -s 198.18.0.0/30 -d 203.0.113.0/30 -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null || true
    rm -f "$HOST_IPTABLES_FORWARD_OUT_MARKER"
  fi
  if [[ -n "$HOST_IPTABLES_FORWARD_IN_MARKER" && -f "$HOST_IPTABLES_FORWARD_IN_MARKER" ]]; then
    iptables -D FORWARD -i "$HOST_LINK_OUT" -o "$HOST_LINK_IN" -d 198.18.0.0/30 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    rm -f "$HOST_IPTABLES_FORWARD_IN_MARKER"
  fi
  if [[ "$HOST_IP_FORWARD_CHANGED" == 1 ]]; then
    sysctl -w net.ipv4.ip_forward="$HOST_IP_FORWARD_ORIG" >/dev/null
    HOST_IP_FORWARD_CHANGED=0
  fi
  # Detener solo procesos cuyo cmdline conserva la ruta PID file de esta prueba.
  for pf in "${PID_FILES[@]}"; do
    [ -s "$pf" ] || continue
    pid=$(cat "$pf" 2>/dev/null || true)
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    [ -r "/proc/$pid/cmdline" ] || continue
    cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline")
    if [[ "$cmdline" == *"/tmp/nlci-"*"$SUF"* ]]; then kill -TERM "$pid" 2>/dev/null || true; fi
  done
  sleep 1
  for pf in "${PID_FILES[@]}"; do
    [ -s "$pf" ] || continue
    pid=$(cat "$pf" 2>/dev/null || true)
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    [ -r "/proc/$pid/cmdline" ] || continue
    cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline")
    if [[ "$cmdline" == *"/tmp/nlci-"*"$SUF"* ]]; then kill -KILL "$pid" 2>/dev/null || true; fi
  done
  for ns in "${NAMESPACES[@]}"; do ip netns del "$ns" 2>/dev/null || true; done
  for dev in "${HOST_LINKS[@]}"; do ip link del "$dev" 2>/dev/null || true; done
  for f in "${PID_FILES[@]}" "${TEMP_FILES[@]}"; do rm -f "$f" 2>/dev/null || true; done
  if [[ "$restore_errexit" == 1 ]]; then set -e; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then
    echo "Namespace de prueba preexistente: $ns" >&2; exit 1
  fi
  if ! ip netns add "$ns" 2>/tmp/nlci-netns-error; then
    cleanup
    if grep -qiE 'operation not permitted|permission denied|mount --make-shared' /tmp/nlci-netns-error; then
      if [[ "${CI:-}" == true ]]; then
        echo "FALLO: CI no permite crear namespaces; no se ejecutaron las pruebas funcionales." >&2
        cat /tmp/nlci-netns-error >&2
        rm -f /tmp/nlci-netns-error
        exit 1
      fi
      echo "SKIP: el entorno interactivo no permite crear namespaces de red (se requiere CAP_SYS_ADMIN/CAP_NET_ADMIN)"
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

# Reversión de la primera topología y comprobación de ausencia de residuos.
cleanup
for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then
    echo "FALLO: quedó namespace residual $ns" >&2; exit 1
  fi
done

# Prueba funcional 2: VLAN 802.1Q, puertos access, trunk y routing inter-VLAN.
VSW="nlci_vsw_${SUF}"; VH1="nlci_vh1_${SUF}"; VH2="nlci_vh2_${SUF}"; VR="nlci_vr_${SUF}"
NAMESPACES+=("$VSW" "$VH1" "$VH2" "$VR")
for ns in "$VSW" "$VH1" "$VH2" "$VR"; do ip netns add "$ns"; ip netns exec "$ns" ip link set lo up; done
HOST_LINKS+=("v10h_${SUF}" "v10s_${SUF}" "v20h_${SUF}" "v20s_${SUF}" "trsw_${SUF}" "trrt_${SUF}")
ip link add "v10h_${SUF}" type veth peer name "v10s_${SUF}"
ip link set "v10h_${SUF}" netns "$VH1"; ip link set "v10s_${SUF}" netns "$VSW"
ip link add "v20h_${SUF}" type veth peer name "v20s_${SUF}"
ip link set "v20h_${SUF}" netns "$VH2"; ip link set "v20s_${SUF}" netns "$VSW"
ip link add "trsw_${SUF}" type veth peer name "trrt_${SUF}"
ip link set "trsw_${SUF}" netns "$VSW"; ip link set "trrt_${SUF}" netns "$VR"
ip netns exec "$VSW" ip link add br0 type bridge vlan_filtering 1 vlan_default_pvid 0
ip netns exec "$VSW" ip link set br0 up
for pair in "v10s_${SUF} 10" "v20s_${SUF} 20"; do
  set -- $pair
  ip netns exec "$VSW" ip link set "$1" master br0
  ip netns exec "$VSW" ip link set "$1" up
  ip netns exec "$VSW" bridge vlan add dev "$1" vid "$2" pvid untagged
 done
ip netns exec "$VSW" ip link set "trsw_${SUF}" name tr0
ip netns exec "$VR" ip link set "trrt_${SUF}" name tr0
ip netns exec "$VSW" ip link set tr0 master br0
ip netns exec "$VSW" ip link set tr0 up
ip netns exec "$VSW" bridge vlan add dev tr0 vid 10
ip netns exec "$VSW" bridge vlan add dev tr0 vid 20
ip netns exec "$VR" ip link set tr0 up
ip netns exec "$VR" ip link add link tr0 name tr0.10 type vlan id 10
ip netns exec "$VR" ip link add link tr0 name tr0.20 type vlan id 20
ip netns exec "$VR" ip addr add 10.10.10.1/24 dev tr0.10
ip netns exec "$VR" ip addr add 10.20.20.1/24 dev tr0.20
ip netns exec "$VR" ip link set tr0.10 up
ip netns exec "$VR" ip link set tr0.20 up
ip netns exec "$VR" sysctl -qw net.ipv4.ip_forward=1
ip netns exec "$VH1" ip addr add 10.10.10.2/24 dev "v10h_${SUF}"
ip netns exec "$VH2" ip addr add 10.20.20.2/24 dev "v20h_${SUF}"
ip netns exec "$VH1" ip link set "v10h_${SUF}" up
ip netns exec "$VH2" ip link set "v20h_${SUF}" up
ip netns exec "$VH1" ip route add default via 10.10.10.1
ip netns exec "$VH2" ip route add default via 10.20.20.1
ip netns exec "$VH1" ping -c 2 -W 2 10.20.20.2 >/dev/null
ip netns exec "$VSW" bridge vlan show | grep -q '10'
ip netns exec "$VSW" bridge vlan show | grep -q '20'
cleanup
for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then echo "FALLO: quedó namespace VLAN $ns" >&2; exit 1; fi
done

# Prueba funcional 3: túnel GRE entre routers y rutas de redes remotas.
GR1="nlci_gr1_${SUF}"; GR2="nlci_gr2_${SUF}"; GH1="nlci_gh1_${SUF}"; GH2="nlci_gh2_${SUF}"
GRE_DEV="gre_${SUF}"
NAMESPACES+=("$GR1" "$GR2" "$GH1" "$GH2")
for ns in "$GR1" "$GR2" "$GH1" "$GH2"; do ip netns add "$ns"; ip netns exec "$ns" ip link set lo up; done
HOST_LINKS+=("ngli1_${SUF}" "ngli2_${SUF}" "ngll1_${SUF}" "ngll2_${SUF}")
ip link add "ngli1_${SUF}" type veth peer name "ngli2_${SUF}"
ip link set "ngli1_${SUF}" netns "$GR1"; ip link set "ngli2_${SUF}" netns "$GR2"
ip link add "ngll1_${SUF}" type veth peer name "ngll2_${SUF}"
ip link set "ngll1_${SUF}" netns "$GH1"; ip link set "ngll2_${SUF}" netns "$GR1"
ip link add "ngll3_${SUF}" type veth peer name "ngll4_${SUF}"
HOST_LINKS+=("ngll3_${SUF}" "ngll4_${SUF}")
ip link set "ngll3_${SUF}" netns "$GH2"; ip link set "ngll4_${SUF}" netns "$GR2"
for spec in "$GR1:ngli1_${SUF}:under0" "$GR2:ngli2_${SUF}:under0" "$GR1:ngll2_${SUF}:lan0" "$GR2:ngll4_${SUF}:lan0" "$GH1:ngll1_${SUF}:lan0" "$GH2:ngll3_${SUF}:lan0"; do
  ns=${spec%%:*}; rest=${spec#*:}; dev=${rest%%:*}; newname=${rest##*:}
  ip netns exec "$ns" ip link set "$dev" name "$newname"
  ip netns exec "$ns" ip link set "$newname" up
done
ip netns exec "$GR1" ip addr add 192.0.2.1/30 dev under0
ip netns exec "$GR2" ip addr add 192.0.2.2/30 dev under0
ip netns exec "$GR1" ip addr add 10.1.1.1/24 dev lan0
ip netns exec "$GR2" ip addr add 10.2.2.1/24 dev lan0
ip netns exec "$GH1" ip addr add 10.1.1.2/24 dev lan0
ip netns exec "$GH2" ip addr add 10.2.2.2/24 dev lan0
ip netns exec "$GR1" ip tunnel add "$GRE_DEV" mode gre local 192.0.2.1 remote 192.0.2.2 ttl 64
ip netns exec "$GR2" ip tunnel add "$GRE_DEV" mode gre local 192.0.2.2 remote 192.0.2.1 ttl 64
ip netns exec "$GR1" ip addr add 10.255.0.1/30 dev "$GRE_DEV"
ip netns exec "$GR2" ip addr add 10.255.0.2/30 dev "$GRE_DEV"
ip netns exec "$GR1" ip link set "$GRE_DEV" up
ip netns exec "$GR2" ip link set "$GRE_DEV" up
ip netns exec "$GR1" sysctl -qw net.ipv4.ip_forward=1
ip netns exec "$GR2" sysctl -qw net.ipv4.ip_forward=1
ip netns exec "$GR1" ip route add 10.2.2.0/24 via 10.255.0.2 dev "$GRE_DEV"
ip netns exec "$GR2" ip route add 10.1.1.0/24 via 10.255.0.1 dev "$GRE_DEV"
ip netns exec "$GH1" ip route add default via 10.1.1.1
ip netns exec "$GH2" ip route add default via 10.2.2.1
ip netns exec "$GH1" ping -c 2 -W 2 10.2.2.2 >/dev/null
ip netns exec "$GR1" ip -d tunnel show "$GRE_DEV" | grep -q 'remote 192.0.2.2'

# Prueba funcional 4: IPsec ESP/XFRM en modo transporte entre dos namespaces.
XI1="nlci_xi1_${SUF}"; XI2="nlci_xi2_${SUF}"
NAMESPACES+=("$XI1" "$XI2")
for ns in "$XI1" "$XI2"; do ip netns add "$ns"; ip netns exec "$ns" ip link set lo up; done
HOST_LINKS+=("xfrm1_${SUF}" "xfrm2_${SUF}")
ip link add "xfrm1_${SUF}" type veth peer name "xfrm2_${SUF}"
ip link set "xfrm1_${SUF}" netns "$XI1"; ip link set "xfrm2_${SUF}" netns "$XI2"
ip netns exec "$XI1" ip link set "xfrm1_${SUF}" name eth0
ip netns exec "$XI2" ip link set "xfrm2_${SUF}" name eth0
ip netns exec "$XI1" ip addr add 198.51.100.1/30 dev eth0
ip netns exec "$XI2" ip addr add 198.51.100.2/30 dev eth0
ip netns exec "$XI1" ip link set eth0 up
ip netns exec "$XI2" ip link set eth0 up
AUTH_AB=0x112233445566778899001122334455667788990011223344556677889900aabb
AUTH_BA=0xaabbccddeeff001122334455667788990011223344556677889900aabbccddeeff
ENC_AB=0x00112233445566778899aabbccddeeff
ENC_BA=0xffeeddccbbaa99887766554433221100
for ns in "$XI1" "$XI2"; do
  ip netns exec "$ns" ip xfrm state add src 198.51.100.1 dst 198.51.100.2 proto esp spi 0x100 mode transport reqid 1 auth-trunc 'hmac(sha256)' "$AUTH_AB" 128 enc 'cbc(aes)' "$ENC_AB"
  ip netns exec "$ns" ip xfrm state add src 198.51.100.2 dst 198.51.100.1 proto esp spi 0x200 mode transport reqid 1 auth-trunc 'hmac(sha256)' "$AUTH_BA" 128 enc 'cbc(aes)' "$ENC_BA"
done
ip netns exec "$XI1" ip xfrm policy add src 198.51.100.1/32 dst 198.51.100.2/32 dir out tmpl src 198.51.100.1 dst 198.51.100.2 proto esp mode transport reqid 1
ip netns exec "$XI1" ip xfrm policy add src 198.51.100.2/32 dst 198.51.100.1/32 dir in tmpl src 198.51.100.2 dst 198.51.100.1 proto esp mode transport reqid 1
ip netns exec "$XI2" ip xfrm policy add src 198.51.100.1/32 dst 198.51.100.2/32 dir in tmpl src 198.51.100.1 dst 198.51.100.2 proto esp mode transport reqid 1
ip netns exec "$XI2" ip xfrm policy add src 198.51.100.2/32 dst 198.51.100.1/32 dir out tmpl src 198.51.100.2 dst 198.51.100.1 proto esp mode transport reqid 1
ip netns exec "$XI1" ping -c 2 -W 2 198.51.100.2 >/dev/null
ip netns exec "$XI2" ip -s xfrm state | grep -q 'bytes'
cleanup
for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then echo "FALLO: quedó namespace IPsec $ns" >&2; exit 1; fi
done

# Prueba funcional 5: DHCP y DNS internos con dnsmasq.
DHS="nlci_dhs_${SUF}"; DHC="nlci_dhc_${SUF}"
NAMESPACES+=("$DHS" "$DHC")
for ns in "$DHS" "$DHC"; do ip netns add "$ns"; ip netns exec "$ns" ip link set lo up; done
HOST_LINKS+=("dhsv_${SUF}" "dhcl_${SUF}")
ip link add "dhsv_${SUF}" type veth peer name "dhcl_${SUF}"
ip link set "dhsv_${SUF}" netns "$DHS"; ip link set "dhcl_${SUF}" netns "$DHC"
ip netns exec "$DHS" ip link set "dhsv_${SUF}" name eth0
ip netns exec "$DHC" ip link set "dhcl_${SUF}" name eth0
ip netns exec "$DHS" ip addr add 10.30.0.1/24 dev eth0
ip netns exec "$DHS" ip link set eth0 up
ip netns exec "$DHC" ip link set eth0 up
DNS_PID="/tmp/nlci-dnsmasq-${SUF}.pid"
DNS_LOG="/tmp/nlci-dnsmasq-${SUF}.log"
DNS_LEASES="/tmp/nlci-dnsmasq-${SUF}.leases"

DHCP_PID="/tmp/nlci-dhclient-${SUF}.pid"
DHCP_LEASES="/tmp/nlci-dhclient-${SUF}.leases"
DHCP_LOG="/tmp/nlci-dhclient-${SUF}.log"
DHCLIENT_SCRIPT="/tmp/nlci-dhclient-${SUF}.sh"
DHCP_EVENT="/tmp/nlci-dhclient-${SUF}.event"

PID_FILES+=("$DNS_PID" "$DHCP_PID")
TEMP_FILES+=("$DNS_LOG" "$DNS_LEASES" "$DHCP_LEASES" "$DHCP_LOG" "$DHCLIENT_SCRIPT" "$DHCP_EVENT")

ip netns exec "$DHS" dnsmasq \
  --no-daemon \
  --conf-file=/dev/null \
  --user=root \
  --no-resolv \
  --no-hosts \
  --bind-interfaces \
  --interface=eth0 \
  --listen-address=10.30.0.1 \
  --port=53 \
  --dhcp-range=10.30.0.100,10.30.0.120,255.255.255.0,1h \
  --dhcp-option=option:router,10.30.0.1 \
  --dhcp-option=option:dns-server,10.30.0.1 \
  --dhcp-leasefile="$DNS_LEASES" \
  --address=/app.lab.test/10.30.0.10 \
  --pid-file="$DNS_PID" \
  --log-facility=- >"$DNS_LOG" 2>&1 &

DNS_LAUNCHER_PID=$!
DNS_STARTED=0

for _ in $(seq 1 10); do
  if [ -s "$DNS_PID" ] && kill -0 "$(cat "$DNS_PID")" 2>/dev/null; then
    DNS_STARTED=1
    break
  fi
  if ! kill -0 "$DNS_LAUNCHER_PID" 2>/dev/null; then
    break
  fi
  sleep 1
done

if [[ "$DNS_STARTED" != 1 ]]; then
  echo "FALLO: dnsmasq no inició. Diagnóstico:" >&2
  cat "$DNS_LOG" >&2 || true
  exit 1
fi

# Script DHCP acotado: registra opciones y no toca /etc/resolv.conf ni archivos del host.
cat > "$DHCLIENT_SCRIPT" <<'EOF'
#!/bin/sh
{
  printf 'reason=%s\n' "$reason"
  printf 'ip=%s\n' "$new_ip_address"
  printf 'mask=%s\n' "$new_subnet_mask"
  printf 'routers=%s\n' "$new_routers"
  printf 'dns=%s\n' "$new_domain_name_servers"
} >> "$DHCP_EVENT_FILE"
exit 0
EOF
chmod 700 "$DHCLIENT_SCRIPT"
DHCP_EVENT_FILE="$DHCP_EVENT" ip netns exec "$DHC" dhclient -4 -1 -d -sf "$DHCLIENT_SCRIPT" -pf "$DHCP_PID" -lf "$DHCP_LEASES" eth0 >"$DHCP_LOG" 2>&1 &
LEASE_OK=0
for _ in $(seq 1 15); do
  if [ -s "$DHCP_EVENT" ] && grep -q '^reason=BOUND$' "$DHCP_EVENT"; then LEASE_OK=1; break; fi
  sleep 1
done
[ "$LEASE_OK" = 1 ] || { echo "FALLO: el cliente no obtuvo una concesión DHCP" >&2; cat "$DHCP_LOG" >&2 || true; exit 1; }
LEASE_IP=$(sed -n 's/^ip=//p' "$DHCP_EVENT" | tail -1)
LEASE_ROUTER=$(sed -n 's/^routers=//p' "$DHCP_EVENT" | tail -1)
LEASE_DNS=$(sed -n 's/^dns=//p' "$DHCP_EVENT" | tail -1)
[[ "$LEASE_IP" =~ ^10\.30\.0\.(10[0-9]|11[0-9]|120)$ ]] || { echo "FALLO: dirección DHCP inesperada: $LEASE_IP" >&2; exit 1; }
[[ "$LEASE_ROUTER" == 10.30.0.1* && "$LEASE_DNS" == 10.30.0.1* ]] || { echo "FALLO: opciones DHCP de gateway/DNS incorrectas" >&2; exit 1; }
# La configuración IP se aplica dentro del namespace cliente, sin ejecutar el script de host de dhclient.
ip netns exec "$DHC" ip addr add "$LEASE_IP/24" dev eth0
ip netns exec "$DHC" ip route add default via "$LEASE_ROUTER" dev eth0
ip netns exec "$DHC" dig +time=2 +tries=1 +short @10.30.0.1 app.lab.test | grep -qx '10.30.0.10'

cleanup
for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then echo "FALLO: quedó namespace DHCP/DNS $ns" >&2; exit 1; fi
done

# Prueba funcional 6: VRRP con cambio real de VIP entre dos gateways.
VR1="nlci_vr1_${SUF}"; VR2="nlci_vr2_${SUF}"; VC="nlci_vc_${SUF}"; VSW="nlci_vsw2_${SUF}"
NAMESPACES+=("$VR1" "$VR2" "$VC" "$VSW")
for ns in "$VR1" "$VR2" "$VC" "$VSW"; do ip netns add "$ns"; ip netns exec "$ns" ip link set lo up; done
ip netns exec "$VSW" ip link add br0 type bridge
ip netns exec "$VSW" ip link set br0 up
for spec in "$VR1:r1" "$VR2:r2" "$VC:cl"; do
  ns=${spec%%:*}; port=${spec##*:}; hostdev="v${port}_${SUF}"; swdev="s${port}_${SUF}"
  HOST_LINKS+=("$hostdev" "$swdev")
  ip link add "$hostdev" type veth peer name "$swdev"
  ip link set "$hostdev" netns "$ns"; ip link set "$swdev" netns "$VSW"
  ip netns exec "$ns" ip link set "$hostdev" name lan0
  ip netns exec "$ns" ip link set lan0 up
  ip netns exec "$VSW" ip link set "$swdev" master br0
  ip netns exec "$VSW" ip link set "$swdev" up
done
ip netns exec "$VR1" ip addr add 10.40.0.2/24 dev lan0
ip netns exec "$VR2" ip addr add 10.40.0.3/24 dev lan0
ip netns exec "$VC" ip addr add 10.40.0.10/24 dev lan0
ip netns exec "$VC" ip route add default via 10.40.0.1
VR1_CONF="/tmp/nlci-vrrp1-${SUF}.conf"; VR2_CONF="/tmp/nlci-vrrp2-${SUF}.conf"
VR1_PID="/tmp/nlci-vrrp1-${SUF}.pid"; VR2_PID="/tmp/nlci-vrrp2-${SUF}.pid"
VR1_VPID="/tmp/nlci-vrrp1-${SUF}.vrrp.pid"; VR2_VPID="/tmp/nlci-vrrp2-${SUF}.vrrp.pid"
PID_FILES+=("$VR1_PID" "$VR2_PID" "$VR1_VPID" "$VR2_VPID")
TEMP_FILES+=("$VR1_CONF" "$VR2_CONF")
cat > "$VR1_CONF" <<EOF
vrrp_instance CI_VIP {
    state MASTER
    interface lan0
    virtual_router_id 42
    priority 110
    advert_int 1
    unicast_src_ip 10.40.0.2
    unicast_peer {
        10.40.0.3
    }
    virtual_ipaddress {
        10.40.0.1/24 dev lan0
    }
}
EOF
cat > "$VR2_CONF" <<EOF
vrrp_instance CI_VIP {
    state BACKUP
    interface lan0
    virtual_router_id 42
    priority 100
    advert_int 1
    unicast_src_ip 10.40.0.3
    unicast_peer {
        10.40.0.2
    }
    virtual_ipaddress {
        10.40.0.1/24 dev lan0
    }
}
EOF
ip netns exec "$VR1" keepalived -n -l -P -f "$VR1_CONF" -p "$VR1_PID" -r "$VR1_VPID" >/tmp/nlci-vrrp1-${SUF}.log 2>&1 &
TEMP_FILES+=("/tmp/nlci-vrrp1-${SUF}.log")
ip netns exec "$VR2" keepalived -n -l -P -f "$VR2_CONF" -p "$VR2_PID" -r "$VR2_VPID" >/tmp/nlci-vrrp2-${SUF}.log 2>&1 &
TEMP_FILES+=("/tmp/nlci-vrrp2-${SUF}.log")
VIP_MASTER=0
for _ in $(seq 1 12); do
  if ip netns exec "$VR1" ip -4 -o addr show dev lan0 | grep -q '10\.40\.0\.1/24'; then VIP_MASTER=1; break; fi
  sleep 1
done
[ "$VIP_MASTER" = 1 ] || { echo "FALLO: Dist1 no adquirió la VIP VRRP" >&2; exit 1; }
ip netns exec "$VC" ping -c 2 -W 2 10.40.0.1 >/dev/null
VR1_PID_VALUE=$(cat "$VR1_PID")
VR1_CMDLINE=$(tr '\0' ' ' < "/proc/$VR1_PID_VALUE/cmdline" 2>/dev/null || true)
[[ "$VR1_PID_VALUE" =~ ^[0-9]+$ && "$VR1_CMDLINE" == *keepalived* && "$VR1_CMDLINE" == *"$VR1_CONF"* ]] || { echo "FALLO: el PID de VRRP1 no coincide con su configuración" >&2; exit 1; }
kill -TERM "$VR1_PID_VALUE"
VIP_BACKUP=0
for _ in $(seq 1 12); do
  if ip netns exec "$VR2" ip -4 -o addr show dev lan0 | grep -q '10\.40\.0\.1/24'; then VIP_BACKUP=1; break; fi
  sleep 1
done
[ "$VIP_BACKUP" = 1 ] || { echo "FALLO: Dist2 no tomó la VIP tras la caída de Dist1" >&2; exit 1; }
ip netns exec "$VC" ping -c 2 -W 2 10.40.0.1 >/dev/null
cleanup

# Reversión final: comprueba que todas las topologías y enlaces temporales desaparecen.
cleanup
for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then
    echo "FALLO: quedó namespace residual $ns" >&2; exit 1
  fi
done
for dev in "${HOST_LINKS[@]}"; do
  if ip link show "$dev" >/dev/null 2>&1; then echo "FALLO: quedó interfaz host residual $dev" >&2; exit 1; fi
done

# Prueba funcional 7: continuidad entre laboratorios y preservación de recursos ajenos.
PARENT="nlci_parent_${SUF}"; CHILD="nlci_child_${SUF}"; FOREIGN="nlci_foreign_${SUF}"; FOREIGN_LINK="nf${SUF}"
NAMESPACES+=("$PARENT" "$CHILD")
ip netns add "$PARENT"; ip netns add "$CHILD"; ip netns add "$FOREIGN"
trap 'cleanup; ip netns del "$FOREIGN" 2>/dev/null || true; ip link del "$FOREIGN_LINK" 2>/dev/null || true' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
ip netns exec "$PARENT" ip link set lo alias networking-lab-owned
ip netns exec "$CHILD" ip link set lo alias networking-lab-owned
ip netns exec "$FOREIGN" ip link set lo alias external-test
HOST_LINKS+=("nli_p_${SUF}" "nli_c_${SUF}")
ip link add "nli_p_${SUF}" type veth peer name "nli_c_${SUF}"
ip link set "nli_p_${SUF}" netns "$PARENT"; ip link set "nli_c_${SUF}" netns "$CHILD"
ip netns exec "$PARENT" ip addr add 10.99.0.1/30 dev "nli_p_${SUF}"
ip netns exec "$CHILD" ip addr add 10.99.0.2/30 dev "nli_c_${SUF}"
ip netns exec "$PARENT" ip link set "nli_p_${SUF}" up
ip netns exec "$CHILD" ip link set "nli_c_${SUF}" up
ip netns exec "$PARENT" ping -c 2 -W 2 10.99.0.2 >/dev/null
ip link add "$FOREIGN_LINK" type dummy
# Simula la limpieza del laboratorio hijo: el namespace heredado debe continuar.
ip netns del "$CHILD"
if ! ip netns list | awk '{print $1}' | grep -qx "$PARENT"; then
  echo "FALLO: la limpieza del laboratorio hijo eliminó el namespace heredado" >&2; exit 1
fi
cleanup
if ! ip netns list | awk '{print $1}' | grep -qx "$FOREIGN"; then
  echo "FALLO: se eliminó un namespace ajeno" >&2; exit 1
fi
if ! ip link show "$FOREIGN_LINK" >/dev/null 2>&1; then
  echo "FALLO: se eliminó una interfaz ajena del host" >&2; exit 1
fi
ip netns del "$FOREIGN"
ip link del "$FOREIGN_LINK"

# Prueba funcional 8: reenvío/NAT en el host y restauración exacta de su estado previo.
HOST_NS_IN="nlci_hin_${SUF}"
HOST_NS_OUT="nlci_hout_${SUF}"
HOST_LINK_IN="nlci_hin_${SUF}"
HOST_LINK_OUT="nlci_hout_${SUF}"
HOST_PEER_IN="nlci_pin_${SUF}"
HOST_PEER_OUT="nlci_pout_${SUF}"
NAMESPACES+=("$HOST_NS_IN" "$HOST_NS_OUT")
HOST_LINKS+=("$HOST_LINK_IN" "$HOST_LINK_OUT")
ip netns add "$HOST_NS_IN"
ip netns add "$HOST_NS_OUT"
ip link add "$HOST_LINK_IN" type veth peer name "$HOST_PEER_IN"
ip link add "$HOST_LINK_OUT" type veth peer name "$HOST_PEER_OUT"
ip link set "$HOST_PEER_IN" netns "$HOST_NS_IN"
ip link set "$HOST_PEER_OUT" netns "$HOST_NS_OUT"
ip addr add 198.18.0.1/30 dev "$HOST_LINK_IN"
ip addr add 203.0.113.1/30 dev "$HOST_LINK_OUT"
ip netns exec "$HOST_NS_IN" ip addr add 198.18.0.2/30 dev "$HOST_PEER_IN"
ip netns exec "$HOST_NS_OUT" ip addr add 203.0.113.2/30 dev "$HOST_PEER_OUT"
ip link set "$HOST_LINK_IN" up; ip link set "$HOST_LINK_OUT" up
ip netns exec "$HOST_NS_IN" ip link set "$HOST_PEER_IN" up
ip netns exec "$HOST_NS_OUT" ip link set "$HOST_PEER_OUT" up
ip netns exec "$HOST_NS_IN" ip route add default via 198.18.0.1
ip netns exec "$HOST_NS_OUT" ip route add default via 203.0.113.1
HOST_IP_FORWARD_ORIG=$(sysctl -n net.ipv4.ip_forward)
sysctl -w net.ipv4.ip_forward=1 >/dev/null
HOST_IP_FORWARD_CHANGED=1
if [[ "$FIREWALL_BACKEND" == nft ]]; then
  HOST_NFT_TABLE="nlci_host_${SUF}"
  nft add table inet "$HOST_NFT_TABLE"
  nft "add chain inet $HOST_NFT_TABLE forward { type filter hook forward priority filter; policy drop; }"
  nft "add chain inet $HOST_NFT_TABLE postrouting { type nat hook postrouting priority srcnat; }"
  nft add rule inet "$HOST_NFT_TABLE" forward iifname "$HOST_LINK_IN" oifname "$HOST_LINK_OUT" ip saddr 198.18.0.0/30 ip daddr 203.0.113.0/30 icmp type echo-request accept
  nft add rule inet "$HOST_NFT_TABLE" forward iifname "$HOST_LINK_OUT" oifname "$HOST_LINK_IN" ct state established,related accept
  nft add rule inet "$HOST_NFT_TABLE" postrouting oifname "$HOST_LINK_OUT" ip saddr 198.18.0.0/30 masquerade
  nft list table inet "$HOST_NFT_TABLE" >/dev/null
elif [[ "$FIREWALL_BACKEND" == iptables ]]; then
  HOST_IPTABLES_NAT_MARKER="/tmp/nlci-host-nat-${SUF}.added"
  HOST_IPTABLES_FORWARD_OUT_MARKER="/tmp/nlci-host-forward-out-${SUF}.added"
  HOST_IPTABLES_FORWARD_IN_MARKER="/tmp/nlci-host-forward-in-${SUF}.added"
  TEMP_FILES+=("$HOST_IPTABLES_NAT_MARKER" "$HOST_IPTABLES_FORWARD_OUT_MARKER" "$HOST_IPTABLES_FORWARD_IN_MARKER")
  touch "$HOST_IPTABLES_NAT_MARKER"
  iptables -t nat -I POSTROUTING 1 -s 198.18.0.0/30 -o "$HOST_LINK_OUT" -j MASQUERADE
  touch "$HOST_IPTABLES_FORWARD_OUT_MARKER"
  iptables -I FORWARD 1 -i "$HOST_LINK_IN" -o "$HOST_LINK_OUT" -s 198.18.0.0/30 -d 203.0.113.0/30 -p icmp --icmp-type echo-request -j ACCEPT
  touch "$HOST_IPTABLES_FORWARD_IN_MARKER"
  iptables -I FORWARD 1 -i "$HOST_LINK_OUT" -o "$HOST_LINK_IN" -d 198.18.0.0/30 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
fi
ip netns exec "$HOST_NS_IN" ping -c 2 -W 1 203.0.113.2 >/dev/null || { echo "FALLO: el host no reenvía/NATea el tráfico de prueba" >&2; exit 1; }
cleanup
[[ "$(sysctl -n net.ipv4.ip_forward)" == "$HOST_IP_FORWARD_ORIG" ]] || { echo "FALLO: ip_forward del host no se restauró" >&2; exit 1; }
if [[ -n "$HOST_NFT_TABLE" ]] && nft list table inet "$HOST_NFT_TABLE" >/dev/null 2>&1; then echo "FALLO: quedó tabla nft temporal del host" >&2; exit 1; fi
if [[ -n "$HOST_IPTABLES_NAT_MARKER" ]] && iptables -t nat -C POSTROUTING -s 198.18.0.0/30 -o "$HOST_LINK_OUT" -j MASQUERADE 2>/dev/null; then echo "FALLO: quedó regla NAT temporal del host" >&2; exit 1; fi
if [[ -n "$HOST_IPTABLES_FORWARD_OUT_MARKER" ]] && iptables -C FORWARD -i "$HOST_LINK_IN" -o "$HOST_LINK_OUT" -s 198.18.0.0/30 -d 203.0.113.0/30 -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null; then echo "FALLO: quedó regla FORWARD de salida temporal" >&2; exit 1; fi
if [[ -n "$HOST_IPTABLES_FORWARD_IN_MARKER" ]] && iptables -C FORWARD -i "$HOST_LINK_OUT" -o "$HOST_LINK_IN" -d 198.18.0.0/30 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; then echo "FALLO: quedó regla FORWARD de retorno temporal" >&2; exit 1; fi
[[ ! -e "/sys/class/net/$HOST_LINK_IN" && ! -e "/sys/class/net/$HOST_LINK_OUT" ]] || { echo "FALLO: quedaron interfaces host temporales" >&2; exit 1; }
trap - EXIT INT TERM
echo "OK: L2/FDB, routing, firewall, VLAN 802.1Q, GRE, IPsec, DHCP/DNS, VRRP, continuidad entre labs, preservación de recursos ajenos, cambios host y reversión verificados; backend de firewall: ${FIREWALL_BACKEND:-no disponible}"
