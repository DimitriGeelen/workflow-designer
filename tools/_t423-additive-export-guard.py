#!/usr/bin/env python3
"""_t423-additive-export-guard.py — export ADDS DI and changes nothing else.

Pairs each source corpus map with its export and requires that the two are identical on
every element outside the DI namespaces: same tags, same attributes, same document order.
Additions are permitted only in `bpmndi`/`dc`/`di`, plus two named provenance attributes on
the root.

WHAT THIS REPLACES, AND WHY THE AC IT SATISFIES COULD NOT BE IMPLEMENTED AS WRITTEN.
T-423 carries an AC reading: *"The intent extensions (forceStraight 12, routingHint 22,
loopDetour 9, anchors 19, aef:waypoint 1) are untouched."* Those five numbers do not
describe any document. They are LINE COUNTS OF THE IDENTIFIER IN THE DESIGNER'S OWN SOURCE
FILE. Measured:

    identifier      AC   lines in src/aef-workflow-designer.html   minus the comment
                                                                   that quotes this AC
    forceStraight   12   13                                        12   <- match
    routingHint     22   23                                        22   <- match
    loopDetour       9   10                                         9   <- match
    aef:waypoint     1    2                                         1   <- match
    anchors         19   21                                        20   <- drifted

Four of five reproduce exactly once the source comment that quotes the AC is excluded — the
AC's own restatement inside the implementation is counted BY the AC. `anchors` has already
drifted 19 -> 20 because it is an English word and someone wrote "Ctrl+wheel anchors at the
cursor" in an unrelated comment. So the metric moves when a comment is edited and does not
move when an exported document loses an extension, which is the exact inversion of what the
AC exists to detect.

It is also G-015's population-pin class (no corpus count in executable code) reappearing as
a pin on the IMPLEMENTATION rather than the corpus, and the T-495 shape — prose about a
thing counted as an instance of the thing — in the AC's own metric.

The AC's INTENT is sound and is what this guard implements: DI has no vocabulary for layout
INTENT, only for computed results, so DI cannot carry these and must not be read as having
replaced them. Expressed as PER-DOCUMENT IDENTITY derived from each pair, never as a count.
Adding a corpus map cannot falsify it; deleting an extension from one document will.

WHY STRICT SEQUENCE EQUALITY RATHER THAN SET COMPARISON. The AC says "no existing element
removed OR REORDERED". A set comparison is blind to order by construction, so it would
satisfy the sentence while ignoring half of it. Comparing the ordered sequence of
(tag, sorted attributes) costs nothing extra and covers removal, addition, reordering and
attribute mutation in one equality.

WHY THE ALLOWED ADDITIONS ARE ENUMERATED RATHER THAN THE COMPARISON LOOSENED. The exporter
stamps `exporter` (and, if present, `exporterVersion`) on the root. The cheap fix is "ignore
attributes on the root element", which would also hide a REMOVED `targetNamespace` — the
seam attribute AEF's reader keys on. Two named attributes an auditor can read beats a rule
whose blast radius nobody can see. Anything else appearing on the root is a violation.

VACUITY IS REPORTED PER VOCABULARY ITEM, NOT ASSUMED AWAY. A guard that says "the intent
extensions are untouched" over a corpus containing none of them has proved nothing about
them, and would go green forever. Measured population in the rendered corpus:

    aef:anchors 55   aef:routingHint 9   aef:loopDetour 3
    aef:forceStraight 0   aef:waypoint 0        <- exercised by NOTHING

The last two are supported by the designer and absent from every corpus map. This guard
prints them as UNEXERCISED and never counts them as covered. That is yesterday's
carrier-guard lesson (a comparison producing zero rows is not agreement) applied to a
vocabulary rather than to a node set.

Exit 0 = every pair is identical outside DI, and at least one pair was compared.
     1 = a document diverged.
     2 = nothing to compare (missing dir, no pairs, unparseable input) — REFUSAL, not a pass.
"""

import os
import sys
import xml.etree.ElementTree as ET

DI_NS = {
    "http://www.omg.org/spec/BPMN/20100524/DI",
    "http://www.omg.org/spec/DD/20100524/DC",
    "http://www.omg.org/spec/DD/20100524/DI",
}
AEF_NS = "http://anchorpoint.framework/aef/extensions"

# Provenance the exporter stamps on the root. Enumerated on purpose — see the docstring.
ALLOWED_ROOT_ADDITIONS = {"exporter", "exporterVersion"}

# The vocabulary the AC names, as it actually appears in documents: elements, not attributes.
INTENT_VOCAB = ("anchors", "routingHint", "loopDetour", "forceStraight", "waypoint")


def _ns(tag):
    return tag[1:tag.index("}")] if tag.startswith("{") else ""


def _local(tag):
    return tag[tag.index("}") + 1:] if tag.startswith("{") else tag


def _sequence(path, drop_di):
    """Ordered [(tag, sorted attrs)] for every element, DI optionally dropped.

    Raises on unparseable input; the caller turns that into a refusal rather than into
    "no differences found", which is the same distinction the round-trip probe had to be
    taught (an unreadable document is not an unchanged one).
    """
    root = ET.parse(path).getroot()
    out = []
    for el in root.iter():
        if drop_di and _ns(el.tag) in DI_NS:
            continue
        attrs = dict(el.attrib)
        if el is root:
            for k in list(attrs):
                if k in ALLOWED_ROOT_ADDITIONS:
                    attrs.pop(k)
        out.append((el.tag, tuple(sorted(attrs.items()))))
    return out


