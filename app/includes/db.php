<?php
require_once __DIR__ . '/../config/database.php';

function db_connect() {
    static $conn = null;
    if ($conn) return $conn;

    if (!function_exists('oci_connect')) {
        throw new RuntimeException('OCI8 NO ESTA HABILITADO EN PHP. REVISA README.md Y test_connection.php.');
    }

    $conn = @oci_connect(DB_USERNAME, DB_PASSWORD, DB_CONNECTION_STRING, DB_CHARSET);
    if (!$conn) {
        $e = oci_error();
        throw new RuntimeException('ERROR DE CONEXION ORACLE: ' . ($e['message'] ?? 'DESCONOCIDO'));
    }
    return $conn;
}

function oracle_error_message($resource = null): string {
    $e = oci_error($resource);
    $msg = $e['message'] ?? 'ERROR ORACLE DESCONOCIDO';
    return trim(preg_replace('/\s+/', ' ', $msg));
}

function oracle_run(string $sql, array $params = [], array $inout = []): array {
    $conn = db_connect();
    $stid = @oci_parse($conn, $sql);
    if (!$stid) throw new RuntimeException(oracle_error_message($conn));

    $vars = [];
    foreach ($params as $name => $value) {
        $vars[$name] = $value;
        $len = in_array($name, $inout, true) ? 4000 : 4000;
        if (!@oci_bind_by_name($stid, ':' . $name, $vars[$name], $len)) {
            throw new RuntimeException(oracle_error_message($stid));
        }
    }

    if (!@oci_execute($stid)) {
        $msg = oracle_error_message($stid);
        @oci_free_statement($stid);
        throw new RuntimeException($msg);
    }
    @oci_free_statement($stid);
    return $vars;
}

function oracle_cursor(string $procedure, array $params = []): array {
    $conn = db_connect();
    $parts = [];
    foreach (array_keys($params) as $name) $parts[] = ':' . $name;
    $parts[] = ':P_CURSOR';
    $sql = 'BEGIN ' . $procedure . '(' . implode(', ', $parts) . '); END;';

    $stid = @oci_parse($conn, $sql);
    if (!$stid) throw new RuntimeException(oracle_error_message($conn));

    $vars = [];
    foreach ($params as $name => $value) {
        $vars[$name] = $value;
        @oci_bind_by_name($stid, ':' . $name, $vars[$name], 4000);
    }

    $cursor = oci_new_cursor($conn);
    @oci_bind_by_name($stid, ':P_CURSOR', $cursor, -1, OCI_B_CURSOR);

    if (!@oci_execute($stid)) throw new RuntimeException(oracle_error_message($stid));
    if (!@oci_execute($cursor)) throw new RuntimeException(oracle_error_message($cursor));

    $rows = [];
    while (($row = oci_fetch_assoc($cursor)) !== false) {
        $rows[] = $row;
    }
    @oci_free_statement($cursor);
    @oci_free_statement($stid);
    return $rows;
}

function oracle_query(string $sql, array $params = []): array {
    $conn = db_connect();
    $stid = @oci_parse($conn, $sql);
    if (!$stid) throw new RuntimeException(oracle_error_message($conn));
    $vars = [];
    foreach ($params as $name => $value) {
        $vars[$name] = $value;
        @oci_bind_by_name($stid, ':' . $name, $vars[$name], 4000);
    }
    if (!@oci_execute($stid)) throw new RuntimeException(oracle_error_message($stid));
    $rows=[];
    while (($row=oci_fetch_assoc($stid))!==false) $rows[]=$row;
    @oci_free_statement($stid);
    return $rows;
}
