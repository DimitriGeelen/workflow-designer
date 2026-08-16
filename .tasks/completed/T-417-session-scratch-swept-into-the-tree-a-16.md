---
id: T-417
name: "Session scratch swept into the tree: a 1.6MB rail dump under .context/working/
  was auto-committed (third instance of the T-222/T-410 shape)"
description: >
  Session scratch swept into the tree: a 1.6MB rail dump under .context/working/ was
  auto-committed (third instance of the T-222/T-410 shape)

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
created: 2026-08-09T15:41:22Z
last_update: '2026-08-16T14:33:35Z'
date_finished: 2026-08-09T15:43:26Z
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
  - ts: '2026-08-16T12:33:57Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:35Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F2=0 (no-signal); F4=0 (no-signal); F3=4 
      (prose:seam-fixture-or-pin); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/_t413-land-fixtures.py,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:55Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:tools/_t413-land-fixtures.py); tier=2 
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-417: Session scratch swept into the tree: a 1.6MB rail dump under .context/working/ was auto-committed (third instance of the T-222/T-410 shape)

## Context

T-413 needed the rail's raw envelopes to decode two `payload_b64` fixtures. The termlink CLI
was used to dump the whole DM topic to a file so 32K characters of base64 never entered the
agent's context — a good call. The file was written to `.context/working/t413/rail-state.json`,
which is **inside a tracked directory**, and the checkpoint handover's bulk add swept it into
commit `23b2c500`: 1.6 MB containing every message body of a 464-message conversation, in a
repository that mirrors to GitHub.

Nothing secret is in it — it is our own correspondence — but it is a **regenerable scratch
artifact**, it is large, and nobody chose to publish it.

**Third instance of a documented shape, and the note is in the file that should have caught
it.** `.context/working/.gitignore` already says, about T-410: *"371 tracked files under
.context/working/ meant it was swept in without anyone choosing it. Second instance of the
T-222 shape directly above: an ignore file that is trusted to cover a directory while the one
entry that matters is absent."* T-222 was `.tier0-approval*`, T-410 was `.fw-secret-key`, and
this is the third — each time a new file lands in that directory and inclusion is the default.

**The agent-side error, stated plainly:** this session has a scratchpad directory for exactly
this, and the dump belonged there. Writing it under `.context/working/` put a temp file one
bulk `git add` away from publication, and that add came four minutes later. Ignoring the file
is the local repair; not writing regenerable scratch into a tracked tree is the practice.

## Acceptance Criteria

### Agent
- [x] `.context/working/t413/` untracked and the 1.6 MB blob out of the index
- [x] `.context/working/.gitignore` carries an entry for it with the reason, in the style of
      the T-222 and T-410 entries above it — that file is the register of this failure class
- [x] The ignore is verified to actually MATCH (`git check-ignore -v`), not merely present:
      an entry that does not match is precisely the T-222 defect, where the pattern lacked a
      leading dot and never fired
- [x] `tools/_t413-land-fixtures.py` takes the capture path as an argument and is re-run from
      a scratchpad-resident capture, proving the fixture path does not depend on the dump
      living in the tree
- [x] The scratch-location practice is captured as a learning, not just fixed here

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
# --- T-417 ---
# The blob is out of the index. `git ls-files` prints nothing and exits 0 either way, so the
# test is on emptiness, not on the command succeeding.
test -z "$(git ls-files .context/working/t413)"
# The ignores MATCH. T-222 was an entry that existed and never fired; presence is not the
# property being verified here.
git check-ignore -q .context/working/t413/probe.out
git check-ignore -q .context/working/t414-probe.out
# The 1.6MB dump is not in the working tree either.
test ! -e .context/working/t413/rail-state.json

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** commit `23b2c500` published `.context/working/t413/rail-state.json` — 1.6 MB,
every message body of a 464-message private conversation — into a repo that mirrors to GitHub.

**Root cause:** a regenerable scratch file was written inside a tracked directory where
inclusion is the default, and a bulk `git add -A` four minutes later swept it in. No
individual decision to publish it was ever made.

**Why structurally allowed:** `.context/working/` holds hundreds of tracked files, so its
`.gitignore` is an *opt-out* list against an *opt-in* directory. Every new working file is one
bulk add from publication, and the only thing standing between them is somebody remembering to
add a line. That is the third time: T-222 (`.tier0-approval*` — the entry existed and had no
leading dot, so it never matched), T-410 (`.fw-secret-key` — never listed), and now this.

**Prevention:**
- `t413/` and `*-probe.out` ignored, with the reason written into the file that is now the
  register of this failure class.
- Both patterns verified with `git check-ignore -v` rather than eyeballed — T-222's entry was
  *present and non-matching*, so presence is not the property that matters.
- The dump moved to the session scratchpad, and `_t413-land-fixtures.py` re-run from there to
  prove the fixture path never depended on it living in the tree.
- Learning captured: the reasoning ("keep the base64 out of context") was right; the location
  was wrong, and this session had a scratchpad for exactly that.

**Not claimed as fixed:** the directory's opt-out posture is unchanged, so a fourth instance
is available to the next person who writes a new file here. Narrowing what is tracked under
`.context/working/` is a larger change than this task, and pretending otherwise would be
mitigation dressed as prevention (G-019).

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

### 2026-08-09T15:41:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-417-session-scratch-swept-into-the-tree-a-16.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-df325fd0
- **Timestamp:** 2026-08-09T15:43:27Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#4 (Agent)** — `tools/_t413-land-fixtures.py` takes the capture path as an argument and is re-run from
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_t413-land-fixtures.py in: `tools/_t413-land-fixtures.py` takes the capture path as an argument and is re-run from`

### 2026-08-09T15:43:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
