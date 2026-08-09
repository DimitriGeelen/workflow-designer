---
id: T-415
name: "Probe the ANNOUNCED span rule against AEF's second-qualifier-occurrence case (rail 506 §4)"
description: >
  Probe the ANNOUNCED span rule against AEF's second-qualifier-occurrence case (rail 506 §4)

status: started-work
workflow_type: test
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-09T15:32:09Z
last_update: 2026-08-09T15:32:09Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-415: Probe the ANNOUNCED span rule against AEF's second-qualifier-occurrence case (rail 506 §4)

## Context

AEF took T-412's span rule to their own scanner, and their first fix — split the name on
the qualifier's first occurrence, look for the noun in either side — passed all seven of
their fixture legs and was **still wrong**. Their generative leg refused it on
`passwd-passwd`, which named a more general form than either of us had stated:

> the noun can be hiding inside a **second qualifier occurrence**.

`auth-password-policy.json`: split on the first qualifier and `pass` is found inside
`password`. The spans genuinely do not overlap, and **both words are qualifiers** — there
is no noun anywhere in the name. Disjointness is necessary and not sufficient.

They asked directly (rail 506 §4): *"If your span check is implemented as a split,
`auth-password-policy` is worth a probe."* This measures it rather than reasoning about it,
because reasoning about my own scanner from their instance is exactly the error I made at
502 §4 and corrected at 503.

## Acceptance Criteria

### Agent
- [x] `auth-password-policy.json` and the rest of AEF's 506 §4 case list run through
      `tools/tracked-secret-artifacts.py` and the verdicts recorded, right or wrong
- [x] The result is stated as a structural claim about *why*, not just a verdict: whether
      this implementation is split-based (AEF's failing form) or occurrence-enumerating
- [x] If it fires: a fix task is filed separately (one bug = one task) and this task carries
      only the measurement. If it does not: the reason is recorded so the next reader knows
      it was measured and not assumed

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# --- T-415 ---
# AEF's exact case must stay unflagged; this is the whole answer to their 506 §4 question.
python3 -c "import importlib.util as i; s=i.spec_from_file_location('t','tools/tracked-secret-artifacts.py'); m=i.module_from_spec(s); s.loader.exec_module(m); raise SystemExit(0 if m.classify('config/auth-password-policy.json')[0] is None else 1)"
# The class DOES fire here (secret-password-rotation.md and friends) and that measurement
# is NOT pinned as a verification line on purpose: a gate written to hold only until the
# fix lands would go red on T-416 and read as a regression. The witness belongs in T-416,
# as a leg that is red before its fix and green after.

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

## Measured

    config/auth-password-policy.json   -> unflagged      <- AEF's exact case. Does not fire.
    docs/auth-password-policy.md       -> unflagged
    docs/secret-password-rotation.md   -> ANNOUNCED      <- the class, in realistic prose
    docs/credential-password-guide.md  -> ANNOUNCED
    docs/password-secret-handling.md   -> ANNOUNCED
    docs/passwd-password-migration.md  -> ANNOUNCED
    x/password-passwd.txt              -> ANNOUNCED
    docs/reset-password.md             -> unflagged      (T-412's three, still clean)
    docs/password-policy.md            -> unflagged
    config/password-key.txt            -> ANNOUNCED      (genuine pairs, still flagged)
    x/private-key-store.dat            -> ANNOUNCED

**Answering AEF's actual question — is this split-based?** No. `_spans()` enumerates *every*
occurrence of every word and `announced_pair()` tries all (secrecy, noun) combinations, so
there is no "first occurrence" to split on. And the noun half runs with
`whole_part_only=True`, so `pass` cannot be found inside `password` at all — the substring
their split exposed is not reachable here. `auth-password-policy` therefore has no candidate
noun and returns `None`.

**But their general form lands, one word over.** `password` and `passwd` are in *both*
tuples by design (T-412 kept the overlap so the span rule stays load-bearing). Give a name
two members of that family and each satisfies a different half at a different span:
`secret-password-rotation.md` → `secret` as qualifier at (0,6), `password` as noun at (7,15),
disjoint, pair complete. **There is no credential noun in that name.** Two qualifiers,
nothing announced, and it is an entirely ordinary documentation filename.

So AEF's insight transfers exactly and their instance does not: **disjointness is necessary
and not sufficient**, and what saved me from `auth-password-policy` was whole-part matching
on the noun half, not anything about the pair rule. I would have called this clean if I had
reasoned from their case instead of running mine — the same error as 502 §4, avoided this
time only because they told me to probe.

The T-412 fix is now the second one in this lineage to survive its own instance and fail on
the next word: their T-2897 curated the lists, my T-412 added spans, and both left a rule
whose failure mode is one plausible word away. Fix filed as **T-416** (masking form).

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-09T15:32:09Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-415-probe-the-announced-span-rule-against-ae.md
- **Context:** Initial task creation
