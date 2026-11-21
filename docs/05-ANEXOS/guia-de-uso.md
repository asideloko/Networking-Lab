---
title: "Guía de uso, alcance y convenciones"
description: "Alcance, metodología, lectura de ejemplos, requisitos y seguridad operativa de NETWORKING Lab."
---

# GUÍA DE USO, ALCANCE Y CONVENCIONES


Esta guía reúne las instrucciones necesarias para interpretar y ejecutar las prácticas de NETWORKING Lab. Explica su alcance, metodología, convenciones de lectura, requisitos y medidas de seguridad.

## 1. Alcance: qué son y qué no son

Son **representaciones didácticas** construidas principalmente con *namespaces* de red de [Linux](https://docs.kernel.org/): simplifican la realidad para explicar cómo funciona cada tecnología. **No** son procedimientos de implementación profesional ni reproducen todos los componentes de una infraestructura real. Un ejemplo explica correctamente un proceso cuando **representa correctamente ese proceso**; cuando una simplificación afecta a lo explicado (por ejemplo, rutas [IP](https://www.rfc-editor.org/rfc/rfc791) estáticas en lugar de [MPLS](https://www.rfc-editor.org/rfc/rfc3031) real), la página lo indica.


## 2. Organización y metodología de los laboratorios

El proyecto consta de **15 laboratorios**, relacionados con los temas del libro. Cada práctica sigue, cuando corresponde, este recorrido didáctico:

1. Presentar el contexto y el objetivo técnico.
2. Identificar los conceptos y mecanismos que se van a observar.
3. Delimitar el escenario, los dispositivos, las redes y el direccionamiento.
4. Preparar el entorno y declarar dependencias.
5. Aplicar la configuración de forma progresiva.
6. Explicar la función de los comandos y parámetros relevantes.
7. Verificar cada etapa con evidencias observables.
8. Distinguir la salida real, la salida representativa y el resultado esperado.
9. Explicar limitaciones, limpieza y reversión cuando proceda.
10. Cerrar con conclusiones y preguntas de reflexión.

Ese recorrido se traduce en una **estructura de secciones** común a los quince laboratorios. Conocerla permite saber qué esperar de cada parte y dónde buscar una respuesta:

| Sección | Qué responde | Presencia |
|---|---|---|
| **Contexto empresarial** | ¿Qué necesita la empresa Networking SecOps y por qué ahora? Continúa la historia del laboratorio anterior. | Todos |
| **Problema inicial** | ¿Qué falta o qué falla hoy? | Todos |
| **Objetivos del laboratorio** | ¿Qué sabrás hacer al terminar? | Todos |
| **Conceptos previos** y **Herramientas necesarias** | ¿Qué debo saber e instalar antes de empezar? | Cuando corresponde |
| **Topología** | ¿Qué se construye, con qué dispositivos y direcciones? | Todos |
| **Construcción** (pasos y verificación) | ¿Cómo se construye y cómo compruebo cada etapa? | Todos |
| **Análisis**, **observación** y **profundización** | ¿Por qué funciona así y dónde están sus límites? | Según el laboratorio |
| **Ejercicios** | ¿Puedo aplicarlo a otro caso? | Según el laboratorio |
| **Errores comunes y soluciones** | ¿Qué suele fallar y cómo se resuelve? | Según el laboratorio |
| **Conceptos clave** | ¿Cuáles son las ideas que debo retener? | Según el laboratorio |
| **Preguntas de reflexión** | ¿Puedo razonar sobre lo aprendido sin los comandos? | Todos |
| **Conclusiones técnicas** | ¿Qué se demostró y qué limita a la representación? | Todos |
| **Limpieza** o **Revertir los cambios del host** | ¿Cómo dejo el equipo como estaba? | Todos (en el laboratorio 14 es el último paso de la construcción) |
| **Preparación para el siguiente laboratorio** | ¿Cómo continúa la historia? | Todos; el 15 apunta al Proyecto final |

Los laboratorios pueden montar escenarios independientes. No debe suponerse que un dispositivo, interfaz, dirección o namespace conserva el mismo significado entre prácticas: cada laboratorio declara su propia topología y sus recursos.

## 3. Cómo leer las salidas y los ejemplos

| Etiqueta | Significado |
|---|---|
| **Ejemplo de salida** | Resultado representativo; no implica que se haya ejecutado en el equipo del lector. Direcciones, identificadores, tiempos y contadores pueden variar. |
| **Captura de referencia** | Evidencia de una ejecución concreta en el entorno indicado. |
| **Resultado esperado** | Comportamiento que debería producirse bajo las condiciones descritas. |
| **Esquema conceptual** | Representación simplificada de un mecanismo; no es una transcripción literal de paquetes ni una captura. |
| **Verificación** | Comando o comprobación que permite contrastar el estado o resultado descrito. |

No se debe interpretar una salida de ejemplo como garantía de que el comando producirá exactamente los mismos valores en otra distribución, versión del kernel o topología.

## 4. Convenciones de comandos y terminal

- Los bloques identificados como `bash` contienen comandos para la shell Bash; no copies los marcadores de bloque.
- Los comandos que requieren privilegios se indican con `sudo`, salvo los laboratorios que declaran expresamente que se ejecutan desde una sesión root.
- En los laboratorios 01 a 05 se asume una sesión root (`sudo -i`) y por ello algunos comandos aparecen sin `sudo`; desde el 06 se muestra explícitamente cuando corresponde.
- Los nombres entre `< >` representan valores que debes sustituir; no escribas literalmente los signos angulares salvo que el comando así lo requiera.
- Las direcciones, interfaces, nombres de namespace, rutas y PID deben corresponder al escenario de la práctica activa.
- Ejecuta los pasos en el orden indicado. No adelantes una verificación si aún no has creado o configurado el recurso que consulta.
- Antes de repetir un laboratorio, revisa su sección de limpieza y confirma que no quedan recursos de una ejecución anterior.
- No ejecutes comandos de limpieza globales como sustituto de la limpieza selectiva del laboratorio.

## 5. Requisitos y preparación

- Linux en una máquina virtual, WSL2 compatible o equipo de pruebas con privilegios de superusuario.
- Conocimientos básicos de terminal, direccionamiento IP y administración Linux.
- Herramientas comunes: `sudo apt install tcpdump traceroute iperf3 dnsutils curl`. Cada laboratorio declara paquetes adicionales.
- Algunos escenarios requieren módulos del kernel: `8021q` (05 y 11), `ip_gre` (06 y 09) y `wireguard`, `esp4`/`xfrm_user` y `tun` (09). El laboratorio 15 utiliza `frr`, `keepalived` y `dnsmasq-base`.
- El laboratorio 10 presenta MPLS a nivel conceptual; no requiere `mpls_router`.

!!! warning "Entorno de práctica"
    Los laboratorios pueden crear namespaces, interfaces virtuales, bridges, rutas y reglas de firewall. Utiliza una máquina virtual o un equipo dedicado a pruebas. No ejecutes estas prácticas directamente en servidores de producción ni en equipos cuya conectividad sea crítica.

## 6. Cambios en el host y seguridad operativa

Un *namespace* aísla la pila de red que se ejecuta dentro de él, pero **no aísla automáticamente todos los cambios del equipo anfitrión**. Revisa especialmente:

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

## 7. Convención visual de diagramas

Los diagramas se escriben en Mermaid y se presentan con el tema claro u oscuro del sitio. Las referencias normativas se separan por su alcance: una norma de símbolos no es automáticamente una norma de colores, y una norma de colores de seguridad no define cómo colorear routers, servidores o procesos.

### 7.1 Normas y referencias aplicables

1. **[ISO 5807:1985 — Information processing: Documentation symbols and conventions for data, program and system flowcharts, program network charts and system resources charts](https://www.iso.org/standard/11955.html).** Es la referencia para seleccionar y utilizar símbolos en diagramas de flujo de datos, programas, sistemas, redes de programas y recursos de sistema. La ficha oficial de ISO indica que fue confirmada en 2019 y continúa vigente. Se aplica a la notación de los flujos cuando el tipo de diagrama corresponde; no establece la paleta de este proyecto ni una taxonomía cromática de dispositivos de red.
2. **[W3C — Web Content Accessibility Guidelines (WCAG) 2.2, criterio 1.4.1 «Use of Color»](https://www.w3.org/TR/WCAG22/#use-of-color).** Es el criterio de accesibilidad aplicable a la presentación web: el color no puede ser el único medio visual para transmitir información o distinguir elementos. Por eso cada categoría también debe reconocerse mediante texto, forma, flechas o leyenda.
3. **[ANSI/NEMA Z535.1-2022 — Safety Colors](https://webstore.ansi.org/standards/nema/ansiz5352022-2475871).** Especifica colores de seguridad y sus tolerancias. Su alcance es la señalización y comunicación de seguridad; no asigna violeta a infraestructura, índigo a servicios ni otros colores a categorías de diagramas de redes. Por tanto, no se presenta como fundamento de la paleta funcional del proyecto.
4. **[ISO 3864-1:2011](https://www.iso.org/standard/51021.html) e [ISO 3864-4:2011](https://www.iso.org/standard/51000.html).** Tratan los principios de diseño y las propiedades colorimétricas/fotométricas de colores y señales de seguridad. Son pertinentes cuando un gráfico incorpora señalización de seguridad normalizada; no definen la codificación cromática de los componentes de una arquitectura de red.

**Límite normativo importante:** no se ha identificado una norma ISO, IEC, IEEE, ANSI o IETF que prescriba un color para los routers, los servidores, los firewalls o los procesos de un diagrama de red. Afirmar que la asignación de este proyecto procede de ISO 5807, ANSI Z535.1 o ISO 3864 sería incorrecto. La asignación que sigue es una **convención editorial propia de NETWORKING Lab**: las cajas de resaltado usan cuatro colores por la gravedad del aviso y los diagramas usan doce categorías por la función del elemento. No es una certificación ni una codificación normativa universal.

### 7.2 Convención cromática del proyecto

La paleta tiene **dos capas**. Cada color tiene **una única función**, y todo se define en un solo lugar (`stylesheets/extra.css`; las reglas de asignación, en `javascripts/custom.js`).

**A. Cajas de resaltado: cuatro colores.** El tipo de caja fija el color.

| Color | Función | Se escribe | Cuándo se usa | Ejemplo |
|---|---|---|---|---|
| <span class="sx-dot" style="background:#2196D2"></span> Azul | **Nota / Aviso** | `note` | Contexto, alcance, continuidad entre laboratorios. Ignorarlo no tiene consecuencias. | «Continuidad con el laboratorio 04» |
| <span class="sx-dot" style="background:#10B981"></span> Verde | **Dato técnico** | `info`, `tip`, `success` | Hecho técnico que hay que retener y soluciones razonadas de los ejercicios. | «MAC frente a IP» |
| <span class="sx-dot" style="background:#F59E0B"></span> Amarillo | **Advertencia** | `warning` | Limitación, simplificación didáctica o malentendido frecuente. Puede inducir a error. | «Habilitar SSH no equivale a asegurar el servicio» |
| <span class="sx-dot" style="background:#EF4444"></span> Rojo | **Peligro / Error crítico** | `danger` | Cambios en el host fuera de un *namespace* y todo lo que no debe llevarse a producción. Puede causar daño o pérdida. | «Cambio en el host» |

**B. Diagramas: paleta «Cyberpunk» de doce categorías.** En un diagrama el color identifica la **función del elemento**. El estilo es el mismo en todos: **contorno luminoso** del color de la categoría y **fondo translúcido teñido** del mismo color.

| Categoría y color | Clase | Representa | Justificación |
|---|---|---|---|
| <span class="sx-dot d-infra"></span> 01 · Infraestructura de red `#5B14CC` | `sxInfra` | Router, switch, bridge, núcleo, distribución, acceso, gateway | Es el esqueleto de toda topología y la categoría más frecuente; conserva el violeta de la marca del libro. |
| <span class="sx-dot d-zone"></span> 02 · Segmentación y zonas `#10B981` | `sxZone` | LAN, VLAN, subredes, DMZ, segmentos | La red es el medio y la frontera de confianza, no un equipo. |
| <span class="sx-dot d-system"></span> 03 · Sistemas y servidores `#F59E0B` | `sxSystem` | Servidor web, servidor de aplicaciones, servidor DNS (la máquina) | Separa la máquina que aloja del servicio que presta. |
| <span class="sx-dot d-user"></span> 04 · Usuarios y terminales `#EF4444` | `sxUser` | Clientes, PC, usuarios remotos, hosts de ventas o administración | Quien consume la red. Se usa un rojo propio de la paleta; en los diagramas no significa peligro. |
| <span class="sx-dot d-service"></span> 05 · Servicios y aplicaciones `#2196D2` | `sxService` | DNS, DHCP, NTP, web, aplicaciones | El servicio concreto que corre sobre un sistema. |
| <span class="sx-dot d-security"></span> 06 · Seguridad `#E65C9C` | `sxSecurity` | Firewall, VPN Gateway, ZTNA, proveedor de identidad, tráfico cifrado | Color propio para que un control de seguridad no se lea como fallo ni como equipo común. |
| <span class="sx-dot d-transport"></span> 07 · Transporte y proveedor `#F28E2B` | `sxTransport` | PE, P, CE, WAN, ISP, GRE, túneles, TCP/UDP | Lo que lleva el tráfico entre sedes y la frontera con el proveedor. |
| <span class="sx-dot d-process"></span> 08 · Procesamiento y operaciones `#00A6A6` | `sxProcess` | NAT, cadenas de filtrado, rutas, encapsulación, push/swap/pop y **decisiones (rombos)** | Algo que ocurre, no algo que existe. Un rombo es siempre una decisión. |
| <span class="sx-dot d-data"></span> 09 · Datos y estructuras `#344F7A` | `sxData` | Bases de datos, cabeceras, tramas, paquetes, tablas | Información y su formato, no quien la procesa. |
| <span class="sx-dot d-monitor"></span> 10 · Monitoreo y diagnóstico `#8C5A3C` | `sxMonitor` | NOC, SIEM, registros, síntomas, causas halladas, fallos | Lo que observa la red y lo que se encuentra al diagnosticarla. |
| <span class="sx-dot d-cloud"></span> 11 · Nube e infraestructura virtual `#8AA61E` | `sxCloud` | VPC, AWS, EC2, RDS, puerta de enlace de Internet | Infraestructura que no es física ni propia. |
| <span class="sx-dot d-external"></span> 12 · Elementos externos y referencia `#737373` | `sxExternal` | Internet, red externa | Lo que está fuera de la organización; también es el gris de lo no clasificado. |

**Por qué doce.** Son las funciones que un lector distingue en una topología, desde el equipo hasta el dato y el diagnóstico. Lo que queda fuera se distingue con la **forma** (círculo = Internet o nube, rombo = decisión) y con el **estilo de línea** (continua = física, discontinua = lógica o de respaldo, gruesa = troncal o preferida), no con un color más. Los túneles y las VPN son una **relación**, no un elemento: se dibujan con línea discontinua y se rotulan.

**Cómo se asigna.** `custom.js` evalúa las reglas en orden y gana la primera coincidencia: primero interfaces (neutro), monitoreo y fallos, operaciones concretas (NAT, cadenas), nube y externos, seguridad, datos, transporte, sistemas, servicios, infraestructura, usuarios, zonas y, por último, procesos. Un rombo es siempre procesamiento. En los casos ambiguos se escribe a mano, al final del diagrama, una línea `class ID sxMonitor` (o la clase que corresponda); **esa línea manda sobre la regla automática**. Ejemplo: en el árbol de diagnóstico, las causas halladas pertenecen a «Monitoreo y diagnóstico» aunque su texto diga «DNS» o «Firewall».

### 7.3 Aplicación gráfica y adaptación de tema

- **Regla visual:** contorno del color de la categoría; relleno translúcido del mismo color; texto con contraste suficiente. No se alteran la geometría, la distribución, la tipografía ni la iconografía de los diagramas.
- **Tema claro:** fondo con tinte muy claro (transparencia alta) y sin brillo. Los contornos de los colores claros (verde, amarillo, naranja, lima) se oscurecen levemente para alcanzar un contraste mínimo de 3:1 con el fondo (WCAG 2.2, 1.4.11).
- **Tema oscuro:** el contorno se aclara (violeta, azul pizarra, marrón y gris) y el fondo es un tinte más profundo con un resplandor sutil. El resplandor **no sustituye** el contraste del contorno.
- **Texto:** siempre en un tono neutro (oscuro en tema claro, claro en tema oscuro), no en el color de la categoría, para garantizar la lectura.
- **Conectores:** siempre grises. Las etiquetas indican si la relación es física, lógica, túnel, ruta, dependencia o flujo de tráfico.
- **Diagramas de secuencia:** los participantes se colorean con las mismas reglas.
- **Una sola paleta:** los fondos se adaptan mediante variables de tema (`--sx-*` en `extra.css`); no hay una segunda paleta duplicada.
- **Accesibilidad:** el color nunca es el único medio (WCAG 2.2, 1.4.1): cada elemento lleva su nombre y esta tabla actúa de leyenda.
- **Límites reconocidos:** con doce categorías hay pares próximos (verde y turquesa, naranja y amarillo, azul pizarra y violeta); se distinguen por contexto, nombre y forma. Y el **rojo** de «Usuarios y terminales» no significa peligro: en las **cajas de resaltado** el rojo sí significa peligro. Son dos sistemas distintos.

### 7.4 Reglas de revisión de cada diagrama

1. El título o texto cercano indica qué aspecto representa.
2. Los nodos tienen nombres inequívocos y no mezclan dispositivos con redes sin distinguirlos.
3. Las flechas tienen dirección coherente con el proceso o tráfico descrito.
4. Las conexiones físicas, lógicas y los flujos de paquetes no se presentan como equivalentes si no lo son.
5. Las decisiones se expresan como condiciones y muestran sus salidas relevantes.
6. Las zonas y límites de confianza se etiquetan.
7. Los colores son consistentes y existe una descripción textual equivalente.
8. El gráfico sigue siendo legible en escala móvil, impresión y ambos temas.

## 8. Referencias y recursos de consulta

- [Diagramación y topologías](diagramacion-y-topologias.md): código fuente, descripción y vínculo al contexto original de los diagramas de laboratorios, proyecto y referencias.
- [Servicios, protocolos y puertos](../04-REFERENCIA/servicios-puertos.md): matriz común de la serie.
- [Comparaciones conceptuales](../04-REFERENCIA/comparaciones.md): bridge/router, MAC/IP, subred/VLAN, GRE/IPsec y otras distinciones.
- [Método de diagnóstico](../04-REFERENCIA/diagnostico.md): secuencia de análisis desde el síntoma hasta la causa.
- [Arquitectura integral](../04-REFERENCIA/arquitectura-integral.md): mapas de síntesis y matriz de disponibilidad.
- [Glosario](../04-REFERENCIA/glosario.md): términos y acrónimos.
- [Competencias y casos integradores](../04-REFERENCIA/competencias.md): resultados esperados y ejercicios de repaso.
- [Proyecto final integrador](../03-PROYECTO-FINAL/index.md): diseño, servicios, seguridad, alta disponibilidad, monitoreo, pruebas y memoria técnica.

## 9. Criterio de cierre

Al terminar una práctica, el lector debería poder explicar qué mecanismo se demostró, qué evidencia respalda el resultado, qué supuestos se utilizaron, qué limitaciones tiene la representación y qué tendría que cambiar para llevar el diseño a una infraestructura real.
