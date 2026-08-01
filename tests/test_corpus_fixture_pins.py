#!/usr/bin/env python3
"""Corpus fixture byte-pin guard (T-216) — the 832-authored canonical corpus diagrams
delivered to the AEF peer over the collaboration rail (arc: designer-authoring-surface),
which AEF now cross-validates byte-exact and holds behind its own sha-guard tests.

WHY a sha-pin contract for these: unlike the typed-event fixtures (guarded by
test_typed_event_fixture_contract.py, T-212), the pair-draft corpus diagrams
(session-handover, T-214; dispatch-loop, T-215) are NOT covered by any browser-driven
harness — they are hand-authored dialect exemplars, not editor round-trip fixtures. They ARE
the shared byte-identical artifact AEF pins on its side (T-559 "pinned sha" half of the
producer contract): AEF's `fw bpmn` compile + sha-guard is keyed to the exact bytes 832
delivered on the rail. A silent local edit to either would break AEF's cross-validation with
NO local failure — the precise gap T-212 closed for typed-events/boundary, here extended to
the two pair-draft diagrams.

This test pins the exact bytes AEF holds and asserts each still validates CLEAN under the
canonical validator (tools/validate-workflow.py) — in PURE PYTHON (stdlib only), so it runs
in EVERY environment. If a fixture is legitimately re-authored (e.g. the T-214 operator/v2
relabel), RE-PIN the sha HERE + notify AEF on the rail so both sides re-pin in lockstep.

BOUNDARY REALITY (T-559 symmetric): this asserts the 832-side producer INPUT only —
byte-determinism + validator-clean. It does NOT assert AEF's compiler OUTPUT (skeletons,
gateway surfacing); that lives on AEF's side. Complements, does not duplicate, T-212.

Runnable standalone (`python3 tests/test_corpus_fixture_pins.py`, exit 0 = pass) and under
pytest. Wired into tests/run-bridge-tests.sh.
"""
import hashlib
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")

# Pinned full sha256 digests — AEF cross-validates byte-exact against these
# (rail: session-handover offset 92; dispatch-loop offsets 99+101). Edit a fixture → re-pin
# HERE + notify AEF on the rail so both sides re-pin in lockstep.
FULL_SHA = {
    "session-handover.bpmn":
        "d971a2fccbac6cf93bebcb8ed7de63e6dfc3c6445626e286f18fc282c87f5855",
    "dispatch-loop.bpmn":
        "95bc24cdb0d27952a4f85da55368b74fc8c1e9586960d0dd839453595543594b",
    # offpage-seam.bpmn (T-219, pair-draft #3) — resolved leg pinned to AEF's live
    # aef-task-lifecycle uuid (rail offset 118); delivered rail-inline offset TBD.
    # T-324 RE-PIN (rail 363 GO / 366 delivery): 0bc15bfac81d… → f9422acd330d…
    # The three off-page hosts carried <bpmn:linkEventThrow>, the canonical YAML
    # type name in the BPMN namespace, which neither emitter can produce. Repaired
    # to <bpmn:intermediateThrowEvent> — tag rename ONLY, 6 lines, no
    # <bpmn:linkEventDefinition/> added: link-ness rides on <aef:link> by design
    # (src/aef-workflow-designer.html:9233-9236), so adding one would have
    # reintroduced the same defect class under a legal element name.
    "offpage-seam.bpmn":
        "f9422acd330d240dec384591753782dde940289cc94475f22be96aa1551d0c5c",
    # s4-exemplar.bpmn (T-235) — S4 picker-claim exemplar, byte-copy of the map SAVED
    # through the running editor (.editor-versions/claim-smoke-legacy/v1.bpmn): born via
    # the T-228 pending-refs picker (adopts+claims ghost 3ceaf02d, via:ui), carries the
    # 3 off-page legs (resolved 1f9b5f0c / ghost 4300eae7 / legacy review-map). AEF holds
    # it at tests/fixtures/832/s4-exemplar.{bpmn,sha256} (their T-2593 intake).
    "s4-exemplar.bpmn":
        "82b6ab78cd5f54b800b3c644b6f35eefbb169dc3ca6d05ce802807a3cec956b7",
}


def _read_bytes(name):
    with open(os.path.join(FIXTURES, name), "rb") as fh:
        return fh.read()


