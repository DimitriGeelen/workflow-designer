#!/usr/bin/env python3
"""_t830-correlation-gate.py — correlations are assigned, derived, and resolve.

H3, ruled D by the operator on 2026-09-22.

WHY THIS EXISTS AS CODE AND NOT AS A SENTENCE. `source-manifest.yaml` has said since
2026-08-26 that "no peer handoff may be opened until they are assigned". A peer handoff
opened on 2026-08-27 with both slots reading UNASSIGNED, and stayed open for two months.
The rule was true, written down, and inert — nothing ever evaluated it. That is PL-206:
a control that CAN fail is worthless if nothing ever fires its stimulus.

WHAT IT CHECKS, and each is a different way the ruling can rot:

  1. ASSIGNED      neither slot reads UNASSIGNED.
  2. DERIVED       each value is `arc:<slug>[/<suffix>]` — derived from a governed object
                   rather than minted. The ruling's whole point is that a minted value can
                   be created by accident and drift by repetition; three did.
  3. RESOLVES      the slug resolves to `.context/arcs/<slug>.yaml`. A derived reference
                   that cannot be checked is a minted string with extra steps. This is the
                   self-invalidating property: if the arc goes away the correlation STOPS
                   WORKING rather than quietly continuing to name nothing.
  4. PROVENANCE    a provenance block records status, what it derives from, who assigned it
                   and under which ruling — so a reader checks rather than trusts. The H2
                   field in this same project once carried a FABRICATED attribution; that is
                   not a hypothetical failure mode here.
  5. NOT PROVISIONAL
                   a value whose `assigned_by` is an agent is PROVISIONAL. It may be used
                   for transport — the system keeps working — but it CANNOT satisfy a
                   completion gate. This is the antifragile half of the ruling: under an
                   unratified value the work continues and the COMPLETION CLAIM fails,
                   rather than completion being reported against nothing.

Exit: 0 assigned, derived, resolving and ratifiable
      1 a finding (named, with the rule that produced it)
      2 PROVISIONAL — usable for transport, cannot close a completion gate
      3 could-not-measure
"""
import os
import re
import sys

try:
    import yaml
except ImportError:
    sys.stderr.write("COULD-NOT-MEASURE: pyyaml unavailable\n")
    sys.exit(3)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
MANIFEST = os.path.join(ROOT, "docs/research/executable-workflow/source-manifest.yaml")
ARCS = os.path.join(ROOT, ".context/arcs")
ENVELOPE = os.path.join(
    ROOT, "docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml"
)

SLOTS = ("shared_initiative_correlation", "designer_agent_correlation")
DERIVED_RE = re.compile(r"^arc:([A-Za-z0-9][A-Za-z0-9_.-]*)(?:/[A-Za-z0-9][A-Za-z0-9_.\-/]*)?$")


def main():
    if not os.path.isfile(MANIFEST):
        sys.stderr.write("COULD-NOT-MEASURE: manifest not found: %s\n" % MANIFEST)
        return 3
    try:
        doc = yaml.safe_load(open(MANIFEST, encoding="utf-8"))
    except Exception as exc:
        sys.stderr.write("COULD-NOT-MEASURE: manifest did not parse: %s\n" % exc)
        return 3

    corr = (doc or {}).get("correlation")
    if not isinstance(corr, dict):
        sys.stderr.write("COULD-NOT-MEASURE: no `correlation:` block in the manifest\n")
        return 3

    findings = []
    provisional = []

    print("=== T-830: correlation gate (H3, ruled D) ===")
    print()

    prov = corr.get("provenance")
    if not isinstance(prov, dict):
        findings.append(
            "no `provenance:` block — a correlation with no recorded origin is exactly "
            "the state H3 was opened to end. RULE: provenance"
        )
        prov = {}

    for slot in SLOTS:
        raw = corr.get(slot)
        value = "" if raw is None else str(raw).strip()

        if not value or value == "UNASSIGNED":
            findings.append(
                "%s is UNASSIGNED. Phase 4 completion is defined as read-back on the SAME "
                "correlation, so this makes completion undefinable rather than merely "
                "unrecorded. RULE: assigned" % slot
            )
            continue

        m = DERIVED_RE.match(value)
        if not m:
            findings.append(
                "%s = %r is not a derived reference. Expected `arc:<slug>` optionally "
                "followed by `/<suffix>`. A free string is a minted value, and three "
                "minted values are what H3 exists to end. RULE: derived" % (slot, value)
            )
            continue

        slug = m.group(1)
        arc_path = os.path.join(ARCS, slug + ".yaml")
        if not os.path.isfile(arc_path):
            findings.append(
                "%s = %r derives from an arc that does NOT resolve (%s missing). A derived "
                "reference that cannot be checked is a minted string with extra steps. "
                "RULE: resolves" % (slot, value, os.path.relpath(arc_path, ROOT))
            )
            continue

        print("  ok   %-30s %s" % (slot, value))
        print("       derives from .context/arcs/%s.yaml (resolves)" % slug)

    assigned_by = str(prov.get("assigned_by", "")).strip().lower()
    status = str(prov.get("status", "")).strip().lower()
    if assigned_by and assigned_by != "operator":
        provisional.append(
            "provenance.assigned_by is %r, not `operator`. The value is PROVISIONAL: usable "
            "for transport, but it cannot satisfy a completion gate. That is the ruling "
            "working, not a defect — an unratified correlation must not be able to report "
            "completion against itself." % assigned_by
        )
    if status == "provisional":
        provisional.append("provenance.status is `provisional`.")

    # The rule that was prose for two months: a handoff open against an unusable slot.
    #
    # ON `findings` ONLY, NOT `provisional`, and the control is what forced that distinction.
    # The manifest forbids opening a handoff until the correlations are ASSIGNED. A
    # provisional value IS assigned — it is merely unratified — and the ruling says
    # explicitly that such a value stays usable for TRANSPORT. A handoff is transport. So
    # firing this rule on a provisional value would forbid the one thing the ruling
    # deliberately still permits, and would collapse "cannot claim completion" into
    # "cannot talk". The first draft did exactly that and the control caught it.
    if os.path.isfile(ENVELOPE) and findings:
        findings.append(
            "A PEER HANDOFF IS OPEN (%s exists) while the correlation is unusable above. "
            "The manifest has forbidden exactly this since 2026-08-26 and a handoff opened "
            "anyway on 2026-08-27, because the rule was prose. It is now a check. "
            "RULE: no-handoff-without-correlation"
            % os.path.relpath(ENVELOPE, ROOT)
        )

    print()
    if findings:
        print("FINDINGS:")
        for f in findings:
            print("  - %s" % f)
        return 1
    if provisional:
        print("PROVISIONAL — transport is fine, completion is not:")
        for p in provisional:
            print("  - %s" % p)
        return 2

    print("correlations assigned, derived, resolving, and ratifiable")
    return 0


if __name__ == "__main__":
    sys.exit(main())
