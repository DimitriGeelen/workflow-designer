---
id: T-489
name: "Close the seam fixed-point coverage gap: author one fixture that exercises
  the 8 keys T-488 measured as never proven"
description: >
  T-488 measured proven_fraction 26/34: seven projected keys (section, autoTrigger,
  trigger, gatewayKind, scopeOf, owner, linkId) appear in no fixture at all, and hostRef's
  carrier exists but boundary-events.bpmn has a single activity so a boundary event
  has no alternative host to re-point at. The guard is sound (0 BLIND) — the corpus
  simply cannot exercise 8 of the 34 keys it projects. Remedy is ONE NEW fixture,
  not an edit to an existing one: AEF digest-pins tests/fixtures/aef-bpmn/typed-events.bpmn
  and boundary-events.bpmn (SHA_832_TYPED / SHA_832_BOUNDARY), so mutating either
  would break their guard and trigger the rail announcement protocol for no reason.
  OBS-048.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: ["T-488"]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-13T08:50:32Z
last_update: '2026-08-16T12:34:02Z'
date_finished: 2026-08-13T09:04:17Z
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
  - ts: '2026-08-16T12:34:02Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
---

# T-489: Close the seam fixed-point coverage gap: author one fixture that exercises the 8 keys T-488 measured as never proven

## Context

T-488 gave the seam's semantic fixed point per-key teeth and, in doing so, produced its first
honest denominator: **`proven_fraction: 26/34`**. The guard was sound — 0 BLIND — but eight of the
thirty-four keys it projects had never been put in front of it. Seven appear in no fixture at all;
`hostRef`'s carrier exists in `boundary-events.bpmn`, which has a single activity, so a boundary
event has no alternative host to re-point at.

**The one-line fix was the wrong fix.** Adding a second task to `boundary-events.bpmn` makes
`hostRef` exercisable immediately — and that file is digest-pinned by AEF as `SHA_832_BOUNDARY`
(`typed-events.bpmn` as `SHA_832_TYPED`). Their guard would go red, and under their rail-584
announcement protocol an unannounced change makes a legitimate edit read as fixture tampering. A
new file achieves the same coverage, changes no existing byte, and owes no announcement.

## Findings

**`proven_fraction` 26/34 → 34/34.** 34 LIVE, 0 BLIND, 0 NOT-EXERCISABLE, 0 NEVER-PRESENT over 19
fixtures; all 19 round-trip green; bridge suite 71/0; geometry 24 clean.

**T-317's census guard caught a real defect in the first draft**, and its failure message is the
reason this task did not quietly widen: *"A new hit is a real finding to report, not a number to
update."* The gateway had two unconditioned outgoing flows — at most one may be the default, so
the runtime had no defined choice. The tempting move was to add the fixture to the expected census
(one line, suite green). The correct one was to condition the branch, because the guard was right.
The distinction matters more than the fix: a census that gets updated whenever it fires stops
being a census.

**The two unreachable-node warnings the fixture emits are the accepted boundary-event pattern**,
not a defect — `boundary-events.bpmn` emits four of the same kind and has done since it was
written. Checked rather than assumed, because "my new file warns" and "my new file is wrong" look
identical from the warning text alone.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] AC1 — **Blast radius of ADDING a file to `tests/fixtures/aef-bpmn/` established before authoring
      one.** Several suites iterate that directory (`test_corpus_fixture_pins.py`,
      `test_typed_event_fixture_contract.py`, the round-trip harness, `_t338`). If any asserts an
      exact file list, a fixed count, or a per-file contract the new fixture cannot satisfy, that is
      found here and reported — not discovered by a red suite afterwards. If a blocker exists that
      cannot be satisfied without changing an AEF-pinned file, **stop and report** rather than
      widening scope.
- [x] AC2 — **AEF's two digest-pinned fixtures are byte-untouched.** `typed-events.bpmn`
      (`SHA_832_TYPED`) and `boundary-events.bpmn` (`SHA_832_BOUNDARY`) are vendored and digest-guarded
      on their side. `git diff` is empty for both. The temptation this task must refuse is adding a
      second activity to `boundary-events.bpmn` to make `hostRef` exercisable — that is a one-line
      edit which would turn their guard red and, per their rail-584 protocol, make a legitimate change
      read as local fixture tampering. A new file costs nothing and announces nothing.
- [x] AC3 — **One new fixture carries all seven NEVER-PRESENT keys** — `section`, `autoTrigger`,
      `trigger`, `gatewayKind`, `scopeOf`, `owner`, `linkId` — each with a value that is distinct and
      non-empty, so a mutation of it is observable.
- [x] AC4 — **`hostRef` becomes exercisable**: the fixture carries a boundary event AND at least two
      attachable activities, so re-pointing `attachedToRef` at a different valid host is constructible.
      This is the NOT-EXERCISABLE state T-488 split out precisely so this remedy would be obvious.
