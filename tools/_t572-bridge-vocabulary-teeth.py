#!/usr/bin/env python3
"""_t572-bridge-vocabulary-teeth.py — does the T-572 round-trip guard actually discriminate?

The guard this replaces (tests/test_editor_bridge_meta_parity.py, ⊆ direction) was GREEN for
the entire period in which the editor destroyed nine keys the bridge emits. So "the new guard
is green on the fixed source" is worth nothing on its own — that is exactly what the old guard
reported too. Each mutant below is a state the codebase could actually be in, and each must
redden EXACTLY its own legs and lose EXACTLY its own keys. More than that is not
discrimination, and is reported as a failure rather than accepted.

  A — T-570's carriage removed; export reverts to the metaKeys.filter one-liner.
      THIS IS THE CONDITION THE OLD GUARD COULD NOT SEE. It is the whole reason this task
      exists, and if the new guard does not redden here it has not replaced anything.
      Reddens the two round-trip legs plus `hostile-value` (the hostile value rides
      `determinism`, one of the nine casualties). `reproduce-drop` MUST stay green: it asserts
      the pre-fix rule LOSES those keys, which is what mutant A restores.

  B — the SAMPLE repaired instead of the mechanism, plus a key nobody wrote down.
      metaKeys is widened by all nine known bridge-only keys AND carriage is removed — the
      patch that makes every key today's corpus and today's whitelists know about survive.
      Then the bridge gains "zzUnseenKey", which appears NOWHERE in the probe. The guard must
      redden on that one key alone. That is only possible because the fixture is DERIVED from
      META_KEYS at run time; a hand-written fixture pins the 29 it was written with and reports
      green here. `hostile-value` stays GREEN (determinism is whitelisted under B), and that
      asymmetry with A is what separates repairing the sample from repairing the mechanism.

  C — one bridge key added to the export skip set without an emitter to claim it.
      `advisory` is listed as handled-elsewhere while nothing emits it, so it is silently
      dropped. Reddens the same two legs as B but must lose a DIFFERENT key — the leg set
      alone cannot tell B and C apart, so the lost-key set is asserted, not just the verdicts.

A CONTROL RUN ON UNMUTATED SOURCE COMES FIRST. "every mutant died" is equally satisfied by a
harness that fails on everything (T-560), and this probe drives a real browser, so an
environment fault is a live possibility rather than a theoretical one.

Mutants live in a tmpdir copy — of the editor AND of the bridge (B mutates the producer's
vocabulary). Nothing here writes to the tree.
Exit 0 = control green and each mutant kills exactly its own legs with exactly its own keys.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
BRIDGE = os.path.join(ROOT, "tools", "yaml-to-bpmn.py")
PROBE = os.path.join(ROOT, "tools", "_t572-bridge-vocabulary-roundtrip-cdp.mjs")
LEGS = ("vocabulary-derived", "reproduce-drop", "roundtrip-every-key",
        "roundtrip-every-type", "hostile-value", "no-silent-exemptions")

NEW_METAATTRS = ("  const metaAttrs = [...metaKeys.filter(k => aefKeys.includes(k)), ...carriedKeys]\n"
                 "    .map(k => `${k}=\"${escAttr(aef[k])}\"`).join(' ');")
OLD_METAATTRS = ("  const metaAttrs = metaKeys.filter(k => aefKeys.includes(k))"
                 ".map(k => `${k}=\"${escAttr(aef[k])}\"`).join(' ');")
METAKEYS_TAIL = "    'horizon', 'workflowType', 'owner'];"
# the nine keys the bridge emits that the editor's pre-T-570 whitelist never named
NINE = ("'determinism', 'authority', 'endpoint', 'sideEffect', 'autoTriggerKind', "
        "'restoresFrom', 'compensationSnapshot', 'compensatedBy', 'advisory'")
SKIP_LINE = "    'endpoint', 'contextReads', 'artifactsWrites', 'decisionInput', 'decisionOutputs',"
BRIDGE_TAIL = '             "horizon", "workflowType", "owner")'


def run_probe(src_path, bridge_path):
    r = subprocess.run(["node", PROBE, "--src", src_path, "--bridge", bridge_path],
                       capture_output=True, text=True, timeout=900, cwd=ROOT)
    return r.returncode, r.stdout + r.stderr


def verdicts(out):
    v = {}
    for line in out.splitlines():
        m = re.match(r"^(PASS|FAIL)\s+(\S+)\s+—", line)
        if m:
            v[m.group(2)] = m.group(1)
    return {leg: v.get(leg, "MISSING") for leg in LEGS}


def reddened(v):
    return sorted([k for k, s in v.items() if s != "PASS"])


def lost_keys(out):
    """The keys `roundtrip-every-key` reports as destroyed. Distinguishing B from C needs the
    key set, not the leg set — both mutants break the same two legs."""
    m = re.search(r"^FAIL\s+roundtrip-every-key\s+—.*?LOST (\[[^\]]*\])", out, re.M)
    return sorted(json.loads(m.group(1))) if m else []


def patch(path, old, new, label):
    s = open(path, encoding="utf-8").read()
    n = s.count(old)
    if n != 1:
        raise SystemExit("mutant %s: anchor occurs %d times, need exactly 1:\n  %r" % (label, n, old[:90]))
    open(path, "w", encoding="utf-8").write(s.replace(old, new))


def main():
    npass = nfail = 0

    def report(ok, name, detail):
        nonlocal npass, nfail
        if ok:
            npass += 1
        else:
            nfail += 1
        print("%s  %s — %s" % ("PASS" if ok else "FAIL", name, detail))

    for p in (SRC, BRIDGE, PROBE):
        if not os.path.exists(p):
            print("CANNOT RUN: missing %s" % p)
            return 2

    scratch = tempfile.mkdtemp(prefix="t572-teeth-")
    try:
        rc, out = run_probe(SRC, BRIDGE)
        ctl = verdicts(out)
        if rc != 0 or reddened(ctl):
            report(False, "control: unmutated source passes all six legs",
                   "rc=%d failing=%s" % (rc, reddened(ctl) or "none"))
            print("\n%d passed, %d failed" % (npass, nfail))
            return 1
        report(True, "control: unmutated source passes all six legs", ", ".join(LEGS))

        # ── A: carriage removed — the exact state the OLD guard reported as green ───────────
        a = os.path.join(scratch, "A.html")
        shutil.copyfile(SRC, a)
        patch(a, NEW_METAATTRS, OLD_METAATTRS, "A")
        _, out_a = run_probe(a, BRIDGE)
        red, lost = reddened(verdicts(out_a)), lost_keys(out_a)
        want = ["hostile-value", "roundtrip-every-key", "roundtrip-every-type"]
        # EIGHT, not nine. `endpoint` is one of the nine keys outside the pre-T-570 whitelist but
        # it has its own element emitter (<aef:endpoint>), so removing carriage does not destroy
        # it — it merely stops riding <aef:meta>. This expectation was written as nine and the
        # teeth caught it: exactly the error T-570's own census made (4 keys "lost" by whitelist
        # diff, 3 actually destroyed by round trip), re-made one task later in the tooth built to
        # guard against it. A whitelist difference is not a round trip, at any level of the stack.
        want_lost = sorted(["determinism", "authority", "sideEffect", "autoTriggerKind",
                            "restoresFrom", "compensationSnapshot", "compensatedBy", "advisory"])
        report(red == want and lost == want_lost,
               "mutant A killed (carriage removed — what the OLD guard called green)",
               "reddened %s (want %s); lost %d keys (want %d — the nine minus `endpoint`, which "
               "survives on its own element)%s" % (red, want, len(lost), len(want_lost),
                                                   "" if lost == want_lost else "; GOT %s" % lost))

        # ── B: sample repaired, mechanism not, plus a key the probe has never heard of ──────
        b_src = os.path.join(scratch, "B.html")
        b_br = os.path.join(scratch, "B-bridge.py")
        shutil.copyfile(SRC, b_src)
        shutil.copyfile(BRIDGE, b_br)
        patch(b_src, METAKEYS_TAIL, "    'horizon', 'workflowType', 'owner', %s];" % NINE, "B")
        patch(b_src, NEW_METAATTRS, OLD_METAATTRS, "B2")
        # APPENDED, not prepended. Prepending makes "zzUnseenKey" the bridge's first key, and
        # the probe's hostile value rides the first CARRIED key — so a front-inserted mutant
        # moves the hostile value onto the very key it destroys and reddens leg 5 for a reason
        # that has nothing to do with what B is testing. Appending is also what someone adding a
        # key to a tuple actually does.
        patch(b_br, BRIDGE_TAIL, BRIDGE_TAIL.replace('"owner")', '"owner", "zzUnseenKey")'), "B3")
        _, out_b = run_probe(b_src, b_br)
        red, lost = reddened(verdicts(out_b)), lost_keys(out_b)
        want = ["roundtrip-every-key", "roundtrip-every-type"]
        report(red == want and lost == ["zzUnseenKey"],
               "mutant B killed (nine known keys whitelisted; a 30th the probe never names)",
               "reddened %s (want %s — hostile-value stays GREEN); lost %s (want ['zzUnseenKey'] "
               "— only a DERIVED fixture can see it)" % (red, want, lost))

        # ── C: a bridge key declared handled-elsewhere with nothing to handle it ────────────
        c = os.path.join(scratch, "C.html")
        shutil.copyfile(SRC, c)
        patch(c, SKIP_LINE, SKIP_LINE.replace("    'endpoint',", "    'endpoint', 'advisory',"), "C")
        _, out_c = run_probe(c, BRIDGE)
        red, lost = reddened(verdicts(out_c)), lost_keys(out_c)
        want = ["roundtrip-every-key", "roundtrip-every-type"]
        report(red == want and lost == ["advisory"],
               "mutant C killed (a key skipped by an emitter that does not exist)",
               "reddened %s (want %s — same legs as B, DIFFERENT key); lost %s (want ['advisory'])"
               % (red, want, lost))

        print("\n%d passed, %d failed" % (npass, nfail))
        if nfail == 0:
            print("%d/%d teeth legs passed" % (npass, npass))
        return 0 if nfail == 0 else 1
    finally:
        shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
