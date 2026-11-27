<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
if (!isset($_SESSION['id_usuario'])) {
    header("Location: /esports_maule/index.php");
    exit();
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Esports Maule | Gestión de Torneos</title>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,700&display=fallback">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
</head>
<body class="hold-transition sidebar-mini layout-fixed">
<div class="wrapper">

  <!-- Barra superior -->
  <nav class="main-header navbar navbar-expand navbar-white navbar-light">
    <ul class="navbar-nav">
      <li class="nav-item">
        <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
      </li>
      <li class="nav-item d-none d-sm-inline-block">
        <a href="/esports_maule/dashboard.php" class="nav-link">Inicio</a>
      </li>
    </ul>

    <ul class="navbar-nav ml-auto">
      <li class="nav-item">
        <span class="nav-link text-muted">
          <i class="fas fa-user-shield mr-1"></i>
          <?= htmlspecialchars($_SESSION['nombre']) ?> (<b><?= htmlspecialchars($_SESSION['perfil']) ?></b>)
        </span>
      </li>
      <li class="nav-item">
        <a href="/esports_maule/logout.php" class="nav-link text-danger">
          <i class="fas fa-sign-out-alt"></i> Salir
        </a>
      </li>
    </ul>
  </nav>

  <!-- Menú Lateral (Sidebar) -->
  <aside class="main-sidebar sidebar-dark-primary elevation-4">
    <a href="/esports_maule/dashboard.php" class="brand-link text-center">
      <span class="brand-text font-weight-bold"><i class="fas fa-gamepad mr-2"></i>ESPORTS MAULE</span>
    </a>

    <div class="sidebar">
      <nav class="mt-2">
        <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu" data-accordion="false">
          <li class="nav-item">
            <a href="/esports_maule/dashboard.php" class="nav-link">
              <i class="nav-icon fas fa-tachometer-alt"></i>
              <p>Dashboard y Auditoría</p>
            </a>
          </li>

          <li class="nav-header">CATÁLOGOS (10 MANTENEDORES)</li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/juegos.php" class="nav-link"><i class="nav-icon fas fa-headset"></i><p>1. Juegos</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/plataformas.php" class="nav-link"><i class="nav-icon fas fa-desktop"></i><p>2. Plataformas</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/sedes.php" class="nav-link"><i class="nav-icon fas fa-map-marker-alt"></i><p>3. Sedes</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/patrocinadores.php" class="nav-link"><i class="nav-icon fas fa-handshake"></i><p>4. Patrocinadores</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/categorias.php" class="nav-link"><i class="nav-icon fas fa-tags"></i><p>5. Categorías</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/arbitros.php" class="nav-link"><i class="nav-icon fas fa-gavel"></i><p>6. Árbitros</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/reglas.php" class="nav-link"><i class="nav-icon fas fa-book"></i><p>7. Reglas de Torneo</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/premios.php" class="nav-link"><i class="nav-icon fas fa-trophy"></i><p>8. Premios</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/equipos.php" class="nav-link"><i class="nav-icon fas fa-users"></i><p>9. Equipos</p></a></li>
          <li class="nav-item"><a href="/esports_maule/mantenedores/jugadores.php" class="nav-link"><i class="nav-icon fas fa-user-ninja"></i><p>10. Jugadores</p></a></li>

          <li class="nav-header">OPERACIÓN (5 GESTORES)</li>
          <li class="nav-item"><a href="/esports_maule/gestores/torneos.php" class="nav-link"><i class="nav-icon fas fa-sitemap"></i><p>Torneos</p></a></li>
          <li class="nav-item"><a href="/esports_maule/gestores/inscripciones.php" class="nav-link"><i class="nav-icon fas fa-clipboard-check"></i><p>1. Inscripciones</p></a></li>
          <li class="nav-item"><a href="/esports_maule/gestores/partidas.php" class="nav-link"><i class="nav-icon fas fa-crosshairs"></i><p>2. Partidas y Resultados</p></a></li>
          <li class="nav-item"><a href="/esports_maule/gestores/kda.php" class="nav-link"><i class="nav-icon fas fa-chart-line"></i><p>3. Estadísticas KDA</p></a></li>
          <li class="nav-item"><a href="/esports_maule/gestores/sanciones.php" class="nav-link"><i class="nav-icon fas fa-ban"></i><p>4. Sanciones</p></a></li>
          <li class="nav-item"><a href="/esports_maule/gestores/asignacion_premios.php" class="nav-link"><i class="nav-icon fas fa-medal"></i><p>5. Asignar Premios</p></a></li>

          <li class="nav-header">ANÁLISIS (3 REPORTES)</li>
          <li class="nav-item"><a href="/esports_maule/reportes/rep_juegos.php" class="nav-link"><i class="nav-icon fas fa-chart-pie"></i><p>1. Rendimiento Juegos</p></a></li>
          <li class="nav-item"><a href="/esports_maule/reportes/rep_mvp.php" class="nav-link"><i class="nav-icon fas fa-star"></i><p>2. Ranking MVP</p></a></li>
          <li class="nav-item"><a href="/esports_maule/reportes/rep_torneos.php" class="nav-link"><i class="nav-icon fas fa-building"></i><p>3. Ocupación Torneos</p></a></li>
        </ul>
      </nav>
    </div>
  </aside>

  <!-- Contenedor principal -->
  <div class="content-wrapper">