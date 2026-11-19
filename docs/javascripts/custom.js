document$.subscribe(function () {
  document.querySelectorAll('.md-content a[href^="http"]').forEach(function (a) {
    if (a.hostname !== location.hostname) {
      a.target = "_blank";
      a.rel = "noopener";
    }
  });

  var bar = document.querySelector(".sx-progress");
  if (!bar) {
    bar = document.createElement("div");
    bar.className = "sx-progress";
    document.body.appendChild(bar);
  }

  window.onscroll = function () {
    var h = document.documentElement;
    var max = h.scrollHeight - h.clientHeight;
    bar.style.width = (max > 0 ? h.scrollTop / max * 100 : 0) + "%";
  };

  var meta = document.querySelector(".tema-meta");
  var inner = document.querySelector(".md-content__inner");

  if (meta && inner && !meta.querySelector(".sx-lectura")) {
    var clon = inner.cloneNode(true);
    clon.querySelectorAll("svg, pre, table, .tema-meta, .headerlink")
      .forEach(function (n) { n.remove(); });

    var palabras = (clon.textContent.match(/\S+/g) || []).length;
    var lectura = document.createElement("span");
    lectura.className = "sx-lectura";
    lectura.textContent = "≈ " + Math.max(1, Math.round(palabras / 200)) + " min de lectura";
    meta.appendChild(lectura);
  }

  renderMermaid();
});

var COLORES_FUNCIONALES = {
  aviso: "#2196D2",
  advertencia: "#F59E0B",
  tecnico: "#10B981",
  peligro: "#EF4444"
};

function mermaidTema() {
  var oscuro = document.body.getAttribute("data-md-color-scheme") === "slate";
  var tinta = oscuro ? "#E5E7EB" : "#172033";
  var fondo = oscuro ? "#263244" : "#F1F5F9";
  var borde = oscuro ? "#94A3B8" : "#64748B";

  return {
    background: "transparent",
    primaryColor: fondo,
    secondaryColor: fondo,
    tertiaryColor: fondo,
    primaryTextColor: tinta,
    textColor: tinta,
    lineColor: borde,
    primaryBorderColor: borde,
    clusterBkg: "transparent",
    clusterBorder: borde,
    edgeLabelBackground: "transparent",
    fontFamily: "Chakra Petch, sans-serif"
  };
}

function renderMermaid() {
  if (typeof mermaid === "undefined") return;

  var nodos = document.querySelectorAll(".md-typeset div.mermaid");
  if (!nodos.length) return;

  nodos.forEach(function (n) {
    if (!n.dataset.fuente) {
      n.dataset.fuente = n.textContent;
    } else {
      n.textContent = n.dataset.fuente;
      n.removeAttribute("data-processed");
    }
  });

  mermaid.initialize({
    startOnLoad: false,
    securityLevel: "loose",
    theme: "base",
    themeVariables: mermaidTema()
  });

  mermaid.run({ nodes: nodos }).then(function () {
    aplicarColoresFuncionales(nodos);
  }).catch(function (error) {
    console.error("Error Mermaid:", error);
  });
}

function aplicarColoresFuncionales(nodos) {
  var reglas = [
    ["peligro", /\b(peligro|error crítico|error critico|fallo crítico|fallo critico|fatal|amenaza|intrusión|intrusion|malware|comprometido)\b/i],
    ["advertencia", /\b(advertencia|precaución|precaucion|cuidado|riesgo potencial|atención|atencion|no ejecutar|no eliminar|sobrescribir|inseguro)\b/i],
    ["tecnico", /\b(dato técnico|dato tecnico|parámetro|parametro|dirección ip|direccion ip|máscara de subred|mascara de subred|gateway|configuración|configuracion|comando|puerto tcp|puerto udp|vlan\s*\d+|\d{1,3}(?:\.\d{1,3}){3}(?:\/\d{1,2})?)\b/i],
    ["aviso", /\b(nota|aviso|observación|observacion|información relevante|informacion relevante|referencia|importante)\b/i]
  ];

  function categoria(texto) {
    for (var i = 0; i < reglas.length; i++) {
      if (reglas[i][1].test(texto)) return reglas[i][0];
    }
    return null;
  }

  nodos.forEach(function (root) {
    root.querySelectorAll("g.node").forEach(function (node) {
      var texto = (node.textContent || "").replace(/\s+/g, " ").trim();
      var tipo = categoria(texto);

      if (!tipo) {
        node.removeAttribute("data-funcion");
        return;
      }

      var fondo = COLORES_FUNCIONALES[tipo];
      var tinta = tipo === "advertencia" || tipo === "tecnico"
        ? "#172033" : "#FFFFFF";

      node.setAttribute("data-funcion", tipo);

      node.querySelectorAll(":scope > rect, :scope > polygon, :scope > circle, :scope > ellipse")
        .forEach(function (shape) {
          shape.style.setProperty("fill", fondo, "important");
          shape.style.setProperty("fill-opacity", "1", "important");
          shape.style.setProperty("stroke", fondo, "important");
          shape.style.setProperty("stroke-width", "2px", "important");
        });

      node.querySelectorAll("text, tspan").forEach(function (label) {
        label.style.setProperty("fill", tinta, "important");
      });

      node.querySelectorAll("foreignObject div, foreignObject span, foreignObject p")
        .forEach(function (label) {
          label.style.setProperty("color", tinta, "important");
          label.style.setProperty("background", "transparent", "important");
        });
    });

    root.querySelectorAll("g.note rect, g.note polygon").forEach(function (shape) {
      shape.style.setProperty("fill", COLORES_FUNCIONALES.aviso, "important");
      shape.style.setProperty("stroke", COLORES_FUNCIONALES.aviso, "important");
    });

    root.querySelectorAll("g.note text, g.note tspan").forEach(function (label) {
      label.style.setProperty("fill", "#FFFFFF", "important");
    });
  });
}

var esquemaObserver = new MutationObserver(function () {
  renderMermaid();
});

esquemaObserver.observe(document.documentElement, {
  attributes: true,
  attributeFilter: ["data-md-color-scheme"]
});
