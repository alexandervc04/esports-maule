# ArenaControl — Sistema de Gestión de Torneos de Esports

Proyecto web PHP para XAMPP conectado a Oracle mediante OCI8. La aplicación está construida para utilizar el script `AV_JP_RM_BE_PROYECTO_SIMPLIFICADO.sql` y sus objetos PL/SQL.

## Qué incluye

- Login mediante `AV_JP_RM_BE_SP_LOGIN` y perfiles ADMIN, ORGANIZADOR y CAPITAN.
- 10 mantenedores CRUD: usuarios, videojuegos, plataformas, sedes, patrocinadores, categorías, formatos, equipos, jugadores y árbitros/staff.
- 5 gestores: apertura de torneo; inscripción + roster; fixture; resultados + KDA; sanciones + premiación.
- 3 reportes estratégicos: demanda/recaudación, ranking MVP y ocupación/balance.
- Uso de procedimientos almacenados, funciones indirectamente, secuencias, cursores y triggers del script Oracle.
- Interfaz responsive sin frameworks externos ni Internet.

## 1. Instalar en XAMPP

Copia la carpeta `AV_JP_RM_BE_ESPORTS_WEB` dentro de:

`C:\xampp\htdocs\`

Luego la URL será:

`http://localhost/AV_JP_RM_BE_ESPORTS_WEB/`

## 2. Preparar Oracle

Ejecuta primero el archivo:

`sql/AV_JP_RM_BE_PROYECTO_SIMPLIFICADO.sql`

en el usuario/esquema de Oracle que utilizarás para el proyecto.

El script incluye datos demo. Credenciales web iniciales:

- ADMIN / ADMIN123
- ORGANIZADOR / ORGANIZADOR123
- CAPITAN1 / CAPITAN123
- CAPITAN2 / CAPITAN123

## 3. Habilitar OCI8 en PHP/XAMPP

La web utiliza `oci_connect()`. XAMPP necesita la extensión OCI8 y Oracle Instant Client compatibles con la arquitectura y versión de PHP instalada.

1. Comprueba tu PHP desde `http://localhost/dashboard/phpinfo.php` o `php -v`.
2. Instala Oracle Instant Client de 64 bits si tu XAMPP es de 64 bits.
3. Habilita/instala la extensión OCI8 compatible con tu versión de PHP.
4. Reinicia Apache.
5. Comprueba en `phpinfo()` que aparezca una sección `oci8`.

Si `test_connection.php` indica `OCI8 NO ESTA HABILITADO`, el problema es la extensión de PHP, no el código del proyecto.

> El nombre exacto del DLL de OCI8 depende de la versión de PHP/XAMPP. No copies un DLL de otra versión de PHP porque Apache puede no iniciar.

## 4. Configurar la conexión

Edita:

`config/database.php`

Cambia:

```php
define('DB_USERNAME', 'TU_USUARIO_ORACLE');
define('DB_PASSWORD', 'TU_PASSWORD_ORACLE');
define('DB_CONNECTION_STRING', 'localhost/XEPDB1');
```

Cadenas frecuentes:

- Oracle XE 18c/21c: `localhost/XEPDB1`
- Oracle Database Free 23ai: `localhost/FREEPDB1`

Usa el servicio que realmente aparezca en tu Oracle/SQL Developer.

## 5. Probar antes de presentar

1. Abre la web e inicia sesión con ADMIN.
2. En Dashboard pulsa `Probar conexión Oracle`.
3. Revisa un mantenedor y crea un registro.
4. Crea un torneo.
5. Inscribe al menos 2 equipos con jugadores activos.
6. Genera el fixture una sola vez.
7. Registra un resultado y KDA.
8. Registra una sanción/premio.
9. Abre los tres reportes.

## Cómo explicar la arquitectura

**Capa cliente:** PHP/HTML/CSS en XAMPP presenta formularios y resultados.

**Capa servidor robusta:** Oracle contiene la lógica PL/SQL. PHP llama procedimientos como `AV_JP_RM_BE_SP_INSCRIBIR_EQUIPO`; Oracle valida cupos con una función, usa secuencia para el ID, recorre jugadores mediante cursor y genera el roster. Los triggers se ejecutan automáticamente cuando corresponde.

Esto permite demostrar que PHP no replica la lógica principal de negocio.

## Nota sobre el perfil CAPITAN

El capitán puede entrar a la inscripción y a los reportes. En la inscripción, la web limita los equipos visibles a los que tengan `ID_CAPITAN` igual al usuario conectado. El procedimiento de Oracle sigue realizando la creación de la inscripción y del roster.

## Estructura

- `config/`: conexión y definición de módulos.
- `includes/`: conexión OCI8, sesión, permisos y componentes comunes.
- `assets/`: CSS y JavaScript.
- `sql/`: script Oracle del proyecto.
- `crud.php`: motor común de los 10 mantenedores.
- `gestor_*.php`: gestores de información.
- `reportes.php`: tres dashboards.
