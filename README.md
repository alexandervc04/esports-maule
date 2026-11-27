# Sistema de Gestión de Torneos de Esports

UCM · ECI224 Base de Datos · Evaluación 3 (Proyecto Final) · Oracle Database 21c XE + PHP 8 + XAMPP + OCI8
> Todos los objetos principales de la base de datos utilizan el prefijo `AV_JP_RM_BE_`.

## Contenido del proyecto

| Archivo / carpeta | Descripción |
|---|---|
| `script.sql` | Script completo de Oracle: 19 tablas en 3FN, 16 secuencias, 3 funciones, 46 procedimientos, cursores, 2 triggers y datos de prueba. |
| `MODELO_3FN.mdj` | Modelo gráfico de la base de datos en 3FN para abrir y editar en StarUML. |
| `app/` | Aplicación web PHP desarrollada para XAMPP y conectada a Oracle mediante OCI8. |
| `app/sql/main.sql` | Copia del script Oracle incluida dentro del proyecto web. |
| `MAPA_PARA_PRESENTACION.txt` | Resumen de los módulos y objetos PL/SQL utilizados, pensado como apoyo para la defensa. |
| `README.md` | Instrucciones generales de instalación, ejecución y demostración del proyecto. |

## 1. Base de datos — Oracle XE 21c

### 1.1 Crear el usuario/esquema

Conectarse como `SYSTEM` a `XEPDB1` y ejecutar una sola vez:

```sql
CREATE USER ESPORTS IDENTIFIED BY ESPORTS2026
DEFAULT TABLESPACE USERS
QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE SEQUENCE,
      CREATE PROCEDURE,
      CREATE TRIGGER
TO ESPORTS;
```

Después conectarse en SQL Developer con:

- Usuario: `ESPORTS`
- Contraseña: `ESPORTS2026`
- Host: `localhost`
- Puerto: `1521`
- Servicio: `XEPDB1`

### 1.2 Ejecutar el script

Abrir el archivo:

```text
script.sql
```

y ejecutarlo en SQL Developer utilizando **Ejecutar script (F5)**.

El script crea:

- 19 tablas normalizadas hasta 3FN.
- 16 secuencias.
- 3 funciones de negocio.
- 46 procedimientos almacenados.
- Cursores explícitos y `SYS_REFCURSOR`.
- 2 triggers de monitoreo.
- Datos iniciales para realizar pruebas.

> Importante: el script está pensado para ejecutarse sobre un **esquema limpio**. No elimina automáticamente los objetos existentes. Si se necesita volver a ejecutarlo desde cero, primero se deben eliminar los objetos anteriores o recrear el esquema `ESPORTS`.

### 1.3 Comprobar objetos inválidos

Después de ejecutar el script se puede comprobar que no existan procedimientos, funciones o triggers inválidos con:

```sql
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE STATUS = 'INVALID';
```

El resultado esperado es **0 filas**.

## 2. Aplicación web — XAMPP en Windows

La aplicación se encuentra en:

```text
app/
```

### 2.1 Copiar el proyecto a XAMPP

Copiar la carpeta completa dentro de:

```text
C:\xampp\htdocs\
```

Debe quedar aproximadamente así:

```text
C:\xampp\htdocs\app\
```

### 2.2 Instalar y habilitar OCI8

La aplicación utiliza `oci_connect()` para comunicarse con Oracle.

1. Verificar la versión y arquitectura de PHP utilizada por XAMPP mediante `phpinfo()` o:

```bash
php -v
```

2. Instalar **Oracle Instant Client** compatible con la arquitectura de XAMPP, normalmente 64 bits.
3. Agregar la carpeta de Oracle Instant Client al `PATH` de Windows.
4. Habilitar una extensión OCI8 compatible con la versión instalada de PHP en:

```text
C:\xampp\php\php.ini
```

5. Reiniciar Apache desde el Panel de Control de XAMPP.
6. Revisar en `phpinfo()` que aparezca la sección **oci8**.

> El nombre exacto de la DLL de OCI8 depende de la versión de PHP incluida en XAMPP. No se debe copiar una DLL correspondiente a otra versión de PHP porque Apache puede dejar de iniciar.

### 2.3 Configurar la conexión con Oracle

Editar:

```text
app/config/database.php
```

Configurar:

```php
define('DB_USERNAME', 'ESPORTS');
define('DB_PASSWORD', 'ESPORTS2026');
define('DB_CONNECTION_STRING', 'localhost/XEPDB1');
define('DB_CHARSET', 'AL32UTF8');
```

