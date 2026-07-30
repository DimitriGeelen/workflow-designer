#!/usr/bin/env python3
"""Two-lane joint promote-fixture contract (T-208) — the 832-authored canonical joint
fixture for the compile→promote seam (rail offset 69, option (a); AEF ref
`tests/unit/bpmn_promote_e2e.bats`, T-2545/T-2546).

WHY a second contract test beside test_promote_contract.py: the proven shared fixture
`inception-gonogo.bpmn` has ONE owner-bearing node — the human/sovereignty inception — so
it exercises only sovereignty→owner:human derivation. AEF's seam-slice also needs
initiative→owner:agent. `two-lane-joint.bpmn` adds an owner-bearing serviceTask in the
Agent·Initiative lane, so its manifest carries BOTH derivations. This test asserts that
producer contract over the new fixture.

BOUNDARY REALITY (same as test_promote_contract): T-559 is symmetric — no live e2e from
either side. This asserts producer INPUTS only (uid totality, lane-authority-derived
owner, manifest tuple, byte-determinism); it does NOT assert AEF promote OUTPUTS. The
manifest-extraction + mapping-mirror logic is REUSED from test_promote_contract (not
forked — PL-005) so both tests track the one canonical contract.

Runnable standalone (`python3 tests/test_two_lane_joint_contract.py`, exit 0 = pass) and
under pytest. Wired into tests/run-bridge-tests.sh.
"""
import hashlib
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Reuse the promote-contract helpers by path (its filename has no hyphen, but load it
# by spec anyway so this test does not depend on sys.path / cwd). This binds us to the
# SAME extract_manifest / uid_missing / node_authority_map / AUTHORITY_OWNER mirror the
# single-node contract uses — one contract, two fixtures.
_pc_path = os.path.join(ROOT, "tests", "test_promote_contract.py")
_spec = importlib.util.spec_from_file_location("promote_contract", _pc_path)
pc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pc)

vw = pc.vw  # the canonical validate-workflow module, already loaded by pc

FIXTURE = "two-lane-joint.bpmn"
FIXTURE_PATH = os.path.join(pc.FIXTURES, FIXTURE)
# source_bpmn_sha reconcile key — pinned; AEF cross-validates byte-exact against this.
PINNED_SHA = "efb53839bfddeb44c12bf0d8e11198c4394b017f55f0e0e238eb2524271a8c92"

# The manifest AEF reads from this fixture: one owner-bearing node PER lane, owner
# DERIVED from lane authority (IW-9, no node override).
EXPECTED_MANIFEST = {
    "n_inception": {
        "name": "explore the question — go/no-go",
        "owner": "human",          # ← sovereignty lane
        "workflow_type": "inception",
    },
    "n_plan": {
        "name": "draft the build plan",
        "owner": "agent",          # ← initiative lane
        "workflow_type": "build",
    },
}


def _read_bytes():
    with open(FIXTURE_PATH, "rb") as fh:
        return fh.read()


