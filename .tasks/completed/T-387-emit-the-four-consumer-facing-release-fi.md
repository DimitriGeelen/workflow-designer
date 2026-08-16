---
id: T-387
name: "Emit the four consumer-facing release fields AEF asked for in dist/MANIFEST.yaml
  (G-024 consumer half)"
description: >
  AEF answered the manifest-shape question at rail 464: version, released (ISO8601
  UTC at cut), src_commit, supersedes — none derived from the others — so they can
  compute build lag and adoption lag from their own seat and drop the vendored-pin
  read. Emit them at cut, preserving released across idempotent re-runs, and backfill
  0.8.0.

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
created: 2026-08-08T17:15:17Z
last_update: '2026-08-16T14:33:33Z'
date_finished: 2026-08-08T17:22:50Z
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
  - ts: '2026-08-16T12:33:54Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 1
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=1 (body:log-or-error-line); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:33Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 1
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 3
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=1 (body:log-or-error-line); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=3 
      (prose:seam-consumer-defect); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:dist/MANIFEST.yaml,scripts/release-designer.sh,tools/_t352-p011-errexit-probe.sh,tools/_t382-release-lag.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-387: Emit the four consumer-facing release fields AEF asked for in dist/MANIFEST.yaml (G-024 consumer half)

## Context

AEF answered the manifest-shape question at rail 464 with four fields — `version`,
`released` (ISO8601 UTC at cut), `src_commit`, `supersedes` — none derived from the
others. `released` lets them compute how old what they hold is; `src_commit` lets them
compute BUILD lag against our src themselves rather than taking our word for it;
`supersedes` gives a chain so "I am 1 behind" and "I skipped 4" stop being the same
number.

**The fifth thing they asked for already exists, and I am not building it.** They asked
for "one fetchable pointer OUTSIDE the versioned artifact — dist/LATEST.yaml, **or the
manifest published at a stable path**". `dist/MANIFEST.yaml` IS that: a stable path,
overwritten on every cut, not shipped inside any versioned artifact. Their premise —
"a manifest shipped inside a release is necessarily silent about its own successor" —
is true of a manifest that ships inside the release, and ours does not. Adding a second
file with identical properties would duplicate the mechanism without adding a capability,
and would fail in exactly the same way for the same reason: **the problem is not which
file they read, it is that they read a VENDORED copy instead of fetching.** Raised with
them rather than silently building or silently skipping.

**A determinism conflict this creates, resolved rather than ignored.** The manifest header
declares "Content-derived, deterministic — re-running at the same VERSION yields an
identical file." A wall-clock `released:` breaks that. Resolution: re-running at the same
VERSION with a byte-identical artifact PRESERVES the existing `released:` value, because
the release happened once and re-running the script is not a re-cut. That keeps idempotence
truthfully rather than by omission.

## Acceptance Criteria

### Agent
- [x] `scripts/release-designer.sh` emits all four fields at cut: `version`, `released` (ISO8601 UTC), `src_commit`, `supersedes`
- [x] Re-running the script at an unchanged VERSION with a byte-identical artifact leaves `released:` and `src_commit:` UNCHANGED — measured by running it twice and diffing, not asserted from reading the code
- [x] The manifest header no longer claims unqualified determinism if that claim has stopped being true; whatever it claims must match what a second run actually produces
- [x] `supersedes:` is derived from the actual previous release present in `dist/`, not from a hand-maintained list that can drift from what shipped
- [x] `dist/MANIFEST.yaml` backfilled for 0.8.0 with values DERIVED and each one's derivation recorded — no invented timestamps
- [x] The backfilled `src_commit` is accompanied by an explicit note that content-matching alone cannot identify it: three commits carry byte-identical src for 0.8.0, so the sha bounds WHAT was built, never WHERE it came from
- [x] Existing consumer contract is not broken: `latest`, `artifact`, `sha256`, `bytes`, `source`, `capabilities` all still present and unchanged in meaning
- [x] `tools/_t382-release-lag.py` still runs and reports (the instrument that reads this file must survive the shape change)
- [x] Position on the redundant `dist/LATEST.yaml` sent to AEF with the reasoning, so they can overrule it — it is their consumer half, not mine to close by fiat

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

# Exits 3 (COULD-NOT-MEASURE) if the sandbox cut produces no manifest — which is
# exactly how the set -e / grep -v defect presented: no file, no error message.
bash tools/_t387-manifest-fields.sh > /tmp/.t387-out 2>&1 && grep -q "PASS=17 FAIL=0" /tmp/.t387-out
# The two legs that pull in opposite directions. Either alone is satisfiable by a
# wrong implementation: a frozen timestamp passes the first, a wall-clock one the second.
grep -q "released is sticky across re-run" /tmp/.t387-out
grep -q "released MOVED on a real cut" /tmp/.t387-out
# Teeth must have RUN and had bite, not merely not-failed.
grep -q "teeth: non-sticky script DOES move released" /tmp/.t387-out
# First-release case: supersedes empty is correct and must not abort the script.
grep -q "supersedes (empty = first release)" /tmp/.t387-out
# The live manifest parses and carries all four fields plus the legacy contract.
python3 -c "import yaml; d=yaml.safe_load(open('dist/MANIFEST.yaml')); assert all(d.get(k) for k in ('version','released','src_commit','supersedes','latest','artifact','sha256','bytes','source','capabilities')), d"
# The instrument that reads this file must survive the shape change (exit 3 = could-not-measure).
python3 tools/_t382-release-lag.py > /tmp/.t387-lag 2>&1; test $? -ne 3
# The release script still parses — a broken one is discovered at the worst moment.
bash -n scripts/release-designer.sh

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

### 2026-08-08T17:15:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-387-emit-the-four-consumer-facing-release-fi.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9ca88336
- **Timestamp:** 2026-08-08T17:22:55Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#9 (Agent)** — Position on the redundant `dist/LATEST.yaml` sent to AEF with the reasoning, so they can overrule it — it is their consumer half, not mine to close by fiat
  - **AC-verify-mismatch** (narrow, heuristic) — `path=dist/LATEST.yaml in: Position on the redundant `dist/LATEST.yaml` sent to AEF with the reasoning, so they can overrule it — it is their consumer half, not mine to close by`

### 2026-08-08T17:22:50Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
