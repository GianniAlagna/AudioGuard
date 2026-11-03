<form id="hits-form" method="post" action="ajax/takedown.php">
<div class="toolbar">
  <select name="action" id="bulk-action">
    <option value="">-- Aktion --</option>
    <option value="approve">Freigeben (Notice erstellen)</option>
    <option value="false_positive">Kein Treffer (False Positive)</option>
    <option value="ignore">Ignorieren</option>
    <option value="verify">Fingerprint prüfen</option>
  </select>
  <button type="button" id="bulk-go">Ausführen</button>
  <span id="bulk-msg"></span>
  <span class="filter">
    Status:
    <a href="hits.php?status=new">neu</a> |
    <a href="hits.php?status=candidate">Kandidat</a> |
    <a href="hits.php?status=sent">gesendet</a> |
    <a href="hits.php?status=still_online">noch online</a>
  </span>
</div>

<table class="grid" id="hits">
  <tr>
    <th><input type="checkbox" id="check-all" /></th>
    <th>Kat.-Nr.</th><th>Track</th><th>Gefunden als</th><th>Hoster</th>
    <th>Meta</th><th>FP</th><th>Status</th><th>Seit</th>
  </tr>
  <?php if (!$hits): ?>
  <tr><td colspan="9" class="empty">Keine Treffer.</td></tr>
  <?php endif; ?>
  <?php foreach ($hits as $hit): ?>
  <tr class="st-<?php echo h($hit['status']); ?><?php if ($hit['pre_release']) echo ' leak'; ?>">
    <td><input type="checkbox" name="ids[]" value="<?php echo (int)$hit['id']; ?>" /></td>
    <td><?php echo h($hit['catalog_no']); ?></td>
    <td><?php echo h($hit['artist'] . ' - ' . $hit['title']); ?>
        <?php if ($hit['mix_name']) echo '<em>(' . h($hit['mix_name']) . ')</em>'; ?></td>
    <td><a href="<?php echo h($hit['url']); ?>" target="_blank" rel="noreferrer"><?php echo h($hit['found_title']); ?></a></td>
    <td><?php echo h($hit['domain']); ?></td>
    <td class="num score-<?php echo $hit['meta_score'] >= 80 ? 'hi' : 'mid'; ?>"><?php echo (int)$hit['meta_score']; ?></td>
    <td class="num"><?php echo $hit['fp_confidence'] === null ? '&ndash;' : h($hit['fp_confidence']); ?></td>
    <td><?php echo h($hit['status']); ?><?php if ($hit['pre_release']) echo ' <b class="leak">LEAK</b>'; ?></td>
    <td><?php echo h(substr($hit['first_seen'], 0, 10)); ?></td>
  </tr>
  <?php endforeach; ?>
</table>
<div class="pager">
  <?php if ($page > 1): ?><a href="?p=<?php echo $page - 1; ?>">&laquo; zurück</a><?php endif; ?>
  Seite <?php echo $page; ?>
  <a href="?p=<?php echo $page + 1; ?>">weiter &raquo;</a><!-- FIXME: no total count -->
</div>
</form>
