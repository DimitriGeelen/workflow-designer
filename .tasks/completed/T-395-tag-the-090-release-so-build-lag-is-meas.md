---
id: T-395
name: "tag the 0.9.0 release so build lag is measurable"
description: >
  tag the 0.9.0 release so build lag is measurable

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
created: 2026-08-08T19:37:36Z
last_update: '2026-08-16T12:33:55Z'
date_finished: 2026-08-08T19:43:25Z
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

# T-395: tag the 0.9.0 release so build lag is measurable

## Context

Release 0.9.0 was cut in T-393 (VERSION bump + `dist/` regeneration at commit
`8cd0c5d3`) but never tagged. The audit surfaced this as a **warn, not a pass**:

    [WARN] Release lag UNMEASURED — COULD NOT MEASURE: release tag designer-v0.9.0
           does not exist — cannot measure build lag. A missing tag is NOT zero lag.

That wording is the point. The check refuses to report a number it cannot derive
rather than reporting `0` — an absent tag and a zero lag are the same one-bit
outcome under a naive check, and this one declines to conflate them
(see the `exit-codes-carry-the-wrong-reason` family).

Tag target is `8cd0c5d3`, established by convention across the two prior cuts,
verified not assumed:

| tag              | commit     | that commit's `VERSION` |
|------------------|-----------|--------------------------|
| `designer-v0.7.1`| `9d62c852`| 0.7.1                    |
| `designer-v0.8.0`| `1a13035c`| 0.8.0                    |
| `designer-v0.9.0`| `8cd0c5d3`| **0.9.0** (confirmed)    |

Note `dist/MANIFEST.yaml` records `src_commit: dd5f80c1`, which is the commit the
build was made *from* — NOT the release commit. Tagging `dd5f80c1` would match the
manifest field and still be wrong: it does not contain the 0.9.0 `VERSION` or the
built artifact. The two identifiers answer different questions and only one of them
is what a release tag names.

## Acceptance Criteria

### Agent
- [x] Annotated tag `designer-v0.9.0` exists and points at `8cd0c5d3` (the VERSION-bump commit), matching the convention of the two prior cuts
- [x] The tag's tree carries `VERSION` == `0.9.0` — i.e. the tag names a commit that actually IS the release, not merely one near it
- [x] The tag's tree carries `dist/aef-workflow-designer-0.9.0.html` at sha256 `9ccd2c584e073bcd3702eb7efac5b0e5ec734b9ecabb572a3cff012083ff801a` (the sha announced to AEF at rail 480) — so the announced bytes and the tagged bytes are provably the same artifact
- [x] `tools/_t382-release-lag.py` reports a MEASURED lag (no `COULD NOT MEASURE`)
- [x] `fw audit` no longer emits `Release lag UNMEASURED`
- [x] Tag is pushed to `origin` and visible via `git ls-remote --tags`
- [x] The structural gap is recorded: `scripts/release-designer.sh` contains no tagging step, so this omission recurs on every cut unless prevention is filed (see RCA)

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

# Tag resolves to the release commit. `^{commit}` peels the annotated tag object;
# without it an annotated tag resolves to its OWN sha and this can never match.
git rev-parse designer-v0.9.0^{commit} > /tmp/.t395-rev 2>&1 && grep -qx "8cd0c5d3d5e6511236953aba18f4068ddcd1befd" /tmp/.t395-rev
# The tagged tree IS the release, not merely adjacent to it.
git show designer-v0.9.0:VERSION > /tmp/.t395-ver 2>&1 && grep -qx "0.9.0" /tmp/.t395-ver
# Tagged artifact bytes == the sha announced to AEF at rail 480. Reads from the TAG,
# not the worktree, so a dirty tree cannot forge this.
git show designer-v0.9.0:dist/aef-workflow-designer-0.9.0.html 2>/dev/null | sha256sum > /tmp/.t395-sha 2>&1 && grep -q "9ccd2c584e073bcd3702eb7efac5b0e5ec734b9ecabb572a3cff012083ff801a" /tmp/.t395-sha
# Lag is MEASURED. Negated grep is the verdict, so a tool crash (empty output) also fails.
python3 tools/_t382-release-lag.py > /tmp/.t395-lag 2>&1 && ! grep -q "COULD NOT MEASURE" /tmp/.t395-lag
# Audit no longer reports the UNMEASURED warn. `;` is DELIBERATE here (contra the errexit
# note above): audit exits 1 while the 3 fabric warns stand, so its exit code must not be
# the verdict — the absence of this specific string is. Anchored on "Release lag UNMEASURED"
# which cannot appear when the check succeeds.
.agentic-framework/bin/fw audit > /tmp/.t395-audit 2>&1; ! grep -q "Release lag UNMEASURED" /tmp/.t395-audit
# Tag is on origin, not just local.
git ls-remote --tags origin designer-v0.9.0 > /tmp/.t395-remote 2>&1 && grep -q "designer-v0.9.0" /tmp/.t395-remote

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

