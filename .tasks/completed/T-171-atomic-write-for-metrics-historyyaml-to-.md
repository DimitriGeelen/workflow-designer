---
id: T-171
name: "atomic write for metrics-history.yaml to fix push-gate race"
description: >
  atomic write for metrics-history.yaml to fix push-gate race

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
created: 2026-07-10T04:50:05Z
last_update: '2026-08-16T12:33:41Z'
date_finished: 2026-07-10T04:56:23Z
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
  - ts: '2026-08-16T12:33:41Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-171: atomic write for metrics-history.yaml to fix push-gate race

## Context

`audit.sh` writes `.context/project/metrics-history.yaml` non-atomically: `open(METRICS_FILE, "w")`
truncates the file, then writes a header and `yaml.dump()`. During that window the on-disk file is
empty/partial. Cron audits run every 30 min (`/etc/cron.d/agentic-audit-832-workflow-designer`), so a
concurrent reader — notably the T-1610 pre-push YAML gate (`agents/git/lib/hooks.sh`) which parses
every `.context/project/*.yaml` — can catch the file mid-write and fail with a parse error. This
blocked a handover push this session (empty error message = the gate's second/error-extraction pass
re-read the file after the write completed, so it found no YAMLError text). Fix: make the write atomic
(write to a temp file in the same dir, then `os.replace()` — atomic rename on POSIX).

## Acceptance Criteria

### Agent
- [x] `audit.sh` writes `metrics-history.yaml` via temp-file + `os.replace()` (no direct `open(METRICS_FILE, "w")` truncate-in-place).
- [x] The temp file is created in the same directory as the target (so `os.replace` is a same-filesystem atomic rename), and is cleaned up on write failure.
- [x] Running `fw audit` still appends a well-formed entry: the file parses and its newest `entries[-1].timestamp` is the run just performed (verified: 869→870 entries, newest `2026-07-10T04:52:01Z`).
- [x] A concurrent-read stress check does not observe a partial/empty file (verified: new atomic pattern 0/53 partial reads vs old truncate-in-place 19/24).

### Human-removed
<!-- Human section removed: fix is fully agent-verifiable. -->
<!-- ORIGINAL-HUMAN-SECTION-BELOW-STRIPPED
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

# T-171 checks:
! grep -q 'open(METRICS_FILE, "w")' .agentic-framework/agents/audit/audit.sh
grep -q 'os.replace' .agentic-framework/agents/audit/audit.sh
python3 -c "import yaml; yaml.safe_load(open('.context/project/metrics-history.yaml'))"

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

**Symptom:** `git push` (auto-handover) blocked with `Push blocked — YAML parse failure in tracked
project file(s): - metrics-history.yaml:` — and the error detail after the colon was **empty**.
Seconds later the file parsed fine.

**Root cause:** `audit.sh`'s metrics writer opens the target with `open(METRICS_FILE, "w")`, which
truncates the file in place, then writes a header and `yaml.dump()`. The write is non-atomic: for the
duration of the write the on-disk file is empty or partial. The T-1610 pre-push gate
(`agents/git/lib/hooks.sh`) parses every `.context/project/*.yaml`; a cron audit (runs every 30 min)
writing metrics-history.yaml at the same moment left the gate reading a half-written file. The empty
error message is diagnostic: the gate's first `safe_load` (into `2>/dev/null`) hit the partial file,
but its second pass — which re-opens the file to extract `e` — ran after the write completed, so it
saw a valid file and produced no YAMLError text.

**Why structurally allowed:** the T-1610 gate assumes `.context/project/*.yaml` are quiescent, but
scheduled cron audits write them concurrently with no lock coordination, and the writer uses a
truncate-in-place write instead of an atomic temp+rename. Reliability directive: a false failure with
no observable cause.

**Prevention:** atomic write (temp file in the same dir + `os.replace()`), so a concurrent reader
always sees either the complete old file or the complete new file — never a partial one. The
Verification grep guards against the truncate-in-place pattern regressing.

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

### 2026-07-10T04:50:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-171-atomic-write-for-metrics-historyyaml-to-.md
- **Context:** Initial task creation

### 2026-07-10T04:56:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
