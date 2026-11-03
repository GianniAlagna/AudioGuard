# AudioGuard — Technical Specification

| Field          | Value                                        |
|----------------|----------------------------------------------|
| Document       | AG-TS-001                                    |
| Version        | 0.4 (DRAFT — never approved)                 |
| Owner          | Gianni Alagna, CEO & Managing Partner, QT Records |
| Date           | 2011-06-14 (last edit 2011-10-02)            |
| Classification | Internal / Confidential                      |

---

## 1. Purpose & scope

AudioGuard detects unauthorised copies of QT Records' sound recordings on the
public internet and automates the takedown process.

**In scope (Phase 1)**
- Catalogue of own releases (≈ 340 tracks, 2006-2011) incl. ISRC and audio masters
- Metadata-based discovery on file-locker search engines, MP3 blogs, torrent RSS
- Acoustic verification of downloadable samples (first 30 s)
- Generation, sending and tracking of takedown notices
- Back-office dashboard for label staff

**Out of scope**
- Monitoring of individual P2P users / IP address collection (legal, see §9.3)
- Content ID-style monitoring of YouTube / streaming (no API access in 2011)
- Licensing / monetisation of found uses (idea for Phase 3)
- Services for third-party labels (SaaS idea, Phase 3)

## 2. Requirements

### 2.1 Functional

| ID    | Requirement                                                              | Prio |
|-------|---------------------------------------------------------------------------|------|
| F-01  | Import release metadata (CSV export from distributor / manual entry)      | M    |
| F-02  | Generate & store reference fingerprint per track from WAV/FLAC master     | M    |
| F-03  | Query configured sources for each catalogue item (artist + title + label) | M    |
| F-04  | Normalise and deduplicate found URLs ("hits")                              | M    |
| F-05  | Score hits by metadata similarity (0-100)                                 | M    |
| F-06  | Download max. 30 s / 5 MB sample for verification where legally and technically possible | S |
| F-07  | Fingerprint match against reference; store confidence                     | S    |
| F-08  | Resolve abuse contact for host (lookup table + WHOIS fallback)            | M    |
| F-09  | Generate notice from template (DMCA / URG-DE / URG-EN)                    | M    |
| F-10  | Send notice by e-mail, log Message-ID, track status                       | M    |
| F-11  | Re-check URL after 72 h; mark as *removed* / *still online* / *escalate*  | S    |
| F-12  | Dashboard: hits per release, removal rate, hosts ranking                  | M    |
| F-13  | Weekly PDF/CSV report for management and artists                          | C    |
| F-14  | Pre-release leak alert (hit found before official release date)           | S    |

M = must, S = should, C = could

### 2.2 Non-functional

- **Accuracy over volume:** a false takedown damages the label's reputation.
  No notice is sent automatically unless `fp_confidence ≥ 0.85` *or* a human
  approved it (four-eyes principle for metadata-only hits).
- **Politeness:** max. 1 request / 3 s per domain, honour `robots.txt` where
  not in conflict with the scan purpose (decision pending, see §11).
- **Volume estimate:** 340 tracks × ~8 sources × daily = ~2'700 queries/day.
- **Hardware:** 1 dedicated server (Hetzner EX4: Core i7-2600, 16 GB RAM,
  2 × 3 TB), budget CHF 80/month.
- **Availability:** best-effort; crawler is a cron job, not 24/7 critical.

## 3. System architecture

```
                 +---------------------------------------------------+
                 |                 Back-office (PHP 5.3)             |
   Label staff ->|  Dashboard | Catalogue | Hits | Takedown queue     |
                 +-------------------------+-------------------------+
                                           | mysql_*
                                           v
 +----------------+   writes      +------------------+    reads    +-------------------+
 | Fingerprinter  |-------------->|   MySQL 5.1      |<------------| Notice sender     |
 | (Python/NumPy) |  reference FP |   audioguard     |  pending    | (PHP CLI, cron)   |
 +----------------+               +------------------+  notices    +---------+---------+
        ^                               ^       ^                            |
        | sample (30s)                  | hits  | jobs                       | SMTP
        |                               |       |                            v
 +------+-------------------------------+-------+------+           +-------------------+
 |                Crawler daemon (Python 2.6)          |           | Hoster abuse desk |
 |  scheduler -> source plugins -> normaliser -> scorer|           | (RapidShare, MU,  |
 |   [filestube] [google_cse] [torrent_rss] [blogs]    |           |  Hotfile, Blogger)|
 +-----------------------------------------------------+           +-------------------+
                         |
                         v
                  Public internet (HTTP)
```

### 3.1 Components

