<?php
require 'config.php';
require 'lib/db.php';
require 'lib/auth.php';
auth_required();

$where = array("h.status IN ('new','candidate','approved','sent','still_online')");
if (!empty($_GET['catalog_no'])) {
    $where[] = "r.catalog_no = '" . db_esc($_GET['catalog_no']) . "'";
}
if (!empty($_GET['status'])) {
    $where = array("h.status = '" . db_esc($_GET['status']) . "'");   // FIXME: drops catalog filter
}
$page   = isset($_GET['p']) ? max(1, (int)$_GET['p']) : 1;
$offset = ($page - 1) * 50;

$hits = db_all("
    SELECT h.id, h.url, h.found_title, h.meta_score, h.fp_confidence, h.status, h.pre_release,
           h.first_seen, t.title, t.mix_name, r.catalog_no, a.name AS artist, ho.domain
      FROM hit h
      JOIN track t     ON t.id = h.track_id
      JOIN `release` r ON r.id = t.release_id
      JOIN artist a    ON a.id = r.artist_id
      JOIN host ho     ON ho.id = h.host_id
     WHERE " . implode(' AND ', $where) . "
     ORDER BY h.pre_release DESC, h.first_seen DESC
     LIMIT $offset, 50");

$title = 'Treffer';
include 'templates/header.tpl.php';
include 'templates/hits.tpl.php';
include 'templates/footer.tpl.php';
