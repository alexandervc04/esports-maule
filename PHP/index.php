<?php
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_login();

$kpi = leer('sp_resumen_panel')[0] ?? [];
$torneos = leer('sp_torneo_listar', [null]);
$activos = array_filter($torneos, function ($t) { return in_array($t['estado'], ['ABIERTO', 'EN_CURSO'], true); });

layout_inicio('Panel principal', 'panel', 'Resumen general del sistema · SP_RESUMEN_PANEL');
$tarjetas = [
    ['Torneos en curso', $kpi['torneos_en_curso'] ?? 0, 'broadcast', 'warning'],
    ['Torneos abiertos', $kpi['torneos_abiertos'] ?? 0, 'door-open', 'primary'],
    ['Equipos activos', $kpi['equipos'] ?? 0, 'shield', 'info'],
    ['Jugadores', $kpi['jugadores'] ?? 0, 'people', 'success'],
    ['Partidas jugadas', $kpi['partidas_jugadas'] ?? 0, 'joystick', 'secondary'],
    ['Sanciones vigentes', $kpi['sanciones_vigentes'] ?? 0, 'shield-exclamation', 'danger'],
];
?>
<div class="row g-3 mb-4">
    <?php foreach ($tarjetas as [$t, $v, $i, $c]): ?>
        <div class="col-6 col-md-4 col-xl-2">
            <div class="kpi kpi-<?= $c ?>">
                <i class="bi bi-<?= $i ?>"></i>
                <div class="kpi-valor"><?= numero($v) ?></div>
                <div class="kpi-texto"><?= e($t) ?></div>
            </div>
        </div>
    <?php endforeach; ?>
</div>
<?php if (es(['ADMIN', 'ORGANIZADOR'])): ?>
<div class="row g-3 mb-4">
    <div class="col-md-6">
        <div class="kpi kpi-wide"><div class="kpi-texto">Recaudación por inscripciones</div>
            <div class="kpi-valor"><?= monto($kpi['recaudacion_total'] ?? 0) ?></div></div>
    </div>
    <div class="col-md-6">
        <div class="kpi kpi-wide"><div class="kpi-texto">Premios liquidados</div>
            <div class="kpi-valor"><?= monto($kpi['premios_pagados'] ?? 0) ?></div></div>
    </div>
</div>
<?php endif; ?>

<div class="card shadow-sm">
    <div class="card-header"><i class="bi bi-trophy me-1"></i>Torneos abiertos y en curso</div>
    <div class="table-responsive">
        <table class="table align-middle mb-0">
            <thead><tr><th>Torneo</th><th>Juego</th><th>Sede</th><th>Formato</th><th>Fechas</th><th>Cupos</th><th>Partidas pendientes</th><th>Estado</th><th></th></tr></thead>
            <tbody>
            <?php foreach ($activos as $t): ?>
                <tr>
                    <td class="fw-semibold"><?= e($t['nombre']) ?></td>
                    <td><?= e($t['videojuego']) ?></td>
                    <td><?= e($t['sede']) ?></td>
                    <td><?= e($t['formato']) ?></td>
                    <td class="text-nowrap"><?= fecha($t['fecha_inicio']) ?> → <?= fecha($t['fecha_fin']) ?></td>
                    <td><?= e($t['cupo_maximo'] - $t['cupos_disponibles']) ?> / <?= e($t['cupo_maximo']) ?></td>
                    <td><?= e($t['partidas_pendientes']) ?></td>
                    <td><?= badge_estado($t['estado']) ?></td>
                    <td class="text-end"><a class="btn btn-sm btn-outline-primary" href="fixture.php?torneo=<?= e($t['id_torneo']) ?>">Ver fixture</a></td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$activos): ?><tr><td colspan="9" class="text-center text-secondary py-4">No hay torneos activos.</td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</div>
<?php layout_fin();
