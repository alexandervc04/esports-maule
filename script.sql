/* ============================================================================
   UNIVERSIDAD CATÓLICA DEL MAULE - ECI224 BASE DE DATOS - EVALUACIÓN 3
   PROYECTO FINAL: "SISTEMA DE GESTIÓN DE TORNEOS DE ESPORTS"
   Motor     : Oracle Database 21c XE (PL/SQL)
   Académico : Carlos Andrés Castro Bustamante
   ----------------------------------------------------------------------------
   ESTRUCTURA DEL SCRIPT
     0. Limpieza (permite re-ejecutar el script completo)
     1. Tablas (modelo relacional en 3FN) y restricciones
     2. Secuencias
     3. Funciones
     4. Procedimientos: login y control de acceso
     5. Procedimientos: 10 mantenedores (CRUD)
     6. Procedimientos: 5 gestores de información
     7. Procedimientos: 3 reportes estratégicos + resumen
     8. Triggers de monitoreo y control
     9. Datos de prueba (cargados usando los mismos procedimientos)
   ----------------------------------------------------------------------------
   Ejecutar conectado al esquema del proyecto (ej. ESPORTS) en SQL Developer
   con "Ejecutar script" (F5) o en SQL*Plus con @script.sql
   ============================================================================ */

-- (Opcional, como SYSTEM en XEPDB1) creación del esquema del proyecto:
-- CREATE USER esports IDENTIFIED BY esports2026 DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
-- GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER, CREATE VIEW TO esports;

SET DEFINE OFF
SET SQLBLANKLINES ON
SET SERVEROUTPUT ON SIZE UNLIMITED

/* ============================================================================
   0. LIMPIEZA
   ============================================================================ */
DECLARE
    TYPE t_lista IS TABLE OF VARCHAR2(30);
    v_tablas t_lista := t_lista(
        'LOG_ACCESO','AUDITORIA_GENERAL','AUDITORIA_MARCADOR','PREMIACION','SANCION',
        'DETALLE_PARTIDA_JUGADOR','PARTIDA','ROSTER','INSCRIPCION','TORNEO_PATROCINADOR',
        'TORNEO','ARBITRO','JUGADOR','EQUIPO','FORMATO_TORNEO','CATEGORIA','PATROCINADOR',
        'SEDE','PLATAFORMA','VIDEOJUEGO','USUARIO','PERFIL');
    v_secuencias t_lista := t_lista(
        'SEQ_PERFIL','SEQ_USUARIO','SEQ_VIDEOJUEGO','SEQ_PLATAFORMA','SEQ_SEDE',
        'SEQ_PATROCINADOR','SEQ_CATEGORIA','SEQ_FORMATO','SEQ_EQUIPO','SEQ_JUGADOR',
        'SEQ_ARBITRO','SEQ_TORNEO','SEQ_INSCRIPCION','SEQ_PARTIDA','SEQ_SANCION',
        'SEQ_PREMIACION','SEQ_AUDITORIA','SEQ_AUDITORIA_GEN','SEQ_LOG_ACCESO');
BEGIN
    FOR i IN 1 .. v_tablas.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE ' || v_tablas(i) || ' CASCADE CONSTRAINTS PURGE';
        EXCEPTION WHEN OTHERS THEN NULL;  -- la tabla no existía
        END;
    END LOOP;
    FOR i IN 1 .. v_secuencias.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE ' || v_secuencias(i);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

/* ============================================================================
   1. TABLAS
   Catálogos independientes (3FN): PERFIL, VIDEOJUEGO, PLATAFORMA, SEDE,
   PATROCINADOR, CATEGORIA, FORMATO_TORNEO.
   Tablas intermedias N:M (2FN): TORNEO_PATROCINADOR, INSCRIPCION, ROSTER,
   DETALLE_PARTIDA_JUGADOR.
   ============================================================================ */

-- ---------- Seguridad ----------
CREATE TABLE perfil (
    id_perfil     NUMBER(3)      CONSTRAINT pk_perfil PRIMARY KEY,
    codigo        VARCHAR2(20)   NOT NULL CONSTRAINT uq_perfil_codigo UNIQUE,
    nombre        VARCHAR2(50)   NOT NULL,
    descripcion   VARCHAR2(200),
    CONSTRAINT ck_perfil_codigo CHECK (codigo IN ('ADMIN','ORGANIZADOR','CAPITAN'))
);

CREATE TABLE usuario (
    id_usuario         NUMBER(10)     CONSTRAINT pk_usuario PRIMARY KEY,
    username           VARCHAR2(30)   NOT NULL CONSTRAINT uq_usuario_username UNIQUE,
    password_hash      VARCHAR2(64)   NOT NULL,
    nombre_completo    VARCHAR2(100)  NOT NULL,
    email              VARCHAR2(100)  NOT NULL CONSTRAINT uq_usuario_email UNIQUE,
    id_perfil          NUMBER(3)      NOT NULL CONSTRAINT fk_usuario_perfil REFERENCES perfil(id_perfil),
    estado             VARCHAR2(10)   DEFAULT 'ACTIVO' NOT NULL,
    intentos_fallidos  NUMBER(2)      DEFAULT 0 NOT NULL,
    fecha_creacion     DATE           DEFAULT SYSDATE NOT NULL,
    ultimo_acceso      DATE,
    CONSTRAINT ck_usuario_estado CHECK (estado IN ('ACTIVO','BLOQUEADO','INACTIVO'))
);