def _intent_census(path):
    """{local name -> count} for the AC's vocabulary, in the aef namespace."""
    root = ET.parse(path).getroot()
    c = {k: 0 for k in INTENT_VOCAB}
    for el in root.iter():
        if _ns(el.tag) == AEF_NS:
            n = _local(el.tag)
            if n in c:
                c[n] += 1
    return c


def _first_divergence(a, b):
    i = 0
    while i < min(len(a), len(b)) and a[i] == b[i]:
        i += 1
    return i, (a[i] if i < len(a) else None), (b[i] if i < len(b) else None)


def compare(src_dir, exp_dir):
    """-> (violations, pairs, di_added_total, src_census, exp_census, unparseable)."""
    violations, unparseable = [], []
    src_files = {f for f in os.listdir(src_dir) if f.endswith(".bpmn")} if os.path.isdir(src_dir) else set()
    exp_files = {f for f in os.listdir(exp_dir) if f.endswith(".bpmn")} if os.path.isdir(exp_dir) else set()
    pairs = sorted(src_files & exp_files)

    # A map that exported but has no source, or vice versa, is a population change the
    # verdict must not absorb silently.
    for f in sorted(exp_files - src_files):
        violations.append(f"{f}: present in the export set with NO source map to compare against")
    for f in sorted(src_files - exp_files):
        violations.append(f"{f}: source map did not export — it is missing from the export set")

    di_added = 0
    src_c = {k: 0 for k in INTENT_VOCAB}
    exp_c = {k: 0 for k in INTENT_VOCAB}

    for f in pairs:
        sp, ep = os.path.join(src_dir, f), os.path.join(exp_dir, f)
        try:
            s = _sequence(sp, drop_di=False)
            e_nodi = _sequence(ep, drop_di=True)
            e_all = _sequence(ep, drop_di=False)
        except ET.ParseError as ex:
            unparseable.append(f"{f}: {ex}")
            continue

        di_added += len(e_all) - len(e_nodi)
        for k, v in _intent_census(sp).items():
            src_c[k] += v
        for k, v in _intent_census(ep).items():
            exp_c[k] += v

        if s != e_nodi:
            i, a, b = _first_divergence(s, e_nodi)
            if a is None:
                violations.append(f"{f}: export has {len(e_nodi) - len(s)} MORE non-DI element(s) "
                                  f"than the source; first extra at index {i}: {b}")
            elif b is None:
                violations.append(f"{f}: export is MISSING {len(s) - len(e_nodi)} non-DI element(s); "
                                  f"first missing at index {i}: {a}")
            else:
                violations.append(f"{f}: diverges at non-DI element {i} of {len(s)}\n"
                                  f"      SOURCE: {a}\n"
                                  f"      EXPORT: {b}")

    return violations, pairs, di_added, src_c, exp_c, unparseable


def main(argv):
    if len(argv) != 3:
        print("REFUSE — usage: _t423-additive-export-guard.py <source-dir> <export-dir>")
        return 2
    src_dir, exp_dir = argv[1], argv[2]
    for d in (src_dir, exp_dir):
        if not os.path.isdir(d):
            print(f"REFUSE — not a directory: {d}")
            return 2

    violations, pairs, di_added, src_c, exp_c, unparseable = compare(src_dir, exp_dir)

    if unparseable:
        print(f"REFUSE — {len(unparseable)} document(s) could not be parsed. An unreadable "
              f"document is not an unchanged one, so nothing here is a pass:")
        for u in unparseable:
            print("  " + u)
        return 2
    if not pairs:
        print(f"REFUSE — no source/export filename pairs between {src_dir} and {exp_dir}. "
              f"Nothing was compared, so nothing was shown additive.")
        return 2

    print(f"  compared {len(pairs)} source/export pair(s); {di_added} DI element(s) added in total")
    exercised = [k for k in INTENT_VOCAB if src_c[k] > 0]
    unexercised = [k for k in INTENT_VOCAB if src_c[k] == 0]
    print("  intent-extension population (source -> export), per document set identity above:")
    for k in INTENT_VOCAB:
        mark = "" if src_c[k] else "   <- UNEXERCISED: absent from every source map, so this "
        print(f"      aef:{k:<14} {src_c[k]:>4} -> {exp_c[k]:>4}{mark}"
              + ("guard proves NOTHING about it" if not src_c[k] else ""))

    if violations:
        print(f"\nFAIL — {len(violations)} violation(s); export is NOT additive:")
        for v in violations:
            print("  " + v)
        return 1

    print(f"\nPASS — {len(pairs)} document(s) identical outside DI: no element removed, added or "
          f"reordered, no attribute changed.")
    print(f"       Covered {len(exercised)} of {len(INTENT_VOCAB)} named intent extensions "
          f"({', '.join('aef:' + k for k in exercised)}).")
    if unexercised:
        print(f"       NOT covered, because no source map contains one: "
              f"{', '.join('aef:' + k for k in unexercised)}.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
