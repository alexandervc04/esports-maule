<?php
require_once __DIR__ . '/db.php';

function h($v): string { return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8'); }
function money($v): string { return '$' . number_format((float)$v, 0, ',', '.'); }
function date_for_input($v): string {
    if (!$v) return '';
    foreach (['d-M-y','d-M-Y','Y-m-d','d/m/Y','Y-m-d H:i:s'] as $fmt) {
        $d = DateTime::createFromFormat($fmt, $v);
        if ($d) return $d->format('Y-m-d');
    }
    try { return (new DateTime($v))->format('Y-m-d'); } catch(Throwable $e) { return ''; }
}
function datetime_for_input($v): string {
    if (!$v) return '';
    try { return (new DateTime($v))->format('Y-m-d\TH:i'); } catch(Throwable $e) { return ''; }
}
function module_url(string $m): string { return 'crud.php?mod=' . urlencode($m); }
function lookup_rows(string $type): array {
    switch ($type) {
        case 'usuarios': return oracle_cursor('AV_JP_RM_BE_SP_USUARIO_LISTAR');
        case 'videojuegos': return oracle_cursor('AV_JP_RM_BE_SP_VIDEOJUEGO_LISTAR');
        case 'plataformas': return oracle_cursor('AV_JP_RM_BE_SP_PLATAFORMA_LISTAR');
        case 'sedes': return oracle_cursor('AV_JP_RM_BE_SP_SEDE_LISTAR');
        case 'patrocinadores': return oracle_cursor('AV_JP_RM_BE_SP_PATROCINADOR_LISTAR');
        case 'categorias': return oracle_cursor('AV_JP_RM_BE_SP_CATEGORIA_LISTAR');
        case 'formatos': return oracle_cursor('AV_JP_RM_BE_SP_FORMATO_TORNEO_LISTAR');
        case 'equipos': return oracle_cursor('AV_JP_RM_BE_SP_EQUIPO_LISTAR');
        case 'jugadores': return oracle_cursor('AV_JP_RM_BE_SP_JUGADOR_LISTAR');
        case 'arbitros': return oracle_cursor('AV_JP_RM_BE_SP_ARBITRO_LISTAR');
        case 'torneos': return oracle_cursor('AV_JP_RM_BE_SP_TORNEO_LISTAR');
    }
    return [];
}
function option_map(string $type, ?callable $filter=null): array {
    $defs = [
      'usuarios'=>['ID_USUARIO','NOMBRE'], 'videojuegos'=>['ID_VIDEOJUEGO','NOMBRE'],
      'plataformas'=>['ID_PLATAFORMA','NOMBRE'], 'sedes'=>['ID_SEDE','NOMBRE'],
      'patrocinadores'=>['ID_PATROCINADOR','RAZON_SOCIAL'], 'categorias'=>['ID_CATEGORIA','NOMBRE'],
      'formatos'=>['ID_FORMATO','NOMBRE'], 'equipos'=>['ID_EQUIPO','NOMBRE'],
      'jugadores'=>['ID_JUGADOR','NICKNAME'], 'arbitros'=>['ID_ARBITRO','NOMBRES'],
      'torneos'=>['ID_TORNEO','NOMBRE']
    ];
    [$id,$label] = $defs[$type];
    $out=[];
    foreach (lookup_rows($type) as $r) {
        if ($filter && !$filter($r)) continue;
        $out[(string)$r[$id]] = (string)$r[$label];
    }
    return $out;
}
