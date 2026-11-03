AudioGuard fingerprint prototype (agfp1)
========================================

Requirements (Debian Squeeze):
  apt-get install python2.6 python-numpy python-scipy python-mysqldb ffmpeg

Index full catalogue (not automated yet):
  mysql -N -e "SELECT id, master_path FROM track WHERE master_path IS NOT NULL" audioguard \
    | while read id path; do python2.6 agfp.py index $id "$path"; done

Test set results (r318, 2011-09-27, 40 tracks x 3 bitrates):
  320 kbps MP3   94 %  top-1 correct
  192 kbps MP3   86 %
  128 kbps MP3   71 %
  false positive (conf >= 0.5, wrong track):  ~8 %, mostly 128 BPM tech-house

Echoprint (echoprint-codegen, built 2011-07-12) results kept in
/srv/eval/echoprint/ - not committed (license of test audio).
