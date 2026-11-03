# AudioGuard — Einstellungsnotiz

> Übersetzung von [`../DISCONTINUATION.md`](../DISCONTINUATION.md).
> Bei Abweichungen gilt die englische Fassung.

| Feld       | Wert                                              |
|------------|---------------------------------------------------|
| Entscheid  | No-Go, Projekt eingefroren                        |
| Datum      | 09.12.2011                                        |
| Entschieden| Geschäftsleitung QT Records (G. Alagna)           |
| Dauer      | ~9 Monate (Kick-off 07.03.2011)                   |
| Aufwand    | ~CHF 38'000 (freier Entwickler, Student, Server, rechtliche Vorabklärung) |

## Warum wir gestoppt haben

1. **Sisyphusarbeit.** Manueller Pilot (Okt. 2011, 3 Releases): 214 Links
   gefunden, 131 Notices versandt, 96 innert 7 Tagen entfernt (73 %). Innert
   14 Tagen hatten dieselben Releases über 180 *neue* Links. Die Entfernung
   veränderte die Verkäufe der Pilot-Releases auf Beatport/iTunes nicht messbar.
2. **Prüflücke.** ~60 % der Filehoster-Links liessen sich ohne Premium-Konto
   oder CAPTCHA nicht anspielen → Fingerprinting war gerade dort nicht
   anwendbar, wo es zählte; reine Metadaten-Treffer erfordern eine manuelle Prüfung.
3. **Fingerprint-Qualität.** 71 % Trefferquote im Testset mit 128-kbps-MP3 statt
   der angestrebten 90 %; ~8 % falsche Treffer zwischen EDM-Tracks mit gleichem
   Tempo. Nicht sicher genug für automatische Notices.
4. **Rechtsunsicherheit in der Schweiz.** Kein gesetzliches Notice-and-Takedown,
   der Logistep-Entscheid (BGE 136 II 508) schränkte die P2P-Überwachung ein,
   kein Budget für ein Rechtsgutachten zu automatisierten Notices.
5. **Team und Fokus.** Teilzeit-Team; das Label-Geschäft (Releases, Events,
   Vertriebsverträge) hatte Vorrang. Der studentische Entwickler ging nach dem Semester.

## Was funktioniert hat

- Katalog- / ISRC-Datenmodell — wiederverwendet für das Reporting an den Vertrieb.
- FilesTube-Plugin + manuelle Prüfung belegten das Ausmass des Problems mit
  harten Zahlen (nützlich in Gesprächen mit Vertrieben und der IFPI).
- Die Notice-Vorlagen wurden vom Label-Team bis 2012 manuell weiterverwendet.

## Lehren / was wir anders machen würden

- Monetarisieren statt nur entfernen (Claim & Monetise, wie es YouTube Content ID
  später zum Standard machte) — die Branche ging diesen Weg, nicht den der Takedowns.
- Ressourcen über mehrere unabhängige Labels bündeln (gemeinsamer Dienst)
  statt eines Tools für ein einzelnes Label.
- Mit einem bestehenden Fingerprint-Anbieter zusammenarbeiten, statt die
  Signalverarbeitung selbst zu entwickeln.

## Eingefrorener Stand

Der gesamte Code bleibt auf dem Stand der letzten SVN-Revision (r412). Keine
weitere Wartung.
