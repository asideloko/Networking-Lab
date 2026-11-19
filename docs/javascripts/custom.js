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

function aplicarColoresFuncionales() {
  const colores = {
    azul: "#2196D2",
    amarillo: "#F59E0B",
    verde: "#10B981",
    rojo: "#EF4444"
  };

  document.querySelectorAll(".mermaid svg").forEach(svg => {
    svg.querySelectorAll(".node").forEach(node => {
      const texto = (node.textContent || "").toLowerCase();
      let color = null;

      if (/peligro|error crítico|error critico|crítico|critico/.test(texto)) {
        color = colores.rojo;
      } else if (/advertencia|precaución|precaucion|riesgo/.test(texto)) {
        color = colores.amarillo;
      } else if (/dato técnico|dato tecnico|información técnica|informacion tecnica/.test(texto)) {
        color = colores.verde;
      } else if (/nota|aviso/.test(texto)) {
        color = colores.azul;
      }

      if (!color) return;

      node.querySelectorAll("rect, polygon, circle, ellipse").forEach(shape => {
        shape.style.fill = color;
        shape.style.stroke = color;
      });

      node.querySelectorAll("text, .label").forEach(label => {
        label.style.fill = "#ffffff";
        label.style.color = "#ffffff";
      });
    });
  });
}