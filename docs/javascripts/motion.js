
/* ==========================================================================
   NETWORKING LAB — CONTROL RESPONSIVE DE ANIMACIONES
   Compatible con navegación instantánea de Zensical.
   IntersectionObserver + accesibilidad + reinicialización dinámica.
   ========================================================================== */

(function () {
  "use strict";

  var SELECTOR = [
    ".sx-hero",
    ".sx-stats > div",
    ".sx-card",
    ".galeria__item",
    ".md-typeset > h1",
    ".md-typeset > h2",
    ".md-typeset > h3",
    ".md-typeset > p",
    ".md-typeset > ul",
    ".md-typeset > ol",
    ".md-typeset > figure",
    ".md-typeset > table",
    ".md-typeset > .admonition",
    ".md-typeset > details"
  ].join(",");

  var observer = null;
  var contador = 0;

  var consultaMovimiento = window.matchMedia
    ? window.matchMedia("(prefers-reduced-motion: reduce)")
    : null;

  function movimientoReducido() {
    return consultaMovimiento && consultaMovimiento.matches;
  }

  function obtenerElementos() {
    return Array.prototype.slice.call(
      document.querySelectorAll(SELECTOR)
    );
  }

  function mostrarSinAnimacion(elementos) {
    elementos.forEach(function (elemento) {
      elemento.classList.remove("sx-reveal");
      elemento.classList.add("sx-visible");

      elemento.removeAttribute("data-sx-motion-init");
      elemento.style.removeProperty("--sx-reveal-delay");
    });

    document.documentElement.classList.remove("sx-motion-ready");
  }

  function destruirObservador() {
    if (observer) {
      observer.disconnect();
      observer = null;
    }
  }

  function crearObservador() {
    if (observer) {
      return true;
    }

    if (!("IntersectionObserver" in window)) {
      return false;
    }

    observer = new IntersectionObserver(
      function (entradas) {
        entradas.forEach(function (entrada) {
          if (!entrada.isIntersecting) {
            return;
          }

          entrada.target.classList.add("sx-visible");
          observer.unobserve(entrada.target);
        });
      },
      {
        root: null,
        rootMargin: "0px 0px -8% 0px",
        threshold: 0.08
      }
    );

    return true;
  }

  function inicializarMovimiento() {
    var elementos = obtenerElementos();

    if (!elementos.length) {
      return;
    }

    if (movimientoReducido()) {
      destruirObservador();
      mostrarSinAnimacion(elementos);
      return;
    }

    if (!crearObservador()) {
      mostrarSinAnimacion(elementos);
      return;
    }

    document.documentElement.classList.add("sx-motion-ready");

    elementos.forEach(function (elemento) {
      if (elemento.getAttribute("data-sx-motion-init") === "true") {
        return;
      }

      elemento.setAttribute("data-sx-motion-init", "true");

      elemento.classList.remove("sx-visible");
      elemento.classList.add("sx-reveal");

      elemento.style.setProperty(
        "--sx-reveal-delay",
        (contador % 5) * 65 + "ms"
      );

      contador++;

      observer.observe(elemento);
    });
  }

  function actualizarPreferencia() {
    if (movimientoReducido()) {
      destruirObservador();
      mostrarSinAnimacion(obtenerElementos());
    } else {
      inicializarMovimiento();
    }
  }

  /*
   * Navegación instantánea de Zensical.
   * Cada cambio de documento vuelve a examinar los elementos nuevos.
   */
  if (
    typeof document$ !== "undefined" &&
    document$ &&
    typeof document$.subscribe === "function"
  ) {
    document$.subscribe(function () {
      inicializarMovimiento();
    });
  } else if (document.readyState === "loading") {
    document.addEventListener(
      "DOMContentLoaded",
      inicializarMovimiento,
      { once: true }
    );
  } else {
    inicializarMovimiento();
  }

  /*
   * Detectar cambios en la preferencia de accesibilidad
   * sin dejar elementos bloqueados u ocultos.
   */
  if (consultaMovimiento) {
    if (typeof consultaMovimiento.addEventListener === "function") {
      consultaMovimiento.addEventListener(
        "change",
        actualizarPreferencia
      );
    } else if (typeof consultaMovimiento.addListener === "function") {
      consultaMovimiento.addListener(
        actualizarPreferencia
      );
    }
  }

})();
