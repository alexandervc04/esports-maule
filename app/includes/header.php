<?php
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/helpers.php';
$flash = pull_flash();
$me = current_user();
?><!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title><?= isset($pageTitle)?h($pageTitle).' · ':'' ?>ArenaControl</title>
<link rel="stylesheet" href="assets/css/style.css"></head><body>
<?php if (is_logged_in()): ?>
<header class="topbar"><a href="dashboard.php" class="brand"><span class="brand-mark">A</span><span>ArenaControl<small>GESTIÓN DE TORNEOS ESPORTS</small></span></a>
<nav class="top-actions"><span class="user-pill"><?=h($me['NOMBRE']??'')?> · <?=h($me['PERFIL']??'')?></span><a class="btn btn-ghost" href="logout.php">Salir</a></nav></header>
<div class="app-shell"><aside class="sidebar">
<a href="dashboard.php">▦ Dashboard</a>
<div class="side-title">Mantenedores</div>
<?php if (current_role()==='ADMIN'): ?><a href="crud.php?mod=usuarios">👤 Usuarios</a><?php endif; ?>
<?php if (in_array(current_role(),['ADMIN','ORGANIZADOR'],true)): ?>
<a href="crud.php?mod=videojuegos">🎮 Videojuegos</a><a href="crud.php?mod=plataformas">🖥 Plataformas</a><a href="crud.php?mod=sedes">📍 Sedes</a><a href="crud.php?mod=patrocinadores">🤝 Patrocinadores</a><a href="crud.php?mod=categorias">🏷 Categorías</a><a href="crud.php?mod=formatos">🧩 Formatos</a><a href="crud.php?mod=equipos">🛡 Equipos</a><a href="crud.php?mod=jugadores">⚔ Jugadores</a><a href="crud.php?mod=arbitros">⚖ Árbitros</a>
<?php endif; ?>
<div class="side-title">Gestores</div>
<?php if (in_array(current_role(),['ADMIN','ORGANIZADOR'],true)): ?><a href="gestor_torneos.php">🏆 Apertura de torneo</a><?php endif; ?>
<a href="gestor_inscripciones.php">📝 Inscripción y roster</a>
<?php if (in_array(current_role(),['ADMIN','ORGANIZADOR'],true)): ?><a href="gestor_fixture.php">🗓 Generar fixture</a><a href="gestor_resultados.php">🎯 Resultados y KDA</a><a href="gestor_sanciones.php">🚨 Sanciones y premiación</a><?php endif; ?>
<div class="side-title">Información</div><a href="reportes.php">📊 Reportes estratégicos</a>
</aside>
<?php endif; ?>
<?php if ($flash): ?><div class="toast <?=h($flash['type'])?>" id="toast"><?=h($flash['message'])?></div><?php endif; ?>
