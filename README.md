# AudioGuard

**Anti-piracy scanning & takedown system for independent music labels**
QT Records · Internal R&D project · 2011

> **STATUS: DISCONTINUED (December 2011)**
> This repository is a frozen, non-working draft. Most modules are stubs,
> half-implemented or untested. It is kept as a record of the concept work,
> not as deployable software. See [`docs/DISCONTINUATION.md`](docs/DISCONTINUATION.md).

> **Provenance note:** This archive is a reconstruction (2026) of the
> AudioGuard concept and draft code as it would have been written at QT Records
> in 2011. It was rebuilt from memory and the original project idea; files are
> not original 2011 artefacts. Toolchain, libraries and legal references
> reflect the state of 2011 on purpose.

---

## The problem (2011)

Practically every release QT Records produced and distributed (Beatport,
iTunes, Juno) appeared on file lockers, blogs, forums and torrent trackers
within 24-72 hours, often *before* the official release date (promo leaks).
Manual search and takedown by label staff took 6-10 hours per release and
did not scale.

## The idea

1. **Catalogue** — register every QT Records release (ISRC, metadata, audio
   master) and generate an acoustic fingerprint for each track.
2. **Scan** — continuously crawl known piracy channels (file-locker search
   engines, MP3 blogs, torrent RSS feeds, forums) for releases matching our
   catalogue by metadata.
3. **Verify** — where a file is downloadable, fetch the first 30 seconds and
   compare it with the reference fingerprint (to avoid false takedowns).
4. **Take down** — generate DMCA (US hosters) or URG-based (CH/EU hosters)
   notices, send them to the abuse contact, and track the response.
5. **Report** — dashboard per release / per artist for A&R and management.

## Repository layout

```
docs/                Technical specification, architecture, legal notes, post-mortem
docs/de/             German translation (Swiss spelling)
docs/it/             Italian translation
sql/                 MySQL 5.1 schema (InnoDB, utf8)
fingerprint/         Python 2.6 + NumPy fingerprinting prototype (spectral peak hashing)
crawler/             Python 2.6 crawler / scanner daemon (sources = plugins)
web/                 PHP 5.3 back-office (dashboard, catalogue, takedown queue), jQuery 1.6
takedown/templates/  Notice templates (DMCA, Swiss URG, German / English)
```

## Stack (as planned in 2011)

| Layer          | Technology                                      |
|----------------|-------------------------------------------------|
| OS / Server    | Debian 6 "Squeeze", Apache 2.2, cron            |
| Database       | MySQL 5.1 (InnoDB)                              |
| Back-office    | PHP 5.3, plain MVC-ish, jQuery 1.6.2, jQuery UI |
| Crawler        | Python 2.6, urllib2, BeautifulSoup 3, feedparser|
| Fingerprinting | Python 2.6, NumPy 1.5, SciPy 0.9, ffmpeg (decode)|
| Alternative FP | Echoprint codegen (open-sourced by The Echo Nest, June 2011) — evaluated |
| Mail           | Postfix + PHP `mail()` / PHPMailer 5.1          |
| VCS            | SVN (migrated to Git for this archive)          |

## Quick (non-)start

There is no working installation path. For reference only:

```
mysql -u root -p audioguard < sql/schema.sql
cp crawler/config.ini.sample crawler/config.ini
python2.6 crawler/crawler.py --source=filestube --once      # partially works, see TODOs
cp web/config.sample.php web/config.php                     # dashboard renders, actions do not
```

## Team (2011)

- Gianni Alagna — CEO & Managing Partner, product owner
- 1 freelance PHP developer (part-time)
- 1 student developer (Python / DSP, ETH semester project scope)
- Label staff — manual verification & test data
