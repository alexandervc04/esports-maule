# Sistema de Gestión de Torneos de Esports
UCM · ECI224 Base de Datos · Evaluación 3 (Proyecto Final) · Oracle Database 21c XE + PHP 8 (OCI8)

## Contenido
| Archivo | Descripción |
|---|---|
| `script.sql` | Script completo y estructurado: tablas 3FN, secuencias, funciones, procedimientos, cursores, triggers y datos de prueba |
| `app/` | Aplicación web PHP (arquitectura de 2 capas: cliente PHP ↔ servidor Oracle con la lógica en PL/SQL) |

## 1. Base de datos (Oracle XE 21c)
1. Como `SYSTEM`, conectado a `XEPDB1`, crear el esquema (una sola vez):
   ```sql
   CREATE USER esports IDENTIFIED BY esports2026 DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
   GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER, CREATE VIEW TO esports;
   ```
2. Conectarse como `esports` en SQL Developer, abrir `script.sql` y ejecutarlo con **Ejecutar script (F5)**.
   El script se puede re-ejecutar: borra y recrea todo.
3. Al final deben verse los mensajes `OK ...` de la carga y la consulta de verificación con **0 objetos inválidos**.

## 2. Aplicación (XAMPP en Windows)
1. Instalar **Oracle Instant Client** (Basic, 64 bits, versión 19 o 21) y agregar su carpeta al `PATH` de Windows.
2. En `C:\xampp\php\php.ini` descomentar/agregar `extension=oci8_19` (para Instant Client 19/21 con PHP 8) y reiniciar Apache.
   Comprobar en `phpinfo()` que aparece la sección **oci8**. Si la DLL `php_oci8_19.dll` no está en `C:\xampp\php\ext`, descargar la versión de OCI8 para su PHP desde PECL (pecl.php.net/package/oci8).
3. Copiar la carpeta `app` a `C:\xampp\htdocs\esports`.
4. Revisar `app/config/config.php` (usuario, clave y `localhost:1521/XEPDB1`).
5. Abrir `http://localhost/esports/`.

## 3. Usuarios de prueba
| Perfil | Usuario | Contraseña | Acceso |
|---|---|---|---|
| Administrador General | `admin` | `Admin2026!` | Todo + usuarios + auditoría |
| Organizador / Árbitro | `organizador` | `Orga2026!` | Mantenedores (excepto usuarios), 5 gestores, 3 reportes |
| Organizador / Árbitro | `arbitro.rojas` | `Arbitro2026!` | Igual al anterior |
| Capitán de Equipo | `cap.tlt` (Talca Titans) | `Capitan2026!` | Jugadores de su equipo, inscripción, fixture, ranking |

Capitanes: `cap.` + tag del equipo en minúsculas (`cap.lrw`, `cap.cpx`, `cap.mrv`, `cap.lnx`, `cap.cqs`, `cap.ctw`, `cap.sjv`, `cap.mlh`, `cap.prp`, `cap.ucd`, `cap.tnk`).
Tras 5 contraseñas incorrectas la cuenta queda **BLOQUEADA** (el admin la reactiva en Usuarios).

## 4. Datos precargados (generados con los mismos procedimientos de la app)
| Torneo | Estado | Para demostrar |
|---|---|---|
| Copa Maule LoL Apertura 2026 | Finalizado | Llaves de eliminación directa, podio y premios |
| Liga Valorant Talca 2026 | Finalizado | Liga con 5 equipos (fecha libre), sanción con descuento de puntos |
| Rocket League Cup Curicó 2026 | Finalizado | Eliminación con 6 equipos (BYE automático) |
| Torneo CS2 Primavera UCM 2026 | En curso | Registrar resultados pendientes, corregir marcador (auditoría), liquidar premios |
| Copa EA Sports FC Online Maule | Abierto | Inscripción 1 vs 1, sede online |
| Liga LoL Clausura Maule 2026 | Abierto | Inscripción con plantilla y generación de fixture en vivo |
| Clash Royale Express Primavera | Cancelado | Control de transición de estados |

Un titular de **San Javier Vipers** quedó **suspendido 14 días** en el torneo de CS2: al intentar inscribirlo en otro torneo, la BD lo rechaza.

