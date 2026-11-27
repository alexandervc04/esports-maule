// Filtro de tablas en el cliente
document.querySelectorAll('[data-filtro]').forEach(function (input) {
    input.addEventListener('input', function () {
        var q = input.value.toLowerCase();
        document.querySelectorAll(input.dataset.filtro + ' tbody tr').forEach(function (tr) {
            tr.style.display = tr.textContent.toLowerCase().indexOf(q) >= 0 ? '' : 'none';
        });
    });
});

// Modal de mantenedores: modo insertar / actualizar
var modal = document.getElementById('modalForm');
if (modal) {
    modal.addEventListener('show.bs.modal', function (ev) {
        var btn = ev.relatedTarget;
        var form = modal.querySelector('form');
        var accion = btn ? btn.dataset.accion : 'insertar';
        form.reset();
        form.elements['accion'].value = accion;
        form.elements['id'].value = btn && btn.dataset.id ? btn.dataset.id : '';
        modal.querySelector('[data-titulo-insertar]').classList.toggle('d-none', accion !== 'insertar');
        modal.querySelector('[data-titulo-actualizar]').classList.toggle('d-none', accion === 'insertar');
        form.querySelectorAll('[data-solo-insert]').forEach(function (el) { el.disabled = accion !== 'insertar'; });
        form.querySelectorAll('[data-required-insert]').forEach(function (el) { el.required = accion === 'insertar'; });
        if (accion === 'actualizar' && btn.dataset.fila) {
            var fila = JSON.parse(btn.dataset.fila);
            Object.keys(fila).forEach(function (k) {
                var el = form.elements[k];
                if (el && el.type !== 'password' && el.type !== 'hidden') {
                    el.value = fila[k] === null ? '' : fila[k];
                }
            });
        }
    });
}

// Inscripción: al marcar titular/suplente se actualiza el contador
document.querySelectorAll('[data-plantilla]').forEach(function (tabla) {
    var requeridos = parseInt(tabla.dataset.plantilla, 10);
    var contador = document.getElementById('contadorTitulares');
    function actualizar() {
        var t = tabla.querySelectorAll('input[value="S"]:checked').length;
        var s = tabla.querySelectorAll('input[value="N"]:checked').length;
        if (contador) {
            contador.textContent = t + ' / ' + requeridos + ' titulares · ' + s + ' suplente(s)';
            contador.className = 'badge ' + (t === requeridos && s <= 2 ? 'text-bg-success' : 'text-bg-warning');
        }
    }
    tabla.addEventListener('change', actualizar);
    actualizar();
});

// Patrocinios en apertura de torneo: habilitar monto al marcar
document.querySelectorAll('[data-patrocinio]').forEach(function (chk) {
    var monto = document.getElementById(chk.dataset.patrocinio);
    chk.addEventListener('change', function () { monto.disabled = !chk.checked; if (chk.checked) monto.focus(); });
});

// Sanciones: mostrar campos según el tipo
var tipoSancion = document.getElementById('tipoSancion');
if (tipoSancion) {
    var refrescar = function () {
        document.getElementById('grpPuntos').classList.toggle('d-none', tipoSancion.value !== 'DESCUENTO_PUNTOS');
        document.getElementById('grpDias').classList.toggle('d-none', tipoSancion.value !== 'SUSPENSION');
    };
    tipoSancion.addEventListener('change', refrescar);
    refrescar();
}

// ------------------------- Gráficos (Chart.js) -------------------------
// Paleta: serie 1 azul, serie 2 naranja; balance: azul (positivo) / rojo (negativo)
var COLOR = { s1: '#257de0', s2: '#f47230', pos: '#257de0', neg: '#ec4647', grid: '#e7e7e7', eje: '#c2c2c2', texto: '#666666' };
function formatoCLP(v) { return '$' + Math.round(v).toLocaleString('es-CL'); }
function grafico(id, tipo, labels, series, opciones) {
    var el = document.getElementById(id);
    if (!el || typeof Chart === 'undefined') return;
    opciones = opciones || {};
    Chart.defaults.font.family = getComputedStyle(document.body).fontFamily;
    Chart.defaults.color = COLOR.texto;
    var horizontal = !!opciones.horizontal;
    var fmt = opciones.formato || function (v) { return v.toLocaleString('es-CL'); };
    new Chart(el, {
        type: tipo,
        data: {
            labels: labels,
            datasets: series.map(function (s) {
                return Object.assign({ borderRadius: 4, borderSkipped: 'start', maxBarThickness: 36,
                                       borderColor: '#ffffff', borderWidth: series.length > 1 ? { top: 2 } : 0 }, s);
            })
        },
        options: {
            indexAxis: horizontal ? 'y' : 'x',
            responsive: true, maintainAspectRatio: false,
            interaction: { mode: 'nearest', intersect: false, axis: horizontal ? 'y' : 'x' },
            plugins: {
                legend: { display: series.length > 1, position: 'top', align: 'start',
                          labels: { boxWidth: 12, boxHeight: 12, useBorderRadius: true, borderRadius: 3 } },
                tooltip: { callbacks: { label: function (c) {
                    return (series.length > 1 ? c.dataset.label + ': ' : '') + fmt(horizontal ? c.parsed.x : c.parsed.y);
                } } }
            },
            scales: {
                x: { stacked: !!opciones.apilado, grid: { display: horizontal, color: COLOR.grid },
                     border: { color: COLOR.eje }, ticks: horizontal ? { callback: fmt } : { autoSkip: false, maxRotation: 40 },
                     max: horizontal ? opciones.max : undefined },
                y: { stacked: !!opciones.apilado, beginAtZero: true, grid: { display: !horizontal, color: COLOR.grid },
                     border: { display: false }, ticks: horizontal ? {} : { callback: fmt },
                     max: horizontal ? undefined : opciones.max }
            }
        }
    });
}
