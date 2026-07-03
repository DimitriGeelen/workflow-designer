#!/usr/bin/env python3
"""test_bridge_aef_passthrough — pin the aef.x-* extension channel and the
loud-drop contract on the YAML->BPMN bridge (T-061, closes FC-13).

FC-13 (verified in T-058): the bridge emitted only a hardcoded set of aef.* keys
and silently dropped every other one, so the aef: namespace the editor advertises
as "free-form passthrough" was a closed, silent whitelist. Root of the T-059 /
T-060 coverage bugs.

The T-061 contract this test enforces:
  1. PASSTHROUGH — a scalar `aef.x-<name>` key survives the bridge as an
     `<aef:meta ... x-<name>="value">` attribute (explicit, opt-in extension).
  2. NO SILENT DROP — a bare unknown `aef.<name>` key (no x- prefix) is dropped
     but LOUDLY: a WARN naming the node + key is written to stderr, and the key
     is absent from the BPMN output. (Non-fatal: exit code stays 0.)
  3. KNOWN keys are unaffected (regression guard for the existing vocabulary).

Invokes the bridge as a subprocess (its filename is hyphenated, not importable),
mirroring how run-bridge-tests.sh drives it. Pure stdlib.
Exit 0 = contract holds. Exit 1 = a contract violation. Exit 2 = harness error.
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRIDGE = os.path.join(ROOT, "tools", "yaml-to-bpmn.py")

# Minimal valid workflow with one node carrying: a known key (determinism), an
# explicit extension key (x-enforcement), and a bare unknown key (enforcement).
YAML_TMPL = """\
workflowMeta: {id: t061, version: 1, schemaVersion: 2}
pool: {id: P, name: t061}
lanes:
  - {id: L, name: L, abbr: l, authority: none, height: 120}
nodes:
  - uid: n1
    type: startEvent
    name: n1
    slug: n1
    lane: L
    x: 100
    y: 80
    aef:
      determinism: deterministic
      x-enforcement: DOCTRINE
      enforcement: BARE-UNKNOWN
edges: []
"""


def run_bridge(yaml_text):
    """Run the bridge on yaml_text; return (stdout, stderr, returncode)."""
    with tempfile.NamedTemporaryFile("w", suffix=".workflow.yaml", delete=False) as fh:
        fh.write(yaml_text)
        path = fh.name
    try:
        proc = subprocess.run([sys.executable, BRIDGE, path],
                              capture_output=True, text=True)
        return proc.stdout, proc.stderr, proc.returncode
    finally:
        os.unlink(path)


def check():
    """Return list of failure strings (empty = contract holds)."""
    fails = []
    out, err, rc = run_bridge(YAML_TMPL)

    if rc != 0:
        fails.append("bridge exited %d (expected 0; unknown keys must be non-fatal)\n%s" % (rc, err))
        return fails  # nothing else meaningful to assert

    # 1. PASSTHROUGH: x-enforcement survives as an attribute.
    if 'x-enforcement="DOCTRINE"' not in out:
        fails.append("passthrough broken: aef.x-enforcement did NOT survive as an attribute")

    # 2a. NO SILENT DROP: bare unknown key emits a WARN naming node + key.
    if "unknown aef key 'enforcement'" not in err or "n1" not in err:
        fails.append("bare unknown key 'enforcement' did NOT produce a WARN naming node n1\nstderr was:\n%s" % err)
    # 2b. ... and the bare unknown value is absent from the output (dropped).
    if "BARE-UNKNOWN" in out:
        fails.append("bare unknown key 'enforcement' leaked into BPMN output (should be dropped)")
    # 2c. The x- key must NOT itself trigger a warn.
    if "unknown aef key 'x-enforcement'" in err:
        fails.append("aef.x-enforcement wrongly reported as unknown (extension keys must be exempt)")

    # 3. KNOWN key regression: determinism still emitted.
    if 'determinism="deterministic"' not in out:
        fails.append("regression: known key 'determinism' no longer emitted")

    return fails


def main():
    try:
        fails = check()
    except Exception as exc:  # harness failure, not a contract result
        sys.stderr.write("HARNESS ERROR: %s\n" % exc)
        return 2
    if fails:
        sys.stderr.write("aef PASSTHROUGH/LOUD-DROP CONTRACT VIOLATED (T-061/FC-13):\n")
        for f in fails:
            sys.stderr.write("  - %s\n" % f)
        return 1
    print("OK: aef.x-* passes through; bare unknown keys warn+drop (non-fatal); known keys intact")
    return 0


if __name__ == "__main__":
    sys.exit(main())
