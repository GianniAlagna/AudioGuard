<?php
/**
 * Takedown notice generation & sending.
 *
 * STATUS r398 (WIP):
 *   renderTemplate()  OK
 *   groupByHost()     OK
 *   createNotices()   partial - abuse contact lookup missing for most hosts
 *   send()            untested, PHPMailer not yet in lib/
 *   recheck()         not started (F-11, cron every 72h)
 */
class Takedown
{
    const TPL_DIR = '../takedown/templates/';

    /** host.country -> template */
    private $countryTemplate = array(
        'US' => 'dmca_en',
        'CH' => 'urg_de',
        'DE' => 'urg_de',
        'AT' => 'urg_de',
    );

    public function templateFor($country)
    {
        return isset($this->countryTemplate[$country]) ? $this->countryTemplate[$country] : 'urg_en';
    }

    /**
     * @return array host_id => array of hit rows
     */
    public function groupByHost(array $hitIds)
    {
        $in   = implode(',', array_map('intval', $hitIds));
        $rows = db_all("
            SELECT h.id, h.url, h.host_id, h.fp_confidence, h.meta_score, h.status,
                   t.title, t.mix_name, t.isrc, r.catalog_no, r.title AS release_title,
                   a.name AS artist, ho.domain, ho.country
              FROM hit h
              JOIN track t     ON t.id = h.track_id
              JOIN `release` r ON r.id = t.release_id
              JOIN artist a    ON a.id = r.artist_id
              JOIN host ho     ON ho.id = h.host_id
             WHERE h.id IN ($in)");
        $groups = array();
        foreach ($rows as $r) {
            $groups[$r['host_id']][] = $r;
        }
        return $groups;
    }

    public function renderTemplate($name, array $vars)
    {
        $file = self::TPL_DIR . $name . '.txt';
        if (!is_readable($file)) {
            throw new Exception("Template $name not found");
        }
        $tpl = file_get_contents($file);
        foreach ($vars as $k => $v) {
            $tpl = str_replace('{' . strtoupper($k) . '}', $v, $tpl);
        }
        return $tpl;
    }

    private function worksList(array $hits)
    {
        $works = array();
        $urls  = array();
        foreach ($hits as $hit) {
            $key = $hit['isrc'];
            $works[$key] = sprintf('- "%s" by %s%s, ISRC %s, release %s (%s)',
                $hit['title'], $hit['artist'],
                $hit['mix_name'] ? ' (' . $hit['mix_name'] . ')' : '',
                $hit['isrc'], $hit['catalog_no'], $hit['release_title']);
            $urls[] = $hit['url'];
        }
        return array(implode("\n", $works), implode("\n", $urls));
    }

    /**
     * One notice per host (spec 7: hosters prefer batches).
     */
    public function createNotices(array $hitIds, $user)
    {
        $created = array();
        foreach ($this->groupByHost($hitIds) as $hostId => $hits) {
            // only approved logic: fp >= threshold OR human approval (= this call)
            $contact = db_one("SELECT email FROM abuse_contact WHERE host_id = " . (int)$hostId .
                              " AND preferred = 1 AND email IS NOT NULL LIMIT 1");
            if (!$contact) {
                // TODO: WHOIS fallback (F-08). Most hosts have no contact yet -> skip
                continue;
            }
            list($works, $urls) = $this->worksList($hits);
            $tpl  = $this->templateFor($hits[0]['country']);
            $body = $this->renderTemplate($tpl, array(
                'host'      => $hits[0]['domain'],
                'date'      => date('d.m.Y'),
                'works'     => $works,
                'urls'      => $urls,
                'signatory' => NOTICE_SIGNATORY,
                'from'      => NOTICE_FROM,
            ));
            $subject = ($tpl == 'dmca_en' ? 'DMCA Notice' : 'Copyright Infringement Notice')
                     . ' - QT Records - ' . count($hits) . ' URL(s)';

            db_query(sprintf("INSERT INTO notice (host_id, template, recipient, subject, body, created_at, signed_by)
                              VALUES (%d, '%s', '%s', '%s', '%s', NOW(), '%s')",
                $hostId, $tpl, db_esc($contact['email']), db_esc($subject), db_esc($body), db_esc($user)));
            $noticeId = mysql_insert_id();
            foreach ($hits as $hit) {
                db_query(sprintf("INSERT INTO notice_hit (notice_id, hit_id) VALUES (%d, %d)", $noticeId, $hit['id']));
            }
            db_query("UPDATE hit SET status = 'approved', reviewed_by = '" . db_esc($user) . "' WHERE id IN ("
                     . implode(',', array_map('intval', array_map(create_function('$h', 'return $h["id"];'), $hits))) . ")");
            $this->event($noticeId, 'created');
            $created[] = $noticeId;
        }
        // FIXME: hits of hosts without contact silently stay 'candidate' - show in UI!
        return $created;
    }

    /**
     * Send pending notices. Called by cron: php -f cron_send.php (not written)
     */
    public function send($noticeId)
    {
        throw new Exception('Takedown::send() not implemented - waiting for PHPMailer 5.1 + SMTP relay');

        /* draft:
        require_once 'lib/phpmailer/class.phpmailer.php';
        $n = db_one("SELECT * FROM notice WHERE id = " . (int)$noticeId . " AND sent_at IS NULL");
        $mail = new PHPMailer(true);
        $mail->CharSet = 'UTF-8';
        $mail->SetFrom(NOTICE_FROM, NOTICE_FROM_NAME);
        $mail->AddAddress($n['recipient']);
        $mail->AddBCC(NOTICE_FROM);              // archive copy
        $mail->Subject = $n['subject'];
        $mail->Body    = $n['body'];
        $mail->Send();
        db_query("UPDATE notice SET sent_at = NOW(), message_id = '" . db_esc($mail->MessageID) . "' WHERE id = " . (int)$noticeId);
        db_query("UPDATE hit h JOIN notice_hit nh ON nh.hit_id = h.id SET h.status = 'sent' WHERE nh.notice_id = " . (int)$noticeId);
        $this->event($noticeId, 'sent');
        */
    }

    public function recheck()
    {
        // TODO F-11: HEAD request on each 'sent' URL older than 72h
        //   404 / "file removed" page -> removed, else still_online -> escalate after 2nd notice
    }

    private function event($noticeId, $event, $detail = null)
    {
        db_query(sprintf("INSERT INTO notice_event (notice_id, event, detail, created_at) VALUES (%d, '%s', %s, NOW())",
            $noticeId, db_esc($event), $detail === null ? 'NULL' : "'" . db_esc($detail) . "'"));
    }
}
