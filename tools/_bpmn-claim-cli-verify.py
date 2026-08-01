#!/usr/bin/env python3
"""_bpmn-claim-cli-verify.py — T-230 / S4b end-to-end guard for `fw bpmn claim`.

Exercises tools/bpmn-cli.py against a fully ISOLATED temp repo (never touches the
live .context/designer/registry.yaml or the :8834 gallery store): seed a pending
ghost + its referrer the way the server does (sync_registry_after_save), run the
CLI, and assert the claim outcome is byte-identical in shape to S4a's editor claim
apart from via:"cli":

  * ghost dropped from registry.ghosts; claims[] records {uuid,project,via:"cli"}
  * target map's stored BPMN carries <aef:workflowMeta ... uuid=<uuid>> (new version)
  * the referrer resolves — merged_ghosts()/build_map_list() no longer surface the uuid
  * idempotent re-claim: no duplicate claim, no new version, ghost stays gone
  * guardrails: unknown uuid and unknown project both fail loud with NO mutation

Dependency-free (stdlib only). Exit 0 = all pass; exit 1 = any fail (P-011 reads this).
"""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
CLI = os.path.join(HERE, 'bpmn-cli.py')

U = '1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7'      # the ghost we claim
U_OTHER = 'adb0e0f2-f2ff-40a2-a898-22f369adee2f'  # a second ghost, for the unknown-project guard

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond), detail))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def load_gs(repo):
    spec = importlib.util.spec_from_file_location('gallery_serve', os.path.join(HERE, 'gallery-serve.py'))
    gs = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gs)
    gs.REPO = os.path.abspath(repo)
    gs.DOCROOT = os.path.join(gs.REPO, 'build', 'gallery')
    return gs


def bpmn(map_id, title, workflow_uuid=None, ref_uuid=None):
    """Minimal valid BPMN. workflow_uuid=None → workflowMeta with NO uuid attr (a
    claim target). ref_uuid set → an off-page <aef:link workflowRef=…> (a referrer)."""
    meta_uuid = (' uuid="%s"' % workflow_uuid) if workflow_uuid else ''
    link = ''
    if ref_uuid:
        # T-327: <bpmn:task> is legal BPMN but NEITHER emitter produces a bare
        # `task` — they emit serviceTask/userTask/scriptTask, and an <aef:link>
        # host specifically as intermediateThrowEvent. Milder than the
        # linkEventThrow class (that tag is not BPMN at all) but the same defect:
        # asserting the ref-scan against a document shape we cannot emit.
        link = ('    <bpmn:intermediateThrowEvent id="node1" name="node one">\n'
                '      <bpmn:extensionElements>\n'
                '        <aef:link workflowRef="%s" name="ghost-name"/>\n'
                '      </bpmn:extensionElements>\n'
                '    </bpmn:intermediateThrowEvent>\n' % ref_uuid)
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"\n'
        '  xmlns:aef="http://anchorpoint.framework/aef/extensions"\n'
        '  id="Definitions_%s" targetNamespace="urn:t">\n'
        '  <aef:workflowMeta id="%s"%s version="1" schemaVersion="2" title="%s" tier_default="2"/>\n'
        '  <bpmn:process id="Process_%s" name="%s">\n'
        '%s'
        '  </bpmn:process>\n'
        '</bpmn:definitions>\n' % (map_id, map_id, meta_uuid, title, map_id, title, link))


def write_rendered(repo, map_id, text):
    d = os.path.join(repo, 'examples', 'aef-processes', 'rendered')
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, '%s.bpmn' % map_id), 'w', encoding='utf-8') as f:
        f.write(text)


def read_registry(repo):
    p = os.path.join(repo, '.context', 'designer', 'registry.yaml')
    with open(p, encoding='utf-8') as f:
        return json.load(f)


def run_cli(repo, *cli_args):
    r = subprocess.run([sys.executable, CLI, '--repo', repo, *cli_args],
                       capture_output=True, text=True, timeout=30)
    return r.returncode, r.stdout + r.stderr


def latest_version_text(gs, map_id):
    lv = gs._latest_version(map_id)
    return gs._read_text(gs._authoritative_bpmn_path(map_id, lv))


