---
id: T-392
name: "Safe-list early-return shadows the focus-drift gate: T-390 exempted drift pattern 2"
description: >
  check-active-task.sh:95-97 exits 0 as soon as is_bash_safe_command returns true; the focus-drift gate is at line 299. Safe-listing a verb therefore also exempts it from drift ATTRIBUTION. T-390 safe-listed fw context add-*, which is drift pattern 2, so that pattern has been unreachable since T-390 landed. Reported by AEF (their T-2880, rail 476) and confirmed here by reading our own ordering. A drift check that never runs is silent in exactly the way a drift check that finds nothing is silent.

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
created: 2026-08-08T18:57:24Z
last_update: 2026-08-08T19:48:51Z
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

# T-392: Safe-list early-return shadows the focus-drift gate: T-390 exempted drift pattern 2

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] Shadowing is demonstrated by probe BEFORE the fix: with a focus set to
      T-A, `fw context add-learning "x" --task T-B` must be shown NOT to reach
      the drift gate, while patterns 1 and 3 do reach it
      — `tools/_t392-drift-shadow-probe.sh`, 11 legs, exit 0, VERDICT
      "shadowing REPRODUCED on this copy"; leg 0 anti-vacuity control proves the
      fixture was visible (block message names both T-9001 and T-9002)
- [ ] After the fix, all three drift patterns reach the gate under the same
      conditions
- [ ] The T-390 deadlock stays fixed: with focus NULL, every capture verb
      (`fw note`, `fw context add-*`, `fw handover`) is still ALLOWED — the fix
      must not re-introduce the deadlock it is built on top of
- [ ] Positive control against over-correction: a safe verb carrying NO task id
      (`fw doctor`, `git status`) still exits early and never consults focus
- [ ] Mutation teeth: reverting the fix must make the pre-fix probe leg go red

### Human
- [ ] [REVIEW] Approve changing the central governance hook
  **Steps:**
  1. Read the `## Decisions` section for the **three** candidate shapes.
     A (hoist the focus read) and B (flag honoured by later checkpoints) were
     ours. **C is AEF's, arrived at rail 482 after this task was filed, and it
     is the recommended one** — it changes no ordering at all: drift-target
     *extraction* is pure string work, so it runs in the fast path, and only the
     early return becomes conditional. C has B's mechanism with A's failure
     direction, and it is already landed and measured on AEF's side (T-2880).
  2. Decide which shape is acceptable in `check-active-task.sh`
  **Expected:** A named choice, or a direction to leave the shadow open and
  document it instead
  **If not:** Leave `horizon: now` and re-raise at the start of a session with
  full budget — this is the central enforcement path and both AEF and 832
  deferred it once already for that reason

  **Note on why this still needs you even though C is clearly better:** the
  question is no longer "which of two risky shapes" — C removes most of that
  risk. What remains is that this is the hook gating every Write/Edit/Bash call
  in every session, and a defect in it fails open silently. That is a
  sovereignty call, not a technical one. The agent-side evidence is complete:
  the defect is reproduced here (11 legs), the shape is specified, and AEF has
  run it in production on their copy.

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

## Decisions

### 2026-08-08 — deferred rather than attempted at 66% budget

- **Chose:** file with full diagnosis; do not start the reorder this session.
- **Why:** this is the central enforcement hook on every Bash/Write/Edit call.
  Budget was 197K/300K (66%) when the report arrived, and framework policy at
  60-75% is small bounded tasks only. AEF independently deferred the identical
  change at 68% for the same reason (rail 476). Getting this wrong fails open on
  every command in the session that discovers it.
- **Rejected:** shipping a quick fix now. The two candidate shapes below are not
  equivalent in risk, and choosing between them at the warn line is how the
  wrong one gets chosen.

### Candidate shapes (for the human REVIEW above)

**A — hoist the focus read.** `CURRENT_TASK` is not read until ~line 186, after
the early return, so the drift comparison cannot simply be moved up; the read
itself has to move. Smaller diff at the call site, larger blast radius on
initialisation order.

**B — flag honoured by later checkpoints.** The safe branch sets e.g.
`_FW_SAFE_ALLOWED=1` instead of `exit 0`; the existing checkpoints then honour
it: exit 0 when focus is NULL (no drift is possible with nothing to drift from),
run drift detection when a focus exists. Preserves the T-390 deadlock fix by
construction, at the cost of three call sites that must all honour the flag —
and any one that forgets it re-introduces the deadlock silently.

Note the asymmetry: A fails toward blocking work, B fails toward permitting it.

**C — extract the QUESTION, not the answer. (AEF, rail 482 §1-2. Landed on their
side as T-2880. This is the recommended shape.)**

Both A and B assumed the drift comparison has to happen where `CURRENT_TASK` is
readable. It doesn't. The hook asks two questions with different inputs:

    "does this need an active task?"        SESSION state    needs focus.yaml
    "is it attributed to the right task?"   COMMAND string   needs nothing

Target *extraction* is pure string work over `$BASH_CMD`. It never needed the
focus parse at ~186, so it can run in the fast path at ~90. Extract the three
patterns into `_fw_extract_drift_target()`, call it BEFORE the safe-list return,
and make that return conditional:

    names no task  -> exit 0            (unchanged — every ordinary safe command)
    names a task   -> SAFE_ALLOWED=1, fall through to the real gate

**No focus read moves. No hoist. Nothing is reordered.** A's cost — a YAML parse
in the hot path of every safe command, and safety made dependent on focus state,
which is the exact coupling that caused this defect — disappears, because the
thing being hoisted is the *question*, not the answer.

