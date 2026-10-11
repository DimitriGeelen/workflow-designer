# I — the hand-off readiness predicate must ask the GO hypothesis gate too (832 T-1123; addendum to bundle E patch 0010)

**Status:** one commit, an **addendum to our proposal E/0010** (the GO hypothesis gate, 832 T-866, queued in your
T-3817). **Not a defect in AEF as released:** v1.8.9 has no hypothesis gate, so its decide command and its hand-off
predicate agree. The defect appears the moment 0010 is applied without this commit — it did, in 832.
**Apply:** after `E/0010`, `git am 0001-inception_handoff_blockers-ask-the-GO-hypothesis-gat.patch` — changes
`lib/inception-readiness.sh` (+22 lines) and adds `contrib/832-handoff-hypothesis/test_handoff_hypothesis.sh`.
Checked with `git am` on AEF v1.8.9 `lib/` plus 0010's `task-audit.sh`/`inception.sh`.

## The bug (832, 2026-10-11)

- The operator approved GO on 832's T-1118. `fw task review` and `/inception/T-1118` both showed it **ready** (no
  blockers, decide form rendered). Our runme job ran `fw inception decide T-1118 go` and it was **refused**:
  "## Hypothesis required before a GO decision" — the success clause was still the placeholder.
- **Root cause.** `inception_handoff_blockers` is "THE one predicate a decision handoff consults" (T-3549); its
  header says a new hand-off requirement is added there and every invitation surface inherits it (fw task review,
  the /inception decide form via `web/shared.py`, audit D14b). 0010 put the hypothesis gate only inside
  `do_inception_decide`. Invitation and enforcement then disagree on GO.
- **Why it went unseen.** 0010 predates your T-3549/T-3896 predicate; 832 re-applied 0010 on each re-vendor and the
  re-vendor check only proves a local fix applies cleanly, not that it still fits the code around it.
- **Size.** 12 of 832's 18 open inceptions would be refused a GO; 2 recommended GO and were being offered as ready.

## The fix

In `inception_handoff_blockers`, after the recommendation rule:

- if `audit_inception_hypothesis` is loaded **and** the (uncommented) `**Recommendation:**` is **GO**, run it with
  `go`; if it refuses, emit `hypothesis-unready <TAB> ## Hypothesis would be refused at a GO: <first line of the
  gate's reason> <TAB> how to fix`.
- **Only on a GO recommendation**, because the gate binds GO alone and every blocker hides the whole decide form
  (`inception_detail.html`): a NO-GO or DEFER must stay decidable.
- **No-op without 0010** (`command -v` guard, same pattern as the recommendation rule above it).
- Return code stays 0 (OBS-566 contract); the finding is in stdout.

## Test (8 legs)

`FRAMEWORK_ROOT=. bash contrib/832-handoff-hypothesis/test_handoff_hypothesis.sh`: GO + placeholder → blocked; GO with
no hypothesis → blocked; GO + checkable clause → clear; NO-GO / DEFER + placeholder → clear; a GO only inside an HTML
comment → clear; returns 0 with a finding; parity with the decide gate. **8/8 with the commit, 6/8 without.**

## Suggestion beyond the patch

A parity test between the gates `do_inception_decide` enforces and the blockers `inception_handoff_blockers` reports
(e.g. for each refusal fixture of decide, the predicate must be non-empty) would catch the next gate added to one
side only.

## 832 side

Same change in our vendored copy (declared local fix, `.vendor-divergence.yaml`, gap G-085); our decide jobs now run
both framework predicates in their rehearsal, so a decide job cannot reach the operator unready again.
