#!/usr/bin/env python3
"""T-1432: apply T-353's proven patch set to the archived Verification lines (operator ruling 2026-11-17: "a").

The 23 lines and their new forms come from the T-353 tools themselves, not from a copy:
  - 19 conversions: the PROVEN members of docs/reports/T-352-member-scan.md, converted by
    tools/_t353-convert.py's convert() (`|| true` inside each VAR=$(...) capture; arithmetic untouched).
  - 4 repairs: in T-288 (2 lines), T-298 and T-299, `grep -q "VALID"` -> `grep -q "^VALID"` on a validate-workflow.py
    line (tools/_t353-repair-probe.sh: the validator prints VALID and INVALID at column 0, so the anchor is the fix).

Archived task files are closed records (the T-4285 gate), so this runs from the operator's session (runme job 155).

  --check   (default) list the 23 edits and refuse unless every original line occurs exactly once; writes nothing
  --apply   make exactly those 23 replacements, and nothing else in those files
  --verify  after applying: every new line is present, no original line remains, and each converted or repaired
            line passes when run as the gate runs it today (project root, bash)

Exit 0 ok, 1 refused or failed, 2 could not run.
"""
import glob
import importlib.util
import os
import subprocess
import sys

# A one-shot for runme job 155, kept in the job's own folder (not tools/): it is not a standing guard, and the
# unwired-guard census (T-451) rightly counted it as one while it lived under tools/. The project root is four up:
# <root>/.context/runme/155-…/apply_t353.py
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
REPAIR_TASKS = ("T-288", "T-298", "T-299")
# T-299's line cites a scratchpad file outside the repository that no longer exists; its repaired line cannot pass
# and is not meant to (T-353 report §3: the repair cannot fix a stale document). It is applied, not run.
NOT_RUNNABLE = ("T-299",)


def _convert_module():
    spec = importlib.util.spec_from_file_location("t353_convert", os.path.join(ROOT, "tools", "_t353-convert.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def plan():
    """[(task, file, old, new)] for all 23 lines; raises ValueError naming any line not found exactly once."""
    c = _convert_module()
    out, bad = [], []
    for tid, orig in c.extract_members():
        files = glob.glob(os.path.join(ROOT, ".tasks", "completed", "%s-*.md" % tid))
        hits = [(f, open(f).read().count(orig)) for f in files]
        found = [f for f, n in hits if n]
        if len(found) != 1 or sum(n for _, n in hits) != 1:
            bad.append("%s: original line found %s times" % (tid, sum(n for _, n in hits)))
            continue
        out.append((tid, found[0], orig, c.convert(orig)))
    for tid in REPAIR_TASKS:
        for f in glob.glob(os.path.join(ROOT, ".tasks", "completed", "%s-*.md" % tid)):
            for line in open(f).read().splitlines():
                if "validate-workflow.py" in line and 'grep -q "VALID"' in line:
                    if open(f).read().count(line) != 1:
                        bad.append("%s: repair line not unique" % tid)
                        continue
                    out.append((tid, f, line, line.replace('grep -q "VALID"', 'grep -q "^VALID"')))
    if bad:
        raise ValueError("; ".join(bad))
    return out


def main():
    mode = (sys.argv[1] if len(sys.argv) > 1 else "--check")
    try:
        edits = plan()
    except (OSError, ValueError) as e:
        print("REFUSED: %s" % e)
        return 1
    if len(edits) != 23:
        print("REFUSED: expected 23 edits, found %d" % len(edits))
        return 1
    if mode == "--check":
        for tid, f, old, new in edits:
            print("%s  %s\n  - %s\n  + %s" % (tid, os.path.relpath(f, ROOT), old, new))
        print("ok  23 edits, every original line found exactly once")
        return 0
    if mode == "--apply":
        for tid, f, old, new in edits:
            text = open(f).read()
            if text.count(old) != 1:
                print("REFUSED: %s changed under us" % os.path.relpath(f, ROOT))
                return 1
            with open(f, "w") as fh:
                fh.write(text.replace(old, new, 1))
        print("applied 23 edits")
        return 0
    if mode == "--verify":
        fails = []
        for tid, f, old, new in edits:
            text = open(f).read()
            if new not in text:
                fails.append("%s: new line missing" % tid)
            if old != new and old in text:
                fails.append("%s: original line still present" % tid)
            if tid in NOT_RUNNABLE:
                continue
            r = subprocess.run(["bash", "-c", new], cwd=ROOT, capture_output=True, text=True, timeout=180)
            if r.returncode != 0:
                fails.append("%s: the new line does not pass today (rc %d): %s" % (tid, r.returncode, new[:120]))
        for x in fails:
            print("FAIL " + x)
        print("%s: %d failure(s)" % ("PASS" if not fails else "FAIL", len(fails)))
        return 1 if fails else 0
    print("usage: %s [--check|--apply|--verify]" % sys.argv[0])
    return 2


if __name__ == "__main__":
    sys.exit(main())