| Component        | Path               | Language          | State (Dec 2011) |
|------------------|--------------------|-------------------|------------------|
| Schema           | `sql/`             | SQL (MySQL 5.1)   | ~90 %            |
| Fingerprinter    | `fingerprint/`     | Python 2.6, NumPy | ~50 %, matching unreliable on re-encoded MP3 < 128 kbps |
| Crawler          | `crawler/`         | Python 2.6        | ~40 %, 1 of 4 sources usable |
| Back-office      | `web/`             | PHP 5.3, jQuery   | ~30 %, read-only views, actions not wired |
| Notice sender    | `web/lib/Takedown.php` | PHP 5.3       | ~25 %, templates OK, SMTP untested |

## 4. Data model (summary)

See `sql/schema.sql` for DDL.

```
artist 1---n release 1---n track 1---1 fingerprint
                              |
                              n
                             hit n---1 host 1---n abuse_contact
                              |
                              1
                             notice 1---n notice_event
scan_job n---1 source
```

Key decisions:
- `track.isrc` is the business key (CH-xxx-11-xxxxx for QT releases).
- `hit.url_hash` = `SHA1(normalised_url)` with UNIQUE index — dedup on insert.
- Fingerprint hashes stored in `fp_hash` (≈ 30-50k rows per track) with index
  on `hash` → simple inverted index. Known issue: table grows to ~15M rows,
  MySQL performance acceptable only with `hash` as leading INT UNSIGNED key.

## 5. Fingerprinting

### 5.1 Approach

Landmark / constellation method (after A. Wang, *An Industrial-Strength Audio
Search Algorithm*, ISMIR 2003):

1. Decode to mono PCM 11'025 Hz via `ffmpeg -ac 1 -ar 11025 -f s16le`
2. STFT: window 1024 (Hann), hop 512
3. Peak picking: local maxima in time-frequency neighbourhood (20 × 20 bins),
   amplitude threshold relative to frame median
4. Fan-out: each anchor peak paired with up to 5 peaks in target zone
   (Δt 1-64 frames)
5. Hash = `f1 (9 bit) | f2 (9 bit) | Δt (6 bit)` → 24-bit int, stored with
   anchor time offset
6. Match: count hash hits per (track_id, Δoffset); score = max bin / total
   query hashes

### 5.2 EDM-specific issues (observed)

- Four-on-the-floor kick drums produce many identical peaks → hash collisions
  between tracks of the same tempo (128 BPM). Mitigation idea: high-pass
  at 150 Hz before peak picking (not implemented).
- DJ mixes / mashups contain only fragments; 30 s sample may be from an
  unrelated intro. Mitigation: sample at 3 positions (not implemented).
- Pirated files are often 128-192 kbps MP3 with different master
  (radio edit vs. extended mix) → match only within the same version.

### 5.3 Alternatives evaluated

| Option             | Result                                                          |
|--------------------|-----------------------------------------------------------------|
| Echoprint (Echo Nest, open-sourced 06/2011) | Promising; codegen compiled on Debian. Server requires Solr + Tokyo Tyrant → too heavy for team size. Parked. |
| Chromaprint / AcoustID | Good for identifying full tracks; less robust for short excerpts at that time. |
| Commercial (Audible Magic, Gracenote) | Out of budget (quotes > CHF 20k/year). |

## 6. Crawler

### 6.1 Flow

```
for each active source:
  for each track due for scan (last_scanned < now - interval):
      queries = build_queries(track)          # "Artist - Title", "Title (Original Mix)", catalog no.
      results = source.search(query)          # plugin
      for r in results:
          url   = normalise(r.url)
          score = metadata_score(track, r.title)
          if score >= 60: store_hit(track, url, score)
```

### 6.2 Source plugins

| Plugin         | Target                          | Status |
|----------------|---------------------------------|--------|
| `filestube`    | FilesTube search (file lockers) | works (HTML scraping, breaks on layout change) |
| `google_cse`   | Google Custom Search API, `"artist" "title" mp3 download` | stub, 100 queries/day free quota insufficient |
| `torrent_rss`  | Public tracker RSS feeds (music category) | partial, no magnet resolution |
| `blogs`        | Curated list of EDM MP3 blogs (Blogger / WordPress RSS) | not started |

### 6.3 Metadata scoring

`score = 0.5 × sim(artist) + 0.4 × sim(title) + 0.1 × bonus(label|catno)` ×100,
where `sim` = `difflib.SequenceMatcher.ratio()` on lowercased, de-accented,
noise-stripped strings (`[www.xyz.com]`, `320kbps`, `-WEB-`, scene group tags).

## 7. Takedown workflow

```
 NEW --(score>=60)--> CANDIDATE --(fp>=0.85 or human OK)--> APPROVED
  |                        |                                   |
  |                        +--(reject)--> FALSE_POSITIVE       v
  |                                                          SENT --(72h recheck)--> REMOVED
  +--(dup)--> IGNORED                                          |                      |
                                                               +--> STILL_ONLINE --> ESCALATED (2nd notice / host upstream)
```

