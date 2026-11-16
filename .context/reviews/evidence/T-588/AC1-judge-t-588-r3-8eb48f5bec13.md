# T-588 Human AC#1 — evidence report

Reviewer dispatch: judge-t-588-r3-8eb48f5bec13 · revision 42e6b181578e46ec4a5e55a5565460b201603396 · 2026-11-16

## Verdict: amber (criterion literal is out of date; no letter is recorded on T-588)

The criterion asks the operator for one letter (A selective merge / B keep refusing / C `fw update` as-is).
No A/B/C reply is recorded in T-588. I did not pick one: that is the operator's call.
But every premise of the question has since changed, and the operator ruled on the same subject in T-1000.

## What I checked

1. **The criterion's own one-liner, run today.** `fw doctor` head: OK. Code-file count
   `find .agentic-framework -type f \( -name '*.py' -o -name '*.sh' \) | wc -l` = **652**, not 328.
   The "upstream 824 vs our 328; 499 we lack" measurement no longer describes this tree.

2. **Option B's stated cost no longer exists.** Both files it says we lack are present:
   `.agentic-framework/agents/context/check-worktree-governance-write.sh` and
   `.agentic-framework/agents/git/lib/worktree-corpus-guard.sh`.

3. **The tree has been re-vendored from upstream repeatedly since.** `.agentic-framework/VERSION` =
   `1.8.15+1630.gc6c0a6738` (was 1.6.354). `git log -- .agentic-framework/VERSION` shows eight pristine
   vendor commits (T-1335 … T-1426, latest 3c0ab7403 on 2026-11-16, AEF v1.8.16-be.54), each followed by a
   "re-apply 832's local fixes" commit (latest c156f1ed7). `.vendor-divergence.yaml` baseline_commit =
   3c0ab74030deb70edf02a7ac20dd2c16cfe7f990, 60 declared paths.

4. **The operator did rule on how upstream is taken — in T-1000, not here.**
   `.tasks/completed/T-1000-…md` line 88 and `docs/reports/T-1000-revendor-gate.md` line 73:
   "Operator chose A (2026-10-02): the re-vendor protocol with a moving baseline, enforced by hooks"
   — quoted "A yes yes yes and this is what AEF needs to adopt … in framework".
   That protocol (pristine `fw upgrade` commit, baseline advance, re-apply declared local fixes) is in
   substance T-588's option A: take upstream, keep ours where declared, do not lose local fixes.
   Note: that "A" is the letter of T-995/T-1000's option list, not T-588's. It is not a reply to this criterion.

5. **The defect that motivated the refusal is gone from upstream and from our tree.**
   - Pristine upstream at 3c0ab7403 already carries the anchored extractor
     (`lib/verification-port.sh:311` `/^## Verification[[:space:]]*$/`, and a comment at :283 naming the old
     `sed -n '/^## Verification/,/^## /p'` form as the previous one). This is T-588's own reversal trigger (a).
   - Our copy adds 35 lines on top (declared divergence, T-943/T-1005: return 3 on a heading-shaped line that
     is not exactly `## Verification`).
   - I ran `extract_verification_block` on three fresh fixtures for D1/D2/D3:
     A (Verification last section) → LEG-ONE, LEG-TWO, LEG-THREE-LAST (final leg kept);
     B (second `## Verification`) → REAL-LEG only;
     C (`## Verification Notes` before the real heading) → REAL-LEG only, no prose. All rc=0.
   - `tools/_t588-verification-extractor-differential.sh` (offline) prints
     "=== T-588 retired: both successors PASS ===", rc=0.

## Conclusion

The A/B/C question as written cannot be answered meaningfully any more: B and C describe a tree state
that no longer exists, and A's "scoped task" was superseded by the T-1000 protocol the operator chose
and that has run eight times. What is missing is only the operator's confirmation that T-1000's ruling
closes this criterion — hence amber with a proposed restatement, not green and not a fresh A/B/C call.
