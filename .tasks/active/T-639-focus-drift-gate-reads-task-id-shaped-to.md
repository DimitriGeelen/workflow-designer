---
id: T-639
name: "Focus-drift gate reads task-id-shaped tokens out of quoted test fixtures, blocking probes that only mention a task id"
description: >
  Focus-drift gate reads task-id-shaped tokens out of quoted test fixtures, blocking probes that only mention a task id

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-30T09:52:37Z
last_update: 2026-08-30T09:52:37Z
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

# T-639: Focus-drift gate reads task-id-shaped tokens out of quoted test fixtures, blocking probes that only mention a task id

## Context

The focus-drift gate (T-1730) identifies which task a command TARGETS, and blocks when
that differs from the focused task. All three of its patterns match against the raw
`$BASH_CMD`, so they read task-id-shaped text out of quoted arguments:

```
elif [[ "$BASH_CMD" =~ (^|[[:space:]])git[[:space:]]+commit ]] && \
     [[ "$BASH_CMD" =~ (T-[0-9]+): ]]; then
```

Two independent over-matches in one condition. The first clause is the T-638 defect
verbatim — `git commit` anywhere, quoted text included. The second is unanchored to
anything: `T-1:` occurring *anywhere* in the command becomes the target.

So a prober that exercises the gate's own git-commit path is blocked by the gate, because
its fixture string contains a task id. That happened (OBS-326). It is not a hypothetical:
during T-638 I wrote every fixture as `T-x:` rather than `T-1:` specifically to stay under
the pattern — which means the gate was silently shaping test data to avoid itself. A gate
that fires on the wrong command trains people to route around it, and the file's own
comment says exactly that about a different anchor.

Patterns 1 and 2 have the same shape: `echo "run fw task update T-1 next"` presents as a
mutation of T-1.

**Why the obvious fix is wrong.** Stripping quotes wholesale and matching the stripped
string would break pattern 3 entirely: a commit's task id lives INSIDE the quoted `-m`
argument, which is precisely what stripping deletes. The two cases need different reads —
that asymmetry is the substance of this task, not an implementation detail.

## Acceptance Criteria

### Agent
- [x] Patterns 1 and 2 (`fw task update T-N`, `fw context add-* --task T-N`) match against
      the QUOTE-STRIPPED command. Their task id is a bare argument, so stripping is the
      correct read and a quoted mention stops being a target.
- [x] Pattern 3 fires only when the command actually INVOKES git commit — some clause's
      leading token is `git` with `commit` next — not when a quoted argument contains the
      words. Reuses the clause reasoning from T-638.
- [x] Pattern 3 takes its task id from the `-m` / `--message` VALUE and anchors it at the
      START of that value (`T-NNN:` is the canonical prefix, enforced by commit-msg), so a
      task id elsewhere in the message body or in an unrelated argument is not a target.
- [x] Genuine drift still blocks — every existing block case is preserved. Verified against
      the live hook, not argued: `git commit -m "T-1: x"` off-focus blocks; `fw task update
      T-1 --status issues` off-focus blocks; `fw context add-learning "x" --task T-1` blocks.
- [x] The three false-positive shapes are admitted: a fixture passed to a prober, a `grep`
      whose pattern contains a commit form, and prose in an `echo`.
- [x] Both documented bypasses (`--switch-focus`, `FW_SWITCH_FOCUS=1`) still work unchanged.
- [x] A mutation prober drives the REAL hook against a mutant carrying the pre-fix patterns
      derived from live source, and asserts DISAGREEMENT on the false positives and
      AGREEMENT on the genuine drifts.
- [x] No per-call fork added — this runs on every Bash tool call.

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
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

# Mutation prober: real hook vs a mutant carrying the pre-fix patterns, derived from
# live source. Asserts BOTH directions — group A (blocked before) now admitted, group
# B (allowed before) unchanged, genuine drift still blocked, bypasses intact.
bash tools/_t639-drift-gate-reads-fixtures.sh
# Standing corpus for the library, incl. 11 drift-target cases.
python3 -m pytest .agentic-framework/web/test_safe_commands.py -q

## RCA

**Symptom:** The focus-drift gate blocked commands that only MENTIONED a task id.
Concretely and self-demonstratingly: a prober written to exercise the gate's own
git-commit path was blocked by the gate, because its fixture strings contain task
ids. Reproduced live in this session — the block fired on the probe script itself.

**Root cause:** All three drift patterns matched against the raw `$BASH_CMD`, so
each read task ids out of quoted arguments. Pattern 3 held two independent
over-matches in one condition: `git commit` anywhere (the T-638 defect verbatim) and
an entirely unanchored `(T-[0-9]+):`.

**Why structurally allowed:** The gate had no tests at all. `test_safe_commands.py`
covers the predicates in `safe-commands.sh`; the drift patterns lived inline in
`check-active-task.sh` where nothing reached them. And the failure mode is
self-concealing in the worst way: it blocks the very probes that would expose it.
During T-638 every fixture was written `T-x:` rather than `T-1:` to stay under the
pattern — the gate was silently shaping test data to avoid itself, and that
adaptation is invisible in the record because the blocked commands were never run.

**A second finding, from the prober disagreeing with me.** I claimed five false
positives; the mutant showed only three. The other two passed before *by accident* —
a `"` happened to precede the match, so the whitespace anchor missed. One added
leading space inside the quoted argument flips them to blocked, which is the sharpest
statement of the defect: the verdict turned on a whitespace character inside a string
the outer command never interprets. The prober now asserts both groups separately so
this task claims credit only for what it changed.

**Prevention:** (1) The three patterns moved into `_sc_drift_target` in the library,
where 11 corpus cases now pin target-vs-mention on every change to that file. (2) The
mutation prober asserts disagreement with a pre-fix mutant derived from live source,
so reverting turns it red. (3) A group-B leg positively asserts what was NOT broken,
which is what caught my overstatement.

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

### 2026-08-30T09:52:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-639-focus-drift-gate-reads-task-id-shaped-to.md
- **Context:** Initial task creation
