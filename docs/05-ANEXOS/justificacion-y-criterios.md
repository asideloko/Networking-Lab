---
title: "Justificación y criterios editoriales"
description: "Fundamento pedagógico, estructural, técnico y visual de NETWORKING Lab."
---

# JUSTIFICACIÓN Y CRITERIOS EDITORIALES

Esta sección concentra las razones que orientan el diseño de NETWORKING Lab. Su propósito es explicar por qué se eligieron el formato de laboratorio, la progresión temática, las simplificaciones técnicas y las convenciones visuales. No sustituye las instrucciones operativas de cada práctica ni presenta decisiones editoriales como requisitos de una norma.

## 1. Justificación pedagógica

La serie necesita un entorno que permita observar mecanismos de red sin el coste, la complejidad ni los riesgos de desplegar una infraestructura empresarial completa. Los *namespaces*, interfaces virtuales, bridges y servicios Linux permiten aislar escenarios, repetir pruebas y observar el comportamiento de protocolos y funciones concretas.

El enfoque combina tres planos que deben permanecer diferenciados:

- **Conceptual:** explica el mecanismo, protocolo o función que se estudia.
- **Representativo:** muestra cómo se ilustra ese mecanismo en la topología, el diagrama, el comando o la salida de ejemplo.
- **Técnico:** delimita qué ocurriría en una implementación real, qué dependencias intervienen y qué condiciones o componentes no están presentes en el laboratorio.

Una simplificación es aceptable cuando conserva el mecanismo que se desea enseñar y se declara cuando puede alterar la interpretación. Por ejemplo, una ruta IP estática puede ayudar a estudiar conectividad, pero no debe describirse como una implementación real de MPLS.

## 2. Justificación de la estructura y el orden

El contenido se organiza en cinco secciones principales, con una progresión desde la orientación inicial hasta la consulta especializada:

1. **Inicio:** presenta el propósito, el recorrido y los accesos principales.
2. **Laboratorios:** desarrolla las prácticas en una secuencia temática de fundamentos, conectividad, servicios, seguridad, arquitectura y operación.
3. **Proyecto final:** integra los conocimientos en un escenario empresarial y exige justificar decisiones, pruebas y limitaciones.
4. **Referencia:** reúne material transversal de consulta para no repetirlo en cada práctica.
5. **Anexos:** concentra las convenciones de uso y los recursos gráficos compartidos.

Los quince laboratorios se agrupan en tres bloques de cinco para facilitar la navegación, no para afirmar que cada bloque sea una fase rígida o que todas las tecnologías se implementen de forma acumulativa. Cada laboratorio declara su propia topología y sus recursos; no se presupone que namespaces, interfaces, direcciones o procesos sobrevivan entre prácticas.

La sección de referencia separa los contenidos de consulta frecuente —glosario, puertos, comparaciones, diagnóstico, arquitectura y competencias— del contenido procedimental de los laboratorios. El sección de diagramación y topologías y esta guía se mantienen como anexos porque describen recursos y convenciones comunes a toda la serie.

## 3. Justificación de las simplificaciones técnicas

La simulación con Linux ofrece observabilidad, bajo coste y repetibilidad. No reproduce automáticamente las funciones específicas de equipos dedicados, ASIC, controladores propietarios, plataformas de orquestación ni planos de control distribuidos.

Por ello, cada práctica debe indicar, cuando corresponda:

- qué mecanismo se ejecuta realmente;
- qué mecanismo se representa mediante una aproximación;
- qué componentes o dependencias no se despliegan;
- qué evidencia permite validar el resultado;
- qué limitaciones impiden extrapolarlo directamente a producción.

Esta separación evita confundir una demostración de un principio con una implementación completa. También permite contrastar el modelo con RFC, estándares y documentación oficial.

## 4. Justificación de la convención cromática

La paleta de los diagramas reutiliza los cuatro tonos funcionales ya definidos por el proyecto en `docs/stylesheets/extra.css`. Se mantiene una paleta reducida para conservar la identidad visual, evitar colores redundantes y facilitar la lectura de topologías extensas. La asignación es una convención editorial propia; no procede de una norma universal de diagramación de redes.

