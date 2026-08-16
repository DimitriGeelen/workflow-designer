---
id: T-409
name: "verification-hygiene baseline keys on relpath, so completing a grandfathered
  task fires a false red"
description: >
  T-408's baseline records .tasks/active/T-102-....md. work-completed moves the file
  to .tasks/completed/, so its grandfathered carrier reappears at a path the baseline
  has never seen and the ratchet reports it as a NEW carrier — a red naming a task
  nobody edited. Three known carriers sit in active/ today (T-093, T-102, T-105) and
  all three are queued for exactly that move. Key the baseline on task-file identity
  (basename) instead of lifecycle location.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-09T10:54:48Z
last_update: '2026-08-16T12:33:56Z'
date_finished: 2026-08-09T10:57:46Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-409: verification-hygiene baseline keys on relpath, so completing a grandfathered task fires a false red

## Context

T-408 baselined the G-015 carrier population keyed on the task file's **relpath**,
e.g. `.tasks/active/T-102-mapmessiness-false-positive-branch-stack.md`. But
`fw task update --status work-completed` **moves the file to `.tasks/completed/`**.
The carrier then appears at a path the baseline has never seen, so the ratchet
reports it as a NEW carrier and goes red about a task nobody edited.

This is not hypothetical: **all three** remaining active carriers (T-093, T-102,
T-105) are queued for exactly that move — they are the tasks waiting on G-015's
leg-1 ruling. The first one to close would have fired a false red, and per T-399's
finding, *a red naming a file always reads as "this file is broken", never as "the
check misidentified whose file this is"*. Worse, it would fire precisely when the
operator finally acted, making the ratchet look like it was punishing the fix.

**Root shape (PL-083):** the key pinned a CURRENT pointer (where the file lives in
its lifecycle) as a stand-in for IDENTITY (which task it is). Directory membership
is lifecycle state and moves by design; the task is the same task either side of
the move. Same lesson as T-399, where scope had to key on the ledger PATH while
exemption keyed on the SHA — the moving property must not be the one carrying identity.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The baseline is keyed on task-file **identity** (basename), not on `active/` vs `completed/` location; a grandfathered carrier that moves between the two still resolves to its baseline entry — `scan()` keys on `os.path.basename`, carrying `where` for reporting only
- [x] A teeth leg proves the move case directly: grandfather a carrier in `active/`, move the file to `completed/` exactly as `work-completed` does, and require rc=0 with NO false red and NO spurious `RATCHET AVAILABLE` notice for that file — leg (g); the no-notice half matters because a spurious notice would invite `--tighten`, which would then drop a still-present carrier
- [x] The ratchet still fires on a genuinely new carrier after the key change (teeth (a)/(b) still red) — narrowing the key must not widen the exemption — (a) (b) (b2) all still rc=1
- [x] Two task files sharing a basename across `active/` and `completed/` cannot silently launder a carrier: the scan detects the collision and fails rather than treating one as the other — leg (g2), rc=2 COLLISION
- [x] The existing baseline is migrated in place; `verification-hygiene.py` exits 0 on the real tree and `--census` still reads `serve-root-diff=75` / `hardcoded-port=17` (no existing verification line edited — leg 1 remains the operator's)
- [x] Full T-408 teeth suite still green end-to-end after the change — 12/12 legs (was 10/10; +g, +g2)

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
#
# NOTE: carries neither G-015 shape — no serve-root diff, no port literal (T-350 AC8).
python3 tools/verification-hygiene.py
bash tools/_t408-hygiene-teeth.sh
# The regression itself: a grandfathered carrier that moves active/ -> completed/ must not
# go red. Asserted by name so this line cannot pass on some other leg's green.
out=$(bash tools/_t408-hygiene-teeth.sh 2>&1); echo "$out" | grep -q "(g) grandfathered carrier survives"
out=$(bash tools/_t408-hygiene-teeth.sh 2>&1); echo "$out" | grep -q "(g2) basename in both"
# Leg 1 still untouched.
out=$(python3 tools/verification-hygiene.py --census 2>&1); echo "$out" | grep -q "serve-root-diff=75"
out=$(python3 tools/verification-hygiene.py --census 2>&1); echo "$out" | grep -q "hardcoded-port=17"

## RCA

**Symptom:** a grandfathered G-015 carrier goes red the moment its task is
completed. Reproduced before fixing: baseline a carrier in `.tasks/active/`, `mv`
the file to `.tasks/completed/` exactly as `work-completed` does, and the scan
exits 1 reporting `.tasks/completed/T-950-grandfathered.md` as a NEW carrier —
while, in the same output, correctly diagnosing the old path as *"moved by
work-completed?"*. It knew and went red anyway.

**Root cause:** the baseline key was the task file's relpath. Directory membership
under `.tasks/` is **lifecycle state** — it changes by design at completion — so the
key encoded *where the task currently is* rather than *which task it is* (PL-083:
pinning a CURRENT pointer as a stand-in for identity).

**Why structurally allowed:** T-408's teeth had ten legs and none of them moved a
file. Every mutation case edited content in place, because the defect I was hunting
was content-shaped (a new carrier line). The lifecycle operation that the framework
performs on every single task was not in the test vocabulary at all — the harness
was thorough about the axis I was thinking on and blind to the one I wasn't.

**Why it mattered more than a routine false positive:** the three files affected are
exactly T-093, T-102 and T-105 — the tasks *waiting on G-015's leg-1 ruling*. The
red would have fired the instant the operator acted, so the guard would have looked
like it was punishing the very fix it exists to make possible. And per T-399, a red
naming a file always reads as "this file is broken", never as "the check
misidentified whose file this is".

**Prevention:** teeth leg (g) performs the real move and requires rc=0 *and* no
stale notice; leg (g2) covers the one way basename keying could launder a carrier
(same basename in both directories → rc=2 COLLISION). Presence is now decided by
what the scan finds, not by testing a stored path on disk.

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

### 2026-08-09T10:54:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-409-verification-hygiene-baseline-keys-on-re.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1d651aca
- **Timestamp:** 2026-08-09T10:58:00Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T10:57:46Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
