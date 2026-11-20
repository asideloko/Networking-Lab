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

// ---- Mermaid: paleta funcional de 12 familias; se adapta al tema activo ----
var SX_PALETA = {
  sxInfra:      { color: "#5B14CC", claro: "#EEE5FF", oscuro: "#24143D", textoClaro: "#35136E", textoOscuro: "#E9D9FF" },
  sxSegment:    { color: "#059669", claro: "#E0F5EC", oscuro: "#10352A", textoClaro: "#075B42", textoOscuro: "#8CE5C3" },
  sxSystems:    { color: "#D97706", claro: "#FFF1D9", oscuro: "#3A2810", textoClaro: "#804400", textoOscuro: "#FFD08A" },
  sxUsers:      { color: "#DC2626", claro: "#FCE8E8", oscuro: "#3B171B", textoClaro: "#941B25", textoOscuro: "#FF9A9F" },
  sxServices:   { color: "#0284C7", claro: "#E2F3FC", oscuro: "#102F42", textoClaro: "#07547D", textoOscuro: "#8BD5FA" },
  sxSecurity:   { color: "#E65C9C", claro: "#FCE8F2", oscuro: "#3A1A2B", textoClaro: "#96335F", textoOscuro: "#FFABD2" },
  sxTransport:  { color: "#F28E2B", claro: "#FFF0E0", oscuro: "#3B2513", textoClaro: "#8A4708", textoOscuro: "#FFC184" },
  sxOperations: { color: "#00A6A6", claro: "#DFF5F3", oscuro: "#103635", textoClaro: "#006C6C", textoOscuro: "#80E2DE" },
  sxData:       { color: "#344F7A", claro: "#E6ECF5", oscuro: "#1B2940", textoClaro: "#263D63", textoOscuro: "#B8CBEA" },
  sxMonitor:    { color: "#8C5A3C", claro: "#F4EAE3", oscuro: "#342219", textoClaro: "#68402B", textoOscuro: "#DDB69D" },
  sxCloud:      { color: "#8AA61E", claro: "#F0F5DE", oscuro: "#2C3515", textoClaro: "#566A0C", textoOscuro: "#D2E68B" },
  sxExternal:   { color: "#737373", claro: "#EEEEEE", oscuro: "#292929", textoClaro: "#454545", textoOscuro: "#D0D0D0" }
};

function mermaidTema() {
  var oscuro = document.body.getAttribute("data-md-color-scheme") === "slate";
  return oscuro ? {
    background: "#1e1e1e", primaryColor: "#25202D", primaryTextColor: "#F3F4F6", primaryBorderColor: "#5B14CC",
    lineColor: "#B9A5D8", secondaryColor: "#252525", tertiaryColor: "#1e1e1e", clusterBkg: "#202020",
    clusterBorder: "#65518A", edgeLabelBackground: "#1e1e1e", textColor: "#E5E5E5"
  } : {
    background: "#ffffff", primaryColor: "#F7F5FA", primaryTextColor: "#181818", primaryBorderColor: "#5B14CC",
    lineColor: "#6B6475", secondaryColor: "#F5F5F5", tertiaryColor: "#ffffff", clusterBkg: "#FAF8FD",
    clusterBorder: "#B9A8D4", edgeLabelBackground: "#ffffff", textColor: "#181818"
  };
}

// Normaliza etiquetas sin depender de mayúsculas, HTML ni acentos.
function normalizarEtiqueta(valor) {
  return String(valor || "")
    .replace(/<br\s*\/?\s*>/gi, " ")
    .replace(/<[^>]*>/g, " ")
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .toLowerCase().replace(/[_-]+/g, " ").replace(/\s+/g, " ").trim();
}