def main():
    repo = tempfile.mkdtemp(prefix='t230-bpmn-')
    gs = load_gs(repo)

    # ── seed: target map (uuid-less, a claim target) + referrer map (off-page ref to U) ──
    write_rendered(repo, 'target-map', bpmn('target-map', 'Target'))
    write_rendered(repo, 'ref-map', bpmn('ref-map', 'Referrer', ref_uuid=U))
    os.makedirs(os.path.join(repo, '.context', 'designer'), exist_ok=True)
    # populate the ghost registry exactly as the server would on save of ref-map
    gs.sync_registry_after_save('ref-map', bpmn('ref-map', 'Referrer', ref_uuid=U))

    reg0 = read_registry(repo)
    seeded = next((g for g in reg0['ghosts'] if g['uuid'] == U), None)
    check('seed: ghost U present with ref-map referrer', bool(seeded)
          and any(r['id'] == 'ref-map' for r in (seeded or {}).get('referenced_by', [])),
          'ghosts=%d' % len(reg0['ghosts']))
    check('seed: U is a ghost in the live derivation (unresolved)',
          any(g['uuid'] == U for g in gs.merged_ghosts()))

    # ── the claim ──
    rc, out = run_cli(repo, 'claim', U, 'target-map')
    check('claim: exits 0', rc == 0, 'rc=%d out=%r' % (rc, out[-160:]))

    reg1 = read_registry(repo)
    check('claim: ghost U dropped from registry.ghosts',
          not any(g['uuid'] == U for g in reg1['ghosts']))
    cl = [c for c in reg1['claims'] if c['uuid'] == U]
    check('claim: claims[] records exactly one {uuid,project,via:cli}',
          len(cl) == 1 and cl[0].get('project') == 'target-map' and cl[0].get('via') == 'cli',
          'claims=%r' % cl)

    tgt_text = latest_version_text(gs, 'target-map')
    check('claim: target map stored BPMN now carries workflowMeta uuid=U',
          gs._uuid_from_text(tgt_text) == U, 'uuid=%r' % gs._uuid_from_text(tgt_text))
    check('claim: target map is a live map carrying U (referrer resolves)',
          any(m['id'] == 'target-map' and m.get('uuid') == U for m in gs.build_map_list()[0]))
    check('claim: U no longer surfaces as a ghost (referrer resolved)',
          not any(g['uuid'] == U for g in gs.merged_ghosts()))

    # ── idempotent re-claim ──
    ver_before = gs._latest_version('target-map')['v']
    rc2, out2 = run_cli(repo, 'claim', U, 'target-map')
    reg2 = read_registry(repo)
    check('idempotent: re-claim exits 0', rc2 == 0, 'rc=%d out=%r' % (rc2, out2[-120:]))
    check('idempotent: still exactly one claims[] entry (no duplicate)',
          len([c for c in reg2['claims'] if c['uuid'] == U]) == 1)
    check('idempotent: no new version written',
          gs._latest_version('target-map')['v'] == ver_before,
          'v_before=%d v_after=%d' % (ver_before, gs._latest_version('target-map')['v']))

    # ── guardrail: unknown uuid → fail loud, NO mutation ──
    reg_before = json.dumps(read_registry(repo), sort_keys=True)
    rc3, out3 = run_cli(repo, 'claim', 'deadbeef-0000-0000-0000-000000000000', 'target-map')
    check('guardrail: unknown uuid exits non-zero', rc3 != 0, 'rc=%d' % rc3)
    check('guardrail: unknown uuid left registry unchanged',
          json.dumps(read_registry(repo), sort_keys=True) == reg_before)

    # ── guardrail: unknown project (with a genuinely pending ghost) → fail loud, NO mutation ──
    gs.sync_registry_after_save('ref-map-2', bpmn('ref-map-2', 'Referrer2', ref_uuid=U_OTHER))
    write_rendered(repo, 'ref-map-2', bpmn('ref-map-2', 'Referrer2', ref_uuid=U_OTHER))
    reg_before2 = json.dumps(read_registry(repo), sort_keys=True)
    rc4, out4 = run_cli(repo, 'claim', U_OTHER, 'no-such-project')
    check('guardrail: unknown project exits non-zero', rc4 != 0, 'rc=%d' % rc4)
    check('guardrail: unknown project left registry unchanged (ghost still pending)',
          json.dumps(read_registry(repo), sort_keys=True) == reg_before2
          and any(g['uuid'] == U_OTHER for g in read_registry(repo)['ghosts']))

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print('\n%d/%d checks passed' % (passed, total))
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
