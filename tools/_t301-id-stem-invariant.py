#!/usr/bin/env python3
"""T-301 — assert `card id == derived workflowMeta.id` across every served corpus.

WHY A CORPUS CHECK AND NOT A CODE FIX. Two identities name the same map. The store card
id is the file stem (the browser fetches `rendered/<id>.bpmn`, the server keys versions by
it); the document id is derived from the document's own bytes inside `parseBpmnXml`.
`openProjectMap` fetches by card id, hands the bytes to `adoptImportedXml`, which re-derives
the id and overwrites `activeKey` — so the card id is discarded. One divergence produces both
reported symptoms: the Versions panel reads `/api/versions?id=workflowMeta.id` and comes back
empty, and `saveToProject` POSTs the re-derived id and forks a new project record.

The editor CANNOT produce the divergence: every editor write path keys the card by
`workflowMeta.id`. The STORE can, and did — `t101-review-audit-process` was a store-level copy
of `audit-process` whose stored bytes still said `audit-process`, which is exactly the shape
this walks for. An editor-side guard would protect the path that was never the source. That is
the T-301 GO's reasoning, and this check is the whole of its approved scope.

THE DERIVATION IS THE SUBJECT, so it is replicated from
src/aef-workflow-designer.html:11210 rather than approximated:

    id = aef:workflowMeta[@id]                  # authored: used UNSANITIZED, by design
         || sanitizeWorkflowId(procId, '')      # the machine id the document declares
         || sanitizeWorkflowId(procName, '')    # a DISPLAY LABEL — last resort
         || 'imported'

Getting that wrong in either direction makes the check measure a derivation the editor does
not perform. T-563 moved this chain after T-301's GO was written (it used to start at the
authored id then fall through to the unsanitized procName), which is why it is pinned here
with a leg that checks the derivation itself against named corpus documents.

Exit 0 invariant holds · 1 divergence or an unmeasurable population · 3 could not measure.
"""
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

PROJ = Path(os.environ.get("T301_PROJ", Path(__file__).resolve().parent.parent))

# Pinned from src/aef-workflow-designer.html:11075. GETTING THIS WRONG IS SILENT: the
# first cut of this tool guessed "https://aef.dev/schema/workflow", found no authored
# element on any document, fell through to the procId leg for all 127, and reported
# "127 of 127 divergent" — a 100% failure rate on a corpus T-301 measured as 0% and
# which the editor opens without complaint. An impossible finding is a broken instrument,
# so it was treated as one.
AEF_NS = "{http://anchorpoint.framework/aef/extensions}"
BPMN_NS = "{http://www.omg.org/spec/BPMN/20100524/MODEL}"


def sanitize_workflow_id(raw, fallback=""):
    """Port of src/aef-workflow-designer.html:1884. Five transforms, in order.

    The leading-separator rule strips BOTH `-` and `_`: the shipped :9162 rule stripped
    `-` only, so `_foo` survived and the validator rejected it on the first character.
    The trailing rule strips `-` ONLY — a trailing `_` is legal per isValidWorkflowId and
    trimming it would move ids that already round-trip.
    """
    s = "" if raw is None else str(raw)
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9_\-]", "-", s)
    s = re.sub(r"^[-_]+", "", s)
    s = re.sub(r"-+$", "", s)
    return s or fallback


def derive_document_id(path):
    """Replicate parseBpmnXml's workflowMeta.id chain. Returns (id, which_leg)."""
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as e:
        return None, f"unparseable: {e}"

    proc = root.find(f".//{BPMN_NS}process")
    if proc is None:
        return None, "no bpmn:process element"

    # DESCENDANT search, not a direct child. The editor uses
    #   byAef = (parent, local) => parent.getElementsByTagNameNS(AEF_NS, local)
    # which walks the whole subtree, and in every real document the element lives at
    # bpmn:process > bpmn:extensionElements > aef:workflowMeta. A direct-child `find`
    # matches nothing and every document falls to the fallback leg.
    meta = proc.find(f".//{AEF_NS}workflowMeta")
    authored = meta.get("id") if meta is not None else None
    if authored:
        # NOT sanitized — it is already machine identity, it already round-trips, and
        # sanitizing it would move bytes on every document carrying the element.
        return authored, "authored"

    proc_id = proc.get("id") or "imported"
    proc_name = proc.get("name") or re.sub(r"^Pool_", "", proc_id)

    from_id = sanitize_workflow_id(proc_id, "")
    if from_id:
        return from_id, "procId"
    from_name = sanitize_workflow_id(proc_name, "")
    if from_name:
        return from_name, "procName"
    return "imported", "default"


def population_rendered(root):
    """A rendered corpus: card id is the FILE STEM."""
    d = PROJ / root
    if not d.is_dir():
        return None, []
    return root, [(p, p.stem) for p in sorted(d.glob("*.bpmn"))]


def population_editor_versions():
    """Store cards: card id is the DIRECTORY name, not the vN stem.

    This is the population the reported instance lived in. The first T-301 pass measured
    only the two rendered roots, came out clean, and was ready to write "not reachable" —
    a measurement that scopes the wrong population and comes out clean is indistinguishable
    from one that scoped the right one.
    """
    d = PROJ / ".editor-versions"
    if not d.is_dir():
        return None, []
    out = []
    for card in sorted(p for p in d.iterdir() if p.is_dir()):
        for v in sorted(card.glob("v*.bpmn")):
            out.append((v, card.name))
    return ".editor-versions", out


