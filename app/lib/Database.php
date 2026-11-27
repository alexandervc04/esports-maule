<?php
/**
 * Capa de acceso a datos (OCI8).
 *
 * La aplicación NO ejecuta SQL de negocio: solo invoca procedimientos almacenados
 * de Oracle. Toda la lógica (validaciones, transacciones, cálculos, auditoría)
 * reside en la capa de servicios de la base de datos (PL/SQL).
 *
 *  - Database::cursor()    -> procedimientos de lectura que devuelven SYS_REFCURSOR
 *  - Database::cursores()  -> procedimientos con varios SYS_REFCURSOR de salida
 *  - Database::ejecutar()  -> procedimientos de escritura (p_resultado / p_mensaje)
 *  - Database::llamar()    -> llamada genérica con parámetros OUT con nombre
 */
class Database
{
    private static $conn = null;

    public static function conexion()
    {
        if (self::$conn === null) {
            if (!function_exists('oci_connect')) {
                throw new RuntimeException('La extensión OCI8 de PHP no está habilitada (ver README).');
            }
            $c = @oci_connect(DB_USER, DB_PASS, DB_DSN, 'AL32UTF8');
            if (!$c) {
                $e = oci_error();
                throw new RuntimeException('No se pudo conectar a Oracle: ' . ($e['message'] ?? 'error desconocido'));
            }
            // Formatos de sesión para que fechas y números viajen sin ambigüedad
            $st = oci_parse($c, "ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD' NLS_NUMERIC_CHARACTERS = '.,'");
            oci_execute($st);
            oci_free_statement($st);
            // Usuario de la app visible para los triggers de auditoría (SYS_CONTEXT CLIENT_IDENTIFIER)
            if (!empty($_SESSION['usuario']['username'])) {
                oci_set_client_identifier($c, $_SESSION['usuario']['username']);
            }
            self::$conn = $c;
        }
        return self::$conn;
    }

    private static function validarNombre($proc)
    {
        if (!preg_match('/^sp_[a-z0-9_]+$/', $proc)) {
            throw new InvalidArgumentException("Nombre de procedimiento inválido: $proc");
        }
    }

    private static function normalizar($v)
    {
        if ($v === '' || $v === null) {
            return null;
        }
        return is_bool($v) ? ($v ? 'S' : 'N') : (string)$v;
    }

    private static function lanzarError($st)
    {
        $e = oci_error($st);
        throw new RuntimeException($e['message'] ?? 'Error al ejecutar en Oracle');
    }

    /** Procedimiento de lectura: parámetros IN + un SYS_REFCURSOR de salida al final. */
    public static function cursor($proc, array $params = [])
    {
        return self::cursores($proc, $params, 1)[0];
    }

    /** Procedimiento con N cursores de salida al final de la firma. */
    public static function cursores($proc, array $params, $n)
    {
        self::validarNombre($proc);
        $c = self::conexion();
        $in = array_values(array_map([self::class, 'normalizar'], $params));
        $ph = [];
        foreach ($in as $i => $_) {
            $ph[] = ":p$i";
        }
        for ($k = 0; $k < $n; $k++) {
            $ph[] = ":cur$k";
        }
        $st = oci_parse($c, "BEGIN $proc(" . implode(', ', $ph) . "); END;");
        foreach ($in as $i => $_) {
            oci_bind_by_name($st, ":p$i", $in[$i], 4000);
        }
        $curs = [];
        for ($k = 0; $k < $n; $k++) {
            $curs[$k] = oci_new_cursor($c);
            oci_bind_by_name($st, ":cur$k", $curs[$k], -1, OCI_B_CURSOR);
        }
        if (!@oci_execute($st)) {
            self::lanzarError($st);
        }
        $resultados = [];
        foreach ($curs as $k => $cur) {
            oci_execute($cur);
            $filas = [];
            oci_fetch_all($cur, $filas, 0, -1, OCI_FETCHSTATEMENT_BY_ROW | OCI_ASSOC | OCI_RETURN_NULLS);
            $resultados[$k] = array_map(function ($f) {
                return array_change_key_case($f, CASE_LOWER);
            }, $filas);
            oci_free_statement($cur);
        }
        oci_free_statement($st);
        return $resultados;
    }

    /**
     * Procedimiento de escritura con la convención del proyecto:
     *   (p_id_sesion, ...parámetros..., [p_id OUT], p_resultado OUT, p_mensaje OUT)
     * Devuelve ['ok' => bool, 'mensaje' => string, 'id' => ?int]
     */
    public static function ejecutar($proc, array $params, $retornaId = false)
    {
        $outs = $retornaId ? ['id' => 20, 'resultado' => 10, 'mensaje' => 4000]
                           : ['resultado' => 10, 'mensaje' => 4000];
        $r = self::llamar($proc, $params, $outs);
        return [
            'ok'      => (int)$r['resultado'] === 1,
            'mensaje' => $r['mensaje'] ?? '',
            'id'      => $r['id'] ?? null,
        ];
    }

    /** Llamada genérica: parámetros IN posicionales seguidos de OUT con nombre => largo. */
    public static function llamar($proc, array $params, array $outs)
    {
        self::validarNombre($proc);
        $c = self::conexion();
        $in = array_values(array_map([self::class, 'normalizar'], $params));
        $ph = [];
        foreach ($in as $i => $_) {
            $ph[] = ":p$i";
        }
        foreach ($outs as $nombre => $_) {
            $ph[] = ":o_$nombre";
        }
        $st = oci_parse($c, "BEGIN $proc(" . implode(', ', $ph) . "); END;");
        foreach ($in as $i => $_) {
            oci_bind_by_name($st, ":p$i", $in[$i], 4000);
        }
        $valores = [];
        foreach ($outs as $nombre => $largo) {
            $valores[$nombre] = null;
            oci_bind_by_name($st, ":o_$nombre", $valores[$nombre], $largo);
        }
        if (!@oci_execute($st)) {
            self::lanzarError($st);
        }
        oci_free_statement($st);
        return $valores;
    }
}
