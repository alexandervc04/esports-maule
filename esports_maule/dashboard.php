<?php
require_once 'includes/header.php';
require_once 'config/conexion.php';

// Consultar Auditoría mediante procedimiento almacenado
$sql_aud = "BEGIN SP_AV_JP_RM_BE_LIST_AUDITORIA(:p_cursor); END;";
$stmt_aud = oci_parse($conn, $sql_aud);
$cursor_aud = oci_new_cursor($conn);
oci_bind_by_name($stmt_aud, ":p_cursor", $cursor_aud, -1, OCI_B_CURSOR);
oci_execute($stmt_aud);
oci_execute($cursor_aud);

$auditorias = [];
while ($row = oci_fetch_assoc($cursor_aud)) {
    $auditorias[] = $row;
}
oci_free_statement($cursor_aud);
oci_free_statement($stmt_aud);
?>

<section class="content-header">
  <div class="container-fluid">
    <h1>Panel Principal — Gestión de Torneos Esports</h1>
  </div>
</section>

<section class="content">
  <div class="container-fluid">
    <!-- Tarjetas de resumen -->
    <div class="row">
      <div class="col-lg-3 col-6">
        <div class="small-box bg-info">
          <div class="inner">
            <h3>10</h3>
            <p>Mantenedores Base</p>
          </div>
          <div class="icon"><i class="fas fa-database"></i></div>
          <a href="mantenedores/juegos.php" class="small-box-footer">Ir a Juegos <i class="fas fa-arrow-circle-right"></i></a>
        </div>
      </div>
      <div class="col-lg-3 col-6">
        <div class="small-box bg-success">
          <div class="inner">
            <h3>5</h3>
            <p>Gestores Operativos</p>
          </div>
          <div class="icon"><i class="fas fa-cogs"></i></div>
          <a href="gestores/torneos.php" class="small-box-footer">Ir a Torneos <i class="fas fa-arrow-circle-right"></i></a>
        </div>
      </div>
      <div class="col-lg-3 col-6">
        <div class="small-box bg-warning">
          <div class="inner">
            <h3>3</h3>
            <p>Reportes de Negocio</p>
          </div>
          <div class="icon"><i class="fas fa-chart-bar"></i></div>
          <a href="reportes/rep_mvp.php" class="small-box-footer">Ver Ranking MVP <i class="fas fa-arrow-circle-right"></i></a>
        </div>
      </div>
      <div class="col-lg-3 col-6">
        <div class="small-box bg-danger">
          <div class="inner">
            <h3><?= count($auditorias) ?></h3>
            <p>Eventos Auditados (Triggers)</p>
          </div>
          <div class="icon"><i class="fas fa-shield-alt"></i></div>
          <a href="#tabla-auditoria" class="small-box-footer">Ver Bitácora <i class="fas fa-arrow-circle-down"></i></a>
        </div>
      </div>
    </div>

    <!-- Tabla de Auditoría generada por Triggers -->
    <div class="card card-dark" id="tabla-auditoria">
      <div class="card-header">
        <h3 class="card-title"><i class="fas fa-history mr-2"></i>Bitácora de Auditoría Automática (AV_JP_RM_BE_AUDITORIA_TORNEOS)</h3>
      </div>
      <div class="card-body table-responsive p-0">
        <table class="table table-hover table-striped">
          <thead>
            <tr>
              <th>ID</th>
              <th>Acción</th>
              <th>Usuario BD</th>
              <th>Fecha y Hora</th>
              <th>Detalle del Evento</th>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($auditorias as $aud): ?>
              <tr>
                <td><?= htmlspecialchars($aud['ID_AUDITORIA']) ?></td>
                <td><span class="badge badge-info"><?= htmlspecialchars($aud['ACCION']) ?></span></td>
                <td><?= htmlspecialchars($aud['USUARIO']) ?></td>
                <td><?= htmlspecialchars($aud['FECHA']) ?></td>
                <td><?= htmlspecialchars($aud['DETALLE']) ?></td>
              </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</section>

<?php
oci_close($conn);
require_once 'includes/footer.php';
?>