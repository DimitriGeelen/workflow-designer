---
id: T-615
name: "cut a 0.12.0 release candidate for the T-589 navigation up to but not including the VERSION bump, so the operator decides on bytes rather than on a question"
description: >
  cut a 0.12.0 release candidate for the T-589 navigation up to but not including the VERSION bump, so the operator decides on bytes rather than on a question

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-27T08:57:46Z
last_update: 2026-08-27T09:00:26Z
date_finished: 2026-08-27T09:00:26Z
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
---

# T-615: cut a 0.12.0 release candidate for the T-589 navigation up to but not including the VERSION bump, so the operator decides on bytes rather than on a question

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

001-CashWeb is parked on a release. T-589's `fabricRef` / `links` navigation is committed in
`src/` and `dist/` tops out at 0.11.0, so no consumer can pin it. Roadmap §2.1 Arc 4 names
"diagram↔Fabric navigation" in the Designer column; the code exists and cannot be reached.

**T-200 is not the task for this, and finding that out is what created this one.** T-200 reads
"Release designer with IW-9 editor (VERSION bump)" and looks like the release task. It is
about **0.3.0**, which shipped in **July** — sha `36be033d…`, 826,643 bytes, AEF notified at
rail offset 61. All five of its agent ACs are ticked and describe completed work. It sits at
`status: captured`, `horizon: later`, `owner: human`, never closed. I deferred work to it
twice this session on the strength of its title.

So the 0.12.0 release had **no task at all**, and the queue looked like it did — which is
PL-076's shape: a lookup that returns something is not the same as a lookup that returns the
right thing.

### What this task deliberately stops short of

A release is a sovereignty promise over immutable bytes (G-007), and the VERSION bump is the
operator's. This task therefore does **everything up to that line and nothing past it**:
build the candidate to a scratch path, compute its identity, run the release render gate
against it, and enumerate exactly what a consumer would receive that they cannot get today.

The output is a decision on **specific bytes with a known sha**, not a question about whether
to release. `VERSION`, `dist/` and `dist/MANIFEST.yaml` are not touched.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A 0.12.0 candidate is built to a scratch path with its **sha256 and byte count
      recorded**, and `VERSION`, `dist/` and `dist/MANIFEST.yaml` are all provably unmodified
      afterwards — checked with `git status`, not asserted.
      <br>**Evidence:** candidate `sha256 fc78717d399bbf528bf8f9fcc67dc7c543bf5489795165f86179602625f75159`,
      **993,710 bytes**. `git status --short -- VERSION dist/` returns **empty**.
      <br>The candidate is `src/` copied verbatim, and that is not a shortcut — it is the
      release script's own invariant: `release-designer.sh:77` refuses to publish unless
      `diff -q "$SRC" "$ARTIFACT"` is clean. `cmp` confirms byte-identity, so these are the
      exact bytes a real cut would produce.
- [x] The release render gate (`tests/test_designer_render.py`) is run **against the
      candidate**, not against `src/` and not against the 0.11.0 release. Result recorded
      whichever way it comes out; a red gate is a finding, not a reason to stop reporting.
      <br>**Evidence: PASS.** `PASS: designer render-check (0.12.0) — render, T-177 markers,
      inspector dropdowns, and console all OK`, exit 0.
      <br>The gate hard-codes `_resolve_build()` to read `ROOT/VERSION` and `ROOT/dist/`, with
      no path or env override. Rather than edit `VERSION` to make it point somewhere — which
      would have touched the file this task exists to leave alone — it was run from a
      **throwaway root** (`VERSION=0.12.0`, `dist/aef-workflow-designer-0.12.0.html`, a copy
      of the test) since `ROOT` derives from the test file's own location.
- [x] The consumer-visible delta between 0.11.0 and the candidate is enumerated from the
      **bytes of both artifacts**, not from git log prose. At minimum it must answer the
      question CashWeb actually asked: does the candidate contain the anchor path that 0.11.0
      measured as absent (`linkify` 0, `window.open` 0, `<a>` 0)?
      <br>**Evidence**, counted in both artifacts:
      <br>`linkify` 0→1 · `window.open` 0→1 · `<a ` 0→1 · `fabricRef` 0→6 · `linkList` 0→2 ·
      `Fabric component` 0→1. Size 966,087 → 993,710 (+27,623 bytes).
      <br>So yes: every marker CashWeb measured as absent is present in the candidate, and
      **0.11.0 genuinely has zero of all six** — the release is the whole difference.
