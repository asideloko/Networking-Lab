(function () {
  function addCopyButtons() {
    document.querySelectorAll(".rst-content pre").forEach(function (pre) {
      if (pre.querySelector(".copy-command")) return;

      var code = pre.querySelector("code");
      if (!code) return;

      var button = document.createElement("button");
      button.className = "copy-command";
      button.type = "button";
      button.textContent = "Copiar";
      button.setAttribute("aria-label", "Copiar código");

      button.addEventListener("click", async function () {
        var text = code.innerText;

        try {
          await navigator.clipboard.writeText(text);
          button.textContent = "Copiado";
        } catch (error) {
          var area = document.createElement("textarea");
          area.value = text;
          area.style.position = "fixed";
          area.style.opacity = "0";
          document.body.appendChild(area);
          area.select();
          var ok = document.execCommand("copy");
          area.remove();
          button.textContent = ok ? "Copiado" : "No disponible";
        }

        window.setTimeout(function () {
          button.textContent = "Copiar";
        }, 1600);
      });

      pre.appendChild(button);
    });
  }

  document.addEventListener("DOMContentLoaded", addCopyButtons);
  addCopyButtons();
})();

(function () {
  function initMermaid() {
    if (typeof mermaid === "undefined") return;
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: "loose",
      theme: "base",
      themeVariables: {
        fontFamily: "Chakra Petch, sans-serif",
        primaryColor: "#efe6fa",
        primaryTextColor: "#1d1d2b",
        primaryBorderColor: "#5B14B6",
        lineColor: "#5B14B6",
        secondaryColor: "#e0f7fb",
        tertiaryColor: "#ffffff",
        clusterBkg: "#f7f2fd",
        clusterBorder: "#5B14B6"
      }
    });
    mermaid.run({ querySelector: ".mermaid" });
  }
  document.addEventListener("DOMContentLoaded", initMermaid);
})();
