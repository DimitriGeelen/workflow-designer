---
id: T-821
name: "Failures become evidence: a fault recorder and an operator-visible surface (F-05)"
description: >
  Failures become evidence: a fault recorder and an operator-visible surface (F-05)

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
created: 2026-09-22T16:36:58Z
last_update: 2026-09-22T16:36:58Z
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

# T-821: Failures become evidence: a fault recorder and an operator-visible surface (F-05)

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `aefRecordFault(code, detail)` exists and CANNOT THROW under any input — it is called only from inside `catch` blocks whose contract is "never break the editor", so a recorder that can throw converts a silent failure into a broken editor, which is strictly worse than the silence it replaces
- [x] It is declared ABOVE its earliest call site (module top level, ~line 2345). A recorder placed beside `APP_VERSION` would put every top-level caller in the temporal dead zone
- [x] A bounded ring (no unbounded growth) persisted to `localStorage`, with the quota case explicitly handled: when the fault BEING recorded is localStorage refusing writes, the in-memory record still stands
- [x] An operator-visible surface: an indicator that is ABSENT when there are no faults and appears when there are, opening a panel that lists each fault with code, detail, time and build
- [x] The meaningful swallowed sites are instrumented — clipboard write, autosave persist, autosave restore, prefs persist, prefs restore, annotation seam, workflow parse, save-to-project
- [x] CENSUS (PL-288: a chosen-set assertion cannot find what you forgot to choose): every `catch (_)` in `src/` is enumerated and must be either INSTRUMENTED or carry an EXPLICIT written excuse. The remainder fails. My hand-picked list of sites is exactly the thing that cannot audit itself
- [x] CONTROL: the recorder is proven to RECORD (a forced fault appears), the indicator proven to APPEAR only then, the recorder proven NOT TO THROW on hostile input, and the census proven to DISCRIMINATE (a new bare catch makes it red)
- [x] Visual verification: element-level screenshots of the indicator present and absent, in light and dark, READ — not DOM-measured (CLAUDE.md §Visual Verification)
- [x] The usage histogram (§8 item 3, the other half of F-05/F-18) is FILED as its own task, not built here — one task, one deliverable

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
         1. Run `bin/fw reviewer T-821`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-821 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ---- T-821 legs -------------------------------------------------------------
# 1. THE RATCHET. Every catch in src/ is instrumented or carries a written excuse with an
#    exact site count. This is the PL-288 leg: my hand-picked list of instrumented sites is
#    precisely the thing that cannot audit itself.
python3 tools/_t821-swallowed-failure-census.py > /tmp/.t821-census.out 2>&1
# 2. THE SURFACE. Records / shows / survives a reload / cannot throw, plus one end-to-end
#    leg that breaks navigator.clipboard and presses the real Copy button — the recorder and
#    the WIRING are different claims, and T-818 is what happens when only the first is held.
node tools/_t821-fault-surface-cdp.mjs > /tmp/.t821-surface.out 2>&1
# 3. THE CENSUS'S TEETH. New bare catch, de-instrumented site, extra copy of an excused
#    pattern, and a catch inside a COMMENT that must NOT count. 5 branches.
bash tools/_t821-census-controls.sh > /tmp/.t821-ctl.out 2>&1
# 4. All three wired with LITERAL tools/<name> paths — _t451's edge detector matches the
#    literal string, so a composed path runs the tool while the wiring census cannot see it.
grep -q 'tools/_t821-swallowed-failure-census.py' tests/run-bridge-tests.sh && grep -q 'tools/_t821-fault-surface-cdp.mjs' tests/run-bridge-tests.sh && grep -q 'tools/_t821-census-controls.sh' tests/run-bridge-tests.sh
# 5. SMOKE. 31 call sites in the editor changed. This drives a full real save end to end, so
#    a syntax or init-order mistake anywhere in them fails here rather than in front of the
#    operator. Cheap (~2s) and it is the only leg that exercises the file as a whole.
node tools/_saveproject-verify-cdp.mjs > /tmp/.t821-smoke.out 2>&1
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

## Visual Verification

Element-level screenshots at deviceScaleFactor 3, clipped to `.brand`, READ with the Read
tool rather than measured. The editor has a single theme (no `data-theme`, no
`prefers-color-scheme`), so the modes that vary are fault count and the panel — not palette.

| shot | what it showed |
|---|---|
| `shot-1-clean` | no badge at all beside `v0.12.0`. Absence is the healthy state and it holds. |
| `shot-2-one-fault` | **DEFECT FOUND.** The badge wrapped: `⚠` above `1`, double the height of the version pill beside it. |
| `shot-3-twelve-faults` | same wrap at `12`. Fixed with `inline-flex` + `nowrap`; re-shot and now one line, matching the pill's height. |
| `shot-4-panel` | **SECOND DEFECT FOUND.** Twelve identical `prefs-persist:view` rows filled the panel. A quota error fires on every preference write, so a 50-slot ring would have evicted every other condition — a record that evicts the evidence is not evidence. Fixed by coalescing repeats into one row with `×n (last)`; re-shot, twelve occurrences now read as two rows. |

Both defects were invisible to DOM geometry, which was correct throughout. The second was
not a styling problem at all — reading the render exposed a data-retention flaw in the ring.

## Decisions

### 2026-09-22 — instrument 31 of 70 catch sites, excuse 39, and make the split auditable

- **Chose:** instrument where the operator LOSES something or is MISLED; excuse the rest
  with a written reason and an exact site count; enforce the split with a census.
- **Why:** the two failure modes are opposite and both real. Instrumenting everything would
  put a permanent badge on a healthy editor — `getBBox` throws on every headless render —
  and OBS-293 records what a permanently-lit indicator teaches: to stop looking. Reporting
  nothing is where we started. The line is whether a human lost work or was shown something
  false: an empty list after a failed fetch is indistinguishable from "there is nothing",
  which is the worst case in the file and is now recorded.
- **Rejected:** a blanket rule either way. Also rejected: keeping the chosen set in my head,
  which is exactly PL-288's hole — the census is the answer to my own judgement, not a
  supplement to it.

### 2026-09-22 — an excuse carries a COUNT, not just a reason

- **Chose:** each excuse is keyed to a source line AND the number of sites it may cover.
- **Why:** a reason is a claim about the sites that existed when it was written. Without the
  count, adding a fifth copy of an excused one-liner inherits an excuse nobody wrote for it,
  and the list rots from a record of decisions into a blindfold.
- **Evidence it was needed:** the count check fired on its FIRST run — my fullscreen excuse
  said one site and the file has two.

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
     fw inception decide T-821 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T16:36:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-821-failures-become-evidence-a-fault-recorde.md
- **Context:** Initial task creation
