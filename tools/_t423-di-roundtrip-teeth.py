#!/usr/bin/env python3
"""_t423-di-roundtrip-teeth.py — prove _t423-di-roundtrip-idempotence-cdp.mjs can go RED.

That probe returned 24/24 identical on its very first run. A gate that has only ever been
green, on the first attempt, against the tree it was written for, is the least informative
result available: it is equally consistent with "the exporter is idempotent" and with "the
comparison does not work". These teeth decide between those two by breaking the designer on
purpose, in a temp copy, and requiring the probe to notice.

WHY THE MUTATIONS ARE WHAT THEY ARE. Idempotence has two failure modes and they want
different fixes, so the probe classifies them and both classifications are exercised here:

  CONVERGING — the second export differs from the first and then settles (E2 === E3). The
    output depends on something about the INPUT that is true of an export and false of a
    source map. One spurious diff per document, once, then quiet. Mutant 2 makes the DI
    precision depend on `state.sourceCarriedDi`, which is exactly that shape and is a
    plausible thing to write by accident — it was the emitter's own condition until
    389133c8 made DI unconditional.

  KEEPS MOVING — every generation differs from the last. Something accumulates. Mutant 1
    appends a character to every flow node's name on export; names round-trip, so each save
    grows the file. This is the one that makes a repository unreviewable.

    THE FIRST VERSION OF THIS MUTANT WAS INERT AND THAT IS ITS OWN FINDING. It appended to
    the DOCUMENT COMMENT, which also round-trips — but `buildBpmnXml` emits the comment only
    when `s.docComment` is non-empty, and MEASURED: zero of the 24 corpus maps carry one. The
    mutation applied, changed the source, and produced no drift, so the case reported
    SURVIVED against a probe that was working correctly. Recorded rather than quietly
    swapped, because it says something about the gate's reach that the green did not: the
    doc-comment emit path is not exercised by this corpus at all, by any leg, and a defect
    there would be invisible to every gate that runs on it.

MUTANT 3 IS THE ANTI-VACUITY LEG and it is not decoration: it makes the exporter write
malformed XML, so our own output cannot be re-parsed. Without it, a probe that silently
counted an unparseable second generation as "no drift detected" would pass every other case
here. The probe must REFUSE (rc 2), and refusing is not the same as passing.

MUTANT 4 is the anti-overfit control: a change to the designer that does NOT affect
idempotence must leave the probe GREEN. A harness where every mutation reddens proves the
probe reacts to edits, not to drift.

Exit 0 = control green and every mutant produced its expected verdict.
     1 = a mutant survived, or the control was not green.
     2 = the probe or the designer source is missing, or a case could not run.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
PROBE = os.path.join(HERE, "_t423-di-roundtrip-idempotence-cdp.mjs")
SRC = os.path.join(REPO, "src", "aef-workflow-designer.html")

results = []


def run_probe(src_path):
    env = dict(os.environ)
    env["T423_SRC"] = src_path
    p = subprocess.run(["node", PROBE], capture_output=True, text=True, env=env, timeout=900)
    return p.returncode, (p.stdout + p.stderr)


def case(name, mutate, expect_rc, expect_in_output=None):
    """A mutation that changes nothing is a NO-OP MUTANT: it does not report "the rule is
    gone", it reports "the mutant did not die", and that is indistinguishable from a probe
    that never worked. Refused here rather than run."""
    d = tempfile.mkdtemp(prefix="t423rt-teeth-")
    try:
        body = open(SRC, encoding="utf-8").read()
        try:
            out = mutate(body)
        except Exception as e:
            results.append((name, "ANCHOR GONE", str(e)))
            return
        if out == body:
            results.append((name, "NO-OP", "mutation changed nothing — re-point this case"))
            return
        p = os.path.join(d, "designer.html")
        with open(p, "w", encoding="utf-8") as f:
            f.write(out)
        rc, log = run_probe(p)
        ok = rc == expect_rc and (expect_in_output is None or expect_in_output in log)
        detail = f"expected rc={expect_rc}" + (f" and {expect_in_output!r} in output" if expect_in_output else "")
        detail += f", got rc={rc}"
        if not ok:
            detail += "\n      " + log.strip().replace("\n", "\n      ")
        else:
            m = re.search(r"^\s*maps:.*$", log, re.M)
            if m:
                detail += " — " + m.group(0).strip()
        results.append((name, "ok" if ok else "SURVIVED", detail))
    finally:
        shutil.rmtree(d, ignore_errors=True)


NODE_NAME = ('lines.push(`    <bpmn:${tag} id="${escAttr(nodeDisplayId)}"'
             ' name="${escAttr(n.name)}"${boundaryAttrs}>`);')
BOUNDS = ('lines.push(`        <dc:Bounds x="${n.x.toFixed(1)}" y="${n.y.toFixed(1)}"'
          ' width="${def.w}" height="${def.h}"/>`);')
WAYPOINT = 'lines.push(`        <di:waypoint x="${p.x.toFixed(1)}" y="${p.y.toFixed(1)}"/>`);'


def _require(body, anchor, what):
    if anchor not in body:
        raise RuntimeError(f"anchor for {what} is gone — re-point this case")


def _accumulating_name(body):
    """KEEPS MOVING: append a character to every flow node's name, which round-trips.

    Every corpus map has flow nodes with names, so unlike the doc-comment version this
    mutation is guaranteed to bite — the population it depends on was checked before the
    mutant was written rather than after it failed."""
    _require(body, NODE_NAME, "the flow-node name emit")
    return body.replace(
        NODE_NAME,
        'lines.push(`    <bpmn:${tag} id="${escAttr(nodeDisplayId)}"'
        ' name="${escAttr(n.name)}."${boundaryAttrs}>`);', 1)


def _converging_precision(body):
    """CONVERGES: DI precision depends on whether the INPUT carried DI. Gen 1 comes from a
    source map (no DI), gen 2 and 3 come from exports (DI present), so it drifts once."""
    _require(body, BOUNDS, "the dc:Bounds emit")
    return body.replace(
        BOUNDS,
        'lines.push(`        <dc:Bounds x="${n.x.toFixed(s.sourceCarriedDi?2:1)}"'
        ' y="${n.y.toFixed(s.sourceCarriedDi?2:1)}"'
        ' width="${def.w}" height="${def.h}"/>`);', 1)


def _unparseable_output(body):
    """Our own export stops being readable. The probe must REFUSE, not report no drift."""
    _require(body, WAYPOINT, "the di:waypoint emit")
    return body.replace(
        WAYPOINT,
        'lines.push(`        <di:waypoint x="${p.x.toFixed(1)}" y="${p.y.toFixed(1)}"`);', 1)


def _benign_edit(body):
    """ANTI-OVERFIT: a real change to the designer that cannot affect idempotence — a
    comment. If this reddens, the probe is reacting to edits rather than to drift."""
    _require(body, WAYPOINT, "the di:waypoint emit")
    return body.replace(
        WAYPOINT,
        "// teeth: benign edit, no behavioural change\n    " + WAYPOINT, 1)


def main():
    for p in (PROBE, SRC):
        if not os.path.exists(p):
            print("REFUSE — missing: " + p.replace(REPO + "/", ""))
            return 2

    rc, log = run_probe(SRC)
    if rc != 0:
        print(f"FAIL — CONTROL is not green (rc={rc}) on the unmutated designer:\n{log}")
        return 1
    m = re.search(r"^\s*maps:.*$", log, re.M)
    print(f"  control: unmutated designer -> PASS  ({m.group(0).strip() if m else ''})")

    case("emitter APPENDS to every node name each export — every save drifts",
         _accumulating_name, 1, "keep moving")
    case("DI precision depends on whether the input carried DI — drifts once, then settles",
         _converging_precision, 1, "CONVERGE")
    # The expected substring is the load-bearing half of this case, not the exit code. rc=2
    # alone is satisfied by ANY refusal — including a corpus map that was malformed before
    # we touched it. Requiring "OUR OWN EXPORT" in the message is what makes this case about
    # the exporter rather than about the inputs, and the probe had to be changed to be able
    # to say it.
    case("our own export stops being re-parseable — must REFUSE, and must say it was OURS",
         _unparseable_output, 2, "OUR OWN EXPORT would not parse")
    case("a comment is added beside the waypoint emit — MUST STAY GREEN",
         _benign_edit, 0)

    bad = [r for r in results if r[1] != "ok"]
    for name, verdict, detail in results:
        if verdict == "ok":
            print(f"  [PASS] {name}\n      {detail}")
        else:
            print(f"  [{verdict}] {name}\n      {detail}")
    if bad:
        print(f"\nTEETH FAIL — {len(bad)} of {len(results)} case(s) did not behave as required")
        return 1
    print(f"\nTEETH PASS — control green, {len(results)} cases each landing on their own verdict")
    return 0


if __name__ == "__main__":
    sys.exit(main())
