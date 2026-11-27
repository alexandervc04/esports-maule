<?php
/**
 * Mantenedor genérico: resuelve los 10 CRUD a partir de lib/entidades.php.
 * Crear / Leer / Actualizar / Eliminar se ejecutan exclusivamente con procedimientos almacenados.
 */
require_once __DIR__ . '/lib/bootstrap.php';
require_once __DIR__ . '/lib/layout.php';

$entidades = require __DIR__ . '/lib/entidades.php';
$clave = $_GET['e'] ?? '';
if (!isset($entidades[$clave])) {
    redirigir('index.php');
}
$cfg = $entidades[$clave];
requiere_perfil($cfg['ver']);
$puedeEscribir = es($cfg['escribir']);
$equipoCapitan = es('CAPITAN') ? ($_SESSION['usuario']['id_equipo'] ?? -1) : null;
$url = 'mantenedor.php?e=' . urlencode($clave);

// ------------------------------- Escritura -------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verificar_csrf();
    if (!$puedeEscribir) {
        flash('danger', 'Su perfil no puede modificar este mantenedor.');
        redirigir($url);
    }
    $accion = $_POST['accion'] ?? '';
    if ($accion === 'eliminar') {
        $r = ejecutar($cfg['eliminar'], [id_sesion(), $_POST['id'] ?? null]);
    } else {
        $params = [id_sesion()];
        if ($accion === 'actualizar') {
            $params[] = $_POST['id'] ?? null;
        }
        foreach ($cfg['campos'] as [$nombre, , , $op]) {
            if ($accion === 'actualizar' && !empty($op['solo_insert'])) {
                continue;
            }
            $valor = $_POST[$nombre] ?? null;
            // El capitán solo puede asignar jugadores a su propio equipo (la BD también lo valida)
            if ($equipoCapitan !== null && $nombre === 'id_equipo') {
                $valor = $equipoCapitan;
            }
            $params[] = is_string($valor) ? trim($valor) : $valor;
        }
        $proc = $accion === 'actualizar' ? $cfg['actualizar'] : $cfg['insertar'];
        $r = ejecutar($proc, $params, $accion !== 'actualizar');
    }
    flash_resultado($r);
    redirigir($url);
}

// ------------------------------- Lectura -------------------------------
$filas = !empty($cfg['listar_por_equipo']) ? leer($cfg['listar'], [$equipoCapitan]) : leer($cfg['listar']);

// Opciones de los campos select que provienen de otros procedimientos
$opciones = [];
foreach ($cfg['campos'] as [$nombre, , $tipo, $op]) {
    if ($tipo !== 'select') {
        continue;
    }
    $o = $op['opciones'];
    if (isset($o['proc'])) {
        $datos = leer($o['proc']);
        if (!empty($o['filtro'])) {
            $datos = array_filter($datos, function ($f) use ($o) {
                foreach ($o['filtro'] as $k => $v) {
                    if (($f[$k] ?? null) !== $v) return false;
                }
                return true;
            });
        }
        if ($nombre === 'id_equipo' && $equipoCapitan !== null) {
            $datos = array_filter($datos, function ($f) use ($equipoCapitan) {
                return (string)$f['id_equipo'] === (string)$equipoCapitan;
            });
        }
        $lista = [];
        foreach ($datos as $f) {
            $lista[$f[$o['valor']]] = $f[$o['etiqueta']];
        }
        $opciones[$nombre] = $lista;
    } else {
        $opciones[$nombre] = $o;
    }
}

$columnasEstado = ['estado', 'estado_disciplinario'];
$montos = $cfg['montos'] ?? [];

