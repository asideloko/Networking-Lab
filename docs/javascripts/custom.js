// NETWORKING · SecOpsMX
// Enlaces externos en pestaña nueva, barra de progreso, tiempo de lectura y diagramas Mermaid (claro/oscuro)
// (compatible con navigation.instant).
document$.subscribe(function () {
  document.querySelectorAll('.md-content a[href^="http"]').forEach(function (a) {
    if (a.hostname !== location.hostname) { a.target = "_blank"; a.rel = "noopener"; }
  });

  var bar = document.querySelector(".sx-progress");
  if (!bar) {
    bar = document.createElement("div");
    bar.className = "sx-progress";
    document.body.appendChild(bar);
    window.addEventListener("scroll", function () {
      var h = document.documentElement;
      var max = h.scrollHeight - h.clientHeight;
      bar.style.width = (max > 0 ? (h.scrollTop / max) * 100 : 0) + "%";
    }, { passive: true });
  }

  // Tiempo de lectura (≈ 200 palabras/min; no cuentan las figuras ni el código)
  var meta = document.querySelector(".tema-meta");
  if (meta && !meta.querySelector(".sx-lectura")) {
    var clon = document.querySelector(".md-content__inner").cloneNode(true);
    clon.querySelectorAll("svg, pre, table, .tema-meta, .headerlink").forEach(function (n) { n.remove(); });
    var palabras = (clon.textContent.match(/\S+/g) || []).length;
    var s = document.createElement("span");
    s.className = "sx-lectura";
    s.textContent = "≈ " + Math.max(1, Math.round(palabras / 200)) + " min de lectura";
    meta.appendChild(s);
  }

  renderMermaid();
});

// ---- Mermaid: se dibuja desde el código fuente y se vuelve a dibujar al cambiar el tema ----
function mermaidTema() {
  // Base neutra (gris): el color lo aportan las clases funcionales de extra.css
  var oscuro = document.body.getAttribute("data-md-color-scheme") === "slate";
  return oscuro ? {
    background: "transparent", primaryColor: "#1e1e1e", primaryTextColor: "#e8e6fa", primaryBorderColor: "#94A3B8",
    lineColor: "#94A3B8", secondaryColor: "#1e1e1e", tertiaryColor: "#1e1e1e", clusterBkg: "transparent",
    clusterBorder: "#94A3B8", edgeLabelBackground: "#1e1e1e", textColor: "#e5e5e5"
  } : {
    background: "transparent", primaryColor: "#ffffff", primaryTextColor: "#14142b", primaryBorderColor: "#64748B",
    lineColor: "#64748B", secondaryColor: "#ffffff", tertiaryColor: "#ffffff", clusterBkg: "transparent",
    clusterBorder: "#64748B", edgeLabelBackground: "#ffffff", textColor: "#181818"
  };
}

// Normaliza etiquetas para reconocer funciones sin depender de mayúsculas ni acentos.
function normalizarEtiqueta(valor) {
  return String(valor || "")
    .replace(/<br\s*\/?\s*>/gi, " ")
    .replace(/<[^>]*>/g, " ")
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .toLowerCase().replace(/[_-]+/g, " ").replace(/\s+/g, " ").trim();
}

