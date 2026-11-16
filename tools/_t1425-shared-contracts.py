#!/usr/bin/env python3
"""T-1425: the five Designer-AEF shared contracts, and whether a release moved 832's side of each.

AEF T-5183 paired five AEF contract artifacts with five 832 artifacts. A shared contract nobody owns drifts: each side
changes its artifact and nothing says the pair still agrees. This tool says, for a release, which of 832's paired
artifacts moved since the release before it, and `--check` holds the release notes to it: the notes must carry a
"## Shared contracts" table whose last column says yes or no for each row, as this tool measures it.

Which notes, and which two refs (the T-1315 rule, as tests/test_t1289_host_contract_notes.py):
  the newest docs/releases/RELEASE-NOTES-<v>.md with v >= VERSION.
  - tag designer-v<v> exists (the release is cut): compare the release before it with that tag.
  - not yet (drafted notes for the next release): compare designer-v<VERSION> with HEAD.

What counts as moving 832's side:
  - the designer page (rows 1, 4, 5): src/aef-workflow-designer.html, ignoring the APP_VERSION line, which every
    release changes and no contract reads;
  - the kit (row 2): the kit's sources, i.e. docs/authoring-kit (not its calibration records, which are not shipped),
    the validator and the kit builder;
  - the validator (row 3): tools/validate-workflow.py.

The AEF side is pinned by hash prefix as agreed (msg 3fe4f1cf). Where AEF's file is vendored, the tool reports
whether it still matches; that is information for the agent, not a release gate (AEF owns those bytes).

Usage:  _t1425-shared-contracts.py [--version V] [--json]   prints the rows
        _t1425-shared-contracts.py --check                  exit 0 notes agree, 1 they do not, 2 NOT CHECKED
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOTES_DIR = os.path.join(ROOT, "docs", "releases")
CONTRACTS = ".agentic-framework/docs/research/executable-workflow/contracts"

PAGE = ("src/aef-workflow-designer.html",)
KIT = ("docs/authoring-kit", ":(exclude)docs/authoring-kit/calibration-records",
       "tools/validate-workflow.py", "tools/build-authoring-kit.py")
VALIDATOR = ("tools/validate-workflow.py",)

# (number, contract, AEF artifact as agreed, AEF pin (sha256 prefix or None), vendored path or None, 832 artifact, paths)
PAIRS = (
    (1, "Procedure interchange", "contracts v2 `procedure.schema.json` v1", "ac9aaefc",
     CONTRACTS + "/v1/procedure.schema.json", "designer page (export)", PAGE),
    (2, "Mapping / compatibility", "\"designer produces contracts v2\" (AEF T-5184, drafting)", None,
     None, "authoring kit", KIT),
    (3, "Validation / refusal diagnostics", "contracts v2 `refusal.schema.json` v2", "c4148a34",
     None, "validate-workflow.py", VALIDATOR),
    (4, "Runtime projection", "projection schema (AEF T-5185, to be frozen)", None,
     None, "designer page (overlay renderer)", PAGE),
    (5, "Ratification", "`task-lifecycle-contract.md` (frozen T-3386)", None,
     CONTRACTS + "/v1/task-lifecycle-contract.md", "designer page (save/export proposal-only)", PAGE),
)

IGNORED_LINE = re.compile(r"^[-+]const APP_VERSION = '[^']*';$")


def git(*args):
    r = subprocess.run(("git",) + args, cwd=ROOT, capture_output=True, text=True)
    if r.returncode not in (0, 1):
        raise RuntimeError("git %s: %s" % (" ".join(args), r.stderr.strip()))
    return r


def semver(v):
    try:
        return tuple(int(x) for x in v.split("."))
    except ValueError:
        return None


def tags():
    out = git("tag", "-l", "designer-v*").stdout.split()
    return sorted((semver(t[len("designer-v"):]), t) for t in out if semver(t[len("designer-v"):]))


def notes_file(version):
    """The newest RELEASE-NOTES-<v>.md with v >= VERSION (T-1315), as (v, path), or None."""
    base, best = semver(version), None
    for f in os.listdir(NOTES_DIR) if base and os.path.isdir(NOTES_DIR) else []:
        if f.startswith("RELEASE-NOTES-") and f.endswith(".md"):
            v = semver(f[len("RELEASE-NOTES-"):-len(".md")])
            if v and v >= base and (best is None or v > best[0]):
                best = (v, os.path.join(NOTES_DIR, f))
    return best


def refs_for(notes_v, version):
    """(base, head) for the notes of version notes_v (a tuple)."""
    known = tags()
    mine = [t for v, t in known if v == notes_v]
    if mine:
        before = [t for v, t in known if v < notes_v]
        if not before:
            raise RuntimeError("no release before %s to compare with" % mine[0])
        return before[-1], mine[0]
    return "designer-v" + version, "HEAD"


def moved(paths, base, head):
    """True when the paths differ between the refs, ignoring the APP_VERSION line."""
    diff = git("diff", "-U0", base, head, "--", *paths).stdout
    for line in diff.splitlines():
        if line.startswith(("+++", "---")) or not line.startswith(("+", "-")):
            continue
        if not IGNORED_LINE.match(line):
            return True
    return False


def sha(path):
    with open(os.path.join(ROOT, path), "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()


def rows(base, head):
    out = []
    for n, name, aef, pin, vendored, mine, paths in PAIRS:
        aef_state = "awaited from AEF"
        if pin and vendored and os.path.exists(os.path.join(ROOT, vendored)):
            aef_state = "vendored, matches pin" if sha(vendored).startswith(pin) else "vendored, DIFFERS from pin"
        elif pin:
            aef_state = "pinned, not vendored here"
        elif vendored and os.path.exists(os.path.join(ROOT, vendored)):
            aef_state = "vendored, no hash agreed"
        out.append({"n": n, "contract": name, "aef": aef, "pin": pin, "aef_state": aef_state,
                    "artifact": mine, "moved": moved(paths, base, head)})
    return out


def table(rs):
    lines = ["| # | Contract | AEF artifact | 832 artifact | Moved in this release |", "|---|---|---|---|---|"]
    for r in rs:
        aef = r["aef"] + (", " + r["pin"] if r["pin"] else "")
        lines.append("| %d | %s | %s | %s | %s |" % (r["n"], r["contract"], aef, r["artifact"],
                                                  "yes" if r["moved"] else "no"))
    return "\n".join(lines)


def claimed(notes_text):
    """{row number: 'yes'|'no'} from the notes' '## Shared contracts' table, or None when it has none."""
    m = re.search(r"^## Shared contracts\b.*?$(.*?)(?=^## |\Z)", notes_text, re.M | re.S)
    if not m:
        return None
    got = {}
    for line in m.group(1).splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 5 and cells[0].isdigit():
            word = cells[-1].split()[0].lower().strip("*") if cells[-1] else ""
            got[int(cells[0])] = word
    return got


