<?php
$usuario    = 'ESPORTS_DB';
$contrasena = 'esports2026';
$cadena_bd  = 'localhost:1521/XEPDB1';

$conn = @oci_connect($usuario, $contrasena, $cadena_bd, 'AL32UTF8');

if (!$conn) {
    $error = oci_error();
    die("Error de conexión a Oracle: " . htmlentities($error['message'], ENT_QUOTES));
}
?>