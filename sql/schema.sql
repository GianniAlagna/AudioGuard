-- AudioGuard schema v3  (r174, 2011-06-10)
-- MySQL 5.1, InnoDB, utf8
-- mysql -u root -p audioguard < schema.sql

SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS audioguard DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE audioguard;

-- ------------------------------------------------------------------
-- Catalogue
-- ------------------------------------------------------------------
DROP TABLE IF EXISTS artist;
CREATE TABLE artist (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name          VARCHAR(128) NOT NULL,
  aliases       VARCHAR(255) NULL COMMENT 'comma separated, used for search queries',
  contact_email VARCHAR(128) NULL,
  created_at    DATETIME NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_artist_name (name)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `release`;
CREATE TABLE `release` (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  catalog_no    VARCHAR(16)  NOT NULL COMMENT 'e.g. QTR047',
  title         VARCHAR(128) NOT NULL,
  artist_id     INT UNSIGNED NOT NULL,
  release_date  DATE NOT NULL,
  promo_date    DATE NULL COMMENT 'promo sent to DJs - leaks before release_date = alert',
  upc           VARCHAR(14)  NULL,
  active_scan   TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_catalog_no (catalog_no),
  KEY idx_artist (artist_id),
  CONSTRAINT fk_release_artist FOREIGN KEY (artist_id) REFERENCES artist (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS track;
CREATE TABLE track (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  release_id    INT UNSIGNED NOT NULL,
  isrc          CHAR(12) NOT NULL COMMENT 'CH-xxx-YY-NNNNN without dashes',
  title         VARCHAR(128) NOT NULL,
  mix_name      VARCHAR(64)  NULL COMMENT 'Original Mix, Radio Edit, XYZ Remix',
  duration_sec  SMALLINT UNSIGNED NULL,
  bpm           SMALLINT UNSIGNED NULL,
  master_path   VARCHAR(255) NULL COMMENT '/srv/masters/QTR047/01.wav',
  last_scanned  DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_isrc (isrc),
  KEY idx_release (release_id),
  KEY idx_last_scanned (last_scanned),
  CONSTRAINT fk_track_release FOREIGN KEY (release_id) REFERENCES `release` (id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------
-- Fingerprints
-- ------------------------------------------------------------------
DROP TABLE IF EXISTS fingerprint;
CREATE TABLE fingerprint (
  track_id      INT UNSIGNED NOT NULL,
  algo          VARCHAR(16) NOT NULL DEFAULT 'agfp1' COMMENT 'agfp1 = own landmark, echoprint = evaluation',
  num_hashes    INT UNSIGNED NOT NULL,
  created_at    DATETIME NOT NULL,
  PRIMARY KEY (track_id, algo),
  CONSTRAINT fk_fp_track FOREIGN KEY (track_id) REFERENCES track (id)
) ENGINE=InnoDB;

-- inverted index; ~40k rows per track. hash must be leading key!
DROP TABLE IF EXISTS fp_hash;
CREATE TABLE fp_hash (
  hash          INT UNSIGNED NOT NULL,
  track_id      INT UNSIGNED NOT NULL,
  t_offset      MEDIUMINT UNSIGNED NOT NULL COMMENT 'anchor frame index',
  KEY idx_hash (hash, track_id)
) ENGINE=MyISAM;   -- MyISAM on purpose: bulk insert speed, no FK needed

-- ------------------------------------------------------------------
-- Scanning
-- ------------------------------------------------------------------
DROP TABLE IF EXISTS source;
CREATE TABLE source (
  id            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  plugin        VARCHAR(32) NOT NULL COMMENT 'python module in crawler/sources',
  name          VARCHAR(64) NOT NULL,
  interval_h    SMALLINT UNSIGNED NOT NULL DEFAULT 24,
  enabled       TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_plugin (plugin)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS scan_job;
CREATE TABLE scan_job (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  source_id     SMALLINT UNSIGNED NOT NULL,
  started_at    DATETIME NOT NULL,
  finished_at   DATETIME NULL,
  queries       INT UNSIGNED NOT NULL DEFAULT 0,
  hits_new      INT UNSIGNED NOT NULL DEFAULT 0,
  error         TEXT NULL,
  PRIMARY KEY (id),
  KEY idx_source (source_id),
  CONSTRAINT fk_job_source FOREIGN KEY (source_id) REFERENCES source (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS host;
CREATE TABLE host (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  domain        VARCHAR(128) NOT NULL,
  country       CHAR(2) NULL COMMENT 'ISO 3166; decides notice template',
  type          ENUM('locker','blog','tracker','forum','other') NOT NULL DEFAULT 'other',
  notes         TEXT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_domain (domain)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS abuse_contact;
CREATE TABLE abuse_contact (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  host_id       INT UNSIGNED NOT NULL,
  email         VARCHAR(128) NULL,
  web_form_url  VARCHAR(255) NULL,
  preferred     TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  KEY idx_host (host_id),
  CONSTRAINT fk_contact_host FOREIGN KEY (host_id) REFERENCES host (id)
) ENGINE=InnoDB;

-- NOTE (legal, BGE 136 II 508 Logistep): NO ip address columns. Do not add.
DROP TABLE IF EXISTS hit;
CREATE TABLE hit (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  track_id      INT UNSIGNED NOT NULL,
  host_id       INT UNSIGNED NOT NULL,
  source_id     SMALLINT UNSIGNED NOT NULL,
  url           VARCHAR(1024) NOT NULL,
  url_hash      CHAR(40) NOT NULL COMMENT 'sha1(normalised url)',
  found_title   VARCHAR(255) NULL,
  meta_score    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  fp_confidence DECIMAL(4,3) NULL,
  status        ENUM('new','candidate','approved','false_positive','sent','removed','still_online','escalated','ignored')
                NOT NULL DEFAULT 'new',
  pre_release   TINYINT(1) NOT NULL DEFAULT 0,
  first_seen    DATETIME NOT NULL,
  last_checked  DATETIME NULL,
  reviewed_by   VARCHAR(32) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_url_hash (url_hash),
  KEY idx_track (track_id),
  KEY idx_status (status),
  KEY idx_host (host_id),
  CONSTRAINT fk_hit_track  FOREIGN KEY (track_id)  REFERENCES track (id),
  CONSTRAINT fk_hit_host   FOREIGN KEY (host_id)   REFERENCES host (id),
  CONSTRAINT fk_hit_source FOREIGN KEY (source_id) REFERENCES source (id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------
-- Takedown
-- ------------------------------------------------------------------
DROP TABLE IF EXISTS notice;
CREATE TABLE notice (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  host_id       INT UNSIGNED NOT NULL,
  template      ENUM('dmca_en','urg_de','urg_en') NOT NULL,
  recipient     VARCHAR(128) NOT NULL,
  subject       VARCHAR(255) NOT NULL,
  body          MEDIUMTEXT NOT NULL,
  message_id    VARCHAR(255) NULL,
  created_at    DATETIME NOT NULL,
  sent_at       DATETIME NULL,
  signed_by     VARCHAR(64) NULL COMMENT 'DMCA 512(c)(3)(A) authorised person',
  PRIMARY KEY (id),
  KEY idx_host (host_id),
  CONSTRAINT fk_notice_host FOREIGN KEY (host_id) REFERENCES host (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS notice_hit;
CREATE TABLE notice_hit (
  notice_id     INT UNSIGNED NOT NULL,
  hit_id        INT UNSIGNED NOT NULL,
  PRIMARY KEY (notice_id, hit_id),
  CONSTRAINT fk_nh_notice FOREIGN KEY (notice_id) REFERENCES notice (id),
  CONSTRAINT fk_nh_hit    FOREIGN KEY (hit_id)    REFERENCES hit (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS notice_event;
CREATE TABLE notice_event (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  notice_id     INT UNSIGNED NOT NULL,
  event         ENUM('created','sent','bounce','reply','recheck_removed','recheck_online','escalated') NOT NULL,
  detail        TEXT NULL,
  created_at    DATETIME NOT NULL,
  PRIMARY KEY (id),
  KEY idx_notice (notice_id),
  CONSTRAINT fk_ne_notice FOREIGN KEY (notice_id) REFERENCES notice (id)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------------
-- Seed data
-- ------------------------------------------------------------------
INSERT INTO source (plugin, name, interval_h, enabled) VALUES
  ('filestube',   'FilesTube',               24, 1),
  ('google_cse',  'Google Custom Search',    48, 0),
  ('torrent_rss', 'Torrent RSS (music)',     12, 1),
  ('blogs',       'EDM blogs (curated)',     24, 0);

INSERT INTO host (domain, country, type) VALUES
  ('rapidshare.com',  'CH', 'locker'),
  ('megaupload.com',  'HK', 'locker'),
  ('hotfile.com',     'PA', 'locker'),
  ('mediafire.com',   'US', 'locker'),
  ('fileserve.com',   'HK', 'locker'),
  ('depositfiles.com','CY', 'locker'),
  ('blogspot.com',    'US', 'blog'),
  ('zippyshare.com',  'NL', 'locker');

-- TODO: abuse_contact seed - fill manually from hoster websites, do not guess addresses