# T-321: counted tolerances — {fixture: (rule-id, exact expected count)}. A finding
# admitted here still PRINTS every run and its count is asserted, so a 4th
# occurrence (or a different rule) fails the build rather than joining the
# exemption.
#
# T-324: EMPTY, and empty is the point. The single entry (offpage-seam.bpmn,
# E-XML-NODE-TYPE x3) is GONE rather than decremented to zero — a tolerance whose
# reason has been repaired must not survive as a 0-count placeholder, because the
# next malformed element would then be measured against an expectation instead of
# failing outright. With this dict empty, `tolerated` is None for every fixture and
# ANY non-clean pinned fixture fails on the FIRST instance.
#
# The mechanism itself is kept deliberately: coordinated re-pins with AEF are a
# recurring shape (T-314, T-324), and re-inventing this under time pressure is how
# a counted tolerance degrades into a silent suppression. A new entry MUST cite an
# open coordinated-re-pin task.
_TOLERATED_FINDINGS = {}


def _validates_clean(name):
    """Return (ok, output): does the fixture validate CLEAN (exit 0) under the validator."""
    proc = subprocess.run(
        [sys.executable, VALIDATOR, os.path.join(FIXTURES, name)],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    return proc.returncode == 0, (proc.stdout + proc.stderr).decode("utf-8", "replace")


def _sha(raw):
    return hashlib.sha256(raw).hexdigest()


def failures():
    fails = []
    for name, pinned in sorted(FULL_SHA.items()):
        try:
            raw = _read_bytes(name)
        except FileNotFoundError:
            fails.append("(0) %s missing — delivered fixture removed?" % name)
            continue

        # (1) byte-determinism — sha256 over exact bytes == pin, recompute-stable
        h1 = _sha(raw)
        h2 = _sha(_read_bytes(name))
        if h1 != pinned:
            fails.append(
                "(1) %s sha256\n     got    %s\n     pinned %s — source_bpmn_sha changed "
                "(fixture edited? re-pin FULL_SHA[%r] + notify AEF on the rail)"
                % (name, h1, pinned, name)
            )
        if h1 != h2:
            fails.append("(1) %s sha256 not recompute-stable: %s vs %s" % (name, h1, h2))

        # (2) validator-clean — the byte-pin is only meaningful if the pinned bytes still
        #     satisfy the canonical dialect (a re-pin can't silently pin a broken diagram).
        ok, out = _validates_clean(name)
        if not ok:
            # COUNTED tolerance, never suppression (T-312/T-314/T-317 pattern):
            # the note prints every run and the count is asserted, so a second
            # instance fails the build instead of joining the exemption.
            #
            # Historical instance (T-321 → T-324, now REPAIRED): offpage-seam.bpmn
            # carried 3 <bpmn:linkEventThrow> elements — not a BPMN element, the
            # YAML type name in the BPMN namespace, which NEITHER emitter can
            # produce (bridge TYPE_MAP and designer TYPE_TAG both rename it to
            # intermediateThrowEvent on the way out). T-321's vocabulary gate was
            # the first thing that could see it; before that the only witness was
            # an INFO skip-note from the lane-capacity rule. Because the bytes were
            # pinned and AEF cross-validates them, repair had to be a COORDINATED
            # re-pin (T-324), exactly as T-314 handled the lane-geometry defect in
            # the fixtures they hold. Kept as the worked example of what this
            # branch is for — the dict above is now empty.
            tolerated = _TOLERATED_FINDINGS.get(name)
            n_hit = sum(1 for ln in out.splitlines() if tolerated and tolerated[0] in ln)
            if tolerated and n_hit == tolerated[1]:
                print("  NOTE (tolerated, T-321/T-324): %s has %d x %s — pinned "
                      "bytes AEF cross-holds; repair is a coordinated re-pin"
                      % (name, n_hit, tolerated[0]))
            else:
                first = out.strip().splitlines()[:3]
                fails.append(
                    "(2) %s no longer validates CLEAN:\n     %s" % (name, "\n     ".join(first))
                )

    # (3) teeth — a one-byte change to a pinned fixture MUST trip the sha assertion, proving
    #     the pin is not vacuous. Mutate in memory (do not touch the file) and re-check.
    probe = "dispatch-loop.bpmn"
    mutated = _sha(_read_bytes(probe) + b" ")  # append one space
    if mutated == FULL_SHA[probe]:
        fails.append("(3) mutation no-op: appended byte did not change %s sha — no teeth" % probe)

    return fails


def test_corpus_fixture_pins():
    fails = failures()
    assert not fails, "corpus fixture pin failures:\n" + "\n".join(fails)


def main():
    fails = failures()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        sys.stderr.write("\n%d pin failure(s)\n" % len(fails))
        return 1
    print(
        "OK: corpus fixture pins — %s"
        % ", ".join("%s (sha %s)" % (n, s[:12]) for n, s in sorted(FULL_SHA.items()))
    )
    print("  byte-determinism + validator-clean + teeth for the pair-draft diagrams AEF cross-holds")
    return 0


if __name__ == "__main__":
    sys.exit(main())
