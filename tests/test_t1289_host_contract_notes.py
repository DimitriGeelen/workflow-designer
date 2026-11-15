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


def _tool():
    """The host-contract tool as a module (its file name has hyphens, so no plain import)."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("t1289_host_contract", TOOL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def unnamed(missing, notes_text):
    """The missing endpoints the notes do not name."""
    return [m for m in missing if m not in notes_text]


def _semver(v):
    try:
        return tuple(int(x) for x in v.split("."))
    except ValueError:
        return None


def notes_file(notes_dir, version):
    """T-1315: the newest RELEASE-NOTES-<v>.md with v >= VERSION, or None. VERSION moves only inside the release job, so
    between releases src can already call an endpoint the last (published) release does not; the next release's drafted
    notes are the ones that must name it. Never a lower version's notes."""
    base = _semver(version)
    best = None
    for f in os.listdir(notes_dir) if base and os.path.isdir(notes_dir) else []:
        if not (f.startswith("RELEASE-NOTES-") and f.endswith(".md")):
            continue
        v = _semver(f[len("RELEASE-NOTES-"):-len(".md")])
        if v and v >= base and (best is None or v > best[0]):
            best = (v, os.path.join(notes_dir, f))
    return best[1] if best else None


def main():
    r = subprocess.run([sys.executable, TOOL, "--json"], capture_output=True, text=True)
    if r.returncode == 2:
        print("FAIL: host contract NOT CHECKED: %s" % r.stdout.strip())
        return 1
    data = json.loads(r.stdout)
    version = open(os.path.join(ROOT, "VERSION"), encoding="utf-8").read().strip()
    notes_path = notes_file(os.path.join(ROOT, "docs", "releases"), version)
    if not notes_path:
        print("FAIL: no release notes for VERSION %s or newer in docs/releases" % version)
        return 1
    notes = open(notes_path, encoding="utf-8").read()
    named_file = os.path.basename(notes_path)

    fails = []
    gaps = unnamed(data["missing"], notes)
    if gaps:
        fails.append("%s does not name designer endpoint(s) AEF does not serve: %s. Tell AEF in "
                     "the notes (the For-AEF section), so the release AEF pins says which features are off there."
                     % (named_file, ", ".join(gaps)))
    # negative control: the check must bite on a gap the notes do not name
    if not unnamed(data["missing"] + ["/api/zz-t1289-control"], notes):
        fails.append("negative control did not fire: an unnamed synthetic endpoint passed the check")

    # T-1414: declined endpoints are reported apart, each with its ruling, and never hide a real gap
    declined = data.get("declined")
    if not isinstance(declined, dict):
        fails.append("the tool's --json carries no 'declined' map (T-1414)")
        declined = {}
    for d, why in declined.items():
        if d in data["missing"] or d in data["served"] or not str(why).strip():
            fails.append("declined endpoint %s is also counted as missing/served, or carries no ruling" % d)
    classify = getattr(_tool(), "classify", None)
    if classify is None:
        fails.append("the tool has no classify(used, served, declined) to run the controls through (T-1414)")
    else:
        _, dec, miss = classify(["/api/a", "/api/b"], set(), {"/api/a": "ruling"})
        if miss != ["/api/b"] or dec != ["/api/a"]:
            fails.append("control: an endpoint neither served nor declined must count as missing (got %r)" % miss)
        ok, dec, _ = classify(["/api/a"], {"/api/a"}, {"/api/a": "ruling"})
        if ok != ["/api/a"] or dec:
            fails.append("control: a declined endpoint AEF now serves must count as served, not declined")

    for f in fails:
        print("FAIL: " + f)
    if fails:
        return 1
    print("OK: host contract %d used, %d served, %d missing, %d declined with a ruling; every missing endpoint is named"
          " in %s (VERSION %s); negative control fires; declined never hides a gap and served wins (T-1414)"
          % (len(data["used"]), len(data["served"]), len(data["missing"]), len(declined), named_file, version))
    return 0


if __name__ == "__main__":
    sys.exit(main())
