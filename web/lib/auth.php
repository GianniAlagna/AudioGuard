<?php
session_start();

function auth_required()
{
    if (empty($_SESSION['ag_user'])) {
        header('Location: index.php');
        exit;
    }
}

function auth_login($user, $pass)
{
    // FIXME: shared password, no per-user accounts, no brute-force protection
    if (AG_PASSWORD_SHA1 !== '' && sha1($pass) === AG_PASSWORD_SHA1) {
        session_regenerate_id(true);
        $_SESSION['ag_user'] = preg_replace('/[^a-z0-9_.-]/i', '', $user);
        return true;
    }
    return false;
}
