# AudioGuard — Specifica tecnica

> Traduzione di [`../TECHNICAL_SPECIFICATION.md`](../TECHNICAL_SPECIFICATION.md).
> In caso di divergenze fa fede la versione inglese.

| Campo          | Valore                                       |
|----------------|----------------------------------------------|
| Documento      | AG-TS-001                                    |
| Versione       | 0.4 (BOZZA — mai approvata)                  |
| Responsabile   | Gianni Alagna, CEO & Managing Partner, QT Records |
| Data           | 14.06.2011 (ultima modifica 02.10.2011)      |
| Classificazione| Interno / Confidenziale                      |

---

## 1. Scopo e ambito

AudioGuard individua copie non autorizzate delle registrazioni sonore di QT
Records su Internet e automatizza il processo di rimozione (takedown).

**Nell’ambito (fase 1)**
- Catalogo delle uscite proprie (≈ 340 brani, 2006–2011) con ISRC e master audio
- Ricerca basata sui metadati su motori di ricerca di file hosting, blog MP3 e RSS torrent
- Verifica acustica di estratti scaricabili (primi 30 s)
- Creazione, invio e monitoraggio delle notifiche di rimozione
- Dashboard di back-office per il team dell’etichetta

**Fuori ambito**
- Monitoraggio di singoli utenti P2P / raccolta di indirizzi IP (motivi giuridici, vedi §9.3)
- Monitoraggio di YouTube / streaming simile a Content ID (nessun accesso API nel 2011)
- Licenze / monetizzazione degli utilizzi trovati (idea per la fase 3)
- Servizi per etichette terze (idea SaaS, fase 3)

## 2. Requisiti

### 2.1 Funzionali

| ID    | Requisito                                                                   | Prio |
|-------|------------------------------------------------------------------------------|------|
| F-01  | Importare i metadati delle uscite (export CSV del distributore / inserimento manuale) | M |
| F-02  | Generare e salvare un fingerprint di riferimento per brano dal master WAV/FLAC | M  |
| F-03  | Interrogare le fonti configurate per ogni voce di catalogo (artista + titolo + etichetta) | M |
| F-04  | Normalizzare e deduplicare gli URL trovati («hit»)                          | M    |
| F-05  | Valutare gli hit in base alla somiglianza dei metadati (0–100)              | M    |
| F-06  | Scaricare al massimo 30 s / 5 MB di estratto per la verifica, ove possibile dal punto di vista legale e tecnico | S |
| F-07  | Confronto del fingerprint con il riferimento; salvare il grado di confidenza | S   |
| F-08  | Individuare il contatto abuse dell’hoster (tabella di lookup + fallback WHOIS) | M  |
| F-09  | Generare la notifica da modello (DMCA / URG-DE / URG-EN)                     | M    |
| F-10  | Inviare la notifica via e-mail, registrare il Message-ID, seguire lo stato   | M    |
| F-11  | Ricontrollare l’URL dopo 72 h; segnare come *rimosso* / *ancora online* / *da escalare* | S |
| F-12  | Dashboard: hit per uscita, tasso di rimozione, classifica degli hoster       | M    |
| F-13  | Report settimanale PDF/CSV per management e artisti                          | C    |
| F-14  | Allarme fuga pre-uscita (hit trovato prima della data di uscita ufficiale)   | S    |

M = obbligatorio, S = raccomandato, C = facoltativo

### 2.2 Non funzionali

- **Precisione prima della quantità:** una rimozione errata danneggia la
  reputazione dell’etichetta. Nessuna notifica viene inviata automaticamente,
  salvo `fp_confidence ≥ 0.85` *o* approvazione di una persona (principio dei
  quattro occhi per gli hit basati solo sui metadati).
- **Discrezione:** max. 1 richiesta / 3 s per dominio; rispettare `robots.txt`
  se non in contrasto con lo scopo della scansione (decisione aperta, vedi §11).
