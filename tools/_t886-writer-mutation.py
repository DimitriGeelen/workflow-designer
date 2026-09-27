#!/usr/bin/env python3
"""_t886-writer-mutation — prove the document-level round-trip guard has TEETH.

T-886 added a derived denominator + WMSPEC projection + document-level self-test to
tools/_roundtrip-serialization-cdp.mjs. That makes a COVERAGE CLAIM. This turns the claim into
evidence the only way available: suppress each attribute in the editor's writer, re-run the
guard, and record whether it goes red.

This is T-885's method, and T-885 is why it is not optional — it predicted tier_default BARE and
uuid COVERED and both were backwards. Reading a projection is not a substitute for mutating it.

Two mutation SHAPES, because they exercise two different legs and a guard that catches only one
is half a guard:

  runtime-suppress   `if (wm.X)` -> `if (false && wm.X)`   the attribute stays in the source text
                     (so it stays in the derived denominator) but is never emitted at runtime.
                     Caught by the round-trip comparison: exit 1.
  writer-delete      the emitting line is removed entirely. The attribute leaves the derived
                     denominator while staying in WMSPEC. Caught by checkWmDenominator as dead
                     coverage: exit 2.

Every mutation is asserted to have APPLIED before its run — a substitution that silently matched
nothing reads identically to a guard that passed, and that failure mode has occurred twice in
this corpus. The source is restored from a byte backup and the restore is verified with a
comparison, not assumed.

Run: python3 tools/_t886-writer-mutation.py
Exit 0 = every mutation was killed (the guard has teeth). Exit 1 = a mutant SURVIVED, which
means the attribute it suppressed is still unguarded.
"""
import filecmp
import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
HARNESS = os.path.join(ROOT, "tools", "_roundtrip-serialization-cdp.mjs")

# (label, shape, needle, replacement)
# The needles are copied from src/aef-workflow-designer.html:10431-10450. If one stops matching,
# that is a real finding about the emitter and is reported as MUTATION-DID-NOT-APPLY, never
# silently skipped.
MUTATIONS = [
    (
        "uuid",
        "runtime-suppress",
        "  if (wm.uuid) wmAttrs.splice(1, 0, ",
        "  if (false && wm.uuid) wmAttrs.splice(1, 0, ",
    ),
    (
        "description",
        "runtime-suppress",
        "  if (wm.description) wmAttrs.push(",
        "  if (false && wm.description) wmAttrs.push(",
    ),
    (
        "kind",
        "runtime-suppress",
        "  if (wm.kind) wmAttrs.push(",
        "  if (false && wm.kind) wmAttrs.push(",
    ),
    (
        "tier_default",
        "runtime-suppress",
        "  if (wm.tier_default) wmAttrs.push(",
        "  if (false && wm.tier_default) wmAttrs.push(",
    ),
    (
        "schemaVersion",
        "writer-delete",
        '    `schemaVersion="${escAttr(wm.schemaVersion || 2)}"`,\n',
        "",
    ),
]


def run_harness():
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=600
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    reason = None
    try:
        d = json.loads(proc.stdout)
        for k in ("error",):
            if d.get(k):
                reason = d[k][:110]
        if reason is None and d.get("pass") is False:
            bad = [f for f in d.get("fixtures", []) if f.get("ok") is not True]
            if bad:
                reason = "fixture drift: %s (%s)" % (
                    bad[0].get("fixture"),
                    str(bad[0].get("reason") or bad[0].get("diff"))[:70],
                )
    except Exception:
        reason = out.strip().splitlines()[-1][:110] if out.strip() else "no output"
    return proc.returncode, reason


def main():
    backup = os.path.join(tempfile.mkdtemp(prefix="t886-"), "designer.html")
    shutil.copyfile(SRC, backup)
    original = open(SRC, encoding="utf-8").read()
    rows = []
    survivors = []

    for label, shape, needle, repl in MUTATIONS:
        if needle not in original:
            rows.append((label, shape, "MUTATION-DID-NOT-APPLY", "-", "needle absent from emitter"))
            survivors.append(label)
            continue
        assert original.count(needle) == 1, (
            "needle for %s matches %d sites — an ambiguous mutation proves nothing about which "
            "one it hit" % (label, original.count(needle))
        )
        mutated = original.replace(needle, repl)
        assert mutated != original, "substitution for %s was a no-op" % label
        with open(SRC, "w", encoding="utf-8") as fh:
            fh.write(mutated)
        # Prove the mutation is on disk and is what we meant, before spending a run on it.
        on_disk = open(SRC, encoding="utf-8").read()
        assert needle not in on_disk, "mutation for %s did not reach disk" % label
        try:
            code, reason = run_harness()
        finally:
            shutil.copyfile(backup, SRC)
            assert filecmp.cmp(backup, SRC, shallow=False), (
                "RESTORE FAILED for %s — source tree is NOT byte-identical" % label
            )
        killed = code != 0
        if not killed:
            survivors.append(label)
        rows.append((label, shape, "KILLED" if killed else "SURVIVED", str(code), reason or "-"))

    # Final byte-identity check against the pristine backup, after every mutation.
    assert filecmp.cmp(backup, SRC, shallow=False), "source tree not byte-identical at end"
    if open(SRC, encoding="utf-8").read() != original:
        sys.exit("content drift at end: the restored file differs from the text read at start")

    w = max(len(r[0]) for r in rows) + 2
    print("T-886 writer-mutation results — does the guard go red when the attribute is dropped?")
    print()
    print("%-*s %-18s %-10s %-6s %s" % (w, "attribute", "shape", "verdict", "exit", "why it went red"))
    print("-" * 118)
    for label, shape, verdict, code, reason in rows:
        print("%-*s %-18s %-10s %-6s %s" % (w, label, shape, verdict, code, reason))
    print()
    print("source tree byte-identical to pre-mutation state: VERIFIED (filecmp, not assumed)")
    if survivors:
        print()
        print("MUTANT(S) SURVIVED: %s — these attributes are still unguarded." % ", ".join(survivors))
        return 1
    print("every mutant killed: the document-level seam has teeth for %d attribute(s)" % len(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main())