## 5. Guion sugerido para el video de demostración
1. Login con contraseña errada (mensaje de intentos restantes) y luego login como `organizador`.
2. **Mantenedores**: crear, editar y eliminar un registro (ej. un patrocinador con RUT inválido → la BD lo rechaza; luego válido).
3. **Gestor 1**: abrir un torneo con patrocinadores (probar un cupo que exceda el aforo de la sede → rechazo).
4. **Gestor 2**: como `cap.sjv`, inscribir San Javier Vipers en la Liga LoL Clausura incluyendo al jugador suspendido → rechazo; quitarlo → inscripción exitosa.
5. **Gestor 3**: generar el fixture de la Liga LoL Clausura.
6. **Gestor 4**: registrar los resultados pendientes del torneo CS2 con KDA; corregir uno (aparece en Auditoría).
7. **Gestor 5**: aplicar una sanción y liquidar premios del torneo CS2 (podio en Fixture).
8. **Reportes**: los 3 dashboards. 9. Como `admin`: Auditoría y accesos.

## 6. Mapeo pauta → objetos de la base de datos
| Requisito | Implementación |
|---|---|
| Control de acceso | `SP_LOGIN`, `FN_HASH_PASSWORD` (SHA-256), `SP_VALIDAR_PERMISO` en cada SP de escritura, `LOG_ACCESO`, bloqueo tras 5 intentos |
| 10 mantenedores | `SP_<ENTIDAD>_LISTAR / _INSERTAR / _ACTUALIZAR / _ELIMINAR` para Usuarios, Videojuegos, Plataformas, Sedes, Patrocinadores, Categorías, Formatos, Equipos, Jugadores, Árbitros |
| 5 gestores | `SP_ABRIR_TORNEO`, `SP_INSCRIBIR_EQUIPO`, `SP_GENERAR_FIXTURE`, `SP_REGISTRAR_RESULTADO` (+`SP_AVANZAR_RONDA`), `SP_REGISTRAR_SANCION` / `SP_LIQUIDAR_PREMIOS` |
| 3 reportes | `SP_REPORTE_DEMANDA_JUEGO`, `SP_REPORTE_RANKING_MVP`, `SP_REPORTE_OCUPACION_SEDES` (2 cursores de salida) |
| Funciones (15) | `FN_VALIDAR_CUPOS_TORNEO`, `FN_CALCULAR_RATIO_KDA`, `FN_VERIFICAR_ESTADO_JUGADOR`, `FN_VALIDAR_RUT`, `FN_HASH_PASSWORD`, `FN_PUNTOS_RESULTADO`, `FN_KDA_JUGADOR`, `FN_ASIGNAR_ARBITRO`, ... |
| Secuencias (19) | `SEQ_<TABLA>` para todas las llaves primarias |
| Cursores explícitos | `SP_LOGIN`, `SP_EQUIPO_ELIMINAR`, `SP_INSCRIBIR_EQUIPO`, `SP_GENERAR_FIXTURE`, `SP_AVANZAR_RONDA`, `SP_REGISTRAR_RESULTADO` (MVP), `SP_PROCESAR_SANCIONES_VENCIDAS`, `SP_LIQUIDAR_PREMIOS`, `FN_ASIGNAR_ARBITRO`; `SYS_REFCURSOR` en todas las lecturas |
| Triggers (8) | `TRG_BLOQUEAR_SANCIONADO`, `TRG_AUDITORIA_MARCADORES`, `TRG_PROTEGER_PARTIDAS`, `TRG_SANCION_SUSPENDER`, `TRG_VALIDAR_JUGADOR`, `TRG_TORNEO_ESTADO`, `TRG_AUDITORIA_USUARIO`, `TRG_AUDITORIA_INSCRIPCION` |
| Concurrencia | `SELECT ... FOR UPDATE` sobre el torneo al inscribir y generar fixture; `COMMIT/ROLLBACK` en cada SP |
| Capa cliente | `app/lib/Database.php`: solo invoca procedimientos (`BEGIN sp_x(...); END;`); no contiene SQL de negocio |

Modelo gráfico 3FN: en SQL Developer, *Archivo → Data Modeler → Importar → Diccionario de datos*, seleccionar el esquema `ESPORTS` y todas las tablas.
