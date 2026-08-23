#!/usr/bin/env python3
"""_t423-carrier-agreement-teeth.py — prove _t423-carrier-agreement-guard.py DISCRIMINATES.

A guard that has never been watched going red is a guard whose green means nothing yet.
That sentence is AEF's, earned twice over on their own index canary (rail 11876), and it is
why this file exists in the same commit as the guard rather than after it.

THE POPULATION IS REAL, NOT SYNTHETIC. Every mutation below is applied to
tests/fixtures/exported/t423-carrier-witness.bpmn — a document the actual designer actually
emitted, written by tools/_t423-carrier-agreement-cdp.mjs through a real browser. Mutating
a document I wrote by hand would prove the guard can read my own fixtures. The witness is
copied into a mkdtemp for each case and the original is never touched.

WHAT EACH CASE IS FOR, since a list of eight red lights looks the same whether or not it
covers anything:

  1  drift beyond tolerance          the plain assertion — the carriers say different things
  2  drift INSIDE tolerance          anti-overfit: the window is real, not zero-width
  3  shape deleted                   coverage, position-side: DI forgets a node
  4  ONE bpmnElement renamed         THE DECOY. This is the case AEF's question is about.
                                     The join between the carriers is the node id; a naive
                                     "compare the pairs that match" implementation reports
                                     no disagreement here, because the broken node produces
                                     no pair at all.
  5  ALL bpmnElements renamed        the decoy at full strength: zero pairs across the whole
                                     document. The strongest possible disagreement, and the
                                     one a pair-counting guard scores as perfect agreement.
  6  aef:position removed            coverage, DI-side — the direction step 3 (T-424) walks
  7  DI block stripped entirely      must REFUSE (2), not pass. Delete the emitter and this
                                     guard has nothing to compare; "nothing disagreed" and
                                     "nothing was compared" must not print the same verdict.
  8  di:waypoint moved               MUST STAY GREEN. Edge routing is not this guard's
                                     subject and has no rival carrier. Without this leg a
                                     guard that simply reddened on any diff would pass 1-7.

Exit 0 = control green and every mutation produced its expected verdict.
     1 = a mutant survived, or the control was not green.
     2 = the witness is missing (run the cdp probe first), or a case could not run.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
GUARD = os.path.join(HERE, "_t423-carrier-agreement-guard.py")
WITNESS = os.path.join(REPO, "tests", "fixtures", "exported", "t423-carrier-witness.bpmn")

results = []


def run_guard(d):
    p = subprocess.run([sys.executable, GUARD, d], capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr)


def case(name, mutate, expect_rc):
    """`mutate` takes the document text and returns the mutated text. An anchor that has
    gone missing raises rather than returning the text unchanged: a mutation that silently
    applies nothing is a NO-OP MUTANT, and a no-op mutant does not report 'the rule is
    gone', it reports 'the mutant did not die' — which is indistinguishable from a broken
    guard. That mistake was live in _t361-guard-teeth.py yesterday; it is cheaper to
    prevent here than to find there."""
    d = tempfile.mkdtemp(prefix="t423-teeth-")
    try:
        src = open(WITNESS, encoding="utf-8").read()
        try:
            out = mutate(src)
        except Exception as e:
            results.append((name, "ANCHOR GONE", f"{e}"))
            return
        if out == src:
            results.append((name, "NO-OP", "mutation changed nothing — re-point this case"))
            return
        with open(os.path.join(d, "witness.bpmn"), "w", encoding="utf-8") as f:
            f.write(out)
        rc, log = run_guard(d)
        ok = rc == expect_rc
        results.append((name, "ok" if ok else "SURVIVED",
                        f"expected rc={expect_rc}, got rc={rc}" + ("" if ok else "\n      " + log.strip().replace("\n", "\n      "))))
    finally:
        shutil.rmtree(d, ignore_errors=True)


def _nth_bounds_x(text, n, delta, places=1):
    """Shift the x of the nth dc:Bounds by delta.

    `places` is not cosmetic and the no-op detector is why it exists. The sub-tolerance
    case first shifted by 0.04 and re-printed at `.1f`, which rounds STRAIGHT BACK to the
    original string — a mutation that changed nothing, run against a guard that then
    correctly said nothing was wrong. It would have been recorded as "the tolerance window
    works" on the strength of a document that was never mutated. The exporter writes one
    decimal, so any drift smaller than that has to be written with two."""
    ms = list(re.finditer(r'(<dc:Bounds x=")(-?[\d.]+)(")', text))
    if len(ms) <= n:
        raise RuntimeError(f"only {len(ms)} dc:Bounds in the witness — re-point this case")
    m = ms[n]
    return text[:m.start()] + m.group(1) + f"{float(m.group(2)) + delta:.{places}f}" + m.group(3) + text[m.end():]


def _drop_first_shape(text):
    m = re.search(r'[ \t]*<bpmndi:BPMNShape\b.*?</bpmndi:BPMNShape>\n', text, re.S)
    if not m:
        raise RuntimeError("no bpmndi:BPMNShape in the witness — re-point this case")
    return text[:m.start()] + text[m.end():]


def _rename_one_ref(text):
    m = re.search(r'(<bpmndi:BPMNShape[^>]*bpmnElement=")([^"]+)(")', text)
    if not m:
        raise RuntimeError("no BPMNShape/@bpmnElement in the witness — re-point this case")
    return text[:m.start()] + m.group(1) + m.group(2) + "_RENAMED" + m.group(3) + text[m.end():]


def _rename_all_refs(text):
    out, n = re.subn(r'(<bpmndi:BPMNShape[^>]*bpmnElement=")([^"]+)(")', r'\1\2_RENAMED\3', text)
    if not n:
        raise RuntimeError("no BPMNShape/@bpmnElement in the witness — re-point this case")
    return out


def _drop_one_position(text):
    m = re.search(r'[ \t]*<aef:position\b[^>]*/>\n', text)
    if not m:
        raise RuntimeError("no aef:position in the witness — re-point this case")
    return text[:m.start()] + text[m.end():]


def _strip_di(text):
    m = re.search(r'[ \t]*<bpmndi:BPMNDiagram\b.*?</bpmndi:BPMNDiagram>\n', text, re.S)
    if not m:
        raise RuntimeError("no bpmndi:BPMNDiagram in the witness — re-point this case")
    return text[:m.start()] + text[m.end():]


def _add_lane_shape(text):
    """Add a BPMNShape for a CONTAINER (a lane), which legitimately has no aef:position.

    This is the control for the allow-list in the guard's _flow_node_ids. BPMN DI carries
    shapes for pools and lanes; our exporter does not emit them yet, but T-424 or a later
    task may. A guard that treated every id in the BPMN namespace as a flow node would read
    the first lane shape anyone adds as a coverage hole and produce a fleet of violations
    against a document that is more correct than the one before it — a false RED, which
    gets a guard switched off far faster than a false green gets it fixed."""
    m = re.search(r'<bpmn:lane\b[^>]*\bid="([^"]+)"', text)
    if not m:
        raise RuntimeError("no bpmn:lane in the witness — re-point this case")
    lane_id = m.group(1)
    anchor = "    </bpmndi:BPMNPlane>"
    if anchor not in text:
        raise RuntimeError("BPMNPlane close not found — re-point this case")
    shape = (f'      <bpmndi:BPMNShape id="BPMNShape_{lane_id}" bpmnElement="{lane_id}">\n'
             f'        <dc:Bounds x="10.0" y="10.0" width="600" height="200"/>\n'
             f'      </bpmndi:BPMNShape>\n')
    return text.replace(anchor, shape + anchor, 1)


def _move_waypoint(text):
    m = re.search(r'(<di:waypoint x=")(-?[\d.]+)(")', text)
    if not m:
        raise RuntimeError("no di:waypoint in the witness — re-point this case")
    return text[:m.start()] + m.group(1) + f"{float(m.group(2)) + 37.0:.1f}" + m.group(3) + text[m.end():]


def main():
    if not os.path.exists(WITNESS):
        print("REFUSE — witness missing: " + WITNESS.replace(REPO + "/", ""))
        print("  Produce it first: node tools/_t423-carrier-agreement-cdp.mjs")
        return 2

    # CONTROL FIRST. If the unmutated real export is not green, every red below is
    # uninformative — a guard that fails on everything discriminates nothing.
    d = tempfile.mkdtemp(prefix="t423-ctrl-")
    try:
        shutil.copyfile(WITNESS, os.path.join(d, "witness.bpmn"))
        rc, log = run_guard(d)
    finally:
        shutil.rmtree(d, ignore_errors=True)
    if rc != 0:
        print(f"FAIL — CONTROL is not green (rc={rc}) on the unmutated witness:\n{log}")
        return 1
    print("  control: unmutated real export -> PASS")

    case("dc:Bounds x drifts +1.0 from aef:position", lambda s: _nth_bounds_x(s, 0, 1.0), 1)
    case("dc:Bounds x drifts +0.04 (inside tolerance) — MUST STAY GREEN", lambda s: _nth_bounds_x(s, 1, 0.04, places=2), 0)
    case("a BPMNShape is deleted, its aef:position remains", _drop_first_shape, 1)
    case("DECOY: one bpmnElement renamed — the pair vanishes rather than disagreeing", _rename_one_ref, 1)
    case("DECOY at full strength: every bpmnElement renamed — ZERO pairs", _rename_all_refs, 1)
    case("an aef:position is removed, its BPMNShape remains (the T-424 direction)", _drop_one_position, 1)
    case("the whole DI block is stripped — must REFUSE, not pass", _strip_di, 2)
    case("a di:waypoint moves 37px — MUST STAY GREEN (edges are not this guard's subject)", _move_waypoint, 0)
    case("a BPMNShape is added for a LANE, which carries no position — MUST STAY GREEN", _add_lane_shape, 0)

    # Two cases the SINGLE-document helper structurally cannot express, and both are legs
    # the guard only grew because case 5 failed on the first run. A one-document harness
    # would have left them uncovered, which is its own version of the mistake this file is
    # about: a checker whose shape decides what can be checked.
    def multi(name, docs, expect_rc):
        d = tempfile.mkdtemp(prefix="t423-multi-")
        try:
            for fn, body in docs.items():
                with open(os.path.join(d, fn), "w", encoding="utf-8") as f:
                    f.write(body)
            rc, log = run_guard(d)
        finally:
            shutil.rmtree(d, ignore_errors=True)
        results.append((name, "ok" if rc == expect_rc else "SURVIVED",
                        f"expected rc={expect_rc}, got rc={rc}" +
                        ("" if rc == expect_rc else "\n      " + log.strip().replace("\n", "\n      "))))

    src = open(WITNESS, encoding="utf-8").read()
    # MIXED RUN. One export carries DI and one does not. Refusing here would be right only
    # if the whole run were vacuous; it is not — the DI-carrying document proves the
    # emitter fires, so the one that lacks DI is a finding and not a source map.
    multi("one document carries DI and one does not — the DI-less one is the finding",
          {"with-di.bpmn": src, "no-di.bpmn": _strip_di(src)}, 1)
    # An unreadable document must not be counted as a document with nothing wrong in it,
    # even when a perfectly good one sits beside it in the same run.
    multi("one document is unparseable beside a good one — must REFUSE, not average out",
          {"good.bpmn": src, "broken.bpmn": src[:len(src) // 2]}, 2)

    # Two refusals that need no document at all. Both are the same shape as case 7: an
    # empty run must not be reported as a clean one.
    empty = tempfile.mkdtemp(prefix="t423-empty-")
    try:
        rc_e, _ = run_guard(empty)
    finally:
        shutil.rmtree(empty, ignore_errors=True)
    results.append(("a directory with no .bpmn at all — must REFUSE",
                    "ok" if rc_e == 2 else "SURVIVED", f"expected rc=2, got rc={rc_e}"))
    p = subprocess.run([sys.executable, GUARD], capture_output=True, text=True)
    results.append(("no paths given at all — must REFUSE",
                    "ok" if p.returncode == 2 else "SURVIVED", f"expected rc=2, got rc={p.returncode}"))

    bad = [r for r in results if r[1] != "ok"]
    for name, verdict, detail in results:
        print(f"  [{'PASS' if verdict == 'ok' else verdict}] {name}\n      {detail}" if verdict != "ok"
              else f"  [PASS] {name}")
    if bad:
        print(f"\nTEETH FAIL — {len(bad)} of {len(results)} case(s) did not behave as required")
        return 1
    print(f"\nTEETH PASS — control green, {len(results)} cases each landing on their own verdict")
    return 0


if __name__ == "__main__":
    sys.exit(main())
