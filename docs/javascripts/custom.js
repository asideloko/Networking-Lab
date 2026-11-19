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
    background: "transparent", primaryColor: violeta, secondaryColor: indigo,
    tertiaryColor: acento, clusterBkg: "transparent", edgeLabelBackground: "transparent",
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
  var C = {
    aviso: "#2196D2",
    advertencia: "#F59E0B",
    tecnico: "#10B981",
    peligro: "#EF4444"
  };
  var reglas = [
    ["peligro", /peligro|error crítico|error critico|crítico|critico|fatal|fallo crítico|fallo critico|denegado|bloqueado|daño|dano|riesgo/i],
    ["advertencia", /advertencia|precaución|precaucion|cuidado|alerta|atención|atencion|borrar|eliminar|sobrescribir|respaldo|inseguro/i],
    ["tecnico", /dato técnico|dato tecnico|información técnica|informacion tecnica|parámetro|parametro|dirección ip|direccion ip|máscara|mascara|gateway|protocolo|configuración|configuracion|comando|interfaz|router|switch|servidor|vlan|subred/i],
    ["aviso", /nota|aviso|información|informacion|referencia|observación|observacion|importante|recomendación|recomendacion/i]
  ];

  function tipo(texto) {
    for (var i = 0; i < reglas.length; i++) {
      if (reglas[i][1].test(texto)) return reglas[i][0];
    }
    return "aviso";
  }

  function tinta(hex) {
    var h = hex.slice(1);
    var rgb = [0,2,4].map(function(i) {
      var v = parseInt(h.slice(i,i+2),16)/255;
      return v <= .04045 ? v/12.92 : Math.pow((v+.055)/1.055,2.4);
    });
    return .2126*rgb[0]+.7152*rgb[1]+.0722*rgb[2] > .42
      ? "#172033" : "#F8FAFC";
  }

  nodos.forEach(function(root) {
    root.querySelectorAll("g.node").forEach(function(node) {
      var texto = (node.textContent || "").replace(/\s+/g," ").trim();
      var categoria = tipo(texto);
      var fondo = C[categoria];
      var frente = tinta(fondo);
      node.setAttribute("data-funcion",categoria);

      node.querySelectorAll("rect,polygon,path,circle,ellipse").forEach(function(el) {
        if (el.closest("defs")) return;
        el.style.setProperty("fill",fondo,"important");
        el.style.setProperty("fill-opacity","1","important");
        el.style.setProperty("stroke",fondo,"important");
        el.style.setProperty("stroke-width","2px","important");
      });
      node.querySelectorAll("text,tspan").forEach(function(el) {
        el.style.setProperty("fill",frente,"important");
      });
      node.querySelectorAll("foreignObject div,foreignObject span,foreignObject p").forEach(function(el) {
        el.style.setProperty("color",frente,"important");
        el.style.setProperty("background","transparent","important");
      });
    });

    root.querySelectorAll(".cluster rect").forEach(function(el) {
      el.style.setProperty("fill",oscuro ? "#172033" : "#F1F5F9","important");
      el.style.setProperty("stroke",C.aviso,"important");
      el.style.setProperty("stroke-width","2px","important");
    });

    root.querySelectorAll("g.note rect,g.note polygon").forEach(function(el) {
      el.style.setProperty("fill",C.aviso,"important");
      el.style.setProperty("stroke",C.aviso,"important");
    });

    root.querySelectorAll(".actor rect").forEach(function(el) {
      el.style.setProperty("fill",C.tecnico,"important");
      el.style.setProperty("stroke",C.tecnico,"important");
    });

    root.querySelectorAll(".edgeLabel rect,.labelBox").forEach(function(el) {
      el.style.setProperty("fill",C.advertencia,"important");
      el.style.setProperty("stroke",C.advertencia,"important");
    });

    root.querySelectorAll(".edgePath path,.flowchart-link,.messageLine0,.messageLine1,.loopLine,.actor-line").forEach(function(el) {
      el.style.setProperty("stroke",C.aviso,"important");
      el.style.setProperty("fill","none","important");
    });

    root.querySelectorAll(".arrowheadPath").forEach(function(el) {
      el.style.setProperty("fill",C.aviso,"important");
      el.style.setProperty("stroke",C.aviso,"important");
    });

    root.querySelectorAll(".messageText,.noteText,.labelText").forEach(function(el) {
      el.style.setProperty("fill",oscuro ? "#F8FAFC" : "#172033","important");
    });
  });
}
new MutationObserver(function () { renderMermaid(); })
  .observe(document.body, { attributes: true, attributeFilter: ["data-md-color-scheme"] });
