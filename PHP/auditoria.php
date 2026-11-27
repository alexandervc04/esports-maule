<?php
/**
 * Monitoreo: registros generados por los triggers (AUDITORIA_MARCADOR, AUDITORIA_GENERAL)
 * y por SP_LOGIN (LOG_ACCESO).
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN']);

$auditoria = leer('sp_auditoria_listar');
$accesos = leer('sp_log_acceso_listar');

layout_inicio('Auditoría y accesos', 'auditoria', 'Monitoreo generado por triggers (TRG_AUDITORIA_*, TRG_TORNEO_ESTADO, TRG_SANCION_SUSPENDER) y SP_LOGIN');
?>
<ul class="nav nav-tabs mb-3">
    <li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tAud" type="button">Auditoría de cambios (<?= count($auditoria) ?>)</button></li>
    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tLog" type="button">Registro de accesos (<?= count($accesos) ?>)</button></li>
</ul>
<div class="tab-content">
    <div class="tab-pane fade show active" id="tAud">
        <div class="card shadow-sm">
            <div class="card-header"><input type="search" class="form-control form-control-sm" style="max-width:300px" placeholder="Filtrar..." data-filtro="#tablaAud"></div>
            <div class="table-responsive">
                <table class="table table-sm align-middle mb-0" id="tablaAud">
                    <thead><tr><th>Fecha</th><th>Tabla</th><th>Operación</th><th>Registro</th><th>Detalle</th><th>Usuario</th></tr></thead>
                    <tbody>
                    <?php foreach ($auditoria as $a): ?>
                        <tr><td class="small text-nowrap"><?= e($a['fecha']) ?></td><td><span class="badge text-bg-light"><?= e($a['tabla']) ?></span></td>
                            <td class="small"><?= e($a['operacion']) ?></td><td class="small"><?= e($a['id_registro']) ?></td>
                            <td class="small"><?= e($a['detalle']) ?></td><td class="small"><?= e($a['usuario_app']) ?></td></tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="tab-pane fade" id="tLog">
        <div class="card shadow-sm">
            <div class="table-responsive">
                <table class="table table-sm align-middle mb-0">
                    <thead><tr><th>Fecha</th><th>Usuario</th><th>Resultado</th><th>IP</th></tr></thead>
                    <tbody>
                    <?php foreach ($accesos as $l): ?>
                        <tr><td class="small"><?= e($l['fecha']) ?></td><td><?= e($l['username']) ?></td><td><?= badge_estado($l['resultado']) ?></td><td class="small"><?= e($l['ip']) ?></td></tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<?php layout_fin();
