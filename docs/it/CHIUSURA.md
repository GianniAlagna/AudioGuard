# AudioGuard — Nota di chiusura

> Traduzione di [`../DISCONTINUATION.md`](../DISCONTINUATION.md).
> In caso di divergenze fa fede la versione inglese.

| Campo      | Valore                                            |
|------------|---------------------------------------------------|
| Decisione  | No-go, progetto congelato                         |
| Data       | 09.12.2011                                        |
| Deciso da  | Direzione QT Records (G. Alagna)                  |
| Durata     | ~9 mesi (kick-off 07.03.2011)                     |
| Spesa      | ~CHF 38'000 (sviluppatore freelance, studente, server, verifica giuridica preliminare) |

## Perché ci siamo fermati

1. **Lavoro di Sisifo.** Pilota manuale (ott. 2011, 3 uscite): 214 link
   trovati, 131 notifiche inviate, 96 rimossi entro 7 giorni (73 %). Entro
   14 giorni le stesse uscite avevano oltre 180 link *nuovi*. La rimozione non
   ha modificato in modo misurabile le vendite su Beatport/iTunes delle uscite pilota.
2. **Lacuna di verifica.** ~60 % dei link su file hosting non si potevano
   campionare senza account premium o CAPTCHA → il fingerprinting non era
   applicabile proprio dove contava; gli hit basati solo sui metadati
   richiedono una verifica manuale.
3. **Qualità del fingerprint.** 71 % di riconoscimento sul set di test MP3 a
   128 kbps contro un obiettivo del 90 %; ~8 % di falsi positivi tra brani EDM
   con lo stesso tempo. Non abbastanza affidabile per notifiche automatiche.
4. **Incertezza giuridica in Svizzera.** Nessuna procedura legale di
   notice-and-takedown, la sentenza Logistep (DTF 136 II 508) limitava il
   monitoraggio P2P, nessun budget per un parere legale sulle notifiche automatiche.
5. **Team e priorità.** Team a tempo parziale; l’attività dell’etichetta
   (uscite, eventi, accordi di distribuzione) aveva la precedenza. Lo
   sviluppatore studente se n’è andato dopo il semestre.

## Cosa ha funzionato

- Modello dei dati catalogo / ISRC — riutilizzato per il reporting ai distributori.
- Il plugin FilesTube + la verifica manuale hanno dimostrato la portata del
  problema con dati concreti (utili nei colloqui con distributori e IFPI).
- I modelli di notifica sono stati usati manualmente dal team dell’etichetta fino al 2012.

## Lezioni / cosa faremmo diversamente

- Monetizzare invece di limitarsi a rimuovere (claim & monetise, come YouTube
  Content ID ha poi reso standard) — il settore ha preso questa strada, non quella delle rimozioni.
- Mettere in comune le risorse tra più etichette indipendenti (servizio
  condiviso) invece di uno strumento per una sola etichetta.
- Collaborare con un fornitore di fingerprint esistente invece di sviluppare
  internamente l’elaborazione del segnale.

## Stato congelato

Tutto il codice resta allo stato dell’ultima revisione SVN (r412). Nessuna
ulteriore manutenzione.
