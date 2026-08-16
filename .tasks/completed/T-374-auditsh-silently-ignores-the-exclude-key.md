---
id: T-374
name: "audit.sh silently ignores the exclude: key that fw fabric drift honors"
description: >
  T-1842 centralised fabric pattern expansion into expand_patterns.py so the exclude:
  key had one source of truth, and reached register.sh and drift.sh but not audit.sh.
  Both of audit.sh's fabric coverage blocks still inline their own expander and read
  patterns: only, dropping exclude: entirely. Measured on one config (tools/**/*.mjs
  with exclude: tools/_*): expand_patterns.py returns 1, audit's logic returns 50.
  So fw fabric drift and fw audit report different unregistered counts for the same
  watch-patterns.yaml whenever exclude: is present. This is the exact Penelope T-1458
  silent-junk class the centralisation was created to retire, surviving in the one
  call site the fix did not name. Blocks the T-344 narrowing path: the operator's
  likely REVIEW action is to narrow the watch scope, and the natural way to do that
  is exclude:.

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
created: 2026-08-08T12:18:11Z
last_update: '2026-08-16T13:57:22Z'
date_finished: 2026-08-08T12:25:07Z
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
  - ts: '2026-08-16T12:33:53Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/audit/audit.sh,.fabric/watch-patterns.yaml,tools/_t344-watch-set-denominator.sh,tools/_t352-p011-errexit-probe.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-374: audit.sh silently ignores the exclude: key that fw fabric drift honors

## Context

Found while landing T-344. `.fabric/watch-patterns.yaml` supports a top-level `exclude:`
key and a per-pattern `exclude:`. `expand_patterns.py` implements both, and `fw fabric drift`
and `fw fabric scan` go through it. Both of `audit.sh`'s fabric coverage blocks instead inline
their own loop over `patterns:` and never look at `exclude:`.

Measured, one config, `tools/**/*.mjs` with `exclude: ["tools/_*"]`:

```
candidate files:      50
expand_patterns.py:    1     <- honors exclude
audit.sh's logic:     50     <- ignores it
```

`expand_patterns.py`'s own header states the purpose: *"Centralising the expansion here means
the exclude predicate has one source of truth — the same bug class cannot recur independently
in register.sh and drift.sh again."* True, and `audit.sh` was not in the sentence. This is the
Penelope T-1458 class (5946/6339 junk cards, 22 days undetected because the bug appeared in
both code paths identically) surviving in the one call site the centralisation did not reach.

**Why it matters now rather than in principle:** T-344 left the operator a [REVIEW] decision to
narrow the fabric watch scope, and the natural way to express a narrowing is `exclude:`. Under
this bug that produces a config where `fw fabric drift` and `fw audit` report different
unregistered counts — silently, with the audit's number always the larger one.

## Acceptance Criteria

### Agent
- [x] Both `audit.sh` fabric coverage blocks obtain their file list from
      `expand_patterns.py` rather than from an inlined glob loop, so `exclude:` has one
      implementation and the two checks read the same set by construction rather than by
      coincidence.
- [x] A probe drives the real `audit.sh` over a watch config **containing** an `exclude:`
      key and requires the audit's denominator to equal `expand_patterns.py`'s. It must go
      RED against the pre-fix `audit.sh` — a config with no `exclude:` cannot distinguish the
      two implementations, so the probe's own input has to carry the discriminator.
- [x] The missing/failing-expander case is reported distinctly from the empty-watch-set case.
      Both yield zero watched files with different remedies, and collapsing them is the exact
      T-344 defect (one message for two states) reappearing in its own fix.
- [x] The audit's standing verdict is unchanged by this refactor on the current config
      (which has no `exclude:` key) — reported before and after. If the number moves, the
      refactor changed behaviour beyond exclude handling and that must be explained, not
      absorbed.

## Measurements

