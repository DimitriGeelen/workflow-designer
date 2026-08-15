#!/usr/bin/env python3
"""
T-523 teeth — can the nesting probe actually go red, and does it go red for the right reason?

`tools/_t523-subprocess-nesting.mjs` pins how the editor treats a node nested inside a
subProcess. It came back green on its first run against the pin it had just been given, and a
green instrument on a fresh control means nothing until a stimulus containing the fault has been
fed to it (PL-206). Worse, this probe's own subject is a 10k-line HTML file, so "would it notice
a change" is not answerable by reading it.

So the mutation here is on the SUBJECT, not on the probe. `parseBpmnXml` collects flow nodes
with `byBpmn(proc, tag)` — a DESCENDANT query, which is precisely why nested children are found
and then re-emitted at process level. The mutant restricts that to direct children:

    if (el.parentNode !== proc) continue;

which is exactly the behaviour the source comment already claims the editor has ("the whole
interior of an accepted element is dropped today"). That comment is what prompted T-523 and the
measurement falsified it, so it makes a good mutant: it is the plausible alternative reality, and
if the probe cannot tell the two apart then it cannot tell anyone anything.

Legs:
  1  mutant → probe exits 1 (drift), and the drift NAMES the nested arm
  2  mutant → the reason is the predicted one: child dropped, attribution says the node is lost.
     A bare rc check would pass on any red at all, including one caused by the mutant breaking
     something unrelated — which is the failure T-509 found in `_t358` and OBS-255 records.
  3  mutant → the FLAT arm is untouched. Without this, leg 1's red is equally explained by the
     mutant having broken the round-trip wholesale, and the probe would be taking credit for
     detecting damage it did not localise.
  4  real tree → rc 0, no drift
  5  pin file absent → rc 2 with a refusal that says so. An abstention must not be able to
     masquerade as a pass (PL-205).
  6  the structure reader distinguishes nesting on hand-built documents, with no browser
     involved. If the reader were blind to `in_sub`, every leg above would agree with it.

Hermetic: mutant and temp pins live under mktemp. Leaves this repository byte-identical.
Exit 0 all legs pass, 1 a leg failed, 2 REFUSE (mutation target absent — nothing was evaluated).
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EDITOR = os.path.join(REPO, "src", "aef-workflow-designer.html")
PROBE = os.path.join(REPO, "tools", "_t523-subprocess-nesting.mjs")
READER = os.path.join(REPO, "tools", "_t523-xml-structure.py")

TARGET = "for (const tag of nodeTags) for (const el of byBpmn(proc, tag)) nodeWork.push([tag, el, null]);"
MUTANT = ("for (const tag of nodeTags) for (const el of byBpmn(proc, tag)) "
          "{ if (el.parentNode !== proc) continue; nodeWork.push([tag, el, null]); }")

# T-528: the mutant for the COLLAPSED arm. One line of the export tag map, turning the
# BPMN-native subProcess tag into a plain task — the "helpful cleanup" AEF named at rail 11926
# as the change that would kill their dialect silently across three published maps. Anchored on
# the trailing `\n};` so it can only match the tag map's own entry and not the several other
# places the string `subProcess:` appears (sizes, field lists, labels, icons).
RETYPE_TARGET = "  subProcess: 'subProcess',\n};"
RETYPE_MUTANT = "  subProcess: 'task',\n};"

NESTED_DOC = """<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:aef="http://anchorpoint.framework/aef/extensions">
  <bpmn:process id="P">
    <bpmn:subProcess id="S">
      <bpmn:extensionElements><aef:uid value="n_s"/></bpmn:extensionElements>
      <bpmn:serviceTask id="A">
        <bpmn:extensionElements><aef:uid value="n_a"/></bpmn:extensionElements>
      </bpmn:serviceTask>
    </bpmn:subProcess>
  </bpmn:process>
</bpmn:definitions>
"""

FLAT_DOC = """<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:aef="http://anchorpoint.framework/aef/extensions">
  <bpmn:process id="P">
    <bpmn:subProcess id="S">
      <bpmn:extensionElements><aef:uid value="n_s"/></bpmn:extensionElements>
    </bpmn:subProcess>
    <bpmn:serviceTask id="A">
      <bpmn:extensionElements><aef:uid value="n_a"/></bpmn:extensionElements>
    </bpmn:serviceTask>
  </bpmn:process>
