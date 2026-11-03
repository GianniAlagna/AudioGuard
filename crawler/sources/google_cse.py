# -*- coding: utf-8 -*-
"""Google Custom Search API (JSON). STUB - quota too small, disabled in DB."""

import urllib
import json      # python 2.6 has json built in

from sources import BaseSource

API = 'https://www.googleapis.com/customsearch/v1?key=%s&cx=%s&q=%s'


class Source(BaseSource):
    name = 'google_cse'

    def search(self, query):
        key = self.cfg.get('google_cse', 'api_key')
        cx = self.cfg.get('google_cse', 'cx')
        if not key:
            return []
        q = '"%s" mp3 download' % query
        data = json.loads(self.fetch(API % (key, cx, urllib.quote_plus(q.encode('utf-8')))))
        # TODO: paging (start=11, 21 ...), every page = 1 query from quota
        return [{'url': i['link'], 'title': i['title']} for i in data.get('items', [])]