- Notice type chosen by host country (`host.country`): `US` → DMCA §512(c)(3);
  `CH` → URG letter (DE); others → EU/URG letter (EN), referencing Directive
  2000/31/EC Art. 14.
- One notice per host per day aggregating all URLs (hosters prefer batches).
- Abuse contacts maintained manually in `abuse_contact`; WHOIS fallback.
- RapidShare (Baar ZG) and Megaupload offered rights-holder tools / abuse
  accounts — integration planned as "direct delete" via their portals (manual).

## 8. Back-office (PHP)

| Page              | File                         | State |
|-------------------|------------------------------|-------|
| Login             | `web/index.php`              | session-based, single shared password (!) |
| Dashboard         | `web/dashboard.php`          | renders KPIs from DB, chart placeholder |
| Catalogue         | `web/catalogue.php`          | not committed |
| Hits list         | `web/templates/hits.tpl.php` | renders, bulk actions not wired |
| Takedown queue    | `web/ajax/takedown.php`      | endpoint stub |

Security debt explicitly accepted for prototype: shared password, no CSRF
tokens, `mysql_*` instead of PDO. **Must** be fixed before any production use.

## 9. Legal framework (state 2011, Switzerland-centric)

> Not legal advice; summary prepared for internal planning, to be validated
> by counsel (budget not approved).

### 9.1 Rights basis
- QT Records holds **producer's neighbouring rights** in its sound recordings
  — Art. 36 URG (SR 231.1): exclusive right to reproduce, distribute and
  make available. Artist contracts additionally assign performers' rights
  (Art. 33 URG) for online exploitation.
- Civil remedies: Art. 62 URG (injunction, removal, damages via OR);
  criminal: Art. 69 URG (violation of neighbouring rights, on complaint).

### 9.2 Private use exception
- Art. 19 URG: **downloading** for private use from an unlawful source was
  (and is) tolerated in CH. **Uploading / making available** is not.
  → AudioGuard targets the *making available* (hosts, links), not downloaders.

### 9.3 Data protection — the Logistep decision
- **BGE 136 II 508 (Federal Supreme Court, 8 Sept 2010, "Logistep")**:
  systematic collection of P2P users' IP addresses by a private company for
  rights holders violated the Federal Data Protection Act (DSG, SR 235.1).
- Consequence for AudioGuard: **no collection or storage of IP addresses of
  uploaders or downloaders**. Torrent plugin stores only `.torrent` metadata
  and tracker URL, never peer lists. This was a hard architectural rule.

### 9.4 Hosting liability / notices
- Switzerland 2011: **no statutory notice-and-takedown** procedure. Notices to
  Swiss hosters rely on URG + participation liability (Art. 50 OR) and the
  hoster's own terms of service.
- US hosters: DMCA, 17 U.S.C. §512(c)(3) — notice must contain signature,
  identification of work and infringing material, contact data, good-faith
  statement, accuracy statement under penalty of perjury.
- EU hosters: Directive 2000/31/EC Art. 14 (hosting safe harbour, removal
  upon actual knowledge), national implementations (e.g. DE: §10 TMG).

### 9.5 Collective management
- SUISA / SWISSPERFORM do not enforce online piracy for individual labels;
  IFPI Schweiz membership considered for support (not pursued).

## 10. Project plan (original, March 2011)

| Milestone | Content                                   | Planned    | Actual |
|-----------|-------------------------------------------|------------|--------|
| M0        | Concept, legal pre-check                  | 2011-03-31 | 2011-04-20 |
| M1        | Schema + catalogue import                 | 2011-05-15 | 2011-06-10 |
| M2        | Crawler with 2 sources                    | 2011-06-30 | 1 source, 2011-08 |
| M3        | Fingerprint prototype ≥ 90 % on 128 kbps  | 2011-07-31 | ~71 %, not reached |
| M4        | Takedown e-mail workflow                  | 2011-08-31 | templates only |
| M5        | Pilot on 3 releases                       | 2011-09-30 | manual pilot, 2011-10 |
| M6        | Go / no-go                                | 2011-11-30 | **No-go, 2011-12-09** |

## 11. Open issues at freeze

1. `robots.txt` policy vs. scan purpose — undecided.
2. Who signs DMCA notices (§512 requires authorised person) — CEO only → bottleneck.
3. Fingerprint false-positive rate on same-tempo EDM tracks (~8 % in test set).
4. Megaupload/Hotfile direct-link expiry: samples often not downloadable without premium account → verification impossible.
5. Legal review of automated notices in CH not budgeted.
6. Scaling the `fp_hash` table beyond 1'000 tracks.
