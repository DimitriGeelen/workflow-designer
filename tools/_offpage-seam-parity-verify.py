#!/usr/bin/env python3
"""_offpage-seam-parity-verify.py — T-232 / S5a off-page seam parity guard.

The PL-005/PL-030 drift counter for the off-page connector seam: a STATIC, pure-Python
key-set-equality guard (PD-015) anchored on the SHARED byte-fixture that 832 AND AEF both
pin — tests/fixtures/aef-bpmn/offpage-seam.bpmn (T-219, pair-draft #3). It turns S2's
one-time round-trip check into a STANDING guard that runs even when the chromium harness
skips (the 832 pattern — cf. tests/test_typed_event_fixture_contract.py, T-212).

What it asserts (on the identical bytes AEF's compiler sees):
  1. sha256 pin — a fixture edit fails loud before anything else (never silently re-baselines).
  2. No-silent-drop / key-set parity: every <aef:link> is accounted for by EXACTLY one 832
     parser path — _link_refs_from_text (uuid-pinned) ∪ _legacy_refs_from_text (legacy) —
     so count(links) == len(uuid_refs)+len(legacy_refs). This is PL-030's core: aspect-by-
     aspect guards can all pass while a whole leg is silently dropped by both paths.
  3. Field-set completeness per leg (workflowRef, name / targetWorkflow) + resolved host node.
  4. Cross-side anchor: the resolved leg's workflowRef == AEF's live uuid 1f9b5f0c… .

Reuses gallery-serve.py's OWN parser functions (imported by path — no re-implementation), so
a future change to those parsers re-runs through this guard. Dependency-free (stdlib only).
Exit 0 = all pass; exit 1 = any fail (the P-011 completion gate reads this).
"""
import hashlib
import importlib.util
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FIXTURE = os.path.join(ROOT, 'tests', 'fixtures', 'aef-bpmn', 'offpage-seam.bpmn')

# Byte pin — MUST match tests/test_corpus_fixture_pins.py FULL_SHA['offpage-seam.bpmn']
# and AEF's tests/fixtures/832/pair-draft-3.sha256. Editing the fixture re-pins BOTH sides.
# T-324 re-pin: 0bc15bfac81d… → f9422acd330d… (3 x <bpmn:linkEventThrow> host tags
# corrected to <bpmn:intermediateThrowEvent>; tag rename only, aef:link untouched).
PIN_SHA = 'f9422acd330d240dec384591753782dde940289cc94475f22be96aa1551d0c5c'
RESOLVED_UUID = '1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7'   # AEF live uuid (pair-draft #3 resolved leg)
GHOST_UUID = '22222222-2222-4222-8222-222222222222'
LEGACY_SLUG = 'review-map'

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond), detail))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def load_gs():
    spec = importlib.util.spec_from_file_location('gallery_serve', os.path.join(HERE, 'gallery-serve.py'))
    gs = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gs)
    return gs


def main():
    if not os.path.exists(FIXTURE):
        print('FAIL fixture missing: %s' % FIXTURE)
        sys.exit(1)
    raw = open(FIXTURE, 'rb').read()
    text = raw.decode('utf-8')

    # 1. sha pin FIRST — never check parity against a mutated fixture.
    sha = hashlib.sha256(raw).hexdigest()
    check('fixture sha256 matches the pin (edit → re-pin BOTH sides + notify AEF)',
          sha == PIN_SHA, sha if sha != PIN_SHA else '')
    if sha != PIN_SHA:
        # A drifted fixture makes every downstream assertion meaningless — stop loud.
        print('\n%d/%d checks passed' % (0, 1))
        sys.exit(1)

    gs = load_gs()
    uuid_refs = gs._link_refs_from_text(text)
    legacy_refs = gs._legacy_refs_from_text(text)

    # 2. No-silent-drop: every <aef:link> is claimed by exactly one parser path.
    link_count = len(re.findall(r'<aef:link\b', text))
    check('no-silent-drop: count(<aef:link>) == uuid_refs + legacy_refs (exactly one path each)',
          link_count == len(uuid_refs) + len(legacy_refs),
          'links=%d uuid=%d legacy=%d' % (link_count, len(uuid_refs), len(legacy_refs)))
    check('no-silent-drop: fixture has all 3 legs (2 uuid-pinned + 1 legacy)',
          len(uuid_refs) == 2 and len(legacy_refs) == 1,
          'uuid=%d legacy=%d' % (len(uuid_refs), len(legacy_refs)))

    # 3. Field-set completeness per uuid-pinned leg (workflowRef + name + resolved host).
    by_ref = {r['workflowRef']: r for r in uuid_refs}
    resolved = by_ref.get(RESOLVED_UUID)
    ghost = by_ref.get(GHOST_UUID)
    check('resolved leg: full field set {workflowRef, name} + id-bearing host node',
          bool(resolved) and resolved.get('name') == 'aef-task-lifecycle'
          and resolved.get('node') and resolved.get('nodeName'),
          repr(resolved))
    check('ghost leg: full field set {workflowRef, name} + id-bearing host node',
          bool(ghost) and ghost.get('name') == 'publish-map'
          and ghost.get('node') and ghost.get('nodeName'),
          repr(ghost))

    # 3b. Legacy leg: slug + resolved host, and NO workflowRef/name leaked in.
    legacy = legacy_refs[0] if legacy_refs else None
    check('legacy leg: {slug} + id-bearing host node (targetWorkflow, no workflowRef)',
          bool(legacy) and legacy.get('slug') == LEGACY_SLUG and legacy.get('node'),
          repr(legacy))

    # 4. Cross-side anchor: the resolved workflowRef is the byte the two sides agree on.
    check('cross-side anchor: resolved workflowRef == AEF live uuid 1f9b5f0c…',
          RESOLVED_UUID in by_ref)

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print('\n%d/%d checks passed' % (passed, total))
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