// La clasificación se basa en la función del elemento en ese diagrama.
// Las reglas más específicas se evalúan primero para resolver ambigüedades.
function clasificarFuncion(etiqueta, id, forma) {
  var texto = normalizarEtiqueta(etiqueta);
  var identificador = normalizarEtiqueta(id).replace(/\s+/g, "");
  if (forma && /^\{(?!\{)/.test(forma.trim())) return null; // el rombo ya expresa decisión

  if (/\b(firewall|vpn gateway|vpn|ipsec|ike|esp|ztna|identity provider|idp|siem|acl|access control|autenticacion|autorizacion|cifrado|descifrado|security|seguridad|bloqueo|filtrado|politica de seguridad)\b/.test(texto)) return "sxSecurity";
  if (/\b(aws|vpc|ec2|rds|cloud|nube|namespace|network namespace|veth|interfaz virtual|virtual interface|subred cloud)\b/.test(texto)) return "sxCloud";
  if (/\b(isp|proveedor|provider|mpls|pe router|pe[0-9]+|ce[0-9]+|p router|transito|transit|operador wan)\b/.test(texto) || /^(pe\d+|ce\d+|p\d+|isp)$/.test(identificador)) return "sxTransport";
  if (/\b(internet|externo|externa|external|public network|red publica|host externo|sistema externo)\b/.test(texto)) return "sxExternal";
  if (/\b(vlan|subred|subnet|dmz|lan|wan|zona|segmento|segmentacion|red interna|red local|red de usuarios|red de servidores|sede|sucursal|public subnet|private subnet)\b/.test(texto) || /^(lan\d*|vlan\d+|dmz|subnet\d*)$/.test(identificador)) return "sxSegment";
  if (/\b(noc|monitor(?:eo|ing)?|observabilidad|telemetria|logs?|metricas?|tcpdump|captura de trafico|colector|alertas?)\b/.test(texto)) return "sxMonitor";
  if (/\b(trama|frame|paquete|packet|datagrama|segmento tcp|cabecera|header|payload|mpls label|etiqueta mpls|bits|bytes|estructura de datos)\b/.test(texto)) return "sxData";
  if (/\b(nat|pat|snat|dnat|masquerade|prerouting|postrouting|forwarding|forward|routing|routeo|enrutamiento|encaminamiento|tabla de rutas|seleccion de ruta|ttl|encapsulacion|decapsulacion|push|swap|pop|stp|failover|ecmp|vrrp|master|backup|procesamiento|switching|conmutacion|handshake|establecimiento de conexion|evaluacion de regla)\b/.test(texto)) return "sxOperations";
  if (/\b(servidor|server|dns interno|dns publico|dns server|dhcp server|servidor web|web server|app server|application server|database|base de datos|db server|servidor de aplicaciones|servidor de archivos)\b/.test(texto)) return "sxSystems";
  if (/\b(dns|dhcp|ntp|http|https|ssh|tls|ssl|tcp|udp|icmp|gre|smtp|snmp|ftp|protocolo|servicio|consulta dns|respuesta dns|solicitud dhcp|aplicacion|application|api)\b/.test(texto)) return "sxServices";
  if (/\b(cliente|client|usuario|user|workstation|estacion|pc[0-9]*|laptop|endpoint|terminal|host|equipo final|dispositivo final)\b/.test(texto)) return "sxUsers";
  if (/\b(router|switch|bridge|gateway|interface|interfaz|puerto|port|core|distribution|distribucion|access switch|acceso|router linux|enlace|link|br[0-9]+|r[0-9]+|sw[0-9]+|fw[0-9]+|igw)\b/.test(texto) || /^(r\d+|sw\d+|br\d+|fw\d+|igw|core\d*|dist\d*|access\d*)$/.test(identificador)) return "sxInfra";
  return null;
}

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

function estilosMermaid(oscuro) {
  return Object.keys(SX_PALETA).map(function (clase) {
    var p = SX_PALETA[clase];
    var fondo = oscuro ? p.oscuro : p.claro;
    var texto = oscuro ? p.textoOscuro : p.textoClaro;
    return "classDef " + clase + " fill:" + fondo + ",stroke:" + p.color + ",color:" + texto + ",stroke-width:2px;";
  });
}

// Añade clases funcionales a graph/flowchart sin modificar sus fuentes originales.
function prepararMermaid(origen) {
  var primeraLinea = String(origen || "").trim().split(/\r?\n/)[0] || "";
  if (!/^\s*(?:graph|flowchart)\b/i.test(primeraLinea)) return origen;

  var regexNodo = /\b([A-Za-z_][\w-]*)\s*(\{\{[^{}\n]*\}\}|\{[^{}\n]*\}|\[\[[^\]\n]*\]\]|\[[^\]\n]*\]|\(\([^\)\n]*\)\)|\(\[[^\]\n]*\]\)|\(\{[^}\n]*\}\)|\([^\)\n]*\))/g;
  var grupos = {};
  Object.keys(SX_PALETA).forEach(function (k) { grupos[k] = []; });
  var vistos = Object.create(null);

  String(origen).split(/\r?\n/).forEach(function (linea) {
    if (/^\s*(?:subgraph|classDef|class\s|style\s|linkStyle|click\s|%%)/i.test(linea)) return;
    var coincidencia;
    regexNodo.lastIndex = 0;
    while ((coincidencia = regexNodo.exec(linea)) !== null) {
      var id = coincidencia[1];
      if (vistos[id]) continue;
      var funcion = clasificarFuncion(extraerEtiquetaMermaid(coincidencia[2]), id, coincidencia[2]);
      if (funcion && grupos[funcion]) { grupos[funcion].push(id); vistos[id] = true; }
    }
  });

  var estilos = estilosMermaid(document.body.getAttribute("data-md-color-scheme") === "slate");
  Object.keys(grupos).forEach(function (funcion) {
    if (grupos[funcion].length) estilos.push("class " + grupos[funcion].join(",") + " " + funcion + ";");
  });
  return String(origen) + "\n" + estilos.join("\n");
}

// Los participantes de sequenceDiagram reciben la misma clasificación funcional.
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
    themeVariables: Object.assign({ fontFamily: "Chakra Petch, sans-serif" }, mermaidTema())
  });
  Promise.resolve(mermaid.run({ nodes: nodos })).then(function () {
    nodos.forEach(function (n) { colorearParticipantes(n, n.dataset.fuente || ""); });
  }).catch(function (error) {
    console.error("No se pudo renderizar uno de los diagramas Mermaid:", error);
  });
}
new MutationObserver(function () { renderMermaid(); })
  .observe(document.body, { attributes: true, attributeFilter: ["data-md-color-scheme"] });
