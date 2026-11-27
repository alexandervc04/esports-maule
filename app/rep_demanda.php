<?php
/**
 * REPORTE 1 · Demanda y recaudación por videojuego (SP_REPORTE_DEMANDA_JUEGO)
 * Pregunta de negocio: ¿qué títulos convocan más equipos e ingresos, para planificar la oferta de torneos?
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN', 'ORGANIZADOR']);

$anio = isset($_GET['anio']) && $_GET['anio'] !== '' ? (int)$_GET['anio'] : null;
$filas = leer('sp_reporte_demanda_juego', [$anio]);
$conDatos = array_values(array_filter($filas, function ($f) { return (int)$f['torneos'] > 0; }));
$totEquipos = array_sum(array_column($filas, 'equipos_inscritos'));
$totIngresos = array_sum(array_column($filas, 'recaudacion')) + array_sum(array_column($filas, 'patrocinio'));
$top = $conDatos[0] ?? null;

layout_inicio('Demanda y recaudación por videojuego', 'r_demanda', 'Reporte 1 · SP_REPORTE_DEMANDA_JUEGO');
?>
<form class="d-flex gap-2 align-items-center mb-3" method="get">
    <label class="text-secondary small">Año</label>
    <select class="form-select form-select-sm" style="width:auto" name="anio" onchange="this.form.submit()">
        <option value="">Todos</option>
        <?php foreach ([2025, 2026, 2027] as $a): ?><option<?= $anio === $a ? ' selected' : '' ?>><?= $a ?></option><?php endforeach; ?>
    </select>
</form>
<div class="row g-3 mb-3">
    <div class="col-md-4"><div class="kpi kpi-wide"><div class="kpi-texto">Juego con mayor demanda</div><div class="kpi-valor"><?= e($top['videojuego'] ?? '—') ?></div><div class="small text-secondary"><?= e($top['equipos_inscritos'] ?? 0) ?> equipos inscritos</div></div></div>
    <div class="col-md-4"><div class="kpi kpi-wide"><div class="kpi-texto">Equipos inscritos (total)</div><div class="kpi-valor"><?= numero($totEquipos) ?></div></div></div>
    <div class="col-md-4"><div class="kpi kpi-wide"><div class="kpi-texto">Ingresos totales (inscripción + patrocinio)</div><div class="kpi-valor"><?= monto($totIngresos) ?></div></div></div>
</div>
<div class="row g-3 mb-3">
    <div class="col-lg-6"><div class="card shadow-sm h-100"><div class="card-header">Equipos inscritos por videojuego</div>
        <div class="card-body"><div class="chart-box"><canvas id="gEquipos"></canvas></div></div></div></div>
    <div class="col-lg-6"><div class="card shadow-sm h-100"><div class="card-header">Ingresos por videojuego</div>
        <div class="card-body"><div class="chart-box"><canvas id="gIngresos"></canvas></div></div></div></div>
</div>
<div class="card shadow-sm">
    <div class="card-header">Detalle</div>
    <div class="table-responsive">
        <table class="table table-sm align-middle mb-0">
            <thead><tr><th>Videojuego</th><th>Género</th><th class="text-end">Torneos</th><th class="text-end">Equipos</th><th class="text-end">Jugadores</th>
                <th class="text-end">Prom. equipos/torneo</th><th class="text-end">Inscripciones</th><th class="text-end">Patrocinio</th><th class="text-end">Total</th></tr></thead>
            <tbody>
            <?php foreach ($filas as $f): ?>
                <tr><td class="fw-semibold"><?= e($f['videojuego']) ?></td><td class="small"><?= e($f['genero']) ?></td>
                    <td class="text-end"><?= e($f['torneos']) ?></td><td class="text-end"><?= e($f['equipos_inscritos']) ?></td>
                    <td class="text-end"><?= e($f['jugadores_inscritos']) ?></td><td class="text-end"><?= $f['promedio_equipos_torneo'] !== null ? numero($f['promedio_equipos_torneo'], 1) : '—' ?></td>
                    <td class="text-end"><?= monto($f['recaudacion']) ?></td><td class="text-end"><?= monto($f['patrocinio']) ?></td>
                    <td class="text-end fw-semibold"><?= monto($f['recaudacion'] + $f['patrocinio']) ?></td></tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php
$labels = json_encode(array_column($conDatos, 'videojuego'), JSON_UNESCAPED_UNICODE);
$equipos = json_encode(array_map('intval', array_column($conDatos, 'equipos_inscritos')));
$recaud = json_encode(array_map('intval', array_column($conDatos, 'recaudacion')));
$patro = json_encode(array_map('intval', array_column($conDatos, 'patrocinio')));
layout_fin("
grafico('gEquipos', 'bar', $labels, [{ label: 'Equipos inscritos', data: $equipos, backgroundColor: COLOR.s1 }]);
grafico('gIngresos', 'bar', $labels, [
  { label: 'Inscripciones', data: $recaud, backgroundColor: COLOR.s1 },
  { label: 'Patrocinio', data: $patro, backgroundColor: COLOR.s2 }
], { apilado: true, formato: formatoCLP });
");
