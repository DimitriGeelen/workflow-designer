#!/usr/bin/env python3
"""_t809-frozen-meta-census.py — do the corpus documents actually carry the frozen keys?

T-809, value review finding F-06.

THE STANDARD (docs/standards/aef-bpmn-mapping-v1.md, frozen, §2):

    "A conformant editor MUST emit each on task-like nodes, and the bridge MUST
     round-trip each"  —  horizon, workflowType, tier, agentType

THE CHECK THAT ALREADY EXISTED. tests/test_mapping_standard_conformance.py prints
"OK: all 4 frozen governance meta-keys ... present in both editor metaKeys and bridge
META_KEYS" and exits 0. It compares TWO PYTHON LISTS. It never opens a corpus document,
and neither does test_editor_bridge_meta_parity.py. So the MUST in §2 — which is about
what is EMITTED — has never been mechanically checked by anything.

This is the second recorded instance of that exact shape in this repo. The first is
documented in test_editor_bridge_meta_parity.py's own docstring: it ran green for 47 days
while nine keys were destroyed on every save, "because check() was never looking (PL-034)".

WHAT THIS DOES, AND DELIBERATELY DOES NOT DO.

Does: opens every rendered corpus document, walks task-like nodes, and counts how many
carry each frozen key on an <aef:meta> element. Ratchets that coverage so it cannot fall.

Does NOT: decide whether the corpus should gain the keys or the standard should change.
That is sovereign (value review §12 Q3) and it is the operator's. This instrument makes
the condition visible and stops it getting worse while that ruling is outstanding. It is
NOT a conformance gate and must not be described as one — a red gate here would be a
standing failure that the next reader switches off, and the corpus is not defective until
the operator says which side moves.

WHY XML AND NOT GREP. The first measurement of this finding used `grep -c tier` and got a
different answer than the truth: `tier` appears in prose, in attribute VALUES, and on
non-task elements. The review's own numbers ("tier 74 occ / 14 files OK") counted
occurrences and files, which cannot answer a per-node MUST at all. Parsed per-node, tier
covers 74 of 165 task-like nodes — short, where the review marked it satisfied.

RATCHET DIRECTION IS INVERTED from tools/_t560-absence-baseline.txt. There the number
counts defects and may fall but not rise. Here it counts coverage and may RISE freely —
raise it in the same commit that improves the corpus — but may not FALL.

Exit: 0 coverage held or improved | 1 coverage FELL, or the census could not measure
"""

import glob
import os
import sys
import xml.etree.ElementTree as ET
from typing import NoReturn

AEF_NS = "{http://anchorpoint.framework/aef/extensions}"

# BPMN activity types that the standard's "task-like nodes" covers. Kept explicit rather
# than "anything ending in Task": callActivity and subProcess end in neither, and a
# suffix rule would silently acquire new members as BPMN grows.
TASKLIKE = {
    "task", "userTask", "serviceTask", "scriptTask", "manualTask",
    "businessRuleTask", "sendTask", "receiveTask", "callActivity", "subProcess",
}

FROZEN_KEYS = ["horizon", "workflowType", "tier", "agentType"]

REPO_ROOT = os.environ.get(
    "T809_REPO_ROOT",
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
)
CORPUS_GLOB = os.path.join(REPO_ROOT, "examples", "aef-processes", "rendered", "*.bpmn")
BASELINE = os.path.join(REPO_ROOT, "tools", "_t809-frozen-meta-baseline.txt")


def die(msg) -> NoReturn:
    # NoReturn is load-bearing, not decoration: without it a type checker reads every
    # `except: die(...)` as a path that falls through, and reports the variable assigned
    # in the `try` as possibly-unbound. Saying so in the signature is the honest fix;
    # silencing the warning would leave the next reader with the same question.
    print(f"CANNOT MEASURE: {msg}", file=sys.stderr)
    print("  A census that cannot reach its subject must not emit a verdict — "
          "'0 failures' and '0 things examined' are the same number otherwise.",
          file=sys.stderr)
    sys.exit(1)


def census():
    files = sorted(glob.glob(CORPUS_GLOB))
    if not files:
        die(f"no corpus documents matched {CORPUS_GLOB}")

    counts = {k: 0 for k in FROZEN_KEYS}
    total_nodes = 0

    for path in files:
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as e:
            die(f"{os.path.basename(path)} does not parse: {e}")

        for el in root.iter():
            if el.tag.split("}")[-1] not in TASKLIKE:
                continue
            total_nodes += 1
            # A node may carry several <aef:meta> elements; the union of their attribute
            # names is what the node "has". Descendant search (not direct children)
            # because meta lives under <bpmn:extensionElements>.
            keys = set()
            for meta in el.iter():
                if meta.tag == AEF_NS + "meta":
                    keys.update(meta.attrib.keys())
            for k in FROZEN_KEYS:
                if k in keys:
                    counts[k] += 1

    if total_nodes == 0:
        die("parsed the corpus and found ZERO task-like nodes. Either the corpus is "
            "empty or TASKLIKE/AEF_NS no longer match what the editor emits — both are "
            "failures of this instrument, not a clean corpus.")

    return files, total_nodes, counts


def read_baseline():
    if not os.path.exists(BASELINE):
        return None
    vals = {}
    with open(BASELINE) as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            try:
                vals[k] = int(v.strip())
            except ValueError:
                die(f"baseline line is not an integer: {line!r}")
    return vals


def main():
    files, total, counts = census()

    print(f"=== T-809 frozen governance meta-key census (F-06) ===")
    print(f"corpus: {len(files)} document(s), {total} task-like node(s)")
    print()
    for k in FROZEN_KEYS:
        n = counts[k]
        pct = 100.0 * n / total
        flag = "" if n == total else "   <-- short of the §2 MUST"
        print(f"  {k:<14} {n:>4}/{total}  ({pct:5.1f}%){flag}")
    print()

    base = read_baseline()
    if base is None:
        print("no baseline file yet — writing one is a deliberate act, not this run's job.")
        print(f"to arm the ratchet, record the numbers above in {BASELINE}")
        return 0

    regressed = []
    for k in FROZEN_KEYS:
        if k not in base:
            die(f"baseline has no entry for frozen key '{k}'. A key present in the "
                f"standard and absent from the baseline would be unratcheted — that is a "
                f"hole in the check, not a pass.")
        if counts[k] < base[k]:
            regressed.append((k, base[k], counts[k]))

    if regressed:
        print("FAIL: frozen-key coverage FELL.", file=sys.stderr)
        for k, was, now in regressed:
            print(f"  {k}: baseline {was} -> {now}  (lost {was - now} node(s))",
                  file=sys.stderr)
        print(file=sys.stderr)
        print("  Coverage may rise freely; it may not fall. A key that stops being "
              "emitted is exactly the silent regression F-06 exists to catch — the "
              "editor/bridge parity test cannot see it, because it compares key lists "
              "and never opens a document.", file=sys.stderr)
        return 1

    improved = [(k, base[k], counts[k]) for k in FROZEN_KEYS if counts[k] > base[k]]
    if improved:
        print("coverage IMPROVED — raise the baseline in the same commit:")
        for k, was, now in improved:
            print(f"  {k}: {was} -> {now}")
        print()
        print("  (Leaving it low silently re-admits exactly that much regression.)")

    print("ok: no frozen-key coverage regression against the baseline")
    return 0


if __name__ == "__main__":
    sys.exit(main())
