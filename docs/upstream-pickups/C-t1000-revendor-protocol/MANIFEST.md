# Bundle C: re-vendor protocol tooling (832 T-1000/T-1005 → AEF T-3737)

**Verified against:** AEF `bleeding-edge` 914326e0 (2026-10-03, via the GitHub mirror), on 2026-10-04.
**Apply:** `git am docs/upstream-pickups/C-t1000-revendor-protocol/*.patch` (1 commit, adds files only, under `contrib/832-revendor-protocol/`; independent of A, B and D).
**Probe:** `bash contrib/832-revendor-protocol/tests/test_t1000_revendor_gate.sh` → 12/12. It builds a scratch consumer repo and walks gates G1, G2 and G4, each refusal leg paired with an allow leg.

## Contents

| File | Role |
|---|---|
| `README.md` | The protocol (pristine commit, baseline advance, worklist, done when clean), the gates, and one measured cycle on 1.7.740. |
| `tools/_t1000-revendor-gate.sh` | Pre-commit gate. **G1:** an upgrade commit contains only vendored paths. **G2:** nothing else is committed until the baseline advances. **G4:** a vendored path that changes must be declared. |
| `tools/_t1000-install-hook.sh` | Idempotent installer into `.git/hooks/pre-commit`. It exists because the framework hook has no project extension point (your T-3737 ask). |
| `tools/_t1000-revendor-worklist.py` | Lists each STALE declared fix with the patch that restores it. |
| `tools/_t517-vendor-divergence.py` | The divergence checker: diverged vs declared, unrecorded vs STALE. Its schema is the one you discussed in T-3752. |
| `tests/test_t1000_revendor_gate.sh` | The gate test above. |

**This is reference input, not drop-in code, as you asked.** It assumes a vendoring project (`.agentic-framework/`, `.vendor-divergence.yaml` there). Running the gate against your own repo would refuse everything.

## What the cycle taught (also in the README)

- The protocol made losses **visible**: unrecorded went from 1599 to 0, with 51 STALE named.
- It cannot see a local fix that was never declared. On 2026-10-04 832 found one, T-931's delegate owner flip, erased silently; it is in bundle A. G4 closes this going forward, and a one-off census (832 T-1020) handles the backlog.
- That is why your T-3737 ask stands: before overwriting, `fw upgrade` should list every vendored path whose content differs from the baseline, declared or not.

## The T-3746 fixture

The security fix AEF filed as T-3746 is in **bundle D** (`docs/upstream-pickups/D-t3746-allowlisted-writes/`), not here.
