#!/usr/bin/env python3
"""Designer → AEF promote-contract test (T-206) — the 832-side half of the joint
compile→promote→`fw task create` seam (AEF green light: DM offset 65, AEF ref
`tests/unit/bpmn_promote_e2e.bats`, T-2545).

BOUNDARY REALITY (decisive): T-559 is SYMMETRIC. 832 cannot run AEF's
`fw bpmn compile`/`promote`; AEF cannot read 832's exports. There is no live
end-to-end run from either side. The seam is a PRODUCER-CONTRACT test over a
SHARED FIXTURE: this test proves 832's `.bpmn` carries exactly the INPUTS AEF's
compiler consumes; AEF proves its promote/gate OUTPUTS on its side; the two
halves meet at a byte-identical fixture + pinned sha.

SCOPE SPLIT (do NOT invert): this test asserts producer INPUTS only —
  * stable namespaced `aef:uid` on every flow node and edge (reconcile key half 1);
  * every owner-bearing node in exactly one lane with a defined `laneMeta authority`;
  * owner DERIVED from lane authority (IW-9, no node override) via the canonical
    mapping (tools/validate-workflow.py §3, reused not forked);
  * the AEF manifest-read tuple {name, owner, workflow_type} extractable per
    owner-bearing uid;
  * byte-determinism: sha256 over the exact fixture bytes is stable and equals a
    pinned constant (reconcile key half 2: `source_bpmn_sha`).
It does NOT assert AEF OUTPUTS (manifest write, aef_provenance stamp,
materialized owner:human/status:captured, reconcile states, gate refusal) — those
are AEF's side, in bpmn_promote_e2e.bats. Asserting them here would build against
the wrong contract.

NOTE (horizon): the shared fixture carries no `horizon` — 832's export does not
emit it here; AEF defaults it manifest-side. So `horizon` is intentionally NOT a
832 producer assertion (documented, not silently dropped).

Runnable standalone: `python3 tests/test_promote_contract.py` (exit 0 = pass,
non-zero = failure), matching the repo's other test scripts. Wired into
tests/run-bridge-tests.sh.
"""

import hashlib
import importlib.util
import os
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")
VW_PATH = os.path.join(ROOT, "tools", "validate-workflow.py")

# tools/validate-workflow.py has a hyphen — load it by path (same idiom as
# test_validate_iw9.py). Reuse its namespace constants + validator so this test
# tracks the canonical contract instead of forking a second copy (PL-005).
_spec = importlib.util.spec_from_file_location("validate_workflow", VW_PATH)
vw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vw)

BPMN_NS = vw.BPMN_NS
AEF_NS = vw.AEF_NS

# The shared fixture AEF cross-validates byte-exact on its side. Two lanes
# (Human·sovereignty, Agent·initiative), 3 nodes; the one owner-bearing node is
# the inception subProcess (sovereignty → owner human).
FIXTURE = "inception-gonogo.bpmn"
# T-314 RE-PIN (was 093858400716…). The fixture declared `human` first while
# drawing the human node BELOW the agent nodes — a wholesale lane inversion
# (1/1 and 2/2 nodes cross) found by T-312's lane_geometry rule. Repaired by
# reordering the laneSet ONLY: membership, positions, uids, flows, lane heights
# and the element set are byte-for-byte identical, so this is zero-semantic by
# AEF's own classification. Both lanes are height 160, so the cumulative band
# boundaries did not move either. AEF cleared the re-pin as a no-op on their
# side (rail 343/344) and was told the new sha on the rail.
PINNED_SHA = "bbfbc5ec48356c3a643efa21e37912994a3fff56532b7e0ef4815f91fbed00ab"

# lane authority -> task owner collapse. CANONICAL SOURCE is the AUTHORITY_OWNER
# dict in tools/validate-workflow.py:_check_iw9_authority (mapping-v1 §3). It is a
# method-local there, so it can't be imported directly — mirrored here and guarded
# below (check_mapping_not_drifted) so a change to the canonical mapping trips this
# test rather than silently diverging.
AUTHORITY_OWNER = {
    "sovereignty": "human",
    "initiative": "agent",
    "authority": "agent",
    # "external" -> no task authored; "none" -> unspecified (both skipped)
}

