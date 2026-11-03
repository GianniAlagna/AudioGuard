# -*- coding: utf-8 -*-
"""URL normalisation + metadata similarity scoring."""

import re
import difflib
import unicodedata
import urllib
import urlparse

# scene / blog noise in file names
NOISE = [
    r'\[?www\.[^\s\]]+\]?', r'\b\d{3}\s?kbps\b', r'\b(320|256|192|128)\b',
    r'-?web-?\d{0,4}', r'\bmp3\b', r'\bflac\b', r'\bwav\b', r'\bzip\b', r'\brar\b',
    r'\bfree download\b', r'\bbeatport\b', r'\bpromo\b', r'\bretail\b',
    r'-[a-z0-9]{2,6}$',          # scene group tag at end, e.g. -TraX, -SRP
    r'\(\s*\)',
]
NOISE_RE = re.compile('|'.join(NOISE), re.I)

TRACKING_PARAMS = ('utm_source', 'utm_medium', 'utm_campaign', 'ref', 'sid', 'PHPSESSID')


def normalise_url(url):
    url = url.strip()
    scheme, netloc, path, query, frag = urlparse.urlsplit(url)
    netloc = netloc.lower()
    if netloc.startswith('www.'):
        netloc = netloc[4:]
    q = [(k, v) for (k, v) in urlparse.parse_qsl(query) if k not in TRACKING_PARAMS]
    q.sort()
    return urlparse.urlunsplit(('http', netloc, path.rstrip('/'), urllib.urlencode(q), ''))


def clean(s):
    if isinstance(s, str):
        s = s.decode('utf-8', 'ignore')
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').lower()
    s = s.replace('_', ' ').replace('.', ' ')
    s = NOISE_RE.sub(' ', s)
    return re.sub(r'\s+', ' ', s).strip()


def sim(a, b):
    return difflib.SequenceMatcher(None, clean(a), clean(b)).ratio()


def metadata_score(track, found_title):
    """0..100, spec 6.3. found_title is usually 'Artist - Title (Mix)' or a file name."""
    ft = clean(found_title)
    if ' - ' in ft:
        f_artist, f_title = ft.split(' - ', 1)
    else:
        # file names without separator: compare everything against both
        f_artist = f_title = ft
    s_artist = sim(track['artist'], f_artist)
    s_title = sim(track['title'], f_title)
    bonus = 0.0
    if track['catalog_no'].lower() in ft or 'qt records' in ft:
        bonus = 1.0
    # TODO: mix name mismatch (Radio Edit vs Original) should reduce score
    return int(round((0.5 * s_artist + 0.4 * s_title + 0.1 * bonus) * 100))
