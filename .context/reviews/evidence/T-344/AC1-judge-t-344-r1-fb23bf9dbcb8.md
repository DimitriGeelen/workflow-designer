# T-344 Human AC#1 — watch scope and the registration debt it makes visible

Reviewer dispatch: judge-t-344-r1-fb23bf9dbcb8 · revision 3d6f2deb65d4071756ed1dc4ee1c918abaf307c3 (HEAD at review; `.fabric/watch-patterns.yaml` has no diff against it)

## Step 1 — expansion
`python3 .agentic-framework/agents/fabric/lib/expand_patterns.py .fabric/watch-patterns.yaml /opt/832-Workflow-designer | wc -l` → **603**. Non-empty. (The old default expanded to 0.)

## Step 2 — audit structure section
`fw audit --section structure 2>&1 | grep -i fabric` (current-run lines):
- `[PASS] Fabric: 522 registered card(s)`
- `[WARN] Fabric: 522 registered, 102 unregistered (of 603 watched — 86% covered, cards flat since earlier today (522))`
- `[WARN] Fabric: 21 card(s) point at files no watch pattern covers`
- `[WARN] Fabric: 186/523 cards have no edges`, `[WARN] Fabric: 192 under-populated card(s)` (card quality, not scope)
`fw audit --check fabric-coverage` reports the same 603 / 102.
The audit's own denominator (603) matches expand_patterns.py (603).

## Judgement
- The scope is precise: 8 include globs (src html, tools/tests/scripts code), with documented reasons for each exclusion (vendored framework, dist, vendor, docs/examples, editor snapshots, fixtures-as-data). It does not depend on `exclude:`, which audit.sh ignores, so drift and audit report the same number.
- The standing debt is **102 unregistered of 603 (86% covered)**. The figure is honest and stated next to a non-zero denominator. The debt has been shrinking, from the ~146-147 cited at authoring to 100 and now 102 as the tree grows. A WARN of this size is reversible and is not risk. Carrying it while cards are written is reasonable. Narrowing (dropping `_t###` probes) would hide the dependents that blast-radius queries need, and the file explains that trade-off.
- The verdict is **green**: both expected conditions hold.

## Observations (not blocking this AC)
1. `tools/_t344-watch-set-denominator.sh` is described in the patterns file as "the fix for the class". It now gives **3 passed, 7 failed** (exit code 0). It can no longer extract the 'Fabric:' / 'Fabric drift:' verdict branches from audit.sh ("it moved; re-anchor"), so it cannot verify that an empty denominator goes red. Its non-empty and agreement checks still PASS. The guard needs re-anchoring under a follow-up task.
2. 21 existing cards point at files outside the watch set (e.g. the fixture cards the file calls out). This is accepted by design ("a card may exist for anything").
3. Running step 2 as prescribed wrote `.context/audits/2026-10-19.yaml` (untracked). This is a side effect of the audit command. I did not edit or commit it.
