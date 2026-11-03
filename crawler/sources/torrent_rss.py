# -*- coding: utf-8 -*-
"""Public tracker RSS feeds (music category).

LEGAL: store .torrent page URL + title ONLY. Never connect to the swarm,
never read peer lists / IPs (BGE 136 II 508 Logistep).

r290: partial - feed items are not filtered by query yet, magnet links ignored.
"""

import feedparser

from sources import BaseSource, log


class Source(BaseSource):
    name = 'torrent_rss'

    def __init__(self, cfg):
        BaseSource.__init__(self, cfg)
        raw = cfg.get('torrent_rss', 'feeds')
        self.feeds = [f.strip() for f in raw.splitlines() if f.strip()]
        self._cache = None

    def _items(self):
        # feeds are fetched once per run, not per query
        if self._cache is None:
            self._cache = []
            for f in self.feeds:
                d = feedparser.parse(f, agent=self.ua)
                for e in d.entries:
                    link = e.get('link')
                    if link and not link.startswith('magnet:'):
                        self._cache.append({'url': link, 'title': e.get('title', '')})
            log.info('torrent_rss: %d items from %d feeds', len(self._cache), len(self.feeds))
        return self._cache

    def search(self, query):
        # FIXME: returns ALL items, scoring in crawler filters them -> 340x more work than needed
        return self._items()
