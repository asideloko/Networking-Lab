document.addEventListener('DOMContentLoaded', function() {
    // Añadir clases Bootstrap a tablas
    var tables = document.querySelectorAll('table');
    tables.forEach(function(table) {
        table.classList.add('table', 'table-striped', 'table-hover');
    });

    // Scrollspy (requiere jQuery)
    if (typeof jQuery !== 'undefined' && typeof jQuery.fn.scrollspy !== 'undefined') {
        jQuery('body').scrollspy({ target: '.bs-sidebar' });
        jQuery('li.disabled a').on('click', function(e) {
            e.preventDefault();
        });
    }
});
