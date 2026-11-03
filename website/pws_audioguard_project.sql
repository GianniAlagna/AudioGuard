-- ---------------------------------------------------------------------------
-- giannialagna.me — project page "AudioGuard" (ga_project)
-- Table prefix: pws_   ·   Languages: en (source) + de, it, fr, es, la (_ga_i18n)
-- Generated 2026-11-03 from github.com/GianniAlagna/AudioGuard
--
-- Import:  mysql --default-character-set=utf8mb4 -u USER -p DBNAME < pws_audioguard_project.sql
--          or phpMyAdmin → Import (character set utf-8).
-- Safe to re-run: the post is matched by slug "audioguard" and its fields are
-- replaced, never duplicated. Back up the database before importing.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;

-- 'draft' = review in WP admin first; change to 'publish' to go live directly.
SET @ga_status := 'draft';
-- Author: the first administrator account.
SET @ga_author := (SELECT u.ID FROM pws_users u JOIN pws_usermeta m ON m.user_id = u.ID AND m.meta_key = 'pws_capabilities' AND m.meta_value LIKE '%administrator%' ORDER BY u.ID LIMIT 1);
SET @ga_author := COALESCE(@ga_author, 1);

START TRANSACTION;

-- 1. Project post (English source text), inserted only if it does not exist yet.
INSERT INTO pws_posts
  (post_author, post_date, post_date_gmt, post_content, post_title, post_excerpt, post_status,
   comment_status, ping_status, post_password, post_name, to_ping, pinged, post_modified,
   post_modified_gmt, post_content_filtered, post_parent, guid, menu_order, post_type, post_mime_type, comment_count)
SELECT @ga_author, NOW(), UTC_TIMESTAMP(), '<!-- wp:paragraph --><p>In 2011 almost every release of QT Records, the Swiss independent EDM label I led as CEO and Managing Partner, was pirated within days. Digital music was barely regulated, and labels had no way to earn from these copies. AudioGuard was our attempt to protect the catalogue with software.</p><!-- /wp:paragraph -->

<!-- wp:paragraph --><p>The plan had five steps: register every release with ISRC and a reference fingerprint; scan file-locker search engines, MP3 blogs and torrent feeds; verify matches by comparing 30 seconds of audio; send DMCA or Swiss copyright notices to the hoster; and report the results per release and artist.</p><!-- /wp:paragraph -->

<!-- wp:paragraph --><p>One rule shaped the design: target the uploads, never the users. After the Swiss Federal Supreme Court’s Logistep ruling (BGE 136 II 508, 2010), collecting IP addresses of file-sharing users was not an option, so AudioGuard stored no personal data and went after hosts and links.</p><!-- /wp:paragraph -->

<!-- wp:paragraph --><p>We stopped after nine months. Removed links came back faster than we could take them down, many files could not be verified without premium accounts, and the fingerprinting was not yet reliable enough for automated notices. The industry later solved the problem differently: through streaming, and through fingerprinting systems that let rights holders monetise copies instead of only removing them.</p><!-- /wp:paragraph -->

<!-- wp:paragraph --><p>The repository is a reconstruction (2026) of the concept and the draft code in the stack of that time: PHP 5.3, MySQL 5.1 and Python 2.6. It includes the technical specification, a post-mortem and translations into German and Italian.</p><!-- /wp:paragraph -->',
       'AudioGuard',
       'Anti-piracy scanner for independent music labels, started at QT Records in 2011: it searched file lockers, blogs and torrent feeds for the label’s releases, verified matches by audio fingerprint and prepared takedown notices. Stopped after nine months.',
       @ga_status, 'closed', 'closed', '', 'audioguard', '', '', NOW(), UTC_TIMESTAMP(), '', 0, '', 0, 'ga_project', '', 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM pws_posts WHERE post_type = 'ga_project' AND post_name = 'audioguard');

SET @ga_pid := (SELECT ID FROM pws_posts WHERE post_type = 'ga_project' AND post_name = 'audioguard' ORDER BY ID LIMIT 1);

