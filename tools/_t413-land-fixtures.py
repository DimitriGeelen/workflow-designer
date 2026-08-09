#!/usr/bin/env python3
"""_t413-land-fixtures.py — materialise AEF's two T-406 fixtures from the rail.

OBS-108 shuts the file channel between the two projects, so AEF posted the bytes inline
as base64 at rail offsets 504/505. This lands them.

THE HASH IS TAKEN ON THE DECODED BUFFER, BEFORE ANY WRITE. Hashing the file afterwards
would prove the write succeeded, which nobody doubted; the thing under test is the
transfer. If the digest does not match, nothing is written at all — a wrong-bytes fixture
on disk is worse than no fixture, because every later measurement silently inherits it.

Source of truth for the digests is AEF's rail 506 §1, transcribed here so a later reader
can see what was claimed without re-reading the rail. Both refer to their commit 4f9a42926.

Usage: _t413-land-fixtures.py <rail-state.json> <dest-dir>
Exit 0 = both landed and verified. 2 = digest mismatch, missing offset, or harness error.
"""
import base64
import hashlib
import json
import os
import re
import sys

# (rail offset, expected filename, expected byte length, expected sha256) — from rail 506 §1.
EXPECT = [
    (504, "t406-clean-leading-boilerplate.bpmn", 8918,
     "bbc6269dacc06991c5ab8df6e7231f7e58f5882605d7475dbdd81d4c27befd9c"),
    (505, "t406-incidental-leading-boilerplate.bpmn", 15172,
     "04ae662f09ef27d19bbf4968219e3a4cf5beb7b4e94209c086928ae043f26c41"),
]

RE_B64 = re.compile(r"---BEGIN BASE64---\s*(.*?)\s*---END BASE64---", re.S)


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    rail, dest = sys.argv[1], sys.argv[2]
    rows = json.load(open(rail, encoding="utf-8"))
    by_offset = {r["offset"]: r for r in rows if isinstance(r, dict) and "offset" in r}

    landed = []
    for off, name, want_len, want_sha in EXPECT:
        row = by_offset.get(off)
        if row is None:
            print("ERROR: rail offset %d absent from the capture" % off, file=sys.stderr)
            return 2
        m = RE_B64.search(row.get("payload") or "")
        if not m:
            print("ERROR: offset %d carries no BEGIN/END BASE64 block" % off, file=sys.stderr)
            return 2
        raw = base64.b64decode("".join(m.group(1).split()))

        # --- the gate, before the write -------------------------------------------------
        got_sha = hashlib.sha256(raw).hexdigest()
        if len(raw) != want_len or got_sha != want_sha:
            print("ERROR: offset %d FAILED VERIFICATION — nothing written." % off, file=sys.stderr)
            print("  bytes  want %d  got %d" % (want_len, len(raw)), file=sys.stderr)
            print("  sha256 want %s\n         got %s" % (want_sha, got_sha), file=sys.stderr)
            return 2

        os.makedirs(dest, exist_ok=True)
        with open(os.path.join(dest, name), "wb") as fh:
            fh.write(raw)
        print("  ok  %-42s %6d bytes  sha256 %s… (verified pre-write)"
              % (name, len(raw), got_sha[:12]))
        landed.append(name)

    print("\nlanded %d fixture(s) into %s" % (len(landed), dest))
    return 0


if __name__ == "__main__":
    sys.exit(main())