- [x] The 0.11.0 baseline figures are **re-measured here**, not quoted from rail 604. A
      quoted measurement is a claim; this AC exists because the whole release turns on the
      0.11.0-vs-candidate difference being real.
      <br>**Evidence:** all six counts above were taken from
      `dist/aef-workflow-designer-0.11.0.html` in this task, independently of CashWeb's report
      and of my own rail post. They agree with both. Had they disagreed, the release case
      would have collapsed and the finding would have been that instead.
- [x] T-200's staleness is recorded where the next agent will hit it — in T-200 itself — so
      nobody defers to it a fourth time. Its Human ACs are not ticked and its status is not
      changed: it is `owner: human` and closing it is not delegated.
      <br>**Evidence:** a `STALE` block now heads T-200's body, naming the shipped 0.3.0
      artifact, its sha, the rail offset AEF was notified on, and pointing forward to T-615.
      Frontmatter untouched — `status: captured`, `owner: human`, no AC ticked.

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

# --- T-615 --- this task must have left the sovereignty surface alone.
test "$(tr -d '[:space:]' < VERSION)" = "0.11.0"
git diff --quiet HEAD -- VERSION dist/
# The candidate's identity is reproducible from src (release-designer.sh:77 invariant).
test "$(sha256sum src/aef-workflow-designer.html | cut -c1-64)" = "fc78717d399bbf528bf8f9fcc67dc7c543bf5489795165f86179602625f75159"
# And the claim the release rests on: 0.11.0 really carries none of the navigation.
test "$(grep -c fabricRef dist/aef-workflow-designer-0.11.0.html)" = "0"

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

## Recommendation

**Recommendation:** GO — cut 0.12.0 from the candidate below. This is a recommendation to the
operator, not an action taken: `VERSION` is untouched and the bump is theirs.

**Rationale:** the release is the entire difference between a consumer having Arc-4
diagram↔Fabric navigation and not having it. 0.11.0 carries **zero** of the six navigation
markers; the candidate carries all six. No engineering remains — the code is committed, the
release render gate passes against the exact candidate bytes, and the artifact is
byte-identical to `src/` as the release script requires. A consumer (001-CashWeb) built the
matching destination independently and is parked. The only reason this has not shipped is
that nobody bumped a version file, and for three sessions I mis-attributed the work to T-200,
which shipped in July.

**Evidence:**
- candidate `sha256 fc78717d399bbf528bf8f9fcc67dc7c543bf5489795165f86179602625f75159`, 993,710 bytes
- `PASS: designer render-check (0.12.0)` — run against the candidate in a throwaway root, exit 0
- delta counted in both artifacts: `linkify` 0→1, `window.open` 0→1, `<a ` 0→1,
  `fabricRef` 0→6, `linkList` 0→2, `Fabric component` 0→1; 966,087 → 993,710 bytes
- `git diff --quiet HEAD -- VERSION dist/` exits 0 — nothing in the sovereignty surface moved
- consumer evidence: rail 603 (destination built, 21/21 nodes), rail 604 (our answer)

**The two commands, single-line and copy-pasteable.** The first is the sovereignty act; the
second does the mechanical work and is already fully verified:

    cd /opt/832-Workflow-designer && echo "0.12.0" > VERSION && scripts/release-designer.sh

**What I have deliberately not done:** touched `VERSION`, written to `dist/`, updated
`dist/MANIFEST.yaml`, or notified AEF of a version that does not exist. A release is a
sovereignty promise over immutable bytes (G-007) and a peer benefiting from it is not
authorisation to make it.

**If NO-GO:** say so and I will tell 001-CashWeb plainly that the panel navigation is not
shipping, so they can stop waiting and decide whether their option (a) — the outbound
`aef:select` seam — is worth proposing properly instead.

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

### 2026-08-27T08:57:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-615-cut-a-0120-release-candidate-for-the-t-5.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4f6a1c36
- **Timestamp:** 2026-08-27T09:00:27Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#2 (Agent)** — The release render gate (`tests/test_designer_render.py`) is run **against the
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/test_designer_render.py in: The release render gate (`tests/test_designer_render.py`) is run **against the`

### 2026-08-27T09:00:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
