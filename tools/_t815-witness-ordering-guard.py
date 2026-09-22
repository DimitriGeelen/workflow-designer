#!/usr/bin/env python3
"""_t815-witness-ordering-guard.py — is the committed witness in step with the emitter?

T-815. Surfaced by T-813's first recorded suite run.

WHAT WENT WRONG, and it is small and quiet. T-690 (66e04cff, 2026-09-09) changed the emitter
to write <bpmn:extensionElements> BEFORE <bpmn:conditionExpression> on a sequence flow. The
witness at tests/fixtures/exported/t423-carrier-witness.bpmn was last committed by T-423
(89bdecdc, 2026-08-23), in the old order. The suite regenerates the witness on every
successful run — deliberately, so the artefact under test is what the CURRENT source emits —
so the file moved correctly the next time anyone ran it. Nobody committed it.

Seventeen days. The only thing that ever noticed was a dirty `git status` after a 742-second
suite that nothing schedules, which is to say: nothing noticed.

WHY A STRUCTURAL CHECK AND NOT "RE-EXPORT AND DIFF". Re-exporting needs a real browser and
300 seconds; a guard that expensive runs as rarely as the suite does, which is the condition
being fixed rather than a fix. This asserts the ORDERING INVARIANT the emitter change
established, directly on the committed bytes, in milliseconds. It cannot catch every possible
drift — only the emitter can do that — but it catches this class, which is the class that
actually happened, and it runs often enough to matter.

WHAT IT ASSERTS. Within every <bpmn:sequenceFlow> that carries BOTH children,
<bpmn:extensionElements> must precede <bpmn:conditionExpression>. A flow carrying only one of
them, or neither, is silent — the invariant is about their relative order, and a flow that
makes no ordering claim cannot violate one.

CANNOT-MEASURE IS NOT A PASS. A missing witness, an unparseable one, or a witness in which NO
flow carries both children all exit non-zero. That last case matters most: if the fixture ever
stops containing the construct, this guard would otherwise pass forever while checking
nothing — the T-312 vacuity class the parity suite already names.

Exit: 0 witness is in step | 1 out of step, or nothing could be measured
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WITNESS = os.environ.get(
    "T815_WITNESS",
    os.path.join(REPO, "tests", "fixtures", "exported", "t423-carrier-witness.bpmn"),
)

FLOW = re.compile(r"<bpmn:sequenceFlow\b.*?</bpmn:sequenceFlow>", re.S)
EXT = re.compile(r"<bpmn:extensionElements\b")
COND = re.compile(r"<bpmn:conditionExpression\b")
FLOW_ID = re.compile(r'<bpmn:sequenceFlow\b[^>]*\bid="([^"]*)"')


def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def main():
    if not os.path.exists(WITNESS):
        fail(f"witness not found: {WITNESS}\n"
             "      A missing witness is not a passing one — the guard has nothing to check.")
    text = open(WITNESS, encoding="utf-8").read()
    if not text.strip():
        fail(f"witness is empty: {WITNESS}")

    flows = FLOW.findall(text)
    if not flows:
        fail("no <bpmn:sequenceFlow> found in the witness. Either the fixture changed shape "
             "or the pattern no longer matches it — both are failures of this guard, not a "
             "clean witness.")

    both = 0
    offenders = []
    for flow in flows:
        m_ext = EXT.search(flow)
        m_cond = COND.search(flow)
        if not (m_ext and m_cond):
            continue          # makes no ordering claim
        both += 1
        if m_ext.start() > m_cond.start():
            fid = FLOW_ID.search(flow)
            offenders.append(fid.group(1) if fid else "<unnamed flow>")

    if both == 0:
        fail("no sequence flow in the witness carries BOTH extensionElements and "
             "conditionExpression, so the ordering invariant was never exercised. A guard "
             "that checks nothing reports the same green as one that checks correctly "
             "(the T-312 vacuity class).")

    print(f"=== T-815 witness ordering guard ===")
    print(f"witness: {os.path.relpath(WITNESS, REPO) if WITNESS.startswith(REPO) else WITNESS}")
    print(f"sequence flows: {len(flows)}   carrying both children: {both}")

    if offenders:
        print()
        print("FAIL: extensionElements must precede conditionExpression (T-690), and does "
              "not on:", file=sys.stderr)
        for o in offenders:
            print(f"  {o}", file=sys.stderr)
        print(file=sys.stderr)
        print("  The committed witness is out of step with the emitter. Regenerate and "
              "commit it:", file=sys.stderr)
        print("    cd %s && node tools/_t423-carrier-agreement-cdp.mjs" % REPO,
              file=sys.stderr)
        print("  This is exactly the drift that sat unreported for 17 days after T-690.",
              file=sys.stderr)
        return 1

    print(f"ok: all {both} flow(s) carry extensionElements before conditionExpression (T-690)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
