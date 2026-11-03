#!/usr/bin/env python2.6
# -*- coding: utf-8 -*-
"""
agfp.py - AudioGuard FingerPrint v1 (landmark hashing)

Based on: A. Wang, "An Industrial-Strength Audio Search Algorithm", ISMIR 2003

Usage:
    python2.6 agfp.py index  <track_id> <file.wav>
    python2.6 agfp.py match  <sample.mp3>

STATUS (r377): index works, match ~71% on 128kbps test set. See TODOs.
"""

import sys
import os
import subprocess
import struct
import logging
from collections import defaultdict

import numpy as np
from scipy.ndimage.filters import maximum_filter
# from scipy.signal import butter, lfilter   # highpass experiment, see _highpass()

import MySQLdb

# ---------------------------------------------------------------------------
# Parameters - DO NOT CHANGE without re-indexing the whole catalogue
# ---------------------------------------------------------------------------
SAMPLE_RATE   = 11025
WINDOW        = 1024
HOP           = 512
PEAK_NEIGH    = 20          # neighbourhood size (bins) for local max
AMP_MIN_DB    = 10          # above frame median
FAN_OUT       = 5
DT_MIN        = 1
DT_MAX        = 63          # 6 bit
F_BITS        = 9           # 512 bins -> 9 bit
MAX_SAMPLE_S  = 30

FFMPEG = '/usr/bin/ffmpeg'

DB = dict(host='localhost', user='audioguard', passwd='CHANGEME', db='audioguard', charset='utf8')

log = logging.getLogger('agfp')


# ---------------------------------------------------------------------------
# Decoding
# ---------------------------------------------------------------------------
def decode(path, max_seconds=None):
    """Decode any format ffmpeg understands to mono s16le @ 11025 Hz."""
    cmd = [FFMPEG, '-v', 'quiet', '-i', path, '-ac', '1', '-ar', str(SAMPLE_RATE)]
    if max_seconds:
        cmd += ['-t', str(max_seconds)]
    cmd += ['-f', 's16le', '-']
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    raw, err = p.communicate()
    if p.returncode != 0:
        raise IOError('ffmpeg failed (%d) on %s' % (p.returncode, path))
    samples = np.fromstring(raw, dtype=np.int16).astype(np.float32) / 32768.0
    return samples


def _highpass(samples, cutoff=150.0):
    """Remove kick drum energy (EDM 4/4 problem).
    r377: disabled - makes matching WORSE on radio edits. Investigate."""
    # b, a = butter(4, cutoff / (SAMPLE_RATE / 2.0), btype='high')
    # return lfilter(b, a, samples)
    return samples


# ---------------------------------------------------------------------------
# Spectrogram + peaks
# ---------------------------------------------------------------------------
def spectrogram(samples):
    win = np.hanning(WINDOW)
    n_frames = 1 + (len(samples) - WINDOW) // HOP
    if n_frames <= 0:
        return np.zeros((WINDOW // 2, 0))
    spec = np.empty((WINDOW // 2, n_frames), dtype=np.float32)
    for i in xrange(n_frames):
        frame = samples[i * HOP:i * HOP + WINDOW] * win
        mag = np.abs(np.fft.rfft(frame))[:WINDOW // 2]
        spec[:, i] = 20.0 * np.log10(mag + 1e-10)
    return spec


def find_peaks(spec):
    """Return list of (frame, bin) sorted by frame."""
    local_max = maximum_filter(spec, size=PEAK_NEIGH) == spec
    median = np.median(spec, axis=0)
    above = spec > (median + AMP_MIN_DB)
    f_idx, t_idx = np.nonzero(local_max & above)
    peaks = zip(t_idx, f_idx)
    peaks.sort()
    return peaks


# ---------------------------------------------------------------------------
# Hashing
# ---------------------------------------------------------------------------
def make_hash(f1, f2, dt):
    return ((f1 & 0x1FF) << 15) | ((f2 & 0x1FF) << 6) | (dt & 0x3F)


def hashes(peaks):
    """Yield (hash, anchor_time)."""
    n = len(peaks)
    for i in xrange(n):
        t1, f1 = peaks[i]
        paired = 0
        for j in xrange(i + 1, n):
            t2, f2 = peaks[j]
            dt = t2 - t1
            if dt < DT_MIN:
                continue
            if dt > DT_MAX:
                break
            yield make_hash(f1, f2, dt), t1
            paired += 1
            if paired >= FAN_OUT:
                break


def fingerprint_file(path, max_seconds=None):
    s = decode(path, max_seconds)
    s = _highpass(s)
    return list(hashes(find_peaks(spectrogram(s))))


# ---------------------------------------------------------------------------
# DB
# ---------------------------------------------------------------------------
def db():
    return MySQLdb.connect(**DB)


def index_track(track_id, path):
    fp = fingerprint_file(path)
    log.info('track %s: %d hashes', track_id, len(fp))
    conn = db()
    cur = conn.cursor()
    cur.execute('DELETE FROM fp_hash WHERE track_id = %s', (track_id,))
    # executemany in chunks - 40k rows at once kills max_allowed_packet
    chunk = 5000
    for k in xrange(0, len(fp), chunk):
        rows = [(h, track_id, t) for (h, t) in fp[k:k + chunk]]
        cur.executemany('INSERT INTO fp_hash (hash, track_id, t_offset) VALUES (%s,%s,%s)', rows)
    cur.execute("""REPLACE INTO fingerprint (track_id, algo, num_hashes, created_at)
                   VALUES (%s, 'agfp1', %s, NOW())""", (track_id, len(fp)))
    conn.commit()
    conn.close()
    return len(fp)


def match_sample(path):
    """Return list of (track_id, confidence) best first.
    confidence = aligned hashes / query hashes (0..1)."""
    q = fingerprint_file(path, MAX_SAMPLE_S)
    if not q:
        return []
    q_by_hash = defaultdict(list)
    for h, t in q:
        q_by_hash[h].append(t)

    conn = db()
    cur = conn.cursor()
    # FIXME: IN() with ~3000 values - slow (4-9 s). Use temp table?
    keys = q_by_hash.keys()
    hist = defaultdict(int)
    for k in xrange(0, len(keys), 500):
        part = keys[k:k + 500]
        fmt = ','.join(['%s'] * len(part))
        cur.execute('SELECT hash, track_id, t_offset FROM fp_hash WHERE hash IN (%s)' % fmt, part)
        for h, track_id, t_db in cur.fetchall():
            for t_q in q_by_hash[h]:
                hist[(track_id, t_db - t_q)] += 1
    conn.close()

    best = defaultdict(int)
    for (track_id, delta), cnt in hist.iteritems():
        if cnt > best[track_id]:
            best[track_id] = cnt

    total = float(len(q))
    res = [(tid, round(c / total, 3)) for tid, c in best.iteritems()]
    res.sort(key=lambda x: -x[1])
    # TODO: confidence is not calibrated! 0.85 threshold is a guess (spec 2.2)
    # TODO: same-BPM tracks give 0.2-0.3 background score -> subtract baseline?
    return res[:5]


def main(argv):
    logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
    if len(argv) < 3:
        print __doc__
        return 1
    cmd = argv[1]
    if cmd == 'index' and len(argv) == 4:
        n = index_track(int(argv[2]), argv[3])
        print 'indexed %d hashes' % n
    elif cmd == 'match':
        for tid, conf in match_sample(argv[2]):
            print '%6d  %.3f' % (tid, conf)
    else:
        print __doc__
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