OWNER_BEARING = {"subProcess", "serviceTask", "userTask", "scriptTask"}
# process children that are NOT flow nodes/edges and so carry no aef:uid
SKIP_LOCALS = {"laneSet", "extensionElements"}


def _local(tag):
    return tag.split("}", 1)[-1] if "}" in tag else tag


def read_fixture_bytes(name=FIXTURE):
    with open(os.path.join(FIXTURES, name), "rb") as fh:
        return fh.read()


def process_of(text):
    root = ET.fromstring(text)
    proc = root.find("{%s}process" % BPMN_NS)
    if proc is None:
        raise AssertionError("no <bpmn:process> in fixture")
    return proc


def node_authority_map(proc):
    """flow-node id -> its lane's laneMeta authority (mirrors validator §3)."""
    out = {}
    lane_set = proc.find("{%s}laneSet" % BPMN_NS)
    lanes = lane_set.findall("{%s}lane" % BPMN_NS) if lane_set is not None else []
    for lane in lanes:
        lm = lane.find("{%s}extensionElements/{%s}laneMeta" % (BPMN_NS, AEF_NS))
        authority = lm.get("authority") if lm is not None else None
        for ref in lane.findall("{%s}flowNodeRef" % BPMN_NS):
            rid = (ref.text or "").strip()
            if rid:
                out[rid] = authority
    return out


def uid_of(el):
    u = el.find("{%s}extensionElements/{%s}uid" % (BPMN_NS, AEF_NS))
    return u.get("value") if u is not None else None


def uid_missing(proc):
    """flow nodes + edges lacking a non-empty aef:uid (reconcile key totality)."""
    missing = []
    for child in list(proc):
        local = _local(child.tag)
        if local in SKIP_LOCALS:
            continue
        u = uid_of(child)
        if not (u and u.strip()):
            missing.append(child.get("id") or "<no-id>")
    return missing


def extract_manifest(proc):
    """Per owner-bearing uid, the AEF manifest-read tuple {name, owner,
    workflow_type}. Raises on a structural contract breach (missing uid,
    undefined/authored-out lane authority)."""
    auth = node_authority_map(proc)
    manifest = {}
    for child in list(proc):
        local = _local(child.tag)
        if local not in OWNER_BEARING:
            continue
        nid = child.get("id")
        uid = uid_of(child)
        if not (uid and uid.strip()):
            raise AssertionError("owner-bearing node %r has no aef:uid" % nid)
        a = auth.get(nid)
        if a not in AUTHORITY_OWNER:
            raise AssertionError(
                "owner-bearing node %r lane authority %r has no owner collapse "
                "(absent/external/none) — owner cannot be derived" % (nid, a)
            )
        owner = AUTHORITY_OWNER[a]
        name = child.get("name")
        if not (name and name.strip()):
            raise AssertionError("owner-bearing node %r has no name" % nid)
        meta = child.find("{%s}extensionElements/{%s}meta" % (BPMN_NS, AEF_NS))
        wft = meta.get("workflowType") if meta is not None else None
        # node-level owner override must be gone (IW-9): owner derives from lane
        if child.get("owner") is not None or (meta is not None and meta.get("owner")):
            raise AssertionError(
                "owner-bearing node %r carries a node-level owner override "
                "(IW-9 retired it — owner must derive from lane)" % nid
            )
        manifest[uid] = {"name": name, "owner": owner, "workflow_type": wft}
    return manifest


def check_mapping_not_drifted():
    """Canonical AUTHORITY_OWNER lives in validate-workflow.py as a method-local;
    guard that our mirror still matches so the mapping can't silently fork."""
    with open(VW_PATH) as fh:
        src = fh.read()
    fails = []
    for authority, owner in AUTHORITY_OWNER.items():
        needle = '"%s": "%s"' % (authority, owner)
        if needle not in src:
            fails.append(
                "AUTHORITY_OWNER mirror drifted: %r absent from validate-workflow.py "
                "(canonical mapping changed — reconcile this test)" % needle
            )
    return fails


