#!/usr/bin/env python3
"""T-448 teeth — a gate that names the wrong subsystem sends every reader to the wrong place.

`tools/bake-clean-layout.py --check` fails for two unrelated reasons: the LAYOUT is not a
fixpoint (Clean would move nodes, or the map is messy) or the SERIALIZATION differs (the
emitter changed under a corpus nobody re-baked). Those have different owners and different
risk, so T-448 made the verdict name which one. It named it from the driver's `moved` counter.

That counter is the wrong source, and the reason was already written in the same file, three
lines above the call site, at T-300:

    In-state metrics (moved/netMoved) are unreliable proxies — adoptImportedXml normalizes
    coordinates on import, so transient/net movement can be nonzero while the serialization
    is byte-stable (T-300: audit-process + error-escalation-ladder).

Those are the exact two maps it mislabelled. Measured 2026-08-17 over seven consecutive
deterministic runs: `audit-process` reports moved=5 and `error-escalation-ladder` moved=9,
while a real re-bake in an isolated worktree changes their committed bytes by the same +2/-1
serialization delta as the other twenty-two — no geometry at all. So two of twenty-four maps
were being sent into the layout engine for a byte problem, by the repair for being sent into
the layout engine for a byte problem.

The verdict now comes from the DIFF. These legs drive `classify_drift` directly over
synthetic (committed, re-emitted) pairs built from the corpus's real delta shape, because the
production path needs a headless browser and 24 maps to say one thing about one function.

Leg 3 is the bug this classifier committed on its own first run: the DI trailer the corpus is
stale against reads `node geometry travels as aef:position`, so a substring test found the
marker in PROSE and relabelled all 24 maps LAYOUT+SERIALIZATION. Kept as a leg rather than
fixed and forgotten — a classifier keyed on substrings has to say what counts as the
substring appearing.

Seam: T448_TOOL points at a copy of the tool, so a reconstructed pre-fix classifier can be
shown to turn these legs red without editing the tracked file (PL-206).

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.environ.get("T448_TOOL") or os.path.join(ROOT, "tools", "bake-clean-layout.py")

# The corpus's real staleness, verbatim from `git diff` of a re-bake run in an isolated
# worktree on 2026-08-17. Paraphrasing a stimulus makes it a different stimulus.
COMMITTED = """<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:aef="urn:aef:workflow"
                  id="defs_1">
  <!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->
  <bpmn:process id="p1">
    <bpmn:task id="t1" name="Do the thing" aef:position="120,240" />
  </bpmn:process>
</bpmn:definitions>
"""

REEMITTED = """<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:aef="urn:aef:workflow"
                  exporter="aef-workflow-designer"
                  id="defs_1">
  <!-- BPMN DI (visual layout) omitted; node geometry travels as aef:position -->
  <bpmn:process id="p1">
    <bpmn:task id="t1" name="Do the thing" aef:position="120,240" />
  </bpmn:process>
