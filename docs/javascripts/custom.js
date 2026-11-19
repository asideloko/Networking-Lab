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

// ---- Mermaid: cuatro tonos institucionales, fondo transparente y adaptación claro/oscuro ----
function mermaidTema() {
  var oscuro = document.body.getAttribute("data-md-color-scheme") === "slate";
  var css = getComputedStyle(document.documentElement);
  var color = function (name, fallback) { return css.getPropertyValue(name).trim() || fallback; };
  var violeta = color("--cv-violeta", "#5b18cc");
  var indigo = color("--cv-indigo", "#29187a");
  var acento = color("--cv-acento", "#8b5cf6");
  var lila = color("--cv-lila", "#cbbcff");
  var tinta = oscuro ? "#e8e6fa" : "#14142b";
  return {
    background: "transparent", primaryColor: "transparent", secondaryColor: "transparent",
    tertiaryColor: "transparent", clusterBkg: "transparent", edgeLabelBackground: "transparent",
    primaryTextColor: tinta, textColor: tinta, lineColor: oscuro ? lila : indigo,
    primaryBorderColor: violeta, clusterBorder: oscuro ? acento : violeta,
    fontFamily: "Chakra Petch, sans-serif"
  };
}

function renderMermaid() {
  if (typeof mermaid === "undefined") return;
  var nodos = document.querySelectorAll(".md-typeset div.mermaid");
  if (!nodos.length) return;
  nodos.forEach(function (n) {
    if (!n.dataset.fuente) n.dataset.fuente = n.textContent;
    else { n.textContent = n.dataset.fuente; n.removeAttribute("data-processed"); }
  });
  mermaid.initialize({ startOnLoad: false, securityLevel: "loose", theme: "base", themeVariables: mermaidTema() });
  mermaid.run({ nodes: nodos }).then(function () { aplicarColoresFuncionales(nodos); });
}

function aplicarColoresFuncionales(nodos) {
  var oscuro = document.body.getAttribute("data-md-color-scheme") === "slate";
  var css = getComputedStyle(document.documentElement);
  var color = function (name, fallback) { return css.getPropertyValue(name).trim() || fallback; };
  var paleta = {
    dispositivo: color("--cv-violeta", "#5b18cc"),
    servicio: color("--cv-indigo", "#29187a"),
    proceso: color("--cv-acento", "#8b5cf6"),
    decision: color("--cv-lila", "#cbbcff"),
    linea: oscuro ? "#cbbcff" : "#55418a",
    grupo: oscuro ? "#8b5cf6" : "#5b18cc",
    texto: oscuro ? "#f1edff" : "#171329",
    fondo: oscuro ? "#171329" : "#ffffff"
  };
  var reglas = [
    { tipo: "decision", re: /¿|\?|decisi[oó]n|selecci[oó]n|condici[oó]n|verdadero|falso|cumple|no cumple|existe\?/i },
    { tipo: "servicio", re: /\bdhcp\b|\bdns\b|\bntp\b|\bsiem\b|syslog|snmp|https?|servidor|servicio|database|base de datos|aplicaci[oó]n|broker|\bidp\b|monitor|noc/i },
    { tipo: "proceso", re: /paquete|trama|encapsul|prerouting|postrouting|discover|offer|request|ack|syn|fin\b|push|swap|pop|consulta|respuesta|flujo|negociaci[oó]n|\bacl\b|iptables|nftables|regla|pol[ií]tica|permitir|denegar|bloque|nat\b|routing|enrutamiento|m[eé]trica|failover/i },
    { tipo: "dispositivo", re: /router|switch|gateway|host|cliente|firewall|core|dist|access|\bpe\b|\bce\b|\br[0-9]+\b|\bsw[0-9]+\b|veth|bridge|equipo|nodo|internet|wan|lan|vlan|vpc|subred|segmento|nube|cloud|sede|sucursal|zona/i }
  ];
  var tonos = {
    dispositivo: oscuro ? "rgba(139,92,246,.18)" : "rgba(91,24,204,.09)",
    servicio: oscuro ? "rgba(99,102,241,.22)" : "rgba(41,24,122,.09)",
    proceso: oscuro ? "rgba(139,92,246,.22)" : "rgba(139,92,246,.12)",
    decision: oscuro ? "rgba(203,188,255,.20)" : "rgba(203,188,255,.34)"
  };
  nodos.forEach(function (contenedor) {
    contenedor.querySelectorAll("g.node").forEach(function (node) {
      var label = (node.textContent || "").replace(/\s+/g, " ").trim();
      var regla = reglas.find(function (r) { return r.re.test(label); });
      var tipo = regla ? regla.tipo : "dispositivo";
      var stroke = paleta[tipo];
      node.setAttribute("data-funcion", tipo);
      node.querySelectorAll("rect, polygon, path, circle, ellipse").forEach(function (shape) {
        if (shape.closest("defs")) return;
        shape.style.fill = tonos[tipo];
        shape.style.fillOpacity = "1";
        shape.style.stroke = stroke;
        shape.style.strokeWidth = tipo === "decision" ? "2.2px" : "2px";
      });
      node.querySelectorAll("text, tspan").forEach(function (el) {
        el.style.fill = paleta.texto;
        el.style.fontWeight = "600";
      });
    });
    contenedor.querySelectorAll(".edgePath path.path, .flowchart-link, .messageLine0, .messageLine1, .loopLine").forEach(function (line) {
      line.style.stroke = paleta.linea;
      line.style.strokeWidth = "1.9px";
      line.style.fill = "none";
    });
    contenedor.querySelectorAll(".arrowheadPath").forEach(function (arrow) {
      arrow.style.fill = paleta.linea;
      arrow.style.stroke = paleta.linea;
    });
    contenedor.querySelectorAll(".cluster rect").forEach(function (shape) {
      shape.style.fill = oscuro ? "rgba(139,92,246,.06)" : "rgba(91,24,204,.035)";
      shape.style.fillOpacity = "1";
      shape.style.stroke = paleta.grupo;
      shape.style.strokeWidth = "1.7px";
      shape.style.strokeDasharray = "5 3";
    });
    contenedor.querySelectorAll(".actor rect, .actor-man line, .actor-man circle").forEach(function (shape) {
      shape.style.fill = tonos.servicio;
      shape.style.stroke = paleta.servicio;
    });
    contenedor.querySelectorAll(".messageText, .noteText, .labelText").forEach(function (el) {
      el.style.fill = paleta.texto;
    });
  });
}

new MutationObserver(function () { renderMermaid(); })
  .observe(document.body, { attributes: true, attributeFilter: ["data-md-color-scheme"] });