def failures():
    fails = []
    raw = read_fixture_bytes()
    text = raw.decode("utf-8")

    # (0) mapping mirror is in sync with the canonical validator
    fails += check_mapping_not_drifted()

    # (1) canonical validator accepts the fixture (reuses O-3 sovereignty + shape).
    #
    #     T-314: the W-XML-LANE-GEOMETRY exception that used to live here is GONE,
    #     because its cause is gone. This fixture declared 'human' first while
    #     drawing hum_1_inception at y=300, below both agent nodes at y=120 — a
    #     wholesale inversion found in our own bytes the day T-312's rule landed,
    #     and the same authoring defect AEF had diagnosed in their generator. It is
    #     now repaired at the source by a laneSet reorder (zero-semantic: nothing
    #     but declaration order changed), so the fixture validates CLEAN and no
    #     tolerance is needed. A tolerance kept past its cause is indistinguishable
    #     from a suppression list, so it comes out the moment the bytes are fixed.
    all_findings = vw.run_xml(text)
    blocking = [f for f in all_findings if f.severity != vw.INFO]
    if blocking:
        rules = sorted({f.rule for f in blocking})
        fails.append("(1) validator rejects the shared fixture; findings=%s" % rules)

    proc = process_of(text)

    # (2) uid totality — every flow node + edge carries a non-empty aef:uid
    miss = uid_missing(proc)
    if miss:
        fails.append("(2) flow nodes/edges missing aef:uid: %s" % miss)

    # (3) manifest tuple per owner-bearing uid is exactly the expected contract
    try:
        manifest = extract_manifest(proc)
    except AssertionError as e:
        fails.append("(3) manifest extraction failed on clean fixture: %s" % e)
        manifest = None
    expected = {
        "n_inception": {
            "name": "explore the question — go/no-go",
            "owner": "human",          # derived from sovereignty lane (IW-9)
            "workflow_type": "inception",
        }
    }
    if manifest is not None and manifest != expected:
        fails.append(
            "(3) manifest tuple mismatch.\n  expected: %s\n  got:      %s"
            % (expected, manifest)
        )

    # (4) byte-determinism — sha256 over exact bytes == pin, and recompute-equal
    h1 = hashlib.sha256(raw).hexdigest()
    h2 = hashlib.sha256(read_fixture_bytes()).hexdigest()
    if h1 != PINNED_SHA:
        fails.append(
            "(4) fixture sha256 %s != pinned %s — source_bpmn_sha reconcile key "
            "changed (fixture edited? re-pin + notify AEF)" % (h1, PINNED_SHA)
        )
    if h1 != h2:
        fails.append("(4) sha256 not recompute-stable: %s vs %s" % (h1, h2))

    # (5a) gate teeth — blanking the sovereignty lane authority must trip the
    #      canonical validator (O-3), proving contract-clean is not vacuous.
    broken_auth = text.replace('authority="sovereignty"', 'authority="initiative"')
    if broken_auth == text:
        fails.append("(5a) mutation no-op: 'authority=\"sovereignty\"' not found")
    elif vw.exit_code(vw.run_xml(broken_auth)) == 0:
        fails.append(
            "(5a) inception moved out of the sovereignty lane was ACCEPTED — "
            "gate has no teeth (O-3 not enforced)"
        )

    # (5b) gate teeth — stripping the owner-bearing node's uid must be detected
    #      by the manifest/uid contract (not silently passed).
    broken_uid = text.replace('<aef:uid value="n_inception"/>', "")
    if broken_uid == text:
        fails.append("(5b) mutation no-op: n_inception uid element not found")
    else:
        bproc = process_of(broken_uid)
        if not uid_missing(bproc):
            fails.append("(5b) stripped uid NOT detected by uid-totality check")
        try:
            extract_manifest(bproc)
            fails.append("(5b) manifest extraction accepted a node with no uid")
        except AssertionError:
            pass  # expected

    return fails


def main():
    fails = failures()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        sys.stderr.write("\n%d contract failure(s)\n" % len(fails))
        return 1
    print("OK: designer→AEF promote contract — %s (sha %s)" % (FIXTURE, PINNED_SHA[:12]))
    print("  manifest owner-bearing uids: n_inception {owner:human←sovereignty, "
          "workflow_type:inception}; uid totality + byte-determinism + teeth verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
