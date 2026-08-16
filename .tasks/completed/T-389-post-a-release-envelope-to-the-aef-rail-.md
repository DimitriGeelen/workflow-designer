---
id: T-389
name: "Post a release envelope to the AEF rail at cut time (G-024 consumer half)"
description: >
  AEF cannot fetch dist/MANIFEST.yaml and will not probe our remote unasked (rail
  471 §3). Their ask: release-designer.sh posts one envelope per cut carrying version
  + released + src_commit, so their currency check is a live rail read compared against
  their pin — outside the artifact, read live, no vendored copy. Closes the consumer
  half of G-024.

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
created: 2026-08-08T17:43:33Z
last_update: '2026-08-16T12:33:55Z'
date_finished: 2026-08-08T17:53:08Z
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
  - ts: '2026-08-16T12:33:55Z'
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

# T-389: Post a release envelope to the AEF rail at cut time (G-024 consumer half)

## Context

AEF answered the one live G-024 question at rail 471 §3: they will **not** `git fetch` our
origin (their T-559 boundary forbids reading our tree, and they will not guess repo URLs
unasked), and a second file (`dist/LATEST.yaml`) is refused on both sides — a vendored copy
of an outside-the-artifact pointer is back inside a versioned thing. Their ask is **one
envelope per cut on the existing rail**: no new file, no new transport. Their currency check
then becomes a live read compared against their pin.

## Acceptance Criteria

### Agent
- [x] `scripts/announce-release.sh` reads `dist/MANIFEST.yaml` (never re-derives release
      identity) and posts ONE envelope carrying `version`, `released`, `src_commit`,
      `sha256`, `artifact` — the three AEF asked for plus the two their pin verification
      needs — tagged `metadata.cv_key=designer-release`
- [x] The announce is IDEMPOTENT against the rail, not against a 5-minute TTL: re-running
      with an unchanged manifest reads the current cv_key value first and appends nothing.
      (`--client-msg-id` dedupe is explicitly NOT relied on — its TTL is ~5 min, and
      "did we already announce 0.8.0?" is a question spanning days.)
      Confirmed live: second run → "Already announced: 0.8.0", rail unchanged.
- [x] A failed announce does NOT abort or roll back the cut — the artifact is the
      deliverable — but is LOUD: non-zero from the announce step, a warning naming the
      standalone recovery command, and the release script's own final line states
      ANNOUNCED or NOT ANNOUNCED. Silence is the one outcome that is not allowed.
- [x] `scripts/release-designer.sh` invokes the announce step after the manifest is
      written, and the existing determinism/idempotence contract still holds — verified
      structurally: the change is a pure insertion at line 181+, and the manifest
      heredoc ends at line 175, so no byte of manifest generation is reachable by it
- [x] `tools/_t389-release-envelope.sh` proves the above with teeth that mutate LIVE
      source (never `git show HEAD~N:`), an anti-vacuity leg, and `exit 3`
      COULD-NOT-MEASURE rather than a false census when the hub is unreachable — 8/8
- [x] The 0.8.0 envelope is posted and retrievable by `channel subscribe
      --include-current-value` without replaying the topic — live at rail offset 472
- [x] The cost of that currency read is MEASURED (cv-indexed read vs full state replay of
      the 470+ message rail) — this is the question AEF flagged as unverified on their
      side, and it is cheap for us to answer and expensive for them to guess:
      **full `channel state` 1,443,501 bytes / 0.08s (grows without bound) vs cv-indexed
      read 756 bytes / 0.01s (constant)** — 1900x on the live rail

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
bash tools/_t389-release-envelope.sh
test -x scripts/announce-release.sh
grep -q "CUT but NOT ANNOUNCED" scripts/release-designer.sh
# The rail must agree with the manifest. Fail-closed on purpose: if this cannot be
# established (hub down), completion is blocked rather than assumed green — the whole
# gap is about reporting "current" when you do not know.
scripts/announce-release.sh > /tmp/.t389-rail 2>&1 && grep -q "Already announced" /tmp/.t389-rail

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

### 2026-08-08 — cv-indexed envelope on the existing rail, not a new topic
- **Chose:** post to the existing DM rail tagged `metadata.cv_key=designer-release`.
- **Why:** AEF asked for no new transport. The cv index makes topic pollution a
  non-issue — the key resolves to the latest release envelope regardless of how much
  prose shares the topic, verified on a scratch topic where unrelated chatter posted
  between two keyed envelopes did not move the key.
- **Rejected:** a dedicated release topic (a new transport AEF must learn about and
  subscribe to, for a problem the cv index already solves); scanning the rail for the
  newest release-shaped message (1.44 MB per check and growing without bound).

### 2026-08-08 — idempotence keyed on the rail's own current value, not `--client-msg-id`
- **Chose:** read the current cv value and compare `version + sha256` before posting.
- **Why:** `--client-msg-id` dedupe has a ~5 minute TTL. "Have we already announced
  0.8.0?" is a question that spans days, so the TTL answers a different question than
  the one being asked — it would go quiet exactly when a duplicate is most likely.
- **Rejected:** version-only identity. A re-cut under `RELEASE_ALLOW_OVERWRITE` changes
  the bytes at an unchanged version; the rail would keep advertising the old sha and a
  consumer's pin verification would fail against an announcement we believed was current.

### 2026-08-08 — announce failure is non-fatal to the cut but never silent
- **Chose:** the cut succeeds, the announce failure is loud, and the final line always
  states `CUT and ANNOUNCED` or `CUT but NOT ANNOUNCED`.
- **Why:** the artifact is the deliverable and a down hub must not roll it back. But a
  quiet announce failure leaves AEF's check reporting "current" from a stale rail —
  the false-green direction they called unacceptable at rail 471 §3.
- **Rejected:** aborting the cut on announce failure (loses a verified artifact to an
  unrelated outage); best-effort silent announce (recreates G-024 exactly).

### 2026-08-08 — verify the hub INDEXED the envelope, not merely accepted it
- **Chose:** after posting, re-read the cv index and require it to point at our offset.
- **Why:** a post can succeed while `cv_key` metadata is dropped. The consumer's O(1)
  read would then never see the release while we believe we announced it — PL-034, a
  guard checking internal self-consistency cannot detect a broken promise. The post's
  own success is exactly such a self-consistent signal.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-08T17:43:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-389-post-a-release-envelope-to-the-aef-rail-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-059a8412
- **Timestamp:** 2026-08-08T17:53:10Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Agent)** — `scripts/announce-release.sh` reads `dist/MANIFEST.yaml` (never re-derives release
  - **AC-verify-mismatch** (narrow, heuristic) — `path=dist/MANIFEST.yaml in: `scripts/announce-release.sh` reads `dist/MANIFEST.yaml` (never re-derives release`

### 2026-08-08T17:53:08Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
