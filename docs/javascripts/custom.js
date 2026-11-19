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
  var css = getComputedStyle(document.documentElement);
  var oscuro = document.body.getAttribute("data-md-color-scheme") === "slate";
  var c = function(n,d) { return css.getPropertyValue(n).trim() || d; };
  var P = {
    dispositivo:c("--cv-violeta","#5B18CC"),
    servicio:c("--cv-indigo","#29187A"),
    proceso:c("--cv-acento","#8B5CF6"),
    decision:c("--cv-lila","#CBBcff")
  };
  var reglas = [
    ["decision",/decisi[oó]n|condici[oó]n|verdadero|falso|¿|\?|válido|valido|permitido/i],
    ["servicio",/dhcp|dns|ntp|snmp|syslog|servidor|servicio|api|web|correo|aplicaci[oó]n|base de datos/i],
    ["proceso",/paquete|trama|encapsul|discover|offer|request|ack|syn|fin\b|consulta|respuesta|flujo|protocolo|autenticaci[oó]n|cifrado|nat\b|acl|iptables|nftables|regla|enrutamiento/i]
  ];
  function tinta(h) {
    var x=h.replace("#","");
    var v=[0,2,4].map(function(i) {
      var n=parseInt(x.slice(i,i+2),16)/255;
      return n<=.04045?n/12.92:Math.pow((n+.055)/1.055,2.4);
    });
    return .2126*v[0]+.7152*v[1]+.0722*v[2]>.42?"#171329":"#F1EDFF";
  }
  nodos.forEach(function(root) {
    root.querySelectorAll("g.node").forEach(function(node) {
      var label=(node.textContent||"").replace(/\s+/g," ");
      var tipo="dispositivo";
      for(var i=0;i<reglas.length;i++) {
        if(reglas[i][1].test(label)){tipo=reglas[i][0];break;}
      }
      var fondo=P[tipo], texto=tinta(fondo);
      node.setAttribute("data-funcion",tipo);
      node.querySelectorAll("rect,polygon,path,circle,ellipse").forEach(function(el) {
        if(el.closest("defs")) return;
        el.style.setProperty("fill",fondo,"important");
        el.style.setProperty("fill-opacity","1","important");
        el.style.setProperty("stroke",fondo,"important");
      });
      node.querySelectorAll("text,tspan").forEach(function(el) {
        el.style.setProperty("fill",texto,"important");
      });
      node.querySelectorAll("foreignObject div,foreignObject span,foreignObject p").forEach(function(el) {
        el.style.setProperty("color",texto,"important");
        el.style.setProperty("background","transparent","important");
      });
    });
    root.querySelectorAll(".cluster rect").forEach(function(el) {
      el.style.setProperty("fill",oscuro?"#171329":"#ECE6FB","important");
      el.style.setProperty("stroke",oscuro?P.proceso:P.dispositivo,"important");
      el.style.setProperty("stroke-dasharray","5 3","important");
    });
    root.querySelectorAll(".edgePath path,.flowchart-link,.messageLine0,.messageLine1,.loopLine,.actor-line").forEach(function(el) {
      el.style.setProperty("stroke",oscuro?P.decision:P.servicio,"important");
      el.style.setProperty("fill","none","important");
    });
    root.querySelectorAll(".arrowheadPath").forEach(function(el) {
      el.style.setProperty("fill",oscuro?P.decision:P.servicio,"important");
      el.style.setProperty("stroke",oscuro?P.decision:P.servicio,"important");
    });
    root.querySelectorAll(".actor rect").forEach(function(el) {
      el.style.setProperty("fill",P.servicio,"important");
      el.style.setProperty("stroke",P.servicio,"important");
    });
    root.querySelectorAll("g.note rect,g.note polygon").forEach(function(el) {
      el.style.setProperty("fill",P.proceso,"important");
      el.style.setProperty("stroke",P.proceso,"important");
    });
    root.querySelectorAll(".edgeLabel rect,.labelBox").forEach(function(el) {
      el.style.setProperty("fill",P.decision,"important");
      el.style.setProperty("stroke",P.decision,"important");
    });
    root.querySelectorAll(".messageText,.noteText,.labelText").forEach(function(el) {
      el.style.setProperty("fill",oscuro?"#F1EDFF":"#171329","important");
    });
  });
}
new MutationObserver(function () { renderMermaid(); })
  .observe(document.body, { attributes: true, attributeFilter: ["data-md-color-scheme"] });
