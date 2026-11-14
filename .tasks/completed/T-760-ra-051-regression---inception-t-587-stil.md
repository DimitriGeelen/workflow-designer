---
id: T-760
name: "RA-051: REGRESSION - inception T-587 still has no research artifact after RA-011
  closed"
description: >
  Complete 19-section audit reports [WARN] Inception task T-587 has no research artifact
  in docs/reports/. RA-011 (T-707) was created for this exact finding and is work-completed.

status: work-completed
workflow_type: build
current_node: frw_end_task
owner: agent
horizon: null
tags: [audit-remediation, cycle-2]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T08:47:48Z
last_update: 2026-11-14T14:24:31Z
date_finished: 2026-11-14T14:24:31Z
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
  - ts: '2026-09-21T08:49:30Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F2=0 
      (no-signal); F4=0 (no-signal); F3=1 (prose:AEF seam-incidental); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-26T09:06:29Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: 'D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); D4=2
      (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F2=0 (no-signal);
      F4=0 (L0: no signal); F3=0 (L0: no signal); F1=1 (L1:keyword=designer,L1:keyword=bpmn)'
    rubric_sha: e4a00f38e801
  - ts: '2026-11-14T14:20:47Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 0
      D3: 0
      D4: 1
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: 'D1=2 (body:learning-ref); D2=0 (no-signal); D3=0 (no-signal); D4=1
      (body:hard-coded-removed); F-RECALL=2 (body:lightly-promoted); F2=0 (no-signal);
      F4=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F3=0 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L0: no signal); F1=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T08:49:30Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
      blast_radius: 1
    rationale: blast_radius=1 
      (paths:docs/research/executable-workflow/reflection-designer.md); tier=2 
      (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-760: RA-051: REGRESSION - inception T-587 still has no research artifact after RA-011 closed

## Context

**Background / trigger:** the residue audit (RA-051) warned that inception T-587 has no research document under
`docs/reports/`, although its research exists under `docs/research/executable-workflow/`.
**Problem / hypothesis:** the check looked only in `docs/reports/`, so research kept elsewhere by this project's own
convention read as missing.
**Goal:** establish where the check looks today, whether `docs/research/` is a legitimate home, and how often the
check has been wrong.
**Expected outcome:** the check passes for T-587, or its defect is recorded with evidence; nothing is moved to please it.

### Correction: this task's NAME says REGRESSION. That is wrong.

It was created under that label because the finding re-appeared after a task had
closed on it, which is the regression shape. Reading what those tasks actually did
shows it is not. The name is left as created rather than quietly rewritten — a task
id that changes meaning silently is worse than one that carries its own correction.

### Verbatim tool output

```
[WARN] Inception task T-587 has no research artifact in docs/reports/
```

### The invariant that is not held

This one is simpler than its sibling and worse for the check. **T-587's research
artifact exists.** RA-011 (T-707) located it and recorded path and size:

> `docs/research/executable-workflow/reflection-designer.md`, 19,876 bytes,
> dated 2026-08-25 — with three further T-587 research documents beside it:
> `operating-digest.md`, `designer-contract-inventory.md`,
> `questions-and-dispositions.md`

Four research documents, ~20KB in the principal one. T-707 additionally measured
every section of T-587 as filled and confirmed zero `@auto-tick-on-decide` markers,
distinguishing it from the genuinely-empty inceptions T-015 and T-103.

The check reports the artifact missing because it looks **only in `docs/reports/`**,
and this project keeps research under `docs/research/`. The invariant that is not
held is the check's: it has a hardcoded directory standing in for the question it
claims to answer. This is not a marginal false positive — it is a check reporting
the absence of a 19,876-byte document that is in the repository.

### Root-cause links

Predecessor: RA-011/T-707 (work-completed; it FOUND the artifact). Sibling instance: RA-050/T-759 (T-250), same check, different reason — there the record is in the task file by ruling; here it is simply in another directory.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The check's search path is established from its implementation, and whether `docs/research/` is a legitimate location for inception research in this project is answered from the repo's own convention rather than assumed.
- [x] Either the check searches wherever this project actually keeps research, or the project's convention is stated and the check is corrected to match it. The artifact is NOT moved to satisfy a hardcoded path — that would be relocating 20KB of real work to please a grep.
- [x] The false-positive rate of this check is stated: of the instances it has reported, how many were genuinely missing (T-015, T-103) versus present-elsewhere (T-587) versus ruled-not-required (T-250). A check that is wrong more often than right on a known population is a different problem from one that is occasionally wrong.
- [x] The originating check reports PASS on re-run for T-587, or the reason it cannot is recorded as a defect of the check with the evidence above.

**Evidence (2026-11-14):**
1. *Search path, from the implementation:* `audit.sh` section "research" (line ~6853) warns for each id in
   `missing_research` from `agents/audit/completed-task-scan.py <tasks> <episodic> <reports_dir>`, whose reports dir is
   `docs/reports/`. Since the framework's T-3569 the scan also accepts an inception whose own task record carries the
   research (`lib/research_preserved.py`); those go to `research_in_task_record`, not `missing_research`. It does not
   search `docs/research/`. *Convention:* this project's CLAUDE.md (Inception Discipline, C-001) puts inception
   research at `docs/reports/T-XXX-*.md`; `docs/research/executable-workflow/` is the EWCR source packet T-587
   ingested, not a second home for inception research.
2. *Match without moving anything:* nothing was moved; the check was not changed by 832. T-587 now passes through the
   task-record rule (there is no `docs/reports/*587*`), which is where its exploration is recorded.
3. *False-positive rate on the known population:* of the 4 instances it reported (T-015, T-103, T-587, T-250), 2 were
   genuinely missing and 2 were wrong (T-587 present elsewhere, T-250 ruled not required): wrong half the time on that
   population. Both wrong cases now pass.
4. *Re-run:* `fw audit --section research` at ~13:40 CET: `[PASS] All completed inceptions have research artifacts —
   examined 64 completed inception(s)`.

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

test -f docs/research/executable-workflow/reflection-designer.md
test "$(stat -c %s docs/research/executable-workflow/reflection-designer.md)" -gt 19000

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

**Symptom:** the audit warned that inception T-587 had no research artifact, although its research exists.
**Root cause:** the scan treated one folder (`docs/reports/`) as the only proof of research and could not see research
kept in the task record (or elsewhere).
**Why structurally allowed:** location was used as a proxy for existence, with no way to recognise another record.
(Not a regression: the name says so, the Context corrects it.)
**Prevention:** the framework's T-3569 (`lib/research_preserved.py`) now accepts research in the inception's own
record, shared by both scans; the re-run passes on all 64 completed inceptions.

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

### 2026-11-14 — the framework fixed the check upstream
- **What changed:** AEF's T-3569 taught the scan to accept research kept in the inception's own task record; T-587
  and T-250 both pass now, with nothing moved and no exemption needed.
- **Plan impact:** no 832 change; SQ-4 exemptions (T-769) are no longer needed for these two.
- **Triggered:** a correction note on T-759, which said the T-250 warning would remain until T-769.

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
     fw inception decide T-760 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T08:47:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-760-ra-051-regression---inception-t-587-stil.md
- **Context:** Initial task creation

### 2026-11-14T14:20:41Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-11-14T14:24:31Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e304a37e
- **Timestamp:** 2026-11-14T14:24:34Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** none
