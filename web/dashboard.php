<?php
require 'config.php';
require 'lib/db.php';
require 'lib/auth.php';
auth_required();

$kpi = db_one("
    SELECT COUNT(*)                                       AS hits_total,
           SUM(status = 'new' OR status = 'candidate')    AS to_review,
           SUM(status = 'sent')                           AS sent,
           SUM(status = 'removed')                        AS removed,
           SUM(pre_release = 1)                           AS leaks
      FROM hit");
$kpi['removal_rate'] = ($kpi['sent'] + $kpi['removed']) > 0
    ? round(100 * $kpi['removed'] / ($kpi['sent'] + $kpi['removed']))
    : 0;

$top_releases = db_all("
    SELECT r.catalog_no, r.title, a.name AS artist, COUNT(h.id) AS hits
      FROM hit h
      JOIN track t     ON t.id = h.track_id
      JOIN `release` r ON r.id = t.release_id
      JOIN artist a    ON a.id = r.artist_id
     GROUP BY r.id
     ORDER BY hits DESC
     LIMIT 10");

$top_hosts = db_all("
    SELECT ho.domain, ho.country, COUNT(h.id) AS hits,
           SUM(h.status = 'removed') AS removed
      FROM hit h JOIN host ho ON ho.id = h.host_id
     GROUP BY ho.id ORDER BY hits DESC LIMIT 10");

$jobs = db_all("
    SELECT s.name, j.started_at, j.finished_at, j.queries, j.hits_new, j.error
      FROM scan_job j JOIN source s ON s.id = j.source_id
     ORDER BY j.id DESC LIMIT 5");

$title = 'Dashboard';
include 'templates/header.tpl.php';
?>
<div class="kpis">
  <div class="kpi"><span><?php echo (int)$kpi['hits_total']; ?></span>Treffer total</div>
  <div class="kpi warn"><span><?php echo (int)$kpi['to_review']; ?></span>zu prüfen</div>
  <div class="kpi"><span><?php echo (int)$kpi['sent']; ?></span>Notices offen</div>
  <div class="kpi ok"><span><?php echo $kpi['removal_rate']; ?>%</span>Removal Rate</div>
  <div class="kpi alert"><span><?php echo (int)$kpi['leaks']; ?></span>Pre-Release Leaks</div>
</div>

<div class="col">
  <h3>Top Releases (Treffer)</h3>
  <table class="grid">
    <tr><th>Kat.-Nr.</th><th>Artist</th><th>Release</th><th>Treffer</th></tr>
    <?php foreach ($top_releases as $r): ?>
    <tr>
      <td><?php echo h($r['catalog_no']); ?></td>
      <td><?php echo h($r['artist']); ?></td>
      <td><a href="hits.php?catalog_no=<?php echo urlencode($r['catalog_no']); ?>"><?php echo h($r['title']); ?></a></td>
      <td class="num"><?php echo (int)$r['hits']; ?></td>
    </tr>
    <?php endforeach; ?>
  </table>
</div>

<div class="col">
  <h3>Top Hoster</h3>
  <table class="grid">
    <tr><th>Domain</th><th>Land</th><th>Treffer</th><th>Entfernt</th></tr>
    <?php foreach ($top_hosts as $ho): ?>
    <tr>
      <td><?php echo h($ho['domain']); ?></td>
      <td><?php echo h($ho['country'] ? $ho['country'] : '?'); ?></td>
      <td class="num"><?php echo (int)$ho['hits']; ?></td>
      <td class="num"><?php echo (int)$ho['removed']; ?></td>
    </tr>
    <?php endforeach; ?>
  </table>
</div>

<div class="clear"></div>
<h3>Trend (30 Tage)</h3>
<!-- TODO: chart - evaluate Google Chart Tools vs. Highcharts (license?) -->
<div id="chart-trend" class="placeholder">Chart folgt</div>

<h3>Letzte Scan-Jobs</h3>
<table class="grid">
  <tr><th>Quelle</th><th>Start</th><th>Ende</th><th>Queries</th><th>Neu</th><th>Fehler</th></tr>
  <?php foreach ($jobs as $j): ?>
  <tr<?php if ($j['error']) echo ' class="err"'; ?>>
    <td><?php echo h($j['name']); ?></td>
    <td><?php echo h($j['started_at']); ?></td>
    <td><?php echo h($j['finished_at'] ? $j['finished_at'] : 'läuft...'); ?></td>
    <td class="num"><?php echo (int)$j['queries']; ?></td>
    <td class="num"><?php echo (int)$j['hits_new']; ?></td>
    <td><?php echo h(substr($j['error'], 0, 60)); ?></td>
  </tr>
  <?php endforeach; ?>
</table>
<?php include 'templates/footer.tpl.php'; ?>
