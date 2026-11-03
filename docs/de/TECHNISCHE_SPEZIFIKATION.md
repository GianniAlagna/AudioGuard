# AudioGuard — Technische Spezifikation

> Übersetzung von [`../TECHNICAL_SPECIFICATION.md`](../TECHNICAL_SPECIFICATION.md).
> Bei Abweichungen gilt die englische Fassung.

| Feld           | Wert                                         |
|----------------|----------------------------------------------|
| Dokument       | AG-TS-001                                    |
| Version        | 0.4 (ENTWURF — nie freigegeben)              |
| Verantwortlich | Gianni Alagna, CEO & Managing Partner, QT Records |
| Datum          | 14.06.2011 (letzte Änderung 02.10.2011)      |
| Klassifizierung| Intern / Vertraulich                         |

---

## 1. Zweck und Umfang

AudioGuard erkennt nicht autorisierte Kopien der Tonaufnahmen von QT Records im
öffentlichen Internet und automatisiert den Takedown-Prozess.

**Im Umfang (Phase 1)**
- Katalog der eigenen Releases (≈ 340 Tracks, 2006–2011) inkl. ISRC und Audio-Master
- Metadatenbasierte Suche auf Filehoster-Suchmaschinen, MP3-Blogs und Torrent-RSS
- Akustische Prüfung herunterladbarer Ausschnitte (erste 30 s)
- Erstellung, Versand und Verfolgung von Takedown-Notices
- Back-Office-Dashboard für das Label-Team

**Nicht im Umfang**
- Überwachung einzelner P2P-Nutzer / Sammeln von IP-Adressen (rechtlich, siehe §9.3)
- Content-ID-ähnliche Überwachung von YouTube / Streaming (2011 kein API-Zugang)
- Lizenzierung / Monetarisierung gefundener Nutzungen (Idee für Phase 3)
- Dienstleistungen für Drittlabels (SaaS-Idee, Phase 3)

## 2. Anforderungen

### 2.1 Funktional

| ID    | Anforderung                                                                 | Prio |
|-------|------------------------------------------------------------------------------|------|
| F-01  | Release-Metadaten importieren (CSV-Export des Vertriebs / manuelle Erfassung) | M    |
| F-02  | Referenz-Fingerprint pro Track aus WAV/FLAC-Master erzeugen und speichern    | M    |
| F-03  | Konfigurierte Quellen pro Katalogeintrag abfragen (Artist + Titel + Label)   | M    |
| F-04  | Gefundene URLs („Treffer“) normalisieren und deduplizieren                   | M    |
| F-05  | Treffer nach Metadaten-Ähnlichkeit bewerten (0–100)                          | M    |
| F-06  | Max. 30 s / 5 MB Ausschnitt zur Prüfung laden, wo rechtlich und technisch möglich | S |
| F-07  | Fingerprint-Abgleich mit Referenz; Konfidenz speichern                       | S    |
| F-08  | Abuse-Kontakt des Hosters ermitteln (Lookup-Tabelle + WHOIS-Fallback)        | M    |
| F-09  | Notice aus Vorlage erzeugen (DMCA / URG-DE / URG-EN)                          | M    |
| F-10  | Notice per E-Mail senden, Message-ID protokollieren, Status verfolgen        | M    |
| F-11  | URL nach 72 h erneut prüfen; als *entfernt* / *noch online* / *eskalieren* markieren | S |
| F-12  | Dashboard: Treffer pro Release, Entfernungsquote, Hoster-Rangliste           | M    |
| F-13  | Wöchentlicher PDF/CSV-Report für Management und Artists                      | C    |
| F-14  | Pre-Release-Leak-Alarm (Treffer vor offiziellem Release-Datum)               | S    |

M = muss, S = soll, C = kann

### 2.2 Nicht funktional

- **Genauigkeit vor Menge:** Ein falscher Takedown schadet dem Ruf des Labels.
  Keine Notice wird automatisch versandt, ausser `fp_confidence ≥ 0.85` *oder*
  eine Person hat sie freigegeben (Vier-Augen-Prinzip bei reinen Metadaten-Treffern).
- **Rücksichtnahme:** max. 1 Anfrage / 3 s pro Domain; `robots.txt` beachten,
  soweit es dem Zweck des Scans nicht widerspricht (Entscheid offen, siehe §11).