**C takes B's mechanism with A's failure direction.** My own framing of the A/B
choice was "B is the one I would reach for and A is the one I would trust"; AEF's
reply is that those are separable, and the flag's danger lives in its REACH, not
in its being a flag:

    flag honoured at 3 sites -> one forgets -> gate silently stops enforcing
    flag honoured at 1 site  -> that site missed -> deadlock returns LOUDLY,
                                                    with a remedy

`SAFE_ALLOWED` is consumed at **exactly one place**: the null-focus branch
(line 233 here). Nowhere else. The stale-focus / G-013 / status checks
deliberately do NOT honour it — so a drift-naming command under stale focus
blocks, and AEF verified the remedy that block prints (`fw work-on T-X`) is
itself safe-listed, i.e. not a second deadlock.

**AEF's measurement, before and after** (real hook, synthetic PROJECT_ROOT via
the stdin `cwd` re-anchor, live focus untouched — `context add-*` naming T-9002
while focus is T-9001):

    focus state                    before   after
    null (post-completion)         ALLOW    ALLOW   <- T-2878/T-390 preserved
    T-9001, current session        ALLOW    BLOCK   <- the repair
    T-9001, stale session          ALLOW    BLOCK   (remedy is safe-listed)
    T-9001, not in active/         ALLOW    BLOCK
    T-9001, status captured        ALLOW    BLOCK

Non-drift-naming safe commands (`doctor`, `git status`, `ls -la`, `note`,
`handover`, `context status`, and bare `context add-learning` with no `--task`)
are unchanged ALLOW in all five states. 11 new assertions plus 160 pre-existing
over that hook, green.

**Sharper root cause, from AEF §3 — and it reproduces here verbatim.** Lines
221-224 of our own `check-active-task.sh`, written for T-2054's `git commit`
exemption, two hundred lines above where T-390 broke it:

    "This lives here, NOT in is_bash_safe_command, on purpose: when focus is
     NON-null git commit must still reach the focus-drift gate (T-1730) — a
     context-free allowlist entry would short-circuit that."

The rule was stated, correctly, in prose, by a prior task that hit the identical
tension and resolved it right. T-390 then added a context-free allowlist entry
and short-circuited the gate. **The placement was known-wrong before it was
written** — which is a sharper root cause than "the early return was in the wrong
place", and it points at a different prevention: nothing enforced the rule and
nothing surfaced it at the point of edit. Verified present in our copy at
lines 221-224, not taken on report.

### 2026-08-08 — OBS-003 lands in the SAME function shape C creates: do them together

Not a separate piece of work, and splitting them would mean writing
`_fw_extract_drift_target()` and then immediately rewriting it.

OBS-003 (raised at T-390, still open, registered as a gap): the drift gate infers
its target from **any task id appearing anywhere in the command string, including
inside a quoted payload that is merely prose**. Writing a rail message whose text
mentions a completed task was blocked as "action targets a different task" when
the action was writing a file. That describes every cross-project rail message we
send. Its recorded remedy direction is *"derive the target from the fw
sub-command's own argument position, not from a scan of the whole string."*

Shape C's whole content is extracting those three patterns into
`_fw_extract_drift_target()`. That function IS the scan OBS-003 wants replaced —
so the argument-position fix belongs in it at the moment it is created, not after.

Concretely, patterns 1 and 2 already anchor on the sub-command
(`fw task update <id>`, `fw context add-* --task <id>`) and are close to correct.
**Pattern 3 is the loose one:** `git commit` + a bare `(T-[0-9]+):` match anywhere
in the string, which is what a quoted commit body or heredoc trips. Anchoring it
to the message argument rather than the whole command is the fix.

Flagged here rather than filed separately because whoever implements C will be
editing exactly these lines, and OBS-003 is invisible from inside that diff.

### 2026-08-08 — shadowing reproduced HERE, not inferred from AEF's report

`tools/_t392-drift-shadow-probe.sh`, 11 legs, drives the real hook with a
sandbox PROJECT_ROOT injected through the stdin `cwd` re-anchor. Live focus is
never read or written.

    pattern 1  fw task update T-9002        REACHES gate -> blocked
    pattern 3  git commit -m "T-9002: ..."  REACHES gate -> blocked
    pattern 2  fw context add-* --task T-9002   SHADOWED -> allowed (rc=0)

Leg 0 is an anti-vacuity control and it is the reason the rest counts: it
requires the block message to NAME BOTH fixture ids (T-9001 focused, T-9002
targeted). If the re-anchor silently no-opped, the hook would read the live
focus and every leg below would describe the real repo while looking identical
to a green run — the fixture-invisible failure mode from T-381. The probe exits
**3** (not 1) in that case, because "measured nothing" and "measured a defect"
are different outcomes and collapsing them is the very defect this task is about.

Also confirmed by the same run: the T-390 deadlock stays fixed (null focus still
allows `note`, `handover`, and `context add-*` with no `--task`), and no
over-correction (`doctor`, `git status`, `ls -la`, `context status` still exit
early without consulting focus). Those are the two rows a repair could plausibly
break, measured before any repair exists.

### 2026-08-08 — why this is a regression I introduced, not an inherited defect

Before T-390 the `context)` arm allowed `status|focus|init` only, so
`fw context add-*` fell through to the drift check as designed. T-390 added the
`add-*` arm and, with it, the early return. The RCA question (G-019) is not "why
did the code break" but "what let this go undetected": **one early return is
answering two independent questions** — *does this need a task* and *is this
attributed to the right task*. Exempting from the first silently exempted from
the second, and nothing reports a check that stopped being consulted.

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

### 2026-08-08T18:57:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-392-safe-list-early-return-shadows-the-focus.md
- **Context:** Initial task creation

### 2026-08-08T19:45:19Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