def disagreements(rs, got):
    """What the notes say wrongly or not at all."""
    if got is None:
        return ["the notes have no '## Shared contracts' section"]
    bad = []
    for r in rs:
        want = "yes" if r["moved"] else "no"
        have = got.get(r["n"])
        if have is None:
            bad.append("row %d (%s) is missing" % (r["n"], r["contract"]))
        elif have != want:
            bad.append("row %d (%s) says '%s'; the %s %s between the releases" % (
                r["n"], r["contract"], have, r["artifact"], "moved" if r["moved"] else "did not move"))
    return bad


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--version", help="release whose notes to measure (default: the T-1315 notes pick)")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    try:
        version = open(os.path.join(ROOT, "VERSION")).read().strip()
        if a.version:
            pick = (semver(a.version), os.path.join(NOTES_DIR, "RELEASE-NOTES-%s.md" % a.version))
        else:
            pick = notes_file(version)
        if not pick or not pick[0]:
            print("NOT CHECKED: no release notes at or above VERSION %s" % version)
            return 2
        base, head = refs_for(pick[0], version)
        rs = rows(base, head)
    except (OSError, RuntimeError) as e:
        print("NOT CHECKED: %s" % e)
        return 2
    rel = os.path.relpath(pick[1], ROOT)
    if a.json:
        print(json.dumps({"notes": rel, "base": base, "head": head, "rows": rs}, indent=1))
    elif not a.check:
        print("%s (%s..%s)\n\n%s" % (rel, base, head, table(rs)))
    if not a.check:
        return 0
    try:
        text = open(pick[1]).read()
    except OSError as e:
        print("NOT CHECKED: %s" % e)
        return 2
    bad = disagreements(rs, claimed(text))
    if bad:
        print("FAIL: %s does not say which shared-contract artifacts moved (%s..%s):" % (rel, base, head))
        for b in bad:
            print("  - " + b)
        print("Expected table (paste under '## Shared contracts'):\n\n" + table(rs))
        return 1
    print("ok  %s: shared-contract table agrees (%s..%s)" % (rel, base, head))
    return 0


if __name__ == "__main__":
    sys.exit(main())