- **Volumi stimati:** 340 brani × ~8 fonti × giornaliero = ~2'700 interrogazioni/giorno.
- **Hardware:** 1 server dedicato (Hetzner EX4: Core i7-2600, 16 GB RAM,
  2 × 3 TB), budget CHF 80/mese.
- **Disponibilità:** best effort; il crawler è un job cron, non critico 24/7.

## 3. Architettura del sistema

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

### 3.1 Componenti

| Componente       | Percorso           | Linguaggio        | Stato (dic. 2011) |
|------------------|--------------------|-------------------|-------------------|
| Schema           | `sql/`             | SQL (MySQL 5.1)   | ~90 %             |
| Fingerprinter    | `fingerprint/`     | Python 2.6, NumPy | ~50 %, confronto inaffidabile su MP3 ricodificati < 128 kbps |
| Crawler          | `crawler/`         | Python 2.6        | ~40 %, 1 fonte su 4 utilizzabile |
| Back-office      | `web/`             | PHP 5.3, jQuery   | ~30 %, solo viste in lettura, azioni non collegate |
| Invio notifiche  | `web/lib/Takedown.php` | PHP 5.3       | ~25 %, modelli OK, SMTP non testato |

## 4. Modello dei dati (sintesi)

Per il DDL vedi `sql/schema.sql`.

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

Decisioni principali:
- `track.isrc` è la chiave di business (CH-xxx-11-xxxxx per le uscite QT).
- `hit.url_hash` = `SHA1(url_normalizzato)` con indice UNIQUE — deduplicazione all’inserimento.
- Gli hash dei fingerprint sono salvati in `fp_hash` (≈ 30–50k righe per brano)
  con indice su `hash` → semplice indice invertito. Problema noto: la tabella
  cresce fino a ~15 milioni di righe; prestazioni MySQL accettabili solo con
  `hash` come prima chiave INT UNSIGNED.

## 5. Fingerprinting

### 5.1 Approccio

Metodo a landmark / costellazione (secondo A. Wang, *An Industrial-Strength
Audio Search Algorithm*, ISMIR 2003):

1. Decodifica in PCM mono a 11'025 Hz tramite `ffmpeg -ac 1 -ar 11025 -f s16le`
2. STFT: finestra 1024 (Hann), passo 512
3. Rilevamento dei picchi: massimi locali in un intorno tempo-frequenza
   (20 × 20 bin), soglia di ampiezza relativa alla mediana del frame
4. Fan-out: ogni picco di ancoraggio è accoppiato con al massimo 5 picchi nella
   zona di destinazione (Δt 1–64 frame)
5. Hash = `f1 (9 bit) | f2 (9 bit) | Δt (6 bit)` → intero a 24 bit, salvato con
   lo scostamento temporale dell’ancora
6. Confronto: conteggio degli hash per (track_id, Δoffset); punteggio = bin
   massimo / numero totale di hash della query

### 5.2 Problemi specifici dell’EDM (osservati)

- Le casse in quattro (four-on-the-floor) producono molti picchi identici →
  collisioni di hash tra brani con lo stesso tempo (128 BPM). Possibile rimedio:
  filtro passa-alto a 150 Hz prima del rilevamento dei picchi (non implementato).
- DJ mix / mashup contengono solo frammenti; un estratto di 30 s può provenire
  da un’intro estranea. Rimedio: estratti in 3 posizioni (non implementato).
- I file piratati sono spesso MP3 a 128–192 kbps con un master diverso
  (radio edit vs. extended mix) → confronto solo all’interno della stessa versione.

### 5.3 Alternative valutate

| Opzione            | Risultato                                                       |
|--------------------|-----------------------------------------------------------------|
| Echoprint (Echo Nest, open source dal 06/2011) | Promettente; codegen compilato su Debian. Il server richiede Solr + Tokyo Tyrant → troppo pesante per le dimensioni del team. Accantonato. |
| Chromaprint / AcoustID | Buono per identificare brani interi; all’epoca meno robusto su estratti brevi. |
| Commerciali (Audible Magic, Gracenote) | Fuori budget (offerte > CHF 20k/anno). |

