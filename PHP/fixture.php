<?php
/**
 * GESTOR 3 · Generación de fixture
 * SP_GENERAR_FIXTURE recorre con cursor los equipos inscritos y crea las partidas
 * (liga: método del círculo / eliminación: llaves con BYE). Muestra posiciones (VW_POSICIONES_TORNEO).
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN', 'ORGANIZADOR', 'CAPITAN']);
$staff = es(['ADMIN', 'ORGANIZADOR']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verificar_csrf();
    $idTorneo = (int)($_POST['id_torneo'] ?? 0);
    if ($staff && ($_POST['accion'] ?? '') === 'generar') {
        flash_resultado(ejecutar('sp_generar_fixture', [id_sesion(), $idTorneo]));
    }
    redirigir('fixture.php?torneo=' . $idTorneo);
}

$torneos = array_values(array_filter(leer('sp_torneo_listar', [null]), function ($t) { return $t['estado'] !== 'CANCELADO'; }));
$idTorneo = isset($_GET['torneo']) ? (int)$_GET['torneo'] : (int)($torneos[0]['id_torneo'] ?? 0);
$torneo = null;
foreach ($torneos as $t) {
    if ((int)$t['id_torneo'] === $idTorneo) $torneo = $t;
}
$partidas = $torneo ? leer('sp_partida_listar', [$idTorneo]) : [];
$posiciones = $torneo ? leer('sp_posiciones_torneo', [$idTorneo]) : [];
$premios = ($torneo && $torneo['estado'] === 'FINALIZADO') ? leer('sp_premiacion_listar', [$idTorneo]) : [];
$rondas = [];
foreach ($partidas as $p) {
    $rondas[$p['ronda']][] = $p;
}
$esElim = $torneo && $torneo['tipo_formato'] === 'ELIMINACION_DIRECTA';
$inscritos = $torneo ? $torneo['cupo_maximo'] - $torneo['cupos_disponibles'] : 0;
$totalRondas = $esElim && $inscritos > 1 ? (int)ceil(log($inscritos, 2)) : count($rondas);
function nombre_ronda($r, $total, $elim)
{
    if (!$elim) return 'Fecha ' . $r;
    $faltan = $total - $r;
    return $faltan === 0 ? 'Final' : ($faltan === 1 ? 'Semifinal' : ($faltan === 2 ? 'Cuartos de final' : 'Ronda ' . $r));
}

layout_inicio('Fixture y posiciones', 'g_fixture', 'Gestor 3 · SP_GENERAR_FIXTURE (cursor de equipos inscritos) · SP_POSICIONES_TORNEO');
?>
<form class="card shadow-sm mb-4" method="get">
    <div class="card-body row g-3 align-items-end">
        <div class="col-md-7">
            <label class="form-label">Torneo</label>
            <select class="form-select" name="torneo" onchange="this.form.submit()">
                <?= opciones($torneos, 'id_torneo', function ($t) { return $t['nombre'] . ' — ' . str_replace('_', ' ', $t['estado']); }, $idTorneo) ?>
            </select>
        </div>
        <?php if ($torneo): ?>
        <div class="col-md-5 d-flex gap-3 justify-content-md-end align-items-center">
            <div><div class="small text-secondary">Formato</div><div class="fw-semibold"><?= e($torneo['formato']) ?></div></div>
            <div><div class="small text-secondary">Estado</div><?= badge_estado($torneo['estado']) ?></div>
        </div>
        <?php endif; ?>
    </div>
</form>

<?php if ($torneo && $torneo['estado'] === 'ABIERTO'): ?>
<div class="alert alert-primary d-flex align-items-center gap-3">
    <i class="bi bi-shuffle fs-4"></i>
    <div class="flex-grow-1">Torneo abierto con <strong><?= e($torneo['cupo_maximo'] - $torneo['cupos_disponibles']) ?></strong> equipo(s) inscrito(s).
        Al generar el fixture se sortean los cruces, se asignan árbitros y el torneo pasa a <strong>En curso</strong> (se cierran las inscripciones).</div>
    <?php if ($staff): ?>
    <form method="post" onsubmit="return confirm('¿Generar el fixture? Se cerrarán las inscripciones.');">
        <?= csrf_campo() ?><input type="hidden" name="accion" value="generar"><input type="hidden" name="id_torneo" value="<?= e($idTorneo) ?>">
        <button class="btn btn-primary"><i class="bi bi-diagram-3"></i> Generar fixture</button>
    </form>
    <?php endif; ?>
</div>
<?php endif; ?>

<?php if ($premios): ?>
<div class="row g-3 mb-4">
    <?php foreach ($premios as $pr): $medalla = ['', 'gold', 'silver', 'bronze'][$pr['posicion']] ?? ''; ?>
        <div class="col-md-4"><div class="podio podio-<?= $medalla ?>">
            <i class="bi bi-trophy-fill"></i><div><div class="small"><?= e($pr['posicion']) ?>° lugar</div>
            <div class="fw-bold fs-5"><?= e($pr['equipo']) ?></div><div><?= monto($pr['monto']) ?></div></div>
        </div></div>
    <?php endforeach; ?>
</div>
<?php endif; ?>

<?php if ($posiciones): ?>
<div class="card shadow-sm mb-4">
    <div class="card-header"><i class="bi bi-list-ol me-1"></i>Tabla de posiciones</div>
    <div class="table-responsive">
        <table class="table table-sm align-middle mb-0 text-center">
            <thead><tr><th>#</th><th class="text-start">Equipo</th><th>PJ</th><th>PG</th><th>PE</th><th>PP</th><th>A favor</th><th>En contra</th><th>Dif.</th><th>Pts.</th></tr></thead>
            <tbody>
            <?php foreach ($posiciones as $p): ?>
                <tr>
                    <td class="fw-semibold"><?= e($p['posicion']) ?></td>
                    <td class="text-start"><?= e($p['equipo']) ?> <span class="small text-secondary">[<?= e($p['tag']) ?>]</span></td>
                    <td><?= e($p['pj']) ?></td><td><?= e($p['pg']) ?></td><td><?= e($p['pe']) ?></td><td><?= e($p['pp']) ?></td>
                    <td><?= e($p['a_favor']) ?></td><td><?= e($p['en_contra']) ?></td><td><?= e($p['diferencia']) ?></td>
                    <td class="fw-bold"><?= e($p['puntos']) ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php endif; ?>

<?php if ($rondas): ?>
<div class="<?= $esElim ? 'bracket' : 'row g-3' ?>">
    <?php foreach ($rondas as $r => $lista): ?>
        <div class="<?= $esElim ? 'bracket-col' : 'col-md-6 col-xl-4' ?>">
            <div class="card shadow-sm h-100">
                <div class="card-header fw-semibold"><?= e(nombre_ronda($r, $totalRondas, $esElim)) ?></div>
                <ul class="list-group list-group-flush">
                <?php foreach ($lista as $p):
                    $ganaL = $p['ganador'] !== null && $p['ganador'] === $p['local'];
                    $ganaV = $p['ganador'] !== null && $p['ganador'] === $p['visita']; ?>
                    <li class="list-group-item partida">
                        <div class="d-flex justify-content-between small text-secondary mb-1">
                            <span><?= fecha($p['fecha_hora']) ?></span><span><?= badge_estado($p['estado']) ?></span>
                        </div>
                        <div class="d-flex justify-content-between <?= $ganaL ? 'fw-bold' : '' ?>"><span><?= e($p['local']) ?></span><span><?= e($p['puntaje_local'] ?? '') ?></span></div>
                        <div class="d-flex justify-content-between <?= $ganaV ? 'fw-bold' : '' ?>"><span><?= e($p['visita']) ?></span><span><?= e($p['puntaje_visita'] ?? '') ?></span></div>
                        <?php if ($p['mvp'] || $p['arbitro'] !== ' '): ?>
                        <div class="small text-secondary mt-1">
                            <?php if ($p['mvp']): ?><i class="bi bi-star-fill text-warning"></i> MVP <?= e($p['mvp']) ?> · <?php endif; ?>
                            <?php if (trim((string)$p['arbitro'])): ?>Árbitro: <?= e($p['arbitro']) ?><?php endif; ?>
                        </div>
                        <?php endif; ?>
                    </li>
                <?php endforeach; ?>
                </ul>
            </div>
        </div>
    <?php endforeach; ?>
</div>
<?php elseif ($torneo && $torneo['estado'] !== 'ABIERTO'): ?>
    <div class="alert alert-secondary">El torneo no tiene partidas.</div>
<?php endif; ?>
<?php layout_fin();
