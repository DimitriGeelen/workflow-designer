---
id: T-628
name: "G-020 block message names two escapes; both are refused by the gate that prints them"
description: >
  G-020 block message names two escapes; both are refused by the gate that prints them

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
created: 2026-08-29T14:56:05Z
last_update: 2026-08-29T15:05:54Z
date_finished: 2026-08-29T15:05:54Z
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

# T-628: G-020 block message names two escapes; both are refused by the gate that prints them

## Context

999-AEF reported (rail @775, their T-3216) that G-020's block message names two
escapes and the same gate refuses both. 577-CashWeb reproduced it (@776) and added
the part that explains why nobody noticed: *following a remedy successfully proves
that YOUR route works; it is not evidence that the remedy is reachable.* Both of them
escaped via the Edit tool and concluded the gate was working as intended — which is
exactly what this session did twice, for the same reason.

Measured here from inside the blocked state (T-628 is its own fixture: a freshly
created build task carries placeholder ACs by definition, so creating it IS entering
the state):

    control   echo probe > <scratch>/t628-control.marker ......... REFUSED (G-020 by name)
    remedy 2  fw task update T-628 --type inception .............. REFUSED
    remedy 2  .agentic-framework/bin/fw task update … --type … ... REFUSED
    remedy 1  sed -i 's/[First criterion]/…/' .tasks/active/… .... REFUSED
    remedy 1  Edit tool, same file, same edit .................... WORKS
    (control) head -5 .tasks/active/T-628-*.md .................... ALLOWED

The control matters: every earlier gate in this hook also exits 2, so "blocked" alone
would have been satisfied by no-active-task or task-not-active. The banner names G-020.
The last line is the negative control that proves the gate is not simply refusing all
Bash — reads pass, so the refusals above are the write-classifier acting, not a blanket.

ROOT CAUSE, and it is one notch below the missing-allowlist-entry reading. Both printed
remedies are actions on `.tasks/`, and `.tasks/*` IS exempt — for Write/Edit, where the
hook has a FILE_PATH to test the exemption against. A Bash command has no single file
path, so the path exemption cannot be evaluated on the very surface the gate restricts,
and every write falls through to the block. The refusal even prints `Attempting to
modify: ` with nothing after it, because there is no FILE_PATH to name. The gate is not
missing an entry; its exemption model has no expression on one of its two surfaces.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Remedy 2 (`fw task update <TASK> --type <type>`) is reachable from Bash while
      G-020 is firing, for both the bare `fw` spelling the message prints and the
      `.agentic-framework/bin/fw` spelling this project mandates
- [x] Remedy 1's wording is surface-accurate: it no longer implies a shell edit is
      available when only the Edit/Write tool path is
- [x] The block message no longer prints a bare `Attempting to modify: ` with an empty
      target when the restricted call is a Bash command
- [x] `tools/_t628-g020-remedy-reachable.sh` probes each printed remedy verbatim from
      inside the firing state, and asserts on OUTPUT not exit code (577 @774 item 5:
      a `!`-inverted leg is satisfied when the guard fires AND when it crashes)
- [x] The prober carries at least one INVENTED fixture that does not occur in our
      corpus, and mutation-testing shows a fixture that only the invented case catches
- [x] Widening is bounded: the allowlist admits the conversion command for the CURRENTLY
      FOCUSED task only, and a negative fixture proves a different task ID is refused

Result: 13/13 legs green, teeth proven by mutation of live source. T-386 (the sibling
gate's prober, same file) re-run at 11/0 — no regression.


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

# Each line's own exit code is the verdict — no chaining, so the T-352 errexit
# trap (`a; b` judged on `b` alone) has nothing to bite on here.
bash tools/_t628-g020-remedy-reachable.sh
bash tools/_t386-drift-remedy-reachable.sh
bash -n .agentic-framework/agents/context/check-active-task.sh

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

**Symptom:** G-020's block message names two escapes. Both are refused by the gate that
prints them, and the refusal reprints the command it just refused.

**Root cause:** Both remedies are actions on `.tasks/`, and `.tasks/*` IS exempt — but
the exemption is expressed as a FILE_PATH test. A Bash tool call carries no single file
path, so the exemption cannot be evaluated on one of the two surfaces the gate restricts,
and every shell form of both remedies falls through to the block. Not a missing allowlist
entry: an exemption model with no expression on one surface.

**Why structurally allowed:** T-2052 already fixed exactly this for the no-active-task
gate ~560 lines above in the same file, with the same reasoning written out in its
comment ("gating them on one is a deadlock; the block message below even lists them as
the unblock path"). T-386 then built a remedy-reachability prober for the focus-drift
gate in the same file, and its header names G-020 as a sibling. We solved the class twice
and never swept the file we solved it in. The reason nobody noticed is 577's (@776): we
hit G-020 twice this session, escaped via the Edit tool both times, and concluded it was
working as intended — FOLLOWING A REMEDY SUCCESSFULLY PROVES YOUR ROUTE WORKS, IT IS NOT
EVIDENCE THAT THE REMEDY IS REACHABLE. The agent best placed to notice is the one least
likely to, because it is not the one that is wedged.

**Prevention:** `tools/_t628-g020-remedy-reachable.sh` runs each printed remedy verbatim
from inside the firing state, through the surface the gate restricts. Distinct from the
fix: the fix makes today's remedy reachable, the prober fails if any future edit to that
message reintroduces an unreachable one. Residual, filed rather than assumed away: the
sibling G-067 gate in the same file prints three remedies that have never been probed.

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

### 2026-08-29 — three of my own legs were red for three different wrong reasons

Worth recording because each red was a defect in the MEASUREMENT, and each would have
been "fixed" by relaxing the leg:

- **The scoped control was not a control.** The gate reads the AC block with a range
  regex piped to a delete-last-line `sed`. My "scoped" fixture ended at its ACs, so the
  range ran to EOF and the delete removed the only AC — the fixture read as unscoped no
  matter what it said. Real task files always carry later sections, so this was a
  property of my fixture. A fixture that cannot express the negative case is not a
  control, and it fails silently in the direction of agreement.
- **A leg asserted the wrong gate's banner.** `fw task update <OTHER> --type inception`
  is refused with rc 2 — by the FOCUS-DRIFT gate, before G-020 is reached. My leg
  demanded the G-020 banner and went red while the tree was correct. A false red is the
  same defect as a false green; it just costs you differently. The leg now asserts the
  absence of the exemption's own NOTE, which nothing else can emit.
- **The mutation ate the wrong `if`.** `if [ "$TOOL_NAME" = "Bash" ]` occurs three times
  in the hook; a non-greedy match from the first swallowed the focus-drift gate whole.
  The mutant failed to parse, which is the only reason it was visible — a mutation that
  removes too little fails loudly, one that removes too much can pass quietly.

And one finding about the harness we already had: **T-386's mutant-in-sandbox idiom is
sound for T-386 and silently vacuous for G-020.** The hook derives `FRAMEWORK_ROOT` from
its own `SCRIPT_DIR`, so a copy outside the framework has no `find_task_file` and dies at
P-002 ~200 lines before G-020. The drift gate sits above that failure point; G-020 sits
below it. Same harness, same file, sound for one gate and testing nothing for its
neighbour. This prober stages its mutant beside the original and guards the teeth with a
reachability leg so the next refactor cannot make it vacuous without saying so.

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

### 2026-08-29T14:56:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-628-g-020-block-message-names-two-escapes-bo.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ed087a12
- **Timestamp:** 2026-08-29T15:06:01Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-29T15:05:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