layout_inicio($cfg['titulo'], 'm_' . $clave, 'Mantenedor · ' . $cfg['listar'] . ' / ' . $cfg['insertar'] . ' / ' . $cfg['actualizar'] . ' / ' . $cfg['eliminar']);
?>
<div class="card shadow-sm">
    <div class="card-header d-flex flex-wrap gap-2 align-items-center">
        <div class="input-group input-group-sm" style="max-width: 320px">
            <span class="input-group-text"><i class="bi bi-search"></i></span>
            <input type="search" class="form-control" placeholder="Buscar..." data-filtro="#tabla">
        </div>
        <span class="text-secondary small"><?= count($filas) ?> registro(s)</span>
        <?php if ($puedeEscribir): ?>
            <button class="btn btn-primary btn-sm ms-auto" data-bs-toggle="modal" data-bs-target="#modalForm" data-accion="insertar">
                <i class="bi bi-plus-lg"></i> Nuevo <?= e($cfg['singular']) ?>
            </button>
        <?php endif; ?>
    </div>
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" id="tabla">
            <thead>
            <tr>
                <th>#</th>
                <?php foreach ($cfg['columnas'] as $titulo): ?><th><?= e($titulo) ?></th><?php endforeach; ?>
                <?php if ($puedeEscribir): ?><th class="text-end">Acciones</th><?php endif; ?>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($filas as $f): ?>
                <tr>
                    <td class="text-secondary"><?= e($f[$cfg['pk']]) ?></td>
                    <?php foreach ($cfg['columnas'] as $col => $titulo): ?>
                        <td>
                            <?php if (in_array($col, $columnasEstado, true)): ?>
                                <?= badge_estado($f[$col]) ?>
                            <?php elseif (in_array($col, $montos, true)): ?>
                                <?= monto($f[$col]) ?>
                            <?php elseif ($col === 'kda'): ?>
                                <?= numero($f[$col], 2) ?>
                            <?php elseif (strpos($col, 'fecha') === 0): ?>
                                <?= e(fecha($f[$col])) ?>
                            <?php else: ?>
                                <?= e($f[$col] ?? '—') ?>
                            <?php endif; ?>
                        </td>
                    <?php endforeach; ?>
                    <?php if ($puedeEscribir): ?>
                        <td class="text-end text-nowrap">
                            <button class="btn btn-outline-primary btn-sm" data-bs-toggle="modal" data-bs-target="#modalForm"
                                    data-accion="actualizar" data-id="<?= e($f[$cfg['pk']]) ?>"
                                    data-fila="<?= e(json_encode($f, JSON_UNESCAPED_UNICODE)) ?>" title="Editar">
                                <i class="bi bi-pencil"></i>
                            </button>
                            <form method="post" class="d-inline" onsubmit="return confirm('¿Eliminar este registro?');">
                                <?= csrf_campo() ?>
                                <input type="hidden" name="accion" value="eliminar">
                                <input type="hidden" name="id" value="<?= e($f[$cfg['pk']]) ?>">
                                <button class="btn btn-outline-danger btn-sm" title="Eliminar"><i class="bi bi-trash"></i></button>
                            </form>
                        </td>
                    <?php endif; ?>
                </tr>
            <?php endforeach; ?>
            <?php if (!$filas): ?>
                <tr><td colspan="<?= count($cfg['columnas']) + 2 ?>" class="text-center text-secondary py-4">Sin registros.</td></tr>
            <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php if ($puedeEscribir): ?>
<div class="modal fade" id="modalForm" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <form class="modal-content" method="post" id="formEntidad">
            <?= csrf_campo() ?>
            <input type="hidden" name="accion" value="insertar">
            <input type="hidden" name="id" value="">
            <div class="modal-header">
                <h5 class="modal-title"><span data-titulo-insertar>Nuevo</span><span data-titulo-actualizar class="d-none">Editar</span> <?= e($cfg['singular']) ?></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                <?php foreach ($cfg['campos'] as [$nombre, $etiqueta, $tipo, $op]):
                    $req = !empty($op['required']) ? ' required' : '';
                    $attrs = '';
                    foreach (['min', 'max', 'maxlength', 'pattern', 'placeholder'] as $a) {
                        if (isset($op[$a])) $attrs .= ' ' . $a . '="' . e($op[$a]) . '"';
                    }
                    $extra = (!empty($op['solo_insert']) ? ' data-solo-insert' : '') . (!empty($op['required_insert']) ? ' data-required-insert' : '');
                    $ancho = $tipo === 'textarea' ? 'col-12' : 'col-md-6'; ?>
                    <div class="<?= $ancho ?>">
                        <label class="form-label" for="f_<?= e($nombre) ?>"><?= e($etiqueta) ?><?= $req ? ' <span class="text-danger">*</span>' : '' ?></label>
                        <?php if ($tipo === 'select'): ?>
                            <select class="form-select" name="<?= e($nombre) ?>" id="f_<?= e($nombre) ?>"<?= $req . $extra ?>>
                                <?php if (isset($op['vacio'])): ?><option value=""><?= e($op['vacio']) ?></option><?php endif; ?>
                                <?php foreach ($opciones[$nombre] as $v => $t): ?>
                                    <option value="<?= e($v) ?>"><?= e($t) ?></option>
                                <?php endforeach; ?>
                            </select>
                        <?php elseif ($tipo === 'textarea'): ?>
                            <textarea class="form-control" rows="2" name="<?= e($nombre) ?>" id="f_<?= e($nombre) ?>"<?= $req . $attrs . $extra ?>></textarea>
                        <?php else: ?>
                            <input class="form-control" type="<?= e($tipo) ?>" name="<?= e($nombre) ?>" id="f_<?= e($nombre) ?>"<?= $req . $attrs . $extra ?>>
                        <?php endif; ?>
                        <?php if (!empty($op['ayuda'])): ?><div class="form-text"><?= e($op['ayuda']) ?></div><?php endif; ?>
                    </div>
                <?php endforeach; ?>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancelar</button>
                <button class="btn btn-primary"><i class="bi bi-save"></i> Guardar</button>
            </div>
        </form>
    </div>
</div>
<?php endif; ?>
<?php layout_fin();
