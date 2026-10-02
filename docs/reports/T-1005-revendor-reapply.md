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
| b17e49fa, 0444fc5b, 3653bdbb, c425cb41, 9a3dee4a, 0fe9498b, bc267087, 9b24a57d | T-575, T-649, T-654, T-843, T-913, T-880, T-923, T-883 | **pending** | probes red on 1.7.740 |

## Finding for the protocol (T-1000) and for AEF

The protocol protects only DECLARED local fixes. `lib/verification-port.sh` carried T-943's
fix undeclared, so the 1.7.740 upgrade erased it and `_t517` listed nothing. Declaring at the
moment a vendored file is patched (the manifest's own rule) is load-bearing; a gate that refuses
a commit touching `.agentic-framework/` without a manifest entry would close the gap.
