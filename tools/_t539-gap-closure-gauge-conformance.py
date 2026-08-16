#!/usr/bin/env python3
"""T-539 teeth — every watching gap's closure gauge must return a verdict the reader accepts.

A gap's `closure_check_command:` is the mechanical half of its closure condition. The
audit already checks the PROSE half (`check_gap_triggers`, T-382, audit.sh:2175 — it
verifies `decision_trigger` is present and sits under the key `fw gaps` renders). Nothing
checked that the COMMAND produces something the consumer can read.

THE CONTRACT LIVES IN THE READER, NOT IN THE NEIGHBOURING ENTRIES
    `lib/gaps.py:run_closure_gauge` requires ALL of:
      1. the command runs and exits 0        <- rc is "did the gauge run", NOT the state
      2. stdout parses as JSON (whole stdout, so no prose alongside it)
      3. the object carries verdict: READY|NOT_READY, or ready: true|false
    Anything else normalises to UNKNOWN, and `close_gap` refuses 412 on non-READY. So a
    non-conforming gauge fails SAFE — nothing can be wrongly closed — but it renders
    identically to "gauge unavailable or broken" in `fw gaps` and on the Watchtower gaps
    page, and one-click closure can never succeed for that gap no matter what the tree does.

WHY THIS PROBE EXISTS (the failure it was written from)
    Measured at T-539: 6 of 32 watching gaps carried a command; 4 conformed and 2 did not.
    Both non-conforming entries were written by this agent — G-038 (T-536) and G-039
    (T-538), the latter authored by explicitly copying G-038's shape roughly an hour before
    this probe. The defect propagated by imitating the adjacent register entry instead of
    reading the consumer. G-038 additionally used the EXIT CODE to signal "stranded",
    which is the channel the reader uses for "the gauge itself failed" — two meanings on
    one wire, and the stricter one wins.

    This probe therefore drives the REAL `run_closure_gauge` rather than reimplementing its
    parsing. A reimplementation would encode my understanding of the contract, which is
    precisely the thing that was wrong.

Exit codes:  0 = green   1 = a gauge is unreadable   2 = REFUSE (stimulus not established)
"""

import hashlib
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAPS_PY = os.path.join(ROOT, ".agentic-framework", "lib", "gaps.py")
CONCERNS = os.path.join(ROOT, ".context", "project", "concerns.yaml")


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_reader():
    spec = importlib.util.spec_from_file_location("aef_gaps", GAPS_PY)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    if not hasattr(mod, "run_closure_gauge"):
        refuse("lib/gaps.py has no run_closure_gauge — the consumer contract moved")
    return mod


def main():
    for p in (GAPS_PY, CONCERNS):
        if not os.path.isfile(p):
            refuse("missing %s" % p)

    import yaml

    before = sha256(CONCERNS)
    reader = load_reader()
    data = yaml.safe_load(open(CONCERNS, encoding="utf-8")) or {}
    gaps = data.get("concerns", data.get("gaps", [])) or []
    watching = [g for g in gaps if g.get("status") == "watching"]
    withcmd = [g for g in watching if (g.get("closure_check_command") or "").strip()]

    if not watching:
        refuse("no watching gaps in the register — nothing to evaluate")
    if not withcmd:
        refuse("no watching gap carries a closure_check_command; a green run here would "
               "mean 'none exist', which reads exactly like 'all are fine'")

    failures = []

    # ── Anti-vacuity, run through the SAME reader, before trusting any real verdict. ──
    probes = [
        ("prose-only (the G-039 shape)",
         "python3 -c \"print('CTL-029 collision=PRESENT')\"", "UNKNOWN"),
        ("conforming NOT_READY",
         "python3 -c \"import json;print(json.dumps({'verdict':'NOT_READY'}))\"", "NOT_READY"),
        ("conforming READY",
         "python3 -c \"import json;print(json.dumps({'ready':True}))\"", "READY"),
        # The trap that bit G-038: a PERFECTLY conforming JSON verdict is still discarded
        # when the command signals state through its exit code.
        ("conforming JSON but exits 1 (the G-038 shape)",
         "python3 -c \"import json,sys;print(json.dumps({'verdict':'NOT_READY'}));sys.exit(1)\"",
         "UNKNOWN"),
    ]
    for label, cmd, expected in probes:
        got, _raw = reader.run_closure_gauge(cmd, project_root=ROOT)
        if got != expected:
            failures.append("anti-vacuity: %s -> %s, expected %s; the reader's contract "
                            "moved and every verdict below is being judged against the "
                            "wrong rule" % (label, got, expected))

    # ── The real register. ──
    results = []
    for g in withcmd:
        verdict, raw = reader.run_closure_gauge(g["closure_check_command"], project_root=ROOT)
        first = ""
        for line in (raw or "").splitlines():
            if line.strip():
                first = line.strip()[:110]
                break
        results.append((g.get("id"), verdict, first or "(no output)"))
        if verdict == "UNKNOWN":
            failures.append("%s: gauge is UNREADABLE (rc!=0, stdout not pure JSON, or no "
                            "verdict/ready key). It can never report READY, so one-click "
                            "closure is impossible and `fw gaps` cannot distinguish it from "
                            "a broken gauge. First output line: %s" % (g.get("id"), first))

    after = sha256(CONCERNS)
    if before != after:
        failures.append("concerns.yaml changed during the run (%s -> %s) — this probe must "
                        "only read the register" % (before[:12], after[:12]))

    print("T-539 gap closure gauge conformance — %d watching gap(s), %d carrying a command"
          % (len(watching), len(withcmd)))
    for gid, verdict, first in results:
        print("    %-8s %-10s %s" % (gid, verdict, first))
    print("    (%d watching gap(s) carry no command at all — prose-only closure conditions, "
          "which is what audit.sh's check_gap_triggers covers)" % (len(watching) - len(withcmd)))

    if failures:
        print("\n%d finding(s):" % len(failures))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("\nall %d gauge(s) return a verdict the reader accepts" % len(withcmd))
    return 0


if __name__ == "__main__":
    sys.exit(main())