-- 2. Refresh the text on re-runs, keep status/author/date as they are.
UPDATE pws_posts SET
  post_content = '<!-- wp:paragraph --><p>In 2011 almost every release of QT Records, the Swiss independent EDM label I led as CEO and Managing Partner, was pirated within days. Digital music was barely regulated, and labels had no way to earn from these copies. AudioGuard was our attempt to protect the catalogue with software.</p><!-- /wp:paragraph -->

<!-- wp:paragraph --><p>The plan had five steps: register every release with ISRC and a reference fingerprint; scan file-locker search engines, MP3 blogs and torrent feeds; verify matches by comparing 30 seconds of audio; send DMCA or Swiss copyright notices to the hoster; and report the results per release and artist.</p><!-- /wp:paragraph -->

<!-- wp:paragraph --><p>One rule shaped the design: target the uploads, never the users. After the Swiss Federal Supreme Court’s Logistep ruling (BGE 136 II 508, 2010), collecting IP addresses of file-sharing users was not an option, so AudioGuard stored no personal data and went after hosts and links.</p><!-- /wp:paragraph -->

<!-- wp:paragraph --><p>We stopped after nine months. Removed links came back faster than we could take them down, many files could not be verified without premium accounts, and the fingerprinting was not yet reliable enough for automated notices. The industry later solved the problem differently: through streaming, and through fingerprinting systems that let rights holders monetise copies instead of only removing them.</p><!-- /wp:paragraph -->

<!-- wp:paragraph --><p>The repository is a reconstruction (2026) of the concept and the draft code in the stack of that time: PHP 5.3, MySQL 5.1 and Python 2.6. It includes the technical specification, a post-mortem and translations into German and Italian.</p><!-- /wp:paragraph -->',
  post_title   = 'AudioGuard',
  post_excerpt = 'Anti-piracy scanner for independent music labels, started at QT Records in 2011: it searched file lockers, blogs and torrent feeds for the label’s releases, verified matches by audio fingerprint and prepared takedown notices. Stopped after nine months.',
  post_modified = NOW(), post_modified_gmt = UTC_TIMESTAMP(),
  guid = IF(guid = '', CONCAT('https://giannialagna.me/?post_type=ga_project&p=', @ga_pid), guid)
WHERE ID = @ga_pid;

-- 3. Project fields (_ga_*) and translations (_ga_i18n, serialized PHP array).
DELETE FROM pws_postmeta WHERE post_id = @ga_pid AND meta_key IN ('_ga_category', '_ga_status', '_ga_year', '_ga_start', '_ga_role', '_ga_repo', '_ga_stack', '_ga_facts', '_ga_i18n');

