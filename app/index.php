<?php
session_start();
header('Location: ' . (!empty($_SESSION['usuario']) ? 'dashboard.php' : 'login.php'));
exit;