Si se utiliza otra instancia de Oracle, modificar únicamente los datos correspondientes.

### 2.4 Probar la conexión

Con Apache iniciado, abrir:

```text
http://localhost/app/test_connection.php
```

Si la configuración es correcta, la página confirmará la conexión con Oracle.

Luego abrir la aplicación principal:

```text
http://localhost/app/
```

## 3. Usuarios de prueba

El script incluye cuatro cuentas iniciales:

| Perfil | Usuario | Contraseña | Acceso principal |
|---|---|---|---|
| Administrador General | `ADMIN` | `ADMIN123` | Dashboard, usuarios, 10 mantenedores, 5 gestores y 3 reportes. |
| Organizador | `ORGANIZADOR` | `ORGANIZADOR123` | Mantenedores excepto usuarios, 5 gestores y 3 reportes. |
| Capitán | `CAPITAN1` | `CAPITAN123` | Inscripción de su equipo, consulta de información y reportes. |
| Capitán | `CAPITAN2` | `CAPITAN123` | Inscripción de su equipo, consulta de información y reportes. |

Las contraseñas no se almacenan como texto plano. El procedimiento `AV_JP_RM_BE_SP_LOGIN` compara la contraseña utilizando `STANDARD_HASH(..., 'SHA256')`.

## 4. Datos precargados

El script incorpora un conjunto mínimo de datos para comprobar el funcionamiento de la aplicación:

| Elemento | Datos de prueba |
|---|---|
| Videojuego | `EA SPORTS FC 26` |
| Plataforma | `PC` |
| Sede | `UCM TALCA` |
| Categoría | `UNIVERSITARIA` |
| Formato | `TODOS CONTRA TODOS` |
| Equipos | `UCM AZUL` y `UCM ROJO` |
| Jugadores | `PLAYERAZUL` y `PLAYERROJO` |
| Árbitro | `ARBITRO PRINCIPAL` |
| Torneo | `COPA UCM ESPORTS` |
| Estado inicial del torneo | `ABIERTO` |
| Inscripciones | UCM Azul y UCM Rojo confirmados |
| Partida | Una partida programada entre ambos equipos |

Estos registros son únicamente datos de demostración y pueden reemplazarse por información más realista antes de la presentación.

## 5. Módulos de la aplicación

### 5.1 Control de acceso

El ingreso se realiza mediante:

```text
AV_JP_RM_BE_SP_LOGIN
```

La aplicación reconoce tres perfiles:

- `ADMIN`
- `ORGANIZADOR`
- `CAPITAN`

El perfil determina las opciones disponibles en el menú de PHP.

### 5.2 Diez mantenedores CRUD

La aplicación implementa los siguientes mantenedores:

1. Usuarios y perfiles.
2. Videojuegos.
3. Plataformas.
4. Sedes / modalidades.
5. Patrocinadores.
6. Categorías / divisiones.
7. Formatos de torneo.
8. Equipos.
9. Jugadores.
10. Árbitros / staff.

Para simplificar la implementación y facilitar la defensa, cada mantenedor sigue el mismo patrón:

```text
AV_JP_RM_BE_SP_<ENTIDAD>_GUARDAR
AV_JP_RM_BE_SP_<ENTIDAD>_LISTAR
AV_JP_RM_BE_SP_<ENTIDAD>_ELIMINAR
```

`GUARDAR` realiza tanto la creación como la actualización según exista o no un ID. `LISTAR` devuelve la información mediante `SYS_REFCURSOR` y `ELIMINAR` realiza el borrado.

### 5.3 Cinco gestores de información

| Gestor | Implementación principal |
|---|---|
| 1. Apertura de torneos | `AV_JP_RM_BE_SP_ABRIR_TORNEO` |
| 2. Inscripción y roster | `AV_JP_RM_BE_SP_INSCRIBIR_EQUIPO` |
| 3. Generación de fixture | `AV_JP_RM_BE_SP_GENERAR_FIXTURE` |
| 4. Resultados y KDA | `AV_JP_RM_BE_SP_REGISTRAR_RESULTADO` y `AV_JP_RM_BE_SP_REGISTRAR_KDA` |
| 5. Sanciones y premiación | `AV_JP_RM_BE_SP_REGISTRAR_SANCION` y `AV_JP_RM_BE_SP_REGISTRAR_PREMIO` |

