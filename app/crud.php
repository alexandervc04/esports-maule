<?php
require_once __DIR__.'/includes/auth.php'; require_login(); require_once __DIR__.'/includes/helpers.php';
$mods=require __DIR__.'/config/modules.php'; $key=$_GET['mod']??''; if(!isset($mods[$key])){http_response_code(404);exit('Módulo no válido');}$m=$mods[$key];
if(($m['admin_only']??false) && current_role()!=='ADMIN') require_roles(['ADMIN']); else require_roles(['ADMIN','ORGANIZADOR']);
$pageTitle=$m['title'];
try { $rows=oracle_cursor($m['list']); } catch(Throwable $e){$rows=[];$error=$e->getMessage();}
$editId=$_GET['edit']??null; $editing=null; if($editId!==null){foreach($rows as $r){if((string)$r[$m['id']]===(string)$editId){$editing=$r;break;}}}
if($_SERVER['REQUEST_METHOD']==='POST'){
 try{
  $action=$_POST['action']??'save';
  if($action==='delete'){
    $id=$_POST['id']??0; oracle_run('BEGIN '.$m['delete'].'(:P_ID); END;',['P_ID'=>$id]); flash('success','Registro eliminado correctamente.');
  } else {
    $params=['P_ID'=>$_POST['id']??0];
    foreach($m['fields'] as $col=>$f){$db=$f['db']??('P_'.$col);$params[$db]=$_POST[$col]??null;}
    oracle_run($m['save'],$params,['P_ID']); flash('success',(!empty($_POST['id'])?'Registro actualizado.':'Registro creado correctamente.'));
  }
  header('Location: '.module_url($key));exit;
 }catch(Throwable $e){$error=$e->getMessage();}
}
function field_options($f){
 if(($f['type']??'')==='select')return $f['options'];
 if(($f['type']??'')==='lookup'){
  if($f['lookup']==='equipos') return option_map('equipos');
  if($f['lookup']==='capitanes') return option_map('usuarios',fn($r)=>$r['PERFIL']==='CAPITAN' && $r['ESTADO']==='ACTIVO');
 }
 return [];
}
include __DIR__.'/includes/header.php';?>
<main class="content"><div class="page-head"><div><h1><?=h($m['icon'].' '.$m['title'])?></h1><p>Mantenedor CRUD conectado a procedimientos almacenados Oracle.</p></div><a class="btn btn-ghost" href="<?=h(module_url($key))?>">+ Nuevo registro</a></div>
<?php if(!empty($error)):?><div class="callout" style="border-color:#ff667d"><?=h($error)?></div><?php endif;?>
<div class="split"><section class="panel"><h2 class="section-title"><?=$editing?'Editar registro':'Nuevo registro'?></h2><form method="post"><input type="hidden" name="action" value="save"><input type="hidden" name="id" value="<?=h($editing[$m['id']]??0)?>"><div class="grid grid-2">
<?php foreach($m['fields'] as $col=>$f): $type=$f['type']??'text';$val=$editing[$col]??'';if($type==='date')$val=date_for_input($val);$opts=field_options($f);?><div class="field"><label><?=h($f['label'])?><?=!empty($f['required'])?' *':''?></label>
<?php if(in_array($type,['select','lookup'],true)):?><select name="<?=h($col)?>" <?=!empty($f['required'])?'required':''?>><option value="">-- Seleccionar --</option><?php foreach($opts as $ov=>$ol):?><option value="<?=h($ov)?>" <?=((string)$val===(string)$ov)?'selected':''?>><?=h($ol)?></option><?php endforeach;?></select>
<?php else:?><input type="<?=h($type)?>" name="<?=h($col)?>" value="<?=h($type==='password'?'':$val)?>" <?=(!empty($f['required']) && !($editing && !empty($f['edit_optional'])))?'required':''?> <?=($type==='number')?'step="any"':''?>><?php if($editing && !empty($f['edit_optional'])):?><span class="mini-note">Déjala vacía para mantener la contraseña actual.</span><?php endif;?><?php endif;?></div><?php endforeach;?></div><div class="form-actions"><button class="btn"><?=$editing?'Guardar cambios':'Crear registro'?></button><?php if($editing):?><a class="btn btn-ghost" href="<?=h(module_url($key))?>">Cancelar</a><?php endif;?></div></form></section>
<section class="panel"><div class="toolbar"><div><h2 class="section-title" style="margin:0">Registros</h2><span class="muted"><?=count($rows)?> encontrados</span></div><input class="search" data-filter="#crud-table" placeholder="Buscar..."></div><div class="table-wrap"><table id="crud-table"><thead><tr><?php if($rows):foreach(array_keys($rows[0]) as $c):?><th><?=h(str_replace('_',' ',$c))?></th><?php endforeach;endif;?><th>Acciones</th></tr></thead><tbody>
<?php foreach($rows as $r):?><tr><?php foreach($r as $c=>$v):?><td><?php if($c==='ESTADO'||$c==='PERFIL'||$c==='TIPO'):?><span class="badge <?=h($v)?>"><?=h($v)?></span><?php else:?><?=h($v)?><?php endif;?></td><?php endforeach;?><td><a class="btn btn-sm btn-ghost" href="<?=h(module_url($key).'&edit='.$r[$m['id']])?>">Editar</a> <form method="post" style="display:inline"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="<?=h($r[$m['id']])?>"><button class="btn btn-sm btn-danger" data-confirm="¿Eliminar este registro? Puede fallar si tiene relaciones asociadas.">Eliminar</button></form></td></tr><?php endforeach;?><?php if(!$rows):?><tr><td colspan="99" class="empty">No hay registros.</td></tr><?php endif;?></tbody></table></div></section></div></main><?php include __DIR__.'/includes/footer.php';?>
