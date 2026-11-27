<?php
return [
'usuarios'=>[
 'title'=>'Usuarios y perfiles','icon'=>'👤','list'=>'AV_JP_RM_BE_SP_USUARIO_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_USUARIO_GUARDAR(:P_ID,:P_USERNAME,:P_CONTRASENA,:P_NOMBRE,:P_EMAIL,:P_PERFIL,:P_ESTADO); END;','delete'=>'AV_JP_RM_BE_SP_USUARIO_ELIMINAR','id'=>'ID_USUARIO','admin_only'=>true,
 'fields'=>[
  'USERNAME'=>['label'=>'Usuario','required'=>true], 'CONTRASENA'=>['label'=>'Contraseña','type'=>'password','db'=>'P_CONTRASENA','edit_optional'=>true],
  'NOMBRE'=>['label'=>'Nombre','required'=>true], 'EMAIL'=>['label'=>'Correo','type'=>'email','required'=>true],
  'PERFIL'=>['label'=>'Perfil','type'=>'select','options'=>['ADMIN'=>'Administrador','ORGANIZADOR'=>'Organizador','CAPITAN'=>'Capitán'],'required'=>true],
  'ESTADO'=>['label'=>'Estado','type'=>'select','options'=>['ACTIVO'=>'Activo','INACTIVO'=>'Inactivo'],'required'=>true]
 ]],
'videojuegos'=>[
 'title'=>'Videojuegos','icon'=>'🎮','list'=>'AV_JP_RM_BE_SP_VIDEOJUEGO_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_VIDEOJUEGO_GUARDAR(:P_ID,:P_NOMBRE,:P_GENERO,:P_JUGADORES_POR_EQUIPO,:P_ESTADO); END;','delete'=>'AV_JP_RM_BE_SP_VIDEOJUEGO_ELIMINAR','id'=>'ID_VIDEOJUEGO',
 'fields'=>['NOMBRE'=>['label'=>'Nombre','required'=>true],'GENERO'=>['label'=>'Género'],'JUGADORES_POR_EQUIPO'=>['label'=>'Jugadores por equipo','type'=>'number','required'=>true],'ESTADO'=>['label'=>'Estado','type'=>'select','options'=>['ACTIVO'=>'Activo','INACTIVO'=>'Inactivo'],'required'=>true]]],
'plataformas'=>[
 'title'=>'Plataformas','icon'=>'🖥️','list'=>'AV_JP_RM_BE_SP_PLATAFORMA_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_PLATAFORMA_GUARDAR(:P_ID,:P_NOMBRE,:P_FABRICANTE,:P_DESCRIPCION); END;','delete'=>'AV_JP_RM_BE_SP_PLATAFORMA_ELIMINAR','id'=>'ID_PLATAFORMA',
 'fields'=>['NOMBRE'=>['label'=>'Nombre','required'=>true],'FABRICANTE'=>['label'=>'Fabricante'],'DESCRIPCION'=>['label'=>'Descripción']]],
'sedes'=>[
 'title'=>'Sedes / modalidades','icon'=>'📍','list'=>'AV_JP_RM_BE_SP_SEDE_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_SEDE_GUARDAR(:P_ID,:P_NOMBRE,:P_DIRECCION,:P_COMUNA,:P_CAPACIDAD,:P_MODALIDAD,:P_ESTADO); END;','delete'=>'AV_JP_RM_BE_SP_SEDE_ELIMINAR','id'=>'ID_SEDE',
 'fields'=>['NOMBRE'=>['label'=>'Nombre','required'=>true],'DIRECCION'=>['label'=>'Dirección'],'COMUNA'=>['label'=>'Comuna','required'=>true],'CAPACIDAD'=>['label'=>'Capacidad','type'=>'number','required'=>true],'MODALIDAD'=>['label'=>'Modalidad','type'=>'select','options'=>['PRESENCIAL'=>'Presencial','ONLINE'=>'Online','HIBRIDA'=>'Híbrida'],'required'=>true],'ESTADO'=>['label'=>'Estado','type'=>'select','options'=>['ACTIVO'=>'Activo','INACTIVO'=>'Inactivo'],'required'=>true]]],
'patrocinadores'=>[
 'title'=>'Patrocinadores','icon'=>'🤝','list'=>'AV_JP_RM_BE_SP_PATROCINADOR_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_PATROCINADOR_GUARDAR(:P_ID,:P_RUT,:P_RAZON_SOCIAL,:P_RUBRO,:P_EMAIL_CONTACTO,:P_TELEFONO); END;','delete'=>'AV_JP_RM_BE_SP_PATROCINADOR_ELIMINAR','id'=>'ID_PATROCINADOR',
 'fields'=>['RUT'=>['label'=>'RUT','required'=>true],'RAZON_SOCIAL'=>['label'=>'Razón social','required'=>true],'RUBRO'=>['label'=>'Rubro'],'EMAIL_CONTACTO'=>['label'=>'Correo','type'=>'email'],'TELEFONO'=>['label'=>'Teléfono']]],
'categorias'=>[
 'title'=>'Categorías / divisiones','icon'=>'🏷️','list'=>'AV_JP_RM_BE_SP_CATEGORIA_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_CATEGORIA_GUARDAR(:P_ID,:P_NOMBRE,:P_DESCRIPCION,:P_EDAD_MINIMA,:P_EDAD_MAXIMA); END;','delete'=>'AV_JP_RM_BE_SP_CATEGORIA_ELIMINAR','id'=>'ID_CATEGORIA',
 'fields'=>['NOMBRE'=>['label'=>'Nombre','required'=>true],'DESCRIPCION'=>['label'=>'Descripción'],'EDAD_MINIMA'=>['label'=>'Edad mínima','type'=>'number','required'=>true],'EDAD_MAXIMA'=>['label'=>'Edad máxima','type'=>'number']]],
'formatos'=>[
 'title'=>'Formatos de torneo','icon'=>'🧩','list'=>'AV_JP_RM_BE_SP_FORMATO_TORNEO_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_FORMATO_TORNEO_GUARDAR(:P_ID,:P_NOMBRE,:P_TIPO,:P_PUNTOS_VICTORIA,:P_PUNTOS_EMPATE); END;','delete'=>'AV_JP_RM_BE_SP_FORMATO_TORNEO_ELIMINAR','id'=>'ID_FORMATO',
 'fields'=>['NOMBRE'=>['label'=>'Nombre','required'=>true],'TIPO'=>['label'=>'Tipo','type'=>'select','options'=>['ELIMINACION_DIRECTA'=>'Eliminación directa','TODOS_CONTRA_TODOS'=>'Todos contra todos'],'required'=>true],'PUNTOS_VICTORIA'=>['label'=>'Puntos victoria','type'=>'number','required'=>true],'PUNTOS_EMPATE'=>['label'=>'Puntos empate','type'=>'number','required'=>true]]],
'equipos'=>[
 'title'=>'Equipos','icon'=>'🛡️','list'=>'AV_JP_RM_BE_SP_EQUIPO_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_EQUIPO_GUARDAR(:P_ID,:P_NOMBRE,:P_TAG,:P_CIUDAD,:P_ID_CAPITAN,:P_ESTADO); END;','delete'=>'AV_JP_RM_BE_SP_EQUIPO_ELIMINAR','id'=>'ID_EQUIPO',
 'fields'=>['NOMBRE'=>['label'=>'Nombre','required'=>true],'TAG'=>['label'=>'TAG','required'=>true],'CIUDAD'=>['label'=>'Ciudad'],'ID_CAPITAN'=>['label'=>'Capitán','type'=>'lookup','lookup'=>'capitanes'],'ESTADO'=>['label'=>'Estado','type'=>'select','options'=>['ACTIVO'=>'Activo','INACTIVO'=>'Inactivo'],'required'=>true]]],
'jugadores'=>[
 'title'=>'Jugadores','icon'=>'⚔️','list'=>'AV_JP_RM_BE_SP_JUGADOR_LISTAR','save'=>"BEGIN AV_JP_RM_BE_SP_JUGADOR_GUARDAR(:P_ID,:P_RUT,:P_NOMBRES,:P_APELLIDOS,:P_NICKNAME,TO_DATE(:P_FECHA_NACIMIENTO,'YYYY-MM-DD'),:P_EMAIL,:P_ID_EQUIPO,:P_ESTADO); END;",'delete'=>'AV_JP_RM_BE_SP_JUGADOR_ELIMINAR','id'=>'ID_JUGADOR',
 'fields'=>['RUT'=>['label'=>'RUT','required'=>true],'NOMBRES'=>['label'=>'Nombres','required'=>true],'APELLIDOS'=>['label'=>'Apellidos','required'=>true],'NICKNAME'=>['label'=>'Nickname','required'=>true],'FECHA_NACIMIENTO'=>['label'=>'Fecha nacimiento','type'=>'date','required'=>true],'EMAIL'=>['label'=>'Correo','type'=>'email'],'ID_EQUIPO'=>['label'=>'Equipo','type'=>'lookup','lookup'=>'equipos'],'ESTADO'=>['label'=>'Estado','type'=>'select','options'=>['ACTIVO'=>'Activo','INACTIVO'=>'Inactivo'],'required'=>true]]],
'arbitros'=>[
 'title'=>'Árbitros / staff','icon'=>'🧑‍⚖️','list'=>'AV_JP_RM_BE_SP_ARBITRO_LISTAR','save'=>'BEGIN AV_JP_RM_BE_SP_ARBITRO_GUARDAR(:P_ID,:P_RUT,:P_NOMBRES,:P_APELLIDOS,:P_EMAIL,:P_TELEFONO,:P_TIPO,:P_ESTADO); END;','delete'=>'AV_JP_RM_BE_SP_ARBITRO_ELIMINAR','id'=>'ID_ARBITRO',
 'fields'=>['RUT'=>['label'=>'RUT','required'=>true],'NOMBRES'=>['label'=>'Nombres','required'=>true],'APELLIDOS'=>['label'=>'Apellidos','required'=>true],'EMAIL'=>['label'=>'Correo','type'=>'email'],'TELEFONO'=>['label'=>'Teléfono'],'TIPO'=>['label'=>'Tipo','type'=>'select','options'=>['ARBITRO'=>'Árbitro','STAFF'=>'Staff','CASTER'=>'Caster'],'required'=>true],'ESTADO'=>['label'=>'Estado','type'=>'select','options'=>['ACTIVO'=>'Activo','INACTIVO'=>'Inactivo'],'required'=>true]]]
];