- **Mengengerüst:** 340 Tracks × ~8 Quellen × täglich = ~2'700 Abfragen/Tag.
- **Hardware:** 1 dedizierter Server (Hetzner EX4: Core i7-2600, 16 GB RAM,
  2 × 3 TB), Budget CHF 80/Monat.
- **Verfügbarkeit:** Best Effort; der Crawler ist ein Cron-Job, nicht 24/7-kritisch.

## 3. Systemarchitektur

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

### 3.1 Komponenten

| Komponente       | Pfad               | Sprache           | Stand (Dez. 2011) |
|------------------|--------------------|-------------------|-------------------|
| Schema           | `sql/`             | SQL (MySQL 5.1)   | ~90 %             |
| Fingerprinter    | `fingerprint/`     | Python 2.6, NumPy | ~50 %, Abgleich unzuverlässig bei neu kodierten MP3 < 128 kbps |
| Crawler          | `crawler/`         | Python 2.6        | ~40 %, 1 von 4 Quellen nutzbar |
| Back-Office      | `web/`             | PHP 5.3, jQuery   | ~30 %, nur Leseansichten, Aktionen nicht angebunden |
| Notice-Versand   | `web/lib/Takedown.php` | PHP 5.3       | ~25 %, Vorlagen OK, SMTP ungetestet |

## 4. Datenmodell (Übersicht)

DDL siehe `sql/schema.sql`.

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

Wichtige Entscheide:
- `track.isrc` ist der fachliche Schlüssel (CH-xxx-11-xxxxx für QT-Releases).
- `hit.url_hash` = `SHA1(normalisierte_url)` mit UNIQUE-Index — Deduplizierung beim Einfügen.
- Fingerprint-Hashes werden in `fp_hash` gespeichert (≈ 30–50k Zeilen pro Track)
  mit Index auf `hash` → einfacher invertierter Index. Bekanntes Problem: Die
  Tabelle wächst auf ~15 Mio. Zeilen; MySQL-Leistung nur akzeptabel mit `hash`
  als führendem INT-UNSIGNED-Schlüssel.

## 5. Fingerprinting

### 5.1 Ansatz

Landmark-/Konstellationsverfahren (nach A. Wang, *An Industrial-Strength Audio
Search Algorithm*, ISMIR 2003):

1. Dekodierung zu Mono-PCM 11'025 Hz via `ffmpeg -ac 1 -ar 11025 -f s16le`
2. STFT: Fenster 1024 (Hann), Schrittweite 512
3. Peak-Erkennung: lokale Maxima in einer Zeit-Frequenz-Umgebung (20 × 20 Bins),
   Amplitudenschwelle relativ zum Median des Frames
4. Fan-out: Jeder Anker-Peak wird mit bis zu 5 Peaks in der Zielzone gepaart
   (Δt 1–64 Frames)
5. Hash = `f1 (9 Bit) | f2 (9 Bit) | Δt (6 Bit)` → 24-Bit-Ganzzahl, gespeichert
   mit dem Zeitversatz des Ankers
6. Abgleich: Hash-Treffer pro (track_id, ΔOffset) zählen; Score = grösster Bin /
   Anzahl Abfrage-Hashes

### 5.2 EDM-spezifische Probleme (beobachtet)

- Four-on-the-floor-Kickdrums erzeugen viele identische Peaks → Hash-Kollisionen
  zwischen Tracks mit gleichem Tempo (128 BPM). Idee zur Abhilfe: Hochpass
  bei 150 Hz vor der Peak-Erkennung (nicht umgesetzt).
- DJ-Mixes / Mashups enthalten nur Fragmente; ein 30-s-Ausschnitt kann aus
  einem fremden Intro stammen. Abhilfe: Ausschnitte an 3 Positionen (nicht umgesetzt).
- Raubkopien sind oft MP3 mit 128–192 kbps und anderem Master
  (Radio Edit vs. Extended Mix) → Abgleich nur innerhalb derselben Version.

### 5.3 Geprüfte Alternativen

