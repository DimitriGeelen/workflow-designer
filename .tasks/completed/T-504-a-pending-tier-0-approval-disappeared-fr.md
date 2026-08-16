---
id: T-504
name: "A pending Tier 0 approval disappeared from disk unactioned — find out what
  removed it"
description: >
  A pending Tier 0 approval disappeared from disk unactioned — find out what removed
  it

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
created: 2026-08-14T19:41:01Z
last_update: '2026-08-16T12:34:04Z'
date_finished: 2026-08-14T19:43:53Z
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
  - ts: '2026-08-16T12:34:04Z'
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

# T-504: A pending Tier 0 approval disappeared from disk unactioned — find out what removed it

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The mechanism that removed `.context/approvals/pending-c9b81f71ff18.yaml` is
      identified by file and line**, or its absence is established — if nothing in the
      tree deletes pending approvals, that is the finding, and the removal came from
      outside the framework (operator action, editor, cron on the host).
- [x] **Whether the removal is silent is answered explicitly.** A pending Tier 0 approval
      is a question put to the operator. If it can vanish without a log line, a
      notification, or a trace, then the operator can be asked for authorisation and never
      learn the question was withdrawn — and the requesting agent cannot tell "denied"
      from "never seen".
- [x] **The state of T-501 is reported accurately** — whether it still needs an operator
      decision, and whether the approval must be re-requested. I do not re-request it and
      I do not run `fw inception decide` under any circumstances: two independent gates
      forbid it and the decision is the operator's alone.
- [x] **No approval file is recreated, restored, or edited by me.** If the file should
      come back, that is the operator's call — silently restoring a sovereignty artefact
      would be indistinguishable from forging one.

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

# The sweep is still in the vendored source (this task reports it, does not patch it), and
# it is still silent. Both pinned so a future reader cannot mistake "reported" for "fixed":
# if AEF changes either, these lines fail and the task's claims get re-read.
grep -q "STALE_AGE=7200" .agentic-framework/agents/context/checkpoint.sh
grep -q "OBS-246" .context/inbox.yaml

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

### 2026-08-14 — a Tier 0 question put to the operator expires in two hours, silently

- **What changed:** Found the mechanism. `.agentic-framework/agents/context/checkpoint.sh:355-364`,
  reached from the PostToolUse hook:

  ```sh
  # --- Stale pending cleanup (Gap 3 from T-636 research) ---
  # Remove pending files older than 2 hours
  STALE_AGE=7200
  for pending in "$APPROVALS_DIR"/pending-*.yaml; do
      file_age=$(( $(date +%s) - $(stat -c %Y "$pending" ...) ))
      if [ "$file_age" -gt "$STALE_AGE" ]; then
          rm -f "$pending"
      fi
  done
  ```

  Timeline, all measured: the file recorded `timestamp: '2026-08-14T17:00:08Z'` and carried
  `command_preview: fw inception decide T-501 go --rationale "..."`. Two hours later the
  next checkpoint pass deleted it — `.context/approvals/` mtime 21:07 local = 19:07Z. It
  survived exactly its TTL and not a minute more.

- **The silence is the finding, not the TTL.** Thirty lines above the sweep, the
  approval-GRANTED branch prints a framed `APPROVAL READY — Human approved in Watchtower`
  block and appends to a notified-file so it is not announced twice. The EXPIRED path does
  none of that: no stdout, no `fw_notify`, no entry in `.gate-bypass-log.yaml`, nothing in
  `.context/working/`. Verified by grep across the working dir and logs — the only
  approvals traffic recorded is Watchtower's `/approvals/content` poll, once a minute,
  which will now simply render one fewer row.

  So an agent that asked for authorisation cannot distinguish **denied** from **expired**
  from **never seen**, and the operator cannot distinguish a question they declined from
  one that was withdrawn while they were away from the terminal. A Tier 0 approval is the
  sovereignty boundary in file form; this is the one artefact in the system whose
  disappearance should never be inferable only from its absence.

- **Fit, not correctness:** a 2-hour TTL is defensible for what the queue was built for —
  a blocked *shell command*, whose session is gone long before then, and whose grant is
  itself only valid for `TIER0_WATCHTOWER_TTL=3600` (check-tier0.sh:274). It fits an
  **inception GO decision** badly: that decision is not tied to a live session, it is not
  more dangerous for being decided tomorrow, and the operator has no way to know a request
  was ever made if they were not at the terminal inside the window.

- **Triggered:** OBS-246. Not patched — `checkpoint.sh` is vendored AEF code and changing
  approval-queue lifetime is a governance change for every consuming project, so it is
  AEF's call under G-008. Reported to them on the rail.

- **T-501 is unchanged and still needs the operator.** No decision was recorded — the
  request was withdrawn, not answered. I did not re-request it, did not recreate the file,
  and will not run `fw inception decide` under any circumstances.

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

### 2026-08-14T19:41:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-504-a-pending-tier-0-approval-disappeared-fr.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-71a3383a
- **Timestamp:** 2026-08-14T19:43:53Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Agent)** — **The mechanism that removed `.context/approvals/pending-c9b81f71ff18.yaml` is
  - **AC-verify-mismatch** (narrow, heuristic) — `path=context/approvals/pending-c9b81f71ff18.yaml in: **The mechanism that removed `.context/approvals/pending-c9b81f71ff18.yaml` is`

### 2026-08-14T19:43:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
