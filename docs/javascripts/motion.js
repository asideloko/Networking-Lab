
/* ==========================================================================
   NETWORKING LAB — CONTROL RESPONSIVE DE ANIMACIONES
   Compatible con navegación instantánea de Zensical.
   Utiliza IntersectionObserver; no depende de eventos hover.
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

  function movimientoReducido() {
    return (
      window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    );
  }

  function mostrarSinAnimacion(elementos) {
    elementos.forEach(function (elemento) {
      elemento.classList.remove("sx-reveal");
      elemento.classList.add("sx-visible");
    });

    document.documentElement.classList.remove("sx-motion-ready");
  }

  function crearObservador() {
    if (observer || !("IntersectionObserver" in window)) {
      return;
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
  }

  function inicializarMovimiento() {
    var elementos = Array.prototype.slice.call(
      document.querySelectorAll(SELECTOR)
    );

    if (!elementos.length) {
      return;
    }

    /* Nunca ocultar contenido si el usuario solicita menos movimiento. */
    if (movimientoReducido()) {
      mostrarSinAnimacion(elementos);
      return;
    }

    /* Fallback: contenido visible si el navegador no soporta la API. */
    if (!("IntersectionObserver" in window)) {
      mostrarSinAnimacion(elementos);
      return;
    }

    crearObservador();

    if (!observer) {
      mostrarSinAnimacion(elementos);
      return;
    }

    document.documentElement.classList.add("sx-motion-ready");

    elementos.forEach(function (elemento) {
      if (elemento.dataset.sxMotionInit === "true") {
        return;
      }

      elemento.dataset.sxMotionInit = "true";
      elemento.classList.add("sx-reveal");

      /* Desfase corto para evitar que todos los bloques aparezcan juntos. */
      elemento.style.setProperty(
        "--sx-reveal-delay",
        (contador % 5) * 65 + "ms"
      );

      contador++;
      observer.observe(elemento);
    });
  }

  /*
   * Zensical utiliza document$ para notificar los cambios de documento
   * cuando navigation.instant está habilitado.
   */
  if (typeof document$ !== "undefined") {
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

  /* Si cambia la preferencia de accesibilidad, actualizar la presentación. */
  if (window.matchMedia) {
    var consultaMovimiento = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    );

    var actualizarPreferencia = function () {
      if (consultaMovimiento.matches) {
        if (observer) {
          observer.disconnect();
          observer = null;
        }

        mostrarSinAnimacion(
          Array.prototype.slice.call(
            document.querySelectorAll(".sx-reveal")
          )
        );
      } else {
        inicializarMovimiento();
      }
    };

    if (consultaMovimiento.addEventListener) {
      consultaMovimiento.addEventListener(
        "change",
        actualizarPreferencia
      );
    } else if (consultaMovimiento.addListener) {
      consultaMovimiento.addListener(actualizarPreferencia);
    }
  }
})();
