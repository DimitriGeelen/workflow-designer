---
id: T-632
name: "Read-only commands classified as writes: sed -n and >/dev/null are refused by the no-active-task gate"
description: >
  Read-only commands classified as writes: sed -n and >/dev/null are refused by the no-active-task gate

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-29T15:43:51Z
last_update: 2026-08-29T15:53:28Z
date_finished: 2026-08-29T15:53:28Z
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

# T-632: Read-only commands classified as writes: sed -n and >/dev/null are refused by the no-active-task gate

## Context

Two pure-read commands were refused by the active-task gate inside five minutes of a
fresh session, both while the session was doing nothing but reading state:

    WURL=$(cat .context/working/watchtower.url 2>/dev/null); ... curl -sf "$WURL/" >/dev/null
    sed -n '340,420p' .agentic-framework/agents/context/lib/safe-commands.sh

Neither writes anything. The first is step 5 of the framework's own `/resume` skill,
verbatim.

The task NAME records my first hypothesis and it is half wrong — kept rather than
rewritten, because the wrong half is the finding. `>/dev/null` is NOT the trigger:
`has_bash_write_pattern` explicitly excludes it (safe-commands.sh:378). Reading the code
instead of trusting the reproduction gave two DIFFERENT mechanisms:

  (a) The redirect walk captures its target with `[^[:space:];|]*`, which does not stop
      at `)`. Inside a command substitution, `$(cat f 2>/dev/null)` yields the target
      `/dev/null)` — which is not the string `/dev/null`, so the sink exclusion misses
      and the segment is classified as a write to a file literally named `/dev/null)`.
      This is PL-025's own class (character-level regex over shell structure) reappearing
      inside the code written to fix PL-025, in the one branch T-404 added to fix it.

  (b) `sed`, `awk`, `cut`, `sort`, `uniq`, `tr` and friends are simply absent from the
      allowlist's read categories (2 and 3). Not misclassified as writes — never
      classified at all, so every segment containing one falls through to "needs a task".
      Since T-405 judges EVERY segment of a pipeline, one such stage condemns the whole
      pipeline: `cat f | sed -n 1,20p` is refused while `cat f` alone passes.

Both directions are false REDs, and a false red is the same defect as a false green: it
moves the gate's verdict away from the truth and trains the reader to route around it.

Scope note: (b) is an allowlist gap and widening a default-deny list is a real decision,
not an obvious fix — it is judged here on whether each verb can write at all, and any
verb that can (sed -i, awk > file) stays out or stays conditional.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Both refusals are reproduced against the LIVE predicate before any fix, so the
      teeth are measured rather than argued: `$(cat f 2>/dev/null)` classified as a
      write, and a `| sed -n` pipeline classified as unsafe.
- [x] (a) is fixed at the redirect walk: a command-substitution close paren no longer
      leaks into the redirect target, and `/dev/null` inside `$( )` is recognised as
      the sink it is.
- [x] (b) is fixed by admitting only verbs that cannot write in the admitted form;
      each addition carries the reason it is safe, and any write-capable form of the
      same verb (`sed -i`, `awk` with a redirect, `tee`) is still refused.
- [x] A prober exists with real teeth: it mutates the live source and asserts the
      relevant leg goes RED, and it fails loudly if the mutation cannot be applied
      (no silent no-op mutation — the T-631 lesson).
- [x] The genuine-write corpus still fails closed: the prober asserts that the forms
      the gate exists to catch (`> file`, `sed -i`, `rm`, heredoc, `tee`) are STILL
      classified as writes after the fix.
- [x] The framework's own `/resume` step 5 runs unblocked from a null-focus session.

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
bash tools/_t632-read-only-misclassification.sh
python3 -m pytest .agentic-framework/web/test_safe_commands.py -q

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** Two pure-read commands were refused by the active-task gate within five
minutes of a session start, on a session that had written nothing. One of them was step
5 of the framework's own `/resume` skill.

**Root cause:** Two independent defects, both in `lib/safe-commands.sh`.
(a) The redirect walk captured its target with `[^[:space:];|]*`, which does not stop at
`)`. Inside a command substitution the target read `/dev/null)` — not the string
`/dev/null` — so the discard-sink exclusion missed by one character and the command was
classified as a write onto a file of that name. `2>&1)` failed the same way against the
fd-dup exclusion.
(b) `sed`, `sort`, `cut`, `tr`, `diff` and the other read-only text tools were absent
from the allowlist entirely — not misclassified, never classified. Because T-405 judges
every segment of a pipeline, one such stage condemned the whole pipeline: `cat f | sed
-n 1,20p` refused while `cat f` passed.

**Why structurally allowed:** PL-025 already named this class on 2026-07-10 — "when a
heuristic reasons about raw characters instead of shell semantics, pin the boundary with
a test corpus." The remedy was applied: `web/test_safe_commands.py` exists, is 49 tests
long, and mirrors the hook's ordering in a `gate_allows` helper. It stayed green anyway,
because it was assembled from the three commands blocked in the 2026-08-09 incident. It
even pins this exact command as `RESUME_STEP5` — but the variant it pins writes
`2>/dev/null || echo ...`, and the `||` splits the segment before the close paren, so
that copy never contains the failing adjacency. **The corpus pinned the instances it had
and never tested the class around them** (577 @774). Measured, not argued: the prober
runs the pinned constant through the pre-fix predicate and shows it passing.

The deeper reason (a) survived is that quote-stripping was treated as *the* structural
fix. T-404 taught the walk that quotes are not structure; nothing taught it that nesting
is. So PL-025's own class recurred inside the branch written to fix PL-025.

**Prevention:** distinct from the fix in both directions.
1. `tools/_t632-read-only-misclassification.sh` (34 legs) builds a pre-fix copy by
   reverting the live source and asserts both defects reproduce there — teeth that
   cannot silently expire, and a fatal error rather than a warning if the mutation
   matches nothing (the T-631 no-op-mutation lesson, hit again in this task's first
   draft: the tail anchor used an indent backreference against a `;;` one level deeper,
   matched nothing, and reported success).
2. The corpus gains 22 tests that are *invented*, not harvested — nesting benign forms,
   writes inside substitutions (the discriminating teeth for the paren fix), the
   read-only tool set, the write-capable forms of the admitted verbs, and the two
   deliberate exclusions so a later widening trips a test instead of production.
3. The hook-level leg runs the two originally-refused commands through
   `check-active-task.sh` with focus genuinely null — behind an anti-vacuity control
   that fails the whole block if the hook refuses nothing in that sandbox.

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

### 2026-08-29T15:43:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-632-read-only-commands-classified-as-writes-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f7e01c82
- **Timestamp:** 2026-08-29T15:53:33Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-29T15:53:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
