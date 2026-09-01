#!/usr/bin/env python3
"""_t358-teeth.py — prove the lane-provenance leg can FAIL, and fail for the right reason.

A green probe is not evidence until it has been shown to go red. This mutates the
SOURCE (a temp copy — the tree is never touched) and the FIXTURES, and requires each
mutation to move the verdict in the predicted direction.

The cases are chosen so that a probe which merely echoes its own input would survive
none of them:

  1. collapse (iii) into (ii)      -> "NOT separable: 4 fixtures produced 3 distinct"
  2. collapse ALL defaults to one  -> not separable, 2 distinct
  3. delete the provenance field   -> "partition is not total"
  4. default the negative control  -> "negative control was DEFAULTED"
  5. change defaultLanes authority -> the fabricated-sovereignty assertion goes unpinned
  6. control's lanes not input-derived -> control check fires independently of provenance

Case 5 is the one worth arguing for: without it the leg would still pass if someone
quietly changed which authority a fabricated lane asserts — and the ASSERTION, not the
lane count, is the defect this task names.

Usage: python3 tools/_t358-teeth.py     Exit 0 = every mutation moved the verdict.
"""
import os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
PROBE = os.path.join(HERE, "_t358-lane-provenance-cdp.mjs")
FIX = os.path.join(ROOT, "tests", "fixtures", "lane-provenance")


def run_probe(root):
    """Run the probe against a mutated tree copy. Returns (rc, output)."""
    p = subprocess.run([shutil.which("node"), os.path.join(root, "tools", "_t358-lane-provenance-cdp.mjs")],
                       capture_output=True, text=True, timeout=900)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def local_deps(entry, _seen=None):
    """Every sibling .mjs the probe pulls in, transitively, derived from its source.

    T-665: this list used to be the literal tuple
    ("_t358-lane-provenance-cdp.mjs", "gallery-serve.py"). On 2026-08-26 T-604 added
    `import { pageWsUrl } from './_cdp-attach.mjs'` to the probe and did not update the
    tuple, so every temp copy from that day on was missing a module the probe imports.
    The control died on ERR_MODULE_NOT_FOUND and every mutation below it stopped meaning
    anything — silently, for a week, because a broken control reports ABSTAINED and the
    sweep reads abstention as acceptable.

    A hand-maintained dependency list is a claim that has to be re-checked by hand every
    time an import changes, which is the same shape as the aged pin in T-663 and the
    stale exclusion in PL-305. Deriving it from the file means the next import cannot
    desynchronise it: adding one updates this automatically, and a missing file is a
    loud COULD-NOT-MEASURE rather than a control that fails for an unrelated reason.
    """
    seen = _seen if _seen is not None else set()
    name = os.path.basename(entry)
    if name in seen:
        return seen
    seen.add(name)
    path = os.path.join(HERE, name)
    if not os.path.exists(path):
        print("COULD-NOT-MEASURE: the probe imports '%s', which is not in tools/" % name,
              file=sys.stderr)
        sys.exit(3)
    src = open(path, encoding="utf-8").read()
    # `from './x.mjs'` / `from "./x.mjs"`, plus bare `import './x.mjs'` side-effect form.
    for m in re.finditer(r"""(?:from|import)\s+['"]\./([A-Za-z0-9_.-]+\.mjs)['"]""", src):
        local_deps(m.group(1), seen)
    return seen


def mutated_tree():
    """A full temp copy of the pieces the probe touches. The real tree is never edited."""
    d = tempfile.mkdtemp(prefix="t358-teeth-")
    for sub in ("src", "tools", os.path.join("tests", "fixtures", "lane-provenance")):
        os.makedirs(os.path.join(d, sub), exist_ok=True)
    shutil.copy2(SRC, os.path.join(d, "src", "aef-workflow-designer.html"))
    for f in sorted(local_deps("_t358-lane-provenance-cdp.mjs")) + ["gallery-serve.py"]:
        shutil.copy2(os.path.join(HERE, f), os.path.join(d, "tools", f))
    for f in os.listdir(FIX):
        shutil.copy2(os.path.join(FIX, f), os.path.join(d, "tests", "fixtures", "lane-provenance", f))
    return d


