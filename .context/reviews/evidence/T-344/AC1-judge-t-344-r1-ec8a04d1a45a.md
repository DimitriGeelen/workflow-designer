# T-344 Human AC#1 — watch scope and registration debt — reviewer evidence

Revision reviewed: e7a97a855717a9a5f59a08a8c0114e0bb977bc3e (HEAD at review time). Date: 2026-10-19.

## Step 1 — expansion
`python3 .agentic-framework/agents/fabric/lib/expand_patterns.py .fabric/watch-patterns.yaml /opt/832-Workflow-designer | wc -l`
-> **603** (not empty). Breakdown by dir: tools 509, tests 70, scripts 17, tools/hooks 5, tools/lib 1, src 1.
447 of the 603 are `_`-prefixed one-shot task probes.

## Step 2 — audit
`fw audit --section structure 2>&1 | grep -i fabric` (the first run hit "Another audit is already running"; I retried after the lock cleared):
```
[PASS] Fabric: 522 registered card(s)
[WARN] Fabric: 185/522 cards have no edges
[WARN] Fabric: 522 registered, 102 unregistered (of 603 watched — 86% covered, cards flat since earlier today (522))
[WARN] Fabric: 21 card(s) point at files no watch pattern covers
[WARN] Fabric: 192 under-populated card(s)
```
I cross-checked this independently by joining the expansion against the `location:` field of every card
in .fabric/components/. The join gives exactly **102** unregistered files, so the audit and the
expander agree here (the yaml comment warns they can disagree when an `exclude:` key is present; there is none).
Of the 102: 66 are `_` probes and 36 are standing files (13 scripts/agent-*.sh / listener scripts, test_t*
suites and so on). The product file `src/aef-workflow-designer.html` is NOT in the unregistered set.

## Scope review (.fabric/watch-patterns.yaml)
- 8 include globs: src html; tools mjs/py/sh; tests py/sh; scripts py/sh. Each matches files.
- What is deliberately not watched (.agentic-framework, dist, vendor, docs, examples, .editor-versions,
  tests/fixtures) is listed with reasons, and narrowing is done by editing the globs, not by adding `exclude:`,
  for the documented reason that audit.sh does not apply exclude. dist/ is not watched, so the "If not" narrowing
  is already in place for dist. The probes are kept on purpose, as the dependents of the product file
  (decision log 2026-08-08).
- The task's tools/_t344-watch-set-denominator.sh guards against the expansion dropping back to zero.

## Judgement
The expansion is non-empty. 102 unregistered out of 603 (86% covered) is a bounded standing WARN that is
reasonable to carry. The debt has gone from 133/147 unregistered at landing to 102/603, with 522 cards
written, so cards ARE being written against this scope. This is a reversible config/hygiene acceptance,
not a risk, irreversible or sovereignty call, so it does not need escalating.

## Observations (non-blocking)
1. The `## Recommendation` section in the task file (NO-GO, figures 321/253 from 2026-08-28) is stale and
   contradicts the current state. It should be refreshed or marked historical when the AC is ticked.
2. The audit's own history shows the unregistered count creeping up (96 -> 100 -> 102) while the card count is
   "flat". New probes are being added faster than they are carded. That is worth watching so the WARN does not
   become noise nobody reads.
3. 21 cards point at files outside the watch set (a separate WARN).