**The fix.** Both blocks now read `FABRIC_WATCHED`, produced by one call to
`expand_patterns.py` before either check runs. The inline glob loops are retained only as a
fallback for an install whose expander is missing, and that state is reported as its own
verdict rather than as an empty watch set.

**Probe:** `tools/_t374-audit-honors-exclude.sh`, 5/5. It drives the real `audit.sh` against a
synthetic project root whose watch config carries `exclude: ["code/_*"]` — 3 files match the
glob, 1 survives the exclude, and the single card covers that one. Honoring exclude gives
0 unregistered; ignoring it gives 2.

**Teeth**, same probe against the pre-T-374 build (`fdf7c98a`, which already has T-344):

```
  PASS  expand_patterns.py honors exclude: 3 candidates -> 1 watched
  PASS  fixture discriminates: 3 files match the glob, 1 survive exclude
  FAIL  audit reports 2 unregistered, expander says 0 — audit IGNORED exclude:.
  FAIL  sibling drift check reports unregistered files: [WARN] Fabric drift: 2 source file(s)...
  FAIL  missing expander produced neither message; output did not match either arm
  2 passed, 6 failed
```

Legs 1–2 stay green and legs 3–5 go red, which is the split that makes the run readable: the
reference implementation and the fixture's discriminating power are *preconditions*, not
findings. Leg 2 exists because an `exclude:` that removes nothing would let legs 3–4 pass
against both builds — the probe would then be measuring a config, not an implementation.

**AC4 — standing verdict unchanged.** This repo's `watch-patterns.yaml` has no `exclude:` key,
so the refactor must be a no-op here, and is:

```
BEFORE (T-344)   Pass: 17  Warn: 3  Fail: 0   Fabric: 17 registered, 133 unregistered (of 147 watched)
AFTER  (T-374)   Pass: 17  Warn: 3  Fail: 0   Fabric: 17 registered, 133 unregistered (of 147 watched)
```

A no-op is the correct result and also the weakest possible evidence — it is what a refactor
that did nothing at all would produce. The claim that anything changed rests entirely on the
teeth run above, over a config this repo does not have.

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

# The audit must honor exclude: on a config that HAS one. Synthetic root; goes
# red against the pre-fix build (2 unregistered where the expander says 0).
bash tools/_t374-audit-honors-exclude.sh

# T-344's guard must still hold — this refactor rewrote the code path it asserts.
bash tools/_t344-watch-set-denominator.sh

# The block-1 python lives inside a double-quoted bash string; a stray backtick
# or double quote there is a bash syntax error, not a python one (T-344).
bash -n .agentic-framework/agents/audit/audit.sh

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
**Symptom:** `fw fabric drift` and `fw audit` report different unregistered counts for the
same `.fabric/watch-patterns.yaml` whenever an `exclude:` key is present — measured 1 vs 50.

**Root cause:** both `audit.sh` fabric blocks inlined their own expansion over `patterns:` and
never read `exclude:`. `expand_patterns.py` is the shared implementation and they did not call
it.

**Why structurally allowed:** T-1842 created `expand_patterns.py` to give the exclude predicate
one source of truth, and enumerated its call sites as "register.sh and drift.sh". `audit.sh`
was a third consumer that nobody listed, so the centralisation's own success criterion could be
fully met while a third copy survived. The divergence is also invisible in the common case: a
config without `exclude:` makes the two implementations identical, so the bug is dormant until
someone uses the feature — and it fires silently, since both numbers look plausible.

**Prevention:** the file list is computed once and shared, so the two checks cannot disagree
about a set they read from the same variable — the class is removed rather than the instance
repaired. `tools/_t374-audit-honors-exclude.sh` pins it with a fixture that carries an
`exclude:` key, because a fixture without one cannot fail.

<!-- template guidance retained below
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

### 2026-08-08T12:18:11Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-374-auditsh-silently-ignores-the-exclude-key.md
- **Context:** Initial task creation

### 2026-08-08T12:18:59Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-97884102
- **Timestamp:** 2026-08-08T12:25:19Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T12:25:07Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