## 6. Crawler

### 6.1 Flusso

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

### 6.2 Plugin delle fonti

| Plugin         | Obiettivo                       | Stato |
|----------------|---------------------------------|-------|
| `filestube`    | Ricerca FilesTube (file hosting)| funziona (scraping HTML, si rompe ai cambi di layout) |
| `google_cse`   | Google Custom Search API, `"artist" "title" mp3 download` | stub, la quota gratuita di 100 interrogazioni/giorno non basta |
| `torrent_rss`  | Feed RSS di tracker pubblici (categoria musica) | parziale, nessuna risoluzione dei magnet |
| `blogs`        | Elenco curato di blog MP3 EDM (Blogger / WordPress RSS) | non iniziato |

### 6.3 Valutazione dei metadati

`score = 0.5 × sim(artist) + 0.4 × sim(title) + 0.1 × bonus(label|catno)` ×100,
dove `sim` = `difflib.SequenceMatcher.ratio()` su stringhe in minuscolo, senza
accenti e ripulite dal rumore (`[www.xyz.com]`, `320kbps`, `-WEB-`, tag dei
gruppi della scene).

## 7. Flusso di rimozione

```
 NEW --(score>=60)--> CANDIDATE --(fp>=0.85 or human OK)--> APPROVED
  |                        |                                   |
  |                        +--(reject)--> FALSE_POSITIVE       v
  |                                                          SENT --(72h recheck)--> REMOVED
  +--(dup)--> IGNORED                                          |                      |
                                                               +--> STILL_ONLINE --> ESCALATED (2nd notice / host upstream)
```

- Il tipo di notifica dipende dal paese dell’hoster (`host.country`): `US` →
  DMCA §512(c)(3); `CH` → lettera LDA (DE); altri → lettera UE/LDA (EN) con
  rinvio alla direttiva 2000/31/CE art. 14.
- Una notifica per hoster al giorno che raggruppa tutti gli URL (gli hoster preferiscono invii cumulativi).
- I contatti abuse sono gestiti manualmente in `abuse_contact`; WHOIS come fallback.
- RapidShare (Baar ZG) e Megaupload offrivano strumenti / account abuse ai
  titolari dei diritti — prevista un’integrazione come «cancellazione diretta»
  tramite i loro portali (manuale).

## 8. Back-office (PHP)

| Pagina            | File                         | Stato |
|-------------------|------------------------------|-------|
| Login             | `web/index.php`              | basato su sessione, un’unica password condivisa (!) |
| Dashboard         | `web/dashboard.php`          | mostra i KPI dal DB, segnaposto per il grafico |
| Catalogo          | `web/catalogue.php`          | non inserito nel repository |
| Elenco hit        | `web/templates/hits.tpl.php` | visualizzato, azioni cumulative non collegate |
| Coda di rimozione | `web/ajax/takedown.php`      | endpoint stub |

Debito di sicurezza accettato consapevolmente per il prototipo: password
condivisa, nessun token CSRF, `mysql_*` invece di PDO. **Da correggere**
prima di qualsiasi uso in produzione.

## 9. Quadro giuridico (stato 2011, incentrato sulla Svizzera)

> Non è una consulenza legale; sintesi per la pianificazione interna, da far
> verificare da un legale (budget non approvato).

### 9.1 Base dei diritti
- QT Records detiene i **diritti di produttore di supporti sonori** sulle proprie
  registrazioni — art. 36 LDA (RS 231.1): diritto esclusivo di riprodurre,
  distribuire e mettere a disposizione. I contratti con gli artisti cedono
  inoltre i diritti degli artisti interpreti (art. 33 LDA) per lo sfruttamento online.