-- ---------- Catálogos ----------
CREATE TABLE videojuego (
    id_videojuego         NUMBER(6)      CONSTRAINT pk_videojuego PRIMARY KEY,
    nombre                VARCHAR2(60)   NOT NULL CONSTRAINT uq_videojuego_nombre UNIQUE,
    genero                VARCHAR2(40)   NOT NULL,
    desarrolladora        VARCHAR2(60),
    jugadores_por_equipo  NUMBER(2)      NOT NULL,
    estado                VARCHAR2(10)   DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT ck_videojuego_jug    CHECK (jugadores_por_equipo BETWEEN 1 AND 11),
    CONSTRAINT ck_videojuego_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE plataforma (
    id_plataforma  NUMBER(6)      CONSTRAINT pk_plataforma PRIMARY KEY,
    nombre         VARCHAR2(40)   NOT NULL CONSTRAINT uq_plataforma_nombre UNIQUE,
    fabricante     VARCHAR2(60),
    descripcion    VARCHAR2(200)
);

CREATE TABLE sede (
    id_sede     NUMBER(6)      CONSTRAINT pk_sede PRIMARY KEY,
    nombre      VARCHAR2(80)   NOT NULL CONSTRAINT uq_sede_nombre UNIQUE,
    direccion   VARCHAR2(120),
    comuna      VARCHAR2(50)   NOT NULL,
    capacidad   NUMBER(5)      NOT NULL,
    modalidad   VARCHAR2(10)   NOT NULL,
    estado      VARCHAR2(10)   DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT ck_sede_capacidad CHECK (capacidad > 0),
    CONSTRAINT ck_sede_modalidad CHECK (modalidad IN ('PRESENCIAL','ONLINE','HIBRIDA')),
    CONSTRAINT ck_sede_estado    CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE patrocinador (
    id_patrocinador  NUMBER(6)      CONSTRAINT pk_patrocinador PRIMARY KEY,
    rut              VARCHAR2(12)   NOT NULL CONSTRAINT uq_patrocinador_rut UNIQUE,
    razon_social     VARCHAR2(100)  NOT NULL,
    rubro            VARCHAR2(50),
    email_contacto   VARCHAR2(100),
    telefono         VARCHAR2(20)
);

CREATE TABLE categoria (
    id_categoria  NUMBER(6)      CONSTRAINT pk_categoria PRIMARY KEY,
    nombre        VARCHAR2(50)   NOT NULL CONSTRAINT uq_categoria_nombre UNIQUE,
    descripcion   VARCHAR2(200),
    edad_minima   NUMBER(2)      DEFAULT 0 NOT NULL,
    edad_maxima   NUMBER(2),
    CONSTRAINT ck_categoria_edades CHECK (edad_maxima IS NULL OR edad_maxima >= edad_minima)
);

CREATE TABLE formato_torneo (
    id_formato       NUMBER(6)      CONSTRAINT pk_formato_torneo PRIMARY KEY,
    nombre           VARCHAR2(60)   NOT NULL CONSTRAINT uq_formato_nombre UNIQUE,
    tipo             VARCHAR2(20)   NOT NULL,
    puntos_victoria  NUMBER(2)      DEFAULT 3 NOT NULL,
    puntos_empate    NUMBER(2)      DEFAULT 1 NOT NULL,
    descripcion      VARCHAR2(200),
    CONSTRAINT ck_formato_tipo CHECK (tipo IN ('ELIMINACION_DIRECTA','TODOS_CONTRA_TODOS')),
    CONSTRAINT ck_formato_puntos CHECK (puntos_victoria > puntos_empate AND puntos_empate >= 0)
);

-- ---------- Entidades principales ----------
CREATE TABLE equipo (
    id_equipo        NUMBER(8)      CONSTRAINT pk_equipo PRIMARY KEY,
    nombre           VARCHAR2(60)   NOT NULL CONSTRAINT uq_equipo_nombre UNIQUE,
    tag              VARCHAR2(5)    NOT NULL CONSTRAINT uq_equipo_tag UNIQUE,
    ciudad           VARCHAR2(50),
    fecha_fundacion  DATE,
    id_capitan       NUMBER(10)     CONSTRAINT fk_equipo_capitan REFERENCES usuario(id_usuario)
                                    CONSTRAINT uq_equipo_capitan UNIQUE,
    estado           VARCHAR2(10)   DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT ck_equipo_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE jugador (
    id_jugador        NUMBER(8)      CONSTRAINT pk_jugador PRIMARY KEY,
    rut               VARCHAR2(12)   NOT NULL CONSTRAINT uq_jugador_rut UNIQUE,
    nombres           VARCHAR2(60)   NOT NULL,
    apellidos         VARCHAR2(60)   NOT NULL,
    nickname          VARCHAR2(30)   NOT NULL CONSTRAINT uq_jugador_nickname UNIQUE,
    fecha_nacimiento  DATE           NOT NULL,
    email             VARCHAR2(100),
    id_equipo         NUMBER(8)      CONSTRAINT fk_jugador_equipo REFERENCES equipo(id_equipo),
    rol_juego         VARCHAR2(30),
    estado            VARCHAR2(10)   DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT ck_jugador_estado CHECK (estado IN ('ACTIVO','SANCIONADO','INACTIVO'))
);

CREATE TABLE arbitro (
    id_arbitro  NUMBER(6)      CONSTRAINT pk_arbitro PRIMARY KEY,
    rut         VARCHAR2(12)   NOT NULL CONSTRAINT uq_arbitro_rut UNIQUE,
    nombres     VARCHAR2(60)   NOT NULL,
    apellidos   VARCHAR2(60)   NOT NULL,
    email       VARCHAR2(100),
    telefono    VARCHAR2(20),
    tipo        VARCHAR2(10)   DEFAULT 'ARBITRO' NOT NULL,
    id_usuario  NUMBER(10)     CONSTRAINT fk_arbitro_usuario REFERENCES usuario(id_usuario)
                               CONSTRAINT uq_arbitro_usuario UNIQUE,
    estado      VARCHAR2(10)   DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT ck_arbitro_tipo   CHECK (tipo IN ('ARBITRO','STAFF','CASTER')),
    CONSTRAINT ck_arbitro_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

-- ---------- Transacciones ----------
CREATE TABLE torneo (
    id_torneo          NUMBER(8)      CONSTRAINT pk_torneo PRIMARY KEY,
    nombre             VARCHAR2(100)  NOT NULL CONSTRAINT uq_torneo_nombre UNIQUE,
    id_videojuego      NUMBER(6)      NOT NULL CONSTRAINT fk_torneo_videojuego REFERENCES videojuego(id_videojuego),
    id_plataforma      NUMBER(6)      NOT NULL CONSTRAINT fk_torneo_plataforma REFERENCES plataforma(id_plataforma),
    id_sede            NUMBER(6)      NOT NULL CONSTRAINT fk_torneo_sede REFERENCES sede(id_sede),
    id_formato         NUMBER(6)      NOT NULL CONSTRAINT fk_torneo_formato REFERENCES formato_torneo(id_formato),
    id_categoria       NUMBER(6)      NOT NULL CONSTRAINT fk_torneo_categoria REFERENCES categoria(id_categoria),
    id_organizador     NUMBER(10)     NOT NULL CONSTRAINT fk_torneo_organizador REFERENCES usuario(id_usuario),
    fecha_inicio       DATE           NOT NULL,
    fecha_fin          DATE           NOT NULL,
    cupo_maximo        NUMBER(3)      NOT NULL,
    costo_inscripcion  NUMBER(10)     DEFAULT 0 NOT NULL,
    premio_total       NUMBER(12)     DEFAULT 0 NOT NULL,
    estado             VARCHAR2(10)   DEFAULT 'ABIERTO' NOT NULL,
    fecha_creacion     DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT ck_torneo_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT ck_torneo_cupo   CHECK (cupo_maximo BETWEEN 2 AND 128),
    CONSTRAINT ck_torneo_montos CHECK (costo_inscripcion >= 0 AND premio_total >= 0),
    CONSTRAINT ck_torneo_estado CHECK (estado IN ('ABIERTO','EN_CURSO','FINALIZADO','CANCELADO'))
);

CREATE TABLE torneo_patrocinador (
    id_torneo        NUMBER(8)   CONSTRAINT fk_tp_torneo REFERENCES torneo(id_torneo),
    id_patrocinador  NUMBER(6)   CONSTRAINT fk_tp_patrocinador REFERENCES patrocinador(id_patrocinador),
    monto_aporte     NUMBER(12)  DEFAULT 0 NOT NULL,
    CONSTRAINT pk_torneo_patrocinador PRIMARY KEY (id_torneo, id_patrocinador),
    CONSTRAINT ck_tp_monto CHECK (monto_aporte >= 0)
);

CREATE TABLE inscripcion (
    id_inscripcion     NUMBER(10)     CONSTRAINT pk_inscripcion PRIMARY KEY,
    id_torneo          NUMBER(8)      NOT NULL CONSTRAINT fk_insc_torneo REFERENCES torneo(id_torneo),
    id_equipo          NUMBER(8)      NOT NULL CONSTRAINT fk_insc_equipo REFERENCES equipo(id_equipo),
    fecha_inscripcion  DATE           DEFAULT SYSDATE NOT NULL,
    monto_pagado       NUMBER(10)     DEFAULT 0 NOT NULL,
    puntos             NUMBER(4)      DEFAULT 0 NOT NULL,
    estado             VARCHAR2(10)   DEFAULT 'CONFIRMADA' NOT NULL,
    CONSTRAINT uq_insc_torneo_equipo UNIQUE (id_torneo, id_equipo),
    CONSTRAINT ck_insc_estado CHECK (estado IN ('CONFIRMADA','RETIRADA'))
);

CREATE TABLE roster (
    id_inscripcion  NUMBER(10)  CONSTRAINT fk_roster_insc REFERENCES inscripcion(id_inscripcion) ON DELETE CASCADE,
    id_jugador      NUMBER(8)   CONSTRAINT fk_roster_jugador REFERENCES jugador(id_jugador),
    es_titular      CHAR(1)     DEFAULT 'S' NOT NULL,
    CONSTRAINT pk_roster PRIMARY KEY (id_inscripcion, id_jugador),
    CONSTRAINT ck_roster_titular CHECK (es_titular IN ('S','N'))
);

CREATE TABLE partida (
    id_partida         NUMBER(10)     CONSTRAINT pk_partida PRIMARY KEY,
    id_torneo          NUMBER(8)      NOT NULL CONSTRAINT fk_partida_torneo REFERENCES torneo(id_torneo),
    ronda              NUMBER(3)      NOT NULL,
    id_equipo_local    NUMBER(8)      NOT NULL CONSTRAINT fk_partida_local REFERENCES equipo(id_equipo),
    id_equipo_visita   NUMBER(8)      CONSTRAINT fk_partida_visita REFERENCES equipo(id_equipo),
    id_arbitro         NUMBER(6)      CONSTRAINT fk_partida_arbitro REFERENCES arbitro(id_arbitro),
    fecha_hora         DATE           NOT NULL,
    puntaje_local      NUMBER(3),
    puntaje_visita     NUMBER(3),
    id_ganador         NUMBER(8)      CONSTRAINT fk_partida_ganador REFERENCES equipo(id_equipo),
    estado             VARCHAR2(10)   DEFAULT 'PROGRAMADA' NOT NULL,
    observacion        VARCHAR2(200),
    CONSTRAINT ck_partida_estado  CHECK (estado IN ('PROGRAMADA','JUGADA','ANULADA','BYE')),
    CONSTRAINT ck_partida_equipos CHECK (id_equipo_visita IS NULL OR id_equipo_visita <> id_equipo_local),
    CONSTRAINT ck_partida_puntaje CHECK (NVL(puntaje_local,0) >= 0 AND NVL(puntaje_visita,0) >= 0)
);

CREATE TABLE detalle_partida_jugador (
    id_partida  NUMBER(10)  CONSTRAINT fk_dpj_partida REFERENCES partida(id_partida) ON DELETE CASCADE,
    id_jugador  NUMBER(8)   CONSTRAINT fk_dpj_jugador REFERENCES jugador(id_jugador),
    kills       NUMBER(4)   DEFAULT 0 NOT NULL,
    deaths      NUMBER(4)   DEFAULT 0 NOT NULL,
    assists     NUMBER(4)   DEFAULT 0 NOT NULL,
    es_mvp      CHAR(1)     DEFAULT 'N' NOT NULL,
    CONSTRAINT pk_detalle_partida_jugador PRIMARY KEY (id_partida, id_jugador),
    CONSTRAINT ck_dpj_valores CHECK (kills >= 0 AND deaths >= 0 AND assists >= 0),
    CONSTRAINT ck_dpj_mvp CHECK (es_mvp IN ('S','N'))
);

CREATE TABLE sancion (
    id_sancion            NUMBER(8)      CONSTRAINT pk_sancion PRIMARY KEY,
    id_torneo             NUMBER(8)      NOT NULL CONSTRAINT fk_sancion_torneo REFERENCES torneo(id_torneo),
    id_jugador            NUMBER(8)      NOT NULL CONSTRAINT fk_sancion_jugador REFERENCES jugador(id_jugador),
    id_arbitro            NUMBER(6)      NOT NULL CONSTRAINT fk_sancion_arbitro REFERENCES arbitro(id_arbitro),
    tipo                  VARCHAR2(20)   NOT NULL,
    motivo                VARCHAR2(300)  NOT NULL,
    puntos_descuento      NUMBER(3)      DEFAULT 0 NOT NULL,
    fecha_sancion         DATE           DEFAULT SYSDATE NOT NULL,
    fecha_fin_suspension  DATE,
    estado                VARCHAR2(10)   DEFAULT 'VIGENTE' NOT NULL,
    CONSTRAINT ck_sancion_tipo   CHECK (tipo IN ('AMONESTACION','SUSPENSION','DESCUENTO_PUNTOS')),
    CONSTRAINT ck_sancion_estado CHECK (estado IN ('VIGENTE','CUMPLIDA','ANULADA')),
    CONSTRAINT ck_sancion_puntos CHECK (puntos_descuento >= 0)
);

CREATE TABLE premiacion (
    id_premiacion  NUMBER(8)   CONSTRAINT pk_premiacion PRIMARY KEY,
    id_torneo      NUMBER(8)   NOT NULL CONSTRAINT fk_premiacion_torneo REFERENCES torneo(id_torneo),
    id_equipo      NUMBER(8)   NOT NULL CONSTRAINT fk_premiacion_equipo REFERENCES equipo(id_equipo),
    posicion       NUMBER(2)   NOT NULL,
    monto          NUMBER(12)  DEFAULT 0 NOT NULL,
    fecha          DATE        DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_premiacion_posicion UNIQUE (id_torneo, posicion),
    CONSTRAINT uq_premiacion_equipo   UNIQUE (id_torneo, id_equipo)
);

-- ---------- Monitoreo / auditoría (pobladas por triggers y login) ----------
CREATE TABLE auditoria_marcador (
    id_auditoria          NUMBER(10)    CONSTRAINT pk_auditoria_marcador PRIMARY KEY,
    id_partida            NUMBER(10)    NOT NULL,
    operacion             VARCHAR2(10)  NOT NULL,
    puntaje_local_ant     NUMBER(3),
    puntaje_visita_ant    NUMBER(3),
    puntaje_local_nuevo   NUMBER(3),
    puntaje_visita_nuevo  NUMBER(3),
    estado_ant            VARCHAR2(10),
    estado_nuevo          VARCHAR2(10),
    usuario_app           VARCHAR2(64),
    usuario_bd            VARCHAR2(128),
    fecha                 DATE          DEFAULT SYSDATE NOT NULL
);

CREATE TABLE auditoria_general (
    id_auditoria  NUMBER(10)     CONSTRAINT pk_auditoria_general PRIMARY KEY,
    tabla         VARCHAR2(30)   NOT NULL,
    operacion     VARCHAR2(10)   NOT NULL,
    id_registro   NUMBER(10),
    detalle       VARCHAR2(500),
    usuario_app   VARCHAR2(64),
    usuario_bd    VARCHAR2(128),
    fecha         DATE           DEFAULT SYSDATE NOT NULL
);

CREATE TABLE log_acceso (
    id_log      NUMBER(10)     CONSTRAINT pk_log_acceso PRIMARY KEY,
    username    VARCHAR2(30)   NOT NULL,
    id_usuario  NUMBER(10),
    fecha       DATE           DEFAULT SYSDATE NOT NULL,
    resultado   VARCHAR2(10)   NOT NULL,
    ip          VARCHAR2(45),
    CONSTRAINT ck_log_resultado CHECK (resultado IN ('EXITOSO','FALLIDO','BLOQUEADO'))
);

-- Índices de apoyo a FK y consultas de reportes
CREATE INDEX ix_jugador_equipo   ON jugador(id_equipo);
CREATE INDEX ix_torneo_videojuego ON torneo(id_videojuego);
CREATE INDEX ix_torneo_sede      ON torneo(id_sede);
CREATE INDEX ix_insc_equipo      ON inscripcion(id_equipo);
CREATE INDEX ix_roster_jugador   ON roster(id_jugador);
CREATE INDEX ix_partida_torneo   ON partida(id_torneo, ronda);
CREATE INDEX ix_dpj_jugador      ON detalle_partida_jugador(id_jugador);
CREATE INDEX ix_sancion_jugador  ON sancion(id_jugador, estado);

/* ============================================================================
   2. SECUENCIAS (generación correlativa de llaves primarias)
   ============================================================================ */
CREATE SEQUENCE seq_perfil        START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_usuario       START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_videojuego    START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_plataforma    START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_sede          START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_patrocinador  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_categoria     START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_formato       START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_equipo        START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_jugador       START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_arbitro       START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_torneo        START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_inscripcion   START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_partida       START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_sancion       START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_premiacion    START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_auditoria     START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_auditoria_gen START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_log_acceso    START WITH 1 INCREMENT BY 1 NOCACHE;

/* ============================================================================
   3. FUNCIONES (cálculos y validaciones de negocio, prefijo FN_)
   ============================================================================ */

-- Traduce errores Oracle a mensajes legibles para la capa cliente.
CREATE OR REPLACE FUNCTION fn_mensaje_error (p_error IN VARCHAR2) RETURN VARCHAR2 IS
    v_linea VARCHAR2(4000);
BEGIN
    -- Solo la primera línea del error (sin la pila ORA-06512)
    v_linea := REGEXP_SUBSTR(p_error, '^[^' || CHR(10) || ']+');
    IF v_linea LIKE 'ORA-00001%' THEN
        RETURN 'Ya existe un registro con esos datos (valor único duplicado).';
    ELSIF v_linea LIKE 'ORA-02292%' THEN
        RETURN 'No se puede eliminar: existen registros asociados que dependen de este.';
    ELSIF v_linea LIKE 'ORA-02291%' THEN
        RETURN 'Referencia inválida: el registro relacionado no existe.';
    ELSIF v_linea LIKE 'ORA-02290%' THEN
        RETURN 'Valor no permitido por las reglas de la base de datos (' ||
               REGEXP_SUBSTR(v_linea, '\(([^)]+)\)', 1, 1, NULL, 1) || ').';
    ELSIF v_linea LIKE 'ORA-01400%' THEN
        RETURN 'Falta completar un campo obligatorio.';
    ELSIF v_linea LIKE 'ORA-12899%' THEN
        RETURN 'Uno de los valores excede el largo permitido.';
    ELSIF v_linea LIKE 'ORA-01722%' OR v_linea LIKE 'ORA-06502%' THEN
        RETURN 'Formato numérico o de texto inválido.';
    ELSIF v_linea LIKE 'ORA-018%' THEN
        RETURN 'Formato de fecha inválido.';
    ELSIF REGEXP_LIKE(v_linea, '^ORA-20[0-9]{3}: ') THEN
        -- Errores de negocio lanzados con RAISE_APPLICATION_ERROR
        RETURN REGEXP_REPLACE(v_linea, '^ORA-20[0-9]{3}: ', '');
    END IF;
    RETURN v_linea;
END fn_mensaje_error;
/

-- Hash SHA-256 de la contraseña con "sal" (el username), nunca se guarda en texto plano.
CREATE OR REPLACE FUNCTION fn_hash_password (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN VARCHAR2 IS
    v_hash VARCHAR2(64);
BEGIN
    SELECT LOWER(RAWTOHEX(STANDARD_HASH(LOWER(TRIM(p_username)) || ':' || p_password || ':ESPORTS-UCM', 'SHA256')))
      INTO v_hash
      FROM dual;
    RETURN v_hash;
END fn_hash_password;
/

-- Valida un RUT chileno con dígito verificador (módulo 11). Formato aceptado: 12345678-9
CREATE OR REPLACE FUNCTION fn_validar_rut (p_rut IN VARCHAR2) RETURN NUMBER IS
    v_rut     VARCHAR2(20) := UPPER(REPLACE(REPLACE(TRIM(p_rut), '.', ''), ' ', ''));
    v_cuerpo  VARCHAR2(10);
    v_dv      CHAR(1);
    v_suma    NUMBER := 0;
    v_factor  NUMBER := 2;
    v_resto   NUMBER;
    v_dv_calc CHAR(1);
BEGIN
    IF v_rut IS NULL OR NOT REGEXP_LIKE(v_rut, '^[0-9]{7,8}-[0-9K]$') THEN
        RETURN 0;
    END IF;
    v_cuerpo := SUBSTR(v_rut, 1, INSTR(v_rut, '-') - 1);
    v_dv     := SUBSTR(v_rut, -1);
    FOR i IN REVERSE 1 .. LENGTH(v_cuerpo) LOOP
        v_suma   := v_suma + TO_NUMBER(SUBSTR(v_cuerpo, i, 1)) * v_factor;
        v_factor := CASE WHEN v_factor = 7 THEN 2 ELSE v_factor + 1 END;
    END LOOP;
    v_resto := 11 - MOD(v_suma, 11);
    v_dv_calc := CASE v_resto WHEN 11 THEN '0' WHEN 10 THEN 'K' ELSE TO_CHAR(v_resto) END;
    RETURN CASE WHEN v_dv = v_dv_calc THEN 1 ELSE 0 END;
END fn_validar_rut;
/

-- Perfil (código) de un usuario activo; NULL si no existe o no está activo.
CREATE OR REPLACE FUNCTION fn_perfil_usuario (p_id_usuario IN NUMBER) RETURN VARCHAR2 IS
    v_codigo perfil.codigo%TYPE;
BEGIN
    SELECT p.codigo
      INTO v_codigo
      FROM usuario u
      JOIN perfil p ON p.id_perfil = u.id_perfil
     WHERE u.id_usuario = p_id_usuario
       AND u.estado = 'ACTIVO';
    RETURN v_codigo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END fn_perfil_usuario;
/

-- Edad en años cumplidos a una fecha de referencia.
CREATE OR REPLACE FUNCTION fn_calcular_edad (
    p_fecha_nacimiento IN DATE,
    p_fecha_ref        IN DATE DEFAULT SYSDATE
) RETURN NUMBER IS
BEGIN
    RETURN TRUNC(MONTHS_BETWEEN(p_fecha_ref, p_fecha_nacimiento) / 12);
END fn_calcular_edad;
/

-- Cupos disponibles de un torneo (cupo máximo - inscripciones confirmadas).
CREATE OR REPLACE FUNCTION fn_validar_cupos_torneo (p_id_torneo IN NUMBER) RETURN NUMBER IS
    v_cupo     torneo.cupo_maximo%TYPE;
    v_inscritos NUMBER;
BEGIN
    IF p_id_torneo IS NULL THEN
        RETURN NULL;
    END IF;
    SELECT cupo_maximo INTO v_cupo FROM torneo WHERE id_torneo = p_id_torneo;
    SELECT COUNT(*)
      INTO v_inscritos
      FROM inscripcion
     WHERE id_torneo = p_id_torneo
       AND estado = 'CONFIRMADA';
    RETURN v_cupo - v_inscritos;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'El torneo ' || p_id_torneo || ' no existe.');
END fn_validar_cupos_torneo;
/

-- Ratio KDA = (kills + assists) / deaths (si deaths = 0 se usa 1).
CREATE OR REPLACE FUNCTION fn_calcular_ratio_kda (
    p_kills   IN NUMBER,
    p_deaths  IN NUMBER,
    p_assists IN NUMBER
) RETURN NUMBER DETERMINISTIC IS
BEGIN
    RETURN ROUND((NVL(p_kills, 0) + NVL(p_assists, 0)) / GREATEST(NVL(p_deaths, 0), 1), 2);
END fn_calcular_ratio_kda;
/

-- KDA acumulado de un jugador (opcionalmente filtrado por torneo).
CREATE OR REPLACE FUNCTION fn_kda_jugador (
    p_id_jugador IN NUMBER,
    p_id_torneo  IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_k NUMBER; v_d NUMBER; v_a NUMBER;
BEGIN
    SELECT NVL(SUM(d.kills), 0), NVL(SUM(d.deaths), 0), NVL(SUM(d.assists), 0)
      INTO v_k, v_d, v_a
      FROM detalle_partida_jugador d
      JOIN partida p ON p.id_partida = d.id_partida
     WHERE d.id_jugador = p_id_jugador
       AND (p_id_torneo IS NULL OR p.id_torneo = p_id_torneo);
    RETURN fn_calcular_ratio_kda(v_k, v_d, v_a);
END fn_kda_jugador;
/

-- Estado disciplinario real de un jugador: HABILITADO | SANCIONADO | INACTIVO | NO_EXISTE
CREATE OR REPLACE FUNCTION fn_verificar_estado_jugador (p_id_jugador IN NUMBER) RETURN VARCHAR2 IS
    v_estado     jugador.estado%TYPE;
    v_suspension NUMBER;
BEGIN
    SELECT estado INTO v_estado FROM jugador WHERE id_jugador = p_id_jugador;
    IF v_estado = 'INACTIVO' THEN
        RETURN 'INACTIVO';
    END IF;
    SELECT COUNT(*)
      INTO v_suspension
      FROM sancion
     WHERE id_jugador = p_id_jugador
       AND tipo = 'SUSPENSION'
       AND estado = 'VIGENTE'
       AND fecha_fin_suspension >= TRUNC(SYSDATE);
    IF v_suspension > 0 THEN
        RETURN 'SANCIONADO';
    END IF;
    RETURN 'HABILITADO';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'NO_EXISTE';
END fn_verificar_estado_jugador;
/

-- Puntos que otorga un resultado al equipo indicado según el formato del torneo.
CREATE OR REPLACE FUNCTION fn_puntos_resultado (
    p_id_torneo   IN NUMBER,
    p_id_equipo   IN NUMBER,
    p_id_ganador  IN NUMBER,
    p_es_empate   IN CHAR
) RETURN NUMBER IS
    v_victoria formato_torneo.puntos_victoria%TYPE;
    v_empate   formato_torneo.puntos_empate%TYPE;
BEGIN
    SELECT f.puntos_victoria, f.puntos_empate
      INTO v_victoria, v_empate
      FROM torneo t
      JOIN formato_torneo f ON f.id_formato = t.id_formato
     WHERE t.id_torneo = p_id_torneo;
    IF p_es_empate = 'S' THEN
        RETURN v_empate;
    ELSIF p_id_ganador = p_id_equipo THEN
        RETURN v_victoria;
    END IF;
    RETURN 0;
END fn_puntos_resultado;
/

-- Recaudación por inscripciones de un torneo.
CREATE OR REPLACE FUNCTION fn_recaudacion_torneo (p_id_torneo IN NUMBER) RETURN NUMBER IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(monto_pagado), 0)
      INTO v_total
      FROM inscripcion
     WHERE id_torneo = p_id_torneo
       AND estado = 'CONFIRMADA';
    RETURN v_total;
END fn_recaudacion_torneo;
/

-- Aporte total de patrocinadores a un torneo.
CREATE OR REPLACE FUNCTION fn_aporte_patrocinio (p_id_torneo IN NUMBER) RETURN NUMBER IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(monto_aporte), 0)
      INTO v_total
      FROM torneo_patrocinador
     WHERE id_torneo = p_id_torneo;
    RETURN v_total;
END fn_aporte_patrocinio;
/

-- Usuario de la aplicación que ejecuta la operación (lo fija PHP con oci_set_client_identifier).
CREATE OR REPLACE FUNCTION fn_usuario_app RETURN VARCHAR2 IS
BEGIN
    RETURN NVL(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), USER);
END fn_usuario_app;
/

-- Formato monetario chileno independiente de la configuración NLS de la sesión ($1.250.000)
CREATE OR REPLACE FUNCTION fn_formato_monto (p_monto IN NUMBER) RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
    RETURN '$' || TO_CHAR(NVL(p_monto, 0), 'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''');
END fn_formato_monto;
/

/* ============================================================================
   4. CONTROL DE ACCESO
   Convención de todos los procedimientos de escritura:
     p_resultado OUT -> 1 = éxito, 0 = error
     p_mensaje   OUT -> mensaje para mostrar en la aplicación
   ============================================================================ */

-- Lanza error si el usuario no tiene uno de los perfiles permitidos (lista separada por comas).
CREATE OR REPLACE PROCEDURE sp_validar_permiso (
    p_id_usuario IN NUMBER,
    p_perfiles   IN VARCHAR2
) IS
    v_perfil perfil.codigo%TYPE;
BEGIN
    v_perfil := fn_perfil_usuario(p_id_usuario);
    IF v_perfil IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Sesión inválida o usuario inactivo.');
    END IF;
    IF INSTR(',' || p_perfiles || ',', ',' || v_perfil || ',') = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Su perfil (' || v_perfil || ') no tiene permiso para esta operación.');
    END IF;
END sp_validar_permiso;
/

-- Autenticación: valida credenciales, bloquea tras 5 intentos fallidos y registra LOG_ACCESO.
CREATE OR REPLACE PROCEDURE sp_login (
    p_username    IN  VARCHAR2,
    p_password    IN  VARCHAR2,
    p_ip          IN  VARCHAR2,
    p_id_usuario  OUT NUMBER,
    p_nombre      OUT VARCHAR2,
    p_perfil      OUT VARCHAR2,
    p_id_equipo   OUT NUMBER,
    p_resultado   OUT NUMBER,
    p_mensaje     OUT VARCHAR2
) IS
    CURSOR cur_usuario IS
        SELECT u.id_usuario, u.username, u.password_hash, u.nombre_completo,
               u.estado, u.intentos_fallidos, p.codigo
          FROM usuario u
          JOIN perfil p ON p.id_perfil = u.id_perfil
         WHERE LOWER(u.username) = LOWER(TRIM(p_username))
           FOR UPDATE OF u.intentos_fallidos;
    v_usr cur_usuario%ROWTYPE;
    c_max_intentos CONSTANT NUMBER := 5;
BEGIN
    p_resultado := 0;
    OPEN cur_usuario;
    FETCH cur_usuario INTO v_usr;
    IF cur_usuario%NOTFOUND THEN
        CLOSE cur_usuario;
        INSERT INTO log_acceso (id_log, username, id_usuario, resultado, ip)
        VALUES (seq_log_acceso.NEXTVAL, SUBSTR(NVL(p_username, '?'), 1, 30), NULL, 'FALLIDO', p_ip);
        COMMIT;
        p_mensaje := 'Usuario o contraseña incorrectos.';
        RETURN;
    END IF;

    IF v_usr.estado <> 'ACTIVO' THEN
        CLOSE cur_usuario;
        INSERT INTO log_acceso (id_log, username, id_usuario, resultado, ip)
        VALUES (seq_log_acceso.NEXTVAL, v_usr.username, v_usr.id_usuario, 'BLOQUEADO', p_ip);
        COMMIT;
        p_mensaje := 'La cuenta está ' || LOWER(v_usr.estado) || '. Contacte al administrador.';
        RETURN;
    END IF;

    IF v_usr.password_hash <> fn_hash_password(v_usr.username, p_password) THEN
        UPDATE usuario
           SET intentos_fallidos = intentos_fallidos + 1,
               estado = CASE WHEN intentos_fallidos + 1 >= c_max_intentos THEN 'BLOQUEADO' ELSE estado END
         WHERE CURRENT OF cur_usuario;
        CLOSE cur_usuario;
        INSERT INTO log_acceso (id_log, username, id_usuario, resultado, ip)
        VALUES (seq_log_acceso.NEXTVAL, v_usr.username, v_usr.id_usuario, 'FALLIDO', p_ip);
        COMMIT;
        IF v_usr.intentos_fallidos + 1 >= c_max_intentos THEN
            p_mensaje := 'Cuenta bloqueada por superar ' || c_max_intentos || ' intentos fallidos.';
        ELSE
            p_mensaje := 'Usuario o contraseña incorrectos. Intentos restantes: ' ||
                         (c_max_intentos - v_usr.intentos_fallidos - 1) || '.';
        END IF;
        RETURN;
    END IF;

    UPDATE usuario
       SET intentos_fallidos = 0,
           ultimo_acceso = SYSDATE
     WHERE CURRENT OF cur_usuario;
    CLOSE cur_usuario;

    INSERT INTO log_acceso (id_log, username, id_usuario, resultado, ip)
    VALUES (seq_log_acceso.NEXTVAL, v_usr.username, v_usr.id_usuario, 'EXITOSO', p_ip);

    BEGIN
        SELECT id_equipo INTO p_id_equipo FROM equipo WHERE id_capitan = v_usr.id_usuario;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN p_id_equipo := NULL;
    END;

    COMMIT;
    p_id_usuario := v_usr.id_usuario;
    p_nombre     := v_usr.nombre_completo;
    p_perfil     := v_usr.codigo;
    p_resultado  := 1;
    p_mensaje    := 'Bienvenido, ' || v_usr.nombre_completo || '.';
EXCEPTION
    WHEN OTHERS THEN
        IF cur_usuario%ISOPEN THEN CLOSE cur_usuario; END IF;
        ROLLBACK;
        p_resultado := 0;
        p_mensaje := fn_mensaje_error(SQLERRM);
END sp_login;
/

-- Registro de auditoría de accesos (para el administrador)
CREATE OR REPLACE PROCEDURE sp_log_acceso_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT id_log, username, TO_CHAR(fecha, 'YYYY-MM-DD HH24:MI:SS') AS fecha, resultado, ip
          FROM log_acceso
         ORDER BY id_log DESC
         FETCH FIRST 200 ROWS ONLY;
END sp_log_acceso_listar;
/

CREATE OR REPLACE PROCEDURE sp_auditoria_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
      SELECT * FROM (
        SELECT 'MARCADOR' AS tabla, operacion, id_partida AS id_registro,
               'Partida ' || id_partida || ': ' || NVL(TO_CHAR(puntaje_local_ant), '-') || '-' ||
               NVL(TO_CHAR(puntaje_visita_ant), '-') || ' (' || estado_ant || ') -> ' ||
               NVL(TO_CHAR(puntaje_local_nuevo), '-') || '-' || NVL(TO_CHAR(puntaje_visita_nuevo), '-') ||
               ' (' || estado_nuevo || ')' AS detalle,
               usuario_app, fecha AS fecha_orden, TO_CHAR(fecha, 'YYYY-MM-DD HH24:MI:SS') AS fecha
          FROM auditoria_marcador
        UNION ALL
        SELECT tabla, operacion, id_registro, detalle, usuario_app, fecha,
               TO_CHAR(fecha, 'YYYY-MM-DD HH24:MI:SS')
          FROM auditoria_general
      )
      ORDER BY fecha_orden DESC
      FETCH FIRST 300 ROWS ONLY;
END sp_auditoria_listar;
/

/* ============================================================================
   5. MANTENEDORES (CRUD) - 10 en total
   Cada uno: SP_<ENTIDAD>_LISTAR (cursor), _INSERTAR (secuencia), _ACTUALIZAR, _ELIMINAR
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- MANTENEDOR 1: USUARIOS Y PERFILES
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_perfil_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT id_perfil, codigo, nombre, descripcion FROM perfil ORDER BY id_perfil;
END sp_perfil_listar;
/

CREATE OR REPLACE PROCEDURE sp_usuario_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT u.id_usuario, u.username, u.nombre_completo, u.email, u.id_perfil,
               p.nombre AS perfil, p.codigo AS codigo_perfil, u.estado, u.intentos_fallidos,
               TO_CHAR(u.fecha_creacion, 'YYYY-MM-DD') AS fecha_creacion,
               TO_CHAR(u.ultimo_acceso, 'YYYY-MM-DD HH24:MI') AS ultimo_acceso
          FROM usuario u
          JOIN perfil p ON p.id_perfil = u.id_perfil
         ORDER BY u.id_usuario;
END sp_usuario_listar;
/

CREATE OR REPLACE PROCEDURE sp_usuario_insertar (
    p_id_sesion       IN  NUMBER,
    p_username        IN  VARCHAR2,
    p_password        IN  VARCHAR2,
    p_nombre_completo IN  VARCHAR2,
    p_email           IN  VARCHAR2,
    p_id_perfil       IN  NUMBER,
    p_estado          IN  VARCHAR2,
    p_id              OUT NUMBER,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN');
    IF NOT REGEXP_LIKE(TRIM(p_username), '^[A-Za-z0-9_.]{4,30}$') THEN
        RAISE_APPLICATION_ERROR(-20010, 'El usuario debe tener 4 a 30 caracteres (letras, números, punto o guion bajo).');
    END IF;
    IF p_password IS NULL OR LENGTH(p_password) < 8 THEN
        RAISE_APPLICATION_ERROR(-20011, 'La contraseña debe tener al menos 8 caracteres.');
    END IF;
    p_id := seq_usuario.NEXTVAL;
    INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado)
    VALUES (p_id, LOWER(TRIM(p_username)), fn_hash_password(p_username, p_password),
            TRIM(p_nombre_completo), LOWER(TRIM(p_email)), p_id_perfil, NVL(p_estado, 'ACTIVO'));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Usuario "' || LOWER(TRIM(p_username)) || '" creado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_usuario_insertar;
/

CREATE OR REPLACE PROCEDURE sp_usuario_actualizar (
    p_id_sesion       IN  NUMBER,
    p_id_usuario      IN  NUMBER,
    p_password        IN  VARCHAR2,   -- NULL = mantener la actual
    p_nombre_completo IN  VARCHAR2,
    p_email           IN  VARCHAR2,
    p_id_perfil       IN  NUMBER,
    p_estado          IN  VARCHAR2,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) IS
    v_username      usuario.username%TYPE;
    v_perfil_actual usuario.id_perfil%TYPE;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN');
    SELECT username, id_perfil INTO v_username, v_perfil_actual
      FROM usuario WHERE id_usuario = p_id_usuario FOR UPDATE;
    IF p_id_usuario = p_id_sesion AND (p_estado <> 'ACTIVO' OR p_id_perfil <> v_perfil_actual) THEN
        RAISE_APPLICATION_ERROR(-20012, 'No puede cambiar su propio perfil ni desactivar su propia cuenta.');
    END IF;
    IF p_password IS NOT NULL AND LENGTH(p_password) < 8 THEN
        RAISE_APPLICATION_ERROR(-20011, 'La contraseña debe tener al menos 8 caracteres.');
    END IF;
    UPDATE usuario
       SET nombre_completo   = TRIM(p_nombre_completo),
           email             = LOWER(TRIM(p_email)),
           id_perfil         = p_id_perfil,
           estado            = p_estado,
           intentos_fallidos = CASE WHEN p_estado = 'ACTIVO' THEN 0 ELSE intentos_fallidos END,
           password_hash     = CASE WHEN p_password IS NULL THEN password_hash
                                    ELSE fn_hash_password(v_username, p_password) END
     WHERE id_usuario = p_id_usuario;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Usuario actualizado correctamente.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK; p_resultado := 0; p_mensaje := 'El usuario no existe.';
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_usuario_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_usuario_eliminar (
    p_id_sesion  IN  NUMBER,
    p_id_usuario IN  NUMBER,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN');
    IF p_id_usuario = p_id_sesion THEN
        RAISE_APPLICATION_ERROR(-20013, 'No puede eliminar su propia cuenta.');
    END IF;
    DELETE FROM usuario WHERE id_usuario = p_id_usuario;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El usuario no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Usuario eliminado.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_usuario_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 2: VIDEOJUEGOS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_videojuego_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT v.id_videojuego, v.nombre, v.genero, v.desarrolladora, v.jugadores_por_equipo, v.estado,
               (SELECT COUNT(*) FROM torneo t WHERE t.id_videojuego = v.id_videojuego) AS torneos
          FROM videojuego v
         ORDER BY v.nombre;
END sp_videojuego_listar;
/

CREATE OR REPLACE PROCEDURE sp_videojuego_insertar (
    p_id_sesion            IN  NUMBER,
    p_nombre               IN  VARCHAR2,
    p_genero               IN  VARCHAR2,
    p_desarrolladora       IN  VARCHAR2,
    p_jugadores_por_equipo IN  NUMBER,
    p_estado               IN  VARCHAR2,
    p_id                   OUT NUMBER,
    p_resultado            OUT NUMBER,
    p_mensaje              OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    p_id := seq_videojuego.NEXTVAL;
    INSERT INTO videojuego (id_videojuego, nombre, genero, desarrolladora, jugadores_por_equipo, estado)
    VALUES (p_id, TRIM(p_nombre), TRIM(p_genero), TRIM(p_desarrolladora), p_jugadores_por_equipo, NVL(p_estado, 'ACTIVO'));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Videojuego registrado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_videojuego_insertar;
/

CREATE OR REPLACE PROCEDURE sp_videojuego_actualizar (
    p_id_sesion            IN  NUMBER,
    p_id_videojuego        IN  NUMBER,
    p_nombre               IN  VARCHAR2,
    p_genero               IN  VARCHAR2,
    p_desarrolladora       IN  VARCHAR2,
    p_jugadores_por_equipo IN  NUMBER,
    p_estado               IN  VARCHAR2,
    p_resultado            OUT NUMBER,
    p_mensaje              OUT VARCHAR2
) IS
    v_activos NUMBER;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    -- No se puede cambiar el tamaño de equipo si hay torneos abiertos o en curso de ese juego
    SELECT COUNT(*) INTO v_activos
      FROM torneo t JOIN videojuego v ON v.id_videojuego = t.id_videojuego
     WHERE t.id_videojuego = p_id_videojuego
       AND t.estado IN ('ABIERTO','EN_CURSO')
       AND v.jugadores_por_equipo <> p_jugadores_por_equipo;
    IF v_activos > 0 THEN
        RAISE_APPLICATION_ERROR(-20014, 'No se puede cambiar jugadores por equipo: hay torneos abiertos o en curso de este juego.');
    END IF;
    UPDATE videojuego
       SET nombre = TRIM(p_nombre), genero = TRIM(p_genero), desarrolladora = TRIM(p_desarrolladora),
           jugadores_por_equipo = p_jugadores_por_equipo, estado = p_estado
     WHERE id_videojuego = p_id_videojuego;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El videojuego no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Videojuego actualizado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_videojuego_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_videojuego_eliminar (
    p_id_sesion     IN  NUMBER,
    p_id_videojuego IN  NUMBER,
    p_resultado     OUT NUMBER,
    p_mensaje       OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    DELETE FROM videojuego WHERE id_videojuego = p_id_videojuego;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El videojuego no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Videojuego eliminado.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_videojuego_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 3: PLATAFORMAS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_plataforma_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT id_plataforma, nombre, fabricante, descripcion FROM plataforma ORDER BY nombre;
END sp_plataforma_listar;
/

CREATE OR REPLACE PROCEDURE sp_plataforma_insertar (
    p_id_sesion   IN  NUMBER,
    p_nombre      IN  VARCHAR2,
    p_fabricante  IN  VARCHAR2,
    p_descripcion IN  VARCHAR2,
    p_id          OUT NUMBER,
    p_resultado   OUT NUMBER,
    p_mensaje     OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    p_id := seq_plataforma.NEXTVAL;
    INSERT INTO plataforma (id_plataforma, nombre, fabricante, descripcion)
    VALUES (p_id, TRIM(p_nombre), TRIM(p_fabricante), TRIM(p_descripcion));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Plataforma registrada correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_plataforma_insertar;
/

CREATE OR REPLACE PROCEDURE sp_plataforma_actualizar (
    p_id_sesion     IN  NUMBER,
    p_id_plataforma IN  NUMBER,
    p_nombre        IN  VARCHAR2,
    p_fabricante    IN  VARCHAR2,
    p_descripcion   IN  VARCHAR2,
    p_resultado     OUT NUMBER,
    p_mensaje       OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    UPDATE plataforma
       SET nombre = TRIM(p_nombre), fabricante = TRIM(p_fabricante), descripcion = TRIM(p_descripcion)
     WHERE id_plataforma = p_id_plataforma;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'La plataforma no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Plataforma actualizada correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_plataforma_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_plataforma_eliminar (
    p_id_sesion     IN  NUMBER,
    p_id_plataforma IN  NUMBER,
    p_resultado     OUT NUMBER,
    p_mensaje       OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    DELETE FROM plataforma WHERE id_plataforma = p_id_plataforma;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'La plataforma no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Plataforma eliminada.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_plataforma_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 4: SEDES / MODALIDADES
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_sede_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT id_sede, nombre, direccion, comuna, capacidad, modalidad, estado FROM sede ORDER BY nombre;
END sp_sede_listar;
/

CREATE OR REPLACE PROCEDURE sp_sede_insertar (
    p_id_sesion IN  NUMBER,
    p_nombre    IN  VARCHAR2,
    p_direccion IN  VARCHAR2,
    p_comuna    IN  VARCHAR2,
    p_capacidad IN  NUMBER,
    p_modalidad IN  VARCHAR2,
    p_estado    IN  VARCHAR2,
    p_id        OUT NUMBER,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    p_id := seq_sede.NEXTVAL;
    INSERT INTO sede (id_sede, nombre, direccion, comuna, capacidad, modalidad, estado)
    VALUES (p_id, TRIM(p_nombre), TRIM(p_direccion), TRIM(p_comuna), p_capacidad, p_modalidad, NVL(p_estado, 'ACTIVO'));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Sede registrada correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_sede_insertar;
/

CREATE OR REPLACE PROCEDURE sp_sede_actualizar (
    p_id_sesion IN  NUMBER,
    p_id_sede   IN  NUMBER,
    p_nombre    IN  VARCHAR2,
    p_direccion IN  VARCHAR2,
    p_comuna    IN  VARCHAR2,
    p_capacidad IN  NUMBER,
    p_modalidad IN  VARCHAR2,
    p_estado    IN  VARCHAR2,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    UPDATE sede
       SET nombre = TRIM(p_nombre), direccion = TRIM(p_direccion), comuna = TRIM(p_comuna),
           capacidad = p_capacidad, modalidad = p_modalidad, estado = p_estado
     WHERE id_sede = p_id_sede;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'La sede no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Sede actualizada correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_sede_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_sede_eliminar (
    p_id_sesion IN  NUMBER,
    p_id_sede   IN  NUMBER,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    DELETE FROM sede WHERE id_sede = p_id_sede;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'La sede no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Sede eliminada.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_sede_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 5: PATROCINADORES
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_patrocinador_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT p.id_patrocinador, p.rut, p.razon_social, p.rubro, p.email_contacto, p.telefono,
               (SELECT NVL(SUM(tp.monto_aporte), 0) FROM torneo_patrocinador tp
                 WHERE tp.id_patrocinador = p.id_patrocinador) AS total_aportado
          FROM patrocinador p
         ORDER BY p.razon_social;
END sp_patrocinador_listar;
/

CREATE OR REPLACE PROCEDURE sp_patrocinador_insertar (
    p_id_sesion      IN  NUMBER,
    p_rut            IN  VARCHAR2,
    p_razon_social   IN  VARCHAR2,
    p_rubro          IN  VARCHAR2,
    p_email_contacto IN  VARCHAR2,
    p_telefono       IN  VARCHAR2,
    p_id             OUT NUMBER,
    p_resultado      OUT NUMBER,
    p_mensaje        OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    IF fn_validar_rut(p_rut) = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'RUT inválido. Use el formato 12345678-9 con dígito verificador correcto.');
    END IF;
    p_id := seq_patrocinador.NEXTVAL;
    INSERT INTO patrocinador (id_patrocinador, rut, razon_social, rubro, email_contacto, telefono)
    VALUES (p_id, UPPER(REPLACE(TRIM(p_rut), '.', '')), TRIM(p_razon_social), TRIM(p_rubro),
            LOWER(TRIM(p_email_contacto)), TRIM(p_telefono));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Patrocinador registrado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_patrocinador_insertar;
/

CREATE OR REPLACE PROCEDURE sp_patrocinador_actualizar (
    p_id_sesion       IN  NUMBER,
    p_id_patrocinador IN  NUMBER,
    p_rut             IN  VARCHAR2,
    p_razon_social    IN  VARCHAR2,
    p_rubro           IN  VARCHAR2,
    p_email_contacto  IN  VARCHAR2,
    p_telefono        IN  VARCHAR2,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    IF fn_validar_rut(p_rut) = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'RUT inválido. Use el formato 12345678-9 con dígito verificador correcto.');
    END IF;
    UPDATE patrocinador
       SET rut = UPPER(REPLACE(TRIM(p_rut), '.', '')), razon_social = TRIM(p_razon_social),
           rubro = TRIM(p_rubro), email_contacto = LOWER(TRIM(p_email_contacto)), telefono = TRIM(p_telefono)
     WHERE id_patrocinador = p_id_patrocinador;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El patrocinador no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Patrocinador actualizado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_patrocinador_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_patrocinador_eliminar (
    p_id_sesion       IN  NUMBER,
    p_id_patrocinador IN  NUMBER,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    DELETE FROM patrocinador WHERE id_patrocinador = p_id_patrocinador;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El patrocinador no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Patrocinador eliminado.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_patrocinador_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 6: CATEGORÍAS / DIVISIONES
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_categoria_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT id_categoria, nombre, descripcion, edad_minima, edad_maxima FROM categoria ORDER BY nombre;
END sp_categoria_listar;
/

CREATE OR REPLACE PROCEDURE sp_categoria_insertar (
    p_id_sesion   IN  NUMBER,
    p_nombre      IN  VARCHAR2,
    p_descripcion IN  VARCHAR2,
    p_edad_minima IN  NUMBER,
    p_edad_maxima IN  NUMBER,
    p_id          OUT NUMBER,
    p_resultado   OUT NUMBER,
    p_mensaje     OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    p_id := seq_categoria.NEXTVAL;
    INSERT INTO categoria (id_categoria, nombre, descripcion, edad_minima, edad_maxima)
    VALUES (p_id, TRIM(p_nombre), TRIM(p_descripcion), NVL(p_edad_minima, 0), p_edad_maxima);
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Categoría registrada correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_categoria_insertar;
/

CREATE OR REPLACE PROCEDURE sp_categoria_actualizar (
    p_id_sesion    IN  NUMBER,
    p_id_categoria IN  NUMBER,
    p_nombre       IN  VARCHAR2,
    p_descripcion  IN  VARCHAR2,
    p_edad_minima  IN  NUMBER,
    p_edad_maxima  IN  NUMBER,
    p_resultado    OUT NUMBER,
    p_mensaje      OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    UPDATE categoria
       SET nombre = TRIM(p_nombre), descripcion = TRIM(p_descripcion),
           edad_minima = NVL(p_edad_minima, 0), edad_maxima = p_edad_maxima
     WHERE id_categoria = p_id_categoria;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'La categoría no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Categoría actualizada correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_categoria_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_categoria_eliminar (
    p_id_sesion    IN  NUMBER,
    p_id_categoria IN  NUMBER,
    p_resultado    OUT NUMBER,
    p_mensaje      OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    DELETE FROM categoria WHERE id_categoria = p_id_categoria;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'La categoría no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Categoría eliminada.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_categoria_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 7: FORMATOS DE TORNEO
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_formato_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT id_formato, nombre, tipo, puntos_victoria, puntos_empate, descripcion
          FROM formato_torneo ORDER BY nombre;
END sp_formato_listar;
/

CREATE OR REPLACE PROCEDURE sp_formato_insertar (
    p_id_sesion       IN  NUMBER,
    p_nombre          IN  VARCHAR2,
    p_tipo            IN  VARCHAR2,
    p_puntos_victoria IN  NUMBER,
    p_puntos_empate   IN  NUMBER,
    p_descripcion     IN  VARCHAR2,
    p_id              OUT NUMBER,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    p_id := seq_formato.NEXTVAL;
    INSERT INTO formato_torneo (id_formato, nombre, tipo, puntos_victoria, puntos_empate, descripcion)
    VALUES (p_id, TRIM(p_nombre), p_tipo, NVL(p_puntos_victoria, 3), NVL(p_puntos_empate, 1), TRIM(p_descripcion));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Formato registrado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_formato_insertar;
/

CREATE OR REPLACE PROCEDURE sp_formato_actualizar (
    p_id_sesion       IN  NUMBER,
    p_id_formato      IN  NUMBER,
    p_nombre          IN  VARCHAR2,
    p_tipo            IN  VARCHAR2,
    p_puntos_victoria IN  NUMBER,
    p_puntos_empate   IN  NUMBER,
    p_descripcion     IN  VARCHAR2,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) IS
    v_en_uso NUMBER;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    -- Las reglas de puntaje no cambian mientras haya torneos en curso con este formato
    SELECT COUNT(*) INTO v_en_uso
      FROM torneo
     WHERE id_formato = p_id_formato AND estado = 'EN_CURSO';
    IF v_en_uso > 0 THEN
        RAISE_APPLICATION_ERROR(-20015, 'El formato está siendo usado por torneos en curso; no se puede modificar.');
    END IF;
    UPDATE formato_torneo
       SET nombre = TRIM(p_nombre), tipo = p_tipo, puntos_victoria = p_puntos_victoria,
           puntos_empate = p_puntos_empate, descripcion = TRIM(p_descripcion)
     WHERE id_formato = p_id_formato;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El formato no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Formato actualizado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_formato_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_formato_eliminar (
    p_id_sesion  IN  NUMBER,
    p_id_formato IN  NUMBER,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    DELETE FROM formato_torneo WHERE id_formato = p_id_formato;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El formato no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Formato eliminado.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_formato_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 8: EQUIPOS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_equipo_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT e.id_equipo, e.nombre, e.tag, e.ciudad,
               TO_CHAR(e.fecha_fundacion, 'YYYY-MM-DD') AS fecha_fundacion,
               e.id_capitan, u.nombre_completo AS capitan, e.estado,
               (SELECT COUNT(*) FROM jugador j WHERE j.id_equipo = e.id_equipo) AS jugadores,
               (SELECT COUNT(*) FROM inscripcion i WHERE i.id_equipo = e.id_equipo AND i.estado = 'CONFIRMADA') AS torneos
          FROM equipo e
          LEFT JOIN usuario u ON u.id_usuario = e.id_capitan
         ORDER BY e.nombre;
END sp_equipo_listar;
/

-- Valida que el capitán asignado tenga perfil CAPITAN
CREATE OR REPLACE PROCEDURE sp_validar_capitan (p_id_capitan IN NUMBER) IS
    v_perfil perfil.codigo%TYPE;
BEGIN
    IF p_id_capitan IS NOT NULL THEN
        v_perfil := fn_perfil_usuario(p_id_capitan);
        IF v_perfil IS NULL OR v_perfil <> 'CAPITAN' THEN
            RAISE_APPLICATION_ERROR(-20021, 'El capitán asignado debe ser un usuario activo con perfil Capitán de Equipo.');
        END IF;
    END IF;
END sp_validar_capitan;
/

CREATE OR REPLACE PROCEDURE sp_equipo_insertar (
    p_id_sesion       IN  NUMBER,
    p_nombre          IN  VARCHAR2,
    p_tag             IN  VARCHAR2,
    p_ciudad          IN  VARCHAR2,
    p_fecha_fundacion IN  DATE,
    p_id_capitan      IN  NUMBER,
    p_estado          IN  VARCHAR2,
    p_id              OUT NUMBER,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    sp_validar_capitan(p_id_capitan);
    p_id := seq_equipo.NEXTVAL;
    INSERT INTO equipo (id_equipo, nombre, tag, ciudad, fecha_fundacion, id_capitan, estado)
    VALUES (p_id, TRIM(p_nombre), UPPER(TRIM(p_tag)), TRIM(p_ciudad), p_fecha_fundacion, p_id_capitan, NVL(p_estado, 'ACTIVO'));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Equipo registrado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_equipo_insertar;
/

CREATE OR REPLACE PROCEDURE sp_equipo_actualizar (
    p_id_sesion       IN  NUMBER,
    p_id_equipo       IN  NUMBER,
    p_nombre          IN  VARCHAR2,
    p_tag             IN  VARCHAR2,
    p_ciudad          IN  VARCHAR2,
    p_fecha_fundacion IN  DATE,
    p_id_capitan      IN  NUMBER,
    p_estado          IN  VARCHAR2,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    sp_validar_capitan(p_id_capitan);
    UPDATE equipo
       SET nombre = TRIM(p_nombre), tag = UPPER(TRIM(p_tag)), ciudad = TRIM(p_ciudad),
           fecha_fundacion = p_fecha_fundacion, id_capitan = p_id_capitan, estado = p_estado
     WHERE id_equipo = p_id_equipo;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El equipo no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Equipo actualizado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_equipo_actualizar;
/

-- Al eliminar un equipo se liberan sus jugadores (cursor explícito) y luego se borra.
-- Si tiene inscripciones en torneos, la FK impide el borrado y se revierte todo.
CREATE OR REPLACE PROCEDURE sp_equipo_eliminar (
    p_id_sesion IN  NUMBER,
    p_id_equipo IN  NUMBER,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
    CURSOR cur_jugadores IS
        SELECT id_jugador FROM jugador WHERE id_equipo = p_id_equipo FOR UPDATE OF id_equipo;
    v_id_jugador jugador.id_jugador%TYPE;
    v_liberados  NUMBER := 0;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    OPEN cur_jugadores;
    LOOP
        FETCH cur_jugadores INTO v_id_jugador;
        EXIT WHEN cur_jugadores%NOTFOUND;
        UPDATE jugador SET id_equipo = NULL WHERE CURRENT OF cur_jugadores;
        v_liberados := v_liberados + 1;
    END LOOP;
    CLOSE cur_jugadores;
    DELETE FROM equipo WHERE id_equipo = p_id_equipo;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El equipo no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Equipo eliminado. Jugadores liberados: ' || v_liberados || '.';
EXCEPTION
    WHEN OTHERS THEN
        IF cur_jugadores%ISOPEN THEN CLOSE cur_jugadores; END IF;
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_equipo_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 9: JUGADORES  (el capitán solo administra jugadores de su equipo)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_jugador_listar (
    p_id_equipo IN  NUMBER,          -- NULL = todos
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT j.id_jugador, j.rut, j.nombres, j.apellidos, j.nickname,
               TO_CHAR(j.fecha_nacimiento, 'YYYY-MM-DD') AS fecha_nacimiento,
               fn_calcular_edad(j.fecha_nacimiento) AS edad,
               j.email, j.id_equipo, e.nombre AS equipo, j.rol_juego, j.estado,
               fn_verificar_estado_jugador(j.id_jugador) AS estado_disciplinario,
               fn_kda_jugador(j.id_jugador) AS kda
          FROM jugador j
          LEFT JOIN equipo e ON e.id_equipo = j.id_equipo
         WHERE p_id_equipo IS NULL OR j.id_equipo = p_id_equipo
         ORDER BY e.nombre NULLS LAST, j.nickname;
END sp_jugador_listar;
/

-- Si quien opera es CAPITAN, el jugador debe pertenecer (o quedar) en su propio equipo
CREATE OR REPLACE PROCEDURE sp_validar_equipo_capitan (
    p_id_sesion IN NUMBER,
    p_id_equipo IN NUMBER
) IS
    v_equipo_capitan equipo.id_equipo%TYPE;
BEGIN
    IF fn_perfil_usuario(p_id_sesion) = 'CAPITAN' THEN
        BEGIN
            SELECT id_equipo INTO v_equipo_capitan FROM equipo WHERE id_capitan = p_id_sesion;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20022, 'Su usuario no tiene un equipo asignado como capitán.');
        END;
        IF p_id_equipo IS NULL OR p_id_equipo <> v_equipo_capitan THEN
            RAISE_APPLICATION_ERROR(-20023, 'Como capitán solo puede administrar jugadores de su propio equipo.');
        END IF;
    END IF;
END sp_validar_equipo_capitan;
/

CREATE OR REPLACE PROCEDURE sp_jugador_insertar (
    p_id_sesion        IN  NUMBER,
    p_rut              IN  VARCHAR2,
    p_nombres          IN  VARCHAR2,
    p_apellidos        IN  VARCHAR2,
    p_nickname         IN  VARCHAR2,
    p_fecha_nacimiento IN  DATE,
    p_email            IN  VARCHAR2,
    p_id_equipo        IN  NUMBER,
    p_rol_juego        IN  VARCHAR2,
    p_estado           IN  VARCHAR2,
    p_id               OUT NUMBER,
    p_resultado        OUT NUMBER,
    p_mensaje          OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR,CAPITAN');
    sp_validar_equipo_capitan(p_id_sesion, p_id_equipo);
    p_id := seq_jugador.NEXTVAL;
    -- Validaciones de RUT, edad y normalización: trigger TRG_VALIDAR_JUGADOR
    INSERT INTO jugador (id_jugador, rut, nombres, apellidos, nickname, fecha_nacimiento,
                         email, id_equipo, rol_juego, estado)
    VALUES (p_id, p_rut, p_nombres, p_apellidos, p_nickname, p_fecha_nacimiento,
            p_email, p_id_equipo, p_rol_juego, NVL(p_estado, 'ACTIVO'));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Jugador registrado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_jugador_insertar;
/

CREATE OR REPLACE PROCEDURE sp_jugador_actualizar (
    p_id_sesion        IN  NUMBER,
    p_id_jugador       IN  NUMBER,
    p_rut              IN  VARCHAR2,
    p_nombres          IN  VARCHAR2,
    p_apellidos        IN  VARCHAR2,
    p_nickname         IN  VARCHAR2,
    p_fecha_nacimiento IN  DATE,
    p_email            IN  VARCHAR2,
    p_id_equipo        IN  NUMBER,
    p_rol_juego        IN  VARCHAR2,
    p_estado           IN  VARCHAR2,
    p_resultado        OUT NUMBER,
    p_mensaje          OUT VARCHAR2
) IS
    v_equipo_actual jugador.id_equipo%TYPE;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR,CAPITAN');
    SELECT id_equipo INTO v_equipo_actual FROM jugador WHERE id_jugador = p_id_jugador FOR UPDATE;
    sp_validar_equipo_capitan(p_id_sesion, v_equipo_actual);   -- el jugador es de su equipo
    sp_validar_equipo_capitan(p_id_sesion, p_id_equipo);       -- y sigue en su equipo
    UPDATE jugador
       SET rut = p_rut, nombres = p_nombres, apellidos = p_apellidos, nickname = p_nickname,
           fecha_nacimiento = p_fecha_nacimiento, email = p_email, id_equipo = p_id_equipo,
           rol_juego = p_rol_juego, estado = p_estado
     WHERE id_jugador = p_id_jugador;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Jugador actualizado correctamente.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK; p_resultado := 0; p_mensaje := 'El jugador no existe.';
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_jugador_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_jugador_eliminar (
    p_id_sesion  IN  NUMBER,
    p_id_jugador IN  NUMBER,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2
) IS
    v_equipo_actual jugador.id_equipo%TYPE;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR,CAPITAN');
    SELECT id_equipo INTO v_equipo_actual FROM jugador WHERE id_jugador = p_id_jugador;
    sp_validar_equipo_capitan(p_id_sesion, v_equipo_actual);
    DELETE FROM jugador WHERE id_jugador = p_id_jugador;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Jugador eliminado.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK; p_resultado := 0; p_mensaje := 'El jugador no existe.';
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_jugador_eliminar;
/

-- ---------------------------------------------------------------------------
-- MANTENEDOR 10: ÁRBITROS / STAFF
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_arbitro_listar (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT a.id_arbitro, a.rut, a.nombres, a.apellidos, a.nombres || ' ' || a.apellidos AS nombre_completo,
               a.email, a.telefono, a.tipo, a.id_usuario, u.username, a.estado,
               (SELECT COUNT(*) FROM partida p WHERE p.id_arbitro = a.id_arbitro) AS partidas_dirigidas
          FROM arbitro a
          LEFT JOIN usuario u ON u.id_usuario = a.id_usuario
         ORDER BY a.apellidos, a.nombres;
END sp_arbitro_listar;
/

CREATE OR REPLACE PROCEDURE sp_arbitro_insertar (
    p_id_sesion  IN  NUMBER,
    p_rut        IN  VARCHAR2,
    p_nombres    IN  VARCHAR2,
    p_apellidos  IN  VARCHAR2,
    p_email      IN  VARCHAR2,
    p_telefono   IN  VARCHAR2,
    p_tipo       IN  VARCHAR2,
    p_id_usuario IN  NUMBER,
    p_estado     IN  VARCHAR2,
    p_id         OUT NUMBER,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    IF fn_validar_rut(p_rut) = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'RUT inválido. Use el formato 12345678-9 con dígito verificador correcto.');
    END IF;
    p_id := seq_arbitro.NEXTVAL;
    INSERT INTO arbitro (id_arbitro, rut, nombres, apellidos, email, telefono, tipo, id_usuario, estado)
    VALUES (p_id, UPPER(REPLACE(TRIM(p_rut), '.', '')), TRIM(p_nombres), TRIM(p_apellidos),
            LOWER(TRIM(p_email)), TRIM(p_telefono), NVL(p_tipo, 'ARBITRO'), p_id_usuario, NVL(p_estado, 'ACTIVO'));
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Árbitro/staff registrado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_arbitro_insertar;
/

CREATE OR REPLACE PROCEDURE sp_arbitro_actualizar (
    p_id_sesion  IN  NUMBER,
    p_id_arbitro IN  NUMBER,
    p_rut        IN  VARCHAR2,
    p_nombres    IN  VARCHAR2,
    p_apellidos  IN  VARCHAR2,
    p_email      IN  VARCHAR2,
    p_telefono   IN  VARCHAR2,
    p_tipo       IN  VARCHAR2,
    p_id_usuario IN  NUMBER,
    p_estado     IN  VARCHAR2,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    IF fn_validar_rut(p_rut) = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'RUT inválido. Use el formato 12345678-9 con dígito verificador correcto.');
    END IF;
    UPDATE arbitro
       SET rut = UPPER(REPLACE(TRIM(p_rut), '.', '')), nombres = TRIM(p_nombres), apellidos = TRIM(p_apellidos),
           email = LOWER(TRIM(p_email)), telefono = TRIM(p_telefono), tipo = p_tipo,
           id_usuario = p_id_usuario, estado = p_estado
     WHERE id_arbitro = p_id_arbitro;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El árbitro no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Árbitro/staff actualizado correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_arbitro_actualizar;
/

CREATE OR REPLACE PROCEDURE sp_arbitro_eliminar (
    p_id_sesion  IN  NUMBER,
    p_id_arbitro IN  NUMBER,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    DELETE FROM arbitro WHERE id_arbitro = p_id_arbitro;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El árbitro no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Árbitro/staff eliminado.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_arbitro_eliminar;
/

/* ============================================================================
   6. GESTORES DE INFORMACIÓN (5)
   Generan información nueva cruzando datos existentes. Listas compuestas se
   reciben como texto delimitado y se procesan en la BD en una sola transacción:
     patrocinios   -> 'id_patrocinador:monto;id_patrocinador:monto'
     plantilla     -> 'id_jugador:S;id_jugador:N'   (S = titular, N = suplente)
     estadísticas  -> 'id_jugador:kills:deaths:assists;...'
   ============================================================================ */

-- Vista de apoyo: tabla de posiciones calculada a partir de las partidas
CREATE OR REPLACE VIEW vw_posiciones_torneo AS
SELECT i.id_torneo, i.id_inscripcion, e.id_equipo, e.nombre AS equipo, e.tag, i.puntos,
       f.tipo AS tipo_formato,
       COUNT(p.id_partida) AS pj,
       NVL(SUM(CASE WHEN p.id_ganador = e.id_equipo THEN 1 ELSE 0 END), 0) AS pg,
       NVL(SUM(CASE WHEN p.estado = 'JUGADA' AND p.id_ganador IS NULL THEN 1 ELSE 0 END), 0) AS pe,
       NVL(SUM(CASE WHEN p.estado = 'JUGADA' AND p.id_ganador <> e.id_equipo THEN 1 ELSE 0 END), 0) AS pp,
       NVL(SUM(CASE WHEN p.id_equipo_local = e.id_equipo THEN p.puntaje_local ELSE p.puntaje_visita END), 0) AS a_favor,
       NVL(SUM(CASE WHEN p.id_equipo_local = e.id_equipo THEN p.puntaje_visita ELSE p.puntaje_local END), 0) AS en_contra
  FROM inscripcion i
  JOIN equipo e         ON e.id_equipo = i.id_equipo
  JOIN torneo t         ON t.id_torneo = i.id_torneo
  JOIN formato_torneo f ON f.id_formato = t.id_formato
  LEFT JOIN partida p   ON p.id_torneo = i.id_torneo
                       AND p.estado IN ('JUGADA','BYE')
                       AND (p.id_equipo_local = e.id_equipo OR p.id_equipo_visita = e.id_equipo)
 WHERE i.estado = 'CONFIRMADA'
 GROUP BY i.id_torneo, i.id_inscripcion, e.id_equipo, e.nombre, e.tag, i.puntos, f.tipo;

-- Suma (o resta) puntos a la inscripción de un equipo. Uso interno, sin COMMIT.
CREATE OR REPLACE PROCEDURE sp_sumar_puntos (
    p_id_torneo IN NUMBER,
    p_id_equipo IN NUMBER,
    p_puntos    IN NUMBER
) IS
BEGIN
    IF p_id_equipo IS NOT NULL AND NVL(p_puntos, 0) <> 0 THEN
        UPDATE inscripcion
           SET puntos = puntos + p_puntos
         WHERE id_torneo = p_id_torneo
           AND id_equipo = p_id_equipo;
    END IF;
END sp_sumar_puntos;
/

-- Árbitro activo para asignar a una partida (rotativo según cantidad de partidas dirigidas)
CREATE OR REPLACE FUNCTION fn_asignar_arbitro (p_id_torneo IN NUMBER) RETURN NUMBER IS
    CURSOR cur_arbitros IS
        SELECT a.id_arbitro
          FROM arbitro a
         WHERE a.estado = 'ACTIVO' AND a.tipo = 'ARBITRO'
         ORDER BY (SELECT COUNT(*) FROM partida p
                    WHERE p.id_arbitro = a.id_arbitro AND p.id_torneo = p_id_torneo), a.id_arbitro;
    v_id arbitro.id_arbitro%TYPE;
BEGIN
    OPEN cur_arbitros;
    FETCH cur_arbitros INTO v_id;
    IF cur_arbitros%NOTFOUND THEN
        v_id := NULL;
    END IF;
    CLOSE cur_arbitros;
    RETURN v_id;
END fn_asignar_arbitro;
/

-- ---------------------------------------------------------------------------
-- GESTOR 1: APERTURA DE TORNEOS
-- Cruza Videojuego + Plataforma + Sede + Formato + Categoría + Patrocinadores
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_abrir_torneo (
    p_id_sesion         IN  NUMBER,
    p_nombre            IN  VARCHAR2,
    p_id_videojuego     IN  NUMBER,
    p_id_plataforma     IN  NUMBER,
    p_id_sede           IN  NUMBER,
    p_id_formato        IN  NUMBER,
    p_id_categoria      IN  NUMBER,
    p_fecha_inicio      IN  DATE,
    p_fecha_fin         IN  DATE,
    p_cupo_maximo       IN  NUMBER,
    p_costo_inscripcion IN  NUMBER,
    p_premio_total      IN  NUMBER,
    p_patrocinios       IN  VARCHAR2,
    p_id                OUT NUMBER,
    p_resultado         OUT NUMBER,
    p_mensaje           OUT VARCHAR2
) IS
    v_juego      videojuego%ROWTYPE;
    v_sede       sede%ROWTYPE;
    v_choque     NUMBER;
    v_item       VARCHAR2(100);
    v_idx        PLS_INTEGER := 1;
    v_id_pat     patrocinador.id_patrocinador%TYPE;
    v_monto      NUMBER;
    v_n_pat      NUMBER := 0;
    v_total_pat  NUMBER := 0;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');

    BEGIN
        SELECT * INTO v_juego FROM videojuego WHERE id_videojuego = p_id_videojuego;
        SELECT * INTO v_sede  FROM sede       WHERE id_sede = p_id_sede;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20030, 'El videojuego o la sede seleccionados no existen.');
    END;
    IF v_juego.estado <> 'ACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20031, 'El videojuego "' || v_juego.nombre || '" está inactivo.');
    END IF;
    IF v_sede.estado <> 'ACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20032, 'La sede "' || v_sede.nombre || '" está inactiva.');
    END IF;
    IF p_fecha_inicio IS NULL OR p_fecha_fin IS NULL OR p_fecha_fin < p_fecha_inicio THEN
        RAISE_APPLICATION_ERROR(-20033, 'Las fechas del torneo son inválidas (la fecha de término debe ser posterior al inicio).');
    END IF;
    -- Capacidad física: cupo de equipos x jugadores por equipo no puede superar el aforo de la sede
    IF v_sede.modalidad <> 'ONLINE' AND p_cupo_maximo * v_juego.jugadores_por_equipo > v_sede.capacidad THEN
        RAISE_APPLICATION_ERROR(-20034, 'La sede "' || v_sede.nombre || '" admite ' || v_sede.capacidad ||
            ' personas y el torneo requiere ' || (p_cupo_maximo * v_juego.jugadores_por_equipo) || ' jugadores.');
    END IF;
    -- Una sede presencial no puede tener dos torneos activos con fechas que se crucen
    IF v_sede.modalidad <> 'ONLINE' THEN
        SELECT COUNT(*) INTO v_choque
          FROM torneo
         WHERE id_sede = p_id_sede
           AND estado IN ('ABIERTO','EN_CURSO')
           AND fecha_inicio <= p_fecha_fin
           AND fecha_fin >= p_fecha_inicio;
        IF v_choque > 0 THEN
            RAISE_APPLICATION_ERROR(-20035, 'La sede ya tiene un torneo activo en ese rango de fechas.');
        END IF;
    END IF;

    p_id := seq_torneo.NEXTVAL;
    INSERT INTO torneo (id_torneo, nombre, id_videojuego, id_plataforma, id_sede, id_formato, id_categoria,
                        id_organizador, fecha_inicio, fecha_fin, cupo_maximo, costo_inscripcion,
                        premio_total, estado)
    VALUES (p_id, TRIM(p_nombre), p_id_videojuego, p_id_plataforma, p_id_sede, p_id_formato, p_id_categoria,
            p_id_sesion, TRUNC(p_fecha_inicio), TRUNC(p_fecha_fin), p_cupo_maximo, NVL(p_costo_inscripcion, 0),
            NVL(p_premio_total, 0), 'ABIERTO');

    -- Patrocinios asociados (tabla intermedia TORNEO_PATROCINADOR)
    LOOP
        v_item := REGEXP_SUBSTR(p_patrocinios, '[^;]+', 1, v_idx);
        EXIT WHEN v_item IS NULL;
        v_id_pat := TO_NUMBER(REGEXP_SUBSTR(v_item, '[^:]+', 1, 1));
        v_monto  := NVL(TO_NUMBER(REGEXP_SUBSTR(v_item, '[^:]+', 1, 2)), 0);
        INSERT INTO torneo_patrocinador (id_torneo, id_patrocinador, monto_aporte)
        VALUES (p_id, v_id_pat, v_monto);
        v_n_pat := v_n_pat + 1;
        v_total_pat := v_total_pat + v_monto;
        v_idx := v_idx + 1;
    END LOOP;

    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Torneo "' || TRIM(p_nombre) || '" abierto con ' || p_cupo_maximo || ' cupos y ' ||
                 v_n_pat || ' patrocinador(es) (aporte ' || fn_formato_monto(v_total_pat) || ').';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_abrir_torneo;
/

CREATE OR REPLACE PROCEDURE sp_torneo_listar (
    p_estado IN  VARCHAR2,           -- NULL = todos
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT t.id_torneo, t.nombre, v.nombre AS videojuego, v.jugadores_por_equipo, pl.nombre AS plataforma,
               s.nombre AS sede, s.modalidad, f.nombre AS formato, f.tipo AS tipo_formato, c.nombre AS categoria,
               u.nombre_completo AS organizador,
               TO_CHAR(t.fecha_inicio, 'YYYY-MM-DD') AS fecha_inicio,
               TO_CHAR(t.fecha_fin, 'YYYY-MM-DD') AS fecha_fin,
               t.cupo_maximo, fn_validar_cupos_torneo(t.id_torneo) AS cupos_disponibles,
               t.costo_inscripcion, t.premio_total, t.estado,
               fn_recaudacion_torneo(t.id_torneo) AS recaudacion,
               fn_aporte_patrocinio(t.id_torneo) AS patrocinio,
               (SELECT COUNT(*) FROM partida p WHERE p.id_torneo = t.id_torneo AND p.estado = 'PROGRAMADA') AS partidas_pendientes,
               (SELECT COUNT(*) FROM partida p WHERE p.id_torneo = t.id_torneo) AS partidas_total
          FROM torneo t
          JOIN videojuego v      ON v.id_videojuego = t.id_videojuego
          JOIN plataforma pl     ON pl.id_plataforma = t.id_plataforma
          JOIN sede s            ON s.id_sede = t.id_sede
          JOIN formato_torneo f  ON f.id_formato = t.id_formato
          JOIN categoria c       ON c.id_categoria = t.id_categoria
          JOIN usuario u         ON u.id_usuario = t.id_organizador
         WHERE p_estado IS NULL OR t.estado = p_estado
         ORDER BY CASE t.estado WHEN 'EN_CURSO' THEN 1 WHEN 'ABIERTO' THEN 2 WHEN 'FINALIZADO' THEN 3 ELSE 4 END,
                  t.fecha_inicio DESC;
END sp_torneo_listar;
/

CREATE OR REPLACE PROCEDURE sp_torneo_patrocinios_listar (
    p_id_torneo IN  NUMBER,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT p.razon_social, p.rubro, tp.monto_aporte
          FROM torneo_patrocinador tp
          JOIN patrocinador p ON p.id_patrocinador = tp.id_patrocinador
         WHERE tp.id_torneo = p_id_torneo
         ORDER BY tp.monto_aporte DESC;
END sp_torneo_patrocinios_listar;
/

CREATE OR REPLACE PROCEDURE sp_torneo_cancelar (
    p_id_sesion IN  NUMBER,
    p_id_torneo IN  NUMBER,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    -- Las transiciones de estado válidas se controlan en TRG_TORNEO_ESTADO
    UPDATE partida SET estado = 'ANULADA' WHERE id_torneo = p_id_torneo AND estado = 'PROGRAMADA';
    UPDATE torneo SET estado = 'CANCELADO' WHERE id_torneo = p_id_torneo;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'El torneo no existe.');
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Torneo cancelado. Partidas pendientes anuladas.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_torneo_cancelar;
/

-- ---------------------------------------------------------------------------
-- GESTOR 2: INSCRIPCIÓN DE EQUIPOS Y ROSTER
-- Cruza Torneo + Equipo + Jugadores validando cupos, estado disciplinario,
-- edad de la categoría y tamaño de plantilla. Bloquea el torneo (FOR UPDATE)
-- para que dos inscripciones simultáneas no superen el cupo.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_inscribir_equipo (
    p_id_sesion IN  NUMBER,
    p_id_torneo IN  NUMBER,
    p_id_equipo IN  NUMBER,
    p_jugadores IN  VARCHAR2,
    p_id        OUT NUMBER,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
    CURSOR cur_torneo IS
        SELECT t.nombre, t.estado, t.costo_inscripcion, t.fecha_inicio,
               v.jugadores_por_equipo, c.nombre AS categoria, c.edad_minima, c.edad_maxima
          FROM torneo t
          JOIN videojuego v ON v.id_videojuego = t.id_videojuego
          JOIN categoria c  ON c.id_categoria = t.id_categoria
         WHERE t.id_torneo = p_id_torneo
           FOR UPDATE OF t.estado;
    v_t              cur_torneo%ROWTYPE;
    v_equipo         equipo%ROWTYPE;
    v_insc_previa    inscripcion.estado%TYPE;
    v_jug            jugador%ROWTYPE;
    v_item           VARCHAR2(50);
    v_idx            PLS_INTEGER := 1;
    v_id_jug         NUMBER;
    v_titular        CHAR(1);
    v_titulares      NUMBER := 0;
    v_suplentes      NUMBER := 0;
    v_edad           NUMBER;
    v_estado_disc    VARCHAR2(20);
    v_otro_roster    NUMBER;
    c_max_suplentes  CONSTANT NUMBER := 2;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR,CAPITAN');
    sp_validar_equipo_capitan(p_id_sesion, p_id_equipo);

    OPEN cur_torneo;
    FETCH cur_torneo INTO v_t;
    IF cur_torneo%NOTFOUND THEN
        CLOSE cur_torneo;
        RAISE_APPLICATION_ERROR(-20040, 'El torneo no existe.');
    END IF;
    CLOSE cur_torneo;   -- el bloqueo FOR UPDATE se mantiene hasta COMMIT/ROLLBACK

    IF v_t.estado <> 'ABIERTO' THEN
        RAISE_APPLICATION_ERROR(-20041, 'El torneo "' || v_t.nombre || '" no está abierto a inscripciones (estado ' || v_t.estado || ').');
    END IF;
    IF fn_validar_cupos_torneo(p_id_torneo) <= 0 THEN
        RAISE_APPLICATION_ERROR(-20042, 'El torneo "' || v_t.nombre || '" no tiene cupos disponibles.');
    END IF;

    BEGIN
        SELECT * INTO v_equipo FROM equipo WHERE id_equipo = p_id_equipo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20043, 'El equipo no existe.');
    END;
    IF v_equipo.estado <> 'ACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20044, 'El equipo "' || v_equipo.nombre || '" está inactivo.');
    END IF;

    -- Inscripción previa: si está confirmada se rechaza; si fue retirada se reemplaza
    BEGIN
        SELECT estado INTO v_insc_previa
          FROM inscripcion WHERE id_torneo = p_id_torneo AND id_equipo = p_id_equipo;
        IF v_insc_previa = 'CONFIRMADA' THEN
            RAISE_APPLICATION_ERROR(-20045, 'El equipo "' || v_equipo.nombre || '" ya está inscrito en este torneo.');
        END IF;
        DELETE FROM inscripcion WHERE id_torneo = p_id_torneo AND id_equipo = p_id_equipo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
    END;

    p_id := seq_inscripcion.NEXTVAL;
    INSERT INTO inscripcion (id_inscripcion, id_torneo, id_equipo, fecha_inscripcion, monto_pagado, puntos, estado)
    VALUES (p_id, p_id_torneo, p_id_equipo, SYSDATE, v_t.costo_inscripcion, 0, 'CONFIRMADA');

    -- Procesamiento de la plantilla
    LOOP
        v_item := REGEXP_SUBSTR(p_jugadores, '[^;]+', 1, v_idx);
        EXIT WHEN v_item IS NULL;
        v_id_jug  := TO_NUMBER(REGEXP_SUBSTR(v_item, '[^:]+', 1, 1));
        v_titular := NVL(UPPER(REGEXP_SUBSTR(v_item, '[^:]+', 1, 2)), 'S');

        BEGIN
            SELECT * INTO v_jug FROM jugador WHERE id_jugador = v_id_jug;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20046, 'El jugador ' || v_id_jug || ' no existe.');
        END;
        IF NVL(v_jug.id_equipo, -1) <> p_id_equipo THEN
            RAISE_APPLICATION_ERROR(-20047, 'El jugador ' || v_jug.nickname || ' no pertenece al equipo ' || v_equipo.nombre || '.');
        END IF;
        v_estado_disc := fn_verificar_estado_jugador(v_id_jug);
        IF v_estado_disc <> 'HABILITADO' THEN
            RAISE_APPLICATION_ERROR(-20048, 'El jugador ' || v_jug.nickname || ' está ' || v_estado_disc || ' y no puede ser inscrito.');
        END IF;
        v_edad := fn_calcular_edad(v_jug.fecha_nacimiento, v_t.fecha_inicio);
        IF v_edad < v_t.edad_minima OR (v_t.edad_maxima IS NOT NULL AND v_edad > v_t.edad_maxima) THEN
            RAISE_APPLICATION_ERROR(-20049, 'El jugador ' || v_jug.nickname || ' (' || v_edad ||
                ' años) no cumple la edad de la categoría ' || v_t.categoria || '.');
        END IF;
        SELECT COUNT(*) INTO v_otro_roster
          FROM roster r
          JOIN inscripcion i ON i.id_inscripcion = r.id_inscripcion
         WHERE r.id_jugador = v_id_jug
           AND i.id_torneo = p_id_torneo
           AND i.estado = 'CONFIRMADA'
           AND i.id_inscripcion <> p_id;
        IF v_otro_roster > 0 THEN
            RAISE_APPLICATION_ERROR(-20050, 'El jugador ' || v_jug.nickname || ' ya está inscrito en otro equipo de este torneo.');
        END IF;

        INSERT INTO roster (id_inscripcion, id_jugador, es_titular) VALUES (p_id, v_id_jug, v_titular);
        IF v_titular = 'S' THEN
            v_titulares := v_titulares + 1;
        ELSE
            v_suplentes := v_suplentes + 1;
        END IF;
        v_idx := v_idx + 1;
    END LOOP;

    IF v_titulares <> v_t.jugadores_por_equipo THEN
        RAISE_APPLICATION_ERROR(-20051, 'El juego requiere ' || v_t.jugadores_por_equipo ||
            ' titular(es) y se indicaron ' || v_titulares || '.');
    END IF;
    IF v_suplentes > c_max_suplentes THEN
        RAISE_APPLICATION_ERROR(-20052, 'Se permiten como máximo ' || c_max_suplentes || ' suplentes.');
    END IF;

    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Equipo "' || v_equipo.nombre || '" inscrito en "' || v_t.nombre || '" con ' ||
                 v_titulares || ' titular(es) y ' || v_suplentes || ' suplente(s). Monto: ' ||
                 fn_formato_monto(v_t.costo_inscripcion) || '.';
EXCEPTION
    WHEN OTHERS THEN
        IF cur_torneo%ISOPEN THEN CLOSE cur_torneo; END IF;
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_inscribir_equipo;
/

CREATE OR REPLACE PROCEDURE sp_retirar_inscripcion (
    p_id_sesion      IN  NUMBER,
    p_id_inscripcion IN  NUMBER,
    p_resultado      OUT NUMBER,
    p_mensaje        OUT VARCHAR2
) IS
    v_id_equipo     inscripcion.id_equipo%TYPE;
    v_estado_torneo torneo.estado%TYPE;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR,CAPITAN');
    SELECT i.id_equipo, t.estado INTO v_id_equipo, v_estado_torneo
      FROM inscripcion i JOIN torneo t ON t.id_torneo = i.id_torneo
     WHERE i.id_inscripcion = p_id_inscripcion
       FOR UPDATE OF i.estado;
    sp_validar_equipo_capitan(p_id_sesion, v_id_equipo);
    IF v_estado_torneo <> 'ABIERTO' THEN
        RAISE_APPLICATION_ERROR(-20053, 'Solo se puede retirar una inscripción mientras el torneo está abierto.');
    END IF;
    UPDATE inscripcion SET estado = 'RETIRADA' WHERE id_inscripcion = p_id_inscripcion;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Inscripción retirada; el cupo quedó disponible.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK; p_resultado := 0; p_mensaje := 'La inscripción no existe.';
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_retirar_inscripcion;
/

CREATE OR REPLACE PROCEDURE sp_inscripcion_listar (
    p_id_torneo IN  NUMBER,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT i.id_inscripcion, i.id_equipo, e.nombre AS equipo, e.tag,
               TO_CHAR(i.fecha_inscripcion, 'YYYY-MM-DD HH24:MI') AS fecha_inscripcion,
               i.monto_pagado, i.puntos, i.estado,
               (SELECT LISTAGG(j.nickname || CASE WHEN r.es_titular = 'N' THEN ' (S)' END, ', ')
                       WITHIN GROUP (ORDER BY r.es_titular DESC, j.nickname)
                  FROM roster r JOIN jugador j ON j.id_jugador = r.id_jugador
                 WHERE r.id_inscripcion = i.id_inscripcion) AS plantilla
          FROM inscripcion i
          JOIN equipo e ON e.id_equipo = i.id_equipo
         WHERE i.id_torneo = p_id_torneo
         ORDER BY i.estado, i.fecha_inscripcion;
END sp_inscripcion_listar;
/

-- Jugadores de un equipo con su estado disciplinario (para armar la plantilla)
CREATE OR REPLACE PROCEDURE sp_jugadores_equipo (
    p_id_equipo IN  NUMBER,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT j.id_jugador, j.nickname, j.nombres || ' ' || j.apellidos AS nombre, j.rol_juego,
               fn_calcular_edad(j.fecha_nacimiento) AS edad,
               fn_verificar_estado_jugador(j.id_jugador) AS estado_disciplinario
          FROM jugador j
         WHERE j.id_equipo = p_id_equipo
         ORDER BY j.id_jugador;
END sp_jugadores_equipo;
/

-- ---------------------------------------------------------------------------
-- GESTOR 3: GENERACIÓN DE FIXTURE
-- Recorre con cursor los equipos inscritos (orden aleatorio = sorteo) y crea
-- las partidas: liga -> método del círculo (todos contra todos);
-- eliminación directa -> llaves de la ronda 1 (BYE si el número es impar).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_generar_fixture (
    p_id_sesion IN  NUMBER,
    p_id_torneo IN  NUMBER,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
    CURSOR cur_inscritos IS
        SELECT id_equipo
          FROM inscripcion
         WHERE id_torneo = p_id_torneo
           AND estado = 'CONFIRMADA'
         ORDER BY DBMS_RANDOM.VALUE;
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_eq          t_ids;
    v_n           PLS_INTEGER := 0;
    v_id_equipo   NUMBER;
    v_estado      torneo.estado%TYPE;
    v_tipo        formato_torneo.tipo%TYPE;
    v_inicio      DATE;
    v_fin         DATE;
    v_existentes  NUMBER;
    v_creadas     NUMBER := 0;
    v_rondas      PLS_INTEGER;
    v_mitad       PLS_INTEGER;
    v_a           NUMBER;
    v_b           NUMBER;
    v_tmp         NUMBER;
    v_fecha       DATE;
    v_m           PLS_INTEGER;
    v_i           PLS_INTEGER;
    v_equipos     PLS_INTEGER;

    PROCEDURE crear_partida (p_ronda IN NUMBER, p_local IN NUMBER, p_visita IN NUMBER, p_fecha IN DATE) IS
        v_arbitro NUMBER;
    BEGIN
        IF p_visita IS NULL THEN
            -- BYE: el equipo avanza directo y suma la victoria
            INSERT INTO partida (id_partida, id_torneo, ronda, id_equipo_local, id_equipo_visita, id_arbitro,
                                 fecha_hora, id_ganador, estado, observacion)
            VALUES (seq_partida.NEXTVAL, p_id_torneo, p_ronda, p_local, NULL, NULL,
                    p_fecha, p_local, 'BYE', 'Pasa directo a la siguiente ronda');
            sp_sumar_puntos(p_id_torneo, p_local, fn_puntos_resultado(p_id_torneo, p_local, p_local, 'N'));
        ELSE
            v_arbitro := fn_asignar_arbitro(p_id_torneo);
            INSERT INTO partida (id_partida, id_torneo, ronda, id_equipo_local, id_equipo_visita, id_arbitro,
                                 fecha_hora, estado)
            VALUES (seq_partida.NEXTVAL, p_id_torneo, p_ronda, p_local, p_visita, v_arbitro,
                    p_fecha, 'PROGRAMADA');
            v_creadas := v_creadas + 1;
        END IF;
    END crear_partida;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');

    SELECT t.estado, f.tipo, t.fecha_inicio, t.fecha_fin
      INTO v_estado, v_tipo, v_inicio, v_fin
      FROM torneo t JOIN formato_torneo f ON f.id_formato = t.id_formato
     WHERE t.id_torneo = p_id_torneo
       FOR UPDATE OF t.estado;
    IF v_estado <> 'ABIERTO' THEN
        RAISE_APPLICATION_ERROR(-20060, 'El fixture solo se genera para torneos abiertos (estado actual: ' || v_estado || ').');
    END IF;
    SELECT COUNT(*) INTO v_existentes FROM partida WHERE id_torneo = p_id_torneo;
    IF v_existentes > 0 THEN
        RAISE_APPLICATION_ERROR(-20061, 'El torneo ya tiene partidas generadas.');
    END IF;
    IF fn_asignar_arbitro(p_id_torneo) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20062, 'No hay árbitros activos para asignar a las partidas.');
    END IF;

    -- Sorteo: cursor explícito sobre los equipos inscritos
    OPEN cur_inscritos;
    LOOP
        FETCH cur_inscritos INTO v_id_equipo;
        EXIT WHEN cur_inscritos%NOTFOUND;
        v_n := v_n + 1;
        v_eq(v_n) := v_id_equipo;
    END LOOP;
    CLOSE cur_inscritos;

    IF v_n < 2 THEN
        RAISE_APPLICATION_ERROR(-20063, 'Se necesitan al menos 2 equipos inscritos para generar el fixture.');
    END IF;

    v_equipos := v_n;
    IF v_tipo = 'TODOS_CONTRA_TODOS' THEN
        -- Método del círculo: si es impar se agrega un "descanso" (NULL)
        IF MOD(v_n, 2) = 1 THEN
            v_n := v_n + 1;
            v_eq(v_n) := NULL;
        END IF;
        v_rondas := v_n - 1;
        v_mitad  := v_n / 2;
        FOR r IN 1 .. v_rondas LOOP
            v_fecha := LEAST(TRUNC(v_inicio) + (r - 1), TRUNC(v_fin)) + 18/24;
            v_m := 0;
            FOR m IN 1 .. v_mitad LOOP
                v_a := v_eq(m);
                v_b := v_eq(v_n - m + 1);
                IF v_a IS NOT NULL AND v_b IS NOT NULL THEN
                    IF MOD(r, 2) = 0 THEN   -- alterna localía
                        v_tmp := v_a; v_a := v_b; v_b := v_tmp;
                    END IF;
                    crear_partida(r, v_a, v_b, v_fecha + v_m / 24);
                    v_m := v_m + 1;
                END IF;
            END LOOP;
            -- Rotación: el primero queda fijo, el último pasa a la posición 2
            v_tmp := v_eq(v_n);
            FOR k IN REVERSE 3 .. v_n LOOP
                v_eq(k) := v_eq(k - 1);
            END LOOP;
            v_eq(2) := v_tmp;
        END LOOP;
    ELSE
        -- Eliminación directa: ronda 1 por pares; si es impar el último recibe BYE
        v_fecha := TRUNC(v_inicio) + 18/24;
        v_i := 1;
        v_m := 0;
        WHILE v_i <= v_n LOOP
            IF v_i + 1 <= v_n THEN
                crear_partida(1, v_eq(v_i), v_eq(v_i + 1), v_fecha + v_m / 24);
            ELSE
                crear_partida(1, v_eq(v_i), NULL, v_fecha + v_m / 24);
            END IF;
            v_m := v_m + 1;
            v_i := v_i + 2;
        END LOOP;
    END IF;

    UPDATE torneo SET estado = 'EN_CURSO' WHERE id_torneo = p_id_torneo;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Fixture generado: ' || v_creadas || ' partida(s) programada(s) para ' ||
                 v_equipos ||
                 ' equipos. El torneo pasó a EN CURSO.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK; p_resultado := 0; p_mensaje := 'El torneo no existe.';
    WHEN OTHERS THEN
        IF cur_inscritos%ISOPEN THEN CLOSE cur_inscritos; END IF;
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_generar_fixture;
/

-- Eliminación directa: cuando una ronda termina, crea la siguiente con los ganadores.
-- Uso interno (lo invoca SP_REGISTRAR_RESULTADO), sin COMMIT.
CREATE OR REPLACE PROCEDURE sp_avanzar_ronda (
    p_id_torneo IN  NUMBER,
    p_ronda     IN  NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
    CURSOR cur_ganadores IS
        SELECT id_ganador
          FROM partida
         WHERE id_torneo = p_id_torneo
           AND ronda = p_ronda
           AND estado IN ('JUGADA','BYE')
         ORDER BY id_partida;
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_g         t_ids;
    v_n         PLS_INTEGER := 0;
    v_id        NUMBER;
    v_pend      NUMBER;
    v_fecha     DATE;
    v_i         PLS_INTEGER := 1;
    v_m         PLS_INTEGER := 0;
    v_arbitro   NUMBER;
BEGIN
    p_mensaje := NULL;
    SELECT COUNT(*) INTO v_pend
      FROM partida
     WHERE id_torneo = p_id_torneo AND ronda = p_ronda AND estado = 'PROGRAMADA';
    IF v_pend > 0 THEN
        RETURN;   -- la ronda aún no termina
    END IF;

    OPEN cur_ganadores;
    LOOP
        FETCH cur_ganadores INTO v_id;
        EXIT WHEN cur_ganadores%NOTFOUND;
        v_n := v_n + 1;
        v_g(v_n) := v_id;
    END LOOP;
    CLOSE cur_ganadores;

    IF v_n <= 1 THEN
        p_mensaje := 'Final disputada: el torneo está listo para liquidar premios.';
        RETURN;
    END IF;

    SELECT TRUNC(MAX(fecha_hora)) + 1 + 18/24 INTO v_fecha
      FROM partida WHERE id_torneo = p_id_torneo AND ronda = p_ronda;

    WHILE v_i <= v_n LOOP
        IF v_i + 1 <= v_n THEN
            v_arbitro := fn_asignar_arbitro(p_id_torneo);
            INSERT INTO partida (id_partida, id_torneo, ronda, id_equipo_local, id_equipo_visita, id_arbitro,
                                 fecha_hora, estado)
            VALUES (seq_partida.NEXTVAL, p_id_torneo, p_ronda + 1, v_g(v_i), v_g(v_i + 1), v_arbitro,
                    v_fecha + v_m / 24, 'PROGRAMADA');
        ELSE
            INSERT INTO partida (id_partida, id_torneo, ronda, id_equipo_local, id_equipo_visita, id_arbitro,
                                 fecha_hora, id_ganador, estado, observacion)
            VALUES (seq_partida.NEXTVAL, p_id_torneo, p_ronda + 1, v_g(v_i), NULL, NULL,
                    v_fecha + v_m / 24, v_g(v_i), 'BYE', 'Pasa directo a la siguiente ronda');
            sp_sumar_puntos(p_id_torneo, v_g(v_i), fn_puntos_resultado(p_id_torneo, v_g(v_i), v_g(v_i), 'N'));
        END IF;
        v_m := v_m + 1;
        v_i := v_i + 2;
    END LOOP;
    p_mensaje := CASE WHEN v_n = 2 THEN 'Se generó la FINAL.' ELSE 'Se generó la ronda ' || (p_ronda + 1) || '.' END;
END sp_avanzar_ronda;
/

CREATE OR REPLACE PROCEDURE sp_partida_listar (
    p_id_torneo IN  NUMBER,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT p.id_partida, p.ronda, p.id_equipo_local, el.nombre AS local, p.id_equipo_visita,
               NVL(ev.nombre, '— BYE —') AS visita,
               TO_CHAR(p.fecha_hora, 'YYYY-MM-DD HH24:MI') AS fecha_hora,
               a.nombres || ' ' || a.apellidos AS arbitro,
               p.puntaje_local, p.puntaje_visita, g.nombre AS ganador, p.estado,
               (SELECT j.nickname FROM detalle_partida_jugador d JOIN jugador j ON j.id_jugador = d.id_jugador
                 WHERE d.id_partida = p.id_partida AND d.es_mvp = 'S' FETCH FIRST 1 ROW ONLY) AS mvp
          FROM partida p
          JOIN equipo el      ON el.id_equipo = p.id_equipo_local
          LEFT JOIN equipo ev ON ev.id_equipo = p.id_equipo_visita
          LEFT JOIN equipo g  ON g.id_equipo = p.id_ganador
          LEFT JOIN arbitro a ON a.id_arbitro = p.id_arbitro
         WHERE p.id_torneo = p_id_torneo
         ORDER BY p.ronda, p.fecha_hora, p.id_partida;
END sp_partida_listar;
/

-- Plantillas de ambos equipos de una partida con sus estadísticas (si existen)
CREATE OR REPLACE PROCEDURE sp_partida_detalle (
    p_id_partida IN  NUMBER,
    p_cursor     OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT CASE WHEN i.id_equipo = p.id_equipo_local THEN 'LOCAL' ELSE 'VISITA' END AS lado,
               e.nombre AS equipo, j.id_jugador, j.nickname, r.es_titular,
               d.kills, d.deaths, d.assists, NVL(d.es_mvp, 'N') AS es_mvp,
               CASE WHEN d.id_jugador IS NOT NULL THEN fn_calcular_ratio_kda(d.kills, d.deaths, d.assists) END AS kda
          FROM partida p
          JOIN inscripcion i ON i.id_torneo = p.id_torneo
                            AND i.id_equipo IN (p.id_equipo_local, p.id_equipo_visita)
          JOIN equipo e      ON e.id_equipo = i.id_equipo
          JOIN roster r      ON r.id_inscripcion = i.id_inscripcion
          JOIN jugador j     ON j.id_jugador = r.id_jugador
          LEFT JOIN detalle_partida_jugador d ON d.id_partida = p.id_partida AND d.id_jugador = j.id_jugador
         WHERE p.id_partida = p_id_partida
         ORDER BY CASE WHEN i.id_equipo = p.id_equipo_local THEN 1 ELSE 2 END, r.es_titular DESC, j.nickname;
END sp_partida_detalle;
/

-- ---------------------------------------------------------------------------
-- GESTOR 4: REGISTRO DE RESULTADOS Y KDA
-- Cruza Partida + Equipos + Jugadores + Árbitro. Asigna puntos según formato,
-- registra estadísticas, elige MVP con cursor y avanza llaves si corresponde.
-- La corrección de un marcador queda auditada por TRG_AUDITORIA_MARCADORES.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_resultado (
    p_id_sesion      IN  NUMBER,
    p_id_partida     IN  NUMBER,
    p_puntaje_local  IN  NUMBER,
    p_puntaje_visita IN  NUMBER,
    p_estadisticas   IN  VARCHAR2,
    p_resultado      OUT NUMBER,
    p_mensaje        OUT VARCHAR2
) IS
    CURSOR cur_partida IS
        SELECT p.id_torneo, p.ronda, p.id_equipo_local, p.id_equipo_visita, p.id_ganador, p.estado,
               t.estado AS estado_torneo, f.tipo AS tipo_formato
          FROM partida p
          JOIN torneo t         ON t.id_torneo = p.id_torneo
          JOIN formato_torneo f ON f.id_formato = t.id_formato
         WHERE p.id_partida = p_id_partida
           FOR UPDATE OF p.estado;
    CURSOR cur_mvp IS
        SELECT id_jugador
          FROM detalle_partida_jugador
         WHERE id_partida = p_id_partida
         ORDER BY fn_calcular_ratio_kda(kills, deaths, assists) DESC, kills DESC, deaths ASC;
    v_p           cur_partida%ROWTYPE;
    v_ganador     NUMBER;
    v_empate      CHAR(1);
    v_empate_ant  CHAR(1);
    v_posteriores NUMBER;
    v_item        VARCHAR2(100);
    v_idx         PLS_INTEGER := 1;
    v_id_jug      NUMBER;
    v_k           NUMBER;
    v_d           NUMBER;
    v_a           NUMBER;
    v_en_roster   NUMBER;
    v_n_stats     NUMBER := 0;
    v_mvp         NUMBER;
    v_msg_ronda   VARCHAR2(200);
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');

    OPEN cur_partida;
    FETCH cur_partida INTO v_p;
    IF cur_partida%NOTFOUND THEN
        CLOSE cur_partida;
        RAISE_APPLICATION_ERROR(-20070, 'La partida no existe.');
    END IF;
    CLOSE cur_partida;

    IF v_p.estado_torneo <> 'EN_CURSO' THEN
        RAISE_APPLICATION_ERROR(-20071, 'Solo se registran resultados de torneos en curso.');
    END IF;
    IF v_p.estado IN ('BYE','ANULADA') THEN
        RAISE_APPLICATION_ERROR(-20072, 'Esta partida está en estado ' || v_p.estado || ' y no admite resultado.');
    END IF;
    IF p_puntaje_local IS NULL OR p_puntaje_visita IS NULL OR p_puntaje_local < 0 OR p_puntaje_visita < 0 THEN
        RAISE_APPLICATION_ERROR(-20073, 'Debe indicar un marcador válido para ambos equipos.');
    END IF;

    IF p_puntaje_local = p_puntaje_visita THEN
        IF v_p.tipo_formato = 'ELIMINACION_DIRECTA' THEN
            RAISE_APPLICATION_ERROR(-20074, 'En eliminación directa no se permiten empates.');
        END IF;
        v_empate := 'S';
        v_ganador := NULL;
    ELSE
        v_empate := 'N';
        v_ganador := CASE WHEN p_puntaje_local > p_puntaje_visita
                          THEN v_p.id_equipo_local ELSE v_p.id_equipo_visita END;
    END IF;

    -- Corrección de un resultado ya cargado: se revierten los puntos anteriores
    IF v_p.estado = 'JUGADA' THEN
        IF v_p.tipo_formato = 'ELIMINACION_DIRECTA' THEN
            SELECT COUNT(*) INTO v_posteriores
              FROM partida WHERE id_torneo = v_p.id_torneo AND ronda > v_p.ronda;
            IF v_posteriores > 0 THEN
                RAISE_APPLICATION_ERROR(-20075, 'No se puede corregir: la ronda siguiente ya fue generada.');
            END IF;
        END IF;
        v_empate_ant := CASE WHEN v_p.id_ganador IS NULL THEN 'S' ELSE 'N' END;
        sp_sumar_puntos(v_p.id_torneo, v_p.id_equipo_local,
            -fn_puntos_resultado(v_p.id_torneo, v_p.id_equipo_local, v_p.id_ganador, v_empate_ant));
        sp_sumar_puntos(v_p.id_torneo, v_p.id_equipo_visita,
            -fn_puntos_resultado(v_p.id_torneo, v_p.id_equipo_visita, v_p.id_ganador, v_empate_ant));
    END IF;

    UPDATE partida
       SET puntaje_local = p_puntaje_local,
           puntaje_visita = p_puntaje_visita,
           id_ganador = v_ganador,
           estado = 'JUGADA'
     WHERE id_partida = p_id_partida;

    sp_sumar_puntos(v_p.id_torneo, v_p.id_equipo_local,
        fn_puntos_resultado(v_p.id_torneo, v_p.id_equipo_local, v_ganador, v_empate));
    sp_sumar_puntos(v_p.id_torneo, v_p.id_equipo_visita,
        fn_puntos_resultado(v_p.id_torneo, v_p.id_equipo_visita, v_ganador, v_empate));

    -- Estadísticas individuales (KDA)
    LOOP
        v_item := REGEXP_SUBSTR(p_estadisticas, '[^;]+', 1, v_idx);
        EXIT WHEN v_item IS NULL;
        v_id_jug := TO_NUMBER(REGEXP_SUBSTR(v_item, '[^:]+', 1, 1));
        v_k      := TO_NUMBER(REGEXP_SUBSTR(v_item, '[^:]+', 1, 2));
        v_d      := TO_NUMBER(REGEXP_SUBSTR(v_item, '[^:]+', 1, 3));
        v_a      := TO_NUMBER(REGEXP_SUBSTR(v_item, '[^:]+', 1, 4));
        IF v_id_jug IS NULL OR v_k IS NULL OR v_d IS NULL OR v_a IS NULL THEN
            RAISE_APPLICATION_ERROR(-20076, 'Estadística con formato inválido: "' || v_item || '".');
        END IF;
        SELECT COUNT(*) INTO v_en_roster
          FROM roster r
          JOIN inscripcion i ON i.id_inscripcion = r.id_inscripcion
         WHERE r.id_jugador = v_id_jug
           AND i.id_torneo = v_p.id_torneo
           AND i.id_equipo IN (v_p.id_equipo_local, v_p.id_equipo_visita);
        IF v_en_roster = 0 THEN
            RAISE_APPLICATION_ERROR(-20077, 'El jugador ' || v_id_jug || ' no pertenece a la plantilla de los equipos de esta partida.');
        END IF;
        MERGE INTO detalle_partida_jugador d
        USING (SELECT p_id_partida AS id_partida, v_id_jug AS id_jugador FROM dual) s
           ON (d.id_partida = s.id_partida AND d.id_jugador = s.id_jugador)
         WHEN MATCHED THEN
              UPDATE SET d.kills = v_k, d.deaths = v_d, d.assists = v_a, d.es_mvp = 'N'
         WHEN NOT MATCHED THEN
              INSERT (id_partida, id_jugador, kills, deaths, assists, es_mvp)
              VALUES (p_id_partida, v_id_jug, v_k, v_d, v_a, 'N');
        v_n_stats := v_n_stats + 1;
        v_idx := v_idx + 1;
    END LOOP;

    -- MVP: el de mejor ratio KDA de la partida (cursor explícito ordenado)
    UPDATE detalle_partida_jugador SET es_mvp = 'N' WHERE id_partida = p_id_partida;
    OPEN cur_mvp;
    FETCH cur_mvp INTO v_mvp;
    IF cur_mvp%FOUND THEN
        UPDATE detalle_partida_jugador SET es_mvp = 'S'
         WHERE id_partida = p_id_partida AND id_jugador = v_mvp;
    END IF;
    CLOSE cur_mvp;

    IF v_p.tipo_formato = 'ELIMINACION_DIRECTA' THEN
        sp_avanzar_ronda(v_p.id_torneo, v_p.ronda, v_msg_ronda);
    END IF;

    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Resultado ' || p_puntaje_local || '-' || p_puntaje_visita || ' registrado con estadísticas de ' ||
                 v_n_stats || ' jugador(es).' || CASE WHEN v_msg_ronda IS NOT NULL THEN ' ' || v_msg_ronda END;
EXCEPTION
    WHEN OTHERS THEN
        IF cur_partida%ISOPEN THEN CLOSE cur_partida; END IF;
        IF cur_mvp%ISOPEN THEN CLOSE cur_mvp; END IF;
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_registrar_resultado;
/

CREATE OR REPLACE PROCEDURE sp_posiciones_torneo (
    p_id_torneo IN  NUMBER,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT ROW_NUMBER() OVER (ORDER BY CASE WHEN tipo_formato = 'ELIMINACION_DIRECTA' THEN pg ELSE puntos END DESC,
                                           puntos DESC, (a_favor - en_contra) DESC, equipo) AS posicion,
               id_equipo, equipo, tag, pj, pg, pe, pp, a_favor, en_contra, (a_favor - en_contra) AS diferencia, puntos
          FROM vw_posiciones_torneo
         WHERE id_torneo = p_id_torneo
         ORDER BY posicion;
END sp_posiciones_torneo;
/

-- ---------------------------------------------------------------------------
-- GESTOR 5: SANCIONES Y PREMIACIÓN
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_sancion (
    p_id_sesion        IN  NUMBER,
    p_id_torneo        IN  NUMBER,
    p_id_jugador       IN  NUMBER,
    p_id_arbitro       IN  NUMBER,
    p_tipo             IN  VARCHAR2,
    p_motivo           IN  VARCHAR2,
    p_puntos_descuento IN  NUMBER,
    p_dias_suspension  IN  NUMBER,
    p_id               OUT NUMBER,
    p_resultado        OUT NUMBER,
    p_mensaje          OUT VARCHAR2
) IS
    v_estado_torneo  torneo.estado%TYPE;
    v_id_equipo      equipo.id_equipo%TYPE;
    v_nick           jugador.nickname%TYPE;
    v_estado_arbitro arbitro.estado%TYPE;
    v_puntos         NUMBER := 0;
    v_fin            DATE;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    BEGIN
        SELECT estado INTO v_estado_torneo FROM torneo WHERE id_torneo = p_id_torneo;
        SELECT estado INTO v_estado_arbitro FROM arbitro WHERE id_arbitro = p_id_arbitro;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20080, 'El torneo o el árbitro no existen.');
    END;
    IF v_estado_torneo NOT IN ('ABIERTO','EN_CURSO') THEN
        RAISE_APPLICATION_ERROR(-20081, 'Solo se sanciona en torneos abiertos o en curso.');
    END IF;
    IF v_estado_arbitro <> 'ACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20082, 'El árbitro que aplica la sanción está inactivo.');
    END IF;
    BEGIN
        SELECT i.id_equipo, j.nickname INTO v_id_equipo, v_nick
          FROM roster r
          JOIN inscripcion i ON i.id_inscripcion = r.id_inscripcion
          JOIN jugador j     ON j.id_jugador = r.id_jugador
         WHERE r.id_jugador = p_id_jugador
           AND i.id_torneo = p_id_torneo
           AND i.estado = 'CONFIRMADA';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20083, 'El jugador no está inscrito en este torneo.');
    END;
    IF p_motivo IS NULL OR LENGTH(TRIM(p_motivo)) < 10 THEN
        RAISE_APPLICATION_ERROR(-20084, 'Describa el motivo de la sanción (mínimo 10 caracteres).');
    END IF;
    IF p_tipo = 'DESCUENTO_PUNTOS' THEN
        IF NVL(p_puntos_descuento, 0) <= 0 THEN
            RAISE_APPLICATION_ERROR(-20085, 'Indique cuántos puntos se descuentan.');
        END IF;
        v_puntos := p_puntos_descuento;
    ELSIF p_tipo = 'SUSPENSION' THEN
        IF NVL(p_dias_suspension, 0) <= 0 THEN
            RAISE_APPLICATION_ERROR(-20086, 'Indique los días de suspensión.');
        END IF;
        v_fin := TRUNC(SYSDATE) + p_dias_suspension;
    END IF;

    p_id := seq_sancion.NEXTVAL;
    INSERT INTO sancion (id_sancion, id_torneo, id_jugador, id_arbitro, tipo, motivo,
                         puntos_descuento, fecha_sancion, fecha_fin_suspension, estado)
    VALUES (p_id, p_id_torneo, p_id_jugador, p_id_arbitro, p_tipo, TRIM(p_motivo),
            v_puntos, SYSDATE, v_fin, 'VIGENTE');
    -- La suspensión cambia el estado del jugador mediante TRG_SANCION_SUSPENDER
    IF v_puntos > 0 THEN
        sp_sumar_puntos(p_id_torneo, v_id_equipo, -v_puntos);
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Sanción (' || REPLACE(p_tipo, '_', ' ') || ') registrada a ' || v_nick ||
                 CASE WHEN v_puntos > 0 THEN '. Se descontaron ' || v_puntos || ' punto(s) a su equipo' END ||
                 CASE WHEN v_fin IS NOT NULL THEN '. Suspendido hasta el ' || TO_CHAR(v_fin, 'DD-MM-YYYY') END || '.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; p_id := NULL; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_registrar_sancion;
/

-- Jugadores inscritos en un torneo (para elegir a quién sancionar)
CREATE OR REPLACE PROCEDURE sp_jugadores_torneo (
    p_id_torneo IN  NUMBER,
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT j.id_jugador, j.nickname, j.nombres || ' ' || j.apellidos AS nombre, e.nombre AS equipo,
               fn_verificar_estado_jugador(j.id_jugador) AS estado_disciplinario
          FROM roster r
          JOIN inscripcion i ON i.id_inscripcion = r.id_inscripcion AND i.estado = 'CONFIRMADA'
          JOIN jugador j     ON j.id_jugador = r.id_jugador
          JOIN equipo e      ON e.id_equipo = i.id_equipo
         WHERE i.id_torneo = p_id_torneo
         ORDER BY e.nombre, j.nickname;
END sp_jugadores_torneo;
/

CREATE OR REPLACE PROCEDURE sp_anular_sancion (
    p_id_sesion  IN  NUMBER,
    p_id_sancion IN  NUMBER,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2
) IS
    v_s              sancion%ROWTYPE;
    v_estado_torneo  torneo.estado%TYPE;
    v_id_equipo      equipo.id_equipo%TYPE;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    SELECT * INTO v_s FROM sancion WHERE id_sancion = p_id_sancion FOR UPDATE;
    IF v_s.estado <> 'VIGENTE' THEN
        RAISE_APPLICATION_ERROR(-20087, 'Solo se pueden anular sanciones vigentes.');
    END IF;
    SELECT estado INTO v_estado_torneo FROM torneo WHERE id_torneo = v_s.id_torneo;
    IF v_s.puntos_descuento > 0 THEN
        IF v_estado_torneo = 'FINALIZADO' THEN
            RAISE_APPLICATION_ERROR(-20088, 'El torneo ya fue liquidado; no se pueden devolver los puntos.');
        END IF;
        SELECT i.id_equipo INTO v_id_equipo
          FROM roster r JOIN inscripcion i ON i.id_inscripcion = r.id_inscripcion
         WHERE r.id_jugador = v_s.id_jugador AND i.id_torneo = v_s.id_torneo AND i.estado = 'CONFIRMADA';
        sp_sumar_puntos(v_s.id_torneo, v_id_equipo, v_s.puntos_descuento);
    END IF;
    UPDATE sancion SET estado = 'ANULADA' WHERE id_sancion = p_id_sancion;
    -- Si ya no tiene suspensiones vigentes, el jugador vuelve a quedar activo
    IF v_s.tipo = 'SUSPENSION' AND fn_verificar_estado_jugador(v_s.id_jugador) = 'HABILITADO' THEN
        UPDATE jugador SET estado = 'ACTIVO' WHERE id_jugador = v_s.id_jugador AND estado = 'SANCIONADO';
    END IF;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Sanción anulada.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK; p_resultado := 0; p_mensaje := 'La sanción no existe.';
    WHEN OTHERS THEN
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_anular_sancion;
/

-- Recorre con cursor las suspensiones vencidas, las marca CUMPLIDA y rehabilita jugadores.
CREATE OR REPLACE PROCEDURE sp_procesar_sanciones_vencidas (
    p_id_sesion IN  NUMBER,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
    CURSOR cur_vencidas IS
        SELECT id_sancion, id_jugador
          FROM sancion
         WHERE tipo = 'SUSPENSION'
           AND estado = 'VIGENTE'
           AND fecha_fin_suspension < TRUNC(SYSDATE)
           FOR UPDATE OF estado;
    v_reg           cur_vencidas%ROWTYPE;
    v_cumplidas     NUMBER := 0;
    v_rehabilitados NUMBER := 0;
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    OPEN cur_vencidas;
    LOOP
        FETCH cur_vencidas INTO v_reg;
        EXIT WHEN cur_vencidas%NOTFOUND;
        UPDATE sancion SET estado = 'CUMPLIDA' WHERE CURRENT OF cur_vencidas;
        v_cumplidas := v_cumplidas + 1;
        IF fn_verificar_estado_jugador(v_reg.id_jugador) = 'HABILITADO' THEN
            UPDATE jugador SET estado = 'ACTIVO'
             WHERE id_jugador = v_reg.id_jugador AND estado = 'SANCIONADO';
            v_rehabilitados := v_rehabilitados + SQL%ROWCOUNT;
        END IF;
    END LOOP;
    CLOSE cur_vencidas;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Suspensiones cumplidas: ' || v_cumplidas || '. Jugadores rehabilitados: ' || v_rehabilitados || '.';
EXCEPTION
    WHEN OTHERS THEN
        IF cur_vencidas%ISOPEN THEN CLOSE cur_vencidas; END IF;
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_procesar_sanciones_vencidas;
/

CREATE OR REPLACE PROCEDURE sp_sancion_listar (
    p_id_torneo IN  NUMBER,          -- NULL = todas
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT s.id_sancion, t.nombre AS torneo, j.nickname, j.nombres || ' ' || j.apellidos AS jugador,
               a.nombres || ' ' || a.apellidos AS arbitro, s.tipo, s.motivo, s.puntos_descuento,
               TO_CHAR(s.fecha_sancion, 'YYYY-MM-DD') AS fecha_sancion,
               TO_CHAR(s.fecha_fin_suspension, 'YYYY-MM-DD') AS fecha_fin_suspension, s.estado
          FROM sancion s
          JOIN torneo t  ON t.id_torneo = s.id_torneo
          JOIN jugador j ON j.id_jugador = s.id_jugador
          JOIN arbitro a ON a.id_arbitro = s.id_arbitro
         WHERE p_id_torneo IS NULL OR s.id_torneo = p_id_torneo
         ORDER BY s.fecha_sancion DESC, s.id_sancion DESC;
END sp_sancion_listar;
/

-- Liquida premios: recorre la tabla de posiciones con cursor y reparte 50% / 30% / 20%.
CREATE OR REPLACE PROCEDURE sp_liquidar_premios (
    p_id_sesion IN  NUMBER,
    p_id_torneo IN  NUMBER,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) IS
    CURSOR cur_posiciones IS
        SELECT id_equipo, equipo
          FROM vw_posiciones_torneo
         WHERE id_torneo = p_id_torneo
         ORDER BY CASE WHEN tipo_formato = 'ELIMINACION_DIRECTA' THEN pg ELSE puntos END DESC,
                  puntos DESC, (a_favor - en_contra) DESC, equipo;
    v_pos        cur_posiciones%ROWTYPE;
    v_estado     torneo.estado%TYPE;
    v_premio     torneo.premio_total%TYPE;
    v_nombre     torneo.nombre%TYPE;
    v_pend       NUMBER;
    v_jugadas    NUMBER;
    v_posicion   PLS_INTEGER := 0;
    v_pct        NUMBER;
    v_monto      NUMBER;
    v_campeon    VARCHAR2(60);
BEGIN
    sp_validar_permiso(p_id_sesion, 'ADMIN,ORGANIZADOR');
    SELECT estado, premio_total, nombre INTO v_estado, v_premio, v_nombre
      FROM torneo WHERE id_torneo = p_id_torneo FOR UPDATE;
    IF v_estado <> 'EN_CURSO' THEN
        RAISE_APPLICATION_ERROR(-20090, 'Solo se liquidan torneos en curso (estado actual: ' || v_estado || ').');
    END IF;
    SELECT COUNT(CASE WHEN estado = 'PROGRAMADA' THEN 1 END), COUNT(CASE WHEN estado = 'JUGADA' THEN 1 END)
      INTO v_pend, v_jugadas
      FROM partida WHERE id_torneo = p_id_torneo;
    IF v_pend > 0 THEN
        RAISE_APPLICATION_ERROR(-20091, 'Quedan ' || v_pend || ' partida(s) por jugar.');
    END IF;
    IF v_jugadas = 0 THEN
        RAISE_APPLICATION_ERROR(-20092, 'El torneo no tiene partidas jugadas.');
    END IF;

    OPEN cur_posiciones;
    LOOP
        FETCH cur_posiciones INTO v_pos;
        EXIT WHEN cur_posiciones%NOTFOUND OR v_posicion >= 3;
        v_posicion := v_posicion + 1;
        v_pct := CASE v_posicion WHEN 1 THEN 0.5 WHEN 2 THEN 0.3 ELSE 0.2 END;
        v_monto := ROUND(v_premio * v_pct);
        INSERT INTO premiacion (id_premiacion, id_torneo, id_equipo, posicion, monto, fecha)
        VALUES (seq_premiacion.NEXTVAL, p_id_torneo, v_pos.id_equipo, v_posicion, v_monto, SYSDATE);
        IF v_posicion = 1 THEN
            v_campeon := v_pos.equipo;
        END IF;
    END LOOP;
    CLOSE cur_posiciones;

    UPDATE torneo SET estado = 'FINALIZADO' WHERE id_torneo = p_id_torneo;
    COMMIT;
    p_resultado := 1;
    p_mensaje := 'Torneo "' || v_nombre || '" finalizado. Campeón: ' || v_campeon ||
                 ' (' || fn_formato_monto(ROUND(v_premio * 0.5)) || '). Premios liquidados: ' || v_posicion || '.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK; p_resultado := 0; p_mensaje := 'El torneo no existe.';
    WHEN OTHERS THEN
        IF cur_posiciones%ISOPEN THEN CLOSE cur_posiciones; END IF;
        ROLLBACK; p_resultado := 0; p_mensaje := fn_mensaje_error(SQLERRM);
END sp_liquidar_premios;
/

CREATE OR REPLACE PROCEDURE sp_premiacion_listar (
    p_id_torneo IN  NUMBER,          -- NULL = todas
    p_cursor    OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT t.nombre AS torneo, pr.posicion, e.nombre AS equipo, pr.monto,
               TO_CHAR(pr.fecha, 'YYYY-MM-DD') AS fecha
          FROM premiacion pr
          JOIN torneo t ON t.id_torneo = pr.id_torneo
          JOIN equipo e ON e.id_equipo = pr.id_equipo
         WHERE p_id_torneo IS NULL OR pr.id_torneo = p_id_torneo
         ORDER BY t.fecha_inicio DESC, pr.posicion;
END sp_premiacion_listar;
/

/* ============================================================================
   7. REPORTES ESTRATÉGICOS (3) + RESUMEN DEL PANEL
   ============================================================================ */

-- REPORTE 1: Demanda y recaudación por videojuego
-- ¿Qué títulos atraen más equipos e ingresos? Apoya la planificación de la oferta de torneos.
CREATE OR REPLACE PROCEDURE sp_reporte_demanda_juego (
    p_anio   IN  NUMBER,             -- NULL = todos los años
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT v.id_videojuego, v.nombre AS videojuego, v.genero,
               COUNT(DISTINCT t.id_torneo) AS torneos,
               COUNT(i.id_inscripcion) AS equipos_inscritos,
               NVL(SUM(i.monto_pagado), 0) AS recaudacion,
               (SELECT NVL(SUM(tp.monto_aporte), 0)
                  FROM torneo_patrocinador tp
                  JOIN torneo t2 ON t2.id_torneo = tp.id_torneo
                 WHERE t2.id_videojuego = v.id_videojuego
                   AND t2.estado <> 'CANCELADO'
                   AND (p_anio IS NULL OR EXTRACT(YEAR FROM t2.fecha_inicio) = p_anio)) AS patrocinio,
               (SELECT COUNT(*)
                  FROM roster r
                  JOIN inscripcion i3 ON i3.id_inscripcion = r.id_inscripcion AND i3.estado = 'CONFIRMADA'
                  JOIN torneo t3      ON t3.id_torneo = i3.id_torneo
                 WHERE t3.id_videojuego = v.id_videojuego
                   AND t3.estado <> 'CANCELADO'
                   AND (p_anio IS NULL OR EXTRACT(YEAR FROM t3.fecha_inicio) = p_anio)) AS jugadores_inscritos,
               ROUND(COUNT(i.id_inscripcion) / NULLIF(COUNT(DISTINCT t.id_torneo), 0), 1) AS promedio_equipos_torneo
          FROM videojuego v
          LEFT JOIN torneo t      ON t.id_videojuego = v.id_videojuego
                                 AND t.estado <> 'CANCELADO'
                                 AND (p_anio IS NULL OR EXTRACT(YEAR FROM t.fecha_inicio) = p_anio)
          LEFT JOIN inscripcion i ON i.id_torneo = t.id_torneo AND i.estado = 'CONFIRMADA'
         GROUP BY v.id_videojuego, v.nombre, v.genero
         ORDER BY equipos_inscritos DESC, recaudacion DESC, v.nombre;
END sp_reporte_demanda_juego;
/

-- REPORTE 2: Ranking de jugadores MVP (ratio KDA, victorias y distinciones MVP)
-- Identifica talento para selecciones, premios individuales y scouting.
CREATE OR REPLACE PROCEDURE sp_reporte_ranking_mvp (
    p_top           IN  NUMBER,      -- cantidad de jugadores
    p_id_videojuego IN  NUMBER,      -- NULL = todos los juegos
    p_cursor        OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT j.id_jugador, j.nickname, j.nombres || ' ' || j.apellidos AS jugador,
               ea.nombre AS equipo_actual,
               COUNT(*) AS partidas,
               SUM(d.kills) AS kills, SUM(d.deaths) AS deaths, SUM(d.assists) AS assists,
               fn_calcular_ratio_kda(SUM(d.kills), SUM(d.deaths), SUM(d.assists)) AS kda,
               SUM(CASE WHEN p.id_ganador = i.id_equipo THEN 1 ELSE 0 END) AS victorias,
               ROUND(100 * SUM(CASE WHEN p.id_ganador = i.id_equipo THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_victorias,
               SUM(CASE WHEN d.es_mvp = 'S' THEN 1 ELSE 0 END) AS mvps
          FROM detalle_partida_jugador d
          JOIN partida p      ON p.id_partida = d.id_partida AND p.estado = 'JUGADA'
          JOIN torneo t       ON t.id_torneo = p.id_torneo
          JOIN roster r       ON r.id_jugador = d.id_jugador
          JOIN inscripcion i  ON i.id_inscripcion = r.id_inscripcion AND i.id_torneo = p.id_torneo
          JOIN jugador j      ON j.id_jugador = d.id_jugador
          LEFT JOIN equipo ea ON ea.id_equipo = j.id_equipo
         WHERE p_id_videojuego IS NULL OR t.id_videojuego = p_id_videojuego
         GROUP BY j.id_jugador, j.nickname, j.nombres, j.apellidos, ea.nombre
         ORDER BY kda DESC, mvps DESC, victorias DESC, j.nickname
         FETCH FIRST NVL(p_top, 10) ROWS ONLY;
END sp_reporte_ranking_mvp;
/

-- REPORTE 3: Ocupación de sedes y balance económico por torneo
-- % de cupos cubiertos vs. capacidad, e ingresos (inscripción + patrocinio) vs. premios.
CREATE OR REPLACE PROCEDURE sp_reporte_ocupacion_sedes (
    p_detalle OUT SYS_REFCURSOR,     -- un registro por torneo
    p_resumen OUT SYS_REFCURSOR      -- agregado por sede
) IS
BEGIN
    OPEN p_detalle FOR
        SELECT t.id_torneo, t.nombre AS torneo, s.nombre AS sede, s.modalidad, t.estado,
               TO_CHAR(t.fecha_inicio, 'YYYY-MM-DD') AS fecha_inicio,
               t.cupo_maximo, t.cupo_maximo - fn_validar_cupos_torneo(t.id_torneo) AS inscritos,
               ROUND(100 * (t.cupo_maximo - fn_validar_cupos_torneo(t.id_torneo)) / t.cupo_maximo, 1) AS pct_ocupacion,
               fn_recaudacion_torneo(t.id_torneo) AS recaudacion,
               fn_aporte_patrocinio(t.id_torneo) AS patrocinio,
               t.premio_total,
               fn_recaudacion_torneo(t.id_torneo) + fn_aporte_patrocinio(t.id_torneo) - t.premio_total AS balance
          FROM torneo t
          JOIN sede s ON s.id_sede = t.id_sede
         WHERE t.estado <> 'CANCELADO'
         ORDER BY t.fecha_inicio;

    OPEN p_resumen FOR
        SELECT s.nombre AS sede, s.comuna, s.modalidad, s.capacidad,
               COUNT(x.id_torneo) AS torneos,
               NVL(SUM(x.cupo_maximo), 0) AS cupos_ofrecidos,
               NVL(SUM(x.inscritos), 0) AS cupos_cubiertos,
               ROUND(100 * SUM(x.inscritos) / NULLIF(SUM(x.cupo_maximo), 0), 1) AS pct_ocupacion,
               NVL(SUM(x.balance), 0) AS balance
          FROM sede s
          LEFT JOIN (SELECT t.id_torneo, t.id_sede, t.cupo_maximo,
                            t.cupo_maximo - fn_validar_cupos_torneo(t.id_torneo) AS inscritos,
                            fn_recaudacion_torneo(t.id_torneo) + fn_aporte_patrocinio(t.id_torneo)
                              - t.premio_total AS balance
                       FROM torneo t
                      WHERE t.estado <> 'CANCELADO') x ON x.id_sede = s.id_sede
         GROUP BY s.id_sede, s.nombre, s.comuna, s.modalidad, s.capacidad
         ORDER BY pct_ocupacion DESC NULLS LAST, s.nombre;
END sp_reporte_ocupacion_sedes;
/

-- Indicadores generales para el panel de inicio
CREATE OR REPLACE PROCEDURE sp_resumen_panel (p_cursor OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_cursor FOR
        SELECT (SELECT COUNT(*) FROM torneo WHERE estado = 'ABIERTO')   AS torneos_abiertos,
               (SELECT COUNT(*) FROM torneo WHERE estado = 'EN_CURSO')  AS torneos_en_curso,
               (SELECT COUNT(*) FROM torneo WHERE estado = 'FINALIZADO') AS torneos_finalizados,
               (SELECT COUNT(*) FROM equipo WHERE estado = 'ACTIVO')    AS equipos,
               (SELECT COUNT(*) FROM jugador WHERE estado <> 'INACTIVO') AS jugadores,
               (SELECT COUNT(*) FROM partida WHERE estado = 'JUGADA')   AS partidas_jugadas,
               (SELECT COUNT(*) FROM partida WHERE estado = 'PROGRAMADA') AS partidas_pendientes,
               (SELECT COUNT(*) FROM sancion WHERE estado = 'VIGENTE')  AS sanciones_vigentes,
               (SELECT NVL(SUM(monto_pagado), 0) FROM inscripcion WHERE estado = 'CONFIRMADA') AS recaudacion_total,
               (SELECT NVL(SUM(monto), 0) FROM premiacion) AS premios_pagados
          FROM dual;
END sp_resumen_panel;
/

/* ============================================================================
   8. TRIGGERS DE MONITOREO Y CONTROL
   ============================================================================ */

-- T1. Impide que un jugador sancionado o inactivo integre una plantilla (BEFORE, :NEW)
CREATE OR REPLACE TRIGGER trg_bloquear_sancionado
BEFORE INSERT OR UPDATE OF id_jugador ON roster
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(20);
BEGIN
    v_estado := fn_verificar_estado_jugador(:NEW.id_jugador);
    IF v_estado <> 'HABILITADO' THEN
        RAISE_APPLICATION_ERROR(-20100, 'Bloqueado por control disciplinario: el jugador ' || :NEW.id_jugador ||
                                ' está ' || v_estado || ' y no puede integrar una plantilla.');
    END IF;
END trg_bloquear_sancionado;
/

-- T2. Historial de cambios de marcador y estado de las partidas (AFTER, :OLD / :NEW)
CREATE OR REPLACE TRIGGER trg_auditoria_marcadores
AFTER UPDATE OR DELETE ON partida
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(10);
BEGIN
    IF DELETING THEN
        v_operacion := 'DELETE';
    ELSE
        v_operacion := 'UPDATE';
    END IF;
    IF DELETING
       OR NVL(:OLD.puntaje_local, -1) <> NVL(:NEW.puntaje_local, -1)
       OR NVL(:OLD.puntaje_visita, -1) <> NVL(:NEW.puntaje_visita, -1)
       OR :OLD.estado <> :NEW.estado THEN
        INSERT INTO auditoria_marcador (id_auditoria, id_partida, operacion,
                                        puntaje_local_ant, puntaje_visita_ant,
                                        puntaje_local_nuevo, puntaje_visita_nuevo,
                                        estado_ant, estado_nuevo, usuario_app, usuario_bd, fecha)
        VALUES (seq_auditoria.NEXTVAL, :OLD.id_partida, v_operacion,
                :OLD.puntaje_local, :OLD.puntaje_visita,
                :NEW.puntaje_local, :NEW.puntaje_visita,
                :OLD.estado, :NEW.estado, fn_usuario_app, USER, SYSDATE);
    END IF;
END trg_auditoria_marcadores;
/

-- T3. Una vez finalizado o cancelado el torneo, sus partidas quedan protegidas
CREATE OR REPLACE TRIGGER trg_proteger_partidas
BEFORE UPDATE OR DELETE ON partida
FOR EACH ROW
DECLARE
    v_estado torneo.estado%TYPE;
BEGIN
    SELECT estado INTO v_estado FROM torneo WHERE id_torneo = :OLD.id_torneo;
    IF v_estado IN ('FINALIZADO','CANCELADO') THEN
        RAISE_APPLICATION_ERROR(-20101, 'El torneo está ' || v_estado || ': sus partidas no se pueden modificar.');
    END IF;
END trg_proteger_partidas;
/

-- T4. Al registrar una suspensión, el jugador pasa a SANCIONADO y se deja registro
CREATE OR REPLACE TRIGGER trg_sancion_suspender
AFTER INSERT ON sancion
FOR EACH ROW
BEGIN
    IF :NEW.tipo = 'SUSPENSION' THEN
        UPDATE jugador SET estado = 'SANCIONADO'
         WHERE id_jugador = :NEW.id_jugador AND estado = 'ACTIVO';
    END IF;
    INSERT INTO auditoria_general (id_auditoria, tabla, operacion, id_registro, detalle, usuario_app, usuario_bd, fecha)
    VALUES (seq_auditoria_gen.NEXTVAL, 'SANCION', 'INSERT', :NEW.id_sancion,
            'Jugador ' || :NEW.id_jugador || ' - ' || :NEW.tipo ||
            CASE WHEN :NEW.puntos_descuento > 0 THEN ' (-' || :NEW.puntos_descuento || ' pts)' END ||
            CASE WHEN :NEW.fecha_fin_suspension IS NOT NULL
                 THEN ' hasta ' || TO_CHAR(:NEW.fecha_fin_suspension, 'DD-MM-YYYY') END ||
            ': ' || SUBSTR(:NEW.motivo, 1, 300),
            fn_usuario_app, USER, SYSDATE);
END trg_sancion_suspender;
/

-- T5. Normaliza y valida datos del jugador (RUT, edad) y registra cambios de estado
CREATE OR REPLACE TRIGGER trg_validar_jugador
BEFORE INSERT OR UPDATE ON jugador
FOR EACH ROW
BEGIN
    :NEW.rut       := UPPER(REPLACE(REPLACE(TRIM(:NEW.rut), '.', ''), ' ', ''));
    :NEW.nombres   := TRIM(:NEW.nombres);
    :NEW.apellidos := TRIM(:NEW.apellidos);
    :NEW.nickname  := TRIM(:NEW.nickname);
    :NEW.email     := LOWER(TRIM(:NEW.email));
    IF fn_validar_rut(:NEW.rut) = 0 THEN
        RAISE_APPLICATION_ERROR(-20102, 'RUT de jugador inválido: ' || :NEW.rut || '.');
    END IF;
    IF :NEW.fecha_nacimiento > SYSDATE OR fn_calcular_edad(:NEW.fecha_nacimiento) < 13 THEN
        RAISE_APPLICATION_ERROR(-20103, 'El jugador debe tener al menos 13 años.');
    END IF;
    IF UPDATING AND :OLD.estado <> :NEW.estado THEN
        INSERT INTO auditoria_general (id_auditoria, tabla, operacion, id_registro, detalle, usuario_app, usuario_bd, fecha)
        VALUES (seq_auditoria_gen.NEXTVAL, 'JUGADOR', 'ESTADO', :NEW.id_jugador,
                :NEW.nickname || ': ' || :OLD.estado || ' -> ' || :NEW.estado, fn_usuario_app, USER, SYSDATE);
    END IF;
END trg_validar_jugador;
/

-- T6. Controla las transiciones válidas del estado de un torneo y las registra
CREATE OR REPLACE TRIGGER trg_torneo_estado
BEFORE UPDATE OF estado ON torneo
FOR EACH ROW
BEGIN
    IF :OLD.estado <> :NEW.estado THEN
        IF NOT ((:OLD.estado = 'ABIERTO'  AND :NEW.estado IN ('EN_CURSO','CANCELADO')) OR
                (:OLD.estado = 'EN_CURSO' AND :NEW.estado IN ('FINALIZADO','CANCELADO'))) THEN
            RAISE_APPLICATION_ERROR(-20104, 'Transición de estado no permitida: ' || :OLD.estado || ' -> ' || :NEW.estado || '.');
        END IF;
        INSERT INTO auditoria_general (id_auditoria, tabla, operacion, id_registro, detalle, usuario_app, usuario_bd, fecha)
        VALUES (seq_auditoria_gen.NEXTVAL, 'TORNEO', 'ESTADO', :NEW.id_torneo,
                :NEW.nombre || ': ' || :OLD.estado || ' -> ' || :NEW.estado, fn_usuario_app, USER, SYSDATE);
    END IF;
END trg_torneo_estado;
/

-- T7. Monitoreo de cuentas: altas, bajas, cambios de perfil/estado/contraseña
CREATE OR REPLACE TRIGGER trg_auditoria_usuario
AFTER INSERT OR UPDATE OR DELETE ON usuario
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(10);
    v_detalle   VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_detalle := 'Alta de usuario ' || :NEW.username || ' (perfil ' || :NEW.id_perfil || ')';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_detalle := 'Baja de usuario ' || :OLD.username;
    ELSE
        v_operacion := 'UPDATE';
        IF :OLD.id_perfil <> :NEW.id_perfil THEN
            v_detalle := v_detalle || 'perfil ' || :OLD.id_perfil || ' -> ' || :NEW.id_perfil || '; ';
        END IF;
        IF :OLD.estado <> :NEW.estado THEN
            v_detalle := v_detalle || 'estado ' || :OLD.estado || ' -> ' || :NEW.estado || '; ';
        END IF;
        IF :OLD.password_hash <> :NEW.password_hash THEN
            v_detalle := v_detalle || 'cambio de contraseña; ';
        END IF;
        IF NVL(:OLD.email, '-') <> NVL(:NEW.email, '-') THEN
            v_detalle := v_detalle || 'email ' || :OLD.email || ' -> ' || :NEW.email || '; ';
        END IF;
        IF v_detalle IS NOT NULL THEN
            v_detalle := 'Usuario ' || :NEW.username || ': ' || v_detalle;
        END IF;
    END IF;
    IF v_detalle IS NOT NULL THEN
        INSERT INTO auditoria_general (id_auditoria, tabla, operacion, id_registro, detalle, usuario_app, usuario_bd, fecha)
        VALUES (seq_auditoria_gen.NEXTVAL, 'USUARIO', v_operacion, NVL(:NEW.id_usuario, :OLD.id_usuario),
                SUBSTR(v_detalle, 1, 500), fn_usuario_app, USER, SYSDATE);
    END IF;
END trg_auditoria_usuario;
/

-- T8. Registro de inscripciones y retiros de equipos
CREATE OR REPLACE TRIGGER trg_auditoria_inscripcion
AFTER INSERT OR UPDATE OF estado ON inscripcion
FOR EACH ROW
BEGIN
    IF INSERTING OR :OLD.estado <> :NEW.estado THEN
        INSERT INTO auditoria_general (id_auditoria, tabla, operacion, id_registro, detalle, usuario_app, usuario_bd, fecha)
        VALUES (seq_auditoria_gen.NEXTVAL, 'INSCRIPCION',
                CASE WHEN :OLD.id_inscripcion IS NULL THEN 'INSERT' ELSE 'ESTADO' END,
                :NEW.id_inscripcion,
                'Torneo ' || :NEW.id_torneo || ', equipo ' || :NEW.id_equipo || ': ' ||
                NVL(:OLD.estado, 'NUEVA') || ' -> ' || :NEW.estado || ' ($' || :NEW.monto_pagado || ')',
                fn_usuario_app, USER, SYSDATE);
    END IF;
END trg_auditoria_inscripcion;
/

/* ============================================================================
   9. DATOS DE PRUEBA
   Catálogos con INSERT directo (usando secuencias). Torneos, inscripciones,
   fixtures, resultados, sanciones y premiaciones se generan invocando los
   mismos procedimientos almacenados que usa la aplicación.
   Contraseñas de prueba:
     admin / Admin2026!        organizador / Orga2026!      arbitro.rojas / Arbitro2026!
     cap.<tag> / Capitan2026!  (ej. cap.tlt para Talca Titans)
   ============================================================================ */

-- Perfiles
INSERT INTO perfil VALUES (seq_perfil.NEXTVAL, 'ADMIN', 'Administrador General', 'Acceso total, gestión de usuarios y auditoría');
INSERT INTO perfil VALUES (seq_perfil.NEXTVAL, 'ORGANIZADOR', 'Organizador / Árbitro', 'Gestión de torneos, fixture, resultados y sanciones');
INSERT INTO perfil VALUES (seq_perfil.NEXTVAL, 'CAPITAN', 'Capitán de Equipo', 'Inscripción de plantilla y consulta de estadísticas');


-- Usuarios (contraseñas con hash SHA-256 mediante FN_HASH_PASSWORD)
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'admin', fn_hash_password('admin', 'Admin2026!'), 'Administrador del Sistema', 'admin@esportsmaule.cl', 1, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'organizador', fn_hash_password('organizador', 'Orga2026!'), 'Daniela Muñoz Soto', 'dmunoz@esportsmaule.cl', 2, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'arbitro.rojas', fn_hash_password('arbitro.rojas', 'Arbitro2026!'), 'Felipe Rojas Contreras', 'frojas@esportsmaule.cl', 2, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.tlt', fn_hash_password('cap.tlt', 'Capitan2026!'), 'Maximiliano Castillo Cortés', 'cap.tlt@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.lrw', fn_hash_password('cap.lrw', 'Capitan2026!'), 'Fernanda Cáceres Contreras', 'cap.lrw@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.cpx', fn_hash_password('cap.cpx', 'Capitan2026!'), 'Lucas Figueroa Riquelme', 'cap.cpx@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.mrv', fn_hash_password('cap.mrv', 'Capitan2026!'), 'Constanza Álvarez Vergara', 'cap.mrv@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.lnx', fn_hash_password('cap.lnx', 'Capitan2026!'), 'Constanza Carrasco Rivera', 'cap.lnx@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.cqs', fn_hash_password('cap.cqs', 'Capitan2026!'), 'Catalina Torres González', 'cap.cqs@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.ctw', fn_hash_password('cap.ctw', 'Capitan2026!'), 'Agustina Soto Silva', 'cap.ctw@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.sjv', fn_hash_password('cap.sjv', 'Capitan2026!'), 'Franco Contreras Sánchez', 'cap.sjv@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.mlh', fn_hash_password('cap.mlh', 'Capitan2026!'), 'Benjamín Carrasco Castillo', 'cap.mlh@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.prp', fn_hash_password('cap.prp', 'Capitan2026!'), 'Felipe Pizarro Araya', 'cap.prp@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.ucd', fn_hash_password('cap.ucd', 'Capitan2026!'), 'Emilio Reyes Castro', 'cap.ucd@esportsmaule.cl', 3, 'ACTIVO');
INSERT INTO usuario (id_usuario, username, password_hash, nombre_completo, email, id_perfil, estado) VALUES (seq_usuario.NEXTVAL, 'cap.tnk', fn_hash_password('cap.tnk', 'Capitan2026!'), 'Fernanda Bravo Pérez', 'cap.tnk@esportsmaule.cl', 3, 'ACTIVO');

-- Videojuegos
INSERT INTO videojuego VALUES (seq_videojuego.NEXTVAL, 'League of Legends', 'MOBA', 'Riot Games', 5, 'ACTIVO');
INSERT INTO videojuego VALUES (seq_videojuego.NEXTVAL, 'Valorant', 'Shooter táctico', 'Riot Games', 5, 'ACTIVO');
INSERT INTO videojuego VALUES (seq_videojuego.NEXTVAL, 'Counter-Strike 2', 'Shooter táctico', 'Valve', 5, 'ACTIVO');
INSERT INTO videojuego VALUES (seq_videojuego.NEXTVAL, 'Rocket League', 'Deportes / Vehículos', 'Psyonix', 3, 'ACTIVO');
INSERT INTO videojuego VALUES (seq_videojuego.NEXTVAL, 'EA Sports FC', 'Deportes / Fútbol', 'EA Sports', 1, 'ACTIVO');
INSERT INTO videojuego VALUES (seq_videojuego.NEXTVAL, 'Clash Royale', 'Estrategia en tiempo real', 'Supercell', 1, 'ACTIVO');
INSERT INTO videojuego VALUES (seq_videojuego.NEXTVAL, 'Dota 2', 'MOBA', 'Valve', 5, 'INACTIVO');

-- Plataformas
INSERT INTO plataforma VALUES (seq_plataforma.NEXTVAL, 'PC', 'Varios', 'Computadores de escritorio y notebooks gamer');
INSERT INTO plataforma VALUES (seq_plataforma.NEXTVAL, 'PlayStation 5', 'Sony', 'Consola de sobremesa');
INSERT INTO plataforma VALUES (seq_plataforma.NEXTVAL, 'Xbox Series X|S', 'Microsoft', 'Consola de sobremesa');
INSERT INTO plataforma VALUES (seq_plataforma.NEXTVAL, 'Nintendo Switch', 'Nintendo', 'Consola híbrida');
INSERT INTO plataforma VALUES (seq_plataforma.NEXTVAL, 'Móvil (Android / iOS)', 'Varios', 'Teléfonos y tablets');

-- Sedes / modalidades (Región del Maule)
INSERT INTO sede VALUES (seq_sede.NEXTVAL, 'Gimnasio Campus San Miguel UCM', 'Av. San Miguel 3605', 'Talca', 400, 'HIBRIDA', 'ACTIVO');
INSERT INTO sede VALUES (seq_sede.NEXTVAL, 'Arena Gamer Talca', '2 Norte 845', 'Talca', 80, 'PRESENCIAL', 'ACTIVO');
INSERT INTO sede VALUES (seq_sede.NEXTVAL, 'Pixel LAN Center Curicó', 'Merced 520', 'Curicó', 60, 'PRESENCIAL', 'ACTIVO');
INSERT INTO sede VALUES (seq_sede.NEXTVAL, 'Centro Juvenil Linares', 'Independencia 410', 'Linares', 60, 'PRESENCIAL', 'ACTIVO');
INSERT INTO sede VALUES (seq_sede.NEXTVAL, 'Plataforma Online Maule (Discord)', 'Servidor oficial de la liga', 'Online', 5000, 'ONLINE', 'ACTIVO');

-- Patrocinadores
INSERT INTO patrocinador VALUES (seq_patrocinador.NEXTVAL, '77616475-5', 'Tecnología del Maule SpA', 'Tecnología', 'contacto@tecmaule.cl', '+56 71 2234567');
INSERT INTO patrocinador VALUES (seq_patrocinador.NEXTVAL, '76813859-1', 'Bebidas Energéticas Lircay Ltda.', 'Alimentos y bebidas', 'marketing@lircayenergy.cl', '+56 71 2456789');
INSERT INTO patrocinador VALUES (seq_patrocinador.NEXTVAL, '76288041-5', 'CyberHardware Chile SpA', 'Retail tecnológico', 'ventas@cyberhw.cl', '+56 2 29876543');
INSERT INTO patrocinador VALUES (seq_patrocinador.NEXTVAL, '77269058-4', 'FibraSur Telecomunicaciones S.A.', 'Telecomunicaciones', 'empresas@fibrasur.cl', '+56 600 3601200');
INSERT INTO patrocinador VALUES (seq_patrocinador.NEXTVAL, '77228403-9', 'Pizzería La Cancha Talca', 'Gastronomía', 'pedidos@lacanchatalca.cl', '+56 9 87654321');

-- Categorías / divisiones
INSERT INTO categoria VALUES (seq_categoria.NEXTVAL, 'Abierta', 'Todo competidor desde 14 años', 14, NULL);
INSERT INTO categoria VALUES (seq_categoria.NEXTVAL, 'Universitaria', 'Estudiantes de educación superior', 18, NULL);
INSERT INTO categoria VALUES (seq_categoria.NEXTVAL, 'Juvenil Sub-18', 'Competidores escolares', 13, 17);
INSERT INTO categoria VALUES (seq_categoria.NEXTVAL, 'Master +30', 'Competidores de 30 años o más', 30, NULL);

-- Formatos de torneo
INSERT INTO formato_torneo VALUES (seq_formato.NEXTVAL, 'Eliminación directa Bo1', 'ELIMINACION_DIRECTA', 3, 1, 'Llaves a partido único; el perdedor queda eliminado');
INSERT INTO formato_torneo VALUES (seq_formato.NEXTVAL, 'Liga todos contra todos (3-1-0)', 'TODOS_CONTRA_TODOS', 3, 1, 'Una rueda; 3 puntos por victoria y 1 por empate');
INSERT INTO formato_torneo VALUES (seq_formato.NEXTVAL, 'Liga express (2-1-0)', 'TODOS_CONTRA_TODOS', 2, 1, 'Una rueda corta; 2 puntos por victoria');

-- Equipos (el capitán de cada equipo es el usuario cap.<tag>)
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Talca Titans', 'TLT', 'Talca', DATE '2021-03-14', 4, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Lircay Wolves', 'LRW', 'Talca', DATE '2022-08-02', 5, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Curicó Phoenix', 'CPX', 'Curicó', DATE '2020-11-20', 6, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Maule Ravens', 'MRV', 'Talca', DATE '2023-01-09', 7, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Linares Lynx', 'LNX', 'Linares', DATE '2022-05-30', 8, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Cauquenes Storm', 'CQS', 'Cauquenes', DATE '2023-07-17', 9, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Constitución Waves', 'CTW', 'Constitución', DATE '2021-09-25', 10, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'San Javier Vipers', 'SJV', 'San Javier', DATE '2024-02-11', 11, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Molina Hawks', 'MLH', 'Molina', DATE '2022-12-03', 12, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Parral Pumas', 'PRP', 'Parral', DATE '2023-10-21', 13, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'UCM Dragons', 'UCD', 'Talca', DATE '2020-04-06', 14, 'ACTIVO');
INSERT INTO equipo VALUES (seq_equipo.NEXTVAL, 'Teno Knights', 'TNK', 'Teno', DATE '2024-06-15', 15, 'ACTIVO');

-- Jugadores (7 por equipo: 5 titulares habituales + 2 suplentes). Validados por TRG_VALIDAR_JUGADOR
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22555906-6', 'Emilia', 'Sepúlveda Cáceres', 'Lircay3', DATE '2005-05-01', 'esepulveda.lircay3@mail.cl', 1, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22637406-K', 'Nicolás', 'Fernández Vásquez', 'GhostJr', DATE '2005-09-16', 'nfernandez.ghostjr@mail.cl', 1, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21172595-8', 'Agustina', 'Pizarro Herrera', 'FuryJr', DATE '2005-08-17', 'apizarro.furyjr@mail.cl', 1, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22008605-4', 'Franco', 'Hernández Martínez', 'Blaze3', DATE '2004-11-04', 'fhernandez.blaze3@mail.cl', 1, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21828232-6', 'Gaspar', 'Sepúlveda Ramírez', 'OnyxCL', DATE '2006-12-15', 'gsepulveda.onyxcl@mail.cl', 1, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21713140-5', 'Javier', 'Araya Jara', 'NyxZz', DATE '2000-09-26', 'jaraya.nyxzz@mail.cl', 1, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19628490-7', 'Gaspar', 'Pizarro Vásquez', 'Titan99', DATE '2000-01-02', 'gpizarro.titan99@mail.cl', 1, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21036624-5', 'Renato', 'Fernández Herrera', 'PulseMx', DATE '1999-05-23', 'rfernandez.pulsemx@mail.cl', 2, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22845386-2', 'Gaspar', 'Vásquez Jara', 'Puma', DATE '2000-06-15', 'gvasquez.puma@mail.cl', 2, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19269673-9', 'Lucas', 'Cortés Araya', 'SableX', DATE '2002-12-16', 'lcortes.sablex@mail.cl', 2, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22843998-3', 'Gaspar', 'Gutiérrez Contreras', 'Titan3', DATE '2002-03-15', 'ggutierrez.titan3@mail.cl', 2, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19506751-1', 'Sofía', 'Sánchez Rivera', 'GlitchCL', DATE '2005-04-08', 'ssanchez.glitchcl@mail.cl', 2, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21445553-6', 'Javier', 'Flores Bravo', 'CobraX', DATE '1996-06-22', 'jflores.cobrax@mail.cl', 2, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22674184-4', 'Gaspar', 'Martínez Núñez', 'OnyxGG', DATE '2005-03-20', 'gmartinez.onyxgg@mail.cl', 2, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21129456-6', 'Diego', 'Soto Álvarez', 'PumaX', DATE '1998-10-10', 'dsoto.pumax@mail.cl', 3, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19215483-9', 'Joaquín', 'Herrera López', 'Orion', DATE '1997-07-03', 'jherrera.orion@mail.cl', 3, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '20273691-2', 'Simón', 'Reyes Muñoz', 'NovaTK', DATE '2003-06-22', 'sreyes.novatk@mail.cl', 3, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21179417-8', 'Matías', 'Carrasco Fernández', 'Draco_cl', DATE '1998-03-19', 'mcarrasco.draco_cl@mail.cl', 3, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19143246-0', 'Camila', 'Fernández Figueroa', 'OnyxZz', DATE '1997-09-13', 'cfernandez.onyxzz@mail.cl', 3, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21029375-2', 'Josefa', 'Rojas Cáceres', 'Glitch', DATE '2003-11-07', 'jrojas.glitch@mail.cl', 3, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21773369-3', 'Benjamín', 'Martínez Cáceres', 'Ember7', DATE '2004-03-06', 'bmartinez.ember7@mail.cl', 3, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19785168-6', 'Ignacio', 'Flores Vásquez', 'GlitchJr', DATE '1997-07-10', 'iflores.glitchjr@mail.cl', 4, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21178249-8', 'Tomás', 'Fernández Carrasco', 'Bolt99', DATE '2003-03-11', 'tfernandez.bolt99@mail.cl', 4, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22685202-6', 'Matías', 'Herrera Flores', 'Raven7', DATE '1999-01-03', 'mherrera.raven7@mail.cl', 4, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21882145-6', 'Sebastián', 'Álvarez Núñez', 'NovaMx', DATE '1998-06-18', 'salvarez.novamx@mail.cl', 4, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21382538-0', 'Javier', 'Fuentes Silva', 'Wraith3', DATE '2000-09-25', 'jfuentes.wraith3@mail.cl', 4, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22278017-9', 'Franco', 'Espinoza Vergara', 'HexZz', DATE '2004-03-04', 'fespinoza.hexzz@mail.cl', 4, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19778023-1', 'Trinidad', 'Morales Contreras', 'Cóndor', DATE '2001-12-26', 'tmorales.condor@mail.cl', 4, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19676922-6', 'Matías', 'Cortés Castillo', 'Hex_cl', DATE '1997-05-11', 'mcortes.hex_cl@mail.cl', 5, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '20299893-3', 'Florencia', 'González Álvarez', 'Shadow', DATE '1997-04-01', 'fgonzalez.shadow@mail.cl', 5, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19159429-0', 'Constanza', 'Castillo Fernández', 'TalonZz', DATE '2006-12-20', 'ccastillo.talonzz@mail.cl', 5, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21879236-7', 'Sebastián', 'Figueroa Fuentes', 'TalonGG', DATE '2002-11-04', 'sfigueroa.talongg@mail.cl', 5, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '20831826-8', 'Bastián', 'Araya Castro', 'KairoMx', DATE '1996-12-23', 'baraya.kairomx@mail.cl', 5, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21456209-K', 'Diego', 'Tapia Espinoza', 'MaquiCL', DATE '2000-07-11', 'dtapia.maquicl@mail.cl', 5, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19514579-2', 'Javier', 'Tapia López', 'Quake', DATE '1997-03-20', 'jtapia.quake@mail.cl', 5, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19529731-2', 'Catalina', 'Herrera Reyes', 'Halcón99', DATE '1996-07-19', 'cherrera.halcon99@mail.cl', 6, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21277201-1', 'Ignacio', 'Castro Torres', 'BoltZz', DATE '1999-03-06', 'icastro.boltzz@mail.cl', 6, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21008414-2', 'Amanda', 'Araya Sepúlveda', 'Onyx', DATE '1996-05-18', 'aaraya.onyx@mail.cl', 6, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21727191-6', 'Sebastián', 'Martínez Bravo', 'NeonCL', DATE '1998-09-02', 'smartinez.neoncl@mail.cl', 6, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22525951-8', 'Bastián', 'Araya Tapia', 'SagaTK', DATE '2001-01-22', 'baraya.sagatk@mail.cl', 6, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22314186-2', 'Martina', 'Ramírez Díaz', 'VortexX', DATE '2002-12-12', 'mramirez.vortexx@mail.cl', 6, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21301815-9', 'Fernanda', 'Tapia López', 'JinxMx', DATE '2003-11-15', 'ftapia.jinxmx@mail.cl', 6, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21033636-2', 'Alonso', 'Rivera Valenzuela', 'TitanX', DATE '2006-07-05', 'arivera.titanx@mail.cl', 7, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '20563610-2', 'Nicolás', 'Herrera Álvarez', 'FrostZz', DATE '1998-02-10', 'nherrera.frostzz@mail.cl', 7, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19187246-0', 'Tomás', 'Martínez Contreras', 'Zephyr3', DATE '2005-05-19', 'tmartinez.zephyr3@mail.cl', 7, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19358767-4', 'Ignacio', 'Núñez Herrera', 'HalcónZz', DATE '1998-09-04', 'inunez.halconzz@mail.cl', 7, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21777740-2', 'Amanda', 'Tapia Jara', 'Fury99', DATE '1996-12-19', 'atapia.fury99@mail.cl', 7, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19039631-2', 'Agustín', 'Espinoza Núñez', 'PixelJr', DATE '1999-12-21', 'aespinoza.pixeljr@mail.cl', 7, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19123785-4', 'Simón', 'Ramírez Vásquez', 'CobraTK', DATE '1998-12-17', 'sramirez.cobratk@mail.cl', 7, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22216248-3', 'Catalina', 'Morales Muñoz', 'StormTK', DATE '2006-12-21', 'cmorales.stormtk@mail.cl', 8, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21558603-0', 'Constanza', 'Pérez Gutiérrez', 'Drako7', DATE '2004-03-20', 'cperez.drako7@mail.cl', 8, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21587695-0', 'Antonia', 'Castillo Carrasco', 'Raven3', DATE '1997-07-09', 'acastillo.raven3@mail.cl', 8, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22475581-3', 'Matías', 'Reyes Ramírez', 'PulseCL', DATE '2004-09-08', 'mreyes.pulsecl@mail.cl', 8, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '20308732-2', 'Lucas', 'Rivera Reyes', 'GhostCL', DATE '1997-08-25', 'lrivera.ghostcl@mail.cl', 8, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22804676-0', 'Martina', 'Morales Castillo', 'RuneTK', DATE '2004-06-11', 'mmorales.runetk@mail.cl', 8, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22629830-4', 'Alonso', 'Carrasco Pizarro', 'VoltX', DATE '1999-08-08', 'acarrasco.voltx@mail.cl', 8, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22116491-1', 'Nicolás', 'Reyes Álvarez', 'NeonJr', DATE '1999-03-15', 'nreyes.neonjr@mail.cl', 9, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22528165-3', 'Gabriel', 'Martínez Vásquez', 'HexMx', DATE '1997-06-09', 'gmartinez.hexmx@mail.cl', 9, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21354262-1', 'Tomás', 'Sepúlveda Núñez', 'Saga99', DATE '1999-06-05', 'tsepulveda.saga99@mail.cl', 9, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21305752-9', 'Tomás', 'Espinoza Vergara', 'KryptoZz', DATE '2002-07-01', 'tespinoza.kryptozz@mail.cl', 9, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21654937-6', 'Alonso', 'Álvarez Tapia', 'RavenZz', DATE '2003-11-28', 'aalvarez.ravenzz@mail.cl', 9, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19251789-3', 'Alonso', 'Núñez Herrera', 'ZephyrJr', DATE '2001-11-11', 'anunez.zephyrjr@mail.cl', 9, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21428298-4', 'Gabriel', 'Rodríguez González', 'HexTK', DATE '2000-03-11', 'grodriguez.hextk@mail.cl', 9, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22270593-2', 'Felipe', 'Ramírez Tapia', 'StormZz', DATE '2000-06-01', 'framirez.stormzz@mail.cl', 10, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21904278-7', 'Emilia', 'Cortés Flores', 'WraithZz', DATE '2001-02-18', 'ecortes.wraithzz@mail.cl', 10, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21823366-K', 'Sofía', 'Contreras Sepúlveda', 'Astro7', DATE '2003-04-20', 'scontreras.astro7@mail.cl', 10, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21345276-2', 'Javiera', 'Soto Vergara', 'Bolt3', DATE '2004-11-19', 'jsoto.bolt3@mail.cl', 10, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19970368-4', 'Sofía', 'Flores Álvarez', 'FrostX', DATE '2004-12-17', 'sflores.frostx@mail.cl', 10, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22704662-7', 'Gaspar', 'Tapia Reyes', 'Volt_cl', DATE '2003-05-16', 'gtapia.volt_cl@mail.cl', 10, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '20535901-K', 'Tomás', 'Rojas Cáceres', 'PulseX', DATE '1996-08-26', 'trojas.pulsex@mail.cl', 10, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19227279-3', 'Emilia', 'López Gutiérrez', 'MaquiJr', DATE '2000-04-19', 'elopez.maquijr@mail.cl', 11, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19380500-0', 'Martín', 'Cáceres Cortés', 'CóndorTK', DATE '2000-08-20', 'mcaceres.condortk@mail.cl', 11, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21357378-0', 'Bastián', 'Figueroa Castillo', 'PumaMx', DATE '2001-03-03', 'bfigueroa.pumamx@mail.cl', 11, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19901119-7', 'Agustín', 'Araya Herrera', 'EmberJr', DATE '2006-02-20', 'aaraya.emberjr@mail.cl', 11, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22320552-6', 'Martina', 'Fuentes Vásquez', 'VortexTK', DATE '1998-09-07', 'mfuentes.vortextk@mail.cl', 11, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '20644175-5', 'Emilio', 'Carrasco Martínez', 'QuakeZz', DATE '2001-06-21', 'ecarrasco.quakezz@mail.cl', 11, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22056565-3', 'Gabriel', 'Núñez López', 'Echo_cl', DATE '2004-12-05', 'gnunez.echo_cl@mail.cl', 11, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21906444-6', 'Isidora', 'Rojas Flores', 'DrakoX', DATE '1998-05-18', 'irojas.drakox@mail.cl', 12, 'IGL', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '20736094-5', 'Lucas', 'Morales Rodríguez', 'Copihue', DATE '1998-11-05', 'lmorales.copihue@mail.cl', 12, 'Duelista', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21853780-4', 'Gaspar', 'Núñez Muñoz', 'VortexMx', DATE '2004-02-15', 'gnunez.vortexmx@mail.cl', 12, 'Soporte', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19243979-5', 'Joaquín', 'Castillo Sepúlveda', 'LircayTK', DATE '1996-08-01', 'jcastillo.lircaytk@mail.cl', 12, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21782497-4', 'Fernanda', 'Tapia Muñoz', 'NexusTK', DATE '1999-02-14', 'ftapia.nexustk@mail.cl', 12, 'Iniciador', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21247566-1', 'Agustín', 'Torres Hernández', 'PumaGG', DATE '1999-06-06', 'atorres.pumagg@mail.cl', 12, 'Suplente', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22097111-2', 'Felipe', 'Vásquez Fernández', 'Jinx3', DATE '1999-05-21', 'fvasquez.jinx3@mail.cl', 12, 'Suplente', 'ACTIVO');
-- Agentes libres (sin equipo)
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '22685576-9', 'Lucas', 'Jara Figueroa', 'ZenitCL', DATE '2001-04-11', 'zenitcl@mail.cl', NULL, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '19482961-2', 'Martín', 'Reyes Riquelme', 'CopihueX', DATE '2000-04-16', 'copihuex@mail.cl', NULL, 'Flex', 'ACTIVO');
INSERT INTO jugador VALUES (seq_jugador.NEXTVAL, '21718717-6', 'Cristóbal', 'Vásquez Muñoz', 'QuakeX', DATE '2002-05-15', 'quakex@mail.cl', NULL, 'Flex', 'ACTIVO');

-- Árbitros / staff (el primero está vinculado al usuario arbitro.rojas)
INSERT INTO arbitro VALUES (seq_arbitro.NEXTVAL, '15341197-2', 'Felipe', 'Rojas Contreras', 'frojas@esportsmaule.cl', '+56 9 50638980', 'ARBITRO', 3, 'ACTIVO');
INSERT INTO arbitro VALUES (seq_arbitro.NEXTVAL, '15997796-K', 'Carolina', 'Bustos Leiva', 'cbustos@esportsmaule.cl', '+56 9 84964892', 'ARBITRO', NULL, 'ACTIVO');
INSERT INTO arbitro VALUES (seq_arbitro.NEXTVAL, '15860471-K', 'Rodrigo', 'Salazar Mella', 'rsalazar@esportsmaule.cl', '+56 9 68326492', 'ARBITRO', NULL, 'ACTIVO');
INSERT INTO arbitro VALUES (seq_arbitro.NEXTVAL, '14971102-3', 'Paula', 'Ortega Quiroz', 'portega@esportsmaule.cl', '+56 9 82760629', 'STAFF', NULL, 'ACTIVO');
INSERT INTO arbitro VALUES (seq_arbitro.NEXTVAL, '13157187-9', 'Ignacio', 'Lagos Paredes', 'ilagos@esportsmaule.cl', '+56 9 57211707', 'CASTER', NULL, 'ACTIVO');
INSERT INTO arbitro VALUES (seq_arbitro.NEXTVAL, '18654947-3', 'Marcelo', 'Vidal Ponce', 'mvidal@esportsmaule.cl', '+56 9 59663152', 'ARBITRO', NULL, 'INACTIVO');
COMMIT;

-- ---------------------------------------------------------------------------
-- Torneos generados con los procedimientos del sistema (gestores 1 al 5)
-- ---------------------------------------------------------------------------
DECLARE
    c_admin   CONSTANT NUMBER := 1;   -- usuario admin
    c_org     CONSTANT NUMBER := 2;   -- usuario organizador
    v_res     NUMBER;
    v_msg     VARCHAR2(4000);
    v_id      NUMBER;
    v_t1 NUMBER; v_t2 NUMBER; v_t3 NUMBER; v_t4 NUMBER; v_t5 NUMBER; v_t6 NUMBER; v_t7 NUMBER;
    v_jug     NUMBER;

    PROCEDURE ok (p_ctx IN VARCHAR2) IS
    BEGIN
        IF v_res <> 1 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Carga de datos - ' || p_ctx || ': ' || v_msg);
        END IF;
        DBMS_OUTPUT.PUT_LINE('OK  ' || p_ctx || ' -> ' || v_msg);
    END ok;

    -- Construye la plantilla 'id:S;id:N' con los primeros jugadores del equipo
    FUNCTION plantilla (p_id_equipo IN NUMBER, p_titulares IN NUMBER, p_suplentes IN NUMBER) RETURN VARCHAR2 IS
        CURSOR cur_j IS SELECT id_jugador FROM jugador
                         WHERE id_equipo = p_id_equipo AND estado = 'ACTIVO' ORDER BY id_jugador;
        v_txt VARCHAR2(400);
        v_n   PLS_INTEGER := 0;
    BEGIN
        FOR r IN cur_j LOOP
            v_n := v_n + 1;
            EXIT WHEN v_n > p_titulares + p_suplentes;
            v_txt := v_txt || r.id_jugador || ':' || CASE WHEN v_n <= p_titulares THEN 'S' ELSE 'N' END || ';';
        END LOOP;
        RETURN v_txt;
    END plantilla;

    PROCEDURE inscribir (p_id_torneo IN NUMBER, p_id_equipo IN NUMBER, p_tit IN NUMBER, p_sup IN NUMBER) IS
    BEGIN
        sp_inscribir_equipo(c_admin, p_id_torneo, p_id_equipo, plantilla(p_id_equipo, p_tit, p_sup), v_id, v_res, v_msg);
        ok('Inscripción torneo ' || p_id_torneo || ' equipo ' || p_id_equipo);
    END inscribir;

    -- Estadísticas aleatorias de los titulares de ambos equipos ('id:k:d:a;...')
    FUNCTION estadisticas (p_id_partida IN NUMBER, p_id_ganador IN NUMBER) RETURN VARCHAR2 IS
        CURSOR cur_t IS
            SELECT r.id_jugador, i.id_equipo
              FROM partida p
              JOIN inscripcion i ON i.id_torneo = p.id_torneo
                                AND i.id_equipo IN (p.id_equipo_local, p.id_equipo_visita)
              JOIN roster r      ON r.id_inscripcion = i.id_inscripcion AND r.es_titular = 'S'
             WHERE p.id_partida = p_id_partida;
        v_txt VARCHAR2(4000);
        v_bono NUMBER;
    BEGIN
        FOR r IN cur_t LOOP
            v_bono := CASE WHEN r.id_equipo = p_id_ganador THEN 1 ELSE 0 END;
            v_txt := v_txt || r.id_jugador || ':' ||
                     TRUNC(DBMS_RANDOM.VALUE(1, 12) + 4 * v_bono) || ':' ||
                     TRUNC(DBMS_RANDOM.VALUE(1, 9) + 3 * (1 - v_bono)) || ':' ||
                     TRUNC(DBMS_RANDOM.VALUE(0, 11) + 2 * v_bono) || ';';
        END LOOP;
        RETURN v_txt;
    END estadisticas;

    -- Juega hasta p_max partidas pendientes del torneo (en orden de ronda)
    PROCEDURE jugar (p_id_torneo IN NUMBER, p_max IN NUMBER) IS
        v_pid    NUMBER;
        v_loc    NUMBER;
        v_vis    NUMBER;
        v_juego  VARCHAR2(60);
        v_gana_l BOOLEAN;
        v_pl     NUMBER;
        v_pv     NUMBER;
        v_win    NUMBER;
        v_lose   NUMBER;
        v_n      PLS_INTEGER := 0;
    BEGIN
        SELECT v.nombre INTO v_juego FROM torneo t JOIN videojuego v ON v.id_videojuego = t.id_videojuego
         WHERE t.id_torneo = p_id_torneo;
        LOOP
            EXIT WHEN v_n >= p_max;
            BEGIN
                SELECT id_partida, id_equipo_local, id_equipo_visita INTO v_pid, v_loc, v_vis
                  FROM partida
                 WHERE id_torneo = p_id_torneo AND estado = 'PROGRAMADA'
                 ORDER BY ronda, fecha_hora, id_partida
                 FETCH FIRST 1 ROW ONLY;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN EXIT;
            END;
            -- "Fuerza" fija por equipo para que la tabla tenga sentido
            v_gana_l := DBMS_RANDOM.VALUE(0, 1) < 0.5 + (MOD(v_loc * 37, 10) - MOD(v_vis * 37, 10)) * 0.04;
            IF v_juego IN ('Valorant', 'Counter-Strike 2') THEN
                v_win := 13; v_lose := TRUNC(DBMS_RANDOM.VALUE(3, 12));
            ELSIF v_juego = 'League of Legends' THEN
                v_win := 1; v_lose := 0;
            ELSE
                v_win := TRUNC(DBMS_RANDOM.VALUE(2, 6)); v_lose := TRUNC(DBMS_RANDOM.VALUE(0, v_win));
            END IF;
            IF v_gana_l THEN v_pl := v_win; v_pv := v_lose; ELSE v_pl := v_lose; v_pv := v_win; END IF;
            sp_registrar_resultado(c_org, v_pid, v_pl, v_pv,
                                   estadisticas(v_pid, CASE WHEN v_gana_l THEN v_loc ELSE v_vis END), v_res, v_msg);
            ok('Resultado partida ' || v_pid);
            v_n := v_n + 1;
        END LOOP;
    END jugar;

    -- Primer jugador titular de un equipo en un torneo
    FUNCTION titular (p_id_torneo IN NUMBER, p_id_equipo IN NUMBER) RETURN NUMBER IS
        v NUMBER;
    BEGIN
        SELECT MIN(r.id_jugador) INTO v
          FROM roster r JOIN inscripcion i ON i.id_inscripcion = r.id_inscripcion
         WHERE i.id_torneo = p_id_torneo AND i.id_equipo = p_id_equipo AND r.es_titular = 'S';
        RETURN v;
    END titular;
BEGIN
    DBMS_RANDOM.SEED(2026);
    BEGIN DBMS_SESSION.SET_IDENTIFIER('carga_inicial'); EXCEPTION WHEN OTHERS THEN NULL; END;

    -- T1: Copa Maule LoL Apertura 2026 (eliminación directa, 8 equipos) -> FINALIZADO
    sp_abrir_torneo(c_org, 'Copa Maule LoL Apertura 2026', 1, 1, 1, 1, 2, DATE '2026-04-11', DATE '2026-04-13',
                    8, 25000, 400000, '1:250000;2:150000', v_t1, v_res, v_msg);
    ok('Apertura T1');
    FOR e IN 1 .. 8 LOOP inscribir(v_t1, e, 5, 2); END LOOP;
    sp_generar_fixture(c_org, v_t1, v_res, v_msg); ok('Fixture T1');
    jugar(v_t1, 99);
    sp_liquidar_premios(c_org, v_t1, v_res, v_msg); ok('Premiación T1');

    -- T2: Liga Valorant Talca 2026 (todos contra todos, 5 equipos con descanso) -> FINALIZADO
    sp_abrir_torneo(c_org, 'Liga Valorant Talca 2026', 2, 1, 2, 2, 1, DATE '2026-06-06', DATE '2026-07-11',
                    6, 20000, 300000, '3:200000', v_t2, v_res, v_msg);
    ok('Apertura T2');
    inscribir(v_t2, 2, 5, 1); inscribir(v_t2, 4, 5, 2); inscribir(v_t2, 6, 5, 0);
    inscribir(v_t2, 9, 5, 1); inscribir(v_t2, 11, 5, 2);
    sp_generar_fixture(c_org, v_t2, v_res, v_msg); ok('Fixture T2');
    jugar(v_t2, 6);
    sp_registrar_sancion(c_org, v_t2, titular(v_t2, 4), 2, 'DESCUENTO_PUNTOS',
                         'Lenguaje ofensivo reiterado en el chat de la partida hacia el rival', 2, NULL, v_id, v_res, v_msg);
    ok('Sanción descuento T2');
    sp_registrar_sancion(c_org, v_t2, titular(v_t2, 9), 1, 'AMONESTACION',
                         'Llegada 15 minutos tarde al check-in del equipo', NULL, NULL, v_id, v_res, v_msg);
    ok('Amonestación T2');
    jugar(v_t2, 99);
    sp_liquidar_premios(c_org, v_t2, v_res, v_msg); ok('Premiación T2');

    -- T3: Rocket League Cup Curicó 2026 (eliminación, 6 equipos -> BYE en semifinal) -> FINALIZADO
    sp_abrir_torneo(c_org, 'Rocket League Cup Curicó 2026', 4, 2, 3, 1, 1, DATE '2026-09-19', DATE '2026-09-20',
                    8, 15000, 180000, '4:100000;5:60000', v_t3, v_res, v_msg);
    ok('Apertura T3');
    inscribir(v_t3, 3, 3, 1); inscribir(v_t3, 5, 3, 1); inscribir(v_t3, 7, 3, 0);
    inscribir(v_t3, 10, 3, 1); inscribir(v_t3, 12, 3, 0); inscribir(v_t3, 1, 3, 1);
    sp_generar_fixture(c_org, v_t3, v_res, v_msg); ok('Fixture T3');
    jugar(v_t3, 99);
    sp_liquidar_premios(c_org, v_t3, v_res, v_msg); ok('Premiación T3');

    -- T4: Torneo CS2 Primavera UCM 2026 (liga, 4 equipos) -> EN CURSO con 3 de 6 partidas jugadas
    sp_abrir_torneo(c_org, 'Torneo CS2 Primavera UCM 2026', 3, 1, 1, 2, 2, DATE '2026-11-20', DATE '2026-12-05',
                    6, 20000, 350000, '1:200000;3:120000', v_t4, v_res, v_msg);
    ok('Apertura T4');
    inscribir(v_t4, 1, 5, 2); inscribir(v_t4, 3, 5, 1); inscribir(v_t4, 8, 5, 2); inscribir(v_t4, 11, 5, 1);
    sp_generar_fixture(c_org, v_t4, v_res, v_msg); ok('Fixture T4');
    jugar(v_t4, 3);
    -- Suspensión vigente: este jugador queda bloqueado para nuevas inscripciones (demo del trigger)
    v_jug := titular(v_t4, 8);
    sp_registrar_sancion(c_org, v_t4, v_jug, 1, 'SUSPENSION',
                         'Abandono intencional de la partida y conducta antideportiva con el árbitro', NULL, 14,
                         v_id, v_res, v_msg);
    ok('Suspensión T4');

    -- T5: Copa EA Sports FC Online Maule (eliminación, online, 1 vs 1) -> ABIERTO
    sp_abrir_torneo(c_org, 'Copa EA Sports FC Online Maule', 5, 2, 5, 1, 1, DATE '2026-12-12', DATE '2026-12-13',
                    16, 5000, 100000, '2:80000', v_t5, v_res, v_msg);
    ok('Apertura T5');
    inscribir(v_t5, 2, 1, 0); inscribir(v_t5, 5, 1, 0); inscribir(v_t5, 7, 1, 0);
    inscribir(v_t5, 9, 1, 0); inscribir(v_t5, 12, 1, 0);

    -- T6: Liga LoL Clausura Maule 2026 (liga express) -> ABIERTO, listo para demo de inscripción y fixture
    sp_abrir_torneo(c_org, 'Liga LoL Clausura Maule 2026', 1, 1, 4, 3, 1, DATE '2026-12-14', DATE '2026-12-20',
                    8, 25000, 500000, '1:300000;4:150000', v_t6, v_res, v_msg);
    ok('Apertura T6');
    inscribir(v_t6, 4, 5, 2); inscribir(v_t6, 6, 5, 1); inscribir(v_t6, 10, 5, 2);

    -- T7: torneo cancelado por baja convocatoria (demuestra control de transición de estados)
    sp_abrir_torneo(c_org, 'Clash Royale Express Primavera', 6, 5, 5, 1, 1, DATE '2026-10-03', DATE '2026-10-03',
                    16, 3000, 60000, NULL, v_t7, v_res, v_msg);
    ok('Apertura T7');
    inscribir(v_t7, 11, 1, 0);
    sp_torneo_cancelar(c_org, v_t7, v_res, v_msg); ok('Cancelación T7');

    -- Fechas históricas coherentes para los torneos ya disputados
    UPDATE torneo t SET fecha_creacion = t.fecha_inicio - 45 WHERE t.fecha_inicio < SYSDATE;
    UPDATE torneo t SET fecha_creacion = SYSDATE - 20 WHERE t.fecha_inicio >= SYSDATE;
    UPDATE inscripcion i
       SET fecha_inscripcion = (SELECT t.fecha_inicio - 12 + MOD(i.id_inscripcion, 9) FROM torneo t
                                 WHERE t.id_torneo = i.id_torneo)
     WHERE i.id_torneo IN (v_t1, v_t2, v_t3, v_t4, v_t7);
    UPDATE premiacion pr
       SET fecha = (SELECT t.fecha_fin FROM torneo t WHERE t.id_torneo = pr.id_torneo);
    UPDATE sancion s SET fecha_sancion = DATE '2026-06-20' WHERE s.id_torneo = v_t2;
    COMMIT;
    BEGIN DBMS_SESSION.SET_IDENTIFIER(NULL); EXCEPTION WHEN OTHERS THEN NULL; END;
    DBMS_OUTPUT.PUT_LINE('Carga de datos de prueba finalizada correctamente.');
END;
/

-- Verificación rápida
SELECT estado, COUNT(*) AS torneos FROM torneo GROUP BY estado ORDER BY estado;
SELECT object_type, COUNT(*) AS cantidad, SUM(CASE WHEN status = 'INVALID' THEN 1 ELSE 0 END) AS invalidos
  FROM user_objects
 WHERE object_type IN ('TABLE','SEQUENCE','FUNCTION','PROCEDURE','TRIGGER','VIEW')
 GROUP BY object_type ORDER BY object_type;