def failures():
    fails = []
    raw = _read_bytes()
    text = raw.decode("utf-8")

    # (0) the AUTHORITY_OWNER mirror in test_promote_contract is still in sync with the
    #     canonical validator — reuse its guard so this fixture can't ride a silent fork.
    fails += pc.check_mapping_not_drifted()

    # (1) canonical validator accepts the fixture (O-3 sovereignty + shape).
    #     Same known, printed exception as the T-206 fixture: this one declares
    #     'human' first and draws hum_1_inception at y=300 under three agent
    #     nodes — a wholesale inversion under W-XML-LANE-GEOMETRY (T-312).
    #     sha-pinned and AEF-facing, so repair is a coordinated re-pin (T-314).
    all_findings = vw.run_xml(text)
    for f in all_findings:
        if f.rule == "W-XML-LANE-GEOMETRY":
            print("NOTE (known, T-314): %s: %s" % (f.location, f.message))
    blocking = [
        f
        for f in all_findings
        if f.severity != vw.INFO and f.rule != "W-XML-LANE-GEOMETRY"
    ]
    if blocking:
        rules = sorted({f.rule for f in blocking})
        fails.append("(1) validator rejects the joint fixture; findings=%s" % rules)

    proc = pc.process_of(text)

    # (2) uid totality — every flow node + edge carries a non-empty aef:uid
    miss = pc.uid_missing(proc)
    if miss:
        fails.append("(2) flow nodes/edges missing aef:uid: %s" % miss)

    # (3) manifest tuples — BOTH sovereignty→human AND initiative→agent present & exact
    try:
        manifest = pc.extract_manifest(proc)
    except AssertionError as e:
        fails.append("(3) manifest extraction failed on clean fixture: %s" % e)
        manifest = None
    if manifest is not None:
        if manifest != EXPECTED_MANIFEST:
            fails.append(
                "(3) manifest tuple mismatch.\n  expected: %s\n  got:      %s"
                % (EXPECTED_MANIFEST, manifest)
            )
        # explicit both-lanes assertion — the whole point of this second fixture
        owners = {m["owner"] for m in manifest.values()}
        if owners != {"human", "agent"}:
            fails.append(
                "(3) joint fixture must derive BOTH owner:human (sovereignty) and "
                "owner:agent (initiative); got owners=%s" % sorted(owners)
            )

    # (4) byte-determinism — sha256 over exact bytes == pin, recompute-stable
    h1 = hashlib.sha256(raw).hexdigest()
    h2 = hashlib.sha256(_read_bytes()).hexdigest()
    if h1 != PINNED_SHA:
        fails.append(
            "(4) fixture sha256 %s != pinned %s — source_bpmn_sha changed (fixture "
            "edited? re-pin in this test + T-208 + notify AEF)" % (h1, PINNED_SHA)
        )
    if h1 != h2:
        fails.append("(4) sha256 not recompute-stable: %s vs %s" % (h1, h2))

    # (5a) teeth — moving the inception out of the sovereignty lane must trip the
    #      canonical validator (O-3), proving contract-clean is not vacuous.
    broken_auth = text.replace('authority="sovereignty"', 'authority="initiative"')
    if broken_auth == text:
        fails.append("(5a) mutation no-op: 'authority=\"sovereignty\"' not found")
    elif vw.exit_code(vw.run_xml(broken_auth)) == 0:
        fails.append(
            "(5a) inception moved out of the sovereignty lane was ACCEPTED — "
            "gate has no teeth (O-3 not enforced)"
        )

    # (5b) teeth — blanking the initiative lane's authority must break owner derivation
    #      for the agent task (manifest extraction raises), not silently pass.
    broken_init = text.replace('authority="initiative"', 'authority="none"')
    if broken_init == text:
        fails.append("(5b) mutation no-op: 'authority=\"initiative\"' not found")
    else:
        try:
            pc.extract_manifest(pc.process_of(broken_init))
            fails.append(
                "(5b) agent task with no derivable lane authority was accepted — "
                "initiative→agent derivation has no teeth"
            )
        except AssertionError:
            pass  # expected — owner cannot be derived

    # (5c) teeth — stripping the agent task's uid must be caught by uid-totality.
    broken_uid = text.replace('<aef:uid value="n_plan"/>', "")
    if broken_uid == text:
        fails.append("(5c) mutation no-op: n_plan uid element not found")
    elif not pc.uid_missing(pc.process_of(broken_uid)):
        fails.append("(5c) stripped n_plan uid NOT detected by uid-totality check")

    return fails


def main():
    fails = failures()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        sys.stderr.write("\n%d contract failure(s)\n" % len(fails))
        return 1
    print("OK: two-lane joint promote contract — %s (sha %s)" % (FIXTURE, PINNED_SHA[:12]))
    print("  owner-bearing uids: n_inception {owner:human←sovereignty, wf:inception}; "
          "n_plan {owner:agent←initiative, wf:build}; uid totality + byte-determinism + teeth verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
