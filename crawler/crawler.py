#!/usr/bin/env python2.6
# -*- coding: utf-8 -*-
"""
AudioGuard crawler / scanner daemon

    python2.6 crawler.py [--source=PLUGIN] [--once] [--dry-run]

cron (planned):
    15 */6 * * *  audioguard  /usr/bin/python2.6 /srv/audioguard/crawler/crawler.py --once >> /var/log/audioguard/crawler.log 2>&1

LEGAL (BGE 136 II 508 / Logistep): never collect or store IP addresses
of users/peers. Only public URLs of offered files.
"""

import sys
import time
import hashlib
import logging
import optparse
import ConfigParser
import urlparse
from datetime import datetime, date

import MySQLdb
import MySQLdb.cursors

from normalise import normalise_url, metadata_score
from sources import load_plugin

log = logging.getLogger('crawler')

META_THRESHOLD = 60


class Crawler(object):

    def __init__(self, cfg, dry_run=False):
        self.cfg = cfg
        self.dry_run = dry_run
        self.conn = MySQLdb.connect(
            host=cfg.get('db', 'host'), user=cfg.get('db', 'user'),
            passwd=cfg.get('db', 'password'), db=cfg.get('db', 'name'),
            charset='utf8', cursorclass=MySQLdb.cursors.DictCursor)
        self._host_cache = {}

    # --------------------------------------------------------------
    def sources(self, only=None):
        cur = self.conn.cursor()
        if only:
            cur.execute('SELECT * FROM source WHERE plugin = %s', (only,))
        else:
            cur.execute('SELECT * FROM source WHERE enabled = 1')
        return cur.fetchall()

    def due_tracks(self, interval_h):
        cur = self.conn.cursor()
        cur.execute("""
            SELECT t.id, t.title, t.mix_name, t.isrc, r.catalog_no, r.release_date,
                   a.name AS artist, a.aliases
              FROM track t
              JOIN `release` r ON r.id = t.release_id
              JOIN artist a    ON a.id = r.artist_id
             WHERE r.active_scan = 1
               AND (t.last_scanned IS NULL OR t.last_scanned < NOW() - INTERVAL %s HOUR)
             ORDER BY r.release_date DESC
             LIMIT 200""", (interval_h,))
        return cur.fetchall()

    def build_queries(self, track):
        q = ['%s - %s' % (track['artist'], track['title'])]
        if track['mix_name']:
            q.append('%s - %s (%s)' % (track['artist'], track['title'], track['mix_name']))
        q.append(track['catalog_no'])
        if track['aliases']:
            for alias in track['aliases'].split(','):
                q.append('%s - %s' % (alias.strip(), track['title']))
        return q

    # --------------------------------------------------------------
    def host_id(self, url):
        domain = urlparse.urlparse(url)[1].lower()
        if domain.startswith('www.'):
            domain = domain[4:]
        # collapse subdomains of blogspot etc. -> 2nd level
        parts = domain.split('.')
        if len(parts) > 2:
            domain = '.'.join(parts[-2:])      # FIXME: breaks .co.uk / .com.br
        if domain in self._host_cache:
            return self._host_cache[domain]
        cur = self.conn.cursor()
        cur.execute('SELECT id FROM host WHERE domain = %s', (domain,))
        row = cur.fetchone()
        if row:
            hid = row['id']
        else:
            cur.execute("INSERT INTO host (domain, type) VALUES (%s, 'other')", (domain,))
            hid = cur.lastrowid
            # TODO: geoip lookup for country -> needed for notice template
        self._host_cache[domain] = hid
        return hid

    def store_hit(self, track, source_id, url, found_title, score):
        norm = normalise_url(url)
        h = hashlib.sha1(norm).hexdigest()
        pre = 1 if date.today() < track['release_date'] else 0
        if self.dry_run:
            log.info('[dry] %3d %s', score, norm)
            return False
        cur = self.conn.cursor()
        n = cur.execute("""
            INSERT IGNORE INTO hit (track_id, host_id, source_id, url, url_hash, found_title,
                                    meta_score, status, pre_release, first_seen)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'new', %s, NOW())""",
            (track['id'], self.host_id(norm), source_id, norm, h, found_title[:255], score, pre))
        if n and pre:
            log.warning('PRE-RELEASE LEAK: %s %s -> %s', track['catalog_no'], track['title'], norm)
            # TODO F-14: mail alert to label@ (not implemented)
        return n == 1

    # --------------------------------------------------------------
    def run_source(self, src):
        plugin = load_plugin(src['plugin'], self.cfg)
        cur = self.conn.cursor()
        cur.execute('INSERT INTO scan_job (source_id, started_at) VALUES (%s, NOW())', (src['id'],))
        job_id = cur.lastrowid
        queries = hits_new = 0
        error = None
        try:
            for track in self.due_tracks(src['interval_h']):
                for q in self.build_queries(track):
                    queries += 1
                    try:
                        results = plugin.search(q)
                    except Exception, e:
                        log.error('%s: query "%s" failed: %s', src['plugin'], q, e)
                        continue
                    for r in results:
                        score = metadata_score(track, r['title'])
                        if score >= META_THRESHOLD:
                            if self.store_hit(track, src['id'], r['url'], r['title'], score):
                                hits_new += 1
                    time.sleep(plugin.delay)
                cur.execute('UPDATE track SET last_scanned = NOW() WHERE id = %s', (track['id'],))
                self.conn.commit()
        except Exception, e:
            error = repr(e)
            log.exception('source %s aborted', src['plugin'])
        cur.execute("""UPDATE scan_job SET finished_at = NOW(), queries = %s, hits_new = %s, error = %s
                       WHERE id = %s""", (queries, hits_new, error, job_id))
        self.conn.commit()
        log.info('%s: %d queries, %d new hits', src['plugin'], queries, hits_new)


def main():
    p = optparse.OptionParser()
    p.add_option('--source', dest='source')
    p.add_option('--once', action='store_true', default=False)
    p.add_option('--dry-run', action='store_true', default=False)
    p.add_option('-c', '--config', default='config.ini')
    opts, args = p.parse_args()

    logging.basicConfig(level=logging.INFO, format='%(asctime)s %(name)s %(levelname)s %(message)s')
    cfg = ConfigParser.SafeConfigParser()
    if not cfg.read(opts.config):
        log.error('config %s not found', opts.config)
        return 2

    c = Crawler(cfg, dry_run=opts.dry_run)
    while True:
        for src in c.sources(opts.source):
            c.run_source(src)
        if opts.once:
            break
        # TODO: proper daemon (python-daemon) - for now use cron + --once
        time.sleep(3600)
    return 0


if __name__ == '__main__':
    sys.exit(main())