- Rimedi civili: art. 62 LDA (azione inibitoria, di rimozione, risarcimento
  secondo il CO); penali: art. 69 LDA (violazione di diritti di protezione
  affini, perseguibile a querela di parte).

### 9.2 Uso privato
- Art. 19 LDA: lo **scaricamento** per uso privato da una fonte illecita era
  (ed è) tollerato in Svizzera. Il **caricamento / la messa a disposizione** no.
  → AudioGuard si rivolge alla *messa a disposizione* (hoster, link), non a chi scarica.

### 9.3 Protezione dei dati — la sentenza Logistep
- **DTF 136 II 508 (Tribunale federale, 8 settembre 2010, «Logistep»)**: la
  raccolta sistematica degli indirizzi IP degli utenti P2P da parte di
  un’impresa privata per conto dei titolari dei diritti violava la legge
  federale sulla protezione dei dati (LPD, RS 235.1).
- Conseguenza per AudioGuard: **nessuna raccolta o conservazione di indirizzi
  IP di chi carica o scarica**. Il plugin torrent salva solo i metadati del
  `.torrent` e l’URL del tracker, mai l’elenco dei peer. Era una regola
  architetturale vincolante.

### 9.4 Responsabilità degli hoster / notifiche
- Svizzera 2011: **nessuna procedura legale di notice-and-takedown**. Le
  notifiche agli hoster svizzeri si basano sulla LDA, sulla responsabilità per
  partecipazione (art. 50 CO) e sulle condizioni d’uso dell’hoster.
- Hoster statunitensi: DMCA, 17 U.S.C. §512(c)(3) — la notifica deve contenere
  firma, identificazione dell’opera e del materiale illecito, dati di contatto,
  dichiarazione di buona fede e dichiarazione di esattezza sotto pena di spergiuro.
- Hoster UE: direttiva 2000/31/CE art. 14 (esenzione di responsabilità per
  l’hosting, rimozione dal momento dell’effettiva conoscenza), recepimenti
  nazionali (ad es. DE: §10 TMG).

### 9.5 Gestione collettiva
- SUISA / SWISSPERFORM non perseguono la pirateria online per singole
  etichette; è stata valutata un’adesione a IFPI Svizzera per supporto (non perseguita).

## 10. Piano di progetto (originale, marzo 2011)

| Milestone | Contenuto                                   | Previsto   | Effettivo |
|-----------|---------------------------------------------|------------|-----------|
| M0        | Concetto, verifica giuridica preliminare    | 31.03.2011 | 20.04.2011 |
| M1        | Schema + importazione del catalogo          | 15.05.2011 | 10.06.2011 |
| M2        | Crawler con 2 fonti                         | 30.06.2011 | 1 fonte, 08.2011 |
| M3        | Prototipo fingerprint ≥ 90 % a 128 kbps     | 31.07.2011 | ~71 %, non raggiunto |
| M4        | Flusso e-mail per le rimozioni              | 31.08.2011 | solo modelli |
| M5        | Pilota su 3 uscite                          | 30.09.2011 | pilota manuale, 10.2011 |
| M6        | Go / no-go                                  | 30.11.2011 | **No-go, 09.12.2011** |

## 11. Questioni aperte al blocco

1. Gestione di `robots.txt` vs. scopo della scansione — non deciso.
2. Chi firma le notifiche DMCA (il §512 richiede una persona autorizzata) — solo il CEO → collo di bottiglia.
3. Tasso di falsi positivi del fingerprint su brani EDM con lo stesso tempo (~8 % nel set di test).
4. Scadenza dei link diretti su Megaupload/Hotfile: estratti spesso non scaricabili senza account premium → verifica impossibile.
5. Verifica giuridica delle notifiche automatiche in Svizzera non messa a budget.
6. Scalabilità della tabella `fp_hash` oltre i 1'000 brani.