| Familia visual | Variable CSS | Valor de referencia | Uso |
|---|---|---|---|
| Infraestructura y dispositivos | `--cv-violeta` | `#5b18cc` | Routers, switches, hosts, interfaces, bridges, enlaces y equipos físicos o virtuales. |
| Servicios y software | `--cv-indigo` | `#29187a` | DNS, DHCP, NTP, servidores lógicos, autenticación, monitoreo y aplicaciones. |
| Procesos y operaciones | `--cv-acento` | `#8b5cf6` | Encapsulación, encaminamiento como operación, intercambio de mensajes, reglas y procesamiento. |
| Decisiones y condiciones | `--cv-lila` | `#cbbcff` | Condiciones, bifurcaciones y comprobaciones representadas con rombos. En tema claro se usa el violeta para preservar contraste. |

La función determina el color, no el nombre del elemento. Un firewall dibujado como equipo pertenece a infraestructura; una regla de firewall es una política u operación; una bifurcación condicional es una decisión. Cuando un elemento desempeñe más de una función, la etiqueta y el contexto deben eliminar cualquier ambigüedad.

### 4.1 Reglas de aplicación

- Los fondos de lienzos, nodos y agrupaciones permanecen transparentes para integrarse con los temas claro y oscuro.
- El color funcional se aplica principalmente al contorno del nodo; el texto conserva contraste con el fondo.
- Las conexiones usan el color de línea definido para el tema y se identifican mediante etiquetas cuando sea necesario distinguir enlaces físicos, lógicos, túneles, rutas o flujos.
- Las decisiones se representan mediante rombos y condiciones explícitas; el color por sí solo nunca determina su significado.
- La semántica de cada categoría no cambia al alternar entre tema claro y oscuro.
- El significado debe conservarse en escala de grises y para personas que no distinguen determinados colores: se complementa con forma, etiqueta, flechas y leyenda.

### 4.2 Alcance de las normas y referencias

Las referencias siguientes respaldan aspectos concretos de representación o accesibilidad; ninguna asigna los cuatro tonos anteriores a categorías de dispositivos o procesos de red:

1. **[ISO 5807:1985](https://www.iso.org/standard/11955.html)** describe símbolos y convenciones para determinados diagramas de flujo, sistemas, redes de programas y recursos. Su alcance depende del tipo de diagrama; no define la paleta funcional de NETWORKING Lab.
2. **[W3C WCAG 2.2, criterio 1.4.1 «Use of Color»](https://www.w3.org/TR/WCAG22/#use-of-color)** establece que el color no debe ser el único medio visual para transmitir información o distinguir elementos.
3. **[ANSI/NEMA Z535.1-2022](https://webstore.ansi.org/standards/nema/ansiz5352022-2475871)** aborda colores de seguridad. No es fundamento para asignar colores a routers, servicios o procesos de diagramas de arquitectura.
4. **[ISO 3864-1:2011](https://www.iso.org/standard/51021.html) e [ISO 3864-4:2011](https://www.iso.org/standard/51000.html)** tratan principios de diseño y propiedades de colores y señales de seguridad. Son pertinentes cuando se incorporan señales de seguridad normalizadas, no para codificar componentes ordinarios de una red.

**Límite normativo:** no se ha identificado una norma ISO, IEC, IEEE, ANSI o IETF que prescriba esta asignación cromática para diagramas de redes. Por tanto, la paleta debe presentarse como convención propia del proyecto, no como cumplimiento o certificación normativa.

## 5. Mantenimiento y control de consistencia

Los valores y reglas de renderizado deben mantenerse sincronizados entre `docs/stylesheets/extra.css` y `docs/javascripts/custom.js`. Un cambio en la paleta requiere actualizar esta tabla y comprobar los diagramas en tema claro, tema oscuro y escala de grises.

Antes de publicar una modificación estructural o visual, comprueba:

1. que la navegación refleje la estructura real de carpetas;
2. que los enlaces internos apunten a destinos existentes;
3. que cada diagrama tenga título, etiquetas y leyenda cuando corresponda;
4. que las flechas y relaciones representen el flujo descrito;
5. que las categorías se distingan sin depender exclusivamente del color;
6. que el contenido sea legible en pantalla móvil e impresión.

## 6. Criterio editorial final

Cada decisión debe ayudar al lector a distinguir entre explicación, representación y comportamiento técnico. Cuando una práctica no implemente una función, debe indicarlo; cuando un diagrama simplifique una arquitectura, debe identificar el alcance de la simplificación; y cuando una convención sea propia del proyecto, debe declararse como tal.
