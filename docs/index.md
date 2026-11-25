---
title: "NETWORKING LAB"
description: "Laboratorios de ejercicios y simulación práctica en redes de computadoras."
hide:
  - toc
---

<div class="sx-hero"><svg class="sx-network-scene" viewBox="0 0 1200 520" preserveAspectRatio="xMidYMid slice" aria-hidden="true" focusable="false"><defs><linearGradient id="sx-line-gradient" x1="0" x2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".08"/><stop offset=".5" stop-color="#ffffff" stop-opacity=".8"/><stop offset="1" stop-color="#ffffff" stop-opacity=".12"/></linearGradient></defs><g stroke="url(#sx-line-gradient)" fill="none"><path class="sx-wire" d="M-40 370 L180 250 L390 330 L600 155 L830 245 L1040 110 L1240 230"/><path class="sx-wire sx-wire--bright" d="M40 40 L250 175 L470 70 L700 210 L930 55 L1160 160"/><path class="sx-wire" d="M160 560 L250 175 M390 330 L470 70 M600 155 L700 460 M830 245 L930 55 M1040 110 L1120 470"/><path class="sx-wire" d="M-20 160 L180 250 L250 420 L520 470 L700 460 L940 370 L1240 420"/></g><g><circle class="sx-pulse" cx="600" cy="155" r="20"/><circle class="sx-pulse" cx="830" cy="245" r="18"/><circle class="sx-node sx-node--core" cx="600" cy="155" r="7"/><circle class="sx-node" cx="180" cy="250" r="5"/><circle class="sx-node" cx="390" cy="330" r="5"/><circle class="sx-node" cx="470" cy="70" r="4"/><circle class="sx-node" cx="700" cy="210" r="5"/><circle class="sx-node" cx="830" cy="245" r="6"/><circle class="sx-node" cx="930" cy="55" r="4"/><circle class="sx-node" cx="1040" cy="110" r="5"/><circle class="sx-node" cx="940" cy="370" r="4"/><circle class="sx-node" cx="250" cy="420" r="4"/></g></svg><p class="sx-hero__eyebrow">SECOPSMX · NETWORKING LAB</p><p><img alt="SecOpsMX" class="sx-hero__logo off-glb" src="assets/logo.png"/></p><h1 id="networking-lab">NETWORKING Lab</h1><p class="sx-hero__sub">Laboratorios de ejercicios y simulación práctica<br/>en Redes de Computadoras.</p><p class="sx-hero__lead">Complemento de NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico.</p><p class="sx-hero__cta"><a class="md-button md-button--primary" href="02-LABORATORIOS/lab-01/index.html">Inicio Lab 01</a><a class="md-button" href="https://leanpub.com/networking-fundamentos">Obtener el libro</a></p><p class="sx-hero__meta">Entorno simulado de prácticas · Guillermo Castillo · SecOpsMX</p></div>

<div class="sx-stats"><div><b>REDES</b><span>DESARROLLO</span></div><div><b>15</b><span>ESCENARIOS</span></div><div><b>+ 30</b><span>DIAGRAMAS</span></div></div>

NETWORKING LAB complementa los fundamentos teóricos de **NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico** mediante quince laboratorios que permiten comprender, configurar, observar y diagnosticar distintos mecanismos de red.

## Qué ofrece este laboratorio

NETWORKING LAB es un entorno de aprendizaje práctico que complementa los fundamentos teóricos de redes mediante escenarios didácticos construidos principalmente con herramientas de Linux.

Sus quince laboratorios permiten comprender los principios de comunicación, direccionamiento, conmutación, enrutamiento, servicios, seguridad y operación de redes. Cada práctica combina explicación conceptual, representación de escenarios, configuración guiada, observación del comportamiento y diagnóstico.

El objetivo es que el lector comprenda cómo funcionan las tecnologías de red, por qué se utilizan y cómo se relacionan entre sí, desarrollando una base técnica que le permita continuar aprendiendo y abordar escenarios más complejos.

Las prácticas utilizan simulaciones y simplificaciones controladas. No constituyen por sí mismas procedimientos de despliegue profesional ni sustituyen la validación de una infraestructura real.

## 1. Del punto A al punto B

Los quince laboratorios siguen una progresión: primero se **construye y comprende** la red; después se **interconecta, se incorporan los servicios y se aplican controles de seguridad**; por último, se **diseña, integra y opera la infraestructura**. Cada práctica declara su propio escenario: comienza con una introducción técnica y constituye un recurso individual que, a su vez, contribuye al conjunto.

El hilo conductor es **Networking SecOps**, una empresa ficticia que parte de una oficina sin red y crece hasta una infraestructura multisede: cada laboratorio abre con la situación de la empresa y cierra con el punto al que llega su red.

