<?php
/**
 * Minimal DB helper. TODO: migrate to PDO before production (security debt, spec 8).
 */

function db_connect()
{
    static $link = null;
    if ($link === null) {
        $link = mysql_connect(DB_HOST, DB_USER, DB_PASS);
        if (!$link) {
            die('DB connection failed: ' . mysql_error());
        }
        mysql_select_db(DB_NAME, $link);
        mysql_set_charset('utf8', $link);
    }
    return $link;
}

function db_esc($s)
{
    return mysql_real_escape_string($s, db_connect());
}

function db_query($sql)
{
    $res = mysql_query($sql, db_connect());
    if ($res === false) {
        trigger_error('SQL error: ' . mysql_error() . ' in: ' . $sql, E_USER_WARNING);
    }
    return $res;
}

function db_all($sql)
{
    $rows = array();
    $res  = db_query($sql);
    if ($res) {
        while ($r = mysql_fetch_assoc($res)) {
            $rows[] = $r;
        }
    }
    return $rows;
}

function db_one($sql)
{
    $rows = db_all($sql);
    return $rows ? $rows[0] : null;
}

function h($s)
{
    return htmlspecialchars($s, ENT_QUOTES, 'UTF-8');
}