- [x] AC5 — **`proven_fraction` measurably rises and the harness says so.** The round-trip harness
      reports 34/34 LIVE with 0 BLIND, 0 NOT-EXERCISABLE and 0 NEVER-PRESENT. The number is read out
      of the harness's own output, not asserted from the fixture's contents — authoring a key into a
      file is a CLAIM that it is covered; the harness reporting it LIVE is the evidence.
- [x] AC6 — **The fixture is a legitimate document, not a key-bag.** It parses, round-trips green
      through the harness like every other fixture (`ok: true`), and passes the bridge suite. A file
      that exercises the keys but is not a valid workflow would move the metric while weakening the
      corpus it joins.
- [x] AC7 — **Byte-neutral outside the one new file.** `git diff` is empty for `src/`,
      `docs/standards/`, `examples/`, `.agentic-framework/` and for every pre-existing file in
      `tests/fixtures/`. No re-pin, no seam event, no rail announcement owed.

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

# NOTE (OBS-043): the P-011 gate strips HTML comment spans from this block before running it.
# No leg below carries those delimiters as data.

# AC2 — AEF's two digest-pinned fixtures are byte-untouched. Pinned at ZERO changed lines, so a
# future "just add a task to boundary-events" goes red instead of silently owing a rail announcement.
test $(git diff --stat -- tests/fixtures/aef-bpmn/typed-events.bpmn tests/fixtures/aef-bpmn/boundary-events.bpmn | wc -l) -eq 0

# AC3+AC4 — the fixture carries the eight keys. This is the CLAIM half; AC5 is the evidence half.
grep -q 'section="intake"' tests/fixtures/aef-bpmn/governance-key-coverage.bpmn
grep -q 'autoTrigger="on-intake"' tests/fixtures/aef-bpmn/governance-key-coverage.bpmn
grep -q 'gatewayKind="exclusive"' tests/fixtures/aef-bpmn/governance-key-coverage.bpmn
grep -q 'linkId="cov-link-1"' tests/fixtures/aef-bpmn/governance-key-coverage.bpmn
test $(grep -c '<bpmn:serviceTask ' tests/fixtures/aef-bpmn/governance-key-coverage.bpmn) -ge 2

# AC5 — the EVIDENCE half, read out of the harness rather than out of the fixture. Authoring a key
# into a file is a claim of coverage; the harness reporting it LIVE is the only thing that proves it.
T=$(mktemp) && node tools/_roundtrip-serialization-cdp.mjs > "$T" && python3 -c "import json; d=json.load(open('$T')); s=d['selftest']; assert d['pass']; assert s['controls']['held']; assert s['proven_fraction'] == '34/34', s['proven_fraction']; assert not s['blind'] and not s['never_present'] and not s['not_exercisable']; print('OK', s['summary'])"

# AC6 — legitimate document: parses, and the gateway is unambiguous (T-317 caught it otherwise).
python3 -c "import xml.dom.minidom; xml.dom.minidom.parse('tests/fixtures/aef-bpmn/governance-key-coverage.bpmn')"
! python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/governance-key-coverage.bpmn 2>&1 | grep -q 'gw_ambiguous'

# AC1+AC6 — the suite that owns the blast radius.
bash tests/run-bridge-tests.sh

# AC7 — nothing changed anywhere else; the fixture is purely additive.
test -z "$(git diff --name-only -- src docs/standards examples .agentic-framework tests/fixtures)"


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

### 2026-08-13 — the cheapest fix was the one that costs the peer
- **What changed:** `hostRef` needs a second attachable activity, and `boundary-events.bpmn` is one
  line away from having one. That file is AEF-digest-pinned (`SHA_832_BOUNDARY`), so the one-line edit
  would turn their guard red and, unannounced, read as fixture tampering under their rail-584 protocol.
- **Plan impact:** Scope moved from "enrich a fixture" to "author a new one" before any byte was
  written. Nothing in our tree marks those two files as pinned — it was known only because T-423's
  vendoring table happened to be in front of me an hour earlier. That is luck, not process.
- **Triggered:** a P-011 leg pinning both files at zero changed lines, so a future one-line edit goes
  red instead of silently owing an announcement; the rule sent to AEF at rail 608.

### 2026-08-13 — a census that updates when it fires stops being a census
- **What changed:** The first draft failed T-317's gateway-ambiguity census: two unconditioned outgoing
  flows, so the runtime has no defined choice. The one-line green was to add the fixture to the expected
  census; the correct move was to condition the branch, because the guard was right.
- **Plan impact:** No AC anticipated the fixture itself being defective. AC6 ("legitimate document, not
  a key-bag") turned out to be the load-bearing one rather than boilerplate.
- **Triggered:** conditionExpression on the branch; the unreachable-node warnings checked against
  `boundary-events.bpmn` rather than assumed benign — "my file warns" and "my file is wrong" are
  indistinguishable from the warning text.

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

### 2026-08-13T08:50:32Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-489-close-the-seam-fixed-point-coverage-gap-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3dc2ca29
- **Timestamp:** 2026-08-13T09:05:55Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 21
     - evidence: `! python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/governance-key-coverage.bpmn 2>&1 | grep -q 'gw_ambiguous'`

### 2026-08-13T09:04:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
