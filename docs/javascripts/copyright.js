document.addEventListener("DOMContentLoaded", function () {
  const footer = document.querySelector(".md-footer-meta__inner");

  if (!footer || footer.querySelector(".copyright-footer")) return;

  const notice = document.createElement("div");
  notice.className = "copyright-footer";

  notice.innerHTML = `
    <strong>NETWORKING – Fundamentos, Arquitecturas y Despliegue Práctico</strong>
    <br>© 2026 Guillermo Castillo · SecOpsMX
    <br>
    <a href="https://creativecommons.org/licenses/by-nc-nd/4.0/deed.es">
      <img src="https://licensebuttons.net/l/by-nc-nd/4.0/88x31.png"
           alt="Creative Commons CC BY-NC-ND 4.0">
    </a>
    <a href="https://creativecommons.org/licenses/by-nc-nd/4.0/deed.es">
      CC BY-NC-ND 4.0 Internacional
    </a>
  `;

  footer.appendChild(notice);
});