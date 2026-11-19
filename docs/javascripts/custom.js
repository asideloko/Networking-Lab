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
  var oscuro = document.body.getAttribute("data-md-color-scheme") === "slate";
  return oscuro ? {
    background: "#1e1e1e", primaryColor: "#2a2a2a", primaryTextColor: "#ffffff", primaryBorderColor: "#7c4dd6",
    lineColor: "#c9b8ee", secondaryColor: "#2a2a2a", tertiaryColor: "#1e1e1e", clusterBkg: "#1e1e1e",
    clusterBorder: "#7c4dd6", edgeLabelBackground: "#1e1e1e", textColor: "#e5e5e5"
  } : {
    background: "#ffffff", primaryColor: "#ede7fa", primaryTextColor: "#181818", primaryBorderColor: "#5b18cc",
    lineColor: "#5b18cc", secondaryColor: "#f5f5f5", tertiaryColor: "#ffffff", clusterBkg: "#faf8ff",
    clusterBorder: "#5b18cc", edgeLabelBackground: "#ffffff", textColor: "#181818"
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
  mermaid.initialize({
    startOnLoad: false, securityLevel: "loose", theme: "base",
    themeVariables: Object.assign({ fontFamily: "Chakra Petch, sans-serif" }, mermaidTema())
  });
  mermaid.run({ nodes: nodos });
}
new MutationObserver(function () { renderMermaid(); })
  .observe(document.body, { attributes: true, attributeFilter: ["data-md-color-scheme"] });
