<?php
/**
 * Bulk actions on hits (AJAX, JSON response).
 *
 * STATUS r340: only 'false_positive' and 'ignore' update the DB.
 * 'approve' and 'verify' are NOT wired - see Takedown.php / agfp.py
 * FIXME: no CSRF token (spec 8)
 */
chdir('..');
require 'config.php';
require 'lib/db.php';
require 'lib/auth.php';
require 'lib/Takedown.php';

header('Content-Type: application/json; charset=utf-8');

if (empty($_SESSION['ag_user'])) {
    echo json_encode(array('ok' => false, 'msg' => 'Nicht angemeldet'));
    exit;
}

$action = isset($_POST['action']) ? $_POST['action'] : '';
$ids    = isset($_POST['ids']) ? array_map('intval', (array)$_POST['ids']) : array();
$ids    = array_filter($ids);

if (!$ids) {
    echo json_encode(array('ok' => false, 'msg' => 'Keine Treffer ausgewählt'));
    exit;
}
$in   = implode(',', $ids);
$user = db_esc($_SESSION['ag_user']);

switch ($action) {
    case 'false_positive':
    case 'ignore':
        $status = $action == 'ignore' ? 'ignored' : 'false_positive';
        db_query("UPDATE hit SET status = '$status', reviewed_by = '$user' WHERE id IN ($in)");
        echo json_encode(array('ok' => true, 'msg' => mysql_affected_rows() . ' Treffer aktualisiert'));
        break;

    case 'approve':
        // TODO: four-eyes check - reviewer must differ from whoever set 'candidate'
        $td = new Takedown();
        $notices = $td->createNotices($ids, $_SESSION['ag_user']);   // throws - not implemented
        echo json_encode(array('ok' => true, 'msg' => count($notices) . ' Notices erstellt'));
        break;

    case 'verify':
        // idea: exec('python2.6 ../fingerprint/agfp.py match ' . $sample) - needs sample download first
        echo json_encode(array('ok' => false, 'msg' => 'Fingerprint-Prüfung noch nicht verfügbar'));
        break;

    default:
        echo json_encode(array('ok' => false, 'msg' => 'Unbekannte Aktion'));
}
