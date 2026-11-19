---
title: "Guía de uso, alcance y convenciones"
description: "Alcance, metodología, lectura de ejemplos, requisitos y seguridad operativa de NETWORKING Lab."
---

# GUÍA DE USO, ALCANCE Y CONVENCIONES


Esta guía reúne las instrucciones necesarias para interpretar y ejecutar las prácticas de NETWORKING Lab. Explica su alcance, metodología, convenciones de lectura, requisitos y medidas de seguridad. Las razones que sustentan la estructura editorial y las decisiones de diseño se documentan en la [sección de justificación y criterios editoriales](justificacion-y-criterios.md).

## 1. Alcance: qué son y qué no son

Son **representaciones didácticas** construidas principalmente con *namespaces* de red de [Linux](https://docs.kernel.org/): simplifican la realidad para explicar cómo funciona cada tecnología. **No** son procedimientos de implementación profesional ni reproducen todos los componentes de una infraestructura real. Un ejemplo explica correctamente un proceso cuando **representa correctamente ese proceso**; cuando una simplificación afecta a lo explicado (por ejemplo, rutas [IP](https://www.rfc-editor.org/rfc/rfc791) estáticas en lugar de [MPLS](https://www.rfc-editor.org/rfc/rfc3031) real), la página lo indica.


## 2. Organización y metodología de los laboratorios

El proyecto consta de **15 laboratorios**, relacionados con los temas del libro. Cada práctica sigue, cuando corresponde, este recorrido:

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

1. **[ISO 5807:1985 — Information processing: Documentation symbols and conventions for data, program and system flowcharts, program network charts and system resources charts](https://www.iso.org/standard/11955.html).** Es la referencia para seleccionar y utilizar símbolos en diagramas de flujo de datos, programas, sistemas, redes de programas y recursos de sistema. La ficha oficial de ISO indica que fue confirmada en 2019 y continúa vigente. Se aplica a la notación de los flujos cuando el tipo de diagrama corresponde; no establece los cuatro colores institucionales de este proyecto ni una taxonomía cromática de dispositivos de red.
2. **[W3C — Web Content Accessibility Guidelines (WCAG) 2.2, criterio 1.4.1 «Use of Color»](https://www.w3.org/TR/WCAG22/#use-of-color).** Es el criterio de accesibilidad aplicable a la presentación web: el color no puede ser el único medio visual para transmitir información o distinguir elementos. Por eso cada categoría también debe reconocerse mediante texto, forma, flechas o leyenda.
3. **[ANSI/NEMA Z535.1-2022 — Safety Colors](https://webstore.ansi.org/standards/nema/ansiz5352022-2475871).** Especifica colores de seguridad y sus tolerancias. Su alcance es la señalización y comunicación de seguridad; no asigna violeta a infraestructura, índigo a servicios ni otros colores a categorías de diagramas de redes. Por tanto, no se presenta como fundamento de la paleta funcional del proyecto.
4. **[ISO 3864-1:2011](https://www.iso.org/standard/51021.html) e [ISO 3864-4:2011](https://www.iso.org/standard/51000.html).** Tratan los principios de diseño y las propiedades colorimétricas/fotométricas de colores y señales de seguridad. Son pertinentes cuando un gráfico incorpora señalización de seguridad normalizada; no definen la codificación cromática de los componentes de una arquitectura de red.

**Límite normativo importante:** no se ha identificado una norma ISO, IEC, IEEE, ANSI o IETF que prescriba que los routers deban ser violetas, los servicios índigo, los procesos de un tercer color y las decisiones de un cuarto. Afirmar que esa asignación procede de ISO 5807, ANSI Z535.1 o ISO 3864 sería incorrecto. La asignación que sigue es una **convención editorial propia de NETWORKING Lab**, elegida para mantener consistencia visual con los cuatro tonos que ya existen en `stylesheets/extra.css`; no es una certificación ni una codificación normativa universal.

### 7.2 Convención cromática del proyecto

La paleta se limita a los cuatro tonos institucionales existentes. Su función es distinguir familias de elementos dentro de los diagramas; no representa severidad, riesgo, estado de salud, prioridad, permiso ni conformidad normativa.

| Color y variable CSS | Uso editorial | Ejemplos |
|---|---|---|
| Violeta `#5b18cc` · `--cv-violeta` | **Infraestructura y dispositivos** | Router, switch, firewall como equipo, host, interfaz, bridge y enlaces. |
| Índigo `#29187a` · `--cv-indigo` | **Servicios y software** | DNS, DHCP, NTP, HTTP/HTTPS, autenticación, monitoreo y aplicaciones. |
| Acento `#8b5cf6` · `--cv-acento` | **Procesos y operaciones** | Encapsulación, encaminamiento como operación, intercambio de mensajes y procesamiento. |
| Lila `#cbbcff` · `--cv-lila` | **Decisiones y condiciones** | Rombos, comprobaciones y bifurcaciones. En tema claro se usa violeta para conservar contraste. |

La tabla anterior documenta una decisión de diseño del proyecto, no una correspondencia tomada de una norma. Se eligieron cuatro categorías porque ya existen cuatro tonos en la hoja de estilos y porque permiten separar infraestructura, servicios, operaciones y decisiones sin introducir una paleta más amplia. Cuando un elemento pueda pertenecer a más de una familia, se colorea según la función que desempeña en ese diagrama y se aclara con una etiqueta; no se deduce su función exclusivamente por el color.

### 7.3 Aplicación gráfica y adaptación de tema

- **Fondos:** lienzo, nodos y agrupaciones permanecen transparentes; no se rellenan con bloques de color opaco.
- **Contornos:** el tono funcional se aplica principalmente al contorno de los nodos. Se conserva un grosor suficiente para que la forma sea visible.
- **Conectores:** las líneas y flechas utilizan el color de conexión definido para el tema; no se les asigna el color funcional del nodo de origen o destino. Las etiquetas identifican si la relación es física, lógica, túnel, ruta, dependencia o flujo de tráfico.
- **Tema claro/oscuro:** los colores se obtienen de variables CSS; el texto y los trazos se ajustan al esquema activo. El significado de cada categoría no cambia al cambiar de tema. El lila se sustituye visualmente por violeta en tema claro cuando sea necesario para el contraste.
- **Decisiones:** se representan con rombo y una condición explícita. La categoría no se determina por palabras como «firewall», «seguridad» o «ACL»: un firewall como dispositivo es infraestructura; una regla ACL es una operación/política; solo una bifurcación real es una decisión.
- **Estados de seguridad:** no se reutiliza la paleta institucional como sustituto de señales de seguridad. Si el diagrama necesita comunicar peligro, prohibición, obligación, emergencia o condición segura, debe emplear la señalización aplicable de ISO 3864/ISO 7010 o ANSI Z535, según el contexto, y no reinterpretar estos cuatro tonos.
- **Accesibilidad:** el significado debe seguir siendo comprensible sin color, mediante formas, etiquetas, flechas y una leyenda textual, conforme a WCAG 2.2, criterio 1.4.1.


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

- [Justificación y criterios editoriales](justificacion-y-criterios.md): propósito de la serie, decisiones de simplificación, organización y fundamento de la convención cromática.
- [Atlas integral de diagramas Mermaid](atlas-diagramas.md): código fuente, descripción y vínculo al contexto original de los diagramas de laboratorios, proyecto y referencias.
- [Servicios, protocolos y puertos](../04-REFERENCIA/servicios-puertos.md): matriz común de la serie.
- [Comparaciones conceptuales](../04-REFERENCIA/comparaciones.md): bridge/router, MAC/IP, subred/VLAN, GRE/IPsec y otras distinciones.
- [Método de diagnóstico](../04-REFERENCIA/diagnostico.md): secuencia de análisis desde el síntoma hasta la causa.
- [Arquitectura integral](../04-REFERENCIA/arquitectura-integral.md): mapas de síntesis y matriz de disponibilidad.
- [Glosario](../04-REFERENCIA/glosario.md): términos y acrónimos.
- [Competencias y casos integradores](../04-REFERENCIA/competencias.md): resultados esperados y ejercicios de repaso.
- [Proyecto final integrador](../03-PROYECTO-FINAL/index.md): diseño, servicios, seguridad, alta disponibilidad, monitoreo, pruebas y memoria técnica.

## 9. Criterio de cierre

Al terminar una práctica, el lector debería poder explicar qué mecanismo se demostró, qué evidencia respalda el resultado, qué supuestos se utilizaron, qué limitaciones tiene la representación y qué tendría que cambiar para llevar el diseño a una infraestructura real.