### 1.1 Infraestructura: bienvenido a SecOps

<div class="sx-cards"><a class="sx-card" href="02-LABORATORIOS/lab-01/index.html"><span class="sx-card__n">01</span><span class="sx-card__t">FUNDAMENTOS DE REDES Y ENCAPSULACIÓN</span></a><a class="sx-card" href="02-LABORATORIOS/lab-02/index.html"><span class="sx-card__n">02</span><span class="sx-card__t">TRANSMISIÓN DE DATOS Y CAPA FÍSICA</span></a><a class="sx-card" href="02-LABORATORIOS/lab-03/index.html"><span class="sx-card__n">03</span><span class="sx-card__t">COMPONENTES DE RED Y CONMUTACIÓN</span></a><a class="sx-card" href="02-LABORATORIOS/lab-04/index.html"><span class="sx-card__n">04</span><span class="sx-card__t">DIRECCIONAMIENTO IP Y SUBREDES</span></a><a class="sx-card" href="02-LABORATORIOS/lab-05/index.html"><span class="sx-card__n">05</span><span class="sx-card__t">CONMUTACIÓN Y SEGMENTACIÓN DE RED</span></a></div>

### 1.2 Conectividad, servicios y seguridad

<div class="sx-cards"><a class="sx-card" href="02-LABORATORIOS/lab-06/index.html"><span class="sx-card__n">06</span><span class="sx-card__t">ENRUTAMIENTO Y CONECTIVIDAD ENTRE REDES</span></a><a class="sx-card" href="02-LABORATORIOS/lab-07/index.html"><span class="sx-card__n">07</span><span class="sx-card__t">PROTOCOLOS Y SERVICIOS DE RED</span></a><a class="sx-card" href="02-LABORATORIOS/lab-08/index.html"><span class="sx-card__n">08</span><span class="sx-card__t">SEGURIDAD EN REDES</span></a><a class="sx-card" href="02-LABORATORIOS/lab-09/index.html"><span class="sx-card__n">09</span><span class="sx-card__t">VPN Y TUNELIZACIÓN</span></a><a class="sx-card" href="02-LABORATORIOS/lab-10/index.html"><span class="sx-card__n">10</span><span class="sx-card__t">INFRAESTRUCTURA WAN Y CORE</span></a></div>

### 1.3 Operación: la arquitectura es toda tuya

<div class="sx-cards"><a class="sx-card" href="02-LABORATORIOS/lab-11/index.html"><span class="sx-card__n">11</span><span class="sx-card__t">ARQUITECTURA DE RED EMPRESARIAL</span></a><a class="sx-card" href="02-LABORATORIOS/lab-12/index.html"><span class="sx-card__n">12</span><span class="sx-card__t">ARQUITECTURAS MODERNAS DE RED</span></a><a class="sx-card" href="02-LABORATORIOS/lab-13/index.html"><span class="sx-card__n">13</span><span class="sx-card__t">MONITOREO Y DIAGNÓSTICO DE REDES</span></a><a class="sx-card" href="02-LABORATORIOS/lab-14/index.html"><span class="sx-card__n">14</span><span class="sx-card__t">HERRAMIENTAS LINUX AVANZADAS</span></a><a class="sx-card" href="02-LABORATORIOS/lab-15/index.html"><span class="sx-card__n">15</span><span class="sx-card__t">IMPLEMENTACIÓN PRÁCTICA INTEGRAL</span></a></div>

## 2. Referencia técnica

- [Comparaciones conceptuales](04-REFERENCIA/comparaciones.md)
- [Método de diagnóstico](04-REFERENCIA/diagnostico.md)
- [Servicios, protocolos y puertos](04-REFERENCIA/servicios-puertos.md)
- [Arquitectura integral](04-REFERENCIA/arquitectura-integral.md)
- [Glosario](04-REFERENCIA/glosario.md)

## 3. Anexos y convenciones

- [Guía de uso, alcance y convenciones](05-ANEXOS/guia-de-uso.md)
- [Diagramación y topologías](05-ANEXOS/diagramacion-y-topologias.md)
- [Derechos de autor](05-ANEXOS/derechos-de-autor.md)

## 4. Entorno y requisitos

Las prácticas se basan principalmente en Linux, *network namespaces*, interfaces virtuales y herramientas de red. Se recomienda una máquina virtual dedicada con privilegios administrativos. Android/Termux no es un entorno de ejecución soportado; WSL2 puede servir para prácticas básicas, sujeto a las capacidades de su kernel.

Los requisitos específicos y las precauciones se detallan en la [guía de uso](05-ANEXOS/guia-de-uso.md).

## 5. Libro de referencia

**NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico**, Guillermo Castillo · SecOpsMX.

[Consultar el libro en Leanpub](https://leanpub.com/networking-fundamentos).
