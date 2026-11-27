<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/db.php';
if (is_logged_in()) { header('Location: dashboard.php'); exit; }
$error='';
if ($_SERVER['REQUEST_METHOD']==='POST') {
    $u=trim($_POST['username']??''); $p=$_POST['password']??'';
    try {
        $conn=db_connect();
        $stid=oci_parse($conn,'BEGIN AV_JP_RM_BE_SP_LOGIN(:U,:P,:IDU,:NOMBRE,:PERFIL,:RES); END;');
        $id=null; $nombre=''; $perfil=''; $res=0;
        oci_bind_by_name($stid,':U',$u,100); oci_bind_by_name($stid,':P',$p,200);
        oci_bind_by_name($stid,':IDU',$id,50); oci_bind_by_name($stid,':NOMBRE',$nombre,200);
        oci_bind_by_name($stid,':PERFIL',$perfil,50); oci_bind_by_name($stid,':RES',$res,50);
        if(!oci_execute($stid)) throw new RuntimeException(oracle_error_message($stid));
        if((int)$res===1){ $_SESSION['usuario']=['ID_USUARIO'=>$id,'NOMBRE'=>$nombre,'PERFIL'=>$perfil,'USERNAME'=>strtoupper($u)]; header('Location: dashboard.php'); exit; }
        $error='Usuario o contraseña incorrectos.';
    } catch(Throwable $e) { $error=$e->getMessage(); }
}
?><!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ingresar · ArenaControl</title><link rel="stylesheet" href="assets/css/style.css"></head><body class="login-page">
<div class="login-card"><div class="brand"><span class="brand-mark">A</span><span>ArenaControl<small>GESTIÓN DE TORNEOS ESPORTS</small></span></div><h1>Iniciar sesión</h1><p>Acceso a la plataforma de administración de torneos.</p>
<?php if($error):?><div class="callout" style="border-color:#ff667d;color:#ffc1ca"><?=htmlspecialchars($error)?></div><?php endif;?>
<form method="post"><div class="field"><label>Usuario</label><input name="username" required autocomplete="username"></div><div class="field"><label>Contraseña</label><input type="password" name="password" required autocomplete="current-password"></div><button class="btn" style="width:100%;justify-content:center">Ingresar</button></form>
<div class="login-help"><strong>Datos demo del SQL:</strong><br>ADMIN / ADMIN123<br>ORGANIZADOR / ORGANIZADOR123<br>CAPITAN1 / CAPITAN123</div></div></body></html>
