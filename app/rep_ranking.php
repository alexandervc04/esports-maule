<?php
/**
 * REPORTE 2 · Ranking de jugadores MVP (SP_REPORTE_RANKING_MVP)
 * Pregunta de negocio: ¿quiénes son los jugadores de mejor rendimiento (KDA, victorias, MVP) para
 * premios individuales, selecciones regionales y scouting?
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN', 'ORGANIZADOR', 'CAPITAN']);

$top = max(3, min(50, (int)($_GET['top'] ?? 10)));
$idJuego = isset($_GET['juego']) && $_GET['juego'] !== '' ? (int)$_GET['juego'] : null;
$juegos = leer('sp_videojuego_listar');
$filas = leer('sp_reporte_ranking_mvp', [$top, $idJuego]);
$lider = $filas[0] ?? null;
$masMvp = $filas ? array_reduce($filas, function ($a, $b) { return ($a === null || $b['mvps'] > $a['mvps']) ? $b : $a; }) : null;

layout_inicio('Ranking de jugadores MVP', 'r_ranking', 'Reporte 2 · SP_REPORTE_RANKING_MVP · ratio KDA = (kills + assists) / deaths');
?>
<form class="d-flex flex-wrap gap-2 align-items-center mb-3" method="get">
    <label class="text-secondary small">Videojuego</label>
    <select class="form-select form-select-sm" style="width:auto" name="juego" onchange="this.form.submit()">
        <?= opciones($juegos, 'id_videojuego', 'nombre', $idJuego, 'Todos') ?>
    </select>
    <label class="text-secondary small ms-2">Top</label>
    <select class="form-select form-select-sm" style="width:auto" name="top" onchange="this.form.submit()">
        <?php foreach ([5, 10, 15, 20] as $n): ?><option<?= $top === $n ? ' selected' : '' ?>><?= $n ?></option><?php endforeach; ?>
    </select>
</form>
<div class="row g-3 mb-3">
    <div class="col-md-6"><div class="kpi kpi-wide"><div class="kpi-texto">Mejor ratio KDA</div>
        <div class="kpi-valor"><?= e($lider['nickname'] ?? '—') ?> <small class="fs-6 text-secondary"><?= $lider ? numero($lider['kda'], 2) : '' ?></small></div>
        <div class="small text-secondary"><?= e($lider['equipo_actual'] ?? '') ?></div></div></div>
    <div class="col-md-6"><div class="kpi kpi-wide"><div class="kpi-texto">Más distinciones MVP (dentro del top)</div>
        <div class="kpi-valor"><?= e($masMvp['nickname'] ?? '—') ?> <small class="fs-6 text-secondary"><?= $masMvp ? e($masMvp['mvps']) . ' MVP' : '' ?></small></div>
        <div class="small text-secondary"><?= e($masMvp['equipo_actual'] ?? '') ?></div></div></div>
</div>
<div class="card shadow-sm mb-3">
    <div class="card-header">Ratio KDA · top <?= e($top) ?></div>
    <div class="card-body"><div class="chart-box" style="height: <?= 60 + 28 * max(count($filas), 1) ?>px"><canvas id="gKda"></canvas></div></div>
</div>
<div class="card shadow-sm">
    <div class="card-header">Detalle</div>
    <div class="table-responsive">
        <table class="table table-sm align-middle mb-0 text-end">
            <thead><tr><th class="text-start">#</th><th class="text-start">Jugador</th><th class="text-start">Equipo</th><th>Partidas</th><th>Kills</th><th>Deaths</th><th>Assists</th><th>KDA</th><th>Victorias</th><th>% victorias</th><th>MVP</th></tr></thead>
            <tbody>
            <?php foreach ($filas as $n => $f): ?>
                <tr><td class="text-start"><?= $n + 1 ?></td>
                    <td class="text-start"><span class="fw-semibold"><?= e($f['nickname']) ?></span><div class="small text-secondary"><?= e($f['jugador']) ?></div></td>
                    <td class="text-start"><?= e($f['equipo_actual'] ?? '—') ?></td>
                    <td><?= e($f['partidas']) ?></td><td><?= e($f['kills']) ?></td><td><?= e($f['deaths']) ?></td><td><?= e($f['assists']) ?></td>
                    <td class="fw-bold"><?= numero($f['kda'], 2) ?></td><td><?= e($f['victorias']) ?></td><td><?= numero($f['pct_victorias'], 1) ?>%</td>
                    <td><?= (int)$f['mvps'] > 0 ? '<i class="bi bi-star-fill text-warning"></i> ' . e($f['mvps']) : '0' ?></td></tr>
            <?php endforeach; ?>
            <?php if (!$filas): ?><tr><td colspan="11" class="text-center text-secondary py-3">Sin estadísticas registradas.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</div>
<?php
$labels = json_encode(array_map(function ($f) { return $f['nickname'] . ' (' . ($f['equipo_actual'] ?? 'libre') . ')'; }, $filas), JSON_UNESCAPED_UNICODE);
$kda = json_encode(array_map('floatval', array_column($filas, 'kda')));
layout_fin("
grafico('gKda', 'bar', $labels, [{ label: 'KDA', data: $kda, backgroundColor: COLOR.s1 }],
        { horizontal: true, formato: function (v) { return v.toLocaleString('es-CL', { maximumFractionDigits: 2 }); } });
");
