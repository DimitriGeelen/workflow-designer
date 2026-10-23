#!/usr/bin/env python3
"""T-1289: every designer endpoint AEF's Watchtower does not answer is named in the current release's notes.

AEF went 13-25 days without 4 designer endpoints because nothing compared the two and no release note said so
(T-1285 spike 4). tools/_t1289-host-contract.py measures the gap; this leg makes it a release-time fact: a NEW gap
fails the suite until docs/releases/RELEASE-NOTES-<VERSION>.md names it, so AEF is told in the notes it pins from.

Negative control: a synthetic missing endpoint that no note names must make the check fail. A guard whose failure was
never demonstrated is a guard nobody has reason to trust (T-560).
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, "tools", "_t1289-host-contract.py")


def unnamed(missing, notes_text):
    """The missing endpoints the notes do not name."""
    return [m for m in missing if m not in notes_text]


def main():
    r = subprocess.run([sys.executable, TOOL, "--json"], capture_output=True, text=True)
    if r.returncode == 2:
        print("FAIL: host contract NOT CHECKED: %s" % r.stdout.strip())
        return 1
    data = json.loads(r.stdout)
    version = open(os.path.join(ROOT, "VERSION"), encoding="utf-8").read().strip()
    notes_path = os.path.join(ROOT, "docs", "releases", "RELEASE-NOTES-%s.md" % version)
    if not os.path.exists(notes_path):
        print("FAIL: no release notes for VERSION %s at %s" % (version, notes_path))
        return 1
    notes = open(notes_path, encoding="utf-8").read()

    fails = []
    gaps = unnamed(data["missing"], notes)
    if gaps:
        fails.append("RELEASE-NOTES-%s.md does not name designer endpoint(s) AEF does not serve: %s. Tell AEF in "
                     "the notes (the For-AEF section), so the release AEF pins says which features are off there."
                     % (version, ", ".join(gaps)))
    # negative control: the check must bite on a gap the notes do not name
    if not unnamed(data["missing"] + ["/api/zz-t1289-control"], notes):
        fails.append("negative control did not fire: an unnamed synthetic endpoint passed the check")

    for f in fails:
        print("FAIL: " + f)
    if fails:
        return 1
    print("OK: host contract %d used, %d served, %d missing; every missing endpoint is named in RELEASE-NOTES-%s.md;"
          " negative control fires" % (len(data["used"]), len(data["served"]), len(data["missing"]), version))
    return 0


if __name__ == "__main__":
    sys.exit(main())
