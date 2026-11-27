<?php
/**
 * GESTOR 5 · Sanciones y premiación
 * SP_REGISTRAR_SANCION (descuento de puntos / suspensión vía TRG_SANCION_SUSPENDER),
 * SP_ANULAR_SANCION, SP_PROCESAR_SANCIONES_VENCIDAS (cursor) y SP_LIQUIDAR_PREMIOS (cursor de posiciones).
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN', 'ORGANIZADOR']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verificar_csrf();
    $idTorneo = (int)($_POST['id_torneo'] ?? 0);
    switch ($_POST['accion'] ?? '') {
        case 'sancionar':
            $r = ejecutar('sp_registrar_sancion', [id_sesion(), $idTorneo, $_POST['id_jugador'] ?? null,
                $_POST['id_arbitro'] ?? null, $_POST['tipo'] ?? null, $_POST['motivo'] ?? null,
                $_POST['puntos_descuento'] ?? null, $_POST['dias_suspension'] ?? null], true);
            break;
        case 'anular':
            $r = ejecutar('sp_anular_sancion', [id_sesion(), $_POST['id_sancion'] ?? null]);
            break;
        case 'vencidas':
            $r = ejecutar('sp_procesar_sanciones_vencidas', [id_sesion()]);
            break;
        case 'liquidar':
            $r = ejecutar('sp_liquidar_premios', [id_sesion(), $idTorneo]);
            break;
        default:
            $r = ['ok' => false, 'mensaje' => 'Acción no válida.'];
    }
    flash_resultado($r);
    redirigir('sanciones.php' . ($idTorneo ? '?torneo=' . $idTorneo : ''));
}

$todos = leer('sp_torneo_listar', [null]);
$activos = array_values(array_filter($todos, function ($t) { return in_array($t['estado'], ['ABIERTO', 'EN_CURSO'], true); }));
$idTorneo = isset($_GET['torneo']) ? (int)$_GET['torneo'] : (int)($activos[0]['id_torneo'] ?? 0);
$jugadores = $idTorneo ? leer('sp_jugadores_torneo', [$idTorneo]) : [];
$arbitros = array_filter(leer('sp_arbitro_listar'), function ($a) { return $a['estado'] === 'ACTIVO'; });
$sanciones = leer('sp_sancion_listar', [null]);
$enCurso = array_filter($todos, function ($t) { return $t['estado'] === 'EN_CURSO'; });
$premios = leer('sp_premiacion_listar', [null]);

layout_inicio('Sanciones y premiación', 'g_sanciones', 'Gestor 5 · SP_REGISTRAR_SANCION · SP_PROCESAR_SANCIONES_VENCIDAS · SP_LIQUIDAR_PREMIOS');
?>
<ul class="nav nav-tabs mb-3" role="tablist">
    <li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tabSanciones" type="button"><i class="bi bi-shield-exclamation me-1"></i>Sanciones</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabPremios" type="button"><i class="bi bi-award me-1"></i>Premiación</button></li>
</ul>
<div class="tab-content">
<div class="tab-pane fade show active" id="tabSanciones">
    <div class="row g-4">
        <div class="col-xl-5">
            <form class="card shadow-sm" method="get">
                <div class="card-body">
                    <label class="form-label">Torneo (abierto o en curso)</label>
                    <select class="form-select" name="torneo" onchange="this.form.submit()">
                        <?= opciones($activos, 'id_torneo', 'nombre', $idTorneo) ?>
                    </select>
                </div>
            </form>
            <form class="card shadow-sm mt-3" method="post">
                <?= csrf_campo() ?>
                <input type="hidden" name="accion" value="sancionar">
                <input type="hidden" name="id_torneo" value="<?= e($idTorneo) ?>">
                <div class="card-header"><i class="bi bi-flag me-1"></i>Registrar sanción</div>
                <div class="card-body row g-3">
                    <div class="col-12">
                        <label class="form-label">Jugador *</label>
                        <select class="form-select" name="id_jugador" required>
                            <?= opciones($jugadores, 'id_jugador', function ($j) { return $j['nickname'] . ' · ' . $j['equipo'] . ($j['estado_disciplinario'] !== 'HABILITADO' ? ' (' . $j['estado_disciplinario'] . ')' : ''); }, null, 'Seleccione...') ?>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Árbitro que sanciona *</label>
                        <select class="form-select" name="id_arbitro" required>
                            <?= opciones($arbitros, 'id_arbitro', 'nombre_completo', null, 'Seleccione...') ?>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Tipo *</label>
                        <select class="form-select" name="tipo" id="tipoSancion" required>
                            <option value="AMONESTACION">Amonestación</option>
                            <option value="DESCUENTO_PUNTOS">Descuento de puntos al equipo</option>
                            <option value="SUSPENSION">Suspensión del jugador</option>
                        </select>
                    </div>
                    <div class="col-md-6" id="grpPuntos"><label class="form-label">Puntos a descontar</label><input class="form-control" type="number" min="1" name="puntos_descuento" value="1"></div>
                    <div class="col-md-6" id="grpDias"><label class="form-label">Días de suspensión</label><input class="form-control" type="number" min="1" name="dias_suspension" value="7"></div>
                    <div class="col-12"><label class="form-label">Motivo *</label><textarea class="form-control" name="motivo" rows="2" required minlength="10" placeholder="Describa la infracción"></textarea></div>
                </div>
                <div class="card-footer"><button class="btn btn-danger" <?= $jugadores ? '' : 'disabled' ?>><i class="bi bi-flag-fill"></i> Aplicar sanción</button></div>
            </form>
        </div>
        <div class="col-xl-7">
            <div class="card shadow-sm">
                <div class="card-header d-flex align-items-center">
                    <span><i class="bi bi-list-check me-1"></i>Historial de sanciones</span>
                    <form method="post" class="ms-auto">
                        <?= csrf_campo() ?><input type="hidden" name="accion" value="vencidas">
                        <button class="btn btn-sm btn-outline-secondary"><i class="bi bi-arrow-repeat"></i> Procesar suspensiones vencidas</button>
                    </form>
                </div>
                <div class="table-responsive">
                    <table class="table table-sm align-middle mb-0">
                        <thead><tr><th>Fecha</th><th>Jugador</th><th>Torneo</th><th>Tipo</th><th>Detalle</th><th>Estado</th><th></th></tr></thead>
                        <tbody>
                        <?php foreach ($sanciones as $s): ?>
                            <tr>
                                <td class="small text-nowrap"><?= fecha($s['fecha_sancion']) ?></td>
                                <td class="fw-semibold"><?= e($s['nickname']) ?></td>
                                <td class="small"><?= e($s['torneo']) ?></td>
                                <td class="small"><?= e(ucfirst(strtolower(str_replace('_', ' ', $s['tipo'])))) ?>
                                    <?= $s['puntos_descuento'] > 0 ? '<span class="badge text-bg-danger">-' . e($s['puntos_descuento']) . ' pts</span>' : '' ?>
                                    <?= $s['fecha_fin_suspension'] ? '<div class="text-secondary">hasta ' . fecha($s['fecha_fin_suspension']) . '</div>' : '' ?></td>
                                <td class="small"><?= e($s['motivo']) ?><div class="text-secondary">Árbitro: <?= e($s['arbitro']) ?></div></td>
                                <td><?= badge_estado($s['estado']) ?></td>
                                <td>
                                    <?php if ($s['estado'] === 'VIGENTE'): ?>
                                    <form method="post" onsubmit="return confirm('¿Anular esta sanción?');">
                                        <?= csrf_campo() ?><input type="hidden" name="accion" value="anular"><input type="hidden" name="id_sancion" value="<?= e($s['id_sancion']) ?>">
                                        <button class="btn btn-sm btn-outline-secondary" title="Anular"><i class="bi bi-arrow-counterclockwise"></i></button>
                                    </form>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        <?php if (!$sanciones): ?><tr><td colspan="7" class="text-center text-secondary py-3">Sin sanciones registradas.</td></tr><?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="tab-pane fade" id="tabPremios">
    <div class="row g-4">
        <div class="col-xl-5">
            <div class="card shadow-sm">
                <div class="card-header"><i class="bi bi-cash-coin me-1"></i>Liquidar premios (50% · 30% · 20%)</div>
                <ul class="list-group list-group-flush">
                    <?php foreach ($enCurso as $t): $listo = (int)$t['partidas_pendientes'] === 0 && (int)$t['partidas_total'] > 0; ?>
                        <li class="list-group-item d-flex align-items-center gap-2">
                            <div class="flex-grow-1"><div class="fw-semibold"><?= e($t['nombre']) ?></div>
                                <small class="text-secondary">Bolsa <?= monto($t['premio_total']) ?> · <?= e($t['partidas_pendientes']) ?> partida(s) pendiente(s)</small></div>
                            <form method="post" onsubmit="return confirm('¿Liquidar premios y finalizar el torneo?');">
                                <?= csrf_campo() ?><input type="hidden" name="accion" value="liquidar"><input type="hidden" name="id_torneo" value="<?= e($t['id_torneo']) ?>">
                                <button class="btn btn-sm <?= $listo ? 'btn-success' : 'btn-outline-secondary' ?>"><i class="bi bi-award"></i> Liquidar</button>
                            </form>
                        </li>
                    <?php endforeach; ?>
                    <?php if (!$enCurso): ?><li class="list-group-item text-secondary">No hay torneos en curso.</li><?php endif; ?>
                </ul>
                <div class="card-footer small text-secondary">La BD verifica que no queden partidas pendientes y recorre la tabla de posiciones con un cursor.</div>
            </div>
        </div>
        <div class="col-xl-7">
            <div class="card shadow-sm">
                <div class="card-header"><i class="bi bi-trophy me-1"></i>Premios liquidados</div>
                <div class="table-responsive">
                    <table class="table table-sm align-middle mb-0">
                        <thead><tr><th>Torneo</th><th>Lugar</th><th>Equipo</th><th class="text-end">Monto</th><th>Fecha</th></tr></thead>
                        <tbody>
                        <?php foreach ($premios as $p): ?>
                            <tr><td><?= e($p['torneo']) ?></td><td><?= e($p['posicion']) ?>°</td><td class="fw-semibold"><?= e($p['equipo']) ?></td>
                                <td class="text-end"><?= monto($p['monto']) ?></td><td class="small"><?= fecha($p['fecha']) ?></td></tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
</div>
<?php layout_fin();
