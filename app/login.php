<?php
/**
 * Control de acceso: la validación de credenciales, el hash, el bloqueo por intentos
 * y el registro en LOG_ACCESO los realiza SP_LOGIN en la base de datos.
 */
require_once __DIR__ . '/lib/bootstrap.php';

if (usuario()) {
    redirigir('index.php');
}
$error = null;
$usuarioIngresado = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $usuarioIngresado = trim($_POST['username'] ?? '');
    try {
        $r = Database::llamar('sp_login',
            [$usuarioIngresado, $_POST['password'] ?? '', $_SERVER['REMOTE_ADDR'] ?? ''],
            ['id_usuario' => 20, 'nombre' => 200, 'perfil' => 30, 'id_equipo' => 20, 'resultado' => 10, 'mensaje' => 4000]);
        if ((int)$r['resultado'] === 1) {
            session_regenerate_id(true);
            $_SESSION['usuario'] = [
                'id'        => (int)$r['id_usuario'],
                'username'  => strtolower($usuarioIngresado),
                'nombre'    => $r['nombre'],
                'perfil'    => $r['perfil'],
                'id_equipo' => $r['id_equipo'] !== null ? (int)$r['id_equipo'] : null,
            ];
            flash('success', $r['mensaje']);
            redirigir('index.php');
        }
        $error = $r['mensaje'];
    } catch (Throwable $ex) {
        $error = $ex->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Ingreso · <?= e(APP_SIGLA) ?></title>
    <link rel="stylesheet" href="assets/vendor/bootstrap.min.css">
    <link rel="stylesheet" href="assets/vendor/bootstrap-icons.min.css">
    <link rel="stylesheet" href="assets/css/app.css">
</head>
<body class="login-page">
<div class="login-card">
    <div class="text-center mb-4">
        <span class="brand-icon big"><i class="bi bi-controller"></i></span>
        <h1 class="h4 mt-3 mb-1"><?= e(APP_NOMBRE) ?></h1>
        <p class="text-secondary small mb-0">Ligas y torneos de deportes electrónicos · Región del Maule</p>
    </div>
    <?php if ($error): ?>
        <div class="alert alert-danger py-2"><i class="bi bi-exclamation-triangle me-1"></i><?= e($error) ?></div>
    <?php endif; ?>
    <form method="post" autocomplete="off">
        <div class="mb-3">
            <label class="form-label" for="username">Usuario</label>
            <div class="input-group">
                <span class="input-group-text"><i class="bi bi-person"></i></span>
                <input class="form-control" id="username" name="username" required autofocus value="<?= e($usuarioIngresado) ?>">
            </div>
        </div>
        <div class="mb-4">
            <label class="form-label" for="password">Contraseña</label>
            <div class="input-group">
                <span class="input-group-text"><i class="bi bi-lock"></i></span>
                <input class="form-control" id="password" name="password" type="password" required>
            </div>
        </div>
        <button class="btn btn-primary w-100"><i class="bi bi-box-arrow-in-right me-1"></i>Ingresar</button>
    </form>
    <p class="text-center text-secondary small mt-4 mb-0">Perfiles: Administrador · Organizador / Árbitro · Capitán de equipo</p>
</div>
</body>
</html>