| Option             | Ergebnis                                                        |
|--------------------|-----------------------------------------------------------------|
| Echoprint (Echo Nest, Open Source seit 06/2011) | Vielversprechend; Codegen unter Debian kompiliert. Der Server benötigt Solr + Tokyo Tyrant → zu schwer für die Teamgrösse. Zurückgestellt. |
| Chromaprint / AcoustID | Gut zur Erkennung ganzer Tracks; damals weniger robust bei kurzen Ausschnitten. |
| Kommerziell (Audible Magic, Gracenote) | Ausserhalb des Budgets (Offerten > CHF 20k/Jahr). |

## 6. Crawler

### 6.1 Ablauf

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

### 6.2 Quellen-Plugins

| Plugin         | Ziel                            | Stand |
|----------------|---------------------------------|-------|
| `filestube`    | FilesTube-Suche (Filehoster)    | funktioniert (HTML-Scraping, bricht bei Layout-Änderungen) |
| `google_cse`   | Google Custom Search API, `"artist" "title" mp3 download` | Stub, Gratis-Kontingent von 100 Abfragen/Tag reicht nicht |
| `torrent_rss`  | Öffentliche Tracker-RSS-Feeds (Kategorie Musik) | teilweise, keine Magnet-Auflösung |
| `blogs`        | Kuratierte Liste von EDM-MP3-Blogs (Blogger / WordPress RSS) | nicht begonnen |

### 6.3 Metadaten-Bewertung

`score = 0.5 × sim(artist) + 0.4 × sim(title) + 0.1 × bonus(label|catno)` ×100,
wobei `sim` = `difflib.SequenceMatcher.ratio()` auf kleingeschriebenen, von
Akzenten und Störtext bereinigten Zeichenketten (`[www.xyz.com]`, `320kbps`,
`-WEB-`, Tags von Scene-Gruppen).

## 7. Takedown-Ablauf

```
 NEW --(score>=60)--> CANDIDATE --(fp>=0.85 or human OK)--> APPROVED
  |                        |                                   |
  |                        +--(reject)--> FALSE_POSITIVE       v
  |                                                          SENT --(72h recheck)--> REMOVED
  +--(dup)--> IGNORED                                          |                      |
                                                               +--> STILL_ONLINE --> ESCALATED (2nd notice / host upstream)
```

- Die Notice-Art richtet sich nach dem Land des Hosters (`host.country`):
  `US` → DMCA §512(c)(3); `CH` → URG-Schreiben (DE); übrige → EU/URG-Schreiben
  (EN) mit Verweis auf Richtlinie 2000/31/EG Art. 14.
- Eine Notice pro Hoster und Tag, die alle URLs bündelt (Hoster bevorzugen Sammelmeldungen).
- Abuse-Kontakte werden manuell in `abuse_contact` gepflegt; WHOIS als Fallback.
- RapidShare (Baar ZG) und Megaupload boten Rechteinhabern Tools / Abuse-Konten
  an — Integration als „Direktlöschung“ über deren Portale geplant (manuell).

## 8. Back-Office (PHP)

| Seite             | Datei                        | Stand |
|-------------------|------------------------------|-------|
| Login             | `web/index.php`              | sitzungsbasiert, ein gemeinsames Passwort (!) |
| Dashboard         | `web/dashboard.php`          | zeigt KPIs aus der DB, Platzhalter für Diagramm |
| Katalog           | `web/catalogue.php`          | nicht eingecheckt |
| Trefferliste      | `web/templates/hits.tpl.php` | wird angezeigt, Sammelaktionen nicht angebunden |
| Takedown-Queue    | `web/ajax/takedown.php`      | Endpunkt-Stub |

Für den Prototyp bewusst in Kauf genommene Sicherheitsschulden: gemeinsames
Passwort, keine CSRF-Tokens, `mysql_*` statt PDO. **Muss** vor jedem
Produktiveinsatz behoben werden.

## 9. Rechtlicher Rahmen (Stand 2011, mit Fokus Schweiz)

> Keine Rechtsberatung; Zusammenfassung für die interne Planung, durch
> Rechtsbeistand zu prüfen (Budget nicht bewilligt).

### 9.1 Rechtsgrundlage
- QT Records hält die **Rechte des Tonträgerherstellers** an seinen Tonaufnahmen
  — Art. 36 URG (SR 231.1): ausschliessliches Recht zur Vervielfältigung,
  Verbreitung und Zugänglichmachung. Die Artist-Verträge übertragen zusätzlich
  die Rechte der ausübenden Künstler (Art. 33 URG) für die Online-Verwertung.
