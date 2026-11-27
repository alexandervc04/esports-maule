<?php
/**
 * REPORTE 3 · Ocupación de sedes y balance (SP_REPORTE_OCUPACION_SEDES, dos cursores de salida)
 * Pregunta de negocio: ¿qué porcentaje de los cupos se cubre en cada torneo y sede, y cuáles
 * torneos son rentables (inscripciones + patrocinio - premios)?
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';
requiere_perfil(['ADMIN', 'ORGANIZADOR']);

try {
    [$detalle, $resumen] = Database::cursores('sp_reporte_ocupacion_sedes', [], 2);
} catch (Throwable $ex) {
    $GLOBALS['error_bd'] = $ex->getMessage();
    $detalle = $resumen = [];
}
$cupos = array_sum(array_column($detalle, 'cupo_maximo'));
$inscritos = array_sum(array_column($detalle, 'inscritos'));
$balance = array_sum(array_column($detalle, 'balance'));

layout_inicio('Ocupación de sedes y balance', 'r_ocupacion', 'Reporte 3 · SP_REPORTE_OCUPACION_SEDES · cupos cubiertos vs. capacidad y resultado económico');
?>
<div class="row g-3 mb-3">
    <div class="col-md-4"><div class="kpi kpi-wide"><div class="kpi-texto">Ocupación global de cupos</div>
        <div class="kpi-valor"><?= $cupos ? numero(100 * $inscritos / $cupos, 1) : 0 ?>%</div><div class="small text-secondary"><?= e($inscritos) ?> de <?= e($cupos) ?> cupos</div></div></div>
    <div class="col-md-4"><div class="kpi kpi-wide"><div class="kpi-texto">Balance acumulado</div>
        <div class="kpi-valor <?= $balance < 0 ? 'text-danger' : '' ?>"><?= monto($balance) ?></div><div class="small text-secondary">Inscripciones + patrocinio − premios</div></div></div>
    <div class="col-md-4"><div class="kpi kpi-wide"><div class="kpi-texto">Torneos analizados</div>
        <div class="kpi-valor"><?= count($detalle) ?></div><div class="small text-secondary">Excluye cancelados</div></div></div>
</div>
<div class="row g-3 mb-3">
    <div class="col-lg-6"><div class="card shadow-sm h-100"><div class="card-header">% de cupos cubiertos por torneo</div>
        <div class="card-body"><div class="chart-box"><canvas id="gOcupacion"></canvas></div></div></div></div>
    <div class="col-lg-6"><div class="card shadow-sm h-100"><div class="card-header">Balance por torneo <small class="text-secondary">(azul = superávit · rojo = déficit)</small></div>
        <div class="card-body"><div class="chart-box"><canvas id="gBalance"></canvas></div></div></div></div>
</div>
<div class="card shadow-sm mb-3">
    <div class="card-header">Detalle por torneo</div>
    <div class="table-responsive">
        <table class="table table-sm align-middle mb-0">
            <thead><tr><th>Torneo</th><th>Sede</th><th>Estado</th><th class="text-end">Cupos</th><th class="text-end">Inscritos</th><th style="min-width:140px">Ocupación</th>
                <th class="text-end">Inscripciones</th><th class="text-end">Patrocinio</th><th class="text-end">Premios</th><th class="text-end">Balance</th></tr></thead>
            <tbody>
            <?php foreach ($detalle as $d): ?>
                <tr><td class="fw-semibold"><?= e($d['torneo']) ?><div class="small text-secondary"><?= fecha($d['fecha_inicio']) ?></div></td>
                    <td class="small"><?= e($d['sede']) ?></td><td><?= badge_estado($d['estado']) ?></td>
                    <td class="text-end"><?= e($d['cupo_maximo']) ?></td><td class="text-end"><?= e($d['inscritos']) ?></td>
                    <td><div class="progress" role="progressbar" style="height:8px"><div class="progress-bar" style="width:<?= (float)$d['pct_ocupacion'] ?>%"></div></div>
                        <small><?= numero($d['pct_ocupacion'], 1) ?>%</small></td>
                    <td class="text-end"><?= monto($d['recaudacion']) ?></td><td class="text-end"><?= monto($d['patrocinio']) ?></td>
                    <td class="text-end"><?= monto($d['premio_total']) ?></td>
                    <td class="text-end fw-semibold <?= $d['balance'] < 0 ? 'text-danger' : '' ?>"><?= monto($d['balance']) ?></td></tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<div class="card shadow-sm">
    <div class="card-header">Resumen por sede</div>
    <div class="table-responsive">
        <table class="table table-sm align-middle mb-0">
            <thead><tr><th>Sede</th><th>Comuna</th><th>Modalidad</th><th class="text-end">Aforo</th><th class="text-end">Torneos</th><th class="text-end">Cupos ofrecidos</th><th class="text-end">Cubiertos</th><th class="text-end">% ocupación</th><th class="text-end">Balance</th></tr></thead>
            <tbody>
            <?php foreach ($resumen as $s): ?>
                <tr><td class="fw-semibold"><?= e($s['sede']) ?></td><td><?= e($s['comuna']) ?></td><td><?= e(ucfirst(strtolower($s['modalidad']))) ?></td>
                    <td class="text-end"><?= numero($s['capacidad']) ?></td><td class="text-end"><?= e($s['torneos']) ?></td>
                    <td class="text-end"><?= e($s['cupos_ofrecidos']) ?></td><td class="text-end"><?= e($s['cupos_cubiertos']) ?></td>
                    <td class="text-end"><?= $s['pct_ocupacion'] !== null ? numero($s['pct_ocupacion'], 1) . '%' : '—' ?></td>
                    <td class="text-end <?= $s['balance'] < 0 ? 'text-danger' : '' ?>"><?= monto($s['balance']) ?></td></tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php
$labels = json_encode(array_column($detalle, 'torneo'), JSON_UNESCAPED_UNICODE);
$pct = json_encode(array_map('floatval', array_column($detalle, 'pct_ocupacion')));
$bal = array_map('intval', array_column($detalle, 'balance'));
$colores = json_encode(array_map(function ($b) { return $b < 0 ? '#ec4647' : '#257de0'; }, $bal));
$bal = json_encode($bal);
layout_fin("
grafico('gOcupacion', 'bar', $labels, [{ label: '% ocupación', data: $pct, backgroundColor: COLOR.s1 }],
        { horizontal: true, max: 100, formato: function (v) { return v.toLocaleString('es-CL') + '%'; } });
grafico('gBalance', 'bar', $labels, [{ label: 'Balance', data: $bal, backgroundColor: $colores }],
        { horizontal: true, formato: formatoCLP });
");
