#!/usr/bin/env python3
"""T-876: every corpus map keeps declaring its workflow kind, in both forms.

All 24 maps of examples/aef-processes/ were marked kind=documentation on 2026-11-14 (aef:workflowMeta/@kind in the
rendered BPMN, workflowMeta.kind in the YAML source), as AEF asked; AEF's resolver uses it to tell documentation maps
from work plans. A map that loses it in either form reads as UNSET again, silently.

Legs:
  1. tools/set-workflow-kind.py documentation --check exits 0 on the corpus ("24 of 24").
  2. CONTROL: on a scratch copy of the corpus with the kind stripped from one rendered map, the same check exits 1 and
     names that map — so leg 1 can fail.
Exit 0 = both legs pass.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, "tools", "set-workflow-kind.py")
fails = []


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


def check(root):
    p = subprocess.run([sys.executable, os.path.join(root, "tools", "set-workflow-kind.py"), "documentation", "--check"],
                       capture_output=True, text=True, timeout=120)
    return p.returncode, p.stdout + p.stderr


def main():
    rc, out = check(ROOT)
    leg(rc == 0 and "declared in both forms" in out, "1 every corpus map declares kind=documentation in both forms",
        out.strip().splitlines()[0] if out.strip() else "no output")

    with tempfile.TemporaryDirectory() as tmp:
        os.makedirs(os.path.join(tmp, "tools"))
        shutil.copy(TOOL, os.path.join(tmp, "tools"))
        shutil.copytree(os.path.join(ROOT, "examples", "aef-processes"), os.path.join(tmp, "examples", "aef-processes"),
                        ignore=shutil.ignore_patterns("*.png"))
        victim = os.path.join(tmp, "examples", "aef-processes", "rendered", "arc-lifecycle.bpmn")
        text = open(victim).read()
        stripped = text.replace(' kind="documentation"', "", 1)
        open(victim, "w").write(stripped)
        rc2, out2 = check(tmp)
        leg(stripped != text and rc2 == 1 and "missing: arc-lifecycle" in out2,
            "2 control: stripping the kind from one rendered map makes the check fail and name it",
            "rc=%d" % rc2)

    print("=== %d failed ===" % len(fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