</bpmn:definitions>
"""

failures = []
passes = 0


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no leg was evaluated.")
    sys.exit(2)


def leg(name, ok, detail=""):
    global passes
    if ok:
        passes += 1
        print("  PASS  %s" % name)
    else:
        failures.append(name)
        print("  FAIL  %s%s" % (name, ("\n        " + detail) if detail else ""))


def run_probe(src=None, pin=None, timeout=180):
    env = dict(os.environ)
    if src:
        env["T523_SRC"] = src
    if pin:
        env["T523_PIN"] = pin
    p = subprocess.run(
        ["node", PROBE], cwd=REPO, env=env, capture_output=True, text=True,
        timeout=timeout, check=False,
    )
    try:
        return p.returncode, json.loads(p.stdout)
    except Exception:
        return p.returncode, {"_unparseable": p.stdout[-600:], "_stderr": p.stderr[-400:]}


def read_structure(doc):
    p = subprocess.run(["python3", READER], input=doc.encode(), capture_output=True, check=False)
    return json.loads(p.stdout)


# ── preconditions ──────────────────────────────────────────────────────────────────────────
for path in (EDITOR, PROBE, READER):
    if not os.path.isfile(path):
        refuse("missing %s" % os.path.relpath(path, REPO))

with open(EDITOR) as f:
    editor_src = f.read()

if editor_src.count(TARGET) != 1:
    refuse(
        "the mutation target appears %d times in the editor (expected exactly 1). The node-"
        "collection line was reformatted or moved, so the mutant below would be a no-op and "
        "legs 1-3 would report a green that means nothing. Update the literal in this file "
        "after checking that the descendant query is still what makes nesting observable."
        % editor_src.count(TARGET)
    )

# T-528: same precondition for the retype mutant, and for the same reason one level over. If the
# export tag map is reformatted, `.replace()` silently returns the source unchanged, the probe
# runs against an UNMUTATED editor, and legs 7-9 would report "no drift" as a failure to detect —
# reading as a real defect in the arm rather than as a dead mutant. Refusing here keeps the two
# apart, which is the whole PL-205 point: an instrument that cannot run must not return a verdict.
if editor_src.count(RETYPE_TARGET) != 1:
    refuse(
        "the retype mutation target appears %d times in the editor (expected exactly 1). The "
        "export tag map's subProcess entry was reformatted or moved, so legs 7-9 would run "
        "against an unmutated editor and report a dead mutant as a detection failure."
        % editor_src.count(RETYPE_TARGET)
    )

print("T-523 teeth — can the nesting probe go red, and for the stated reason")
print("subject: src/aef-workflow-designer.html (parseBpmnXml node collection)")
print()

tmp = tempfile.mkdtemp(prefix="t523-teeth-")
try:
    # ── legs 1-3: mutate the editor so nested nodes are dropped ────────────────────────────
    mutant_path = os.path.join(tmp, "designer-mutant.html")
    with open(mutant_path, "w") as f:
        f.write(editor_src.replace(TARGET, MUTANT, 1))

    rc, out = run_probe(src=mutant_path)
    drift = out.get("drift") or []
    drift_keys = [d.get("key") for d in drift]

    leg(
        "1 mutant makes the probe go red (rc 1, drift on the nested arm)",
        rc == 1 and "nested" in drift_keys,
        "rc=%d drift_keys=%s. A probe that cannot detect the plausible alternative behaviour "
        "cannot certify the actual one." % (rc, drift_keys),
    )

    nested_drift = next((d for d in drift if d.get("key") == "nested"), None)
    measured_child = (nested_drift or {}).get("measured", {}).get("child_a", {}).get("outcome")
    attribution = ((out.get("observed") or {}).get("attribution") or "")
    leg(
        "2 red for the NAMED reason — nested child dropped, attribution says so",
        measured_child == "dropped" and attribution.startswith("nesting-loses-the-node"),
        "child_a outcome=%r attribution=%r. Asserting only that it went red would pass on a "
        "red caused by anything at all — the OBS-255 failure mode." % (measured_child, attribution),
    )

    flat_ok = not any(d.get("key") == "flat" for d in drift)
    leg(
        "3 mutation is LOCALISED — the flat arm is unaffected",
        flat_ok,
        "the flat arm also drifted, so leg 1's red is equally explained by the mutant breaking "
        "the round-trip wholesale. Without this leg the probe takes credit for a detection it "
        "did not localise.",
    )

    # ── leg 4: the real tree matches its pin ───────────────────────────────────────────────
    rc, out = run_probe()
    leg(
        "4 real tree matches the pin (rc 0, no drift)",
        rc == 0 and not (out.get("drift") or []),
        "rc=%d drift=%s" % (rc, out.get("drift")),
    )

    # ── leg 5: an absent pin refuses, and says why ─────────────────────────────────────────
    rc, out = run_probe(pin=os.path.join(tmp, "no-such-pin.json"))
    leg(
        "5 absent pin REFUSES (rc 2) rather than passing",
        rc == 2 and "no pin file" in (out.get("refusal") or ""),
        "rc=%d refusal=%r. 'I have no reference' must not be indistinguishable from 'it "
        "matched'." % (rc, (out.get("refusal") or "")[:120]),
    )

    # ── legs 7-9: the COLLAPSED arm (T-528) must be able to see a RETYPE ───────────────────
    #
    # The collapsed arm passes on the real tree, and a green arm that cannot go red is worth
    # nothing — which matters more here than usual, because this arm exists to reassure AEF
    # about three published maps. Certifying their dialect on the strength of an arm nobody
    # proved could fail would be exactly the shape they caught themselves making at 11926
    # (clearing me on the strength of my own damage).
    #
    # The mutant is the failure AEF actually named: a round-trip that "helpfully" rewrites an
    # empty scope element into a plain activity. One line, in the export tag map — which is
    # what makes it a realistic change rather than a contrived one. Someone tidying node types
    # could make this edit without ever learning that three published maps depend on it.
    retype_path = os.path.join(tmp, "designer-retype.html")
    with open(retype_path, "w") as f:
        f.write(editor_src.replace(RETYPE_TARGET, RETYPE_MUTANT, 1))

    rc, out = run_probe(src=retype_path)
    drift = out.get("drift") or []
    drift_keys = [d.get("key") for d in drift]
    collapsed_drift = next((d for d in drift if d.get("key") == "collapsed"), None)
    measured_node = (collapsed_drift or {}).get("measured", {}).get("node", {}) or {}

    leg(
        "7 a retyping mutant makes the collapsed arm go red (rc 1, drift on 'collapsed')",
        rc == 1 and "collapsed" in drift_keys,
        "rc=%d drift_keys=%s. If this arm cannot detect a retype it cannot certify that one is "
        "not happening, and AEF is relying on it for three published maps." % (rc, drift_keys),
    )

    # This leg asserted `owner == "task"` on first writing and FAILED, measuring 'serviceTask':
    # the editor does not emit the mutated tag verbatim, it falls back. The arm was right and my
    # expectation was wrong — which is the mistake this file's own header warns about one level
    # over ("written from a MEASURED run, not from expectation"), committed in the teeth instead
    # of in the pin. Left recorded rather than quietly corrected, because the useful part is that
    # the arm reported WHAT the node became; had it returned a boolean I would have "confirmed"
    # a retype-to-task that never happened and told AEF so.
    #
    # So the leg now asserts the discrimination rather than my guess: retyped rather than dropped,
    # and a concrete new owner that is not subProcess. Pinning the exact fallback tag here would
    # re-import the same defect — it is a fact about the mutant's interaction with the fallback,
    # not about the property under test.
    leg(
        "8 red for the NAMED reason — survived-retyped (not dropped), with the new owner named",
        measured_node.get("outcome") == "survived-retyped"
        and isinstance(measured_node.get("owner"), str)
        and measured_node.get("owner") not in (None, "", "subProcess"),
        "measured node=%r. 'It went red' would also be satisfied by the node being DROPPED, "
        "which is a different defect with a different conversation attached — the remedy for "
        "'it became something else' and 'it vanished' are not the same." % (measured_node,),
    )

    # This leg asserted the NESTED arm would be unaffected and FAILED, for a reason that was
    # obvious once measured: the nested arm contains a subProcess of its own, so a mutant that
    # retypes every exported subProcess necessarily drifts it. My stated rationale — "those arms
    # carry serviceTask children, whose tag the mutant does not touch" — was true and irrelevant.
    #
    # The FLAT arm is the real control: it contains no subProcess at any level, so it is the only
    # arm whose cleanliness distinguishes "the mutant retyped subProcesses" from "the mutant broke
    # the round-trip wholesale". Narrowing the leg to flat is not weakening it; the nested arm was
    # never capable of carrying this claim.
    leg(
        "9 the retype is LOCALISED — the flat arm, which contains no subProcess at all, is clean",
        "flat" not in drift_keys,
        "drift_keys=%s. The flat arm has no subProcess at any level, so if it drifts too the "
        "mutant broke the round-trip wholesale and leg 7's red is explained by something other "
        "than the retype. (The nested arm SHOULD drift — it contains a subProcess of its own — "
        "and asserting otherwise is what this leg got wrong on first writing.)" % (drift_keys,),
    )

    # ── leg 6: the reader itself can see nesting ───────────────────────────────────────────
    nested = read_structure(NESTED_DOC)
    flat = read_structure(FLAT_DOC)
    n_a_nested = next((u for u in nested["uids"] if u["value"] == "n_a"), None)
    n_a_flat = next((u for u in flat["uids"] if u["value"] == "n_a"), None)
    leg(
        "6 the conforming reader distinguishes nested from flat, with no browser involved",
        bool(n_a_nested and n_a_flat)
        and n_a_nested["in_sub"] is True
        and n_a_flat["in_sub"] is False
        and nested["flow_children_by_parent"].get("S") == 1
        and flat["flow_children_by_parent"].get("S") == 0,
        "nested in_sub=%s flat in_sub=%s containment nested=%s flat=%s. If the reader were "
        "blind to nesting, every leg above would agree with it and all of them would be wrong."
        % (n_a_nested and n_a_nested["in_sub"], n_a_flat and n_a_flat["in_sub"],
           nested["flow_children_by_parent"], flat["flow_children_by_parent"]),
    )
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print()
total = passes + len(failures)
if failures:
    print("%d/%d legs passed — FAILED: %s" % (passes, total, ", ".join(failures)))
    sys.exit(1)
print("%d/%d legs passed" % (passes, total))
sys.exit(0)
