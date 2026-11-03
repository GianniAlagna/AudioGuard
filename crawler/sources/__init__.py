# -*- coding: utf-8 -*-
"""Source plugins. Each module defines class Source(BaseSource)."""

import urllib2
import logging

log = logging.getLogger('sources')


class BaseSource(object):
    name = 'base'
    delay = 3

    def __init__(self, cfg):
        self.cfg = cfg
        self.ua = cfg.get('http', 'user_agent')
        self.timeout = cfg.getint('http', 'timeout')
        self.delay = cfg.getint('http', 'delay')

    def fetch(self, url):
        req = urllib2.Request(url, headers={'User-Agent': self.ua})
        # TODO: robots.txt check (spec 11.1 - undecided)
        return urllib2.urlopen(req, timeout=self.timeout).read()

    def search(self, query):
        """Return list of dicts: {'url': ..., 'title': ...}"""
        raise NotImplementedError


def load_plugin(name, cfg):
    mod = __import__('sources.%s' % name, fromlist=['Source'])
    return mod.Source(cfg)
