/* ==========================================================================
   NETWORKING LAB · MOTOR ÚNICO DE MOVIMIENTO (móvil primero, escritorio también)
   Los efectos están siempre activos, sin botones ni preferencias que activar.
   - Revelado al entrar en pantalla (un solo sistema).
   - Paralaje de la portada con el desplazamiento (funciona en táctil).
   - Contadores de la portada, onda táctil y resplandor en tarjetas.
   - Pausa por ahorro de batería solo cuando la portada no se ve o la pestaña está oculta.
   - Compatible con la navegación instantánea de Zensical (document$).
   - Nunca deja contenido oculto: si algo falla, se muestra.
   ========================================================================== */
(function () {
  "use strict";

  var BASE = [
    ".sx-stats > div", ".sx-card", ".galeria__item", "[data-reveal]",
    ".md-typeset > h1", ".md-typeset > h2", ".md-typeset > h3",
    ".md-typeset > figure", ".md-typeset > table",
    ".md-typeset > .admonition", ".md-typeset > details"
  ];
  var TEXTO = [".md-typeset > p", ".md-typeset > ul", ".md-typeset > ol"];

  var html = document.documentElement;
  var observador = null;
  var observadorHero = null;
  var observadorCifras = null;
  var contador = 0;
  var mqPantallaPequena = window.matchMedia ? window.matchMedia("(max-width: 60em)") : null;
  var cuadroScroll = 0;

  /* ---------- Revelado ---------- */
  function selector() {
    var lista = BASE.slice();
    if (!(mqPantallaPequena && mqPantallaPequena.matches)) lista = lista.concat(TEXTO);
    return lista.join(",");
  }

  function elementos() {
    return Array.prototype.slice.call(document.querySelectorAll(selector()));
  }

  function mostrarTodo() {
    document.querySelectorAll(".sx-reveal").forEach(function (el) {
      el.classList.remove("sx-reveal");
      el.classList.add("sx-visible");
      el.style.removeProperty("--sx-reveal-delay");
    });
    html.classList.remove("sx-motion-ready");
  }

  function cerrarObservadores() {
    [observador, observadorHero, observadorCifras].forEach(function (o) { if (o) o.disconnect(); });
    observador = observadorHero = observadorCifras = null;
  }

  function crearObservador() {
    if (!("IntersectionObserver" in window)) return null;
    return new IntersectionObserver(function (entradas) {
      entradas.forEach(function (e) {
        if (!e.isIntersecting) return;
        var el = e.target;
        el.classList.add("sx-visible");
        observador && observador.unobserve(el);
        /* Terminada la entrada se libera la clase para que :hover y :active funcionen sin retraso. */
        setTimeout(function () {
          el.classList.remove("sx-reveal");
          el.style.removeProperty("--sx-reveal-delay");
        }, 1100);
      });
    }, { root: null, rootMargin: "0px 0px -6% 0px", threshold: 0 });
  }

  function iniciarRevelado() {
    var lista = elementos();
    if (!lista.length) return;

    observador = crearObservador();
    if (!observador) { mostrarTodo(); return; }

    html.classList.add("sx-motion-ready");

    lista.forEach(function (el) {
      if (el.classList.contains("sx-visible")) return;
      el.classList.add("sx-reveal");
      el.style.setProperty("--sx-reveal-delay", (contador % 5) * 70 + "ms");
      contador++;
      observador.observe(el);
    });
  }

  /* ---------- Portada ---------- */
  function pausarSmil(hero, pausar) {
    hero.querySelectorAll("svg").forEach(function (svg) {
      try { pausar ? svg.pauseAnimations() : svg.unpauseAnimations(); } catch (e) { /* sin SMIL */ }
    });
  }

  function vigilarPortada() {
    var hero = document.querySelector(".sx-hero");
    if (!hero || !("IntersectionObserver" in window)) return;
    hero.classList.remove("sx-offscreen");
    observadorHero = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (e) {
        var fuera = !e.isIntersecting;
        hero.classList.toggle("sx-offscreen", fuera);
        pausarSmil(hero, fuera || document.hidden);
      });
    }, { threshold: 0 });
    observadorHero.observe(hero);
  }

  function animarCifra(b) {
    var m = /^(\D*?)(\d+)(\D*)$/.exec((b.getAttribute("data-final") || b.textContent).trim());
    if (!m) return;
    var destino = parseInt(m[2], 10);
    var inicio = null;
    var duracion = 1400;
    function paso(t) {
      if (inicio === null) inicio = t;
      var p = Math.min(1, (t - inicio) / duracion);
      var suave = 1 - Math.pow(1 - p, 3);
      b.textContent = m[1] + Math.round(destino * suave) + m[3];
      if (p < 1) window.requestAnimationFrame(paso);
      else b.textContent = b.getAttribute("data-final");
    }
    window.requestAnimationFrame(paso);
  }

  function iniciarCifras() {
    var cifras = document.querySelectorAll(".sx-stats b");
    if (!cifras.length || !("IntersectionObserver" in window)) return;
    observadorCifras = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (e) {
        if (!e.isIntersecting) return;
        observadorCifras.unobserve(e.target);
        animarCifra(e.target);
      });
    }, { threshold: 0.6 });
    cifras.forEach(function (b) {
      var txt = b.textContent.trim();
      if (!/\d/.test(txt) || b.getAttribute("data-final")) return;
      b.setAttribute("data-final", txt);
      b.textContent = txt.replace(/\d+/, "0");
      observadorCifras.observe(b);
    });
  }

  /* Paralaje: la portada se desplaza más despacio que la página, también en táctil. */
  function actualizarParalaje() {
    cuadroScroll = 0;
    var hero = document.querySelector(".sx-hero");
    if (!hero) return;
    var r = hero.getBoundingClientRect();
    if (r.bottom < -40 || r.top > window.innerHeight) return;
    var desplazamiento = Math.max(0, -r.top);
    hero.style.setProperty("--sx-py", Math.min(70, desplazamiento * 0.22).toFixed(1) + "px");
  }

  function alDesplazar() {
    if (!cuadroScroll) cuadroScroll = window.requestAnimationFrame(actualizarParalaje);
  }

  /* Resplandor bajo el dedo en las tarjetas y onda en los botones. */
  function iniciarToques() {
    document.querySelectorAll(".sx-card").forEach(function (card) {
      if (card.dataset.sxGlow) return;
      card.dataset.sxGlow = "1";
      card.addEventListener("pointerdown", function (e) {
        var r = card.getBoundingClientRect();
        card.style.setProperty("--tx", (e.clientX - r.left) + "px");
        card.style.setProperty("--ty", (e.clientY - r.top) + "px");
      }, { passive: true });
    });

    document.querySelectorAll(".md-typeset .md-button").forEach(function (btn) {
      if (btn.dataset.sxRipple) return;
      btn.dataset.sxRipple = "1";
      btn.addEventListener("pointerdown", function (e) {
        var r = btn.getBoundingClientRect();
        var d = Math.max(r.width, r.height) * 2.2;
        var o = document.createElement("span");
        o.className = "sx-ripple";
        o.style.width = o.style.height = d + "px";
        o.style.left = (e.clientX - r.left - d / 2) + "px";
        o.style.top = (e.clientY - r.top - d / 2) + "px";
        btn.appendChild(o);
        setTimeout(function () { if (o.parentNode) o.parentNode.removeChild(o); }, 700);
      }, { passive: true });
    });
  }

  /* ---------- Arranque ---------- */
  function iniciar() {
    cerrarObservadores();
    contador = 0;
    iniciarRevelado();
    vigilarPortada();
    iniciarCifras();
    iniciarToques();
    actualizarParalaje();
  }

  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(iniciar);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", iniciar, { once: true });
  } else {
    iniciar();
  }

  window.addEventListener("scroll", alDesplazar, { passive: true });

  /* Volver desde el historial (iOS y Android restauran la página en caché). */
  window.addEventListener("pageshow", function (e) { if (e.persisted) iniciar(); });

  /* Pestaña oculta: se pausa también la animación SVG (SMIL); al volver se reanuda. */
  document.addEventListener("visibilitychange", function () {
    var hero = document.querySelector(".sx-hero");
    if (hero) pausarSmil(hero, document.hidden || hero.classList.contains("sx-offscreen"));
  });

  /* Al girar el dispositivo o cambiar el tamaño se vuelve a decidir qué elementos animar. */
  if (mqPantallaPequena) {
    var alCambiar = function () { mostrarTodo(); iniciar(); };
    if (mqPantallaPequena.addEventListener) mqPantallaPequena.addEventListener("change", alCambiar);
    else if (mqPantallaPequena.addListener) mqPantallaPequena.addListener(alCambiar);
  }
})();