### 5.4 Tres reportes estratégicos

| Reporte | Procedimiento |
|---|---|
| Demanda y recaudación por videojuego | `AV_JP_RM_BE_SP_REPORTE_DEMANDA_JUEGO` |
| Ranking de jugadores MVP | `AV_JP_RM_BE_SP_REPORTE_RANKING_MVP` |
| Ocupación de sedes y balance | `AV_JP_RM_BE_SP_REPORTE_OCUPACION_SEDES` |

## 6. Mapeo pauta → objetos de la base de datos

| Requisito | Implementación del proyecto |
|---|---|
| Control de acceso | `AV_JP_RM_BE_SP_LOGIN`, perfiles `ADMIN`, `ORGANIZADOR` y `CAPITAN`, contraseña comparada mediante SHA-256. |
| 10 mantenedores | Patrón `SP_<ENTIDAD>_GUARDAR`, `SP_<ENTIDAD>_LISTAR` y `SP_<ENTIDAD>_ELIMINAR`. |
| 5 gestores | Apertura de torneo, inscripción/roster, fixture, resultados/KDA y sanciones/premiación. |
| 3 reportes | Demanda por videojuego, ranking MVP y ocupación de sedes. |
| Funciones (3) | `AV_JP_RM_BE_FN_VALIDAR_CUPOS_TORNEO`, `AV_JP_RM_BE_FN_CALCULAR_RATIO_KDA`, `AV_JP_RM_BE_FN_VERIFICAR_ESTADO_JUGADOR`. |
| Secuencias (16) | Secuencias `AV_JP_RM_BE_SEQ_*` para las entidades que requieren IDs correlativos. |
| Cursores explícitos | Cursor de jugadores en `AV_JP_RM_BE_SP_INSCRIBIR_EQUIPO` y cursor `OPEN / FETCH / CLOSE` en `AV_JP_RM_BE_SP_GENERAR_FIXTURE`. |
| Cursores de salida | `SYS_REFCURSOR` en mantenedores, consultas de apoyo y reportes. |
| Triggers (2) | `AV_JP_RM_BE_TRG_BLOQUEAR_SANCIONADO` y `AV_JP_RM_BE_TRG_AUDITORIA_MARCADORES`. |
| Transacciones | Los procedimientos de escritura utilizan `COMMIT` y `ROLLBACK` con manejo de excepciones. |
| Normalización | 19 tablas en 3FN, incluyendo tablas intermedias como `AV_JP_RM_BE_INSCRIPCION`, `AV_JP_RM_BE_ROSTER`, `AV_JP_RM_BE_TORNEO_PATROCINADOR` y `AV_JP_RM_BE_DETALLE_PARTIDA_JUGADOR`. |
| Capa cliente | PHP/HTML/CSS en XAMPP. PHP invoca procedimientos Oracle mediante OCI8 y no replica la lógica principal de negocio. |
| Capa servidor | Oracle Database concentra reglas, validaciones, secuencias, cursores, procedimientos, funciones y triggers. |

## 7. Funciones principales

### `AV_JP_RM_BE_FN_VALIDAR_CUPOS_TORNEO`

Comprueba si un torneo todavía posee cupos disponibles antes de realizar una inscripción.

### `AV_JP_RM_BE_FN_CALCULAR_RATIO_KDA`

Calcula el indicador KDA de un jugador utilizando kills, deaths y assists.

### `AV_JP_RM_BE_FN_VERIFICAR_ESTADO_JUGADOR`

Comprueba si un jugador está activo o posee una suspensión vigente.

## 8. Triggers de monitoreo

### `AV_JP_RM_BE_TRG_BLOQUEAR_SANCIONADO`

Se ejecuta antes de insertar o modificar un jugador en un roster. Si el jugador está suspendido o inactivo, Oracle rechaza la operación.

### `AV_JP_RM_BE_TRG_AUDITORIA_MARCADORES`

Se ejecuta después de modificar los marcadores de una partida y registra los valores anteriores y nuevos en `AV_JP_RM_BE_AUDITORIA`.

## 9. Guion sugerido para la demostración

1. Abrir `test_connection.php` y demostrar que PHP se encuentra conectado a Oracle.
2. Intentar iniciar sesión con una contraseña incorrecta y luego ingresar como `ORGANIZADOR`.
3. Entrar a un mantenedor, por ejemplo **Patrocinadores**, y demostrar crear, editar, listar y eliminar.
4. Crear
