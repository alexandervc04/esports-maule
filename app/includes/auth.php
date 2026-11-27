<?php
if (session_status() !== PHP_SESSION_ACTIVE) session_start();

function is_logged_in(): bool { return !empty($_SESSION['usuario']); }
function current_user(): array { return $_SESSION['usuario'] ?? []; }
function current_role(): string { return $_SESSION['usuario']['PERFIL'] ?? ''; }
function require_login(): void {
    if (!is_logged_in()) { header('Location: login.php'); exit; }
}
function require_roles(array $roles): void {
    require_login();
    if (!in_array(current_role(), $roles, true)) {
        http_response_code(403);
        include __DIR__ . '/header.php';
        echo '<main class="content"><div class="panel"><h1>Acceso restringido</h1><p>Tu perfil no tiene permiso para ejecutar esta operación.</p><a class="btn" href="dashboard.php">Volver</a></div></main>';
        include __DIR__ . '/footer.php';
        exit;
    }
}
function flash(string $type, string $message): void { $_SESSION['flash']=['type'=>$type,'message'=>$message]; }
function pull_flash(): ?array { $f=$_SESSION['flash']??null; unset($_SESSION['flash']); return $f; }
