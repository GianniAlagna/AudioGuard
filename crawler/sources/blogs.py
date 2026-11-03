# -*- coding: utf-8 -*-
"""Curated EDM MP3 blogs. NOT STARTED."""

from sources import BaseSource


class Source(BaseSource):
    name = 'blogs'

    def search(self, query):
        # TODO: list of ~40 blogs (Blogger/WordPress), use /feeds/posts/default?q= for Blogger
        raise NotImplementedError('blogs plugin not implemented')
