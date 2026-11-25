---
title: "MÉTODO DE DIAGNÓSTICO"
description: "Un esquema común para razonar desde el síntoma hasta la causa en los laboratorios de NETWORKING Lab."
---

<p class="tema-eyebrow">REFERENCIA</p>

# MÉTODO DE DIAGNÓSTICO

Configurar una red permite construir su funcionamiento; diagnosticarla permite comprender qué ocurre cuando ese funcionamiento cambia o falla. Por eso, además de aprender comandos y herramientas, es necesario desarrollar un método de investigación que permita formular hipótesis, obtener evidencias, interpretar resultados y determinar la causa de una incidencia.

Este método se aplica progresivamente en los laboratorios y proporciona una base para abordar problemas de red de manera ordenada. Se resume en cinco pasos:

## El esquema en cinco pasos

```mermaid
flowchart LR
    A(["1. Síntoma"]) --> B["2. Capa o mecanismo"]
    B --> C["3. Herramientas"]
    C --> D["4. Evidencia"]
    D --> E(["5. Conclusión técnica"])
```

| Paso | Pregunta | Ejemplo: «el usuario no puede acceder a un servicio» |
|------|----------|--------------------------------------------------------|
| **1. Síntoma** | ¿Qué falla exactamente, para quién y desde cuándo? | Solo Finanzas, desde que cambió el firewall |
| **2. Capa o mecanismo** | ¿Conectividad, ruta, nombre, firewall o aplicación? | Probablemente firewall (afecta a un solo origen) |
| **3. Herramientas** | ¿Qué comando separa las hipótesis? | `ping`, `ip route get`, `nft list`, `ss`, `tcpdump` |
| **4. Evidencia** | ¿Qué funciona y dónde aparece el problema? | Hay ruta y respuesta ARP; los paquetes llegan y no salen |
| **5. Conclusión** | ¿Cuál es la causa probable y la solución? | Falta una regla en `forward` para ese origen |

## De lo simple a lo específico

```mermaid
flowchart TD
    S(["Síntoma"]) --> A{"¿Responde ping a la IP?"}
    A -- No --> B{"¿Hay ruta y gateway? ip route get, traceroute"}
    B -- No --> B1["Ruta, gateway o enlace"]
    B -- Sí --> B2["Filtrado ICMP o equipo apagado: capturar con tcpdump"]
    A -- Sí --> C{"¿Resuelve el nombre? dig"}
    C -- No --> C1["DNS"]
    C -- Sí --> D{"¿Abre el puerto? nc -zv, ss"}
    D -- No --> D1["Firewall o servicio"]
    D -- Sí --> E{"¿Va lento? iperf3, mtr"}
    E -- Sí --> E1["Pérdida, MTU o saturación"]
    E -- No --> E2["Aplicación"]
    class B1,B2,C1,D1,E1 sxMonitor
```

## Síntomas, herramientas y causas

| Síntoma | Herramientas | Causas posibles |
|---------|--------------|-----------------|
| No llega a la IP | `ip route get`, `traceroute`, `mtr` | Falta ruta o *gateway*, enlace caído, ICMP filtrado |
| Llega a la IP pero no al nombre | `dig`, `resolv.conf` | DNS caído, nombre inexistente, DNS mal anunciado por DHCP |
| Resuelve pero el puerto no abre | `nc -zv`, `ss -tlnp`, `tcpdump` | Regla `DROP`, servicio detenido, escucha en otra IP |
| Conecta pero va lento | `iperf3`, `mtr`, `ping -s` | Pérdida, fragmentación por MTU, saturación |
| Funciona a veces | Capturas, registros, `mtr` | Rutas que alternan, pérdida intermitente |
| Los clientes no obtienen IP | `tcpdump port 67 or port 68`, `nft list` | DHCP no recibe (firewall en `input`), rango agotado |
| Se pierde la adyacencia OSPF | `vtysh -c "show ip ospf neighbor"`, `tcpdump proto ospf` | Protocolo 89 bloqueado, MTU distinta, enlace caído |

## Orden de diagnóstico por capas

El orden siguiente reduce hipótesis; no se salta directamente a cambiar reglas:

1. **Enlace/interfaz:** `ip -s link`, `ip link`, MTU, estado de veth/bridge y contadores.
2. **Capa 2:** `bridge fdb show`, `bridge vlan show`, `ip neigh`, ARP y captura Ethernet.
3. **Capa 3:** `ip addr`, `ip route`, `ip route get`, `ip rule`, traceroute y TTL.
4. **Transporte:** puertos, `ss`, TCP/UDP, conntrack, retransmisiones y estados.
5. **Servicios:** DHCP, DNS, [HTTP/HTTPS](https://www.rfc-editor.org/rfc/rfc9110) y SSH; distingue timeout, NXDOMAIN, rechazo y error TLS.
6. **Seguridad:** INPUT/FORWARD/OUTPUT, NAT, contadores, políticas XFRM y estado de túneles.
7. **Aplicación/operación:** logs con hora sincronizada, métricas, alertas y correlación temporal.

### Estándar de informe de incidencia

Cada diagnóstico debe registrar: síntoma y alcance; hora de inicio y zona horaria; hipótesis iniciales; pruebas realizadas y resultado; evidencia en ambos extremos cuando sea posible; causa raíz o nivel de confianza; impacto; corrección; validación posterior; reversión y riesgo residual. Una pérdida en un salto intermedio de MTR no demuestra pérdida de tránsito si los saltos posteriores responden normalmente: algunos routers limitan ICMP de control.

## Cinco situaciones para practicar

Cada una se resuelve **razonando** con las herramientas ya vistas; no hace falta construir una topología nueva.

1.  **Un usuario alcanza el *gateway* pero no una aplicación.** Pistas: `ip route get`, `ss` en el servidor, regla en el firewall. ¿Es de ruta, de servicio o de política?
2.  **OSPF pierde una adyacencia.** Pistas: estado de los vecinos, captura del protocolo 89, regla `input`. ¿El problema es del enlace o del filtrado?
3. **El firewall permite el tráfico pero el servicio no es accesible desde fuera.** Pista: ¿existe la traducción de destino (DNAT)? Permitir el reenvío no publica un servicio.
4.  **El *gateway* responde pero no hay salida a Internet.** Pista: ¿el *gateway* tiene una WAN operativa y NAT? (Caso B del laboratorio 15.)
5.  **Una aplicación funciona pero con degradación.** Pistas: `iperf3` (pérdida y *jitter*), `ping -M do -s` (MTU), `mtr` (en qué salto empieza).

!!! note "Qué se espera del razonamiento"
    No hay una única respuesta correcta: lo importante es **descartar capas con evidencia**, no probar comandos al azar. Anota en cada caso qué descartaste y con qué comando.

Véase también: [Comparaciones conceptuales](comparaciones.md) · [Servicios, protocolos y puertos](servicios-puertos.md).