INSERT INTO pws_postmeta (post_id, meta_key, meta_value) VALUES
  (@ga_pid, '_ga_category', 'Software Development'),
  (@ga_pid, '_ga_status', 'discontinued'),
  (@ga_pid, '_ga_year', '2011'),
  (@ga_pid, '_ga_start', '03.2011'),
  (@ga_pid, '_ga_role', 'Lead (CEO & Product Owner)'),
  (@ga_pid, '_ga_repo', 'https://github.com/GianniAlagna/AudioGuard'),
  (@ga_pid, '_ga_stack', 'PHP 5.3, MySQL 5.1, Python 2.6, NumPy, SciPy, jQuery 1.6'),
  (@ga_pid, '_ga_facts', 'Period|03.2011 – 12.2011
Stack|PHP · MySQL · Python
Legal basis|URG · DMCA
Outcome|Stopped after 9 months'),
  (@ga_pid, '_ga_i18n', 'a:5:{s:2:"de";a:5:{s:7:"excerpt";s:267:"Anti-Piraterie-Scanner für unabhängige Musiklabels, 2011 bei QT Records gestartet: Er durchsuchte Filehoster, Blogs und Torrent-Feeds nach den Releases des Labels, prüfte Treffer per Audio-Fingerprint und bereitete Takedown-Notices vor. Nach neun Monaten gestoppt.";s:7:"content";s:1626:"2011 wurde fast jeder Release von QT Records, dem unabhängigen Schweizer EDM-Label, das ich als CEO und Managing Partner führte, innert Tagen raubkopiert. Digitale Musik war kaum reguliert, und Labels hatten keine Möglichkeit, mit diesen Kopien Geld zu verdienen. AudioGuard war unser Versuch, den Katalog mit Software zu schützen.

Der Plan hatte fünf Schritte: jeden Release mit ISRC und einem Referenz-Fingerprint erfassen; Filehoster-Suchmaschinen, MP3-Blogs und Torrent-Feeds durchsuchen; Treffer durch den Vergleich von 30 Sekunden Audio prüfen; DMCA- oder URG-Notices an den Hoster senden; und die Ergebnisse pro Release und Artist auswerten.

Eine Regel prägte das Design: gegen die Uploads, nie gegen die Nutzer. Nach dem Logistep-Entscheid des Bundesgerichts (BGE 136 II 508, 2010) kam das Sammeln von IP-Adressen von Filesharing-Nutzern nicht in Frage. AudioGuard speicherte deshalb keine Personendaten und ging gegen Hoster und Links vor.

Nach neun Monaten haben wir gestoppt. Entfernte Links kamen schneller zurück, als wir sie entfernen konnten, viele Dateien liessen sich ohne Premium-Konto nicht prüfen, und das Fingerprinting war für automatische Notices noch nicht zuverlässig genug. Die Branche löste das Problem später anders: mit Streaming und mit Fingerprinting-Systemen, mit denen Rechteinhaber Kopien monetarisieren, statt sie nur zu entfernen.

Das Repository ist eine Rekonstruktion (2026) des Konzepts und des Entwurfscodes im Stack von damals: PHP 5.3, MySQL 5.1 und Python 2.6. Es enthält die technische Spezifikation, ein Post-Mortem und Übersetzungen auf Deutsch und Italienisch.";s:8:"category";s:19:"Softwareentwicklung";s:4:"role";s:29:"Leitung (CEO & Product Owner)";s:5:"facts";s:118:"Zeitraum|03.2011 – 12.2011
Stack|PHP · MySQL · Python
Rechtsgrundlage|URG · DMCA
Ergebnis|Nach 9 Monaten gestoppt";}s:2:"it";a:5:{s:7:"excerpt";s:282:"Scanner anti-pirateria per etichette musicali indipendenti, avviato da QT Records nel 2011: cercava le uscite dell’etichetta su file hosting, blog e feed torrent, verificava le corrispondenze tramite fingerprint audio e preparava le notifiche di rimozione. Fermato dopo nove mesi.";s:7:"content";s:1676:"Nel 2011 quasi ogni uscita di QT Records, l’etichetta EDM indipendente svizzera che dirigevo come CEO e Managing Partner, veniva piratata nel giro di pochi giorni. La musica digitale era quasi priva di regole e le etichette non avevano modo di guadagnare da quelle copie. AudioGuard era il nostro tentativo di proteggere il catalogo con il software.

Il piano prevedeva cinque passi: registrare ogni uscita con ISRC e un fingerprint di riferimento; scansionare motori di ricerca di file hosting, blog MP3 e feed torrent; verificare le corrispondenze confrontando 30 secondi di audio; inviare all’hoster notifiche DMCA o basate sulla LDA; e riportare i risultati per uscita e per artista.

Una regola ha guidato il progetto: colpire gli upload, mai gli utenti. Dopo la sentenza Logistep del Tribunale federale (DTF 136 II 508, 2010), raccogliere gli indirizzi IP degli utenti del file sharing non era un’opzione: AudioGuard non salvava dati personali e si rivolgeva a hoster e link.

Ci siamo fermati dopo nove mesi. I link rimossi tornavano più in fretta di quanto riuscissimo a eliminarli, molti file non si potevano verificare senza account premium e il fingerprinting non era ancora abbastanza affidabile per notifiche automatiche. In seguito il settore ha risolto il problema in un altro modo: con lo streaming e con sistemi di fingerprinting che permettono ai titolari dei diritti di monetizzare le copie invece di limitarsi a rimuoverle.

Il repository è una ricostruzione (2026) del concetto e del codice provvisorio con lo stack dell’epoca: PHP 5.3, MySQL 5.1 e Python 2.6. Contiene la specifica tecnica, un post-mortem e le traduzioni in tedesco e italiano.";s:8:"category";s:17:"Sviluppo software";s:4:"role";s:34:"Responsabile (CEO & Product Owner)";s:5:"facts";s:109:"Periodo|03.2011 – 12.2011
Stack|PHP · MySQL · Python
Base giuridica|LDA · DMCA
Esito|Fermato dopo 9 mesi";}s:2:"fr";a:5:{s:7:"excerpt";s:314:"Scanner anti-piratage pour labels de musique indépendants, lancé chez QT Records en 2011 : il recherchait les sorties du label sur les hébergeurs de fichiers, les blogs et les flux torrent, vérifiait les correspondances par empreinte audio et préparait les notifications de retrait. Arrêté après neuf mois.";s:7:"content";s:1865:"En 2011, presque chaque sortie de QT Records, le label EDM indépendant suisse que je dirigeais comme CEO et Managing Partner, était piratée en quelques jours. La musique numérique était à peine réglementée, et les labels n’avaient aucun moyen de tirer un revenu de ces copies. AudioGuard était notre tentative de protéger le catalogue par le logiciel.

Le plan comportait cinq étapes : enregistrer chaque sortie avec son ISRC et une empreinte de référence ; parcourir les moteurs de recherche d’hébergeurs de fichiers, les blogs MP3 et les flux torrent ; vérifier les correspondances en comparant 30 secondes d’audio ; envoyer à l’hébergeur des notifications DMCA ou fondées sur la LDA ; et présenter les résultats par sortie et par artiste.

Une règle a guidé la conception : viser les mises en ligne, jamais les utilisateurs. Après l’arrêt Logistep du Tribunal fédéral (ATF 136 II 508, 2010), collecter les adresses IP des utilisateurs de partage de fichiers n’était pas envisageable : AudioGuard n’enregistrait aucune donnée personnelle et s’adressait aux hébergeurs et aux liens.

Nous avons arrêté après neuf mois. Les liens supprimés revenaient plus vite que nous ne pouvions les retirer, de nombreux fichiers ne pouvaient pas être vérifiés sans compte premium, et l’empreinte audio n’était pas encore assez fiable pour des notifications automatiques. Le secteur a ensuite résolu le problème autrement : par le streaming et par des systèmes d’empreintes qui permettent aux ayants droit de monétiser les copies au lieu de seulement les supprimer.

Le dépôt est une reconstitution (2026) du concept et du code provisoire avec la pile technique de l’époque : PHP 5.3, MySQL 5.1 et Python 2.6. Il contient la spécification technique, un post-mortem et des traductions en allemand et en italien.";s:8:"category";s:23:"Développement logiciel";s:4:"role";s:31:"Direction (CEO & Product Owner)";s:5:"facts";s:117:"Période|03.2011 – 12.2011
Stack|PHP · MySQL · Python
Base juridique|LDA · DMCA
Résultat|Arrêté après 9 mois";}s:2:"es";a:5:{s:7:"excerpt";s:312:"Escáner antipiratería para sellos musicales independientes, iniciado en QT Records en 2011: buscaba los lanzamientos del sello en servicios de alojamiento de archivos, blogs y feeds de torrent, verificaba las coincidencias mediante huella de audio y preparaba los avisos de retirada. Detenido tras nueve meses.";s:7:"content";s:1735:"En 2011 casi cada lanzamiento de QT Records, el sello EDM independiente suizo que dirigía como CEO y Managing Partner, era pirateado en cuestión de días. La música digital apenas estaba regulada y los sellos no tenían forma de obtener ingresos de esas copias. AudioGuard fue nuestro intento de proteger el catálogo con software.

El plan tenía cinco pasos: registrar cada lanzamiento con su ISRC y una huella de referencia; rastrear buscadores de alojamiento de archivos, blogs de MP3 y feeds de torrent; verificar las coincidencias comparando 30 segundos de audio; enviar al proveedor avisos DMCA o basados en la ley suiza de derechos de autor; e informar de los resultados por lanzamiento y por artista.

Una regla marcó el diseño: ir contra las subidas, nunca contra los usuarios. Tras la sentencia Logistep del Tribunal Federal suizo (BGE 136 II 508, 2010), recopilar direcciones IP de usuarios de intercambio de archivos no era una opción, así que AudioGuard no guardaba datos personales y se dirigía a los proveedores y a los enlaces.

Lo detuvimos tras nueve meses. Los enlaces retirados volvían más rápido de lo que podíamos eliminarlos, muchos archivos no se podían verificar sin cuentas premium y la huella de audio aún no era lo bastante fiable para avisos automáticos. Más tarde el sector resolvió el problema de otra manera: con el streaming y con sistemas de huella que permiten a los titulares de derechos monetizar las copias en lugar de solo retirarlas.

El repositorio es una reconstrucción (2026) del concepto y del código provisional con la tecnología de la época: PHP 5.3, MySQL 5.1 y Python 2.6. Incluye la especificación técnica, un post mortem y traducciones al alemán y al italiano.";s:8:"category";s:22:"Desarrollo de software";s:4:"role";s:32:"Dirección (CEO & Product Owner)";s:5:"facts";s:115:"Periodo|03.2011 – 12.2011
Stack|PHP · MySQL · Python
Base jurídica|URG · DMCA
Resultado|Detenido tras 9 meses";}s:2:"la";a:5:{s:7:"excerpt";s:319:"Instrumentum contra piraticam musicae pro societatibus musicis liberis, anno MMXI apud QT Records inceptum: editiones societatis in tabulariis, commentariis interretialibus et fluxibus torrentium quaerebat, congruentias per vestigium soni probabat et denuntiationes ad removendum parabat. Post novem menses intermissum.";s:7:"content";s:1590:"Anno MMXI fere omnis editio QT Records, societatis musicae electronicae Helveticae liberae quam ut praeses et socius administrans regebam, intra paucos dies furtim describebatur. Musica digitalis vix legibus regebatur, neque societatibus ulla via erat ex his exemplaribus lucrum faciendi. AudioGuard conatus noster erat catalogum programmate tuendi.

Consilium quinque gradus habebat: omnem editionem cum ISRC et vestigio soni exemplari inscribere; machinas quaerendi tabulariorum, commentarios MP3 et fluxus torrentium perscrutari; congruentias triginta secundis soni comparatis probare; denuntiationes DMCA vel iuris auctoris Helvetici ad hospitem mittere; eventus denique per editionem et artificem referre.

Una regula consilium formavit: in onera, numquam in usores. Post sententiam Logistep Tribunalis Foederalis (BGE 136 II 508, MMX), inscriptiones IP usorum colligere non licebat; itaque AudioGuard nulla data personalia servabat et hospites nexusque petebat.

Post novem menses destitimus. Nexus remoti celerius redibant quam eos tollere poteramus, multa documenta sine ratione pretiosa probari non poterant, neque vestigium soni satis certum erat ad denuntiationes automaticas. Postea ars musica rem aliter solvit: per fluxum continuum (streaming) et per systemata vestigiorum quibus domini iurium exemplaria in quaestum vertunt, non solum tollunt.

Repositorium est restitutio (MMXXVI) consilii et codicis provisorii instrumentis illius temporis scripti: PHP 5.3, MySQL 5.1 et Python 2.6. Continet descriptionem technicam, analysin post finem et versiones Germanicam et Italicam.";s:8:"category";s:12:"Programmatio";s:4:"role";s:25:"Dux (CEO & Product Owner)";s:5:"facts";s:125:"Tempus|03.2011 – 12.2011
Instrumenta|PHP · MySQL · Python
Fundamentum iuris|URG · DMCA
Exitus|Post IX menses intermissum";}}');

COMMIT;

-- Check:
SELECT ID, post_title, post_status, post_name FROM pws_posts WHERE ID = @ga_pid;