def edit_src(root, old, new, required=True):
    p = os.path.join(root, "src", "aef-workflow-designer.html")
    s = open(p, encoding="utf-8").read()
    if old not in s:
        if required:
            # T-666: was a bare-string SystemExit, which exits 1 — a REGRESSION verdict
            # about the subject, for a condition that is entirely about these teeth.
            print(f"TEETH BROKEN — anchor not found in source: {old[:70]!r}")
            raise SystemExit(4)
        return False
    open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
    return True


def edit_fixture(root, name, old, new):
    p = os.path.join(root, "tests", "fixtures", "lane-provenance", name)
    s = open(p, encoding="utf-8").read()
    if old not in s:
        # T-666: same as above — dead teeth, not a regression in what they guard.
        print(f"TEETH BROKEN — anchor not found in {name}: {old[:50]!r}")
        raise SystemExit(4)
    open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))


results = []


def case(desc, mutate, expect_substr):
    root = mutated_tree()
    try:
        mutate(root)
        rc, out = run_probe(root)
        if rc == 0:
            results.append((desc, False, "probe still PASSED after the mutation"))
            return
        if expect_substr.lower() not in out.lower():
            results.append((desc, False, f"went red, but not for the predicted reason (wanted {expect_substr!r})"))
            return
        results.append((desc, True, "red, for the predicted reason"))
    finally:
        shutil.rmtree(root, ignore_errors=True)


# --- control: unmutated copy must PASS, or every red below is meaningless ----------
ctl_root = mutated_tree()
try:
    rc, out = run_probe(ctl_root)
finally:
    shutil.rmtree(ctl_root, ignore_errors=True)
if rc != 0:
    print("TEETH BROKEN — the UNMUTATED copy fails, so no mutation below proves anything.")
    print(out[-1500:])
    raise SystemExit(4)  # T-666: DEAD CONTROL, was 2 (which reads as an honest abstention)
print("control: unmutated copy PASSES\n")

# 1. Collapse (iii) into (ii): drop the later-laneSet branch.
case("cause (iii) collapsed into (ii) — our own first-only read hidden behind the input's shape",
     lambda r: edit_src(r,
         "  } else if (laneSets.some((ls, i) => i > 0 && byBpmn(ls, 'lane').length > 0)) {\n    laneProvenance = 'defaulted:later-laneset-ignored';\n",
         "  } else if (false) {\n    laneProvenance = 'defaulted:later-laneset-ignored';\n"),
     "not separable")

# 2. Collapse every defaulted cause into one verdict — the pre-T-358 world.
case("all three defaulted causes collapsed to one verdict (the defect as filed)",
     lambda r: edit_src(r,
         "  } else if (!laneSets.length) {\n    laneProvenance = 'defaulted:no-laneset';\n",
         "  } else if (true) {\n    laneProvenance = 'defaulted';\n"),
     "not separable")

# 3. Remove the field from the returned state entirely.
case("laneProvenance never reaches state — the partition is not observable at all",
     lambda r: edit_src(r, "    laneProvenance,\n", "\n"),
     "not total")

# 4. Default the negative control by stripping its lanes.
case("negative control stripped of its authored lanes — control must stop reporting 'no fabrication'",
     lambda r: edit_fixture(r, "authored-lanes.bpmn",
         '<bpmn:lane id="Lane_ops" name="Operations">\n        <bpmn:flowNodeRef>Task_1</bpmn:flowNodeRef>\n      </bpmn:lane>\n      <bpmn:lane id="Lane_fin" name="Finance"/>',
         ""),
     "negative control")

# 5. The assertion, not the count: change what a fabricated lane claims.
case("defaultLanes() first lane no longer asserts sovereignty — the named defect goes unpinned",
     lambda r: edit_src(r, "authority: 'sovereignty'", "authority: 'none'"),
     "sovereignty")

# 6. Control's lanes replaced with names that are NOT input-derived.
case("negative control's lane names diverge from its input — 'input-derived' check must fire",
     lambda r: edit_fixture(r, "authored-lanes.bpmn", 'name="Operations"', 'name="Fabricated"'),
     "input-derived")

print()
ok = True
for desc, good, why in results:
    print(f"  [{'ok  ' if good else 'FAIL'}] {desc}\n         -> {why}")
    ok = ok and good

print()
if not ok:
    print("TEETH FAIL — at least one mutation did not move the verdict as predicted.")
    sys.exit(1)
print(f"TEETH PASS — control green, {len(results)} mutations each red for their own predicted reason.")
sys.exit(0)
