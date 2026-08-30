---
id: T-641
name: "T-639 prober sandbox is ignored so it measures live session state"
description: >
  T-639 prober sandbox is ignored so it measures live session state

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
created: 2026-08-30T10:29:29Z
last_update: 2026-08-30T10:29:29Z
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

# T-641: T-639 prober sandbox is ignored so it measures live session state

## Context

`tools/_t639-drift-gate-reads-fixtures.sh` writes a `focus.yaml` into a scratchpad
sandbox and passes that directory as the hook's stdin `cwd`. The hook re-anchors via
`fw_reanchor_from_cwd` (`.agentic-framework/lib/paths.sh:98`), which walks UP from
`cwd` looking for `.framework.yaml` or a `.tasks/` directory. The sandbox has
neither, so the walk finds nothing, the function returns 0 having changed nothing,
and the hook reads the **real** `.context/working/focus.yaml`. The sandbox is inert
— silently, with no error.

Two consequences, both observed:

1. **The prober measured live session state.** It was committed green at 16/16 while
   the session's focus happened to be T-639. With no code change whatsoever it is now
   13/16, because focus moved to T-640. All three failures are the harness, not the
   T-639 fix.
2. **OBS-328 named the wrong marker.** It says `.git`. The marker is `.tasks/` (or
   `.framework.yaml`). A remedy written from that note would not have worked, and the
   same note was posted to the peer rail at @826 with the blast radius overstated as
   "every hook prober" — measured here as exactly one.

The generalizable defect is that the prober never asserted its own fixture took
hold. A sandbox that silently degrades to live state is a false-green generator, so
the fix is not just "add the marker" but "prove the marker worked, every run".

## Acceptance Criteria

### Agent
- [x] The sandbox carries a `.tasks/` marker and a fixture task file, so
      `fw_reanchor_from_cwd` re-anchors and the focused task resolves inside it
- [x] The focus id is synthetic (not a live task id), so completing a real task
      cannot invalidate the prober a second time
- [x] A self-validation leg asserts the sandbox is actually in effect, by asserting
      the verdict INVERTS against the real focus — this leg must fail if the marker
      is removed
- [x] Removing the `.tasks/` marker makes that leg go red (its teeth are shown, not
      assumed)
- [x] `tools/_t639-drift-gate-reads-fixtures.sh` passes all legs, and passes when the
      live focus is some *other* task
- [x] The audit of which probers share this defect is recorded in the task, with the
      sound ones distinguished from the affected one by reason, not by count
- [x] OBS-328 is corrected in place (marker and blast radius), and the correction is
      posted to the rail where the overstatement was posted

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

## Audit — which probers share this defect

Measured, not assumed. Fourteen files build a `focus.yaml` and feed a `cwd` to a hook.
They fall into three groups, and the group boundary is a *reason*, not a count:

| Group | Files | Verdict |
|---|---|---|
| Sandbox + `.tasks/` marker, testing the **no-active-task** path | `_t381`, `_t385`, `_t386`, `_t390`, `_t632`, `_t636`, `_t638` | **Sound.** An empty `.tasks/` is the correct fixture for "no active task", and the marker means the sandbox genuinely governs. |
| Sandbox + marker + fixture task file, testing the **focused** path | `_t392` (×2), `_t628` (×1), `_t629` (×3) | **Sound.** Both halves present. |
| Deliberately mutates the **real** focus under a snapshot/restore trap | `t404-gate-e2e.sh` | **Not this class.** A declared design, documented at its head; it never claims to be sandboxed. |
| No marker at all | `_t639` | **Affected — the only one.** |

So the blast radius is exactly one prober. The rail post at @826 said "a false-green
generator for every hook prober"; that was an overstatement of the same shape as the
5-vs-3 miscount inside T-639 itself, and it is corrected here and on the rail.

## RCA

Three distinct errors, only one of which was in the code:

1. **The sandbox was never in effect.** No `.tasks/` marker, so `fw_reanchor_from_cwd`
   found no project root and returned 0 unchanged. Silent no-op, not an error.
2. **OBS-328 named `.git` as the marker.** It is `.tasks/` or `.framework.yaml`. A
   remedy written from that note would not have worked. Corrected in place.
3. **The prober never asserted its own fixture took hold** — the generalizable defect.
   It could not distinguish "fixture honoured" from "live state happened to agree",
   which is precisely how it shipped green at 16/16 and silently decayed to 13/16.

The fix for (3) is an inversion, not a spot-check: the sandbox's synthetic focus must
be allowed AND the session's live focus must be blocked. No single accident makes both
hold, so the leg cannot pass while inert.

**Also re-encountered: G-037**, the registered instrument-substitution gap. A
throwaway check-line of mine printed `MUTATION FAILED` while the mutation had in fact
applied, because the agent shell's `grep` is ugrep 7.8.4, which anchors on a
mid-pattern `$` where GNU grep takes it literally. The gap is open and known; this is
one more incident, and notably `fw work-on` surfaced PL-199 — *"a limit I had written
down that morning did not reach me that afternoon"* — at the moment this task was
created. Documentation-as-mitigation did not reach the point of use. No new gap filed;
G-037 already says this, and re-filing it would inflate the register rather than the
prevention. The safe idiom when grepping for literal shell source is `grep -F` or an
escaped `\$`.

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
bash tools/_t639-drift-gate-reads-fixtures.sh
# the sandbox must be self-asserting: strip the marker and the inversion leg must go red
bash -c 'S=$(mktemp -d); sed "s#mkdir -p \"\$SANDBOX/.context/working\" \"\$SANDBOX/.tasks/active\"#mkdir -p \"\$SANDBOX/.context/working\"#" tools/_t639-drift-gate-reads-fixtures.sh > "$S/n.sh"; bash "$S/n.sh" 2>&1 | grep -qF "SANDBOX INERT"; rc=$?; rm -rf "$S"; exit $rc'
# the T-639 fix it guards is still pinned by the corpus
python3 -m pytest .agentic-framework/web/test_safe_commands.py -q 2>&1 | tail -1
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

### 2026-08-30T10:29:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-641-t-639-prober-sandbox-is-ignored-so-it-me.md
- **Context:** Initial task creation