// Paleta «Cyberpunk»: 12 categorías funcionales. Se evalúan en ESTE ORDEN; gana la primera coincidencia.
//   sxInfra 01 · sxZone 02 · sxSystem 03 · sxUser 04 · sxService 05 · sxSecurity 06 · sxTransport 07
//   sxProcess 08 · sxData 09 · sxMonitor 10 · sxCloud 11 · sxExternal 12
// Los colores viven en extra.css. Un nodo con «class ID categoría» escrita a mano no se reclasifica.
var SX_REGLAS = [
  // Interfaces y puertos: no son equipos (neutro)
  ["", /^(veth|wan veth)\b|\(puerto\)/],
  // 10 · Monitoreo, diagnóstico y fallos hallados
  ["sxMonitor", /\b(noc|siem|monitor(?:eo|ing)?|logs?|colector|diagnostico|metricas?|alertas?|caid[oa]s?|fallos?|falla|errores?|atacante|comprometid[oa]s?|bloquead[oa]s?|denegad[oa]s?|drop|amenaza|inalcanzable)\b|^(\d+ )?(sintoma|capa o mecanismo|herramientas|evidencia|conclusion)/],
  // 08 · Procesamiento y operaciones concretas
  ["sxProcess", /\b(nat|pat|snat|dnat|masquerade|prerouting|postrouting|proceso|prefijo|gana|default)\b|^cadena\b|^paquete (entra|sale)/],
  // 11 · Nube e infraestructura virtual
  ["sxCloud", /\b(vpc|aws|ec2|rds|cloud|nube|igw|puerta de enlace a internet)\b/],
  // 12 · Elementos externos y referencia
  ["sxExternal", /\b(internet|red externa)\b/],
  // 02 · Zonas plurales
  ["sxZone", /^(dmz|servidores)\b/],
  // 03 · Sistemas y servidores
  ["sxSystem", /^servidor(?:es)?\b|\bserver\b/],
  // 06 · Seguridad
  ["sxSecurity", /\b(firewall|cortafuegos|fw|vpn gateway|vpn gw|gateway vpn|ztna|broker|idp|identity provider|proveedor de identidad|esp|cifrad[oa]s?|ipsec|wireguard|openvpn)\b/],
  // 09 · Datos y estructuras
  ["sxData", /\b(base de datos|database|db|cabecera|trama|paquete|echo|icmp|tabla|fdb|rib|fib|ip exterior|ip interior)\b/],
  // 07 · Transporte y proveedor
  ["sxTransport", /\b(pe ?\d*|p ?\d|p router ?\d*|ce ?\d*|isp|wan|red wan|nucleo del proveedor|frontera|nucleo|gre|tunel|tunnel|tcp o udp|tcp|udp)\b/],
  // 05 · Servicios y aplicaciones
  ["sxService", /\b(dns|dhcp|ntp|http|https|web|ssh|tls|ssl|aplicacion(?:es)?|application|app|centro de datos|servicios?)\b/],
  // 01 · Infraestructura de red (routers, switches, bridges, núcleo, distribución, acceso)
  ["sxInfra", /\b(router(?:es)?|r\d+|gateway|core ?\d*|distribucion|dist ?\d*|equipo|puerta de enlace|switch(?:es)?|bridge|conmutador|br ?\d*|sw ?[a-z]?\d*|access ?\d*|acceso)\b/],
  // 04 · Usuarios y terminales
  ["sxUser", /\b(clientes?|client[a-z]*|host ?\d*|usuarios?|user ?\d*|pc|laptop|ventas \d|it \d|admin \d|remot[oa]s?|empleados?)\b/],
  // 02 · Segmentación y zonas
  ["sxZone", /\b(red|redes|lan ?\d*|vlan ?\d*|subred(?:es)?|segmento|dmz|subnet)\b|^(finanzas|ventas|gestion|sucursal)\b/],
  // 08 · Procesamiento: operaciones restantes y decisiones
  ["sxProcess", /\b(encapsulacion|encaminamiento|enrutamiento|routing|rutas?|forward|input|output|acl|reglas?|politicas?|permitir|procesamiento|mensaje|intercambio|consulta|respuesta|evaluacion|flujo|ttl|siguiente salto|push|swap|pop|llega por|sale por)\b/]
];

