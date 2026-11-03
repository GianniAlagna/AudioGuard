# AudioGuard — Discontinuation Note

| Field    | Value                                             |
|----------|---------------------------------------------------|
| Decision | No-go, project frozen                             |
| Date     | 2011-12-09                                        |
| Decided  | Management QT Records (G. Alagna)                 |
| Duration | ~9 months (kick-off 2011-03-07)                   |
| Spend    | ~CHF 38'000 (freelance dev, student, server, legal pre-check) |

## Why we stopped

1. **Whack-a-mole economics.** Manual pilot (Oct 2011, 3 releases): 214 links
   found, 131 notices sent, 96 removed within 7 days (73 %). Within 14 days
   the same releases had 180+ *new* links. Removal did not measurably
   change Beatport/iTunes sales of the pilot releases.
2. **Verification gap.** ~60 % of file-locker links could not be sampled
   without premium accounts or CAPTCHA → fingerprinting could not be applied
   where it mattered; metadata-only hits require human review.
3. **Fingerprint quality.** 71 % hit rate on 128 kbps MP3 test set vs. target
   90 %; ~8 % false positives between same-tempo EDM tracks. Not safe enough
   for automated notices.
4. **Legal uncertainty in CH.** No statutory notice-and-takedown, Logistep
   ruling (BGE 136 II 508) restricted P2P monitoring, no budget for legal
   opinion on automated notices.
5. **Team & focus.** Part-time team; label operations (releases, events,
   distribution deals) had priority. Student developer left after semester.

## What worked

- Catalogue / ISRC data model — reused for distributor reporting.
- FilesTube plugin + manual review proved the scale of the problem with hard
  numbers (useful in talks with distributors and IFPI).
- Notice templates were used manually by label staff through 2012.

## Lessons / what we would do differently

- Monetise instead of only removing (claim & monetise, as YouTube Content ID
  later made standard) — the industry moved there, not to takedowns.
- Pool resources across independent labels (shared service) instead of a
  single-label tool.
- Partner with an existing fingerprint provider instead of building DSP
  in-house.

## Frozen state

All code is left as of the last SVN revision (r412). No further maintenance.
