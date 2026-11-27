<?php
/**
 * GESTOR 1 · Apertura de torneos
 * Cruza Videojuego + Plataforma + Sede + Formato + Categoría + Patrocinadores -> SP_ABRIR_TORNEO
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN', 'ORGANIZADOR']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verificar_csrf();
    $accion = $_POST['accion'] ?? '';
    if ($accion === 'abrir') {
        // Patrocinios seleccionados -> 'id:monto;id:monto' (se procesan en la BD)
        $pat = [];
        foreach ($_POST['pat'] ?? [] as $idPat => $_) {
            $pat[] = (int)$idPat . ':' . (int)($_POST['monto'][$idPat] ?? 0);
        }
        $r = ejecutar('sp_abrir_torneo', [
            id_sesion(), $_POST['nombre'] ?? '', $_POST['id_videojuego'] ?? null, $_POST['id_plataforma'] ?? null,
            $_POST['id_sede'] ?? null, $_POST['id_formato'] ?? null, $_POST['id_categoria'] ?? null,
            $_POST['fecha_inicio'] ?? null, $_POST['fecha_fin'] ?? null, $_POST['cupo_maximo'] ?? null,
            $_POST['costo_inscripcion'] ?? 0, $_POST['premio_total'] ?? 0, implode(';', $pat),
        ], true);
    } elseif ($accion === 'cancelar') {
        $r = ejecutar('sp_torneo_cancelar', [id_sesion(), $_POST['id_torneo'] ?? null]);
    } else {
        $r = ['ok' => false, 'mensaje' => 'Acción no válida.'];
    }
    flash_resultado($r);
    redirigir('torneos.php');
}

$torneos = leer('sp_torneo_listar', [null]);
$juegos = array_filter(leer('sp_videojuego_listar'), function ($j) { return $j['estado'] === 'ACTIVO'; });
$plataformas = leer('sp_plataforma_listar');
$sedes = array_filter(leer('sp_sede_listar'), function ($s) { return $s['estado'] === 'ACTIVO'; });
$formatos = leer('sp_formato_listar');
$categorias = leer('sp_categoria_listar');
$patrocinadores = leer('sp_patrocinador_listar');
$ver = isset($_GET['ver']) ? (int)$_GET['ver'] : null;
$detallePat = $ver ? leer('sp_torneo_patrocinios_listar', [$ver]) : [];

layout_inicio('Apertura de torneos', 'g_torneos', 'Gestor 1 · SP_ABRIR_TORNEO cruza juego, plataforma, sede, formato, categoría y patrocinadores');
?>
<div class="card shadow-sm mb-4">
    <div class="card-header d-flex align-items-center">
        <span><i class="bi bi-plus-circle me-1"></i>Abrir nuevo torneo</span>
        <button class="btn btn-sm btn-outline-primary ms-auto" data-bs-toggle="collapse" data-bs-target="#formTorneo">Mostrar / ocultar</button>
    </div>
    <div class="collapse<?= $torneos ? '' : ' show' ?>" id="formTorneo">
    <form method="post" class="card-body">
        <?= csrf_campo() ?>
        <input type="hidden" name="accion" value="abrir">
        <div class="row g-3">
            <div class="col-md-6">
                <label class="form-label">Nombre del torneo *</label>
                <input class="form-control" name="nombre" required maxlength="100" placeholder="Ej. Copa Maule Valorant Verano 2027">
            </div>
            <div class="col-md-3">
                <label class="form-label">Videojuego *</label>
                <select class="form-select" name="id_videojuego" required>
                    <?= opciones($juegos, 'id_videojuego', function ($j) { return $j['nombre'] . ' (' . $j['jugadores_por_equipo'] . ' vs ' . $j['jugadores_por_equipo'] . ')'; }, null, 'Seleccione...') ?>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label">Plataforma *</label>
                <select class="form-select" name="id_plataforma" required><?= opciones($plataformas, 'id_plataforma', 'nombre', null, 'Seleccione...') ?></select>
            </div>
            <div class="col-md-4">
                <label class="form-label">Sede *</label>
                <select class="form-select" name="id_sede" required>
                    <?= opciones($sedes, 'id_sede', function ($s) { return $s['nombre'] . ' · ' . ucfirst(strtolower($s['modalidad'])) . ' · ' . $s['capacidad'] . ' pers.'; }, null, 'Seleccione...') ?>
                </select>
            </div>
            <div class="col-md-4">
                <label class="form-label">Formato *</label>
                <select class="form-select" name="id_formato" required><?= opciones($formatos, 'id_formato', 'nombre', null, 'Seleccione...') ?></select>
            </div>
            <div class="col-md-4">
                <label class="form-label">Categoría *</label>
                <select class="form-select" name="id_categoria" required><?= opciones($categorias, 'id_categoria', 'nombre', null, 'Seleccione...') ?></select>
            </div>
            <div class="col-md-2"><label class="form-label">Inicio *</label><input class="form-control" type="date" name="fecha_inicio" required></div>
            <div class="col-md-2"><label class="form-label">Término *</label><input class="form-control" type="date" name="fecha_fin" required></div>
            <div class="col-md-2"><label class="form-label">Cupo (equipos) *</label><input class="form-control" type="number" name="cupo_maximo" min="2" max="128" value="8" required></div>
            <div class="col-md-3"><label class="form-label">Costo inscripción ($)</label><input class="form-control" type="number" name="costo_inscripcion" min="0" step="1000" value="20000"></div>
            <div class="col-md-3"><label class="form-label">Bolsa de premios ($)</label><input class="form-control" type="number" name="premio_total" min="0" step="1000" value="300000"></div>
            <div class="col-12">
                <label class="form-label">Patrocinadores y aporte</label>
                <div class="row g-2">
                <?php foreach ($patrocinadores as $p): $id = (int)$p['id_patrocinador']; ?>
                    <div class="col-md-6 col-xl-4">
                        <div class="input-group input-group-sm">
                            <div class="input-group-text"><input class="form-check-input mt-0" type="checkbox" name="pat[<?= $id ?>]" data-patrocinio="m<?= $id ?>"></div>
                            <span class="input-group-text flex-grow-1 text-truncate"><?= e($p['razon_social']) ?></span>
                            <input class="form-control" style="max-width:120px" type="number" min="0" step="10000" name="monto[<?= $id ?>]" id="m<?= $id ?>" value="100000" disabled>
                        </div>
                    </div>
                <?php endforeach; ?>
                </div>
            </div>
        </div>
        <div class="mt-3 d-flex gap-2 align-items-center">
            <button class="btn btn-primary"><i class="bi bi-trophy"></i> Abrir torneo</button>
            <small class="text-secondary">La BD valida aforo de la sede (cupo × jugadores), choque de fechas, estado del juego y la sede.</small>
        </div>
    </form>
    </div>
</div>

<?php if ($ver): ?>
<div class="card shadow-sm mb-4">
    <div class="card-header"><i class="bi bi-briefcase me-1"></i>Patrocinios del torneo #<?= $ver ?> <a class="float-end small" href="torneos.php">cerrar</a></div>
    <ul class="list-group list-group-flush">
        <?php foreach ($detallePat as $p): ?>
            <li class="list-group-item d-flex"><span><?= e($p['razon_social']) ?> <small class="text-secondary">· <?= e($p['rubro']) ?></small></span><span class="ms-auto fw-semibold"><?= monto($p['monto_aporte']) ?></span></li>
        <?php endforeach; ?>
        <?php if (!$detallePat): ?><li class="list-group-item text-secondary">Sin patrocinios.</li><?php endif; ?>
    </ul>
</div>
<?php endif; ?>

<div class="card shadow-sm">
    <div class="card-header d-flex align-items-center gap-2">
        <span><i class="bi bi-list-ul me-1"></i>Torneos registrados</span>
        <input type="search" class="form-control form-control-sm ms-auto" style="max-width:260px" placeholder="Buscar..." data-filtro="#tablaTorneos">
    </div>
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" id="tablaTorneos">
            <thead><tr><th>#</th><th>Torneo</th><th>Juego / plataforma</th><th>Sede</th><th>Formato · categoría</th><th>Fechas</th>
                <th>Cupos</th><th class="text-end">Recaudación</th><th class="text-end">Patrocinio</th><th class="text-end">Premios</th><th>Estado</th><th></th></tr></thead>
            <tbody>
            <?php foreach ($torneos as $t): ?>
                <tr>
                    <td class="text-secondary"><?= e($t['id_torneo']) ?></td>
                    <td class="fw-semibold"><?= e($t['nombre']) ?><div class="small text-secondary">Org.: <?= e($t['organizador']) ?></div></td>
                    <td><?= e($t['videojuego']) ?><div class="small text-secondary"><?= e($t['plataforma']) ?></div></td>
                    <td><?= e($t['sede']) ?></td>
                    <td><?= e($t['formato']) ?><div class="small text-secondary"><?= e($t['categoria']) ?></div></td>
                    <td class="text-nowrap small"><?= fecha($t['fecha_inicio']) ?><br><?= fecha($t['fecha_fin']) ?></td>
                    <td><?= e($t['cupo_maximo'] - $t['cupos_disponibles']) ?>/<?= e($t['cupo_maximo']) ?></td>
                    <td class="text-end"><?= monto($t['recaudacion']) ?></td>
                    <td class="text-end"><a href="torneos.php?ver=<?= e($t['id_torneo']) ?>"><?= monto($t['patrocinio']) ?></a></td>
                    <td class="text-end"><?= monto($t['premio_total']) ?></td>
                    <td><?= badge_estado($t['estado']) ?></td>
                    <td class="text-end text-nowrap">
                        <a class="btn btn-sm btn-outline-primary" href="inscripciones.php?torneo=<?= e($t['id_torneo']) ?>" title="Inscripciones"><i class="bi bi-person-plus"></i></a>
                        <a class="btn btn-sm btn-outline-primary" href="fixture.php?torneo=<?= e($t['id_torneo']) ?>" title="Fixture"><i class="bi bi-diagram-3"></i></a>
                        <?php if (in_array($t['estado'], ['ABIERTO', 'EN_CURSO'], true)): ?>
                        <form method="post" class="d-inline" onsubmit="return confirm('¿Cancelar el torneo? Las partidas pendientes se anularán.');">
                            <?= csrf_campo() ?><input type="hidden" name="accion" value="cancelar"><input type="hidden" name="id_torneo" value="<?= e($t['id_torneo']) ?>">
                            <button class="btn btn-sm btn-outline-danger" title="Cancelar torneo"><i class="bi bi-x-circle"></i></button>
                        </form>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php layout_fin();