def load_baseline():
    """Known, reasoned divergences. A NEW one fails; a known one is named and allowed.

    This is the _t560 ratchet shape, not an exemption list: the file carries a reason per
    entry, every run prints them, and an entry that STOPS diverging is reported as stale
    so the baseline cannot quietly outlive the thing it excuses.
    """
    f = PROJ / "tools/_t301-known-divergences.txt"
    if not f.is_file():
        return {}, f
    out = {}
    for line in f.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|", 2)]
        if len(parts) < 2:
            continue
        out[(parts[0], parts[1])] = parts[2] if len(parts) > 2 else "(no reason recorded)"
    return out, f


def main():
    roots = [
        population_rendered("examples/aef-processes/rendered"),
        # SCOPE EXTENSION beyond the three roots T-301's GO named, with reasoning.
        # The GO listed examples/aef-processes/rendered, build/gallery/rendered and
        # .editor-versions. But build/gallery/rendered is UNTRACKED build output, and the
        # one document that actually diverges is sourced from
        # examples/app-processes/customer-refund.workflow.yaml -> examples/app-processes/
        # rendered/, which IS tracked. Watching only the build copy would mean the check
        # guards an artifact while the tracked source drifts underneath it.
        population_rendered("examples/app-processes/rendered"),
        population_rendered("build/gallery/rendered"),
        population_editor_versions(),
    ]

    total = 0
    divergent = []
    unreadable = []
    empty_roots = []
    legs = {}

    print("=== T-301: card id == derived workflowMeta.id ===")
    print()

    for name, docs in roots:
        if name is None:
            continue
        if not docs:
            # An empty population must not read as "invariant holds" (T-3105).
            empty_roots.append(name)
            print(f"  {name}: NOT EVALUATED — walked 0 document(s). A root that "
                  f"contributes nothing asserts nothing.")
            continue
        n_bad = 0
        for path, card_id in docs:
            total += 1
            did, leg = derive_document_id(path)
            legs[leg] = legs.get(leg, 0) + 1
            if did is None:
                unreadable.append((path, leg))
                continue
            if did != card_id:
                divergent.append((path, card_id, did, leg))
                n_bad += 1
        print(f"  {name}: {len(docs)} document(s), {n_bad} divergent")

    print()
    print(f"examined {total} document(s) across "
          f"{sum(1 for n, d in roots if n and d)} populated root(s)")
    if legs:
        print("derivation legs used: "
              + ", ".join(f"{k}={v}" for k, v in sorted(legs.items())))
    print()

    if total == 0:
        sys.stderr.write(
            "COULD-NOT-MEASURE: every corpus root was missing or empty. This is not a "
            "pass — nothing was compared.\n")
        return 3

    rc = 0

    if empty_roots:
        print(f"FAIL: {len(empty_roots)} corpus root(s) contributed zero documents: "
              f"{', '.join(empty_roots)}")
        print("      Either the corpus moved or the glob is wrong. A silent empty walk is "
              "how a guard starts asserting nothing while still printing green.")
        rc = 1

    if unreadable:
        print(f"FAIL: {len(unreadable)} document(s) could not yield an id:")
        for p, why in unreadable:
            print(f"  {p.relative_to(PROJ)}  — {why}")
        rc = 1

    baseline, bfile = load_baseline()
    known, unknown = [], []
    for row in divergent:
        _p, card, did, _leg = row
        (known if (card, did) in baseline else unknown).append(row)

    if known:
        print(f"KNOWN: {len(known)} recorded divergence(s) — allowed, and named every run "
              f"so the record cannot be forgotten:")
        for p, card, did, leg in known:
            print(f"  {p.relative_to(PROJ)}")
            print(f"      card '{card}' vs document '{did}' (from: {leg})")
            print(f"      reason: {baseline[(card, did)]}")
        print()

    # A baseline entry that no longer diverges must be reported, not silently carried.
    # Same inference as _t517's STALE: either the document was fixed and the entry is
    # dead weight, or the check stopped seeing it.
    live_pairs = {(c, d) for _p, c, d, _l in divergent}
    stale = [k for k in baseline if k not in live_pairs]
    if stale:
        print(f"FAIL: {len(stale)} baseline entry(ies) no longer diverge — either the "
              f"document was fixed (delete the entry) or this check stopped seeing it:")
        for card, did in stale:
            print(f"  '{card}' vs '{did}'  — recorded in {bfile.relative_to(PROJ)}")
        rc = 1

    if unknown:
        print(f"FAIL: {len(unknown)} NEW document(s) whose card id and document id disagree.")
        print("      The editor opens by card id, then re-derives from bytes and discards")
        print("      it — so for each of these the Versions panel reads empty and a save")
        print("      forks a new project record under the derived id.")
        print()
        for p, card, did, leg in unknown:
            print(f"  {p.relative_to(PROJ)}")
            print(f"      card id     : {card}")
            print(f"      document id : {did}   (from: {leg})")
        print()
        print(f"      If a divergence is intended, record it in "
              f"{bfile.relative_to(PROJ)} WITH a reason. Do not widen the check.")
        rc = 1

    if rc == 0:
        print(f"OK — the invariant holds across all {total} document(s) "
              f"({len(known)} recorded exception(s)).")
    return rc


if __name__ == "__main__":
    sys.exit(main())