**Symptom:** Release 0.9.0 was cut, verified, announced to AEF and pushed — but
carried no git tag. The audit reported `Release lag UNMEASURED` rather than a lag.

**Root cause:** `scripts/release-designer.sh` performs no tagging step. Verified:
the script reads `VERSION`, builds the artifact, and writes `dist/MANIFEST.yaml`,
but `git tag` appears nowhere in its 10821 bytes. Every one of the ten prior tags
(`designer-v0.2.0` … `designer-v0.8.0`) was therefore applied **by hand**, by a
session that happened to remember. 0.9.0 is simply the first cut where nobody did.

**Why structurally allowed:** the release procedure has two outputs — the *artifact*
(automated, deterministic, byte-verified) and the *tag* (manual, unprompted,
unverified at the point of cutting). Nothing at cut time reads the tag back, so the
omission was invisible until an unrelated check went looking for it later. This is
the same shape as PL-112 / the T-391 finding, one layer up: **a step that depends on
the author remembering it is not a step, it is a hope.** The release script's own
success output cannot distinguish "release complete" from "release complete except
for the identifier everything downstream keys on".

**Detection worked — generation is what is missing.** Worth stating precisely,
because the two are easy to conflate into one "we should fix releases" conclusion.
The G-024 / T-382 lag check caught this within a single session, and caught it in
the *right* way: it reported `UNMEASURED (exit 3) — deliberately not 'ok'` rather
than defaulting a missing tag to a zero lag. Confirmed as a live positive control
before the fix (exit 3, `COULD NOT MEASURE`) and after (exit 0, `verdict: OK`), so
the check demonstrably discriminates rather than always-passing. The gap is not in
noticing; it is that the cut can complete without producing the thing.

**Prevention:** not delivered by this task, and deliberately not bolted on here —
one task, one deliverable. Filed separately as **T-396**: make `release-designer.sh`
either create the tag itself or refuse to report success without it. Recording the
distinction rather than closing on the mitigation, per G-019: tagging 0.9.0 is
mitigation (the mess is cleaned up), not prevention (0.10.0 can miss it identically).

**Note on the near-miss target.** `dist/MANIFEST.yaml` records
`src_commit: dd5f80c1`, a *handover* commit — the source state the build was made
from. Tagging that would have matched the manifest field, looked correct, and been
wrong: `dd5f80c1` contains neither `VERSION: 0.9.0` nor the built artifact. The
manifest's `src_commit` and a release tag answer different questions. AC 2 and AC 3
exist to catch exactly that error class — they assert the tagged tree *is* the
release (VERSION + artifact sha), not merely that a tag was created.

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

### 2026-08-08 — which commit the tag names

- **Chose:** `8cd0c5d3`, the VERSION-bump / `dist/` regeneration commit from T-393.
- **Why:** it is the convention the two prior cuts already follow, and the choice was
  verified rather than inferred — `git show <tag>:VERSION` returns the matching
  version for `designer-v0.7.1` (`9d62c852`), `designer-v0.8.0` (`1a13035c`), and now
  `designer-v0.9.0`. The tagged tree additionally reproduces the exact artifact sha
  announced to AEF at rail 480, so the announced bytes and the tagged bytes are the
  same object.
- **Rejected:** `dd5f80c1`, the commit named by `dist/MANIFEST.yaml`'s `src_commit`.
  Superficially the more "official" answer, and wrong: it is the source state the
  build was made *from* and contains neither the 0.9.0 `VERSION` nor the artifact.
  Rejected on evidence, not preference — under AC 2 and AC 3 it fails both.

### 2026-08-08 — mitigation recorded as mitigation, not as a fix

- **Chose:** tag 0.9.0 under this task; file the script change as T-396.
- **Why:** G-019 — tagging this one release cleans up the mess but leaves 0.10.0 able
  to miss identically. Keeping them separate stops a closed task from reading as
  though the recurrence were prevented. Also honours one-task-one-deliverable.
- **Rejected:** amending `release-designer.sh` inside this task. It would have closed
  the audit warn and the structural gap under a single ID, making the prevention
  invisible in the register the moment this task archived.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-08T19:37:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-395-tag-the-090-release-so-build-lag-is-meas.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b8c3c094
- **Timestamp:** 2026-08-08T19:44:39Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#7 (Agent)** — The structural gap is recorded: `scripts/release-designer.sh` contains no tagging step, so this omission recurs on every cut unless prevention is filed (see RCA)
  - **AC-verify-mismatch** (narrow, heuristic) — `path=scripts/release-designer.sh in: The structural gap is recorded: `scripts/release-designer.sh` contains no tagging step, so this omission recurs on every cut unless prevention is file`

### 2026-08-08T19:43:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
