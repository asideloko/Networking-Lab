---
title: "REGISTRO DE ATENCIÓN DE LA AUDITORÍA"
description: "Cambios incorporados a los quince laboratorios de NETWORKING Lab a partir de la auditoría técnica y pedagógica."
---

<p class="tema-eyebrow">REFERENCIA · CONTROL DE CAMBIOS</p>

# REGISTRO DE ATENCIÓN DE LA AUDITORÍA

Este registro resume la intervención aplicada a los quince archivos fuente. Se conserva la estructura `docs/labs/lab-XX/index.md`, la secuencia curricular, los objetivos originales y la narrativa de Networking SecOps. Las ampliaciones no convierten las simulaciones en equipos físicos ni las secciones conceptuales en implementaciones de producto.

## Cambios por laboratorio

| Lab | Correcciones y ampliaciones incorporadas |
|---|---|
| **01 · Fundamentos** | Reconstrucción causal de un ping: decisión de ruta, ARP, trama Ethernet, aprendizaje de MAC, FDB, reenvío y caché de vecinos; distinción entre FDB y tabla de vecinos. |
| **02 · Capa física** | Precisión de 100BASE-TX, 1000BASE-T y 10GBASE-T; separación entre codificación, PAM/QAM, bitrate, baud, throughput y goodput; aclaración de que `veth` no mide señales físicas; recuperación del estado `ip_forward` ante una ejecución interrumpida. |
| **03 · Switching** | Algoritmo de aprendizaje por MAC de origen, unicast conocido/desconocido, flooding y envejecimiento; experimentos predictivos; explicación de MTU, DF y PMTUD. |
| **04 · Subredes** | Algoritmo VLSM paso a paso, operación AND, decisión local/gateway y diagnóstico de máscaras incorrectas; ampliación de la detección de interfaces del entorno. |
| **05 · VLAN** | Recorrido de una trama access–trunk–router–access, etiquetas 802.1Q, PVID y VLAN nativa; matriz de fallos; reglas `FORWARD` del host limitadas y reversibles. |
| **06 · Routing** | RIB/FIB, selección por prefijo, ARP del siguiente salto, TTL, ICMP Time Exceeded, métrica frente a calidad y distinción entre fallo local/remoto; underlay/overlay GRE. |
| **07 · Servicios** | DHCP más allá de DORA, T1/T2, lease y relay; resolución DNS, TCP/UDP/QUIC, conntrack y doble NAT; restauración de la LAN original de R1 al retirar `br-lan`. |
| **08 · Seguridad** | Hooks Netfilter y cadenas INPUT/FORWARD/OUTPUT; verificación estricta de host key SSH; SAN en certificados TLS; copia y restauración exacta de `nf_log_all_netns`; restauración de WAN/ruta/NAT original de R1 y borrado de `br-wan` solo con marca de propiedad. |
| **09 · VPN** | Desarrollo de SA/SPI/ESP/AH/SPD/SAD/IKE, límites de manual keying, OpenVPN y WireGuard; overhead dependiente de configuración; retirada selectiva de GRE, rutas, SA, políticas XFRM y reglas de firewall, con restauración de rutas heredadas. |
| **10 · WAN/Core** | Diferencia operativa entre IP y MPLS; CE/PE/P, FEC/LSP/LFIB, VRF, MP-BGP, RD/RT, PHP y pila de etiquetas; ECMP por flujo y distinción MPLS/SD-WAN. |
| **11 · Arquitectura empresarial** | Matriz de disponibilidad por componente; diferenciación entre rutas alternativas, STP/RSTP y VRRP; medición de convergencia y conservación de controles de propiedad de recursos del host. |
| **12 · Arquitecturas modernas** | Identidad frente a dirección IP, componentes reales de ZTNA y límites del broker simulado; registro y detención selectiva de PID de servicios `nc`; precisión sobre nube y conectividad representadas. |
| **13 · Monitoreo** | Límites de rsyslog como colector, comparación UDP/TCP/TLS, sincronización NTP, retención, interpretación de MTR y evidencia para informes de incidentes; límites de mediciones sobre veth. |
| **14 · Herramientas Linux** | Policy routing con `ip rule`, tablas alternativas y `ip route get from`; alcance real de `ethtool` en veth frente a NIC física; diagnóstico cruzado con `ss`, `tcpdump` y nftables. |
| **15 · Integración** | Precisión del alcance real; RIB/LSDB/SPF/FIB; DNS interno opcional con dnsmasq; matriz de disponibilidad por segmento; limitación de TCPMSS a R1 y a un flujo; propiedad de OVS; PID files en lugar de `pkill -f`; caracterización correcta del ejercicio ARP; proyecto final evaluable. |

## Recursos transversales

- `docs/referencia/arquitectura-integral.md`: separa lo ejecutable, lo simulado y lo conceptual en cada área.
- `docs/referencia/diagnostico.md`: establece un orden de diagnóstico por capas y un formato de informe de incidencia.
- `docs/referencia/competencias.md`: convierte las competencias en evidencias verificables y añade una rúbrica del proyecto final.
- `scripts/validar.py`: amplía los controles estáticos de reversión, propiedad de recursos, SSH, OVS, XFRM y TCPMSS; valida también la sintaxis del test funcional.
- `scripts/pruebas_funcionales.sh`: añade una prueba aislada de bridge/FDB, routing, firewall y limpieza.
- `.github/workflows/docs.yml`: ejecuta la prueba funcional de red en CI después de la validación documental.

## Validación y límites

| Validación | Estado en esta intervención |
|---|---|
| Correspondencia entre `labs.md` y los 15 archivos del ZIP | Verificada antes de modificar: los 15 títulos y contenidos corresponden a los archivos individuales. |
| Sintaxis Bash de los bloques Markdown | Superada mediante `scripts/validar.py`. |
| Controles estáticos de reversión/seguridad | Superados mediante `scripts/validar.py`. |
| Sintaxis del script funcional | Superada con `bash -n`. |
| Ejecución funcional de namespaces en este entorno | No ejecutable aquí: el contenedor no concede `CAP_SYS_ADMIN/CAP_NET_ADMIN`; el script informa `SKIP` y el workflow lo intentará en el runner de GitHub. |
| Construcción local con Zensical | No verificada: el paquete no está instalado y el entorno no tiene acceso a Internet para instalar `zensical==0.1.2`. El workflow conserva el build oficial. |
| Validación en VM Linux real de los 15 laboratorios | Pendiente; no se declara como ejecutada. |

El resultado es una revisión documental y estática reforzada, más una prueba funcional aislada incorporada al pipeline. No debe interpretarse como certificación de que las quince topologías completas se hayan ejecutado en una VM real.
