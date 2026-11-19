# NETWORKING-Lab

## Laboratorios prácticos de redes

**Del fundamento teórico a la implementación práctica.**

*NETWORKING-Lab* es el entorno de laboratorios prácticos que complementa el libro *NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico*, de Guillermo Castillo (SecOpsMX, 2026).

El libro aborda los fundamentos, protocolos, arquitecturas y tecnologías que hacen posible la comunicación entre sistemas y redes. Este laboratorio amplía ese recorrido mediante ejercicios que permiten explorar, configurar, implementar y verificar los conceptos estudiados.

Los laboratorios presentan escenarios ilustrativos de red, topologías, direccionamiento y configuración de tecnologías, además de actividades para comprobar resultados y relacionar los principios técnicos con su aplicación práctica.

## Acceder a los laboratorios

**[Abrir NETWORKING-Lab](https://asideloko.github.io/Networking-Lab/)**

## Áreas de práctica

- Fundamentos de redes y modelos de comunicación.
- Direccionamiento IPv4 e IPv6.
- Switching, VLAN y routing.
- Protocolos y servicios de red.
- Seguridad, VPN y arquitecturas modernas.
- Monitorización, diagnóstico y resolución de problemas.
- Implementación y verificación de escenarios de red.

## Obtener el libro

[NETWORKING — Fundamentos, Arquitecturas y Despliegue Práctico en Leanpub](https://leanpub.com/networking-fundamentos)

**Autor:** Guillermo Castillo · SecOpsMX  
**Edición:** 2026

## Licencia y uso

Material complementario gratuito del libro NETWORKING. Uso educativo; no se autoriza su redistribución con fines comerciales.

## Generar el sitio localmente

El sitio se genera con [Zensical](https://zensical.org/).

```bash
pip install -r requirements.txt
zensical serve      # vista previa en http://localhost:8000
zensical build      # genera site/
python scripts/validar.py
```
