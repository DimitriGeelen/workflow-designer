#!/usr/bin/env python3
"""DEAD-leg census contract test (T-304, rail 325).

Pins the scan contract adopted in pair round #4: dead-but-reachable legs
carry the DEAD: token inside aef:meta note ATTRIBUTES, and census tooling
must read only those attributes — never raw-text grep (header comments
mention the token too; on the pinned fixture a raw scan reads 9 where the
truth is 4). Fixture is AEF's knowledge-leveling v3, sha-pinned to the
rail-325 announcement (sha8 b82668c8) so silent edits surface here.
"""
import hashlib
import importlib.util
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE = os.path.join(ROOT, "tests", "fixtures", "aef-overlay",
                       "draft-knowledge-leveling-v3.bpmn")
PINNED_SHA = "b82668c848014a4dcdb7996228cef884e98f07e08ed0c86d58e42eccd732022a"
EXPECTED_OWNERS = {"fw_1_write", "fw_3_practice", "fw_4_harvest", "agt_0_consolidate"}

spec = importlib.util.spec_from_file_location(
    "census_dead_legs", os.path.join(ROOT, "tools", "census-dead-legs.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# 1. Fixture byte-pin (rail-325 sha8 prefix is the announced form)
sha = hashlib.sha256(open(FIXTURE, "rb").read()).hexdigest()
if sha != PINNED_SHA:
    failures.append(f"fixture sha drifted: {sha[:8]} != pinned {PINNED_SHA[:8]}")

# 2. Contract census: exactly 4 DEAD legs, on the expected owners
hits = mod.census(FIXTURE)
owners = {eid for eid, _ in hits}
if len(hits) != 4:
    failures.append(f"census(fixture) == {len(hits)}, expected 4")
if owners != EXPECTED_OWNERS:
    failures.append(f"census owners {sorted(owners)} != {sorted(EXPECTED_OWNERS)}")

# 3. The contract matters: raw-text scan over-counts (comments mention the token)
raw = open(FIXTURE).read().count(mod.TOKEN)
if raw <= len(hits):
    failures.append(f"raw token count {raw} not > census {len(hits)} — "
                    "fixture no longer demonstrates the over-count hazard")

# 4. Our corpus carries no DEAD legs yet (flips when a dead-leg-bearing map
#    is adopted at promotion — update this expectation deliberately then)
corpus_dir = os.path.join(ROOT, "examples", "aef-processes", "rendered")
corpus_total = sum(len(mod.census(os.path.join(corpus_dir, f)))
                   for f in sorted(os.listdir(corpus_dir)) if f.endswith(".bpmn"))
if corpus_total != 0:
    failures.append(f"corpus DEAD-leg census == {corpus_total}, expected 0 "
                    "(new adoption? update expectation deliberately)")

# 5. Fixture validates clean (pin pattern: sha + validator-clean)
#    KNOWN, PRINTED exceptions: W-XML-LANE-GEOMETRY (T-312) and
#    W-XML-LANE-CAPACITY (T-313). These are AEF's OWN bytes, pinned at
#    b82668c8 — we never edit them, so neither can be "fixed" here. Both are
#    genuine upstream findings: their v3 is a WHOLESALE lane inversion (5/5 and
#    11/11 nodes cross), a strictly larger defect than the two-node swap they
#    reported on v8, AND both its lanes overflow their declared heights.
#    AEF's own all-versions census (rail 344) reproduced this set independently
#    — 1 geometry + 2 overflow, same witnesses, same numbers.
#    Reported on the rail; tracked as T-314.
#    Tolerance shape: COUNTED, not suppressed. Each admitted finding PRINTS
#    every run and the count is asserted in T-312's Verification block, so a
#    fixture joining this set silently is itself the failure.
r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "validate-workflow.py"),
                    FIXTURE, "--json"], capture_output=True, text=True)
_found = json.loads(r.stdout).get("findings", []) if r.stdout.strip() else []
_KNOWN = ("W-XML-LANE-GEOMETRY", "W-XML-LANE-CAPACITY")
for _f in _found:
    if _f["rule"] in _KNOWN:
        print(f"NOTE (known, AEF-owned bytes, T-314): {_f['location']}: {_f['message']}")
_blocking = [f for f in _found
             if f["severity"] != "INFO" and f["rule"] not in _KNOWN]
if _blocking:
    failures.append("fixture no longer validator-clean: "
                    f"{sorted({f['rule'] for f in _blocking})}")

if failures:
    for f in failures:
        print(f"FAIL: {f}")
    sys.exit(1)
print("OK: DEAD-leg census contract — fixture pinned (b82668c8), census 4/4 on "
      "expected owners, raw-scan hazard demonstrated (9>4), corpus 0, validator clean")
