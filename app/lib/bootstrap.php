<?php
/**
 * Inicialización común: sesión, configuración, acceso a datos, autenticación y utilidades.
 */
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/Database.php';

// --------------------------- Sesión y permisos ---------------------------
function usuario()
{
    return $_SESSION['usuario'] ?? null;
}

function perfil()
{
    return $_SESSION['usuario']['perfil'] ?? null;
}

function id_sesion()
{
    return $_SESSION['usuario']['id'] ?? null;
}

function es($perfiles)
{
    return in_array(perfil(), (array)$perfiles, true);
}

function requiere_login()
{
    if (!usuario()) {
        header('Location: login.php');
        exit;
    }
}

function requiere_perfil($perfiles)
{
    requiere_login();
    if (!es($perfiles)) {
        http_response_code(403);
        flash('danger', 'Su perfil no tiene acceso a esa sección.');
        header('Location: index.php');
        exit;
    }
}

// --------------------------- Utilidades ---------------------------
function e($v)
{
    return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8');
}

function flash($tipo, $mensaje)
{
    $_SESSION['flash'][] = [$tipo, $mensaje];
}

function flash_resultado(array $r)
{
    flash($r['ok'] ? 'success' : 'danger', $r['mensaje']);
}

function csrf_token()
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(16));
    }
    return $_SESSION['csrf'];
}

function csrf_campo()
{
    return '<input type="hidden" name="csrf" value="' . csrf_token() . '">';
}

function verificar_csrf()
{
    if (($_POST['csrf'] ?? '') !== csrf_token()) {
        http_response_code(400);
        exit('Solicitud inválida (token CSRF).');
    }
}

function redirigir($url)
{
    header('Location: ' . $url);
    exit;
}

function monto($n)
{
    return '$' . number_format((float)$n, 0, ',', '.');
}

function numero($n, $dec = 0)
{
    return number_format((float)$n, $dec, ',', '.');
}

function fecha($f)
{
    if (!$f) {
        return '—';
    }
    $t = strtotime($f);
    return $t ? date(strlen($f) > 10 ? 'd-m-Y H:i' : 'd-m-Y', $t) : $f;
}

/** Ejecuta una lectura capturando errores de conexión para mostrarlos en pantalla. */
function leer($proc, array $params = [])
{
    try {
        return Database::cursor($proc, $params);
    } catch (Throwable $ex) {
        $GLOBALS['error_bd'] = $ex->getMessage();
        return [];
    }
}

function ejecutar($proc, array $params, $retornaId = false)
{
    try {
        return Database::ejecutar($proc, $params, $retornaId);
    } catch (Throwable $ex) {
        return ['ok' => false, 'mensaje' => $ex->getMessage(), 'id' => null];
    }
}

function badge_estado($estado)
{
    $map = [
        'ACTIVO' => 'success', 'HABILITADO' => 'success', 'CONFIRMADA' => 'success', 'JUGADA' => 'success',
        'ABIERTO' => 'primary', 'PROGRAMADA' => 'primary', 'VIGENTE' => 'warning',
        'EN_CURSO' => 'warning', 'BYE' => 'secondary', 'CUMPLIDA' => 'secondary',
        'FINALIZADO' => 'dark', 'INACTIVO' => 'secondary', 'RETIRADA' => 'secondary',
        'SANCIONADO' => 'danger', 'BLOQUEADO' => 'danger', 'CANCELADO' => 'danger', 'ANULADA' => 'danger',
        'EXITOSO' => 'success', 'FALLIDO' => 'danger',
    ];
    $c = $map[$estado] ?? 'secondary';
    $txt = ucfirst(strtolower(str_replace('_', ' ', (string)$estado)));
    return '<span class="badge text-bg-' . $c . '">' . e($txt) . '</span>';
}

/** Opciones <option> a partir de filas de un cursor. */
function opciones(array $filas, $valor, $etiqueta, $seleccionado = null, $vacio = null)
{
    $h = $vacio !== null ? '<option value="">' . e($vacio) . '</option>' : '';
    foreach ($filas as $f) {
        $v = $f[$valor];
        $sel = ((string)$v === (string)$seleccionado) ? ' selected' : '';
        $h .= '<option value="' . e($v) . '"' . $sel . '>' . e(is_callable($etiqueta) ? $etiqueta($f) : $f[$etiqueta]) . '</option>';
    }
    return $h;
}
