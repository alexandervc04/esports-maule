<?php
/**
 * Configuración de conexión a Oracle.
 * Ajustar usuario, contraseña y cadena de conexión según la instalación local.
 * Oracle XE 21c: el servicio de la base conectable por defecto es XEPDB1.
 */
define('DB_USER', getenv('ESPORTS_DB_USER') ?: 'esports');
define('DB_PASS', getenv('ESPORTS_DB_PASS') ?: 'esports2026');
define('DB_DSN',  getenv('ESPORTS_DB_DSN')  ?: 'localhost:1521/XEPDB1');

define('APP_NOMBRE', 'Sistema de Gestión de Torneos de Esports');
define('APP_SIGLA',  'Esports Maule');

date_default_timezone_set('America/Santiago');
