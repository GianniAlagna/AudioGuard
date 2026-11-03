# -*- coding: utf-8 -*-
"""FilesTube - file locker search engine (HTML scraping).

r261: fixed after their August 2011 redesign. Will break again.
"""

import urllib
from BeautifulSoup import BeautifulSoup

from sources import BaseSource, log

SEARCH_URL = 'http://www.filestube.com/search.html?q=%s&select=All'
# only lockers we can send notices to (have abuse contact)
LOCKERS = ('rapidshare.com', 'megaupload.com', 'hotfile.com', 'mediafire.com',
           'fileserve.com', 'depositfiles.com', 'zippyshare.com')


class Source(BaseSource):
    name = 'filestube'

    def search(self, query):
        html = self.fetch(SEARCH_URL % urllib.quote_plus(query.encode('utf-8')))
        soup = BeautifulSoup(html)
        out = []
        # result block: <div class="resultsLink"> <a href="/xyz/abc.html">title</a> ... <span class="hostname">
        for div in soup.findAll('div', {'class': 'resultsLink'}):
            a = div.find('a')
            if not a:
                continue
            title = ''.join(a.findAll(text=True)).strip()
            detail = 'http://www.filestube.com' + a['href']
            host = div.find('span', {'class': 'hostname'})
            host = host.string.strip().lower() if host and host.string else ''
            if host and not host.endswith(LOCKERS):
                continue
            # FIXME: detail page holds the real locker link -> 2nd request per result.
            #        For now we store the FilesTube detail URL and resolve later (resolver.py, not written)
            out.append({'url': detail, 'title': title})
        log.debug('filestube "%s": %d results', query, len(out))
        return out
