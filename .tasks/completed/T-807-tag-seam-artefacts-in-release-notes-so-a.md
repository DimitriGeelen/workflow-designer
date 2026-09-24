---
id: T-807
name: "Tag seam artefacts in release notes so AEF pins a tag, not a moving head"
description: >
  AEF's second ask at agent-chat-arc @1656, following the branch-model adoption (T-805,
  PD-309): 'tag the seam artefacts in your release notes so we pin a tag, not a moving
  head'. Under the release train AEF pins master, which advances at release. Release
  notes should name the seam artefact state (examples/aef-processes/rendered/) at
  each tag so AEF has a fixed reference rather than a branch head.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [scripts/seam-manifest.sh]
related_tasks: [T-805]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T12:17:18Z
last_update: 2026-09-24T21:35:59Z
date_finished: 2026-09-24T21:35:59Z
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
  - ts: '2026-09-23T16:49:20Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 5
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=5 
      (prose:seam-contract); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-23T16:50:14Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-24T21:32:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-807: Tag seam artefacts in release notes so AEF pins a tag, not a moving head

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

AEF's second ask (`docs/branch-model.md` "The seam" section, `agent-chat-arc @1656`): tag
`examples/aef-processes/rendered/` state in release notes so AEF pins a tag, not a moving head.
The current cut mechanism is `scripts/release-designer.sh`, which writes `dist/MANIFEST.yaml`
for the designer HTML artifact only — it has no record of `examples/aef-processes/rendered/`
at all. There are 16 existing `designer-v*` tags (`designer-v0.1.0`..`designer-v0.13.0`) and no
retroactive record for any of them. `scripts/announce-release.sh` is the other release-adjacent
script (posts the rail announcement); `docs/aef-designer-integration-protocol.md` is the
consumer-facing protocol doc AEF reads. Candidate touch points for the build: a new read-only
script under `scripts/` that computes file-list + sha256 for `examples/aef-processes/rendered/`
at an arbitrary git ref (no writes to `dist/`, `VERSION`, or the seam directory itself), plus a
checked-in record doc under `docs/releases/`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The release process records, at each tag, the state of `examples/aef-processes/rendered/` (file list plus a content hash per file)
- [x] The record lives in the release notes or an artefact the notes reference, and is reachable from the tag alone — no branch head lookup required
- [x] AEF can resolve "which seam bytes does tag `designer-vX.Y.Z` carry" from the tag without fetching a moving branch
- [x] Verified against the existing tag series rather than only the next one, so the answer is not empty for everything already released

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
         1. Run `bin/fw reviewer T-807`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-807 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

test -x scripts/seam-manifest.sh
out=$(./scripts/seam-manifest.sh designer-v0.13.0 2>&1); echo "$out" | grep -q "sha256:"
diff <(./scripts/seam-manifest.sh designer-v0.9.0) <(./scripts/seam-manifest.sh designer-v0.9.0) > /tmp/.out 2>&1 && test ! -s /tmp/.out
test "$(grep -c '^ref: "designer-v' docs/releases/seam-manifest.md)" = "$(git tag -l 'designer-v*' | wc -l)"
out=$(grep -A2 "tag the seam artefacts" docs/branch-model.md 2>&1); echo "$out" | grep -q "done (T-807)"

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

### 2026-09-24 — record mechanism: computed-on-demand, not incrementally-stored
- **Chose:** a read-only script (`scripts/seam-manifest.sh <ref>`) that computes the seam
  manifest live from git's object store for any ref, plus a checked-in doc
  (`docs/releases/seam-manifest.md`) backfilled now for all 16 existing `designer-v*` tags and
  appended manually after each future cut.
- **Why:** the seam directory's history was already fully recorded — by git itself, at every
  past commit and tag. The actual gap was a *queryable, tag-addressable* answer, not a missing
  record. A tool that reads git history directly satisfies AC4 (verified against the whole
  existing series) without any backfill risk, since nothing about past commits needs to change.
  Keeping `dist/`, `VERSION`, and `examples/aef-processes/rendered/` itself untouched avoids the
  hard-reversal / sovereignty-adjacent surface those paths carry (a release is a promise, G-007).
- **Rejected:** (a) writing per-tag manifest files into `dist/` alongside `MANIFEST.yaml` —
  touches the artifact AEF already pins by sha and risks conflating two different guarantees;
  (b) modifying `scripts/release-designer.sh`'s tag-cutting logic to auto-append the manifest at
  cut time — real automation is a natural follow-up, but it changes behaviour of the live release
  script for an external consumer (AEF) and deserves its own review rather than riding in on a
  build task that only needed to make the record queryable. Documented as a manual step instead
  (see `docs/releases/seam-manifest.md` header) so a human decides when to automate it.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-807 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T12:17:18Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-807-tag-seam-artefacts-in-release-notes-so-a.md
- **Context:** Initial task creation

### 2026-09-24T21:32:13Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0104ff65
- **Timestamp:** 2026-09-24T21:36:00Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-24T21:35:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
