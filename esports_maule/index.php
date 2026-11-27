<?php
session_start();
if (isset($_SESSION['id_usuario'])) {
    header("Location: dashboard.php");
    exit();
}

$mensaje_error = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    require_once 'config/conexion.php';

    $email = trim($_POST['email']);
    $password = trim($_POST['contrasena']);

    $sql = "BEGIN SP_AV_JP_RM_BE_LOGIN(:p_email, :p_contrasena, :p_cursor); END;";
    $stmt = oci_parse($conn, $sql);
    $cursor = oci_new_cursor($conn);

    oci_bind_by_name($stmt, ":p_email", $email);
    oci_bind_by_name($stmt, ":p_contrasena", $password);
    oci_bind_by_name($stmt, ":p_cursor", $cursor, -1, OCI_B_CURSOR);

    if (@oci_execute($stmt) && @oci_execute($cursor)) {
        $fila = oci_fetch_assoc($cursor);
        if ($fila) {
            $_SESSION['id_usuario'] = $fila['ID_USUARIO'];
            $_SESSION['nombre']     = $fila['NOMBRE'];
            $_SESSION['email']      = $fila['EMAIL'];
            $_SESSION['perfil']     = $fila['PERFIL'];

            oci_free_statement($cursor);
            oci_free_statement($stmt);
            oci_close($conn);

            header("Location: dashboard.php");
            exit();
        } else {
            $mensaje_error = "Correo o contraseña incorrectos.";
        }
    } else {
        $e = oci_error($stmt);
        $mensaje_error = "Error al iniciar sesión: " . $e['message'];
    }

    oci_free_statement($cursor);
    oci_free_statement($stmt);
    oci_close($conn);
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Esports Maule | Acceso al Sistema</title>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,700&display=fallback">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
</head>
<body class="hold-transition login-page dark-mode">
<div class="login-box">
  <div class="card card-outline card-primary">
    <div class="card-header text-center">
      <a href="#" class="h1"><b>Esports</b>Maule</a>
    </div>
    <div class="card-body">
      <p class="login-box-msg">Inicia sesión para gestionar torneos</p>

      <?php if ($mensaje_error != ""): ?>
        <div class="alert alert-danger text-sm">
          <i class="fas fa-exclamation-triangle mr-1"></i> <?= htmlspecialchars($mensaje_error) ?>
        </div>
      <?php endif; ?>

      <form action="index.php" method="post">
        <div class="input-group mb-3">
          <input type="email" name="email" class="form-control" placeholder="Correo electrónico" required>
          <div class="input-group-append">
            <div class="input-group-text"><span class="fas fa-envelope"></span></div>
          </div>
        </div>
        <div class="input-group mb-3">
          <input type="password" name="contrasena" class="form-control" placeholder="Contraseña" required>
          <div class="input-group-append">
            <div class="input-group-text"><span class="fas fa-lock"></span></div>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <button type="submit" class="btn btn-primary btn-block">Ingresar</button>
          </div>
        </div>
      </form>
      <hr>
      <small class="text-muted">Demo Admin: <b>admin@esportsmaule.cl</b> / <b>admin123</b></small>
    </div>
  </div>
</div>
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
</body>
</html>