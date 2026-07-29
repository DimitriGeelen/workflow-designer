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
r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "validate-workflow.py"),
                    FIXTURE], capture_output=True, text=True)
if r.returncode != 0:
    failures.append(f"fixture no longer validator-clean: {r.stdout.strip()[:200]}")

if failures:
    for f in failures:
        print(f"FAIL: {f}")
    sys.exit(1)
print("OK: DEAD-leg census contract — fixture pinned (b82668c8), census 4/4 on "
      "expected owners, raw-scan hazard demonstrated (9>4), corpus 0, validator clean")
