# T-1005 — re-vendor step 3 for AEF 1.7.740: what each lost local fix became

Pristine 2659abad, baseline d9f997bf. `_t517` named 51 STALE declared fixes; every patch
applied mechanically, so the decision per fix is made by its behaviour probe, not by whether a
merge succeeds. Outcomes: **re-applied** (ours still needed), **superseded** (upstream has the
behaviour; ours dropped), **partly superseded** (upstream covers part; the rest re-applied).

## update-task.sh (17 local commits)

| commit | fix | outcome | evidence |
|---|---|---|---|
| 4836969f / e0fcf3de | T-391/T-394 multi-line construct refusal | **partly superseded**: upstream T-2991 refuses the torn `python3 -c "` form first; ours still the only guard for a heredoc body (removing it made the heredoc probe create its artifact) | `_t391` 15/15; probe now accepts upstream wording and its teeth target the heredoc form |
| e2f3990e | T-522 completion watchdog + guarded fabric greps | **re-applied** (ported by hand: one composed EXIT trap keeping 1.7.740's bounded keylock) — the unguarded-grep bug had come back | `_t522` 5/5 |
| b87ccbf2 | T-561 inception scope-trace import from stdin | **superseded** by upstream T-2734 (framework root passed as argv[3]) | read in source |
| 3813a922 (+ lib/verification-port.sh) | T-943 malformed-heading refusal (rc=3) | **partly superseded**: "say the zero" adopted upstream (T-3546); the rc=3 refusal **re-applied** in extractor and gate. verification-port.sh had NEVER been declared, so the protocol could not see it — now declared | `_t943` 7/7, `_t574` 13/13 (accepts upstream's zero wording) |
| 580d51f2 | T-871 | **re-applied** (clean) | — |
| e8ad5040 | T-931 ownership revert gate | **superseded / compatible** | `_t931` passes on pristine |
| 324faa00 | T-630 stdin swallowed the command list | **superseded**: upstream adopted it (redirect + reconciliation, crediting 832's report) | `_t630` 11/11 — probe accepts upstream wording; its mutation shows the swallow returns without the redirect and reconciliation blocks it |
| ac53a8b9 | T-658 killed vs failed | **re-applied** (ported: signal classified first, 127 next, generic FAIL last; split summary + OBS-332 hint) | `_t658` 11/11, mutation bites; probe accepts upstream's NOT RUNNABLE for 127 |
| 580d51f2 note | T-871 exit 127 = command not found | upstream now carries this as its own branch (NOT RUNNABLE) | read in source |
| 0444fc5b | T-649 warn when completing with uncommitted work | **re-applied** (function + call after P-011) | `_t649` 8/8 |
| 3653bdbb | T-654 null horizon on archive | **superseded**: upstream has ONE end-of-script invariant for every path to completed/ | `_t654` 7/7; probe gained upstream-shape teeth (removing the invariant regresses both paths) |
| b17e49fa | T-575 exact-heading refusal | **covered**: malformed heading by the T-943 port, zero said by upstream T-3546, prefix-heading by upstream's exact-match extractor (`_t574` t542 leg). **Not carried: refusal of TWO exact `## Verification` headings** (only the first runs) — no probe, low incidence; known small gap | — |
| c425cb41 | T-843 uncontrolled absence assertions | **re-applied** (check function + call; lib restored) | `_t843` 12/12, integration 16/16 |
| 0fe9498b | T-880 task-lifecycle node hint (frw_7_all) | **re-applied** (replaces the T-2624 hint, which named a node no template has) | `_t880` 16/16 |
| bc267087 | T-923 instance-position walks at each transition | **re-applied** (lib source + stubs + 7 walk sites, placed by surrounding text) | `_t923` 14/14 |
| 9b24a57d | T-883 refusal audit (R-033, P-010, P-011) | **re-applied** | `_t883` 18/18 |
| 9a3dee4a | T-913 unexplained bypass recorded as such | **re-applied** (3rd-arg reason, explained flag, both callers) | `_t913` 17/17 |

**update-task.sh: complete.** 14 probes green after the last change (sweep: _t391, _t522, _t574, _t630, _t649, _t654, _t658, _t843, _t880, _t883, _t913, _t923, _t931, _t943). `_t517`: 45 stale left.

## Second finding: undeclared local ADDITIONS are deleted, not just overwritten

The pristine commit recorded 7 deletions. Five were our own code files that the vendor copy
does not ship: `check-bare-import.sh` (T-936), `instance-position.sh` (T-880/T-883),
`task-ownership.sh` (T-931), `verification-absence.sh` (T-843) — none declared — and
`external_consult.py` (T-887, declared). Restored from 2659abad^ and declared (24a25850). The two
remaining deletions are runtime state files and stay deleted.

## Finding for the protocol (T-1000) and for AEF

The protocol protects only DECLARED local fixes. `lib/verification-port.sh` carried T-943's
fix undeclared, so the 1.7.740 upgrade erased it and `_t517` listed nothing. Declaring at the
moment a vendored file is patched (the manifest's own rule) is load-bearing; a gate that refuses
a commit touching `.agentic-framework/` without a manifest entry would close the gap.

## Other files (in progress)

| file | outcome | evidence |
|---|---|---|
| 8 exec-bit (mode) entries; `.secret-scan-patterns`; `lib/context_tokens.py` | **superseded** (shipped upstream / identical) — removed from the manifest | `git ls-files -s`, content compare |
| `extract-decisions.py` (T-516, deleted by T-840) | **superseded** by upstream `extract_decisions.py` (T-3015), the live path; its multi-word-label fold fixed in place (declared) | `_t516` 8/8 against the live extractor |
| `observe.sh` (T-557) | **superseded** in substance (upstream refusal adopted); one line re-applied: "Nothing was written" | fw note test 6 legs |
| `create-task.sh` | T-660, T-767 clean; **T-774/T-775/T-776 ported** (frontmatter-scoped substitution; line-break names refused; T-XXX before operator text) | `_t774` 13/13, `_t775` 6/6, `_t776` 5/5, `_t767` 4/4 |
| `git/lib/hooks.sh` | T-686 clean; **T-659 ported** into the hook template; live hooks reinstalled (`install-hooks --force`) and the re-vendor gate line re-added | `_t659` 6/6 |
| `web/test_context_tokens.py`, `web/test_safe_commands.py` (deleted by T-840) | restored to the working tree; to be committed with `safe-commands.sh` | — |
| `safe-commands.sh` + `check-active-task.sh` (T-390..T-652, lost at T-840) | **pending, deliberately**. The right merge is ours = the pre-T-840 file, base = the T-276 baseline (v1.6.763) the fixes were made on, theirs = 1.7.740. Upstream added +1254 / +682 lines to these files meanwhile (partly converging on our approach), leaving 6 + 10 conflict regions in security-relevant hook code. Oracle: `web/test_safe_commands.py` (restored): **78 pass / 54 fail on pristine 1.7.740** — includes genuine writes NOT caught (`cmd 2> errors.log`, `cmd &> combined.log`). Both files restored to pristine meanwhile; done next as a focused piece. | test file restored, uncommitted |

**Merge-source lesson.** For fixes lost at the EARLIER re-vendor (T-840), the pre-upgrade file of THIS
upgrade does not contain them; "ours" must be the file before T-840 and "base" the baseline those fixes
were written against. A first attempt that used the pre-1.7.740 file merged cleanly and restored nothing.

## Measured (2026-10-02 18:37Z, commit cd64a26e)

Bridge suite: **137 passed, 29 failed** (was 128 / 38 at 4db14034 this morning). Nine legs back to green:
fw note payload, P-011 unreadable-block gate, T-943 heading states, card purpose markdown (T-569),
in-place card edit on the live dashboard and /fabric cache (T-568), episodic pipefail, episodic
decisions extractor, designer render check. Remaining 29 include the safe-commands/audit.sh/fabric/BVP
families still on the worklist and the designer-side legs that are separate bug tasks (T-995).
