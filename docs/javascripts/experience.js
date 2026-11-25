
/* NETWORKING LAB · Sistema de movimiento y experiencia adaptable */
(function () {
  'use strict';

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  var observer;

  function initReveal(root) {
    var items = root.querySelectorAll('[data-reveal], .sx-stats > div, .sx-cards .sx-card');

    if (!('IntersectionObserver' in window) || reduceMotion.matches) {
      items.forEach(function (item) {
        item.classList.add('sx-visible');
      });
      return;
    }

    if (!observer) {
      observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('sx-visible');
            observer.unobserve(entry.target);
          }
        });
      }, {
        threshold: 0.12,
        rootMargin: '0px 0px -6% 0px'
      });
    }

    items.forEach(function (item, index) {
      if (item.classList.contains('sx-visible')) return;

      item.style.setProperty('--sx-reveal-order', Math.min(index, 8));
      observer.observe(item);
    });
  }

  function initHero(root) {
    var hero = root.querySelector('.sx-hero');

    if (!hero || hero.dataset.motionReady) return;

    var scene = hero.querySelector('.sx-network-scene');
    if (!scene) return;

    hero.dataset.motionReady = 'true';

    var points = scene.querySelectorAll('.sx-node');

    points.forEach(function (point, index) {
      point.style.setProperty('--node-delay', (index * -0.7) + 's');
    });

    if (reduceMotion.matches) return;

    var frame = 0;
    var lastX = 0;
    var lastY = 0;

    function moveScene(event) {
      if (event.pointerType === 'mouse' && event.buttons !== 0) return;

      var rect = hero.getBoundingClientRect();

      if (!rect.width || !rect.height) return;

      lastX = (event.clientX - rect.left) / rect.width - 0.5;
      lastY = (event.clientY - rect.top) / rect.height - 0.5;

      if (frame) return;

      frame = window.requestAnimationFrame(function () {
        scene.style.setProperty(
          '--scene-x',
          (lastX * 10).toFixed(2) + 'px'
        );

        scene.style.setProperty(
          '--scene-y',
          (lastY * 8).toFixed(2) + 'px'
        );

        frame = 0;
      });
    }

    function resetScene() {
      if (frame) {
        window.cancelAnimationFrame(frame);
        frame = 0;
      }

      scene.style.setProperty('--scene-x', '0px');
      scene.style.setProperty('--scene-y', '0px');
    }

    hero.addEventListener('pointermove', moveScene, {
      passive: true
    });

    hero.addEventListener('pointerleave', resetScene, {
      passive: true
    });

    hero.addEventListener('pointercancel', resetScene, {
      passive: true
    });

    hero.addEventListener('pointerup', function (event) {
      if (event.pointerType !== 'mouse') {
        resetScene();
      }
    }, {
      passive: true
    });
  }

  function initDiagramPan(root) {
    root.querySelectorAll('.md-typeset figure.figura, .md-typeset .mermaid').forEach(function (figure) {
      if (figure.dataset.panReady) return;

      figure.dataset.panReady = 'true';
      figure.setAttribute('tabindex', '0');
      figure.setAttribute(
        'aria-label',
        'Diagrama desplazable horizontalmente; puede ampliarse con los gestos del dispositivo'
      );
    });
  }

  function initCards(root) {
    root.querySelectorAll('.sx-card').forEach(function (card) {
      if (card.dataset.touchReady) return;

      card.dataset.touchReady = 'true';

      card.addEventListener('pointerdown', function () {
        card.classList.add('is-pressed');
      }, {
        passive: true
      });

      ['pointerup', 'pointercancel', 'pointerleave'].forEach(function (name) {
        card.addEventListener(name, function () {
          card.classList.remove('is-pressed');
        }, {
          passive: true
        });
      });
    });
  }

  function closeZoom(dialog) {
    if (!dialog) return;

    dialog.remove();
    document.body.classList.remove('sx-zoom-open');
  }

  function openZoom(figure) {
    var source = figure.querySelector('svg');
    if (!source) return;

    var dialog = document.createElement('div');

    dialog.className = 'sx-zoom';
    dialog.setAttribute('role', 'dialog');
    dialog.setAttribute('aria-modal', 'true');
    dialog.setAttribute('aria-label', 'Diagrama ampliado');

    var box = document.createElement('div');
    box.className = 'sx-zoom__box';

    var clone = source.cloneNode(true);
    clone.removeAttribute('id');

    box.appendChild(clone);

    var hint = document.createElement('span');
    hint.className = 'sx-zoom__hint';
    hint.textContent = 'Toca fuera del diagrama o pulsa Esc para cerrar';

    dialog.appendChild(box);
    dialog.appendChild(hint);

    dialog.addEventListener('click', function (event) {
      if (event.target === dialog) closeZoom(dialog);
    });

    document.body.appendChild(dialog);
    document.body.classList.add('sx-zoom-open');

    dialog.tabIndex = -1;
    dialog.focus();
  }

  function initZoom(root) {
    root.querySelectorAll('.md-typeset figure.figura').forEach(function (figure) {
      if (figure.dataset.zoomReady) return;

      figure.dataset.zoomReady = 'true';

      figure.addEventListener('click', function (event) {
        if (event.target.closest('a, button')) return;
        openZoom(figure);
      });

      figure.addEventListener('keydown', function (event) {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          openZoom(figure);
        }
      });
    });
  }

  function init(root) {
    initReveal(root);
    initHero(root);
    initDiagramPan(root);
    initZoom(root);
    initCards(root);
  }

  function boot() {
    document.documentElement.classList.add('js');

    if (window.document$ && typeof window.document$.subscribe === 'function') {
      window.document$.subscribe(function () {
        init(document);
      });
    } else if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', function () {
        init(document);
      }, {
        once: true
      });
    } else {
      init(document);
    }

    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') {
        closeZoom(document.querySelector('.sx-zoom'));
      }
    });

    document.addEventListener('visibilitychange', function () {
      document.documentElement.classList.toggle(
        'sx-page-hidden',
        document.hidden
      );
    });

    if (reduceMotion.addEventListener) {
      reduceMotion.addEventListener('change', function () {
        if (reduceMotion.matches) {
          document.querySelectorAll(
            '[data-reveal], .sx-stats > div, .sx-cards .sx-card'
          ).forEach(function (item) {
            item.classList.add('sx-visible');
          });
        }
      });
    }
  }

  boot();
})();