- Zivilrechtliche Ansprüche: Art. 62 URG (Unterlassung, Beseitigung,
  Schadenersatz nach OR); strafrechtlich: Art. 69 URG (Verletzung verwandter
  Schutzrechte, Antragsdelikt).

### 9.2 Eigengebrauch
- Art. 19 URG: Das **Herunterladen** zum Eigengebrauch aus einer unrechtmässigen
  Quelle war (und ist) in der Schweiz zulässig. Das **Hochladen /
  Zugänglichmachen** nicht.
  → AudioGuard richtet sich gegen das *Zugänglichmachen* (Hoster, Links),
  nicht gegen Herunterladende.

### 9.3 Datenschutz — der Logistep-Entscheid
- **BGE 136 II 508 (Bundesgericht, 8. September 2010, „Logistep“)**: Das
  systematische Sammeln von IP-Adressen von P2P-Nutzern durch ein privates
  Unternehmen im Auftrag von Rechteinhabern verletzte das Bundesgesetz über
  den Datenschutz (DSG, SR 235.1).
- Folge für AudioGuard: **keine Erhebung oder Speicherung von IP-Adressen von
  Hochladenden oder Herunterladenden**. Das Torrent-Plugin speichert nur
  `.torrent`-Metadaten und die Tracker-URL, nie Peer-Listen. Dies war eine
  verbindliche Architekturregel.

### 9.4 Haftung der Hoster / Notices
- Schweiz 2011: **kein gesetzliches Notice-and-Takedown-Verfahren**. Notices an
  Schweizer Hoster stützen sich auf das URG, die Teilnehmerhaftung (Art. 50 OR)
  und die eigenen Nutzungsbedingungen des Hosters.
- US-Hoster: DMCA, 17 U.S.C. §512(c)(3) — die Notice muss Unterschrift,
  Bezeichnung des Werks und des verletzenden Materials, Kontaktdaten, eine
  Gutglaubenserklärung und eine Richtigkeitserklärung unter Strafandrohung
  wegen Meineids enthalten.
- EU-Hoster: Richtlinie 2000/31/EG Art. 14 (Haftungsprivileg für Hosting,
  Entfernung ab tatsächlicher Kenntnis), nationale Umsetzungen (z. B. DE: §10 TMG).

### 9.5 Verwertungsgesellschaften
- SUISA / SWISSPERFORM verfolgen Online-Piraterie nicht für einzelne Labels;
  eine Mitgliedschaft bei IFPI Schweiz zur Unterstützung wurde erwogen (nicht weiterverfolgt).

## 10. Projektplan (ursprünglich, März 2011)

| Meilenstein | Inhalt                                       | Geplant    | Tatsächlich |
|-------------|----------------------------------------------|------------|-------------|
| M0          | Konzept, rechtliche Vorabklärung             | 31.03.2011 | 20.04.2011 |
| M1          | Schema + Katalogimport                       | 15.05.2011 | 10.06.2011 |
| M2          | Crawler mit 2 Quellen                        | 30.06.2011 | 1 Quelle, 08.2011 |
| M3          | Fingerprint-Prototyp ≥ 90 % bei 128 kbps     | 31.07.2011 | ~71 %, nicht erreicht |
| M4          | E-Mail-Ablauf für Takedowns                  | 31.08.2011 | nur Vorlagen |
| M5          | Pilot mit 3 Releases                         | 30.09.2011 | manueller Pilot, 10.2011 |
| M6          | Go / No-Go                                   | 30.11.2011 | **No-Go, 09.12.2011** |

## 11. Offene Punkte beim Einfrieren

1. Umgang mit `robots.txt` vs. Zweck des Scans — nicht entschieden.
2. Wer unterzeichnet DMCA-Notices (§512 verlangt eine berechtigte Person) — nur der CEO → Engpass.
3. Falsch-Positiv-Rate des Fingerprints bei EDM-Tracks mit gleichem Tempo (~8 % im Testset).
4. Ablauf der Direktlinks bei Megaupload/Hotfile: Ausschnitte oft ohne Premium-Konto nicht ladbar → Prüfung unmöglich.
5. Rechtliche Prüfung automatisierter Notices in der Schweiz nicht budgetiert.
6. Skalierung der Tabelle `fp_hash` über 1'000 Tracks hinaus.
