<?php
/**
 * GESTOR 2 · Inscripción de equipos y roster
 * Cruza Torneo + Equipo + Jugadores -> SP_INSCRIBIR_EQUIPO (cupos, sanciones, edad, tamaño de plantilla)
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN', 'ORGANIZADOR', 'CAPITAN']);

$esCapitan = es('CAPITAN');
$miEquipo = $_SESSION['usuario']['id_equipo'] ?? null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verificar_csrf();
    $idTorneo = (int)($_POST['id_torneo'] ?? 0);
    if (($_POST['accion'] ?? '') === 'inscribir') {
        $plantilla = [];
        foreach ($_POST['rol'] ?? [] as $idJugador => $rol) {
            if ($rol === 'S' || $rol === 'N') {
                $plantilla[] = (int)$idJugador . ':' . $rol;
            }
        }
        $idEquipo = $esCapitan ? $miEquipo : ($_POST['id_equipo'] ?? null);
        $r = ejecutar('sp_inscribir_equipo', [id_sesion(), $idTorneo, $idEquipo, implode(';', $plantilla)], true);
        flash_resultado($r);
        redirigir('inscripciones.php?torneo=' . $idTorneo . ($r['ok'] ? '' : '&equipo=' . (int)$idEquipo));
    }
    if (($_POST['accion'] ?? '') === 'retirar') {
        flash_resultado(ejecutar('sp_retirar_inscripcion', [id_sesion(), $_POST['id_inscripcion'] ?? null]));
    }
    redirigir('inscripciones.php?torneo=' . $idTorneo);
}

$torneos = array_values(array_filter(leer('sp_torneo_listar', [null]), function ($t) { return $t['estado'] !== 'CANCELADO'; }));
$idTorneo = isset($_GET['torneo']) ? (int)$_GET['torneo'] : (int)($torneos[0]['id_torneo'] ?? 0);
$torneo = null;
foreach ($torneos as $t) {
    if ((int)$t['id_torneo'] === $idTorneo) $torneo = $t;
}
$equipos = array_filter(leer('sp_equipo_listar'), function ($e) { return $e['estado'] === 'ACTIVO'; });
$idEquipo = $esCapitan ? $miEquipo : (isset($_GET['equipo']) ? (int)$_GET['equipo'] : null);
$inscripciones = $torneo ? leer('sp_inscripcion_listar', [$idTorneo]) : [];
$jugadores = ($torneo && $idEquipo) ? leer('sp_jugadores_equipo', [$idEquipo]) : [];
$yaInscrito = false;
foreach ($inscripciones as $i) {
    if ((int)$i['id_equipo'] === (int)$idEquipo && $i['estado'] === 'CONFIRMADA') $yaInscrito = true;
}

layout_inicio('Inscripción de equipos y roster', 'g_inscripciones', 'Gestor 2 · SP_INSCRIBIR_EQUIPO valida cupos (con bloqueo FOR UPDATE), sanciones, edad y plantilla');
?>
<form class="card shadow-sm mb-4" method="get">
    <div class="card-body row g-3 align-items-end">
        <div class="col-md-6">
            <label class="form-label">Torneo</label>
            <select class="form-select" name="torneo" onchange="this.form.submit()">
                <?= opciones($torneos, 'id_torneo', function ($t) { return $t['nombre'] . ' — ' . str_replace('_', ' ', $t['estado']); }, $idTorneo) ?>
            </select>
        </div>
        <?php if ($torneo && $torneo['estado'] === 'ABIERTO'): ?>
        <div class="col-md-4">
            <label class="form-label">Equipo a inscribir</label>
            <?php if ($esCapitan): ?>
                <input class="form-control" disabled value="<?= e(current(array_filter($equipos, function ($e) use ($miEquipo) { return (int)$e['id_equipo'] === (int)$miEquipo; }))['nombre'] ?? 'Sin equipo asignado') ?>">
            <?php else: ?>
                <select class="form-select" name="equipo" onchange="this.form.submit()">
                    <?= opciones($equipos, 'id_equipo', 'nombre', $idEquipo, 'Seleccione un equipo...') ?>
                </select>
            <?php endif; ?>
        </div>
        <?php endif; ?>
        <?php if ($torneo): ?>
        <div class="col-md-2 text-md-end">
            <div class="small text-secondary">Cupos</div>
            <div class="fs-5 fw-semibold"><?= e($torneo['cupo_maximo'] - $torneo['cupos_disponibles']) ?> / <?= e($torneo['cupo_maximo']) ?></div>
        </div>
        <?php endif; ?>
    </div>
</form>

<?php if ($torneo && $torneo['estado'] === 'ABIERTO' && $idEquipo && !$yaInscrito): ?>
<form method="post" class="card shadow-sm mb-4">
    <?= csrf_campo() ?>
    <input type="hidden" name="accion" value="inscribir">
    <input type="hidden" name="id_torneo" value="<?= e($idTorneo) ?>">
    <input type="hidden" name="id_equipo" value="<?= e($idEquipo) ?>">
    <div class="card-header d-flex align-items-center gap-3">
        <span><i class="bi bi-people me-1"></i>Plantilla para <strong><?= e($torneo['videojuego']) ?></strong>
            (<?= e($torneo['jugadores_por_equipo']) ?> titulares, hasta 2 suplentes) · Inscripción <?= monto($torneo['costo_inscripcion']) ?></span>
        <span id="contadorTitulares" class="badge text-bg-warning ms-auto"></span>
    </div>
    <div class="table-responsive">
        <table class="table align-middle mb-0" data-plantilla="<?= e($torneo['jugadores_por_equipo']) ?>">
            <thead><tr><th>Jugador</th><th>Nombre</th><th>Rol</th><th>Edad</th><th>Estado disciplinario</th><th class="text-center">Titular</th><th class="text-center">Suplente</th><th class="text-center">No va</th></tr></thead>
            <tbody>
            <?php foreach ($jugadores as $n => $j): $id = (int)$j['id_jugador'];
                $def = $n < $torneo['jugadores_por_equipo'] ? 'S' : '-'; ?>
                <tr class="<?= $j['estado_disciplinario'] !== 'HABILITADO' ? 'table-danger' : '' ?>">
                    <td class="fw-semibold"><?= e($j['nickname']) ?></td>
                    <td><?= e($j['nombre']) ?></td>
                    <td><?= e($j['rol_juego']) ?></td>
                    <td><?= e($j['edad']) ?></td>
                    <td><?= badge_estado($j['estado_disciplinario']) ?></td>
                    <?php foreach (['S', 'N', '-'] as $op): ?>
                        <td class="text-center"><input class="form-check-input" type="radio" name="rol[<?= $id ?>]" value="<?= $op ?>"<?= $def === $op ? ' checked' : '' ?>></td>
                    <?php endforeach; ?>
                </tr>
            <?php endforeach; ?>
            <?php if (!$jugadores): ?><tr><td colspan="8" class="text-center text-secondary py-3">El equipo no tiene jugadores registrados.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
    <div class="card-footer d-flex gap-2 align-items-center">
        <button class="btn btn-primary"><i class="bi bi-check2-circle"></i> Confirmar inscripción</button>
        <small class="text-secondary">Los jugadores sancionados se marcan en rojo; si se incluyen, la base de datos rechaza la inscripción (TRG_BLOQUEAR_SANCIONADO).</small>
    </div>
</form>
<?php elseif ($torneo && $yaInscrito && $idEquipo): ?>
    <div class="alert alert-info">El equipo seleccionado ya está inscrito en este torneo.</div>
<?php elseif ($torneo && $torneo['estado'] !== 'ABIERTO'): ?>
    <div class="alert alert-secondary">Este torneo está <strong><?= e(strtolower(str_replace('_', ' ', $torneo['estado']))) ?></strong>: solo se muestran sus inscripciones.</div>
<?php endif; ?>

<div class="card shadow-sm">
    <div class="card-header"><i class="bi bi-card-checklist me-1"></i>Equipos inscritos <?= $torneo ? '· ' . e($torneo['nombre']) : '' ?></div>
    <div class="table-responsive">
        <table class="table align-middle mb-0">
            <thead><tr><th>Equipo</th><th>Plantilla (S = suplente)</th><th>Fecha</th><th class="text-end">Pagado</th><th>Puntos</th><th>Estado</th><th></th></tr></thead>
            <tbody>
            <?php foreach ($inscripciones as $i): ?>
                <tr>
                    <td class="fw-semibold"><?= e($i['equipo']) ?> <span class="text-secondary small">[<?= e($i['tag']) ?>]</span></td>
                    <td class="small"><?= e($i['plantilla']) ?></td>
                    <td class="small text-nowrap"><?= fecha($i['fecha_inscripcion']) ?></td>
                    <td class="text-end"><?= monto($i['monto_pagado']) ?></td>
                    <td><?= e($i['puntos']) ?></td>
                    <td><?= badge_estado($i['estado']) ?></td>
                    <td class="text-end">
                        <?php if ($torneo['estado'] === 'ABIERTO' && $i['estado'] === 'CONFIRMADA' && (!$esCapitan || (int)$i['id_equipo'] === (int)$miEquipo)): ?>
                        <form method="post" onsubmit="return confirm('¿Retirar la inscripción de este equipo?');">
                            <?= csrf_campo() ?><input type="hidden" name="accion" value="retirar">
                            <input type="hidden" name="id_torneo" value="<?= e($idTorneo) ?>"><input type="hidden" name="id_inscripcion" value="<?= e($i['id_inscripcion']) ?>">
                            <button class="btn btn-sm btn-outline-danger"><i class="bi bi-box-arrow-left"></i> Retirar</button>
                        </form>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$inscripciones): ?><tr><td colspan="7" class="text-center text-secondary py-4">Sin inscripciones.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</div>
<?php layout_fin();
