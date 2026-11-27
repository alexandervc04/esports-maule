<?php
/**
 * GESTOR 4 · Registro de resultados y KDA
 * Cruza Partida + Equipos + Jugadores + Árbitro -> SP_REGISTRAR_RESULTADO
 * (puntos según formato, estadísticas, MVP por cursor, avance de llaves y auditoría por trigger)
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN', 'ORGANIZADOR']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verificar_csrf();
    $idTorneo = (int)($_POST['id_torneo'] ?? 0);
    $idPartida = (int)($_POST['id_partida'] ?? 0);
    $stats = [];
    foreach ($_POST['k'] ?? [] as $idJug => $k) {
        $d = $_POST['d'][$idJug] ?? '';
        $a = $_POST['a'][$idJug] ?? '';
        if ($k === '' && $d === '' && $a === '') {
            continue;   // jugador sin estadísticas (ej. suplente que no jugó)
        }
        $stats[] = (int)$idJug . ':' . (int)$k . ':' . (int)$d . ':' . (int)$a;
    }
    $r = ejecutar('sp_registrar_resultado', [id_sesion(), $idPartida, $_POST['puntaje_local'] ?? null,
                                              $_POST['puntaje_visita'] ?? null, implode(';', $stats)]);
    flash_resultado($r);
    redirigir('resultados.php?torneo=' . $idTorneo . ($r['ok'] ? '' : '&partida=' . $idPartida));
}

$torneos = array_values(leer('sp_torneo_listar', ['EN_CURSO']));
$idTorneo = isset($_GET['torneo']) ? (int)$_GET['torneo'] : (int)($torneos[0]['id_torneo'] ?? 0);
$torneo = null;
foreach ($torneos as $t) {
    if ((int)$t['id_torneo'] === $idTorneo) $torneo = $t;
}
$partidas = $torneo ? leer('sp_partida_listar', [$idTorneo]) : [];
$idPartida = isset($_GET['partida']) ? (int)$_GET['partida'] : null;
$partida = null;
foreach ($partidas as $p) {
    if ((int)$p['id_partida'] === $idPartida) $partida = $p;
}
$detalle = $partida ? leer('sp_partida_detalle', [$idPartida]) : [];
$lados = ['LOCAL' => [], 'VISITA' => []];
foreach ($detalle as $d) {
    $lados[$d['lado']][] = $d;
}

layout_inicio('Resultados y KDA', 'g_resultados', 'Gestor 4 · SP_REGISTRAR_RESULTADO · MVP por cursor · auditoría TRG_AUDITORIA_MARCADORES');
?>
<?php if (!$torneos): ?>
    <div class="alert alert-secondary">No hay torneos en curso. Genere el fixture de un torneo abierto para comenzar a registrar resultados.</div>
<?php else: ?>
<form class="card shadow-sm mb-4" method="get">
    <div class="card-body row g-3 align-items-end">
        <div class="col-md-8">
            <label class="form-label">Torneo en curso</label>
            <select class="form-select" name="torneo" onchange="this.form.submit()">
                <?= opciones($torneos, 'id_torneo', 'nombre', $idTorneo) ?>
            </select>
        </div>
        <div class="col-md-4 text-md-end small text-secondary">
            <?= e($torneo['formato'] ?? '') ?> · <?= e($torneo['partidas_pendientes'] ?? 0) ?> partida(s) pendiente(s)
        </div>
    </div>
</form>

<?php if ($partida): ?>
<form method="post" class="card shadow-sm mb-4 border-primary">
    <?= csrf_campo() ?>
    <input type="hidden" name="id_torneo" value="<?= e($idTorneo) ?>">
    <input type="hidden" name="id_partida" value="<?= e($idPartida) ?>">
    <div class="card-header d-flex align-items-center">
        <span><i class="bi bi-joystick me-1"></i>Partida #<?= e($idPartida) ?> · Ronda <?= e($partida['ronda']) ?> · <?= fecha($partida['fecha_hora']) ?></span>
        <a class="ms-auto small" href="resultados.php?torneo=<?= e($idTorneo) ?>">cerrar</a>
    </div>
    <div class="card-body">
        <?php if ($partida['estado'] === 'JUGADA'): ?>
            <div class="alert alert-warning py-2"><i class="bi bi-pencil-square me-1"></i>Esta partida ya tiene resultado: la corrección revierte los puntos anteriores y queda registrada en la auditoría de marcadores.</div>
        <?php endif; ?>
        <div class="marcador mb-4">
            <div class="equipo"><?= e($partida['local']) ?></div>
            <input class="form-control form-control-lg text-center" type="number" min="0" name="puntaje_local" required value="<?= e($partida['puntaje_local']) ?>">
            <span class="vs">vs</span>
            <input class="form-control form-control-lg text-center" type="number" min="0" name="puntaje_visita" required value="<?= e($partida['puntaje_visita']) ?>">
            <div class="equipo"><?= e($partida['visita']) ?></div>
        </div>
        <div class="row g-3">
        <?php foreach ($lados as $lado => $lista): ?>
            <div class="col-lg-6">
                <h6 class="text-secondary"><?= $lado === 'LOCAL' ? e($partida['local']) : e($partida['visita']) ?></h6>
                <table class="table table-sm align-middle">
                    <thead><tr><th>Jugador</th><th style="width:80px">Kills</th><th style="width:80px">Deaths</th><th style="width:80px">Assists</th><th>KDA</th></tr></thead>
                    <tbody>
                    <?php foreach ($lista as $j): $id = (int)$j['id_jugador']; ?>
                        <tr>
                            <td><?= e($j['nickname']) ?><?= $j['es_titular'] === 'N' ? ' <span class="badge text-bg-light">Suplente</span>' : '' ?>
                                <?= $j['es_mvp'] === 'S' ? ' <i class="bi bi-star-fill text-warning" title="MVP"></i>' : '' ?></td>
                            <td><input class="form-control form-control-sm" type="number" min="0" name="k[<?= $id ?>]" value="<?= e($j['kills']) ?>"></td>
                            <td><input class="form-control form-control-sm" type="number" min="0" name="d[<?= $id ?>]" value="<?= e($j['deaths']) ?>"></td>
                            <td><input class="form-control form-control-sm" type="number" min="0" name="a[<?= $id ?>]" value="<?= e($j['assists']) ?>"></td>
                            <td class="small"><?= $j['kda'] !== null ? numero($j['kda'], 2) : '—' ?></td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endforeach; ?>
        </div>
        <small class="text-secondary">Deje en blanco a los jugadores que no participaron. El MVP se calcula automáticamente (mejor ratio KDA).</small>
    </div>
    <div class="card-footer"><button class="btn btn-primary"><i class="bi bi-save"></i> Guardar resultado</button></div>
</form>
<?php endif; ?>

<div class="card shadow-sm">
    <div class="card-header"><i class="bi bi-calendar-event me-1"></i>Partidas del torneo</div>
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead><tr><th>Ronda</th><th>Fecha</th><th class="text-end">Local</th><th class="text-center">Marcador</th><th>Visita</th><th>Árbitro</th><th>MVP</th><th>Estado</th><th></th></tr></thead>
            <tbody>
            <?php foreach ($partidas as $p): ?>
                <tr class="<?= (int)$p['id_partida'] === $idPartida ? 'table-primary' : '' ?>">
                    <td><?= e($p['ronda']) ?></td>
                    <td class="small text-nowrap"><?= fecha($p['fecha_hora']) ?></td>
                    <td class="text-end <?= $p['ganador'] === $p['local'] ? 'fw-bold' : '' ?>"><?= e($p['local']) ?></td>
                    <td class="text-center fw-semibold"><?= $p['estado'] === 'JUGADA' ? e($p['puntaje_local'] . ' - ' . $p['puntaje_visita']) : '—' ?></td>
                    <td class="<?= $p['ganador'] === $p['visita'] ? 'fw-bold' : '' ?>"><?= e($p['visita']) ?></td>
                    <td class="small"><?= e(trim((string)$p['arbitro']) ?: '—') ?></td>
                    <td class="small"><?= e($p['mvp'] ?? '—') ?></td>
                    <td><?= badge_estado($p['estado']) ?></td>
                    <td class="text-end">
                        <?php if (in_array($p['estado'], ['PROGRAMADA', 'JUGADA'], true)): ?>
                            <a class="btn btn-sm <?= $p['estado'] === 'PROGRAMADA' ? 'btn-primary' : 'btn-outline-secondary' ?>"
                               href="resultados.php?torneo=<?= e($idTorneo) ?>&partida=<?= e($p['id_partida']) ?>">
                                <?= $p['estado'] === 'PROGRAMADA' ? 'Registrar' : 'Corregir' ?></a>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php endif; ?>
<?php layout_fin();
