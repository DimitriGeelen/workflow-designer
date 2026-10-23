# Workflow Designer 0.27.0 — release notes (DRAFT)

**Status: DRAFT, not released.** `VERSION` and `APP_VERSION` stay 0.26.0 until the release task bumps them.

**Since:** `designer-v0.26.0`.

## Authoring kit

- **Review findings carry map evidence, checked mechanically (T-1290).** REVIEW.md asks each finding for
  `map_evidence: {line, quote}` (or `null` for something absent from the map), and the new `kit/verify-findings.py`
  labels each finding verified / absence / unverified.
  - The production review loop sets unverified findings aside in `review.rN.unverified.json` before anyone acts on
    them.
  - Calibration prints each finding's label. Its PASS/FAIL is unchanged: an unverified finding on the clean map
    still fails it.
  - Origin: in 0.26.0's first calibration a reviewer cited a map line that did not contain what it claimed.

## What changes in stored maps

Nothing.
