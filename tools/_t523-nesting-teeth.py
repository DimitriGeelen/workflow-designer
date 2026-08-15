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
