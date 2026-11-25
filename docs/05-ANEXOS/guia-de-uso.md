---
title: "Guía de uso, alcance y convenciones"
description: "Alcance, metodología, lectura de ejemplos, requisitos y seguridad operativa de NETWORKING Lab."
---

# GUÍA DE USO, ALCANCE Y CONVENCIONES


Esta guía reúne las instrucciones necesarias para interpretar y ejecutar las prácticas de NETWORKING Lab. Explica su alcance, metodología, convenciones de lectura, requisitos y medidas de seguridad.

## 1. Alcance: qué son y qué no son

Son **representaciones didácticas** construidas principalmente con *namespaces* de red de [Linux](https://docs.kernel.org/): simplifican la realidad para explicar cómo funciona cada tecnología. **No** son procedimientos de implementación profesional ni reproducen todos los componentes de una infraestructura real. Un ejemplo explica correctamente un proceso cuando **representa correctamente ese proceso**; cuando una simplificación afecta a lo explicado (por ejemplo, rutas [IP](https://www.rfc-editor.org/rfc/rfc791) estáticas en lugar de [MPLS](https://www.rfc-editor.org/rfc/rfc3031) real), la página lo indica.


### Qué se espera aprender

Al completar las prácticas, el lector debería poder explicar cómo funcionan los mecanismos de red estudiados, interpretar las evidencias que producen y razonar sobre sus límites. Aprender redes consiste en configurar, observar, interpretar y diagnosticar; ejecutar comandos es solo el medio. Expresiones como «implementación práctica integral» designan un ejercicio de integración didáctico, no un despliegue de producción: el laboratorio 15 no reúne en ejecución todas las tecnologías de los quince laboratorios (véase la [arquitectura integral](../04-REFERENCIA/arquitectura-integral.md)).

## 2. Organización de los laboratorios

El proyecto consta de **15 laboratorios**, relacionados con los temas del libro. Los une una narrativa de simulación de entorno laboral: **Networking SecOps**, una empresa ficticia que parte de una oficina sin red y crece hasta una infraestructura multisede. Cada laboratorio abre con la situación de la empresa y cierra con el punto al que llega su red; la historia es el hilo conductor y no implica que los recursos persistan entre prácticas. Cada práctica sigue, cuando corresponde, esta secuencia técnica:

1. Presentar la situación de la empresa y la necesidad que origina el laboratorio.
2. Presentar la infraestructura que se construye y el comportamiento que se observa.
3. Delimitar el escenario, los dispositivos, las redes y el direccionamiento.
4. Preparar el entorno y declarar dependencias.
5. Aplicar la configuración de forma progresiva.
6. Explicar la función de los comandos y parámetros relevantes.
7. Verificar cada etapa con evidencias observables.
8. Distinguir la salida real, la salida representativa y el resultado esperado.
9. Explicar limitaciones, limpieza y reversión cuando proceda.
10. Cerrar con el estado final y el siguiente paso de la empresa.

Esa secuencia se traduce en una **estructura de secciones** común a los quince laboratorios:

| Sección | Contenido | Presencia |
|---|---|---|
| **Apertura narrativa** | Primera sección de cada laboratorio: «¡Bienvenido!» en el primero y encabezados breves en los siguientes, que continúan la historia de Networking SecOps y plantean la necesidad que origina el laboratorio. | Todos |
| **Introducción técnica** | Infraestructura que se construye y comportamiento que se observa. | Todos |
| **Objetivos de aprendizaje** | Qué podrá explicar, interpretar o realizar el lector, con sus conocimientos previos y la relación con la práctica anterior. | Todos |
| **Estado inicial** | Qué existe y qué falta al comenzar. | Todos |
| **Resultado que se construirá** | Topología resultante y observaciones previstas. | Todos |
| **Fundamento necesario** y **Herramientas necesarias** | Conceptos y paquetes requeridos antes de la construcción. | Cuando corresponde |
| **Topología** | Dispositivos, redes y direcciones. | Todos |
| **Construcción** (pasos y verificación) | Comandos, función de cada uno y comprobación de cada etapa. | Todos |
| **Análisis**, **observación** y **profundización** | Por qué el sistema se comporta así y dónde están sus límites. | Según el laboratorio |
| **Pruebas de comportamiento** | Cambios controlados sobre una configuración funcional y su efecto. | Según el laboratorio |
| **Diagnóstico de problemas frecuentes** | Síntomas, causas probables y soluciones. | Según el laboratorio |
| **Conceptos clave** | Resumen de las ideas aplicadas en la práctica. | Según el laboratorio |
| **Qué no demuestra esta práctica** | Simplificaciones de la representación y conclusiones que no pueden extraerse de ella. | Todos |
| **Comprensión y reflexión** | Ejercicios de reconocimiento, interpretación y razonamiento, un caso de diagnóstico y respuestas orientativas. | Todos |
| **Limpieza** o **Revertir los cambios del host** | Restauración del equipo a su estado previo. | Todos (en el laboratorio 14 es el último paso de la construcción) |
| **Estado final** | Lo implementado y los límites de la representación. | Todos |
| **Continuidad técnica** | Punto al que llega la red de la empresa y relación con el laboratorio siguiente. | Todos; el 15 cierra la historia |

### Matriz de dependencias técnicas

La narrativa de Networking SecOps continúa siempre; los recursos técnicos no tienen por qué hacerlo. Esta tabla se verificó contra el texto de cada laboratorio:

| Laboratorio | Relación técnica con el anterior | Tipo de escenario |
|---|---|---|
| 01 | Ninguna | Inicial |
| 02 | Usa `cliente1`, `cliente2` y el `router` del 01 | Continuación |
| 03 | Requiere el 02 funcionando y elimina el bridge del `router` | Modificación |
| 04 | Comprueba el estado previo y crea su propia topología tras limpiar nombres coincidentes | Escenario nuevo |
| 05 | No continúa el 04; limpia solo Lab05 | Escenario independiente |
| 06 | Tres routers nuevos; no vuelve a montar las VLAN del 05 | Escenario nuevo |
| 07 | Requiere el 06 funcionando | Continuación |
| 08 | Requiere el 07 funcionando; añade DMZ y seguridad | Continuación (extiende) |
| 09 | Requiere los laboratorios 06 a 08 en pie | Continuación (extiende) |
| 10 | Namespaces propios; conserva `br-wan` del 08 | Escenario nuevo |
| 11 | Reutiliza mecanismos del 05 en otra topología | Escenario nuevo |
| 12 | Namespaces propios; no toca recursos de otras prácticas | Escenario nuevo |
| 13 | Continúa sobre la red del 12 | Continuación |
| 14 | No depende de los anteriores | Independiente |
| 15 | Parte de un entorno vacío | Integrador |


Los laboratorios pueden montar escenarios independientes. No debe suponerse que un dispositivo, interfaz, dirección o namespace conserva el mismo significado entre prácticas: cada laboratorio declara su propia topología y sus recursos.

## 3. Cómo leer las salidas y los ejemplos

| Etiqueta | Significado |
|---|---|
| **Ejemplo de salida** | Resultado representativo; no implica que se haya ejecutado en el equipo del lector. Direcciones, identificadores, tiempos y contadores pueden variar. |
| **Captura de referencia** | Evidencia de una ejecución concreta en el entorno indicado. |
| **Resultado esperado** | Comportamiento que debería producirse bajo las condiciones descritas. |
| **Esquema conceptual** | Representación simplificada de un mecanismo; no es una transcripción literal de paquetes ni una captura. |
| **Verificación** | Comando o comprobación que permite contrastar el estado o resultado descrito. |

La reproducibilidad depende del entorno: los ejemplos se redactaron para un entorno Linux concreto y los comandos pueden variar según la distribución, la versión del kernel o de `iproute2`, los módulos cargados y los privilegios. Cuando un comando requiere una versión reciente, el laboratorio lo advierte y ofrece una alternativa (por ejemplo, `bridge fdb flush` en el laboratorio 03).

No se debe interpretar una salida de ejemplo como garantía de que el comando producirá exactamente los mismos valores en otra distribución, versión del kernel o topología.

## 4. Convenciones de comandos y terminal

- Los bloques identificados como `bash` contienen comandos para la shell Bash; los marcadores de bloque no forman parte del comando.
- Los comandos que requieren privilegios se indican con `sudo`, salvo los laboratorios que declaran expresamente que se ejecutan desde una sesión root.
- En los laboratorios 01 a 05 se asume una sesión root (`sudo -i`) y por ello algunos comandos aparecen sin `sudo`; desde el 06 se muestra explícitamente cuando corresponde.
- Los nombres entre `< >` representan valores que deben sustituirse; los signos angulares no se escriben literalmente salvo que el comando así lo requiera.
- Las direcciones, interfaces, nombres de namespace, rutas y PID deben corresponder al escenario de la práctica activa.
- Los pasos se ejecutan en el orden indicado. Una verificación no se adelanta si el recurso que consulta todavía no está creado o configurado.
- Antes de repetir un laboratorio conviene revisar su sección de limpieza y confirmar que no quedan recursos de una ejecución anterior.
- Los comandos de limpieza globales no sustituyen a la limpieza selectiva del laboratorio.

## 5. Requisitos y preparación

- Linux en una máquina virtual, WSL2 compatible o equipo de pruebas con privilegios de superusuario.
- Conocimientos básicos de Linux: abrir una terminal, ejecutar comandos y manejar archivos y permisos. No se presupone dominio previo de conmutación, enrutamiento, subredes, VPN ni arquitectura empresarial; cada laboratorio explica o remite a los conceptos de red que necesita. El laboratorio 15 es integrador y presupone lo aprendido en los anteriores.
- Herramientas comunes: `sudo apt install tcpdump traceroute iperf3 dnsutils curl`. Cada laboratorio declara paquetes adicionales.
- Algunos escenarios requieren módulos del kernel: `8021q` (05 y 11), `ip_gre` (06 y 09) y `wireguard`, `esp4`/`xfrm_user` y `tun` (09). El laboratorio 15 utiliza `frr`, `keepalived` y `dnsmasq-base`.
- El laboratorio 10 presenta MPLS a nivel conceptual; no requiere `mpls_router`.

!!! warning "Entorno de práctica"
    Los laboratorios pueden crear namespaces, interfaces virtuales, bridges, rutas y reglas de firewall. Se recomienda una máquina virtual o un equipo dedicado a pruebas. Estas prácticas no deben ejecutarse directamente en servidores de producción ni en equipos cuya conectividad sea crítica.

## 6. Cambios en el host y seguridad operativa

Un *namespace* aísla la pila de red que se ejecuta dentro de él, pero **no aísla automáticamente todos los cambios del equipo anfitrión**. Conviene revisar especialmente:

- `net.ipv4.ip_forward` y otros parámetros `sysctl` globales.
- Reglas de firewall o NAT añadidas al host.
- Rutas temporales, bridges e interfaces creados fuera del namespace.
- Módulos del kernel cargados y servicios iniciados.
- Procesos auxiliares que puedan permanecer activos tras cerrar la terminal.

Los pasos que modifican el host se identifican en el laboratorio mediante el aviso **«Cambio en el host»** y deben tener una sección de reversión. Antes de modificar un valor global, registra su estado original; restáuralo al terminar, en lugar de asumir un valor predeterminado.

Como comprobación inicial orientativa:

```bash
sysctl net.ipv4.ip_forward
iptables -t nat -S POSTROUTING
```

La limpieza debe limitarse a recursos creados por la práctica activa. Detén procesos mediante PID registrados o herramientas acotadas como `ip netns pids <namespace>`; evita `pkill` globales o coincidencias amplias de procesos. No elimines interfaces, bridges, reglas o namespaces preexistentes que no pertenezcan al laboratorio.

!!! danger "No trasladar directamente a producción"
    Los comandos son material educativo. Antes de reutilizarlos en una infraestructura real, revisa el alcance, persistencia, impacto, controles de acceso, políticas de firewall, dependencias y procedimiento de reversión.