function clasificarFuncion(etiqueta, id, forma) {
  var texto = normalizarEtiqueta(etiqueta).replace(/[^a-z0-9 /]+/g, " ").replace(/\s+/g, " ").replace(/^[\/ ]+|[\/ ]+$/g, "");
  var identificador = normalizarEtiqueta(id).replace(/\s+/g, "");

  // Una bifurcación (rombo) es una operación de decisión: procesamiento
  if (forma && /^\{(?!\{)/.test(forma.trim())) return "sxProcess";

  for (var i = 0; i < SX_REGLAS.length; i++) {
    if (SX_REGLAS[i][1].test(texto)) return SX_REGLAS[i][0] || null;
  }
  // IDs convencionales cuando el nodo solo muestra R1, PE1, SW…
  if (/^r\d+$/.test(identificador)) return "sxInfra";
  if (/^(pe|ce)\d*$/.test(identificador)) return "sxTransport";
  if (/^(sw|br)\d*$/.test(identificador)) return "sxInfra";
  if (/^(fw|ztna|idp)\d*$/.test(identificador)) return "sxSecurity";
  return null;
}

// Obtiene la etiqueta visible sin alterar la forma original de Mermaid.
function extraerEtiquetaMermaid(forma) {
  var texto = String(forma || "").trim();
  if (texto.indexOf("{{") === 0) return texto.slice(2, -2);
  if (texto.indexOf("[[") === 0) return texto.slice(2, -2);
  if (texto.indexOf("((") === 0) return texto.slice(2, -2);
  if (texto.indexOf("([") === 0 || texto.indexOf("(/ ") === 0 || texto.indexOf("(/") === 0) return texto.slice(2, -2);
  if (texto.charAt(0) === "{") return texto.slice(1, -1);
  if (texto.charAt(0) === "[") return texto.slice(1, -1);
  if (texto.charAt(0) === "(") return texto.slice(1, -1);
  return texto;
}

// Añade clases Mermaid a graph/flowchart sin modificar el código fuente original.
// Los nodos con una línea «class ID clase» escrita a mano en el diagrama NO se reclasifican
// (así se corrigen los casos ambiguos). Los estilos están en extra.css, no en el diagrama.
function prepararMermaid(origen) {
  var primeraLinea = String(origen || "").trim().split(/\r?\n/)[0] || "";
  if (!/^\s*(?:graph|flowchart)\b/i.test(primeraLinea)) return origen;

  var regexNodo = /\b([A-Za-z_][\w-]*)\s*(\{\{[^{}\n]*\}\}|\{[^{}\n]*\}|\[\[[^\]\n]*\]\]|\[[^\]\n]*\]|\(\([^\)\n]*\)\)|\(\[[^\]\n]*\]\)|\(\{[^}\n]*\}\)|\([^\)\n]*\))/g;
  var grupos = Object.create(null);
  var vistos = Object.create(null);
  var lineas = String(origen).split(/\r?\n/);

  lineas.forEach(function (linea) {                       // ids ya clasificados a mano
    var m = /^\s*class\s+([^\s]+)\s+\w+/.exec(linea);
    if (m) m[1].split(",").forEach(function (id) { vistos[id.trim()] = true; });
  });

  lineas.forEach(function (linea) {
    if (/^\s*(?:subgraph|classDef|class\s|style\s|linkStyle|click\s|%%)/i.test(linea)) return;
    var coincidencia;
    regexNodo.lastIndex = 0;
    while ((coincidencia = regexNodo.exec(linea)) !== null) {
      var id = coincidencia[1];
      var forma = coincidencia[2];
      if (vistos[id]) continue;
      var funcion = clasificarFuncion(extraerEtiquetaMermaid(forma), id, forma);
      vistos[id] = true;
      if (funcion) (grupos[funcion] = grupos[funcion] || []).push(id);
    }
  });

  var estilos = Object.keys(grupos).map(function (f) { return "class " + grupos[f].join(",") + " " + f + ";"; });
  return estilos.length ? String(origen) + "\n" + estilos.join("\n") : origen;
}

// Los participantes de sequenceDiagram no admiten classDef de flowchart;
// se les aplica la misma convención tras renderizar el SVG.
function colorearParticipantes(nodo, origen) {
  if (!/^\s*sequenceDiagram\b/im.test(origen)) return;
  nodo.querySelectorAll("svg g.actor").forEach(function (actor) {
    var funcion = clasificarFuncion(actor.textContent || "", "", "");
    if (funcion) actor.classList.add(funcion);
  });
}

function renderMermaid() {
  if (typeof mermaid === "undefined") return;
  var nodos = document.querySelectorAll(".md-typeset div.mermaid");
  if (!nodos.length) return;

  nodos.forEach(function (n) {
    if (!n.dataset.fuente) n.dataset.fuente = n.textContent;
    else { n.textContent = n.dataset.fuente; n.removeAttribute("data-processed"); }
    n.textContent = prepararMermaid(n.dataset.fuente);
  });

  mermaid.initialize({
    startOnLoad: false, securityLevel: "loose", theme: "base",
    themeVariables: Object.assign({ fontFamily: "Bai Jamjuree, sans-serif" }, mermaidTema())
  });

  Promise.resolve(mermaid.run({ nodes: nodos })).then(function () {
    nodos.forEach(function (n) { colorearParticipantes(n, n.dataset.fuente || ""); });
  }).catch(function (error) {
    console.error("No se pudo renderizar uno de los diagramas Mermaid:", error);
  });
}
new MutationObserver(function () { renderMermaid(); })
  .observe(document.body, { attributes: true, attributeFilter: ["data-md-color-scheme"] });
