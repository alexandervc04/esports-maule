<?php
/**
 * Plantilla común (capa de presentación): barra lateral según perfil, encabezado y mensajes.
 */
function menu_items()
{
    $todos = ['ADMIN', 'ORGANIZADOR', 'CAPITAN'];
    $staff = ['ADMIN', 'ORGANIZADOR'];
    $ent = require __DIR__ . '/entidades.php';
    $mant = [];
    foreach ($ent as $clave => $cfg) {
        $mant[] = ['mantenedor.php?e=' . $clave, $cfg['icono'], $cfg['titulo'], $cfg['ver'], 'm_' . $clave];
    }
    return [
        ['General', [
            ['index.php', 'speedometer2', 'Panel principal', $todos, 'panel'],
        ]],
        ['Mantenedores', $mant],
        ['Gestores', [
            ['torneos.php', 'trophy', 'Apertura de torneos', $staff, 'g_torneos'],
            ['inscripciones.php', 'person-plus', 'Inscripción y roster', $todos, 'g_inscripciones'],
            ['fixture.php', 'diagram-3', 'Fixture y posiciones', $todos, 'g_fixture'],
            ['resultados.php', 'joystick', 'Resultados y KDA', $staff, 'g_resultados'],
            ['sanciones.php', 'shield-exclamation', 'Sanciones y premiación', $staff, 'g_sanciones'],
        ]],
        ['Reportes', [
            ['rep_demanda.php', 'bar-chart-line', 'Demanda por videojuego', $staff, 'r_demanda'],
            ['rep_ranking.php', 'star', 'Ranking MVP', $todos, 'r_ranking'],
            ['rep_ocupacion.php', 'building', 'Ocupación y balance', $staff, 'r_ocupacion'],
        ]],
        ['Seguridad', [
            ['auditoria.php', 'journal-check', 'Auditoría y accesos', ['ADMIN'], 'auditoria'],
        ]],
    ];
}

function layout_inicio($titulo, $activo = '', $subtitulo = '')
{
    $u = usuario();
    $perfiles = ['ADMIN' => 'Administrador', 'ORGANIZADOR' => 'Organizador / Árbitro', 'CAPITAN' => 'Capitán'];
    ?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($titulo) ?> · <?= e(APP_SIGLA) ?></title>
    <link rel="stylesheet" href="assets/vendor/bootstrap.min.css">
    <link rel="stylesheet" href="assets/vendor/bootstrap-icons.min.css">
    <link rel="stylesheet" href="assets/css/app.css">
</head>
<body>
<div class="app">
    <aside class="sidebar" id="sidebar">
        <a class="brand" href="index.php">
            <span class="brand-icon"><i class="bi bi-controller"></i></span>
            <span><strong><?= e(APP_SIGLA) ?></strong><small>Gestión de torneos</small></span>
        </a>
        <nav>
        <?php foreach (menu_items() as [$grupo, $items]):
            $visibles = array_filter($items, function ($i) { return es($i[3]); });
            if (!$visibles) continue; ?>
            <div class="nav-group"><?= e($grupo) ?></div>
            <?php foreach ($visibles as [$href, $icono, $texto, , $clave]): ?>
                <a class="nav-link<?= $clave === $activo ? ' active' : '' ?>" href="<?= e($href) ?>">
                    <i class="bi bi-<?= e($icono) ?>"></i><span><?= e($texto) ?></span>
                </a>
            <?php endforeach; ?>
        <?php endforeach; ?>
        </nav>
    </aside>
    <div class="main">
        <header class="topbar">
            <button class="btn btn-sm btn-light d-lg-none" onclick="document.getElementById('sidebar').classList.toggle('open')">
                <i class="bi bi-list"></i>
            </button>
            <div>
                <h1><?= e($titulo) ?></h1>
                <?php if ($subtitulo): ?><p class="sub"><?= e($subtitulo) ?></p><?php endif; ?>
            </div>
            <div class="user">
                <div class="text-end">
                    <div class="fw-semibold"><?= e($u['nombre']) ?></div>
                    <small class="text-secondary"><?= e($perfiles[$u['perfil']] ?? $u['perfil']) ?></small>
                </div>
                <a class="btn btn-outline-secondary btn-sm" href="logout.php" title="Cerrar sesión"><i class="bi bi-box-arrow-right"></i></a>
            </div>
        </header>
        <main class="content">
        <?php foreach ($_SESSION['flash'] ?? [] as [$tipo, $msg]): ?>
            <div class="alert alert-<?= e($tipo) ?> alert-dismissible fade show" role="alert">
                <i class="bi bi-<?= $tipo === 'success' ? 'check-circle' : 'exclamation-triangle' ?> me-1"></i><?= e($msg) ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endforeach; unset($_SESSION['flash']); ?>
    <?php
}

function layout_fin($script = '')
{
    if (!empty($GLOBALS['error_bd'])): ?>
        <div class="alert alert-danger mt-3"><i class="bi bi-database-x me-1"></i>
            Error de base de datos: <?= e($GLOBALS['error_bd']) ?></div>
    <?php endif; ?>
        </main>
        <footer class="footer">UCM · ECI224 Base de Datos · <?= e(APP_NOMBRE) ?> · Oracle Database 21c + PHP/OCI8</footer>
    </div>
</div>
<script src="assets/vendor/bootstrap.bundle.min.js"></script>
<?php if ($script): ?><script src="assets/vendor/chart.umd.js"></script><?php endif; ?>
<script src="assets/js/app.js"></script>
<?php if ($script): ?><script><?= $script ?></script><?php endif; ?>
</body>
</html>
    <?php
}