</bpmn:definitions>
"""

MOVED_GEOMETRY = REEMITTED.replace('aef:position="120,240"', 'aef:position="180,300"')
MOVED_DI = REEMITTED.replace(
    '    <bpmn:task id="t1" name="Do the thing" aef:position="120,240" />',
    '    <bpmn:task id="t1" name="Do the thing" aef:position="120,240" />\n'
    '    <dc:Bounds x="180" y="300" width="100" height="80" />')


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no leg was evaluated.")
    sys.exit(2)


def load_tool():
    if not os.path.isfile(TOOL):
        refuse("%s not found — there is no classifier to drive" % TOOL)
    spec = importlib.util.spec_from_file_location("bake_clean_layout", TOOL)
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
    except SystemExit:
        refuse("importing %s ran its main path and exited; the classifier could not be "
               "reached, so nothing below was measured" % TOOL)
    for name in ("classify_drift", "changed_lines"):
        if not hasattr(mod, name):
            refuse("%s has no %s(); the verdict is no longer computed by a function this "
                   "probe can drive, so its green would be about nothing" % (TOOL, name))
    return mod


def main():
    mod = load_tool()

    failures = []
    passes = 0

    def leg(name, ok, detail=""):
        nonlocal passes
        if ok:
            passes += 1
            print("  PASS  %s" % name)
        else:
            failures.append(name)
            print("  FAIL  %s%s" % (name, ("\n        " + detail) if detail else ""))

    # ── leg 1: the reported defect ─────────────────────────────────────────────────────────
    why, layout_bad = mod.classify_drift(COMMITTED, REEMITTED, moved=5, messiness=0)
    leg("1 a non-zero `moved` with no geometry in the diff is SERIALIZATION ONLY",
        not layout_bad and "SERIALIZATION ONLY" in why,
        "verdict was %r (layout_bad=%s). This is the T-448 defect verbatim: audit-process "
        "reports moved=5 and error-escalation-ladder moved=9, and neither one's committed "
        "bytes carry a geometry change. Deciding from the counter sends the reader into the "
        "layout engine for a byte problem." % (why, layout_bad))

    # ── leg 2: the driver's counter is still REPORTED, not suppressed ──────────────────────
    # A repair that simply stopped mentioning `moved` would pass leg 1 and lose a real fact
    # about the driver: Clean moved nodes and nothing reached the file.
    leg("2 the non-zero `moved` is still surfaced, with what it means",
        "moved=5" in why and "adoptImportedXml" in why,
        "verdict was %r. In-editor movement that leaves no trace in the bytes is worth "
        "knowing about the driver; it is just not a layout failure. Silence about it would "
        "be a second kind of wrong answer." % why)

    # ── leg 3: a geometry marker in PROSE is not geometry ──────────────────────────────────
    # The bug this classifier committed on its first run. The stimulus is the corpus's own
    # DI trailer, which contains the literal string `aef:position` inside a comment.
    comment_only = COMMITTED.replace(
        "<!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->",
        "<!-- BPMN DI (visual layout) omitted; node geometry travels as aef:position -->")
    why_c, layout_bad_c = mod.classify_drift(COMMITTED, comment_only, moved=0, messiness=0)
    marker_present = any("aef:position" in l and "<!--" in l for l in comment_only.splitlines())
    leg("3 a geometry marker inside an XML comment does not count as geometry",
        marker_present and comment_only != COMMITTED and not layout_bad_c,
        "marker-in-a-comment present in the fixture=%s, verdict was %r (layout_bad=%s). The "
        "corpus's DI trailer says 'node geometry travels as aef:position' — a sentence about "
        "where geometry lives, not a coordinate. On its first run this classifier relabelled "
        "all 24 maps LAYOUT+SERIALIZATION off exactly that line."
        % (marker_present, why_c, layout_bad_c))

    # ── leg 4: a real geometry change is still caught ──────────────────────────────────────
    # Without this, leg 1 is satisfied by a classifier that has stopped discriminating and
    # calls everything serialization — agreeable rather than accurate, and worse than the
    # defect because it hides the case that means 're-run the bake'.
    why2, layout_bad2 = mod.classify_drift(COMMITTED, MOVED_GEOMETRY, moved=0, messiness=0)
    leg("4 a changed aef:position IS layout, even when the driver reports moved=0",
        layout_bad2 and "LAYOUT" in why2,
        "verdict was %r (layout_bad=%s). The counter and the diff can disagree in BOTH "
        "directions; the diff is the one that describes the artifact." % (why2, layout_bad2))

    # ── leg 5: standard BPMN DI counts as geometry too ─────────────────────────────────────
    why3, layout_bad3 = mod.classify_drift(COMMITTED, MOVED_DI, moved=0, messiness=0)
    leg("5 a dc:Bounds change counts as geometry (DI is a second carrier since T-340)",
        layout_bad3 and "LAYOUT" in why3,
        "verdict was %r (layout_bad=%s). T-340 gave geometry two carriers — aef:position and "
        "BPMN DI — so a classifier that knows only ours is blind on any document that "
        "arrived carrying DI." % (why3, layout_bad3))

    # ── leg 6: a messy map is a layout failure even when the bytes match ───────────────────
    why4, layout_bad4 = mod.classify_drift(COMMITTED, COMMITTED, moved=0, messiness=9)
    leg("6 a messy map is LAYOUT even when the serialization is byte-stable",
        layout_bad4 and "LAYOUT" in why4 and "messy" in why4,
        "verdict was %r (layout_bad=%s). Messiness is the other half of the layout question "
        "and it does not show up in a diff against a corpus baked while messy." % (why4, layout_bad4))

    # ── leg 7: anti-vacuity — the diff machinery can see 'no difference' ───────────────────
    # If changed_lines() returned [] for everything, legs 1 and 3 would pass for the wrong
    # reason and this whole file would be certifying a function that never looks.
    same = mod.changed_lines(COMMITTED, COMMITTED)
    differs = mod.changed_lines(COMMITTED, REEMITTED)
    leg("7 the diff reports nothing for identical input and something for the real delta",
        same == [] and len(differs) == 3,
        "identical input produced %d changed line(s) and the real corpus delta produced %d "
        "(expected 0 and 3: one added exporter= line, one comment replaced). If the second "
        "is 0, every leg above passed on a classifier that was shown no difference."
        % (len(same), len(differs)))

    print()
    if failures:
        print("T-448 TEETH: %d/%d legs passed — FAILED: %s"
              % (passes, passes + len(failures), ", ".join(failures)))
        return 1
    print("T-448 TEETH: %d/%d legs passed — the fixpoint gate names the implicated subsystem "
          "from the diff rather than from an in-editor counter, still catches real geometry "
          "in both carriers and a messy map, does not mistake a marker in prose for a "
          "coordinate, and reports the counter instead of hiding it" % (passes, passes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
