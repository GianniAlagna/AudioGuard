<?php
/**
 * AudioGuard back-office config. Copy to config.php (not in SVN).
 */
define('AG_VERSION', '0.1-dev r412');

define('DB_HOST', 'localhost');
define('DB_USER', 'audioguard');
define('DB_PASS', 'CHANGEME');
define('DB_NAME', 'audioguard');

// FIXME: single shared password for label staff - prototype only!
define('AG_PASSWORD_SHA1', '');   // sha1('...')

define('NOTICE_FROM',      'copyright@qtrecords.ch');
define('NOTICE_FROM_NAME', 'QT Records - Copyright Department');
define('NOTICE_SIGNATORY', 'Gianni Alagna, CEO & Managing Partner');

define('FP_AUTO_THRESHOLD', 0.85);   // spec 2.2
define('META_REVIEW_MIN',   60);

date_default_timezone_set('Europe/Zurich');
error_reporting(E_ALL & ~E_DEPRECATED);
